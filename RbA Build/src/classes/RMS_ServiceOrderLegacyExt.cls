/*******************************************************//**

@class  RMS_ServiceOrderLegacyExt

@brief  code for driving the create service request process in the event
that the Account does not have any assets. This page displays all Service
Products beneath their Master Products to choose from. See RMS_ServiceOrderExtensionMgr
for more commentary.

@author  Brianne Wilson (Slalom.BLW)

@version    2016-4-19  Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/

public with sharing class RMS_ServiceOrderLegacyExt  {
    
    public final Order o;    
    public list<OrderItem > listOI{ get; set; }    
    public List<Product2> selectedProducts {get;set;}
    public Map<Id,List<ProductWrapper>> ProductToProductWrapperMap{get;set;}
    public static final Id serviceProductRecordTypeId = UtilityMethods.RecordTypeFor('Product2','Service_Product');
    public static final Id masterProductRecordTypeId = UtilityMethods.RecordTypeFor('Product2', 'Master_Product');
    public Boolean hasValidationErrors {get{return ApexPages.hasMessages(ApexPages.Severity.ERROR);}}
    
    public RMS_ServiceOrderLegacyExt(ApexPages.StandardController stdController) {
        if(!test.isRunningTest()){
            stdController.addFields(new List<String>{'AccountId','Pricebook2Id'});           
        }
        
        this.o = (Order)stdController.getRecord();
        
        
        listOI=new list<OrderItem>();
        
        List<id> productIds=new List<id>();
        for(Product2 p : [SELECT    Id
                          FROM Product2 
                          WHERE RecordTypeId = :masterProductRecordTypeId]){
                              productIds.add(p.id);
                          }        
        selectedProducts = [SELECT Id, 
                            Name
                            FROM Product2
                            WHERE Id IN: productIds
                            ORDER BY Name];
        
        //Map<Id,Id> assetIdToProductIdMap = new Map<Id,Id>();
        //for(Asset a: selectedAssets){
        //assetIdToProductIdMap.put(a.Id,a.Product2Id);
        //}
        
        
        List<Product2> serviceProducts = [SELECT    Id,
                                          Name,
                                          Master_Product__c
                                          FROM Product2
                                          WHERE RecordTypeId =: serviceProductRecordTypeId
                                          AND Master_Product__c in: selectedProducts
                                          ORDER BY Name];
        Map<Id,List<ProductWrapper>> masterProductToProductWrapperMap = new Map<Id,List<ProductWrapper>>();
        
        for(Product2 prod: serviceProducts){
            if(masterProductToProductWrapperMap.containsKey(prod.Master_Product__c)){
                masterProductToProductWrapperMap.get(prod.Master_Product__c).add(new ProductWrapper(prod));
            }else{
                masterProductToProductWrapperMap.put(prod.Master_Product__c,new List<ProductWrapper>{new ProductWrapper(prod)});
            }
        }
        
        
        ProductToProductWrapperMap = new Map<Id, List<ProductWrapper>>();
        for(Product2 p: selectedProducts){
            if(masterProductToProductWrapperMap.containsKey(p.Id)){
                ProductToProductWrapperMap.put(p.Id,masterProductToProductWrapperMap.get(p.Id).clone());
            }else{
                ProductToProductWrapperMap.put(p.Id, new List<ProductWrapper>());
            }
        }
        system.debug(ProductToProductWrapperMap);
        
    }
    
    
    
    //Universal Methods
    public PageReference customDelete(){
        delete o;
        
        PageReference deletePage = Page.RMS_DeletePage;
        deletePage.setRedirect(true);
        return deletePage;
        
    }
    
    
    
    
    
    
    public String aid { get; set; }{
        aid = apexpages.currentpage().getparameters().get('aid');
        if ( aid == null ) aid = '';
    }
    
    public String slid { get; set; }{
        slid = apexpages.currentpage().getparameters().get('slid');
        if ( slid == null ) slid = '';
    }
    
    
    
    
    //Page 2 Methods 
    //
    public PageReference saveClose(){
        PageReference pageRef = null;
        
        try{
            Id standardPriceBookId;  
            if(Test.isRunningTest()){
                standardPriceBookId = Test.getStandardPricebookId();
            } else{
                standardPriceBookId = [
                    select Id 
                    from Pricebook2 
                    where isStandard=true
                ].Id;
            }
            
            for(Id productId : ProductToProductWrapperMap.keySet()){
                for(ProductWrapper wrapper: ProductToProductWrapperMap.get(productId)){
                    if(wrapper.isSelected){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Id];                       
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;                        
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;                        
                        oi.Charge_Cost_To__c = wrapper.cost;
                        oi.Primary_Reason__c = wrapper.primary;
                        oi.Secondary_Reason__c = wrapper.secondary;
                        oi.Description = wrapper.description;
                        listOI.add(oi);                           
                    }
                }        
            }
            o.Service_Type__c = propPickValSelected;
            upsert o;
            system.debug(listOI);
            insert listOi;
            pageRef = new PageReference('/' + o.id);
            pageRef.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            listOI.clear();
        }
        
        return pageRef;
    }        
    
    
    public class ProductWrapper{
        public Product2 product{get;set;}
        public Boolean isSelected{get;set;}        
        public Asset asset{get;set;}
        public String cost {get;set;}
        public String primary {get;set;}
        public String secondary {get;set;}
        public String description {get;set;}
        
        public String getDescription(){
            return description;
        }
        
        public void description (String description){
            this.description = description;
        }
        
        public List<SelectOption> getCosts()
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption(' ','--- Select ---'));        
            options.add(new SelectOption('Manufacturer - Replace','Manufacturer - Replace'));
            options.add(new SelectOption('Local - Remake','Local - Remake'));
            options.add(new SelectOption('Customer - Replace','Customer - Replace'));
            return options;
        } 
        
        public String getcost() {
            return cost;
        }
        
        public void cost(String cost) {
            this.cost = cost;
        }
        
        
        public List<SelectOption> getPrimaries()
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption(' ','--- Select ---'));
            if(cost == 'Manufacturer - Replace')
            {       
                options.add(new SelectOption('Andersen Logistics','Andersen Logistics'));
                options.add(new SelectOption('Bayworld','Bayworld'));
                options.add(new SelectOption('EMCO','EMCO'));
                options.add(new SelectOption('Other Vendor','Other Vendor'));
                options.add(new SelectOption('Renewal by Andersen','Renewal by Andersen'));            
            }
            else if(cost == 'Local - Remake')
            {       
                options.add(new SelectOption('Goodwill','Goodwill'));
                options.add(new SelectOption('Installation','Installation'));
                options.add(new SelectOption('Management','Management'));
                options.add(new SelectOption('Order Entry','Order Entry'));
                options.add(new SelectOption('Sales','Sales'));
                options.add(new SelectOption('Service','Service'));
                options.add(new SelectOption('Staining','Staining'));
                options.add(new SelectOption('Tech Measure','Tech Measure'));
                options.add(new SelectOption('Warehouse','Warehouse'));
                options.add(new SelectOption('Home Owner','Home Owner'));
            }
            else
            {
                options.add(new SelectOption(' ','--- Select ---'));
            }      
            return options;
        }  
        
        
        public String getprimary() {
            return primary;
        }
        
        public void primary(String primary) {
            this.primary = primary;
        }
        
        public List<SelectOption> getSecondaries()
        {
            List<SelectOption> options = new List<SelectOption>();
            if(primary == 'Goodwill')
            {       
                options.add(new SelectOption('Customer Satisfaction','Customer Satisfaction'));
                options.add(new SelectOption('Data Entry','Data Entry')); 
                options.add(new SelectOption('Discontinued Vendor','Discontinued Vendor')); 
                options.add(new SelectOption('Out of Warranty','Out of Warranty'));             
            }
            else if(primary == 'Installation')
            {       
                options.add(new SelectOption('Blinds/Shutters','Blinds/Shutters'));
                options.add(new SelectOption('Carbon Monoxide Detector','Carbon Monoxide Detector'));
                options.add(new SelectOption('Caulking','Caulking')); 
                options.add(new SelectOption('Clean-Up','Clean-Up')); 
                options.add(new SelectOption('Damage Product','Damage Product')); 
                options.add(new SelectOption('Incomplete Load','Incomplete Load')); 
                options.add(new SelectOption('Interior Trim','Interior Trim')); 
                options.add(new SelectOption('Product Damage','Product Damage')); 
                options.add(new SelectOption('Quality Workmanship','Quality Workmanship')); 
                options.add(new SelectOption('Rot Repair','Rot Repair')); 
                options.add(new SelectOption('Security Wires','Security Wires')); 
                options.add(new SelectOption('Shims','Shims')); 
                options.add(new SelectOption('Smoke Detectors','Smoke Detectors')); 
                options.add(new SelectOption('Warp','Warp'));             
            }
            else if(primary == 'Management')
            {       
                options.add(new SelectOption('General Manager','General Manager'));
                options.add(new SelectOption('Installation Manager','Installation Manager'));
                options.add(new SelectOption('Operations Manager','Operations Manager')); 
                options.add(new SelectOption('Sales Manager','Sales Manager')); 
                options.add(new SelectOption('Service Manager','Service Manager'));             
            } 
            else if(primary == 'Order Entry')
            {       
                options.add(new SelectOption('Change Order','Change Order'));
                options.add(new SelectOption('Data Entry','Data Entry'));
                options.add(new SelectOption('Process Error','Process Error')); 
                options.add(new SelectOption('Verification','Verification'));           
            }
            else if(primary == 'Sales')
            {       
                options.add(new SelectOption('Blinds/Shutters','Blinds/Shutters'));
                options.add(new SelectOption('Change Order','Change Order'));
                options.add(new SelectOption('Check Rail','Check Rail')); 
                options.add(new SelectOption('Color','Color')); 
                options.add(new SelectOption('Egress','Egress')); 
                options.add(new SelectOption('Glass Type','Glass Type')); 
                options.add(new SelectOption('Grille Pattern','Grille Pattern')); 
                options.add(new SelectOption('Handling','Handling')); 
                options.add(new SelectOption('Hardware','Hardware')); 
                options.add(new SelectOption('Interior Trim','Interior Trim')); 
                options.add(new SelectOption('Sash Ratio','Sash Ratio')); 
                options.add(new SelectOption('Screens','Screens')); 
                options.add(new SelectOption('Stain/Paint Expectation','Stain/Paint Expectation')); 
                options.add(new SelectOption('Tempered Glass','Tempered Glass'));
                options.add(new SelectOption('Unit Type','Unit Type'));
                options.add(new SelectOption('Wrong Expectations','Wrong Expectations'));
            }
            else if(primary == 'Service')
            {       
                options.add(new SelectOption('Incomplete Load','Incomplete Load'));
                options.add(new SelectOption('Order Entry','Order Entry'));
                options.add(new SelectOption('Property Damage','Property Damage')); 
                options.add(new SelectOption('Technician Damage','Technician Damage')); 
                options.add(new SelectOption('Technician Error','Technician Error'));                         
            }
            else if(primary == 'Staining')
            {       
                options.add(new SelectOption('Color Mismatch','Color Mismatch'));
                options.add(new SelectOption('Damage','Damage'));
                options.add(new SelectOption('Quality','Quality'));             
            }
            else if(primary == 'Tech Measure')
            {       
                options.add(new SelectOption('Application','Application'));
                options.add(new SelectOption('Change Order','Change Order'));
                options.add(new SelectOption('Glass Type','Glass Type')); 
                options.add(new SelectOption('Grille Pattern Alignment','Grille Pattern Alignment')); 
                options.add(new SelectOption('Math Error','Math Error')); 
                options.add(new SelectOption('Non-Fitting Unit','Non-Fitting Unit')); 
                options.add(new SelectOption('Sill Angle','Sill Angle')); 
                options.add(new SelectOption('Site Materials','Site Materials')); 
                options.add(new SelectOption('Transposition','Transposition'));              
            }
            else if(primary == 'Warehouse')
            {       
                options.add(new SelectOption('Building Material','Building Material'));
                options.add(new SelectOption('Incomplete Load','Incomplete Load'));
                options.add(new SelectOption('Product Damage','Product Damage'));            
            }
            else if(primary == 'Home Owner')
            {       
                options.add(new SelectOption('Condensation','Condensation'));
                options.add(new SelectOption('Operation','Operation'));
                options.add(new SelectOption('Product Question','Product Question'));            
            }
            else
                
            {
                options.add(new SelectOption(' ','--- Select ---'));
            }      
            return options;
        }   
        
        public String getsecondary() {
            return secondary;
        }
        
        public void secondary(String secondary) {
            this.secondary = secondary;
        }   
        
        public ProductWrapper(Product2 prod){
            product = prod;
            isSelected = false;  
            cost = '-- Select --';
            primary = '-- Select --';
            secondary = '-- Select --';
            description = '';
                }
    }
    
    Public string propPickValSelected { get; set; }
    public List<SelectOption> getPickLstValue()
    {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Order.Service_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        Order od = new order();
        od = [SELECT Sold_Order_JIP_Eligible__c 
              FROM Order 
              WHERE Id =:o.id];            
        IF (od.Sold_Order_JIP_Eligible__c){
            for(Schema.PicklistEntry f : ple){
                if(f.getValue() == 'Job In Progress' || f.getValue() == 'Save'){
                    options.add(new SelectOption(f.getLabel(), f.getValue()));                          
                }                      
            }
        }
        ELSE{
            options.add(new SelectOption('--None--','--None--')); 
            for(Schema.PicklistEntry f : ple){
                if(f.getValue() != 'Job In Progress' && f.getValue() != 'Field Service'){
                    options.add(new SelectOption(f.getLabel(), f.getValue()));
                }
            } 
        }
        
        return options;           
    }
    
    public String getpropPickValSelected() {
        return propPickValSelected;
    }
    
    public void setpropPickValSelected(String propPickValSelected) {
        this.propPickValSelected = propPickValSelected;
    }
    
}
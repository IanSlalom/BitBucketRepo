/*******************************************************//**

@class  RMS_ServiceOrderExtensionMgr

@brief  code for driving the create service request process. This controller
is used for RMS_createServiceRequestRedirect, RMS_createServiceOrderP1, and 
RMS_createServiceOrderP2. Note that there is a separate controller for the 
case where the Account is legacy and does not have any Asset records.

@author  Brianne Wilson (Slalom.BLW)

@version    2016-4-19  Slalom.BLW
Created.


Unauthorized use is prohibited.

***********************************************************/
public with sharing class RMS_ServiceOrderExtensionMgr  {
    
    public final Order o;   
    public integer num_orders;
    public integer num_assets;
    public integer sales_tax;
    public list<OrderItem > listOI{ get; set; } 
    public List<Service_Product__c> serviceProducts {get;set;}
    public List<Asset> selectedAssets {get;set;}
    public Id masterProductId = UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Master_Product');    
    public Map<Id,List<ProductWrapper>> AssetToProductWrapperMap{get;set;}   
    public Boolean hasValidationErrors {get{return ApexPages.hasMessages(ApexPages.Severity.ERROR);}}
    public String baseURL{get;set;}
    public String cancelUpdateURL{get;set;}
    Public string propPickValSelected2 { get; set; }
    public String updateSTURL{get;set;}
    public String editRedirect{get;set;}
    private List<OrderItem> allAccs {get; set;}
    public List<GroupWrapper> groups {get; set;}
    public String groupFieldName {get; set;}
    public List<SelectOption> groupOptions {get; set;}
    public List<Charge__c> charges {get; set;}
    public list<OrderItem > listOILegacy{ get; set; }    
    public List<Product2> selectedProductsLegacy {get;set;}
    public List<Service_Product__c> serviceProductsLegacy {get;set;}
    public Map<Id,List<ProductWrapper2>> ProductToProductWrapperMapLegacy{get;set;}
    
    public RMS_ServiceOrderExtensionMgr(ApexPages.StandardController stdController) {
        if(!test.isRunningTest()){
            stdController.addFields(new List<String>{'AccountId','PriceBook2Id','Service_Type__c','Id'});           
        }
        
        this.o = (Order)stdController.getRecord();
        propPickValSelected2 = o.Service_Type__c;
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        cancelUpdateURL = '/' + o.Id;
        updateSTURL = '/apex/RMS_updateServiceType?id=' + o.Id;
        editRedirect ='/apex/RMS_editServiceRequest?id='+o.Id;
        
        //these aggregate result lists are used to count the number of Orders 
        //and assets for the related Account to determine where the user is taken
        //on the redirect page --> P1 or Legacy P1
        
        List<AggregateResult> results=[select COUNT (Id) 
                                       FROM Order 
                                       WHERE AccountId = :aid 
                                       AND RecordTypeId = :rt];
        num_orders = (Integer) results[0].get('expr0');
        
        List<AggregateResult> results2=[select COUNT (Id) 
                                        FROM Asset 
                                        WHERE AccountId = :aid];
        num_assets = (Integer) results2[0].get('expr0');
        
        
        
        listOI=new list<OrderItem>();
        
        allAccs=[select id, OrderId, Product_Name__c,Installed_Product_Name__c,
                 (select id, Charge_Cost_To__c, Category__c, What_Where__c, Service_Product__c, Service_Request__c from Charges__r)
                 from OrderItem
                 where OrderId =: o.Id];
        
        groupFieldName='Installed_Product_Name__c';
        
        setupGrouping();
        groupOptions=new List<SelectOption>();
        groupOptions.add(new SelectOption('Installed_Product_Name__c', 'Installed_Product_Name__c'));
        //finding the Assets of the related Account to populate on P2 list
        //code then finds the products for each of the Assets and then
        //displays the Service Products for each Product availble to select
        //for the Service Request
        List<id> assetIds=new List<id>();
        for(Asset a : [SELECT    Id,Product2.RecordTypeId
                       FROM Asset 
                       WHERE AccountId = :o.AccountId
                       AND Product2.RecordTypeId = :masterProductId]){
                           assetIds.add(a.id);
                       }        
        selectedAssets = [SELECT    Id,
                          Name,
                          Install_Date__c,
                          Product2Id,
                          Product2.Name, 
                          Original_Order_Variant_Number__c, 
                          Location_Details__c,
                          Original_Order_Product__c
                          FROM Asset 
                          WHERE Id = :assetIds
                          ORDER BY Name];
        
        //Mapping Assets to Products, grabbing ids
        Map<Id,Id> assetIdToProductIdMap = new Map<Id,Id>();
        for(Asset a: selectedAssets){
            assetIdToProductIdMap.put(a.Id,a.Product2Id);
        }
        List<Service_Product__c> serviceProducts = [SELECT    Id,
                                                    Name,
                                                    Master_Product__c,
                                                    Service_Product__c
                                                    FROM Service_Product__c
                                                    WHERE Master_Product__c in: assetIdToProductIdMap.values()
                                                    ORDER BY Name];
        Map<Id,List<ProductWrapper>> masterProductToProductWrapperMap = new Map<Id,List<ProductWrapper>>();
        
        for(Service_Product__c prod: serviceProducts){
            if(masterProductToProductWrapperMap.containsKey(prod.Master_Product__c)){
                masterProductToProductWrapperMap.get(prod.Master_Product__c).add(new ProductWrapper(prod));
            }else{
                masterProductToProductWrapperMap.put(prod.Master_Product__c,new List<ProductWrapper>{new ProductWrapper(prod)});
            }
        }
        
        
        AssetToProductWrapperMap = new Map<Id, List<ProductWrapper>>();
        for(Asset a: selectedAssets){
            if(masterProductToProductWrapperMap.containsKey(a.Product2Id)){
                List<ProductWrapper> wrapperList = new List<ProductWrapper>();
                for(ProductWrapper wrap: masterProductToProductWrapperMap.get(a.Product2Id)){
                    wrapperList.add(new ProductWrapper(wrap.product));
                }
                AssetToProductWrapperMap.put(a.Id,wrapperList);
            }else{
                AssetToProductWrapperMap.put(a.Id, new List<ProductWrapper>());
            }
        }
        system.debug(AssetToProductWrapperMap);
        
        listOILegacy=new list<OrderItem>();
        
        List<id> productIds=new List<id>();
        for(Product2 p : [SELECT    Id
                          FROM Product2 
                          WHERE RecordTypeId = :masterProductId]){
                              productIds.add(p.id);
                          }        
        selectedProductsLegacy = [SELECT Id, 
                                  Name
                                  FROM Product2
                                  WHERE Id IN: productIds
                                  ORDER BY Name];
        
        //Map<Id,Id> assetIdToProductIdMap = new Map<Id,Id>();
        //for(Asset a: selectedAssets){
        //assetIdToProductIdMap.put(a.Id,a.Product2Id);
        //}
        
        
        List<Service_Product__c> serviceProductsLegacy = [SELECT    Id,
                                                          Name,
                                                          Master_Product__c,
                                                          Service_Product__c
                                                          FROM Service_Product__c
                                                          WHERE Master_Product__c in: selectedProductsLegacy
                                                          ORDER BY Name];
        Map<Id,List<ProductWrapper2>> masterProductToProductWrapperMapLegacy = new Map<Id,List<ProductWrapper2>>();
        
        for(Service_Product__c prod: serviceProductsLegacy){
            if(masterProductToProductWrapperMapLegacy.containsKey(prod.Master_Product__c)){
                masterProductToProductWrapperMapLegacy.get(prod.Master_Product__c).add(new ProductWrapper2(prod));
            }else{
                masterProductToProductWrapperMapLegacy.put(prod.Master_Product__c,new List<ProductWrapper2>{new ProductWrapper2(prod)});
            }
        }
        
        
        ProductToProductWrapperMapLegacy = new Map<Id, List<ProductWrapper2>>();
        for(Product2 p: selectedProductsLegacy){
            if(masterProductToProductWrapperMapLegacy.containsKey(p.Id)){
                ProductToProductWrapperMapLegacy.put(p.Id,masterProductToProductWrapperMapLegacy.get(p.Id).clone());
            }else{
                ProductToProductWrapperMapLegacy.put(p.Id, new List<ProductWrapper2>());
            }
        }
        system.debug(ProductToProductWrapperMapLegacy);
    }
    
    
    
    
    //Universal Methods
    public PageReference customDelete(){
        //deletes the order and redirects to delete confirmation page
        delete o;
        
        PageReference deletePage = Page.RMS_DeletePage;
        deletePage.setRedirect(true);
        return deletePage;
        
    }
    
    
    
    //Redirect Page Methods
    
    //grabbing those aggregate result calculcations
    Public Integer getnumorders() {
        return num_orders;
    }
    
    Public Integer getnumassets(){
        return num_assets;
    }
    
    
    public String aid { get; set; }{
        aid = apexpages.currentpage().getparameters().get('aid');
        if ( aid == null ) aid = '';
    }
    
    public String slid { get; set; }{
        slid = apexpages.currentpage().getparameters().get('slid');
        if ( slid == null ) slid = '';
    }
    
    //order is automatically saved on the redirect page, this is 
    //to populate all required fields and parent object records
    //which we either do not want in the UI or need populated
    //in order to make the UI work (i.e. Account)
    //
    public PageReference saveOrder(){
        
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
            
            //populates the Account, a standard price book which is needed
            //to create orderitems, store, sets record type, and status
            o.AccountId = aid;
            o.Pricebook2Id = standardPriceBookId;
            o.Store_Location__c = slid;                              
            o.RecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order');
            o.Status = 'New';           
            upsert o;
            
            
            //if the Account has at least 1 sold order, user is taken to the Select an Order
            //page. If the Account does not have an order, but has assets (legacy), user is taken to
            //Page 2 where they select the Service Products. If the Account does not have any orders
            //or any assets, user is taken to the legacy page where all Service Products are displayed
            //for selection 
            PageReference newPage;
            
            If (num_orders > 0){
                newPage = new PageReference('/apex/RMS_createServiceRequestP1?id='+ o.Id + '&retUrl=' + o.Id);
            } else {
                If (num_assets > 0){
                    newPage = new PageReference('/apex/RMS_createServiceRequestP2?id='+ o.Id + '&retUrl=' + o.Id); 
                } else{
                    Contact_History__c ch = new Contact_History__c();
                    ch = [Select Contact__c, Dwelling__c, Primary_Contact__c, Id FROM Contact_History__c WHERE Dwelling__c =: o.AccountId AND Primary_Contact__c = true];
                    o.BillToContactId = ch.Contact__c;
                    upsert o;
                    newPage = new PageReference('/apex/RMS_ServiceRequestLegacyP1?id='+ o.Id + '&retUrl=' + o.Id);
                }
            }
            
            newPage.setRedirect(true);
            return newPage;
        }catch(DMLException saveEx){
            PageReference newPage = new PageReference('/apex/RMS_createServiceRequestP1?id='+ o.Id + '&retUrl=' + o.Id);
            newPage.setRedirect(true);
            return newPage;
        }
        
    }    
    
    
    //Page 1 Methods    
    Id rt = Schema.SObjectType.Order.RecordTypeInfosByName.get('CORO Record Type').RecordTypeId;
    
    //grabbing all Sold Orders from the related Account and displaying them as a picklist for selection
    public List<selectOption> getOrds() {
        List<selectOption> options = new List<selectOption>(); //new list for holding all of the picklist options        
        for (Order orders : [SELECT Id, OrderNumber, Activated_Date__c, Status 
                             FROM Order 
                             WHERE Status NOT IN('Draft', 'Tech Measure Needed', 'Tech Measure Scheduled', 'Ready to Order', 'Order Released', 'Install Needed')
                             AND RecordTypeId = :rt 
                             AND AccountId = :o.AccountId 
                             ORDER BY Order.OrderNumber DESC]) { 
                                 options.add(new selectOption(orders.Id, orders.OrderNumber + ' - ' + orders.Activated_Date__c + ' - ' + orders.Status)); //for all records found - add them to the picklist options
                             }
        options.add(new selectOption('', 'None')); //add the first option of '- None -' in case the user doesn't want to select a value or in case no values are returned from query below
        return options; //return the picklist options        
    }               
    
    //save method for P1 to P2
    public PageReference saveP2(){
        try{      
            
            //find the Sales Tax from the Store Location and set on Order
            Account sl = new Account();
            sl = [SELECT Store_Location__r.Sales_Tax__c FROM Account WHERE id =: o.AccountId];
            if(sl != null){
                o.Sales_Tax_Percent__c = sl.Store_Location__r.Sales_Tax__c;    
            }
            
            //populate Bill to Contact, either from related Sold Order or the Primary
            //Contact for the Account based on Contact History. This is 
            //a failsafe to ensure Bill to Contact is always populated on P2 which is
            //necessary for all of the UI elements rerendering.           
            Order bc = new Order();
            Contact_History__c ch = new Contact_History__c();
            
            if(o.Sold_Order__c != null){
                bc = [Select BilltoContactId FROM Order WHERE id =: o.Sold_Order__c];
                if(bc != null){
                    o.BillToContactId = bc.BilltoContactId;
                }
            } else {
                ch = [Select Contact__c, Dwelling__c, Primary_Contact__c, Id FROM Contact_History__c WHERE Dwelling__c =: o.AccountId AND Primary_Contact__c = true LIMIT 1];
                o.BillToContactId = ch.Contact__c;
            }            
            
            upsert o;
            
            PageReference pageRef = new PageReference('/apex/RMS_createServiceRequestP2?id='+ o.Id + '&retUrl=' + o.Id);
            pageRef.setRedirect(true);
            return pageRef;
        }catch(DMLException saveEx){
            PageReference pageRef = new PageReference('/apex/RMS_createServiceRequestP2?id='+ o.Id + '&retUrl=' + o.Id);
            pageRef.setRedirect(true);
            return pageRef;
        }
        
    }
    
    //Page 2 Methods 
    //
    //
    //
    
        public PageReference saveClose(){
        PageReference newPage;
        
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
            
            
            //in the wrapper, displaying all Service Products for the Master Products in each
            //Asset for the Account, a checkbox and three fields appear. For each Service Product
            //selected...create an OrderItem for the Service Request and populate appropriate fields.
            for(Id assetID : AssetToProductWrapperMap.keySet()){
                for(ProductWrapper wrapper: AssetToProductWrapperMap.get(assetId)){
                    if(wrapper.isSelected){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];
                        
                        Asset oa = [
                            SELECT Id,Product2Id,Original_Order_Product__c
                            FROM Asset
                            WHERE Id = :assetId];                        
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;
                        oi.Sold_Order_Product_Asset__c = assetId; 
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;
                        oi.Description = wrapper.description;
                        listOI.add(oi); 
                        
                    }
                }        
            }
            
            //checkbox on Order set to true, needed to ensure we validate required fields, but
            //only when the entire request is filled out and not during a rerender.
            o.Validate_Service_Order__c = true;
            //convert the selectOption value to picklist value, set on Ordre
            o.Service_Type__c = propPickValSelected;
            
            
            upsert o;
            system.debug(listOI);
            
            //inserts the OrderItems
            insert listOi;
            
            
            if(listOI.Size() > 0){
                newPage = new PageReference('/'+o.id);                
            } else {
                newPage = new PageReference('/' + o.id);
            }
            
            newPage.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            //needed to make sure the collapsed rows stay collapsed when validation error occurs
            listOI.clear();
        }
        
        return newPage;
    }  
    
    public PageReference saveContinue(){
        PageReference newPage;
        
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
            
            
            //in the wrapper, displaying all Service Products for the Master Products in each
            //Asset for the Account, a checkbox and three fields appear. For each Service Product
            //selected...create an OrderItem for the Service Request and populate appropriate fields.
            for(Id assetID : AssetToProductWrapperMap.keySet()){
                for(ProductWrapper wrapper: AssetToProductWrapperMap.get(assetId)){
                    if(wrapper.isSelected){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];
                        
                        Asset oa = [
                            SELECT Id,Product2Id,Original_Order_Product__c
                            FROM Asset
                            WHERE Id = :assetId];                        
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;
                        oi.Sold_Order_Product_Asset__c = assetId; 
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;
                        oi.Description = wrapper.description;
                        listOI.add(oi); 
                        
                    }
                }        
            }
            
            //checkbox on Order set to true, needed to ensure we validate required fields, but
            //only when the entire request is filled out and not during a rerender.
            o.Validate_Service_Order__c = true;
            //convert the selectOption value to picklist value, set on Ordre
            o.Service_Type__c = propPickValSelected;
            
            
            upsert o;
            system.debug(listOI);
            
            //inserts the OrderItems
            insert listOi;
            
            
            if(listOI.Size() > 0){
                newPage = new PageReference('/apex/RMS_createServiceRequestP3?id='+o.id);
            } else {
                newPage = new PageReference('/' + o.id);
            }
            
            newPage.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            //needed to make sure the collapsed rows stay collapsed when validation error occurs
            listOI.clear();
        }
        
        return newPage;
    }    
    
    //page3 Methods
    public PageReference regroup()
    {
        setupGrouping();
        return null;
    }
    private void setupGrouping()
    {
        Map<String, List<OrderItem>> groupedMap=new Map<String, List<OrderItem>>();
        for (OrderItem acc : allAccs)
        {
            String key=String.valueof(acc.get(groupFieldName));
            if ( (null==key) || (0==key.length()) )
            {
                key='Undefined';
            }
            
            List<OrderItem> groupedAccs=groupedMap.get(key);
            if (null==groupedAccs)
            {
                groupedAccs=new List<OrderItem>();
                groupedMap.put(key, groupedAccs);
            }
            
            groupedAccs.add(acc);
        }
        
        groups=new List<GroupWrapper>();
        for (String key : groupedMap.keySet())
        {
            GroupWrapper gr=new GroupWrapper();
            groups.add(gr);
            gr.accs=groupedMap.get(key);
            gr.groupedVal=key;
        }
    }
    
    public class GroupWrapper
    {
        public List<OrderItem> accs {get; set;}
        public String groupedVal {get; set;}
        public Integer count {get {return accs.size(); } set;}
    }
    
    Public PageReference saveCharges()
    {
        Savepoint sp = Database.setSavepoint();
        PageReference pr;
        
        // List<Charge__c> ch = [SELECT Id, Charge_Cost_To__c, Service_Product__c, Primary_Reason__c, Secondary_Reason__c FROM Charge__c WHERE Service_Product__c =: allAccs];
        List<Charge__c> ch = new list<Charge__c>();
        for(OrderItem oi: allAccs){
            ch.addAll(oi.Charges__r);
        }
        if(ch.size() > 0 ){
            update ch;  
            pr = new PageReference('/apex/RMS_viewServiceRequest?id='+o.Id);
            pr.setRedirect(true);
            return pr;
        } else {
            return null;
        } 
    }
    
    //Legacy Orders Pages
    
        public PageReference saveCloseLegacy(){
        PageReference newPage;
        
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
            
            for(Id productId : ProductToProductWrapperMapLegacy.keySet()){
                for(ProductWrapper2 wrapper: ProductToProductWrapperMapLegacy.get(productId)){
                    if(wrapper.isSelected){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];                       
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;                        
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;                        
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Description = wrapper.description;
                        listOILegacy.add(oi);                           
                    }
                }        
            }
            o.Validate_Service_Order__c = true;
            o.Service_Type__c = propPickValSelectedLegacy;
            upsert o;
            system.debug(listOILegacy);
            insert listOiLegacy;
            
            if(listOiLegacy.Size() > 0){
                newPage = new PageReference('/'+o.id);
            } else {
                newPage = new PageReference('/' + o.id);
            }
            newPage.setRedirect(true); 
            
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            listOILegacy.clear();
        }
        
        return newPage;
    }      
    
    
    public PageReference saveContinueLegacy(){
        PageReference newPage;
        
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
            
            for(Id productId : ProductToProductWrapperMapLegacy.keySet()){
                for(ProductWrapper2 wrapper: ProductToProductWrapperMapLegacy.get(productId)){
                    if(wrapper.isSelected){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];                       
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;                        
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;                        
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Description = wrapper.description;
                        listOILegacy.add(oi);                           
                    }
                }        
            }
            o.Validate_Service_Order__c = true;
            o.Service_Type__c = propPickValSelectedLegacy;
            upsert o;
            system.debug(listOILegacy);
            insert listOiLegacy;
            
            if(listOiLegacy.Size() > 0){
                newPage = new PageReference('/apex/RMS_createServiceRequestP3?id='+o.id);
            } else {
                newPage = new PageReference('/' + o.id);
            }
            
            newPage.setRedirect(true); 

        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            listOILegacy.clear();
        }
        
        return newPage;
    }        
    
    
    
    Public string propPickValSelectedLegacy { get; set; }
    public List<SelectOption> getPickLstValueLegacy()
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
            //options.add(new SelectOption('--None--','--None--')); 
            for(Schema.PicklistEntry f : ple){
                if(f.getValue() != 'Job In Progress' && f.getValue() != 'Field Service'){
                    options.add(new SelectOption(f.getLabel(), f.getValue()));
                }
            } 
        }
        
        return options;           
    }
    
    public String getpropPickValSelectedLegacy() {
        return propPickValSelectedLegacy;
    }
    
    public void setpropPickValSelectedLegacy(String propPickValSelectedLegacy) {
        this.propPickValSelectedLegacy = propPickValSelectedLegacy;
    }
    
    public class ProductWrapper2{
        public Service_Product__c product{get;set;}
        public Boolean isSelected{get;set;}        
        public Asset asset{get;set;}
        public Boolean manufacturer {get;set;}
        public Boolean local {get;set;}
        public Boolean customer {get;set;}
        public String description {get;set;}
        
        public ProductWrapper2(Service_Product__c prod){
            product = prod;
            isSelected = false;  
            manufacturer = false;
            local = false;
            customer = false;
            description = '';
        }
        
        public String getDescription(){
            return description;
        }
        
        public void description (String description){
            this.description = description;
        }
        
    }
    
    
    //add product pages
    public PageReference saveNewProducts(){
        
        PageReference newPage;
        
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
            
            
            //in the wrapper, displaying all Service Products for the Master Products in each
            //Asset for the Account, a checkbox and three fields appear. For each Service Product
            //selected...create an OrderItem for the Service Request and populate appropriate fields.
            for(Id assetID : AssetToProductWrapperMap.keySet()){
                for(ProductWrapper wrapper: AssetToProductWrapperMap.get(assetId)){
                    if(wrapper.isSelected){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];
                        
                        Asset oa = [
                            SELECT Id,Product2Id,Original_Order_Product__c
                            FROM Asset
                            WHERE Id = :assetId];                        
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;
                        oi.Sold_Order_Product_Asset__c = assetId; 
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Description = wrapper.description;
                        listOI.add(oi);                           
                    }
                }        
            }
            
            
            //checkbox on Order set to true, needed to ensure we validate required fields, but
            //only when the entire request is filled out and not during a rerender.
            o.Validate_Service_Order__c = true;
            upsert o;
            system.debug(listOI);
            
            //inserts the OrderItems
            insert listOi;
            if(listOI.Size() > 0){
                newPage = new PageReference('/'+o.id);
            } else {
                newPage = new PageReference('/' + o.id);
            }
            newPage.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            //needed to make sure the collapsed rows stay collapsed when validation error occurs
            listOI.clear();
        }
        
        return newPage;
    }
    
        public PageReference saveNewProductsContinue(){
        
        PageReference newPage;
        
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
            
            
            //in the wrapper, displaying all Service Products for the Master Products in each
            //Asset for the Account, a checkbox and three fields appear. For each Service Product
            //selected...create an OrderItem for the Service Request and populate appropriate fields.
            for(Id assetID : AssetToProductWrapperMap.keySet()){
                for(ProductWrapper wrapper: AssetToProductWrapperMap.get(assetId)){
                    if(wrapper.isSelected){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];
                        
                        Asset oa = [
                            SELECT Id,Product2Id,Original_Order_Product__c
                            FROM Asset
                            WHERE Id = :assetId];                        
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;
                        oi.Sold_Order_Product_Asset__c = assetId; 
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;
                        oi.Description = wrapper.description;
                        listOI.add(oi);                           
                    }
                }        
            }
            
            
            //checkbox on Order set to true, needed to ensure we validate required fields, but
            //only when the entire request is filled out and not during a rerender.
            o.Validate_Service_Order__c = true;
            upsert o;
            system.debug(listOI);
            
            //inserts the OrderItems
            insert listOi;
            if(listOI.Size() > 0){
                newPage = new PageReference('/apex/RMS_createServiceRequestP3?id='+o.id);
            } else {
                newPage = new PageReference('/' + o.id);
            }
            
            newPage.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            //needed to make sure the collapsed rows stay collapsed when validation error occurs
            listOI.clear();
        }
        
        return newPage;
    } 
    
    public PageReference saveNewProductsLegacy(){
        
        PageReference newPage;
        
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
            
            
            //in the wrapper, displaying all Service Products for the Master Products in each
            //Asset for the Account, a checkbox and three fields appear. For each Service Product
            //selected...create an OrderItem for the Service Request and populate appropriate fields.
            for(Id productId : ProductToProductWrapperMapLegacy.keySet()){
                for(ProductWrapper2 wrapper: ProductToProductWrapperMapLegacy.get(productId)){
                    if(wrapper.isSelected){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];                        
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Description = wrapper.description;
                        listOI.add(oi);                           
                    }
                }        
            }
            
            
            //checkbox on Order set to true, needed to ensure we validate required fields, but
            //only when the entire request is filled out and not during a rerender.
            o.Validate_Service_Order__c = true;
            upsert o;
            system.debug(listOI);
            
            //inserts the OrderItems
            insert listOi;
            if(listOI.Size() > 0){
                newPage = new PageReference('/apex/RMS_createServiceRequestP3?id='+o.id);
            } else {
                newPage = new PageReference('/' + o.id);
            }
            
            newPage.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            //needed to make sure the collapsed rows stay collapsed when validation error occurs
            listOI.clear();
        }
        
        return newPage;
    }  
    
        public PageReference saveNewProductsLegacyContinue(){
        
        PageReference newPage;
        
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
            
            
            //in the wrapper, displaying all Service Products for the Master Products in each
            //Asset for the Account, a checkbox and three fields appear. For each Service Product
            //selected...create an OrderItem for the Service Request and populate appropriate fields.
            for(Id productId : ProductToProductWrapperMapLegacy.keySet()){
                for(ProductWrapper2 wrapper: ProductToProductWrapperMapLegacy.get(productId)){
                    if(wrapper.isSelected){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];                        
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Description = wrapper.description;
                        listOI.add(oi);                           
                    }
                }        
            }
            
            
            //checkbox on Order set to true, needed to ensure we validate required fields, but
            //only when the entire request is filled out and not during a rerender.
            o.Validate_Service_Order__c = true;
            upsert o;
            system.debug(listOI);
            
            //inserts the OrderItems
            insert listOi;
            if(listOI.Size() > 0){
                newPage = new PageReference('/apex/RMS_createServiceRequestP3?id='+o.id);
            } else {
                newPage = new PageReference('/' + o.id);
            }
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            //needed to make sure the collapsed rows stay collapsed when validation error occurs
            listOI.clear();
        }
        
        return newPage;
    }   

    
    
    //method for creating Service Type picklist, defaulted to JIP when appropriate, hiding
    //JIP as a value when appropriate
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
    
    //RMS_updateServiceType Methods
    public List<SelectOption> getPickLstValue2()
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
            
            for(Schema.PicklistEntry f : ple){
                if(f.getValue() != 'Job In Progress' && f.getValue() != 'Field Service'){
                    options.add(new SelectOption(f.getLabel(), f.getValue()));
                }
            } 
        }
        
        return options;           
    }
    
    public String getpropPickValSelected2() {
        return propPickValSelected2;
    }
    
    public void setpropPickValSelected2(String propPickValSelected2) {
        this.propPickValSelected2 = propPickValSelected2;
    }
    
    public PageReference saveST(){
        PageReference pageRef = null;
        try{
            o.Service_Type__c = propPickValSelected2;
            upsert o;
            pageRef = new PageReference('/' + o.id);
            pageRef.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
        }
        
        return pageRef;
    }
    
    public PageReference cancelOrder(){
        PageReference pageRef = null;
        try{
            o.Status = 'Cancelled';
            upsert o;
            pageRef = new PageReference('/' + o.id);
            pageRef.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
        }
        
        return pageRef;
    }
    
    //product wrapper for creating table of Service Products
    public class ProductWrapper{
        public Service_Product__c product{get;set;}
        public Boolean isSelected{get;set;}        
        public Asset asset{get;set;}
        public Boolean manufacturer {get;set;}
        public Boolean local {get;set;}
        public Boolean customer {get;set;}
        public String description {get;set;}
        
        public ProductWrapper(Service_Product__c prod){
            product = prod;  
            isSelected = false;
            manufacturer = false;
            local = false;
            customer = false;
            description = '';
        }
        
        public String getDescription(){
            return description;
        }
        
        public void description (String description){
            this.description = description;
        }
        
        
        
    }        
    
}
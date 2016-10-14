public with sharing class RMS_createWorkOrderController {
    
    
    public string woType {get;set;}
    public string orderId {get;set;}
    public string accountId{get;set;}
    public string shippingStreet{get;set;}
    public string shippingCity{get;set;}
    public string shippingState{get;set;}
    public string shippingPostalCode{get;set;}
    public string shippingCountry{get;set;}
    public string hoa{get;set;}
    public string historical{get;set;} 
    public string permit{get;set;}
    public string opportunity{get;set;}
    public string woId{get;set;}
    public string woName{get;set;}
    public string billToContactId{get;set;}
    public string storeId{get;set;}
    
    public string woRTid;

/******* Set up Standard Controller for Purchase_Order__c  *****************/
    private Apexpages.StandardController standardController;
    private final RbA_Work_Order__c wo;
    
    
    //Constructor
    public RMS_createWorkOrderController(ApexPages.StandardController stdController) {
        this.wo = (RbA_Work_Order__c)stdController.getRecord();
        map<string, string> urlParam = ApexPages.currentPage().getParameters();

        orderId = urlParam.get('orderId');
        storeId = urlParam.get('storeId');
        accountId = urlParam.get('accountId');
        shippingStreet = urlParam.get('shippingStreet');
        shippingCity = urlParam.get('shippingCity');
        shippingPostalCode = urlParam.get('shippingPostalCode');
        shippingCountry = urlParam.get('shippingCountry');
        shippingState = urlParam.get('shippingState');
        billToContactId = urlParam.get('billToContactId');
        woType = urlParam.get('type');
        
        opportunity = urlParam.get('relatedOpp');
        
        permit = urlParam.get('permit');
        hoa = urlParam.get('hoa');
        historical = urlParam.get('historical');
        
        woName = wo.Name;
        list<id> storeList = new list<id>{storeId};
        map<Id, Store_Configuration__c> storeIdToStoreConfigMap = UtilityMethods.mapStoreConfigs(storeList);
        Store_Configuration__c storeConfig = storeIdToStoreConfigMap.get(storeId);
        
        if(woType == 'visit'){
            woRTid = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
            wo.RecordTypeId = woRTid;
        }else if(woType == 'actions'){
            woRTid = UtilityMethods.retrieveRecordTypeId('Actions', 'RbA_Work_Order__c');
            wo.RecordTypeId  = woRTid;
        }else if(woType == 'lswp'){
            woRTid = UtilityMethods.retrieveRecordTypeId('LSWP', 'RbA_Work_Order__c');
            wo.RecordTypeId = woRTid;
        }else if(woType == 'paintStain'){
            woRTid = UtilityMethods.retrieveRecordTypeId('Paint_Stain', 'RbA_Work_Order__c');
            wo.RecordTypeId = woRTid;
            if(storeConfig != null && storeConfig.Paint_Stain_Vendor_Account__c != null && storeConfig.Paint_Stain_Vendor_Contact__c != null){
                wo.Vendor__c = storeConfig.Paint_Stain_Vendor_Account__c;
                wo.Vendor_Contact__c = storeConfig.Paint_Stain_Vendor_Contact__c;
            } 
        }else if(woType == 'permit'){
            woRTid = UtilityMethods.retrieveRecordTypeId('Permit', 'RbA_Work_Order__c');
            wo.RecordTypeId = woRTid;
            if(permit != null && permit != '' && permit != 'null'){
                wo.Municipality__c = permit;
            }       
        }else if(woType == 'collections'){
            woRTid = UtilityMethods.retrieveRecordTypeId('Collections', 'RbA_Work_Order__c');
            wo.RecordTypeId = woRTid;
        }
    }
    
    Public string propPickValSelected { get; set; }
    public List<SelectOption> getPickLstValue(){
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = RbA_Work_Order__c.Work_Order_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
            for(Schema.PicklistEntry f : ple){
                if(f.getValue() == 'Tech Measure' || f.getValue() == 'Install') {
                    options.add(new SelectOption(f.getLabel(), f.getValue()));                          
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
    

    public PageReference save() {
        wo.Sold_Order__c = orderId;
        wo.Account__c = accountId;
        wo.Street__c = shippingStreet;
        wo.City__c = shippingCity; 
        wo.State__c = shippingState;
        wo.Zip__c = shippingPostalCode;
        wo.Country__c = shippingCountry;
       
       if(propPickValSelected != null){
        wo.Work_Order_Type__c = propPickValSelected;
        }
        
        if(billToContactId != null && billToContactId != 'null'){
            wo.Contact__c = billToContactId;
        }
        if(opportunity != null && opportunity != '' && opportunity != 'null'){
            wo.Opportunity__c = opportunity;
        }
        if(hoa != null && hoa != '' && hoa != 'null' && wo.Work_Order_Type__c == 'HOA' ){
            wo.Municipality__c = hoa;
        }else if(historical != null && historical != '' && historical != 'null' && wo.Work_Order_Type__c == 'Historical'){
            wo.Municipality__c = historical;
        }
        
        
        wo.RecordTypeId = woRTid;
        
        insert wo;
        
        // Used for redirecting to the view page from javascript
        woId = wo.Id;
        
        return null;
    } 
        
}
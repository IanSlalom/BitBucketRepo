public with sharing class RMS_viewRelatedWorkOrdersController {
    
    public list<RbA_Work_Order__c> workOrdersList = new list<RbA_Work_Order__c>();
    public list<RbA_Work_Order__c> getWorkOrders() {
        return workOrdersList;
    }
    public string getView(){
        return 'View';
    }
    public String strurl;
    public String baseUrl{get;set;}
    
    public string serviceOrderVisitRecordTypeId{get;set;}
    public string serviceOrderActionsRecordTypeId{get;set;}
    public string serviceOrderPermitRecordTypeId{get;set;}
    public string serviceOrderLSWPRecordTypeId{get;set;}
    public string serviceOrderPaintStainRecordTypeId{get;set;}
    public string serviceOrderCollectionsRecordTypeId{get;set;}
    
    public string serviceOrderVisitRecordTypeURL{get;set;}
    public string serviceOrderActionsRecordTypeURL{get;set;}
    public string serviceOrderLSWPRecordTypeURL{get;set;}
    public string serviceOrderPaintStainRecordTypeURL{get;set;}
    public string serviceOrderPermitRecordTypeURL{get;set;}
    public string serviceOrderCollectionsRecordTypeURL{get;set;}
    
    public boolean displayButtonsOnPage{get;set;}
    public boolean displayPaintStainOnly{get;set;}
    
    public String reportURL{get;set;}
    
    /******* Set up Standard Controller for Purchase_Order__c  *****************/
    private Apexpages.StandardController standardController;
    private final Order ord;
    
    
    //Constructor
    public RMS_viewRelatedWorkOrdersController(ApexPages.StandardController stdController) {
        this.ord = (Order)stdController.getRecord();
        
        strurl = ApexPages.currentPage().getUrl();
        strurl = strurl.split('apex/')[1];
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        //TODO: use utility methods
        //list<RecordType> serviceOrderVisitRecordType = [SELECT id FROM RecordType WHERE SobjectType = 'RbA_Work_Order__c' AND Name = 'Visit'];
        //list<RecordType> serviceOrderActionsRecordType = [SELECT id FROM RecordType WHERE SobjectType = 'RbA_Work_Order__c' AND Name = 'Actions'];
        
        serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
        serviceOrderActionsRecordTypeId = UtilityMethods.retrieveRecordTypeId('Actions', 'RbA_Work_Order__c');
        serviceOrderPermitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Permit', 'RbA_Work_Order__c');
        serviceOrderLSWPRecordTypeId = UtilityMethods.retrieveRecordTypeId('LSWP', 'RbA_Work_Order__c');
        serviceOrderPaintStainRecordTypeId = UtilityMethods.retrieveRecordTypeId('Paint_Stain', 'RbA_Work_Order__c');
        serviceOrderCollectionsRecordTypeId = UtilityMethods.retrieveRecordTypeId('Collections', 'RbA_Work_Order__c');
        
        
        String ordId = ord.id;
        
        List<Report> installMatReport = [select Id from Report where DeveloperName = 'Install_Materials_Summary2' limit 1];
        String reportId = '';
        if(installMatReport.size()>0){
            reportId = installMatReport[0].Id;
        }
        reportURL = '/'+reportId+'?pv0='+String.ValueOf(ord.Id).substring(0,15)+'&pv1=Construction_Materials';
        
        
        //TODO: Get rid of dynamic and set record type var
        String woQuery= 'SELECT id, '+ 
            'Name, '+ 
            'Sold_Order__c, '+                        
            'Type_image__c, '+
            'Confirmed_Appt_w_Customer__c, '+
            'Appointment_Start_Time__c,'+
            'Scheduled_Appt_Date_Time__c , '+
            'Appointment_Duration__c,'+
            'Work_Order_Status__c, '+
            'Owner.Name, '+
            'Work_Order_Type__c, '+
            'CreatedDate '+
            
            'FROM RbA_Work_Order__c WHERE Sold_Order__c =: ordId';
        
        if(strurl.Contains('Visit')){
            //String visitRecordType = serviceOrderVisitRecordType[0].id;
            woQuery = woQuery+' AND RecordTypeId = :serviceOrderVisitRecordTypeId';
            
        }else if(strurl.Contains('Actions')){
            //String actionsRecordType = serviceOrderActionsRecordType[0].id;
            
            woQuery = woQuery+' AND (RecordTypeId = :serviceOrderActionsRecordTypeId';
            woQuery = woQuery+' OR RecordTypeId = :serviceOrderPermitRecordTypeId';
            woQuery = woQuery+' OR RecordTypeId = :serviceOrderLSWPRecordTypeId';
            woQuery = woQuery+' OR RecordTypeId = :serviceOrderPaintStainRecordTypeId';
            woQuery = woQuery+' OR RecordTypeId = :serviceOrderCollectionsRecordTypeId)';
            
        }
        system.debug('ads woQuery: '+woQuery);
        workOrdersList = Database.query(woQuery);
        
        
        
        //building strings to use as URL for create new Workorder
        Schema.DescribeSObjectResult r = RbA_Work_Order__c.sObjectType.getDescribe();
        String workOrderKeyPrefix = r.getKeyPrefix();
        
        list<Order> theOrd = [SELECT Id, AccountId, Status, Store_Location__c, OrderNumber, OpportunityId, BillToContactId, RecordTypeId FROM Order WHERE Id =:ordId ];
        Id orderServiceRecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order');
        Id changeOrderRecordTypeId = UtilityMethods.retrieveRecordTypeId('Change_Order', 'Order');
        
        // only display the paint stain button for change orders
        displayPaintStainOnly = (theOrd[0].RecordTypeId == changeOrderRecordTypeId) ? true : false;
        if(theOrd[0].Status == 'Draft' && theOrd[0].RecordTypeId != orderServiceRecordTypeId){
            displayButtonsOnPage = false;
        }else if(theOrd[0].Status != 'Draft' || theOrd[0].RecordTypeId == orderServiceRecordTypeId){
            displayButtonsOnPage = true;
        }
        
        list<Account> relatedAccount = [SELECT  Name,
                                        ShippingStreet,
                                        ShippingCity,
                                        ShippingState,
                                        ShippingPostalCode, 
                                        ShippingCountry,
                                        Historical__c,
                                        HOA__c,
                                        Building_Permit__c
                                        
                                        FROM Account WHERE Id = :theOrd[0].AccountId];
        
        
        map<String, Field_IDs__c> Field_IDs_map = Field_IDs__c.getAll(); 
        Field_IDs__c workOrderFieldIds = Field_IDs_map.get('Work Order');
        /*
String baseURL =    '/'+workOrderKeyPrefix+'/e?'+
'CF'+workOrderFieldIds.Sold_Order__c+'='+theOrd[0].OrderNumber+
'&CF'+workOrderFieldIds.Sold_Order__c+'_lkid='+Ord.Id+

'&CF'+workOrderFieldIds.Account__c+'='+relatedAccount[0].Name+
'&CF'+workOrderFieldIds.Account__c+'_lkid='+relatedAccount[0].Id+

'&'+workOrderFieldIds.Street__c+'='+relatedAccount[0].ShippingStreet+
'&'+workOrderFieldIds.City__c+'='+relatedAccount[0].ShippingCity+
'&'+workOrderFieldIds.State__c+'='+relatedAccount[0].ShippingState+
'&'+workOrderFieldIds.Zip__c+'='+relatedAccount[0].ShippingPostalCode+
'&'+workOrderFieldIds.Country__c+'='+relatedAccount[0].ShippingCountry+
'&ent='+workOrderFieldIds.Object_ID__c+
'&retURL=%2F'+Ord.Id+
'&isdtp=v4';

serviceOrderVisitRecordTypeURL = baseURL + '&RecordType='+serviceOrderVisitRecordTypeId;                                
serviceOrderActionsRecordTypeURL = baseURL + '&RecordType='+serviceOrderActionsRecordTypeId;                                        
*/                  
        
        String endURL =                     '&orderId='+Ord.Id+
            '&storeId='+theOrd[0].Store_Location__c+
            '&accountId='+relatedAccount[0].Id+
            '&shippingStreet='+relatedAccount[0].ShippingStreet+
            '&shippingCity='+relatedAccount[0].ShippingCity+
            '&shippingState='+relatedAccount[0].ShippingState+
            '&shippingPostalCode='+relatedAccount[0].ShippingPostalCode+
            '&shippingCountry='+relatedAccount[0].ShippingCountry+
            '&relatedOpp='+theOrd[0].OpportunityId+
            '&billToContactId='+theOrd[0].BillToContactId+
            '&permit='+relatedAccount[0].Building_Permit__c+    
            '&hoa='+relatedAccount[0].HOA__c+ 
            '&historical='+relatedAccount[0].Historical__c; 
        
        serviceOrderVisitRecordTypeURL =    '/apex/RMS_createVisitWorkOrder?type=visit'+endURL;
        
        
        serviceOrderActionsRecordTypeURL =  '/apex/RMS_createActionsWorkOrder?type=actions'+endURL;
        
        
        serviceOrderLSWPRecordTypeURL = '/apex/RMS_createActionsWorkOrder?type=lswp'+endURL;
        
        serviceOrderPaintStainRecordTypeURL = '/apex/RMS_createActionsWorkOrder?type=paintStain'+endURL; 
        
        serviceOrderPermitRecordTypeURL = '/apex/RMS_createActionsWorkOrder?type=permit'+endURL;
        
        serviceOrderCollectionsRecordTypeURL = '/apex/RMS_createActionsWorkOrder?type=collections'+endURL;                                    
        
    }
    
}
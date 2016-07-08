public class RMS_viewServiceRequestCtrlr {
    
    public final Order o;
    
    Public String baseURL{get;set;}
    public String updateSTURL{get;set;}
    public String editRedirect{get;set;}
    public string serviceOrderVisitRecordTypeURL{get;set;}
    public string serviceOrderActionsRecordTypeURL{get;set;}
    public string serviceOrderLSWPRecordTypeURL{get;set;}
    public string serviceOrderPaintStainRecordTypeURL{get;set;}
    public string serviceOrderPermitRecordTypeURL{get;set;}
    public string serviceOrderCollectionsRecordTypeId{get;set;}
    public string serviceOrderCollectionsRecordTypeURL{get;set;}
    
    public id ordRecId;
    
    public RMS_viewServiceRequestCtrlr(ApexPages.StandardController stdController) {
        if(!test.isRunningTest()){
            stdController.addFields(new List<String>{'RecordType','Id','RecordType.Name','Lock_Service_Request__c'});           
        }
        
        this.o = (Order)stdController.getRecord();
        
        ordRecId = [select id, RecordType.Name, RecordTypeId from Order where id = :ApexPages.currentPage().getParameters().get('id')].id;
        
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        updateSTURL = '/apex/RMS_updateServiceType?id=' + o.Id;
        editRedirect ='/apex/RMS_editServiceRequest?id='+o.Id;
        
        Schema.DescribeSObjectResult r = RbA_Work_Order__c.sObjectType.getDescribe();
        String workOrderKeyPrefix = r.getKeyPrefix();
        
        String ordId = o.id;
        list<Order> theOrd = [SELECT Id, AccountId, Status, RecordType.Name, Store_Location__c, OrderNumber, OpportunityId, BillToContactId, RecordTypeId FROM Order WHERE Id =:ordId ];
        
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
        
        String endURL =                     '&orderId='+o.Id+
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
        
        serviceOrderVisitRecordTypeURL = '/apex/RMS_createVisitWorkOrder?type=visit'+endURL;
        serviceOrderActionsRecordTypeURL =  '/apex/RMS_createActionsWorkOrder?type=actions'+endURL;                
        serviceOrderLSWPRecordTypeURL = '/apex/RMS_createActionsWorkOrder?type=lswp'+endURL;        
        serviceOrderPaintStainRecordTypeURL = '/apex/RMS_createActionsWorkOrder?type=paintStain'+endURL;         
        serviceOrderPermitRecordTypeURL = '/apex/RMS_createActionsWorkOrder?type=permit'+endURL;
        serviceOrderCollectionsRecordTypeURL = '/apex/RMS_createActionsWorkOrder?type=collections'+endURL;                                    
        
    }
    
    List<RbA_Work_Order__c> visitWOs;
    public List<RbA_Work_Order__c> getvisitWOs() {
        if(ordRecId != null) {
            visitWOs = [SELECT Id, Work_Order_Status__c,Work_Order_Type__c,Confirmed_Appt_w_Customer__c,Appointment_Duration__c, Owner.Name
                        FROM RbA_Work_Order__c 
                        WHERE RecordType.DeveloperName = 'Visit' AND Sold_Order__r.id=:ordRecId];
        }
        return visitWOs;
    } 
    
    List<RbA_Work_Order__c> actionWOs;
    public List<RbA_Work_Order__c> getactionWOs() {
        if(ordRecId != null) {
            actionWOs = [SELECT Id, Work_Order_Status__c,Work_Order_Type__c,Confirmed_Appt_w_Customer__c,Owner.Name
                         FROM RbA_Work_Order__c 
                         WHERE RecordType.DeveloperName != 'Visit' AND Sold_Order__r.id=:ordRecId];
        }
        return actionWOs;
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
    
    public PageReference orderRedirect(){
        PageReference newPage = null;
        
        
        
        If (o.RecordType.Name == 'CORO Service'){
            If(o.Lock_Service_Request__c == TRUE){
                newPage = new PageReference('/apex/RMS_viewServiceRequestLocked?id='+ o.Id);
            } else {
                newPage = new PageReference('/apex/RMS_viewServiceRequest?id='+ o.Id);                    
            }
        } else {
            newPage = new PageReference('/'+ o.Id);
            newPage.getParameters().put('nooverride','1');
        }
        
        newPage.setRedirect(true);
        return newPage;
        
        
    }  
    
    public PageReference updateServiceType(){
        PageReference newPage;
        newPage = new PageReference('/apex/RMS_updateServiceType?id='+o.id);
        newPage.setRedirect(true); 
        return newPage;
    } 
    
        public PageReference editServiceRequest(){
        PageReference newPage;
        newPage = new PageReference('/apex/RMS_editServiceRequest?id='+o.id);
        newPage.setRedirect(true); 
        return newPage;
    } 
    
    
}
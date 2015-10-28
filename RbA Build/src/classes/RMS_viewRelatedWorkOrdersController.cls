public with sharing class RMS_viewRelatedWorkOrdersController {
	
	public list<SVMXC__Service_Order__c> workOrdersList = new list<SVMXC__Service_Order__c>();
	public list<SVMXC__Service_Order__c> getWorkOrders() {
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
	
	public string serviceOrderVisitRecordTypeURL{get;set;}
	public string serviceOrderActionsRecordTypeURL{get;set;}
	
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
		//list<RecordType> serviceOrderVisitRecordType = [SELECT id FROM RecordType WHERE SobjectType = 'SVMXC__Service_Order__c' AND Name = 'Visit'];
    	//list<RecordType> serviceOrderActionsRecordType = [SELECT id FROM RecordType WHERE SobjectType = 'SVMXC__Service_Order__c' AND Name = 'Actions'];
    	
    	serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'SVMXC__Service_Order__c');
    	serviceOrderActionsRecordTypeId = UtilityMethods.retrieveRecordTypeId('Actions', 'SVMXC__Service_Order__c');
    	serviceOrderPermitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Permit', 'SVMXC__Service_Order__c');
    	
    	String ordId = ord.id;
    	
    	
    	//TODO: Get rid of dynamic and set record type var
    	String woQuery=	'SELECT id, '+ 
    					'Name, '+ 
    					'Sold_Order__c, '+
    					'SVMXC__Work_Order_Scheduling_Status__c, '+
    					'Type_image__c, '+
    					'SVMXC__Scheduled_Date_Time__c, '+
    					'SVMXC__Group_Member__c, '+
    					'SVMXC__Order_Status__c, '+
    					'Owner.Name, '+
    					'SVMXC__Order_Type__c '+
    					
    					'FROM SVMXC__Service_Order__c WHERE Sold_Order__c =: ordId';
		
		if(strurl.Contains('Visit')){
			//String visitRecordType = serviceOrderVisitRecordType[0].id;
			woQuery = woQuery+' AND RecordTypeId = :serviceOrderVisitRecordTypeId';
		
		}else if(strurl.Contains('Actions')){
			//String actionsRecordType = serviceOrderActionsRecordType[0].id;
			
			woQuery = woQuery+' AND (RecordTypeId = :serviceOrderActionsRecordTypeId';
			woQuery = woQuery+' OR RecordTypeId = :serviceOrderPermitRecordTypeId)';
		}
		system.debug('ads woQuery: '+woQuery);
		workOrdersList = Database.query(woQuery);
		
		
		
		//building strings to use as URL for create new Workorder
		Schema.DescribeSObjectResult r = SVMXC__Service_Order__c.sObjectType.getDescribe();
		String workOrderKeyPrefix = r.getKeyPrefix();
		
		list<Order> theOrd = [SELECT Id, AccountId, OrderNumber FROM Order WHERE Id =:ordId ];
		
		list<Account> relatedAccount = [SELECT 	Name,
												BillingStreet,
								    			BillingCity,
								    			BillingState,
								    			BillingPostalCode, 
								    			BillingCountry
								    			FROM Account WHERE Id = :theOrd[0].AccountId];
		
		
		map<String, Field_IDs__c> Field_IDs_map = Field_IDs__c.getAll(); 
		Field_IDs__c workOrderFieldIds = Field_IDs_map.get('Work Order');
		
		String baseURL = 	'/'+workOrderKeyPrefix+'/e?'+
											'CF'+workOrderFieldIds.Sold_Order__c+'='+theOrd[0].OrderNumber+
											'&CF'+workOrderFieldIds.Sold_Order__c+'_lkid='+Ord.Id+
											
											'&CF'+workOrderFieldIds.Company__c+'='+relatedAccount[0].Name+
											'&CF'+workOrderFieldIds.Company__c+'_lkid='+relatedAccount[0].Id+
											
											'&'+workOrderFieldIds.Street__c+'='+relatedAccount[0].BillingStreet+
											'&'+workOrderFieldIds.City__c+'='+relatedAccount[0].BillingCity+
											'&'+workOrderFieldIds.State__c+'='+relatedAccount[0].BillingState+
											'&'+workOrderFieldIds.Zip__c+'='+relatedAccount[0].BillingPostalCode+
											'&'+workOrderFieldIds.Country__c+'='+relatedAccount[0].BillingCountry+
											'&ent='+workOrderFieldIds.Object_ID__c+
											'&retURL=%2F'+Ord.Id+
											'&isdtp=v4';
											
		serviceOrderVisitRecordTypeURL = baseURL + '&RecordType='+serviceOrderVisitRecordTypeId;								
		serviceOrderActionsRecordTypeURL = baseURL + '&RecordType='+serviceOrderActionsRecordTypeId;										
							
											
		serviceOrderVisitRecordTypeURL = 	'/apex/RMS_createVisitWorkOrder?'+ 
											'orderId='+Ord.Id+
											'&accountId='+relatedAccount[0].Id+
											'&billingStreet='+relatedAccount[0].BillingStreet+
											'&billingCity='+relatedAccount[0].BillingCity+
											'&billingPostalCode='+relatedAccount[0].BillingState+
											'&billingCountry='+relatedAccount[0].BillingCountry;						
		 
	}
	
	

}
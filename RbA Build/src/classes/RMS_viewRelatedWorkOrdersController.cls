public with sharing class RMS_viewRelatedWorkOrdersController {
	
	public list<SVMXC__Service_Order__c> workOrdersList = new list<SVMXC__Service_Order__c>();
	public list<SVMXC__Service_Order__c> getWorkOrders() {
        return workOrdersList;
    }
	public string getView(){
		return 'View';
	}
	public String strurl; 
/******* Set up Standard Controller for Purchase_Order__c  *****************/
 	private Apexpages.StandardController standardController;
 	private final Order ord;
	
	
	//Constructor
	public RMS_viewRelatedWorkOrdersController(ApexPages.StandardController stdController) {
		this.ord = (Order)stdController.getRecord();
		
		strurl = ApexPages.currentPage().getUrl();
		strurl = strurl.split('apex/')[1];
		
		list<RecordType> serviceOrderVisitRecordType = [SELECT id FROM RecordType WHERE SobjectType = 'SVMXC__Service_Order__c' AND Name = 'Visit'];
    	list<RecordType> serviceOrderActionsRecordType = [SELECT id FROM RecordType WHERE SobjectType = 'SVMXC__Service_Order__c' AND Name = 'Actions'];
    	
    	String ordId = ord.id;
    	
    	String woQuery=	'SELECT id, '+ 
    					'Name, '+ 
    					'Sold_Order__c, '+
    					'SVMXC__Work_Order_Scheduling_Status__c, '+
    					'Type_image__c, '+
    					'SVMXC__Scheduled_Date_Time__c, '+
    					'SVMXC__Group_Member__c, '+
    					'SVMXC__Order_Status__c, '+
    					'Owner.Name '+
    					
    					'FROM SVMXC__Service_Order__c WHERE Sold_Order__c =: ordId';
		
		if(strurl.Contains('Visit') && serviceOrderVisitRecordType.size() > 0){
			String visitRecordType = serviceOrderVisitRecordType[0].id;
			woQuery = woQuery+' AND RecordTypeId = :visitRecordType';
		
		}else if(strurl.Contains('Actions') && serviceOrderActionsRecordType.size() > 0 ){
			String actionsRecordType = serviceOrderActionsRecordType[0].id;
			woQuery = woQuery+' AND RecordTypeId = :actionsRecordType';
		}
		system.debug('ads woQuery: '+woQuery);
		workOrdersList = Database.query(woQuery);
		
		 
	}


}
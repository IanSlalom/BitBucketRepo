public with sharing class RMS_createWorkOrderController {
	
	
	public string woType {get;set;}
	public string orderId {get;set;}
	public string accountId{get;set;}
	public string billingStreet{get;set;}
	public string billingCity{get;set;}
	public string billingState{get;set;}
	public string billingPostalCode{get;set;}
	public string billingCountry{get;set;}
	public string hoa{get;set;}
	public string historical{get;set;}
	public string permit{get;set;}
	public string opportunity{get;set;}
	public string woId{get;set;}
	public string woName{get;set;}
	
	public string woRTid;

/******* Set up Standard Controller for Purchase_Order__c  *****************/
	private Apexpages.StandardController standardController;
	private final SVMXC__Service_Order__c wo;
	
	
	//Constructor
	public RMS_createWorkOrderController(ApexPages.StandardController stdController) {
		this.wo = (SVMXC__Service_Order__c)stdController.getRecord();
		map<string, string> urlParam = ApexPages.currentPage().getParameters();

		orderId = urlParam.get('orderId');
		accountId = urlParam.get('accountId');
		billingStreet = urlParam.get('billingStreet');
		billingCity = urlParam.get('billingCity');
		billingPostalCode = urlParam.get('billingPostalCode');
		billingCountry = urlParam.get('billingCountry');
		billingState = urlParam.get('billingState');
		woType = urlParam.get('type');
		
		opportunity = urlParam.get('relatedOpp');
		
		permit = urlParam.get('permit');
		hoa = urlParam.get('hoa');
		historical = urlParam.get('historical');
		
		woName = wo.Name;
		
		if(woType == 'visit'){
			woRTid = UtilityMethods.retrieveRecordTypeId('Visit', 'SVMXC__Service_Order__c');
			wo.RecordTypeId = woRTid;
		}else if(woType == 'actions'){
			woRTid = UtilityMethods.retrieveRecordTypeId('Actions', 'SVMXC__Service_Order__c');
			wo.RecordTypeId  = woRTid;
		}else if(woType == 'lead'){
			woRTid = UtilityMethods.retrieveRecordTypeId('Lead', 'SVMXC__Service_Order__c');
			wo.RecordTypeId = woRTid;
		}else if(woType == 'paintStain'){
			woRTid = UtilityMethods.retrieveRecordTypeId('Paint_Stain', 'SVMXC__Service_Order__c');
			wo.RecordTypeId = woRTid; 
		}else if(woType == 'permit'){
			woRTid = UtilityMethods.retrieveRecordTypeId('Permit', 'SVMXC__Service_Order__c');
			wo.RecordTypeId = woRTid;
			if(permit != null && permit != ''){
				wo.Municipality__c = permit;
			}		
		}
	}
	

	public PageReference save() {
		wo.Sold_Order__c = orderId;
		wo.SVMXC__Company__c = accountId;
		wo.SVMXC__Street__c = billingStreet;
		wo.SVMXC__City__c = billingCity;
		wo.SVMXC__State__c = billingState;
		wo.SVMXC__Zip__c = billingPostalCode;
		wo.SVMXC__Country__c = billingCountry;
		
		wo.Opportunity__c = opportunity;
		if(hoa != null && hoa != '' && wo.SVMXC__Order_Type__c == 'HOA'){
			wo.Municipality__c = hoa;
		}else if(historical != null && historical != '' && wo.SVMXC__Order_Type__c == 'Historical'){
			wo.Municipality__c = historical;
		}
		
		
		wo.RecordTypeId = woRTid;
		
		insert wo;
		
		// Used for redirecting to the view page from javascript
		woId = wo.Id;
		
		return null;
	} 
		
}
public with sharing class RMS_createWorkOrderController {
	
	/*
	Sold_Order__c	orderId
	
	Company__c		accountId
	
	Street__c		BillingStreet
	City__c			BillingCity
	State__c		BillingState
	Zip__c			BillingPostalCode
	Country__c		BillingCountry
	*/
	
	public string orderId {get;set;}
	public string accountId{get;set;}
	public string billingStreet{get;set;}
	public string billingCity{get;set;}
	public string billingState{get;set;}
	public string billingPostalCode{get;set;}
	public string billingCountry{get;set;}
	public string woId{get;set;}
	public string woName{get;set;}

/******* Set up Standard Controller for Purchase_Order__c  *****************/
	private Apexpages.StandardController standardController;
	private final SVMXC__Service_Order__c wo;
	
	
	//Constructor
	public RMS_createWorkOrderController(ApexPages.StandardController stdController) {
		this.wo = (SVMXC__Service_Order__c)stdController.getRecord();
		wo.RecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'SVMXC__Service_Order__c');
		map<string, string> urlParam = ApexPages.currentPage().getParameters();

		orderId = urlParam.get('orderId');
		accountId = urlParam.get('accountId');
		billingStreet = urlParam.get('billingStreet');
		billingCity = urlParam.get('billingCity');
		billingPostalCode = urlParam.get('billingPostalCode');
		billingCountry = urlParam.get('billingCountry');
		billingState = urlParam.get('billingState');
		woName = wo.Name;
	}
	
	
	
	public PageReference save() {
		wo.Sold_Order__c = orderId;
		wo.SVMXC__Company__c = accountId;
		wo.SVMXC__Street__c = billingStreet;
		wo.SVMXC__City__c = billingCity;
		wo.SVMXC__State__c = billingState;
		wo.SVMXC__Zip__c = billingPostalCode;
		wo.SVMXC__Country__c = billingCountry;
		
		wo.RecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'SVMXC__Service_Order__c');
		
		insert wo;
		
		// Used for redirecting to the view page from javascript
		woId = wo.Id;
		
		return null;
	} 
		
}
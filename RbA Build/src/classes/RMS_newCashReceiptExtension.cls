/*******************************************************//**

@class	  RMS_newCashReceiptExtension

@brief	  Extension for redirecting the user when clicking the New payment list button

	Redirects the user directly to a misc cash receipt page depending on if it's linked
	to an order, bypassing the record type selector

@author	 Creston Kuenzi (Slalom.CDK)

@version	2015-2-11  Slalom.CDK
	Created

@see		RMS_newCashReceiptExtensionTest

@copyright  (c)2016 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/

public with sharing class RMS_newCashReceiptExtension {

	/******* Set up Standard Controller for Payment__c  *****************/
	private  Payment__c thePayment;
	private  List<Payment__c> paymentList;
	
	public RMS_newCashReceiptExtension(ApexPages.StandardSetController stdController) {
		this.paymentList = (List<Payment__c>)stdController.getRecords();
        	System.Debug('*****************this.paymentList=' +this.paymentList);	

			this.paymentList = new List<Payment__c>();
			this.thePayment = new Payment__c(); 
			this.paymentList.add(thePayment);

	}

	public String testStoreLocation;

	/******* redirect method  *****************/
	public PageReference redirect() {

		// Retrieve the key prefix for the payment object and insert it into the page reference
		Schema.DescribeSObjectResult r = Payment__c.sObjectType.getDescribe();
		String keyPrefix = r.getKeyPrefix();        
		PageReference p = new PageReference('/' +keyPrefix +'/e');

		// Get all of the url parameters from the current url and put them in the new url
        Map<String, String> m = p.getParameters();
        m.putAll(ApexPages.currentPage().getParameters());

        	System.Debug('*****************thePayment.Order__c=' +thePayment.Order__c);
		// If there is an order, redirect to deposit, otherwise redirect to misc cash receipt
		if (thePayment.Order__c == null) {
        	m.put('RecordType', UtilityMethods.RecordTypeFor('Payment__c', 'Misc_Cash_Receipt'));

			// If a test is running just set the store name, otherwise get it from the current user
			String storeLocationName = (Test.isRunningTest()) ? 	testStoreLocation : [SELECT Default_Store_Location__c FROM User WHERE Id =: UserInfo.getUserId()].Default_Store_Location__c;


			if (String.isBlank(storeLocationName)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.STORE_LOCATION_IS_BLANK_USER)); //
				return null;
			}
			
			for (Account thisStore : [SELECT Id, Name FROM Account WHERE Name =: storeLocationName]) {
        			// TODO:   This parameter will need to be updated after pushing to build and production
         			m.put('CF00N6100000Br7Y0', thisStore.Name);	
         			m.put('CF00N6100000Br7Y0_lkid', thisStore.Id);	
			}
			
			if (m.get('CF00N6100000Br7Y0') == null) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.STORE_LOCATION_IS_BLANK_USER)); //
				return null;
			}
			


		} 
		else {
        	m.put('RecordType', UtilityMethods.RecordTypeFor('Payment__c', 'Deposit'));
        	for (Order theOrder : [SELECT Store_Location__r.Name, Store_Location__c FROM Order WHERE Id =: thePayment.Order__c]) {
        		if (theOrder.Store_Location__c == null) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.STORE_LOCATION_IS_BLANK_PAYMENT)); //
					return null;
        		} 
        		else {
        			// TODO:   This parameter will need to be updated after pushing to build and production
         			m.put('CF00N6100000Br7Y0', theOrder.Store_Location__r.Name);	
         			m.put('CF00N6100000Br7Y0_lkid', theOrder.Store_Location__c);	
        		}
        	}		
		}
        m.put('nooverride', '1');
        return p; 
	}
	
}
/*******************************************************//**

@class	  RMS_newLaborRedirectExtension

@brief	  Extension for redirecting the user when clicking the New labor button

	Redirects the user directly to a labor or misc reimbursement page depending on if it's linked
	to a work order, bypassing the record type selector

@author	 Creston Kuenzi (Slalom.CDK)

@version	2015-12-29  Slalom.CDK
	Created

@see		RMS_newLaborRedirectExtensionTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/

public with sharing class RMS_newLaborRedirectExtension {

	/******* Set up Standard Controller for Labor__c  *****************/
	private final Labor__c theLabor;
	
	public RMS_newLaborRedirectExtension(ApexPages.StandardController stdController) {
		this.theLabor = (Labor__c)stdController.getRecord();
		if (this.theLabor == null)
			this.theLabor = new Labor__c(); 
	}

	public String testStoreLocation;

	/******* redirect method  *****************/
	public PageReference redirect() {

		// Retrieve the key prefix for the labor object and insert it into the page reference
		Schema.DescribeSObjectResult r = Labor__c.sObjectType.getDescribe();
		String keyPrefix = r.getKeyPrefix();        
		PageReference p = new PageReference('/' +keyPrefix +'/e');

		// Get all of the url parameters from the current url and put them in the new url
        Map<String, String> m = p.getParameters();
        m.putAll(ApexPages.currentPage().getParameters());

		// If there is a work order, redirect to labor, otherwise redirect to misc reimbursement
		if (theLabor.Related_Work_Order__c == null) {
        	m.put('RecordType', UtilityMethods.RecordTypeFor('Labor__c', 'Misc_Reimbursement'));

			// If a test is running just set the store name, otherwise get it from the current user
			String storeLocationName = (Test.isRunningTest()) ? 	testStoreLocation :
																	[SELECT Default_Store_Location__c FROM User WHERE Id =: UserInfo.getUserId()].Default_Store_Location__c;


			if (String.isBlank(storeLocationName)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.STORE_LOCATION_IS_BLANK_USER)); //
				return null;
			}
			
			for (Account thisStore : [SELECT Id, Name FROM Account WHERE Name =: storeLocationName]) {         			m.put('CF00N6100000Br7TE', thisStore.Name);	
         			m.put('CF00N6100000Br7TE_lkid', thisStore.Id);	
			}
			
			if (m.get('CF00N6100000Br7TE') == null) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.STORE_LOCATION_IS_BLANK_USER)); //
				return null;
			}

		} else {
        	m.put('RecordType', UtilityMethods.RecordTypeFor('Labor__c', 'Labor'));			

        	for (RbA_Work_Order__c theWorkOrder : [SELECT Sold_Order__r.Store_Location__r.Name, Sold_Order__r.Store_Location__c FROM RbA_Work_Order__c WHERE Id =: theLabor.Related_Work_Order__c]) {
        		if (theWorkOrder.Sold_Order__r.Store_Location__c == null) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.STORE_LOCATION_IS_BLANK_LABOR)); //
					return null;
        		} 
        		else { 
         			m.put('CF00N6100000Br7TE', theWorkOrder.Sold_Order__r.Store_Location__r.Name);	
         			m.put('CF00N6100000Br7TE_lkid', theWorkOrder.Sold_Order__r.Store_Location__c);	
        		}
        	}		
		}
        m.put('nooverride', '1');
        return p;
	}
	
}
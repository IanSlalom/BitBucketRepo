/*******************************************************//**

@class	  RMS_newMiscLaborExtension

@brief	  Extension for redirecting the user when clicking the New Misc Labor button

	Redirects the user directly to a labor or misc reimbursement page depending on if it's linked
	to a work order, bypassing the record type selector

@author	 Creston Kuenzi (Slalom.CDK)

@version	2015-2-12  Slalom.CDK
	Created

@see		RMS_newMiscLaborExtensionTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/

public with sharing class RMS_newMiscLaborExtension {

	/******* Set up Standard Controller for Labor__c  *****************/
	private  Labor__c theLabor;
	private  List<Labor__c> LaborList;
	
	public RMS_newMiscLaborExtension(ApexPages.StandardSetController stdController) {
		this.LaborList = (List<Labor__c>)stdController.getRecords();

		if (this.LaborList.isEmpty()) {
			this.LaborList = new List<Labor__c>();
			this.theLabor = new Labor__c(); 
			this.LaborList.add(theLabor);
		}
		else {
			this.theLabor = this.LaborList[0];
		}

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
			String storeLocationName = (Test.isRunningTest()) ? 	testStoreLocation : [SELECT Default_Store_Location__c FROM User WHERE Id =: UserInfo.getUserId()].Default_Store_Location__c;


			if (String.isBlank(storeLocationName)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.STORE_LOCATION_IS_BLANK_USER)); //
				return null;
			}
			
			for (Account thisStore : [SELECT Id, Name FROM Account WHERE Name =: storeLocationName]) {
        			// TODO:   This parameter will need to be updated after pushing to build and production
         			m.put('CF00N6100000Br7TE', thisStore.Name);	
         			m.put('CF00N6100000Br7TE_lkid', thisStore.Id);	
			}
			
			if (m.get('CF00N6100000Br7TE') == null) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.STORE_LOCATION_IS_BLANK_USER)); //
				return null;
			}

		} else {
        	m.put('RecordType', UtilityMethods.RecordTypeFor('Labor__c', 'Labor'));			

		}
        m.put('nooverride', '1');
        return p;
	}
	
}
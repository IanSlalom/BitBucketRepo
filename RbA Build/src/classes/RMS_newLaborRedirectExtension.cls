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
		} else {
        	m.put('RecordType', UtilityMethods.RecordTypeFor('Labor__c', 'Labor'));			
		}
        m.put('nooverride', '1');
        return p;
	}
	
}
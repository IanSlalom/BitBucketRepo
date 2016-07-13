/*******************************************************//**

@class	  RMS_newMiscLaborExtensionTest

@brief	  Extension for redirecting the user when clicking the New misc labor list button

	Redirects the user directly to a misc reimbursement page depending on if it's linked
	to an order, bypassing the record type selector

@author	 Creston Kuenzi (Slalom.CDK)

@version	2015-7-13  Slalom.CDK
	Created

@see		RMS_newMiscLaborExtension

@copyright  (c)2016 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_newMiscLaborExtensionTest {

	/*******************************************************
					redirectNoOrderTest
	*******************************************************/
	static testmethod void redirectNoOrderTest(){
		TestUtilityMethods utility = new TestUtilityMethods(); 
		
		utility.createOrderTestRecords();

		Labor__c l = new Labor__c();
		List<Labor__c> lList = new List<Labor__c>();
		lList.add(l);

		PageReference pageRef = Page.RMS_newMiscLabor;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(new List<Labor__c>());
		RMS_newMiscLaborExtension customController  = new RMS_newMiscLaborExtension(stdController);
				
		// test with store location
		customController.testStoreLocation = '77 - Twin Cities, MN';				
		customController.redirect();

		// test with null store location
		customController.testStoreLocation = null;				
		customController.redirect();
		
	}
	/*******************************************************
					redirectTestWithLabor
	*******************************************************/
	static testmethod void redirectTestWithLabor(){
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.createOrderTestRecords();

		Labor__c l = new Labor__c();
		List<Labor__c> lList = new List<Labor__c>();
		lList.add(l);

		PageReference pageRef = Page.RMS_newMiscLabor;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(llist);
		RMS_newMiscLaborExtension customController  = new RMS_newMiscLaborExtension(stdController);
				
		// test with store location
		customController.testStoreLocation = '77 - Twin Cities, MN';				
		customController.redirect();

		// test with null store location
		customController.testStoreLocation = null;				
		customController.redirect();


	}
	
}
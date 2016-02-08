/*******************************************************//**

@class	RMS_newLaborRedirectExtensionTest

@brief	Test Class for RMS_newLaborRedirectExtensionTest

@author  Creston Kuenzi (Slalom.CDK)

@version	2015-2-2  Slalom.CDK
	Created.

@see		RMS_newLaborRedirectExtension

@copyright  (c)2016 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_newLaborRedirectExtensionTest {

	/*******************************************************
					redirectTestWithOrder
	*******************************************************/
	static testmethod void redirectTestFromOrder(){
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.createOrderTestRecords();

		Labor__c l = new Labor__c();
		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
//		insert theWorkOrder; 

//		l.Related_Work_Order__c = theWorkOrder.Id;


		PageReference pageRef = Page.RMS_prodConfigRedirect;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardController stdController = new ApexPages.StandardController(l);
		RMS_newLaborRedirectExtension customController  = new RMS_newLaborRedirectExtension(stdController);
				
		customController.redirect();
		
		
		// remove the store location from order and retest
		soldOrder.Store_Location__c = null;
		update soldOrder;
		ApexPages.StandardController stdController2 = new ApexPages.StandardController(l);
		RMS_newLaborRedirectExtension customController2  = new RMS_newLaborRedirectExtension(stdController2);
				
		customController2.redirect();		

	}
	/*******************************************************
					redirectTestWithoutWorkOrder
	*******************************************************/
	static testmethod void redirectTestWithoutWorkOrder(){
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.createOrderTestRecords();

		Labor__c l = new Labor__c();

		PageReference pageRef = Page.RMS_prodConfigRedirect;
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController stdController = new ApexPages.StandardController(l);
		RMS_newLaborRedirectExtension customController  = new RMS_newLaborRedirectExtension(stdController);
		
		// test with store location
		customController.testStoreLocation = '77 - Twin Cities, MN';				
		customController.redirect();

		// test with null store location
		customController.testStoreLocation = null;				
		customController.redirect();

	}
}
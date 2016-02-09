/*******************************************************//**

@class	RMS_newPaymentRedirectExtensionTest

@brief	Test Class for RMS_newPaymentRedirectExtensionTest

@author  Creston Kuenzi (Slalom.CDK)

@version	2015-2-2  Slalom.CDK
	Created.

@see		RMS_newPaymentRedirectExtension

@copyright  (c)2016 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_newPaymentRedirectExtensionTest {

	/*******************************************************
					redirectTestWithOrder
	*******************************************************/
	static testmethod void redirectTestFromOrder(){
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.createOrderTestRecords();

		Payment__c p = new Payment__c();
		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		p.Order__c = soldOrder.Id;


		PageReference pageRef = Page.RMS_newPaymentRedirect;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardController stdController = new ApexPages.StandardController(p);
		RMS_newPaymentRedirectExtension customController  = new RMS_newPaymentRedirectExtension(stdController);
				
		customController.redirect();
		
		
		// remove the store location from order and retest
		soldOrder.Store_Location__c = null;
		update soldOrder;
		ApexPages.StandardController stdController2 = new ApexPages.StandardController(p);
		RMS_newPaymentRedirectExtension customController2  = new RMS_newPaymentRedirectExtension(stdController2);
				
		customController2.redirect();		

	}
	/*******************************************************
					redirectTestWithoutOrder
	*******************************************************/
	static testmethod void redirectTestWithoutOrder(){
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.createOrderTestRecords();

		Payment__c p = new Payment__c();

		PageReference pageRef = Page.RMS_newPaymentRedirect;
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController stdController = new ApexPages.StandardController(p);
		RMS_newPaymentRedirectExtension customController  = new RMS_newPaymentRedirectExtension(stdController);
		
		// test with store location
		customController.testStoreLocation = '77 - Twin Cities, MN';				
		customController.redirect();

		// test with null store location
		customController.testStoreLocation = null;				
		customController.redirect();

	}
}
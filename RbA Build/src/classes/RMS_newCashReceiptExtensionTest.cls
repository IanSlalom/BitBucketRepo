/*******************************************************//**

@class	RMS_newCashReceiptExtensionTest

@brief	Test Class for RMS_newCashReceiptExtension

@author  Creston Kuenzi (Slalom.CDK)

@version	2015-7-13  Slalom.CDK
	Created.

@see		RMS_newCashReceiptExtension

@copyright  (c)2016 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_newCashReceiptExtensionTest {

	/*******************************************************
					redirectNoOrderTest
	*******************************************************/
	static testmethod void redirectNoOrderTest(){
		TestUtilityMethods utility = new TestUtilityMethods(); 
		
		utility.createOrderTestRecords();

		Payment__c p = new Payment__c();
		List<Payment__c> pList = new List<Payment__c>();
		pList.add(p);

		PageReference pageRef = Page.RMS_newCashReceipt;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(new List<Payment__c>());
		RMS_newCashReceiptExtension customController  = new RMS_newCashReceiptExtension(stdController);
				
		// test with store location
		customController.testStoreLocation = '77 - Twin Cities, MN';				
		customController.redirect();

		// test with null store location
		customController.testStoreLocation = null;				
		customController.redirect();
		
	}
	/*******************************************************
					redirectTestWithOrder
	*******************************************************/
	static testmethod void redirectTestWithOrder(){
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.createOrderTestRecords();

		Payment__c p = new Payment__c();
		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		p.Order__c = soldOrder.Id;
		List<Payment__c> pList = new List<Payment__c>();
		pList.add(p);
		
		PageReference pageRef = Page.RMS_newCashReceipt;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(pList);
		RMS_newCashReceiptExtension customController  = new RMS_newCashReceiptExtension(stdController);

		
		// test with store location
		customController.testStoreLocation = '77 - Twin Cities, MN';				
		customController.redirect();

		// test with null store location
		customController.testStoreLocation = null;				
		customController.redirect();

	}
}
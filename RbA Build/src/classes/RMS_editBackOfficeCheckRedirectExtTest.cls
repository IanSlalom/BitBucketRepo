/*******************************************************//**

@class	RMS_editBackOfficeCheckRedirectExtTest

@brief	Test Class for RMS_editBackOfficeCheckRedirectExt

@author  Creston Kuenzi (Slalom.CDK)

@version	2016-10-13  Slalom.CDK
	Created.

@see		RMS_editBackOfficeCheckRedirectExt

@copyright  (c)2016 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_editBackOfficeCheckRedirectExtTest {

	/*******************************************************
					redirectTestWithOrder
	*******************************************************/
	static testmethod void redirectTestFromOrder(){
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.createOrderTestRecords();

		Back_Office_Check__c b = new Back_Office_Check__c();
		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		b.Order__c = soldOrder.Id;


		PageReference pageRef = Page.RMS_editBackOfficeCheckRedirect;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardController stdController = new ApexPages.StandardController(b);
		RMS_editBackOfficeCheckRedirectExtension customController  = new RMS_editBackOfficeCheckRedirectExtension(stdController);
				
		customController.redirect();
		
	}
	/*******************************************************
					redirectTestWithoutOrder
	*******************************************************/
	static testmethod void redirectTestWithoutOrder(){
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.createOrderTestRecords();

		Back_Office_Check__c b = new Back_Office_Check__c();

		PageReference pageRef = Page.RMS_editBackOfficeCheckRedirect;
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController stdController = new ApexPages.StandardController(b);
		RMS_editBackOfficeCheckRedirectExtension customController  = new RMS_editBackOfficeCheckRedirectExtension(stdController);
		
		customController.redirect();

	}
}
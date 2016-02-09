/*******************************************************//**

@class	RMS_prodConfigRedirectExtensionTest

@brief	Test Class for RMS_prodConfigRedirectExtension

@author  Creston Kuenzi (Slalom.CDK)

@version	2015-2-9  Slalom.CDK
	Created.

@see		RMS_prodConfigRedirectExtension

@copyright  (c)2016 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_prodConfigRedirectExtensionTest {

	/*******************************************************
					redirectTestWithOrder
	*******************************************************/
	static testmethod void redirectTestFromOrder(){
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.createOrderTestRecords();

		Order soldOrder = [SELECT Id, Status, Pricebook2Id FROM Order WHERE Name = 'Sold Order 1'];


		PageReference pageRef = Page.RMS_prodConfigRedirect;
		Test.setCurrentPage(pageRef);

		ApexPages.StandardController stdController = new ApexPages.StandardController(soldOrder);
		RMS_prodConfigRedirectExtension customController  = new RMS_prodConfigRedirectExtension(stdController);
				
		customController.redirect();

	}
}
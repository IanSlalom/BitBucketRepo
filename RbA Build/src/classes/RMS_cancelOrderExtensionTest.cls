/*******************************************************//**

@class	RMS_cancelOrderExtensionTest

@brief	Test class for the RMS_cancelOrderExtension Controller extension

	Test class

@author  Creston Kuenzi (Slalom.CDK)

@version	2015-10-25  Slalom.CDK
	Created.

@see		RMS_cancelOrderExtensionTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_cancelOrderExtensionTest {

	/*******************************************************
					createTestRecords
	*******************************************************/
	static testmethod void createTestRecords(){
		
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.setUpConfigs();
		
		Account myAccount1 = utility.createVendorAccount('My Vendor Account 1 ');
		insert myAccount1;

		Account myAccount2 = new Account(	Name = 'RbA',
										AccountNumber = '1234567890',
										Phone = '(763) 555-2000'
									);
		insert myAccount2;

		
		Opportunity opp1 = utility.createOpportunity(myAccount1.id, 'Closed - Won');
		insert opp1;
		
		Pricebook2 pricebook1 =  utility.createPricebook2Name('Standard Price Book');
		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = myAccount1.id
		);
		
		
		insert product1;
		
		PricebookEntry pricebookEntry1 = utility.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = myAccount1.id, 
									EffectiveDate= Date.Today(), 
									Opportunity = opp1, 
									Status ='Draft', 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		
		Purchase_Order__c purchaseOrder1 = new Purchase_Order__c(Order__c = Order1.id);
		insert purchaseOrder1;		

		OrderItem orderItem1 = new OrderItem(OrderId = Order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100, Purchase_Order__c = purchaseOrder1.Id );
		insert orderItem1;		

	}
	
	/*******************************************************
					NoOrderIdTest
	*******************************************************/
	static testmethod void NoOrderIdTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];

		// Set up controller with an order Id and no PO Id
		PageReference pageRef = Page.RMS_cancelOrder;
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController stdController = new ApexPages.StandardController(soldOrder);
		RMS_cancelOrderExtension customController  = new RMS_cancelOrderExtension(stdController);

	}

	/*******************************************************
					CancelOrderTest
	*******************************************************/
	static testmethod void CancelOrderTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];

		// Set up controller with an order Id
		PageReference pageRef = Page.RMS_cancelOrder;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('id',soldOrder.id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(soldOrder);
		RMS_cancelOrderExtension customController  = new RMS_cancelOrderExtension(stdController);
		customController.cancelOrder();

		// Verify all POs are cancelled
		for (Purchase_Order__c cancelledPO :  [SELECT Id, Status__c FROM Purchase_Order__c WHERE Order__c =: soldOrder.Id]) {
			System.AssertEquals('Cancelled', cancelledPO.Status__c);		
		}

	}
}
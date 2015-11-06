/*******************************************************//**

@class	RMS_vendorPurchaseOrderControllerTest

@brief	Test Class for RMS_vendorPurchaseOrderController

@author  Anthony Strafaccia (Slalom.ADS)
@author  Creston Kuenzi (Slalom.CDK)

@version	2015-09-16  Slalom.ADS
	Created.
@version	2015-10-12  Slalom.CDK
	Added ability to add products manually and Cost PO Functionality.

@see		RMS_vendorPurchaseOrderController

@copyright  (c)2015 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/

@isTest
public with sharing class RMS_vendorPurchaseOrderControllerTest {
	
	/*******************************************************
					createTestRecords
	*******************************************************/
	static testmethod void createTestRecords(){
		
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.setUpConfigs();
		
		Account account1 = utility.createVendorAccount('Vendor Account 1 ');
		insert account1;

		Account account2 = new Account(	Name = 'RbA',
										AccountNumber = '1234567890',
										Phone = '(763) 555-2000'
									);
		insert account2;

		
		Opportunity opp1 = utility.createOpportunity(account1.id, 'Closed - Won');
		insert opp1;
		
		Pricebook2 pricebook1 =  utility.createPricebook2Name('Standard Price Book');
		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = account1.id
		);
		
		insert product1;
		
		PricebookEntry pricebookEntry1 = utility.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = account1.id, 
									EffectiveDate= Date.Today(), 
									Opportunity = opp1, 
									Status ='Draft', 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		
		OrderItem orderItem1 = new OrderItem(OrderId = Order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100 );
		insert orderItem1;		
	}
	
	/*******************************************************
					ConstructorTest
	*******************************************************/
	static testmethod void ConstructorTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Account vendorAccount = [SELECT Id FROM Account WHERE Name = 'Vendor Account 1 Test Account'];
		Purchase_Order__c po = new Purchase_Order__c();

		// Set up controller with an order Id and no PO Id
		PageReference pageRef = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('orderId',soldOrder.id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(po);
		RMS_vendorPurchaseOrderController customController  = new RMS_vendorPurchaseOrderController(stdController);
				
		Purchase_Order__c po2 = new Purchase_Order__c();
		insert po2;

		// Set up controller with no order Id but has a PO Id
		PageReference pageRef2 = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef2);
		ApexPages.CurrentPage().getparameters().put('id', po2.Id)		;
		ApexPages.StandardController stdController2 = new ApexPages.StandardController(po2);
		RMS_vendorPurchaseOrderController customController2  = new RMS_vendorPurchaseOrderController(stdController2);
		
	}

	/*******************************************************
					PageVariableTest
	*******************************************************/
	static testmethod void PageVariableTest(){

		// Set up controller with an order Id and no PO Id
		PageReference pageRef = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef);
		Purchase_Order__c po = new Purchase_Order__c();
		ApexPages.StandardController stdController = new ApexPages.StandardController(po);
		RMS_vendorPurchaseOrderController customController  = new RMS_vendorPurchaseOrderController(stdController);

		//public variables used on VF page
		customController.selectedVendor = 'vendor';
		customController.selectedVendorName = 'vendor';
		customController.selectedPricebook = 'vendor';
		customController.status = 'vendor';
		customController.poId = 'vendor';
	
		//public variables used in both new and edit PO
		customController.relatedOrder = new Order();
		customController.relatedOrderItems = new List<OrderItem>();
		customController.relatedProduct2IDList = new list<Id>();
		customController.relatedProducts = new List<Product2>();
		customController.vendorIdList = new list<Id>();
		customController.vendorsOnOrder = new list<Account>();
		customController.newProduct ='new product';

		//Test that the newOrderItems list is initialized with one item
		System.AssertEquals(1, customController.newOrderItems.size());

		// Test SOQL Filters for autocomplete is correct
		System.AssertEquals(' AND RecordTypeId = ', customController.vendorFilter);
		System.AssertEquals(UtilityMethods.retrieveRecordTypeId('Vendor', 'Account'), customController.vendorFilter2);
		System.AssertEquals(' AND Inventoried_Item__c = false AND IsActive = true AND Vendor__c =', customController.productFilter);

		customController.selectedVendor = 'selectedVendor';
		System.AssertEquals('selectedVendor', customController.productFilter2);

		// Test that orderId is blank
		System.AssertEquals('', customController.orderId);

		customController.newPurchaseOrder = false;
		customController.costPurchaseOrder = false;
	
		//public variables to be used in new PO
		customController.avaliableVendors = new list<SelectOption>();
		
		//public variables to create wrapper
		customController.orderItemWrapperList = new List<RMS_vendorPurchaseOrderController.OrderItemWrapper>();
		customController.orderItemIdToOrderItemMap = new Map<Id, OrderItem>();
		customController.accountIdToAccountMap = new Map<Id, Account>();
		customController.productIdToProductMap = new Map<Id, Product2>();
	
		customController.orderItemWrapperByVendor = new List<RMS_vendorPurchaseOrderController.OrderItemWrapper>();
		customController.orderItemWrapperNew = new List<RMS_vendorPurchaseOrderController.OrderItemWrapper>();

	
	}

	/*******************************************************
					SaveTest
	*******************************************************/
	static testmethod void SaveTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Account vendorAccount = [SELECT Id FROM Account WHERE Name = 'Vendor Account 1 Test Account'];
		Purchase_Order__c po = new Purchase_Order__c();
		OrderItem soldOrderItem = [SELECT Id FROM OrderItem WHERE OrderId =: soldOrder.Id LIMIT 1];
		soldOrderItem.Unit_Wholesale_Cost__c = 50;
		upsert soldOrderItem;

		// Set up controller with an order Id
		PageReference pageRef = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('orderId',soldOrder.id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(po);
		RMS_vendorPurchaseOrderController customController  = new RMS_vendorPurchaseOrderController(stdController);

		// Save with No Vendor, verify an error message is added
		customController.save();
		System.Assert(ApexPages.getMessages() != null);		

		// set the selected vendor to the vendor account id
		customController.selectedVendor = vendorAccount.Id;

		// Save with a vendor, 
		customController.save();	
		List<Purchase_Order__c> newPOList = [SELECT Id, Subtotal__c FROM Purchase_Order__c WHERE Order__c =: soldOrder.Id];
		//Verify the PO was inserted and the subtotal is (50*2)
		System.AssertEquals(1, newPOList.size());		
		System.AssertEquals(100, newPOList[0].Subtotal__c);

		// Set up another controller with no order Id
		PageReference pageRef2 = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef2);
		Purchase_Order__c po2 = new Purchase_Order__c();
		ApexPages.StandardController stdController2 = new ApexPages.StandardController(po2);
		RMS_vendorPurchaseOrderController customController2  = new RMS_vendorPurchaseOrderController(stdController2);

		customController2.selectedVendor = vendorAccount.Id;
		//TODO: Finish setting up data to add store location to user
		// Save with a vendor but no PO in the controller
//		customController2.save();

	}
		
//		RMS_vendorPurchaseOrderController.OrderItemWrapper orderWrapper = new RMS_vendorPurchaseOrderController.OrderItemWrapper();


	/*******************************************************
					AddProductTest
	*******************************************************/
	static testmethod void AddProductTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Account vendorAccount = [SELECT Id FROM Account WHERE Name = 'Vendor Account 1 Test Account'];
		Purchase_Order__c po = new Purchase_Order__c();
		Product2 testProduct =  [SELECT Id FROM Product2 WHERE Name = 'Test Product'];
		Pricebook2 testPricebook =  [SELECT Id FROM Pricebook2 WHERE Name = 'Standard Price Book'];
		
		// Set up controller with an order Id
		PageReference pageRef = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('orderId',soldOrder.id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(po);
		RMS_vendorPurchaseOrderController customController  = new RMS_vendorPurchaseOrderController(stdController);

		// Add Product with No Product, verify an error message is added
		customController.addproduct();
		System.Assert(ApexPages.getMessages() != null);	

		// Add product with wrong pricebook
		customController.newProduct = testProduct.Id;
		customController.selectedPricebook = testPricebook.Id;		
		customController.addproduct();

		// Add product with right pricebook
		customController.selectedPricebook = Test.getStandardPricebookId();		
		customController.addproduct();
	}

	/*******************************************************
					MiscButtonTest
	*******************************************************/
	static testmethod void MiscButtonTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Account vendorAccount = [SELECT Id FROM Account WHERE Name = 'Vendor Account 1 Test Account'];
		Purchase_Order__c po = new Purchase_Order__c();
		
		// Set up controller with an order Id
		PageReference pageRef = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('orderId',soldOrder.id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(po);
		RMS_vendorPurchaseOrderController customController  = new RMS_vendorPurchaseOrderController(stdController);

		// Methods without data set
		customController.cancel();
		customController.confirm();
		customController.releasePurchaseOrder();
		customController.checkReceived();

	}
}
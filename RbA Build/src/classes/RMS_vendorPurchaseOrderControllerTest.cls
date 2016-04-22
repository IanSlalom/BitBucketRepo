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

		Account dwelling = utility.createDwellingAccount('Dwelling Account');

		Account store = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
		dwelling.Store_Location__c = store.Id;
		insert dwelling;

		
		Opportunity opp1 = utility.createOpportunity(dwelling.id, 'Closed - Won');
		insert opp1;
	
		//Store_Configuration__c stconfig = new Store_Configuration__c(Store__c = store.Id);
		//insert stconfig;
		
		Financial_Account_Number__c fan = new Financial_Account_Number__c(Name ='Finan Acc');
		insert fan;
		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = account1.id,
			Cost_PO__c = true,
			isActive = true,
			Account_Number__c =  fan.Id
		);
		
		insert product1;
		
		PricebookEntry pricebookEntry1 = utility.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store.Id,
									Opportunity = opp1, 									
									RecordTypeId = UtilityMethods.RecordTypeFor('Order', 'CORO_Record_Type'),									
									Status ='Draft', 
									Pricebook2Id = Test.getStandardPricebookId()
								);		
		insert order1;
		OrderItem orderItem1 = new OrderItem(OrderId = Order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100 );
		insert orderItem1;		
		Vendor_Product__c vp = new Vendor_Product__c(Vendor__c = account1.Id, Product__c = product1.Id);
		insert vp;

	}
	
	/*******************************************************
					ConstructorTest
	*******************************************************/
	static testmethod void ConstructorTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id, Revenue_Recognized_Date__c FROM Order WHERE Name = 'Sold Order 1'];
		System.debug('ORDER REV REC' + soldOrder.Revenue_Recognized_Date__c);
		Account vendorAccount = [SELECT Id FROM Account WHERE Name = 'Vendor Account 1 Test Account'];
		Purchase_Order__c po = new Purchase_Order__c();

		// Set up controller with an order Id and no PO Id
		PageReference pageRef = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('orderId',soldOrder.id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(po);
		RMS_vendorPurchaseOrderController customController  = new RMS_vendorPurchaseOrderController(stdController);
		System.assert(customController.newPurchaseOrder);
		System.assertEquals(customController.po.Status__c,'In Progress');
		Purchase_Order__c po2 = new Purchase_Order__c();
		insert po2;
		System.debug('RELATEDORDER with fields ' + customController.relatedOrder);
		System.debug(customController.showInventoryWriteOff);
		System.assertEquals(customController.showInventoryWriteOff,false);


		soldOrder.Status = 'Job Closed';
		
		update soldOrder;
		customController  = new RMS_vendorPurchaseOrderController(stdController);
		system.AssertEquals(customController.status, 'rec');
		
		soldOrder.Revenue_Recognized_Date__c = Date.Today();
		soldOrder.Status = 'Job in Progress';
		update soldOrder;
		customController  = new RMS_vendorPurchaseOrderController(stdController);
		System.debug('RELATEDORDER with fields ' + customController.relatedOrder);
		System.debug(customController.showInventoryWriteOff);
		System.assertEquals(customController.showInventoryWriteOff,true);



		// Set up controller with no order Id but has a PO Id
		PageReference pageRef2 = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef2);
		ApexPages.CurrentPage().getparameters().put('id', po2.Id)		;
		ApexPages.StandardController stdController2 = new ApexPages.StandardController(po2);
		RMS_vendorPurchaseOrderController customController2  = new RMS_vendorPurchaseOrderController(stdController2);
		customController2.selectedVendor = vendorAccount.Id;
		customController2.costPurchaseOrder =true;
		System.assert(customController2.vendorProducts.contains(customController2.productItems[1].getvalue()));
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

  		customController.lineItemToCancel = 'lineitem';
  		customController.lineItemToReceive = 'lineitem';
  		customController.quantityReceived = 1;
  		customController.dateReceived = System.today();
  		Id myId = customController.storeId;
	
		//public variables used in both new and edit PO
		customController.relatedOrder = new Order();
		customController.relatedOrderItems = new List<OrderItem>();
		customController.relatedProduct2IDList = new list<Id>();
		customController.relatedProducts = new List<Product2>();
		customController.vendorsOnOrder = new list<Account>();
		customController.newProduct ='new product';
		
		//Test that the newOrderItems list is initialized with one item
		System.AssertEquals(1, customController.newOrderItems.size());


		// TODO: Add Assert
		List<SelectOption> productItems = customController.productItems;

		// TODO: Add Assert
		String vendorQueries = customController.vendorQueries;

		// TODO: Add Assert
		String vendorVariables = customController.vendorVariables;

		// TODO: Add Assert
		String productQueries = customController.productQueries;

		// TODO: Add Assert
		String productVariables = customController.productVariables;

		// TODO: Add Assert
		Set<Id> vendorProducts = customController.vendorProducts;

		// TODO: Add Assert
		List<Account> accounts = customController.accounts;

		// TODO: Add Assert
		List<Contact> contacts = customController.contacts;

		// TODO: Add Assert
		List<Product2> products = customController.products;

		// TODO: Add Assert
		List<Cost_Center__c> costCenters = customController.costCenters;

		// TODO: Add Assert
		String pageTitle = customController.pageTitle;

		// TODO: Add Assert
		String productText = customController.productText;

		// Test SOQL Filters for autocomplete is correct
//		System.AssertEquals(' AND RecordTypeId = ', customController.vendorFilter);
//		System.AssertEquals(UtilityMethods.retrieveRecordTypeId('Vendor', 'Account'), customController.vendorFilter2);
//		System.Debug('***************customController.productFilter=' +customController.productFilter);
		// not sure why this is failing, it matches exactly
//		System.AssertEquals(' AND Inventoried_Item__c = false  AND IsActive = true AND Vendor__c =', customController.productFilter);
//		System.Assert(customController.productFilter != null);

		customController.selectedVendor = 'selectedVendor';
//		System.AssertEquals('selectedVendor', customController.productFilter2);

		// Test that orderId is blank
		System.AssertEquals('', customController.orderId);

		customController.newPurchaseOrder = false;
		customController.costPurchaseOrder = false;
	
		//public variables to be used in new PO
		customController.availableVendors = new list<SelectOption>();
		
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

		//JETT-712 Verify PO Status is updated upon save if Status is Released, Estimated Ship Date is populated, and related OrderItems all have wholesale costs
		customController.po.Estimated_Ship_Date__c = System.Today();	
		customController.po.Status__c = 'Released';
		customController.save();
		System.assert(customController.po.Status__c == 'Confirmed');

		List<Purchase_Order__c> newPOList = [SELECT Id, Subtotal__c FROM Purchase_Order__c WHERE Order__c =: soldOrder.Id];

		// Set up another controller with no order Id
		PageReference pageRef2 = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef2);
		Purchase_Order__c po2 = new Purchase_Order__c();
		ApexPages.StandardController stdController2 = new ApexPages.StandardController(po2);
		RMS_vendorPurchaseOrderController customController2  = new RMS_vendorPurchaseOrderController(stdController2);

		//KR - Save with orderId isBlank
		customController2.selectedVendor = vendorAccount.Id;
		customController2.orderId = '';
		customController2.save();
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
		Id priceBookId = Test.getStandardPricebookId();
		
		// Set up controller with an order Id
		PageReference pageRef = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('orderId',soldOrder.id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(po);
		RMS_vendorPurchaseOrderController customController  = new RMS_vendorPurchaseOrderController(stdController);

		// Add Product with No Product, verify an error message is added
		customController.addproduct();
		System.Assert(ApexPages.getMessages() != null);	

		ApexPages.StandardController stdController2 = new ApexPages.StandardController(po);
		RMS_vendorPurchaseOrderController customController2  = new RMS_vendorPurchaseOrderController(stdController2);
		// Add product with wrong pricebook
		customController2.newProduct = testProduct.Id;
		customController2.selectedPricebook = priceBookId;		
		customController2.addproduct();
		Test.startTest();

		ApexPages.StandardController stdController3 = new ApexPages.StandardController(po);
		RMS_vendorPurchaseOrderController customController3  = new RMS_vendorPurchaseOrderController(stdController3);
		// Add product with right pricebook
		customController3.newProduct = testProduct.Id;
		customController3.selectedPricebook = Test.getStandardPricebookId();		
		customController3.addproduct();


		//Cover branch where costPurchaseOrder is true
		customController3.costPurchaseOrder = true;
		customController3.costCenter = null;
		customController3.addproduct();
		customController3.costCenter = '1';
		customController3.addproduct();
		customController3.storeLocationNumber = '';
		customController3.addproduct();
		customController3.storeLocationNumber = '1';
		customController3.addproduct();
		testProduct.Account_Number__c = null;
		update testProduct;
		customController3.addproduct();
		Test.stopTest();
	}

	/*******************************************************
					MiscButtonTest
	*******************************************************/
	static testmethod void MiscButtonTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id, Status FROM Order WHERE Name = 'Sold Order 1'];
		Account vendorAccount = [SELECT Id FROM Account WHERE Name = 'Vendor Account 1 Test Account'];
		Purchase_Order__c po = new Purchase_Order__c(Order__c = soldOrder.Id);
		insert po;
		OrderItem soldOrderItem = [SELECT Id FROM OrderItem WHERE OrderId =: soldOrder.Id LIMIT 1];
		soldOrderItem.NSPR__c = false;
		soldOrderItem.Verify_Item_Configuration__c = false;
		soldOrderItem.Purchase_Order__c = po.Id;
		update soldOrderItem;
		
		// Set up controller with an order Id
		PageReference pageRef = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('orderId',soldOrder.id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(po);
		RMS_vendorPurchaseOrderController customController  = new RMS_vendorPurchaseOrderController(stdController);

		// Methods without data set
		// TODO: Add Asserts
		customController.cancel();
		customController.confirm();

		customController.releasePurchaseOrder();
		System.assert(containsMessage(ApexPages.getMessages(),RMS_ErrorMessages.ORDER_STATUS_INVALID_FOR_PO_RELEASE));
		customController.relatedOrder.Status = 'Ready to Order';
		customController.po.Status__c = 'New';
		customController.releasePurchaseOrder();
		system.debug(apexPages.getMessages());
		System.assert(containsMessage(ApexPages.getMessages(),RMS_ErrorMessages.PO_STATUS_INVALID_FOR_PO_RELEASE));
		customController.po.Status__c = 'In Progress';
		customController.electronicOrder = true;
		customController.releasePurchaseOrder();
		System.assert(containsMessage(ApexPages.getMessages(),RMS_ErrorMessages.PO_LINE_ITEMS_INVALID_FOR_PO_RELEASE));
		customController.electronicOrder = false;
		customController.releasePurchaseOrder();
		System.assertEquals(customController.po.Status__c, 'Released');
	
		customController.cancelPurchaseOrder();
		customController.checkReceived();
		customController.updateCostCenters();
		customController.writeOff();
		customController.receive();
		customController.vendorCredit();
		
	}

	/*******************************************************
					cancelLineItemTest
	*******************************************************/
	static testmethod void cancelLineItemTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Account vendorAccount = [SELECT Id FROM Account WHERE Name = 'Vendor Account 1 Test Account'];
		Purchase_Order__c po = new Purchase_Order__c();
		OrderItem soldOrderItem = [SELECT Id FROM OrderItem WHERE OrderId =: soldOrder.Id LIMIT 1];
		
		// Set up controller with an order Id
		PageReference pageRef = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('orderId',soldOrder.id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(po);
		RMS_vendorPurchaseOrderController customController  = new RMS_vendorPurchaseOrderController(stdController);
		
		
		customController.lineItemToCancel = soldOrderItem.Id;

		PageReference newPageRef = customController.cancelLineItem();
	}

	/*******************************************************
					receiveLineItemsTest
	*******************************************************/
	static testmethod void receiveLineItems(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Account vendorAccount = [SELECT Id FROM Account WHERE Name = 'Vendor Account 1 Test Account'];
		Purchase_Order__c po = new Purchase_Order__c();
		OrderItem soldOrderItem = [SELECT Id, Pricebookentry.Product2.Name, Order.Store_Location__c, Order.AccountId, Order.EffectiveDate, Order.BillToContactId FROM OrderItem WHERE OrderId =: soldOrder.Id LIMIT 1];
		List<OrderItem> orderItemsToReceive = new List<OrderItem>{soldOrderItem}; 
		Set<Id> assetIds = new Set<Id>();
		soldOrderItem.Date_Received__c = System.today();
		soldOrderItem.Quantity_To_Receive__c = 1;
		soldOrderItem.Unit_Wholesale_Cost__c = 100;
		update soldOrderItem;
//		orderItemsToReceive.add(soldOrderItem);	
		// Set up controller with an order Id
		PageReference pageRef = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('orderId',soldOrder.id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(po);
		RMS_vendorPurchaseOrderController customController  = new RMS_vendorPurchaseOrderController(stdController);
		
		// TODO: Add system asserts		
		System.assert(customController.receiveLineItems(orderItemsToReceive, assetIds) != null);
		orderItemsToReceive[0].Quantity_to_Receive__c = null;
		orderItemsToReceive[0].Date_Received__c = System.today();
		customController.receiveLineItems(orderItemsToReceive, assetIds);
		System.debug(ApexPages.getMessages());
		system.assert(containsMessage(ApexPages.getMessages(),RMS_ErrorMessages.REC_DATE_QUANTITY_REQUIRED));
		orderItemsToReceive[0].Quantity_to_Receive__c = 1;
		orderItemsToReceive[0].Unit_Wholesale_Cost__c = null;
		orderItemsToReceive = new List<OrderItem>{soldOrderItem}; 
		customController.receiveLineItems(orderItemsToReceive, assetIds);
		system.assert(containsMessage(ApexPages.getMessages(),RMS_ErrorMessages.WHOLESALE_COST_REQUIRED));
		


	}


	/*******************************************************
					writeOffLineItemsTest
	*******************************************************/
	static testmethod void writeOffLineItemsTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Account vendorAccount = [SELECT Id FROM Account WHERE Name = 'Vendor Account 1 Test Account'];
		Purchase_Order__c po = new Purchase_Order__c();
		OrderItem soldOrderItem = [SELECT Id, Pricebookentry.Product2.Name, Order.Store_Location__c, Order.AccountId, Order.EffectiveDate, Order.BillToContactId FROM OrderItem WHERE OrderId =: soldOrder.Id LIMIT 1];
		List<OrderItem> orderItemsToWriteOff = new List<OrderItem>{soldOrderItem}; 
		Set<Id> assetIds = new Set<Id>();
		soldOrderItem.Date_Written_Off__c = System.today();
		soldOrderItem.Quantity_To_Write_Off__c  = 1;
		soldOrderItem.Unit_Wholesale_Cost__c = 100;
		update soldOrderItem;
		// Set up controller with an order Id
		PageReference pageRef = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('orderId',soldOrder.id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(po);
		RMS_vendorPurchaseOrderController customController  = new RMS_vendorPurchaseOrderController(stdController);
			
		System.assert(customController.writeOffLineItems(orderItemsToWriteOff, assetIds) != null);
		orderItemsToWriteOff[0].Date_Written_Off__c = System.Today();
		orderItemsToWriteOff[0].Quantity_To_Write_Off__c = null;
		customController.writeOffLineItems(orderItemsToWriteOff, assetIds);
		System.assert(containsMessage(ApexPages.getMessages(),RMS_ErrorMessages.WRITEOFF_DATE_QUANTITY_REQUIRED));
		orderItemsToWriteOff[0].Date_Written_Off__c = System.Today();
		orderItemsToWriteOff[0].Quantity_To_Write_Off__c = 1;
		soldOrderItem.Unit_Wholesale_Cost__c = null;
		customController.writeOffLineItems(orderItemsToWriteOff, assetIds);
		System.assert(containsMessage(ApexPages.getMessages(),RMS_ErrorMessages.WHOLESALE_COST_REQUIRED));

	}

	/*******************************************************
					writeOffLineItemsTest
	*******************************************************/
	static testmethod void vendorCreditTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Account vendorAccount = [SELECT Id FROM Account WHERE Name = 'Vendor Account 1 Test Account'];
		Purchase_Order__c po = new Purchase_Order__c();
		OrderItem soldOrderItem = [SELECT Id, Pricebookentry.Product2.Name, Order.Store_Location__c, Order.AccountId, Order.EffectiveDate, Order.BillToContactId FROM OrderItem WHERE OrderId =: soldOrder.Id LIMIT 1];
		List<OrderItem> orderItemsForVendorCredit = new List<OrderItem>{soldOrderItem}; 
		Set<Id> assetIds = new Set<Id>();
		soldOrderItem.Date_Vendor_Credit__c = System.today();
		soldOrderItem.Vendor_Credit_to_Receive__c  = 50;
		soldOrderItem.Unit_Wholesale_Cost__c = 100;
		update soldOrderItem;
		// Set up controller with an order Id
		PageReference pageRef = Page.RMS_viewPurchaseOrder;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('orderId',soldOrder.id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(po);
		RMS_vendorPurchaseOrderController customController  = new RMS_vendorPurchaseOrderController(stdController);

		System.assert(customController.vendorCreditLineItems(orderItemsForVendorCredit, assetIds) != null);
		orderItemsForVendorCredit[0].Date_Vendor_Credit__c = System.Today();
		orderItemsForVendorCredit[0].Vendor_Credit_to_Receive__c = null;
		customController.vendorCreditLineItems(orderItemsForVendorCredit, assetIds);
		System.assert(containsMessage(ApexPages.getMessages(),RMS_ErrorMessages.VENDORCREDIT_DATE_AMOUNT_REQUIRED));

	}

	@isTest
	public static void testOrderItemWrapperClass(){		
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Account vendorAccount = [SELECT Id FROM Account WHERE Name = 'Vendor Account 1 Test Account'];
		OrderItem soldOrderItem = [SELECT Id FROM OrderItem WHERE OrderId =: soldOrder.Id LIMIT 1];
		Product2 testProduct =  [SELECT Id FROM Product2 WHERE Name = 'Test Product'];
	
		RMS_vendorPurchaseOrderController.OrderItemWrapper wrap = new RMS_vendorPurchaseOrderController.OrderItemWrapper();
		wrap = new RMS_vendorPurchaseOrderController.OrderItemWrapper(soldOrderItem,vendorAccount,testProduct);
		System.assertEquals(wrap.orderItem,soldOrderItem);	
		System.assertEquals(wrap.account,vendorAccount);	
		System.assertEquals(wrap.product,testProduct);	
		wrap = new RMS_vendorPurchaseOrderController.OrderItemWrapper(soldOrderItem);
		wrap.quantityReceived = 1;
		wrap.dateReceived = System.today();
		System.assertEquals(wrap.orderItem,soldOrderItem);		
	}

	static boolean containsMessage(List<ApexPages.Message> pageMessages, String message){
		boolean returnVal = false;
		for(ApexPages.Message msg : pageMessages){
			if(msg.getDetail().contains(message)){
				returnVal = true;
				break;
			}
		}
		return returnVal;
	}
}
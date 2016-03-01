/*******************************************************//**

@class	RMS_viewOrderProductsControllerTests

@brief	Test Class for RMS_viewOrderProductsController

@author  Kai Ruan (Slalom.CDK)

@version	2015-2-22  Slalom.CDK
	Created.

@see		RMS_viewOrderProductsController

@copyright  (c)2016 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_viewOrderProductsControllerTests {
	
	@testSetup static void setupData() {
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();
		//Account acc = utility.createAccount('1');
		//insert acc;
		Account dwelling = utility.createDwellingAccount('Dwelling Account');
		Account store = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
		dwelling.Store_Location__c = store.Id;
		insert dwelling;
		Product2 masterProduct = new Product2(	name = 'master',
												IsActive = true, 
												recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Master_Product')
											);
		Product2 miscProduct = new Product2(	name = 'misc',
												IsActive = true, 
												recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Misc_Job_and_Unit_Charges')
											);
		Product2 miscProduct2 = new Product2(	name = 'misc2',
												IsActive = true, 
												recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Misc_Job_and_Unit_Charges')
											);
		Product2 materialProduct = new Product2(	name = 'material',
													IsActive = true, 
													recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Construction_Materials')
												);
		List<Product2> products = new List<Product2>{masterProduct,miscProduct,miscProduct2,materialProduct};
		insert products;
		PricebookEntry pricebookEntryMaster= utility.createPricebookEntry(Test.getStandardPricebookId(), masterProduct.id);		
		PricebookEntry pricebookEntryMisc = utility.createPricebookEntry(Test.getStandardPricebookId(), miscProduct.id);	
		PricebookEntry pricebookEntryMisc2 = utility.createPricebookEntry(Test.getStandardPricebookId(), miscProduct2.id);	
		PricebookEntry pricebookEntryMaterial = utility.createPricebookEntry(Test.getStandardPricebookId(), materialProduct.id);	
		List<PriceBookEntry> pbEntries = new List<PricebookEntry>{pricebookEntryMaster,pricebookEntryMisc,pricebookEntryMisc2,pricebookEntryMaterial};
		insert pbEntries;
		//utility.createOrderTestRecords();
		Order order =  new Order(	Name='Sold Order 1', 
									AccountId = dwelling.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store.Id,							
									Status ='Draft', 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order;
		OrderItem orderItemMaster = new OrderItem(OrderId = Order.id, PricebookentryId = pricebookEntryMaster.Id, Quantity = 2, UnitPrice = 100 );
		insert orderItemMaster;
		OrderItem orderItemMisc = new OrderItem(OrderId = Order.id, PricebookentryId = pricebookEntryMisc.Id, Quantity = 2, UnitPrice = 100, Parent_Order_Item__c = orderItemMaster.id);
		OrderItem orderItemMisc2 = new OrderItem(OrderId = Order.id, PricebookentryId = pricebookEntryMisc2.Id, Quantity = 2, UnitPrice = 100, Parent_Order_Item__c = orderItemMaster.id);
		OrderItem orderItemMaterial = new OrderItem(OrderId = Order.id, PricebookentryId = pricebookEntryMaterial.Id, Quantity = 2, UnitPrice = 100 );
		insert new List<OrderItem>{orderItemMisc,orderItemMisc2, orderItemMaterial};
		}
	
	@isTest static void testController() {
		Order order = [select Id,Pricebook2Id from Order where Name ='Sold Order 1'];
		RMS_viewOrderProductsController controller = new RMS_viewOrderProductsController(new ApexPages.StandardController(order));
		System.assert(controller.OrderItemWrappers.size() == 1);
		OrderItem orderItemMaster = [Select Id from OrderItem where Pricebookentry.Product2.Name = 'master'];
		system.assertEquals(controller.OrderItemWrappers[0].OrderItem.Id,orderItemMaster.Id);
		OrderItem orderItemMisc = [Select Id from OrderItem where Pricebookentry.Product2.Name = 'misc'];
		system.assertEquals(controller.OrderItemWrappers[0].RelatedItems[0].Id,orderItemMisc.Id);
		OrderItem orderItemMisc2 = [Select Id from OrderItem where Pricebookentry.Product2.Name = 'misc2'];
		system.assertEquals(controller.OrderItemWrappers[0].RelatedItems[1].Id,orderItemMisc2.Id);
		System.assertEquals(controller.OrderItemWrappers[0].showRelatedItems,false);
		controller.orderItemToToggle = orderItemMaster.Id;
		controller.toggleShowRelatedItems();
		System.assertEquals(controller.OrderItemWrappers[0].showRelatedItems,true);
	}
	
}
/*******************************************************//**

@class	RMS_viewOrdersControllerTests

@brief	Test Class for RMS_viewOrdersController

@author  Kai Ruan (Slalom)

@version	2016-3-11  Slalom
	Created.

@see		RMS_viewOrdersController

@copyright  (c)2016 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_viewOrdersControllerTests {
	public static Id serviceRecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order');
   	public static Id CORORecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Record_Type', 'Order');
	@testSetup static void setupData() {
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();
		Account dwelling = utility.createDwellingAccount('Dwelling Account');
		Account store = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
		dwelling.Store_Location__c = store.Id;
		insert dwelling;

		Order serviceOrder =  new Order(	Name='Sold Order 1', 
									AccountId = dwelling.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store.Id,							
									Status ='Draft', 
									Pricebook2Id = Test.getStandardPricebookId(),
									recordtypeId = serviceRecordTypeId
								);
		insert serviceOrder;

		Order  COROOrder =  new Order(	Name='Sold Order 2', 
									AccountId = dwelling.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store.Id,							
									Status ='Draft', 
									Pricebook2Id = Test.getStandardPricebookId(),
									recordtypeId = CORORecordTypeId
								);
		insert COROOrder;

				}
	
	@isTest static void testControllerForServiceOrders(){
		Order order = [select Id,Pricebook2Id,RecordTypeId from Order where Name ='Sold Order 1'];
		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        Account acc = [Select Id,Store_Location__c from Account where Name != 'RbA' AND Name != 'Unassigned Account' AND RecordTypeId =: dwellingRT];
		Test.setCurrentPage(new PageReference('/apex/RMS_viewServiceOrders?Id='+acc.Id));
		RMS_viewOrdersController controller = new RMS_viewOrdersController(new ApexPages.StandardController(acc));
		System.assertEquals(controller.orders.size(), 1);
		System.assertEquals(controller.orders[0].Id, order.Id);	
	}

	@isTest static void testControllerForCOROOrders(){
		Order order = [select Id,Pricebook2Id,RecordTypeId from Order where Name ='Sold Order 2'];
		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        Account acc = [Select Id,Store_Location__c from Account where Name != 'RbA' AND Name != 'Unassigned Account' AND RecordTypeId =: dwellingRT];
		Test.setCurrentPage(new PageReference('/apex/RMS_viewCOROOrders?Id='+acc.Id));
		RMS_viewOrdersController controller = new RMS_viewOrdersController(new ApexPages.StandardController(acc));
		System.assertEquals(controller.orders.size(), 1);
		System.assertEquals(controller.orders[0].Id, order.Id);	
	}
	
}
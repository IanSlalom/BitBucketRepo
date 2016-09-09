@isTest
private class TaskTriggerHandlerTests {
	
	@testSetup static void setupData() {
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
		
		List<Order> orderList =  new List<Order>{ new Order(	Name='TMNeeded', 
									AccountId = dwelling.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store.Id,
									Opportunity = opp1,									
									Status ='Draft', 
									Tech_Measure_Status__c = 'New',
									Pricebook2Id = Test.getStandardPricebookId()
								)};		
		insert orderList;

		List<OrderItem> oiList = new List<OrderItem>();
		for(Order o: orderList){
			oiList.add(new OrderItem(OrderId = o.Id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100 ));
		}
		insert oiList;
		
		//System.debug('OLIST' +  [Select Status, Tech_Measure_Status__c, Install_Order_Status__c, Apex_Context__C from Order]);
		
	}
	
	
	@isTest static void testUpdateOrderStatus(){
		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        Account dwelling = [Select Id from Account where Name != 'RbA' AND Name != 'Unassigned Account' AND RecordTypeId =: dwellingRT];
		List<Order> soldOrder = [Select Id, Name, Status, Tech_Measure_Status__c,Install_Order_Status__c, Store_Location__c, OpportunityId, OwnerId
								 from Order where accountId =: dwelling.Id 
												  and Name = 'TMNeeded'];
		System.assertEquals(soldOrder.size(),1);
		String priorStatus = 'Draft';
		Test.startTest();
		soldOrder[0].Status = 'On Hold';
		soldOrder[0].Prior_Status__c = 'Draft';
		update soldOrder;
		List<Task> onHoldTasks = [Select Id, WhatId, OwnerId, recordTypeId from Task Where WhatId =: soldOrder[0].Id];
		System.assertEquals(onHoldTasks.size(),1);
		System.assertEquals(onHoldTasks[0].OwnerId, soldOrder[0].OwnerId);
		System.assertEquals(onHoldTasks[0].recordTypeId, UtilityMethods.retrieveRecordTypeId('On_Hold', 'Task'));
		onHoldTasks[0].Status = 'Completed';
		update onHoldTasks;
		soldOrder = [Select Id, Name, Status from Order where Id =: soldOrder[0].Id];
		System.assertEquals(soldOrder[0].Status, priorStatus);
		Test.stopTest();
	}
}
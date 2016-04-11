@isTest
private class PurchaseOrderTriggerHandlerTests {
	
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
		
		List<Order> orderList =  new List<Order>{ new Order(	Name='Order1', 
									AccountId = dwelling.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store.Id,
									Opportunity = opp1,									
									Status ='Draft', 
									Tech_Measure_Status__c = 'New',
									Pricebook2Id = Test.getStandardPricebookId()
								),	new Order(	Name='Order2', 
									AccountId = dwelling.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									Tech_Measure_Status__c = 'New', 
									Pricebook2Id = Test.getStandardPricebookId()
								),	new Order(Name='Order3', 
									AccountId = dwelling.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store.Id,
									Opportunity = opp1, 									
									Status ='Draft', 
									Install_Order_Status__c = 'New',
									Pricebook2Id = Test.getStandardPricebookId()
								)};		
		insert orderList;

		List<OrderItem> oiList = new List<OrderItem>{new OrderItem(OrderId = OrderList[0].Id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100 ),
				new OrderItem(OrderId = OrderList[1].Id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100 ),
				new OrderItem(OrderId = OrderList[2].Id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100 )};
		insert oiList;

	}

	@isTest static void testeupdateOrderStatusToOrderReleased() {
		Account dwelling = [Select Id from Account where Name = 'Dwelling Account'];
		List<Order> orderList = [Select Id, Name, Status, Tech_Measure_Status__c,Install_Order_Status__c from Order where accountId =: dwelling.Id];
		for(Order o: orderList){
			o.Status = 'Ready to Order';
		}
		update orderList;
		List<Purchase_Order__c> poList = new List<Purchase_Order__c>();
		//Add two Purchase Orders for each Order in the list. Order1 will have one PO updated to Released, but have a related PO in New Status.
		//Order2 will have a related PO in Cancelled Status, and Order3 will have a related PO in Released status.
		for(Order o: orderList){
			if(o.Name == 'Order1'){
				poList.add(new Purchase_Order__c(Order__c = o.Id, Status__c = 'In Progress'));
				poList.add(new Purchase_Order__c(Order__c = o.Id, Status__c = 'New'));
			}else if(o.Name == 'Order2'){
				poList.add(new Purchase_Order__c(Order__c = o.Id, Status__c = 'In Progress'));
				poList.add(new Purchase_Order__c(Order__c = o.Id, Status__c = 'Cancelled'));
			}else if(o.Name == 'Order3'){
				poList.add(new Purchase_Order__c(Order__c = o.Id, Status__c = 'In Progress'));
				poList.add(new Purchase_Order__c(Order__c = o.Id, Status__c = 'Released'));
			}
		}
		insert poList;

		Map<Id, Purchase_Order__c> oldMap = new Map<Id, Purchase_Order__c>();
		Map<Id, Purchase_Order__c> newMap = new Map<Id, Purchase_Order__c>();
		for(Purchase_Order__c po: poList){
			if(po.Status__c == 'In Progress'){
				oldMap.put(po.Id, po);
				Purchase_Order__c poClone = po.clone(true, true, false, false);
				poClone.Status__c = 'Released';
				newMap.put(poClone.Id, poClone);
			}
		}

		System.assertEquals(newMap.keySet().size(),oldMap.keySet().size());

		PurchaseOrderTriggerHandler handler = new PurchaseOrderTriggerHandler(false,200);
		handler.updateOrderStatusToOrderReleased(oldMap, newMap);
		
		orderList = [Select Id, Name, Status, Tech_Measure_Status__c,Install_Order_Status__c from Order where accountId =: dwelling.Id];
		for(Order o: orderList){
			if(o.Name == 'Order1'){
				System.assertEquals('Ready to Order',o.Status);
			}else if(o.Name == 'Order2'){
				System.assertEquals('Order Released',o.Status);
			}else if(o.Name == 'Order3'){
				System.assertEquals('Order Released',o.Status);
			}
		}
	}

	@isTest static void testeupdateOrderStatusToInstallNeeded() {
		Account dwelling = [Select Id from Account where Name = 'Dwelling Account'];
		List<Order> orderList = [Select Id, Name, Status, Tech_Measure_Status__c,Install_Order_Status__c from Order where accountId =: dwelling.Id];
		for(Order o: orderList){
			o.Status = 'Order Released';
		}
		update orderList;
		List<Purchase_Order__c> poList = new List<Purchase_Order__c>();
		//Add two Purchase Orders for each Order in the list. Order1 will have one PO updated to Confirmed, but have a related PO in New Status.
		//Order2 will have a related PO in Cancelled Status, and Order3 will have a related PO in Confirmed status.
		for(Order o: orderList){
			if(o.Name == 'Order1'){
				poList.add(new Purchase_Order__c(Order__c = o.Id, Status__c = 'In Progress'));
				poList.add(new Purchase_Order__c(Order__c = o.Id, Status__c = 'New'));
			}else if(o.Name == 'Order2'){
				poList.add(new Purchase_Order__c(Order__c = o.Id, Status__c = 'In Progress'));
				poList.add(new Purchase_Order__c(Order__c = o.Id, Status__c = 'Cancelled'));
			}else if(o.Name == 'Order3'){
				poList.add(new Purchase_Order__c(Order__c = o.Id, Status__c = 'In Progress'));
				poList.add(new Purchase_Order__c(Order__c = o.Id, Status__c = 'Confirmed'));
			}
		}
		insert poList;

		Map<Id, Purchase_Order__c> oldMap = new Map<Id, Purchase_Order__c>();
		Map<Id, Purchase_Order__c> newMap = new Map<Id, Purchase_Order__c>();
		for(Purchase_Order__c po: poList){
			if(po.Status__c == 'In Progress'){
				oldMap.put(po.Id, po);
				Purchase_Order__c poClone = po.clone(true, true, false, false);
				poClone.Status__c = 'Confirmed';
				newMap.put(poClone.Id, poClone);
			}
		}

		System.assertEquals(newMap.keySet().size(),oldMap.keySet().size());

		PurchaseOrderTriggerHandler handler = new PurchaseOrderTriggerHandler(false,200);
		handler.updateOrderStatusToInstallNeeded(oldMap, newMap);
		
		orderList = [Select Id, Name, Status, Tech_Measure_Status__c,Install_Order_Status__c from Order where accountId =: dwelling.Id];
		for(Order o: orderList){
			if(o.Name == 'Order1'){
				System.assertEquals('Order Released',o.Status);
			}else if(o.Name == 'Order2'){
				System.assertEquals('Install Needed',o.Status);
			}else if(o.Name == 'Order3'){
				System.assertEquals('Install Needed',o.Status);
			}
		}
	}
	
}
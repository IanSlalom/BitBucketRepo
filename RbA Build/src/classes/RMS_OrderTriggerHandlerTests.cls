@isTest
private class RMS_OrderTriggerHandlerTests {
	
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
								),	new Order(	Name='TMScheduled', 
									AccountId = dwelling.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									Tech_Measure_Status__c = 'New', 
									Pricebook2Id = Test.getStandardPricebookId()
								),	new Order(Name='InstallScheduled', 
									AccountId = dwelling.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store.Id,
									Opportunity = opp1, 									
									Status ='Draft', 
									Install_Order_Status__c = 'New',
									Pricebook2Id = Test.getStandardPricebookId()
								),	new Order(Name='InstallNeeded', 
									AccountId = dwelling.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store.Id,
									Opportunity = opp1, 									
									Status ='Draft', 
									Install_Order_Status__c = 'New',
									Pricebook2Id = Test.getStandardPricebookId()
								)};		
		insert orderList;

		List<OrderItem> oiList = new List<OrderItem>();
		for(Order o: orderList){
			oiList.add(new OrderItem(OrderId = o.Id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100 ));
		}
		insert oiList;
		for(Order o: orderList){
			//o.Apex_Context__c = true;
			if(o.Name == 'TMNeeded'){
				o.Status = 'Tech Measure Needed';
			}else if(o.Name == 'TMScheduled'){
				o.Status = 'Tech Measure Scheduled';
			}else if(o.Name == 'InstallScheduled'){
				o.Status = 'Install Scheduled';
			}else if(o.Name == 'InstallNeeded'){
				o.Status = 'Install Needed';
			}
		}
		update orderList;
		//System.debug('OLIST' +  [Select Status, Tech_Measure_Status__c, Install_Order_Status__c, Apex_Context__C from Order]);
		
	}
	
	@isTest static void testUpdateOrderStatus() {
		Account dwelling = [Select Id from Account where Name = 'Dwelling Account'];
		Map<Id,Order> oldMap = new Map<Id,Order>([Select Id, Status, Tech_Measure_Status__c,Install_Order_Status__c from Order where accountId =: dwelling.Id]);
		Map<Id,Order> newMap = new Map<Id,Order>();
		for(Order o: oldMap.values()){
			Order clonedOrder = o.clone(true,true,false,false);
			if(o.Status == 'Tech Measure Needed'){
				clonedOrder.Tech_Measure_Status__c = 'Scheduled';
			}else if(o.Status == 'Tech Measure Scheduled'){
				clonedOrder.Tech_Measure_Status__c = 'Complete';
			}else if(o.Status == 'Install Needed'){
				clonedOrder.Install_Order_Status__c = 'Scheduled';
			}else if(o.Status == 'Install Scheduled'){
				clonedOrder.Install_Order_Status__c = 'Complete';
			}
			newMap.put(o.Id, clonedOrder);
		}

		System.assertEquals(newMap.keySet().size(),oldMap.keySet().size());

		RMS_OrderTriggerHandler handler = new RMS_OrderTriggerHandler(false,200);
		handler.updateOrderStatus(oldMap, newMap);
		for(Order o: newMap.values()){
			if(o.Tech_Measure_Status__c == 'Scheduled'){
				System.assert(o.Status == 'Tech Measure Scheduled');
			}else if(o.Tech_Measure_Status__c == 'Complete'){
				System.assert(o.Status == 'Ready to Order');
			}else if(o.Install_Order_Status__c == 'Scheduled'){
				System.assert(o.Status == 'Install Scheduled');
			}else if(o.Install_Order_Status__c == 'Complete'){
				System.assert(o.Status == 'Install Complete');
			}
		}

/*

		//Used to verify the Apex Context field is set to false by workflow rule
		for(Order o: oldMap.values()){
			if(o.Status == 'Tech Measure Needed'){
				o.Tech_Measure_Status__c = 'Scheduled';
			}else if(o.Status == 'Tech Measure Scheduled'){
				o.Tech_Measure_Status__c = 'Complete';
			}else if(o.Status == 'Install Scheduled'){
				o.Install_Order_Status__c = 'Complete';
			}
		}
		update oldMap.values();
		List<Order> orderl = [Select Status, Tech_Measure_Status__c, Install_Order_Status__c, Apex_Context__C from Order];
		System.debug('ORDERS ' + orderl);*/
	}
	
}
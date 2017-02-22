@isTest
public with sharing class RMS_salesOrderManagerTest {

	static testmethod void positiveActivationOfOpportunity(){ 
		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;
		
		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();
		Profile p = [SELECT Id FROM Profile WHERE Name='RMS-Sales']; 
		// setup configuration stuff
		Datetime tmApptTime = Datetime.now().addDays(5);

		User u = tUtil.createUser(p.id);
		insert u;
		tUtil.createSalesAppt(u.Id, tmApptTime, false, false);
		// build out the container
		Account store1 = [SELECT id, Active_Store_Configuration__c FROM Account Where Name = '77 - Twin Cities, MN'][0];
		Id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        Account dwelling = [Select Id from Account where Name != 'RbA' AND Name != 'Unassigned Account' AND RecordTypeId =: dwellingRT];
		Opportunity opp = [select Id, StageName, rSuite_Id__c from Opportunity where AccountId =: dwelling.id];
		opp.StageName = 'Sold';

		// create pricebook
		Pricebook2 pb = tutil.createPricebook2('SATestPB2', store1.Active_Store_Configuration__c);
		insert pb;
		
		// create store finance programs and store discounts
		Store_Discount__c sd = new Store_Discount__c(Name='testStoreDiscount', Active__c = true, Buy_Number__c = 1, Discount_Amount__c = 1, 
			Store_Configuration__c = store1.Active_Store_Configuration__c, Discount_Product__c = 'Unit', 
			RecordTypeId = UtilityMethods.retrieveRecordTypeId('dollar_off', 'Store_Discount__c'));
		insert sd;
		//Store_Finance_Program__c sf = new Store_Finance_Program__c(Name = 'testStoreFinanceProgram', Active__c = true, );
		
		//create existing quote
		Quote quoteToUpdate = tUtil.createQuote(opp.Id, pb.Id);
		quoteToUpdate.isSold__c = true;
		insert quoteToUpdate;
		// create existing quote lines
		QuoteLineItem qli1 = tUtil.createQLIMasterChildProducts(pb.Id, quotetoUpdate.Id);
		insert qli1;
		QuoteLineItem qli2 = tUtil.createQLIMasterChildProducts(pb.Id, quotetoUpdate.Id);
		insert qli2;
		// create the existing quote discount
		Quote_Discount__c qd = new Quote_Discount__c(Discount_Amount__c = 1.0, Per_Unit_Discount__c = 1.0,
			rSuite_Id__c = 'qd-1234-rsuiteId', Status__c = 'Applied', Quote__c = quoteToUpdate.Id, Store_Discount__c = sd.id);
		insert qd;
		System.assert(qd.Id != null);
		
		Test.startTest();
		update opp;
		Test.stopTest();
		List<Order> allOrders = [select Id, Name, OpportunityId from Order];
		System.debug('$$$$$ ' + allOrders);
		List<Order> orders = [SELECT Id FROM Order WHERE OpportunityId = :opp.id];
		List<OrderItem> ioList = [select Id from OrderItem where Order.OpportunityId = :opp.Id];
		List<Order_Discount__c> odList = [select Id, Per_Unit_Discount__c, rSuite_Id__c, Status__c, Store_Discount__c from Order_Discount__c where Order__r.OpportunityId = :opp.Id];
		
		System.assertEquals(orders.size(), 1);
		System.assert(ioList.size() == 2);
		System.assert(odList.size() == 1);
		System.assert(odList[0].Per_Unit_Discount__c == qd.Per_Unit_Discount__c);
		System.assert(odList[0].Store_Discount__c == qd.Store_Discount__c);
		System.assert(odList[0].rSuite_Id__c == qd.rSuite_Id__c);
		
		
	}
	
	
	static testmethod void noDiscountActivationOfOpportunity(){ 
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
		TestUtilityMethods utilities = new TestUtilityMethods();
		utilities.setUpConfigs();
		Account store = [SELECT Id FROM account WHERE Name ='77 - Twin Cities, MN'];

		//Creating Account (Needed for RMS_Queue_Settings__c)
		Account account1 =  new Account(Name = 'Test Account1',
	        AccountNumber = '1234567890',
	        Phone = '(763) 555-2000',
		 	Store_Location__c = store.id, 
			BillingStreet = '123 happy Ln',
			BillingCity = 'Sunshine',
			BillingState = 'Minnesota',
			BillingStateCode = 'MN',
			BillingPostalCode = '55449', 
			BillingCountry = 'United States',
			RecordTypeId = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account') ); 
	 	insert account1;	
		
		Account vend1 = utilities.createVendorAccount('Vendor Account 1');
		insert vend1;

		Product2 product1 = new Product2(
			Name='Test Product', 
			Vendor__c = vend1.id
		);

		insert product1;
		
		PricebookEntry pricebookEntry1 = utilities.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;

		Opportunity opp = new Opportunity(
											Name = 'Test Opportunity',
											StageName = 'New',
											AccountId = account1.id,
											Store_Location__c = store.id,
											Pricebook2Id = Test.getStandardPricebookId(),
											CloseDate = Date.Today()
										);
		insert opp;
		
		Quote quote = utilities.createQuote(opp.id,Test.getStandardPricebookId());
		insert quote;
				
		Contact contact1 = utilities.createContact(account1.id, '1');
		insert contact1;
		
		OpportunityContactRole ocr = new OpportunityContactRole(IsPrimary = true, 
																OpportunityId = opp.id, 
																ContactId = contact1.id
																);
		insert ocr;
		
		OpportunityLineItem oli = utilities.createOpportunityLineItem(opp.id, pricebookEntry1.id);
		insert oli;

		opp.StageName = 'Sold';
		update opp;
		
		list<Order> orders = [SELECT Id FROM Order WHERE OpportunityId = :opp.id];
		
		System.assertEquals(orders.size(), 1);
		
	}
	
	
	
	
	static testmethod void noPrimaryContactActivationOfOpportunity(){ 
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
		TestUtilityMethods utilities = new TestUtilityMethods();
		utilities.setUpConfigs();
		Account store = [SELECT Id FROM account WHERE Name ='77 - Twin Cities, MN'];

		//Creating Account (Needed for RMS_Queue_Settings__c)
		Account account1 =  new Account(Name = 'Test Account1',
	        AccountNumber = '1234567890',
	        Phone = '(763) 555-2000',
		 	Store_Location__c = store.id, 
			BillingStreet = '123 happy Ln',
			BillingCity = 'Sunshine',
			BillingState = 'Minnesota',
			BillingStateCode = 'MN',
			BillingPostalCode = '55449', 
			BillingCountry = 'United States',
			RecordTypeId = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account') ); 
	 	insert account1;	
		
		Account vend1 = utilities.createVendorAccount('Vendor Account 1');
		insert vend1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = vend1.id
		);

		insert product1;
		
		PricebookEntry pricebookEntry1 = utilities.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;

		Opportunity opp = new Opportunity(
											Name = 'Test Opportunity',
											StageName = 'New',
											AccountId = account1.id,
											Store_Location__c = store.id,
											Pricebook2Id = Test.getStandardPricebookId(),
											CloseDate = Date.Today()
										);
		insert opp;
		
		Quote quote = utilities.createQuote(opp.id,Test.getStandardPricebookId());
		insert quote;
		
		Contact contact1 = utilities.createContact(account1.id, '1');
		insert contact1;
		
		OpportunityContactRole ocr = new OpportunityContactRole(IsPrimary = false, 
																OpportunityId = opp.id, 
																ContactId = contact1.id
																);
		insert ocr;
						
		opp.StageName = 'Sold';
		update opp;
		
		list<Order> orders = [SELECT Id FROM Order WHERE OpportunityId = :opp.id];
		
		System.assertEquals(orders.size(), 1);
		
	}
	
	static testmethod void noContactActivationOfOpportunity(){ 
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
		TestUtilityMethods utilities = new TestUtilityMethods();
		utilities.setUpConfigs();
		Account store = [SELECT Id FROM account WHERE Name ='77 - Twin Cities, MN'];

		//Creating Account (Needed for RMS_Queue_Settings__c)
		Account account1 =  new Account(Name = 'Test Account1',
	        AccountNumber = '1234567890',
	        Phone = '(763) 555-2000',
		 	Store_Location__c = store.id, 
			BillingStreet = '123 happy Ln',
			BillingCity = 'Sunshine',
			BillingState = 'Minnesota',
			BillingStateCode = 'MN',
			BillingPostalCode = '55449', 
			BillingCountry = 'United States',
			RecordTypeId = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account') ); 
	 	insert account1;	
		
		Account vend1 = utilities.createVendorAccount('Vendor Account 1');
		insert vend1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = vend1.id
		);

		insert product1;
		
		PricebookEntry pricebookEntry1 = utilities.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;

		Opportunity opp = new Opportunity(
											Name = 'Test Opportunity',
											StageName = 'New',
											AccountId = account1.id,
											Store_Location__c = store.id,
											Pricebook2Id = Test.getStandardPricebookId(),
											CloseDate = Date.Today()
										);
		insert opp;
		
		Quote quote = utilities.createQuote(opp.id,Test.getStandardPricebookId());
		insert quote;
		
		opp.StageName = 'Sold';
		update opp;
		
		list<Order> orders = [SELECT Id FROM Order WHERE OpportunityId = :opp.id];
		
		System.assertEquals(1, orders.size());
		
	}
	
	static testmethod void testReparentAttachment(){ 
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
		TestUtilityMethods utilities = new TestUtilityMethods();
		utilities.setUpConfigs();
		Account store = [SELECT Id FROM account WHERE Name ='77 - Twin Cities, MN'];

		//Creating Account (Needed for RMS_Queue_Settings__c)
		Account account1 =  new Account(Name = 'Test Account1',
	        AccountNumber = '1234567890',
	        Phone = '(763) 555-2000',
		 	Store_Location__c = store.id, 
			BillingStreet = '123 happy Ln',
			BillingCity = 'Sunshine',
			BillingState = 'Minnesota',
			BillingStateCode = 'MN',
			BillingPostalCode = '55449', 
			BillingCountry = 'United States',
			RecordTypeId = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account') ); 
	 	insert account1;	
		
		Account vend1 = utilities.createVendorAccount('Vendor Account 1');
		insert vend1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = vend1.id
		);

		insert product1;
		
		PricebookEntry pricebookEntry1 = utilities.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;

		Opportunity opp = new Opportunity(
											Name = 'Test Opportunity',
											StageName = 'New',
											AccountId = account1.id,
											Store_Location__c = store.id,
											Pricebook2Id = Test.getStandardPricebookId(),
											CloseDate = Date.Today()
										);
		insert opp;
		
		Attachment attach = new Attachment(Name = 'TestAtt', ParentId = opp.Id, Body=Blob.valueOf('Test PDF'), IsPrivate = false, Description = 'Test Description');
		insert attach;
		Attachment attach2 = new Attachment(Name = 'TestAtt2', ParentId = opp.Id, Body=Blob.valueOf('Test PDF2'), IsPrivate = true, Description = 'Test Description2');
		insert attach2;

		Quote quote = utilities.createQuote(opp.id,Test.getStandardPricebookId());
		insert quote;
				
		Contact contact1 = utilities.createContact(account1.id, '1');
		insert contact1;
		
		OpportunityContactRole ocr = new OpportunityContactRole(IsPrimary = true, 
																OpportunityId = opp.id, 
																ContactId = contact1.id
																);
		insert ocr;
				
		opp.StageName = 'Sold';
		update opp;
		
		list<Order> orders = [SELECT Id FROM Order WHERE OpportunityId = :opp.id];
		
		System.assertEquals(orders.size(), 1);

		List<Attachment> attList = [Select Id, ParentId, Name, Body, IsPrivate, Description from Attachment order by Name];
		System.assertEquals(attList.size(),2);
		System.assertEquals(attList[0].ParentId,orders[0].Id);
		System.assertEquals(attList[1].ParentId,orders[0].Id);
		Blob att1Body = attList[0].Body; 
		System.assertEquals(att1Body.toString(),'Test PDF');
		System.assertEquals(attList[0].Description,'Test Description');
		System.assertEquals(attList[0].IsPrivate,false);
		System.assertEquals(attList[0].Name,'TestAtt');
		Blob att2Body = attList[1].Body; 
		System.assertEquals(att2Body.toString(),'Test PDF2');
		System.assertEquals(attList[1].Description,'Test Description2');
		System.assertEquals(attList[1].IsPrivate,true);
		System.assertEquals(attList[1].Name,'TestAtt2');
		
	}

	/* 
	 * testOrderItemLinking
	 */
	static testmethod void testOrderItemLinking(){

		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;

		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();
		Profile p = [SELECT Id FROM Profile WHERE Name='Sys Admin']; 

		Datetime newApptTime = Datetime.now().addDays(1);
		Datetime tmApptTime = Datetime.now().addDays(5);

		User u = tUtil.createUser(p.id);
		insert u;

		tUtil.createSalesAppt(u.Id, newApptTime, false, false);

		Account store1 = [SELECT id, Name, Active_Store_Configuration__c FROM Account Where Name = '77 - Twin Cities, MN'][0];
		Account dwelling1 = tUtil.createDwellingAccount('456');
		dwelling1.Store_Location__c = store1.id;
		dwelling1.OwnerId = u.Id;
		insert dwelling1;

		List<SObject> itemsToInsert = new List<SObject>();		
		
		Opportunity opp1 = tutil.createOpportunity('aaaTMAppt',dwelling1.id, 'New', u.Id);
		opp1.OwnerId = u.Id;
		itemsToInsert.add(opp1);
		insert itemsToInsert;

		//clean out the list
		itemsToInsert.clear();
		
		Pricebook2 pb = tutil.createPricebook2('bbbsaveQuoteTest', store1.Active_Store_Configuration__c);
		itemsToInsert.add(pb);
		insert itemsToInsert;
		itemsToInsert.clear();

		Quote quote1 = tutil.createQuote(opp1.id, pb.Id);
		quote1.isSold__c = true;
		itemsToInsert.add(quote1);
		insert itemsToInsert;
		//clean out the list
		itemsToInsert.clear();
			
		// qli to update
		QuoteLineItem qli1 = tutil.createQLIMasterChildProducts(pb.Id, quote1.Id);
		qli1.Description = 'original description';
		qli1.rSuite_Id__c = 'rsuite-id-1234';
		itemsToInsert.add(qli1);
		QuoteLineItem qli2 = tutil.createQLIMasterChildProducts(pb.Id, quote1.Id);
		qli2.Description = 'original description';
		qli2.rSuite_Id__c = 'rsuite-id-2234';
		itemsToInsert.add(qli2);
		QuoteLineItem qli3 = tutil.createQLIMasterChildProducts(pb.Id, quote1.Id);
		qli3.Description = 'original description';
		qli3.rSuite_Id__c = 'rsuite-id-3234';
		qli3.Parent_Unit_rSuite_Id__c = qli1.rSuite_Id__c;
		itemsToInsert.add(qli3);
		insert itemsToInsert;
		//clean out the list
		itemsToInsert.clear();
		// updates
		opp1.StageName = 'Sold';


        System.runAs(u) {
        	Test.StartTest();
        	update opp1;
			Test.StopTest();
			// we should have 3 order line items
			// 1. parent
			// 1. childd
			// 1 not a child
			List<OrderItem> oiList = [select Id, rSuite_Id__c, Parent_Order_Item__c, Parent_Unit_rSuite_Id__c from OrderItem where Order.OpportunityId = : opp1.Id order by rSuite_Id__c ASC];
			System.assert(oiList.size() == 3);
			System.assert(oiList[0].rSuite_Id__c == 'rsuite-id-1234');
			System.assert(oiList[1].rSuite_Id__c == 'rsuite-id-2234');
			System.assert(oiList[2].rSuite_Id__c == 'rsuite-id-3234');
			System.assert(oiList[0].Parent_Unit_rSuite_Id__c == null);
			System.assert(oiList[1].Parent_Unit_rSuite_Id__c == null);
			System.assert(oiList[2].Parent_Unit_rSuite_Id__c == 'rsuite-id-1234');
			System.assert(oiList[0].Parent_Order_Item__c == null);
			System.assert(oiList[1].Parent_Order_Item__c == null);
			System.assert(oiList[2].Parent_Order_Item__c == oiList[0].Id);
        }
	
	} 

}
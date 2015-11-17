@isTest
public with sharing class RMS_salesOrderManagerTest {

	static testmethod void positiveActivationOfOpportunity(){ 
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
		
		opp.SyncedQuoteId = quote.id;
		update opp;
		
		Contact contact1 = utilities.createContact(account1.id, '1');
		insert contact1;
		
		OpportunityContactRole ocr = new OpportunityContactRole(IsPrimary = true, 
																OpportunityId = opp.id, 
																ContactId = contact1.id
																);
		insert ocr;
		
		OpportunityLineItem oli = utilities.createOpportunityLineItem(opp.id, pricebookEntry1.id);
		insert oli;
		
		Discount__c discount1 = new Discount__c (	Name = 'testDiscount1',
													Active__c = true,
													Description__c = 'TestDescription',
													Promotion_Start__c = Date.Today().addDays(-1),
													Promotion_End__c = Date.Today().addDays(1)
													);
		insert discount1;
				
		Opportunity_Discount__c oppDiscount1 = new Opportunity_Discount__c(	Status__c = 'Applied', 
																			Discount__c = discount1.id, 
																			Discount_Amount__c = 1, 
																			Opportunity__c = opp.id
																			);
		insert oppDiscount1;
		
		opp.StageName = 'Closed Won';
		update opp;
		
		list<Order> orders = [SELECT Id FROM Order WHERE OpportunityId = :opp.id];
		
		System.assertEquals(orders.size(), 1);
		
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
		
		opp.SyncedQuoteId = quote.id;
		update opp;
		
		Contact contact1 = utilities.createContact(account1.id, '1');
		insert contact1;
		
		OpportunityContactRole ocr = new OpportunityContactRole(IsPrimary = true, 
																OpportunityId = opp.id, 
																ContactId = contact1.id
																);
		insert ocr;
		
		OpportunityLineItem oli = utilities.createOpportunityLineItem(opp.id, pricebookEntry1.id);
		insert oli;

		opp.StageName = 'Closed Won';
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
		
		opp.SyncedQuoteId = quote.id;
		update opp;
		
		Contact contact1 = utilities.createContact(account1.id, '1');
		insert contact1;
		
		OpportunityContactRole ocr = new OpportunityContactRole(IsPrimary = false, 
																OpportunityId = opp.id, 
																ContactId = contact1.id
																);
		insert ocr;
		
		OpportunityLineItem oli = utilities.createOpportunityLineItem(opp.id, pricebookEntry1.id);
		insert oli;
		
		Discount__c discount1 = new Discount__c (	Name = 'testDiscount1',
													Active__c = true,
													Description__c = 'TestDescription',
													Promotion_Start__c = Date.Today().addDays(-1),
													Promotion_End__c = Date.Today().addDays(1)
													);
		insert discount1;
				
		Opportunity_Discount__c oppDiscount1 = new Opportunity_Discount__c(	Status__c = 'Applied', 
																			Discount__c = discount1.id, 
																			Discount_Amount__c = 1, 
																			Opportunity__c = opp.id
																			);
		insert oppDiscount1;
		
		opp.StageName = 'Closed Won';
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
		
		opp.SyncedQuoteId = quote.id;
		update opp;
		
		OpportunityLineItem oli = utilities.createOpportunityLineItem(opp.id, pricebookEntry1.id);
		insert oli;
		
		Discount__c discount1 = new Discount__c (	Name = 'testDiscount1',
													Active__c = true,
													Description__c = 'TestDescription',
													Promotion_Start__c = Date.Today().addDays(-1),
													Promotion_End__c = Date.Today().addDays(1)
													);
		insert discount1;
				
		Opportunity_Discount__c oppDiscount1 = new Opportunity_Discount__c(	Status__c = 'Applied', 
																			Discount__c = discount1.id, 
																			Discount_Amount__c = 1, 
																			Opportunity__c = opp.id
																			);
		insert oppDiscount1;
		
		opp.StageName = 'Closed Won';
		update opp;
		
		list<Order> orders = [SELECT Id FROM Order WHERE OpportunityId = :opp.id];
		
		System.assertEquals(orders.size(), 1);
		
	}
	


}
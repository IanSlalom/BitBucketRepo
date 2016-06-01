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
		
		OpportunityLineItem oli = utilities.createOpportunityLineItem(opp.id, pricebookEntry1.id);
		insert oli;
		
		Discount__c discount1 = new Discount__c (	Name = 'testDiscount1',
													Active__c = true,
													Description__c = 'TestDescription',
													Promotion_Start__c = Date.Today().addDays(-1),
													Promotion_End__c = Date.Today().addDays(1)
													);
		insert discount1;
				
		opp.StageName = 'Closed Won';
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
		
		OpportunityLineItem oli = utilities.createOpportunityLineItem(opp.id, pricebookEntry1.id);
		insert oli;
		
		Discount__c discount1 = new Discount__c (	Name = 'testDiscount1',
													Active__c = true,
													Description__c = 'TestDescription',
													Promotion_Start__c = Date.Today().addDays(-1),
													Promotion_End__c = Date.Today().addDays(1)
													);
		insert discount1;
				
		opp.StageName = 'Closed Won';
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


}
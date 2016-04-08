@isTest
public with sharing class RMS_financialTransactionManagerTest {

	static testmethod void positiveCreatePayment(){
		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling1.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store1.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									BillToContactId = contact1.id, 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;

			
		Account vend1 = testMethods.createVendorAccount('Vendor Account 1');
		insert vend1;
		
		Pricebook2 pricebook1 =  testMethods.createPricebook2Name('Standard Price Book');
		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = vend1.id
		);

		insert product1;
		
		PricebookEntry pricebookEntry1 = testMethods.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;
		
		OrderItem orderItem1 = new OrderItem(OrderId = order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 10000 );
		insert orderItem1;	

		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Deposit',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Id paymentDespositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = order1.id,
												RecordTypeId = paymentDespositRecordTypeId,
												Payment_Type__c = 'Deposit',
												Store_Location__c = store1.id,
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		insert payment1;
		
		RMS_financialTransactionManager FTmanager = new RMS_financialTransactionManager();
		
		list<Payment__c> listNew = new list<Payment__c>();
		map<id,Payment__c> mapNew = new map<id,Payment__c>();
		
		listNew.add(payment1);
		mapNew.put(payment1.id, payment1);
		
		FTmanager.lockPaymentRecords(listNew);
		FTmanager.lockPaymentRecords(listNew, mapNew);
		

		/*
		try{
			throw new anException('An exception should have been thrown by the trigger but was not.'); // 1. If we get to this line it means an error was not added and the test class should throw an exception here. 2. MyException class extends Exception.
		}
		catch(Exception e)
		{
			System.Assert(e.getMessage().contains('transaction'));
		} 
		*/
	}
	
	
	static testmethod void positiveEditPayment(){
		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling1.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store1.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									BillToContactId = contact1.id, 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
			
		Account vend1 = testMethods.createVendorAccount('Vendor Account 1');
		insert vend1;
		
		Pricebook2 pricebook1 =  testMethods.createPricebook2Name('Standard Price Book');
		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = vend1.id
		);

		insert product1;
		
		PricebookEntry pricebookEntry1 = testMethods.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;
		
		OrderItem orderItem1 = new OrderItem(OrderId = order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 10000 );
		insert orderItem1;	
		
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Deposit',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Id paymentDespositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = order1.id,
												RecordTypeId = paymentDespositRecordTypeId,
												Store_Location__c = store1.id,
												Payment_Type__c = 'Deposit',
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		insert payment1;	
		payment1.Payment_Amount__c = 200;
		update payment1;
		
	}
	
	static testmethod void positiveDeletePayment(){
		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling1.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store1.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									BillToContactId = contact1.id, 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		
				//ADDED		
		Account vend1 = testMethods.createVendorAccount('Vendor Account 1');
		insert vend1;
		
		Pricebook2 pricebook1 =  testMethods.createPricebook2Name('Standard Price Book');
		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = vend1.id
		);

		insert product1;
		
		PricebookEntry pricebookEntry1 = testMethods.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;
		
		OrderItem orderItem1 = new OrderItem(OrderId = order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 10000 );
		insert orderItem1;	
		//END OF ADDED
		
		
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Deposit',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Id paymentDespositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = order1.id,
												RecordTypeId = paymentDespositRecordTypeId,
												Store_Location__c = store1.id,
												Payment_Type__c = 'Deposit',
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		insert payment1;
		delete payment1;	
	}
	
	static testmethod void noContactPayment(){
		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		//Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		//insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling1.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store1.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									//BillToContactId = contact1.id, 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		
		Account vend1 = testMethods.createVendorAccount('Vendor Account 1');
		insert vend1;
		
		Pricebook2 pricebook1 =  testMethods.createPricebook2Name('Standard Price Book');
		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = vend1.id
		);

		insert product1;
		
		PricebookEntry pricebookEntry1 = testMethods.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;
		
		OrderItem orderItem1 = new OrderItem(OrderId = order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 10000 );
		insert orderItem1;	
		
	
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Deposit',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Id paymentDespositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = order1.id,
												RecordTypeId = paymentDespositRecordTypeId,
												Store_Location__c = store1.id,
												Payment_Type__c = 'Deposit',
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		
		try{
			insert payment1;
			throw new anException('An exception should have been thrown by the trigger but was not.'); // 1. If we get to this line it means an error was not added and the test class should throw an exception here. 2. MyException class extends Exception.
		}
		catch(Exception e)
		{
			
			System.Assert(e.getMessage().contains('Contact'));
		} 
	}
	
	static testmethod void noFinancialRecordAndTwoFinancialRecordsPayment(){
		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling1.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store1.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									BillToContactId = contact1.id, 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		Account vend1 = testMethods.createVendorAccount('Vendor Account 1');
		insert vend1;
		
		Pricebook2 pricebook1 =  testMethods.createPricebook2Name('Standard Price Book');
		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = vend1.id
		);

		insert product1;
		
		PricebookEntry pricebookEntry1 = testMethods.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;
		
		OrderItem orderItem1 = new OrderItem(OrderId = order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 10000 );
		insert orderItem1;	
		
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		

		
		
		Id paymentDespositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = order1.id,
												RecordTypeId = paymentDespositRecordTypeId,
												Store_Location__c = store1.id,
												Payment_Type__c = 'Deposit',
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		
		try{
			insert payment1;
			throw new anException('An exception should have been thrown by the trigger but was not.'); // 1. If we get to this line it means an error was not added and the test class should throw an exception here. 2. MyException class extends Exception.
		}
		catch(Exception e)
		{
			System.Assert(e.getMessage().contains('no financial transaction record'));
		}
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Deposit',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		Financial_Transaction__c finacialTransaction2 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Deposit',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction2;
		
		try{
			insert payment1;
			throw new anException('An exception should have been thrown by the trigger but was not.'); // 1. If we get to this line it means an error was not added and the test class should throw an exception here. 2. MyException class extends Exception.
		}
		catch(Exception e)
		{
			System.Assert(e.getMessage().contains('two or more financial transaction'));
		}
		
		 
	}
	
	static testmethod void noCreditOrDebitNumberPayment(){
		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling1.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store1.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									BillToContactId = contact1.id, 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		Account vend1 = testMethods.createVendorAccount('Vendor Account 1');
		insert vend1;
		
		Pricebook2 pricebook1 =  testMethods.createPricebook2Name('Standard Price Book');
		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = vend1.id
		);

		insert product1;
		
		PricebookEntry pricebookEntry1 = testMethods.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;
		
		OrderItem orderItem1 = new OrderItem(OrderId = order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 10000 );
		insert orderItem1;	
		
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Deposit',
																						//Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Id paymentDespositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = order1.id,
												RecordTypeId = paymentDespositRecordTypeId,
												Store_Location__c = store1.id,
												Payment_Type__c = 'Deposit',
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		
		try{
			insert payment1;
			throw new anException('An exception should have been thrown by the trigger but was not.'); // 1. If we get to this line it means an error was not added and the test class should throw an exception here. 2. MyException class extends Exception.
		}
		catch(Exception e)
		{	
			system.debug('ads: exception should have Debit: ' +e);
			System.Assert(e.getMessage().contains('Debit'));
		} 
	
		finacialTransaction1.Debit_Account_Number__c = finacialAccountNumber1.id;
		finacialTransaction1.Credit_Account_Number__c = null;
		update finacialTransaction1;
		
		try{
			insert payment1;
			throw new anException('An exception should have been thrown by the trigger but was not.'); // 1. If we get to this line it means an error was not added and the test class should throw an exception here. 2. MyException class extends Exception.
		}
		catch(Exception e)
		{
			System.Assert(e.getMessage().contains('Credit'));
		} 
		
	}
	
	static testmethod void noPaymentAmountPayment(){
		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
	
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling1.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store1.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									BillToContactId = contact1.id, 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		Account vend1 = testMethods.createVendorAccount('Vendor Account 1');
		insert vend1;
		
		Pricebook2 pricebook1 =  testMethods.createPricebook2Name('Standard Price Book');
		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = vend1.id
		);

		insert product1;
		
		PricebookEntry pricebookEntry1 = testMethods.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;
		
		OrderItem orderItem1 = new OrderItem(OrderId = order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 10000 );
		insert orderItem1;	
		
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Deposit',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Id paymentDespositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = order1.id,
												RecordTypeId = paymentDespositRecordTypeId,
												Store_Location__c = store1.id,
												Payment_Type__c = 'Deposit',
												Payment_Date__c = Date.Today()
												);
		
		try{
			insert payment1;
			throw new anException('An exception should have been thrown by the trigger but was not.'); // 1. If we get to this line it means an error was not added and the test class should throw an exception here. 2. MyException class extends Exception.
		}
		catch(Exception e)
		{
			System.Assert(e.getMessage().contains('Payment Amount'));
		} 
	
	}
	
	static testmethod void noOrderPayement(){
		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
	
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling1.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store1.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									BillToContactId = contact1.id, 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Deposit',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Id paymentDespositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	
												Payment_Amount__c = 100,
												RecordTypeId = paymentDespositRecordTypeId,
												Payment_Type__c = 'Deposit',
												Store_Location__c = store1.id,
												Payment_Date__c = Date.Today()
												);
		
		try{
			insert payment1;
			throw new anException('An exception should have been thrown by the trigger but was not.'); // 1. If we get to this line it means an error was not added and the test class should throw an exception here. 2. MyException class extends Exception.
		}
		catch(Exception e)
		{
			System.Assert(e.getMessage().contains('Order'));
		} 
	
	}		
	

	static testmethod void positiveCreateMiscCash(){
		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];

		store1.Active_Store_Configuration__c = storeConfig1.Id;
		update store1;
		storeConfig1.Location_Number__c = '123';
		update storeConfig1;
						
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling1.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store1.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									BillToContactId = contact1.id, 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		Account vend1 = testMethods.createVendorAccount('Vendor Account 1');
		insert vend1;
		
		Pricebook2 pricebook1 =  testMethods.createPricebook2Name('Standard Price Book');
		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = vend1.id
		);

		insert product1;
		
		PricebookEntry pricebookEntry1 = testMethods.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;
		
		OrderItem orderItem1 = new OrderItem(OrderId = order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 10000 );
		insert orderItem1;	
		
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		Financial_Account_Number__c glAccount1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '3132', Account_Type__c = 'Misc Cash Receipt');
		insert glAccount1;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Misc Cash Receipt',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Id paymentMiscCashReceiptRecordTypeId = UtilityMethods.retrieveRecordTypeId('Misc_Cash_Receipt', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = order1.id,
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today(), 
												GL_Account__c = glAccount1.Id,
												Store_Location__c = store1.id,
												RecordTypeId = paymentMiscCashReceiptRecordTypeId
												);
		insert payment1;

	}
	
	
	
	static testmethod void positiveCreateDepositFinalPayment(){
		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling1.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store1.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									BillToContactId = contact1.id, 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		Account vend1 = testMethods.createVendorAccount('Vendor Account 1');
		insert vend1;
		
		Pricebook2 pricebook1 =  testMethods.createPricebook2Name('Standard Price Book');
		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = vend1.id
		);

		insert product1;
		
		PricebookEntry pricebookEntry1 = testMethods.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;
		
		OrderItem orderItem1 = new OrderItem(OrderId = order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 10000 );
		insert orderItem1;	
		
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Final Payment',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Id paymentDepositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = order1.id,
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today(),
												Account_Number__c = '12345',
												Store_Location__c = store1.id,
												RecordTypeId = paymentDepositRecordTypeId,
												Payment_Type__c = 'Final Payment'
												);
		insert payment1;
		payment1.Payment_Amount__c = 10;
		update payment1;
		delete payment1;
	}
	/* NEEDS COMMUNITIES ACTIVATED */
	static testmethod void positiveCreateAndEditLaborLaborExternal(){
		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		store1.Active_Store_Configuration__c = storeConfig1.id;
		update store1;
		storeConfig1.Standard_Hourly_Rate__c = 100;
		update storeConfig1;
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling1.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store1.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									BillToContactId = contact1.id, 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		
		Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
		RbA_Work_Order__c workOrder1 = new RbA_Work_Order__c(  	RecordTypeId = serviceOrderVisitRecordTypeId, 
															                Sold_Order__c = order1.id 
															                    );
		insert workOrder1;
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'External Labor',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		

		Id partnerProfileId = [select id from profile where name='Partner Community User'].id;
       
      	UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
		Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
		
		User portalAccountOwner1 = new User(
			UserRoleId = portalRole.Id,
			ProfileId = profile1.Id,
			Username = System.now().millisecond() + 'test2@test.com',
		   	Alias = 'batman',
			Email='bruce.wayne@wayneenterprises.com',
			EmailEncodingKey='UTF-8',
			Firstname='Bruce',
			Lastname='Wayne',
			LanguageLocaleKey='en_US',
			LocaleSidKey='en_US',
			TimeZoneSidKey='America/Chicago'
		);
		insert portalAccountOwner1;
       
        Account communityUserAccount = new Account(name ='Community User Account', Baan_Business_Partner_Number__c = '12345', OwnerId = portalAccountOwner1.Id);
        insert communityUserAccount; 
       
        Contact communityContact = new Contact(LastName ='testCon',AccountId = communityUserAccount.Id);
        insert communityContact;  
                  
        User communityUser = new User(	Alias = 'test123', 
										Email = 'test123@noemail.com',
		               					EmailEncodingKey ='UTF-8', 
		               					FirstName = 'first',
		               					LastName='Testing', 
		               					LanguageLocaleKey='en_US',
		                				LocaleSidKey='en_US', 
		                				ProfileID = partnerProfileId,
		                				Country = 'United States',
		                				IsActive = true,
						                ContactId = communityContact.Id,
						                TimeZoneSidKey = 'America/Los_Angeles', 
						                Username = 'tester@noemail.com',  
						                PortalRole = 'Worker',
						                CommunityNickname = 'financialTest'
						                );
       
        insert communityUser;
 
		
		Id laborLaborRecordTypeId = UtilityMethods.retrieveRecordTypeId('Labor', 'Labor__c');
		Labor__c labor1 = new Labor__c(	Related_Work_Order__c = workOrder1.id,
										Hours_Applied__c = 1,
										//Standard_Hourly_Rate__c=100,
										External_Labor_Amount__c = 100,
										Store_Location__c = store1.id,
										Date_Applied__c = Date.Today()
										);
										//,
										//Installer__c = communityUser.id
		
		
		try{
			insert labor1;
			throw new anException('An exception should have been thrown by the trigger but was not.'); // 1. If we get to this line it means an error was not added and the test class should throw an exception here. 2. MyException class extends Exception.
		}
		catch(Exception e)
		{
			System.Assert(e.getMessage().contains('Installer'));
		} 
	}
	
	
	static testmethod void positiveCreateAndEditLaborLaborInternal(){
		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		store1.Active_Store_Configuration__c = storeConfig1.id;
		update store1;
		storeConfig1.Standard_Hourly_Rate__c = 100;
		update storeConfig1;
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling1.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store1.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									BillToContactId = contact1.id, 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		
		Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
		RbA_Work_Order__c workOrder1 = new RbA_Work_Order__c(  	RecordTypeId = serviceOrderVisitRecordTypeId, 
															                Sold_Order__c = order1.id 
															                    );
		insert workOrder1;
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Internal Labor',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Id laborLaborRecordTypeId = UtilityMethods.retrieveRecordTypeId('Labor', 'Labor__c');
		Labor__c labor1 = new Labor__c(	Related_Work_Order__c = workOrder1.id,
												Hours_Applied__c = 1,
												//Standard_Hourly_Rate__c=100,
												//External_Labor_Amount__c = 100,
												Store_Location__c = store1.id,
												Date_Applied__c = Date.Today()
												);
		Test.StartTest();
		insert labor1;
		
		labor1.Hours_Applied__c = 2;
		update labor1;
		delete labor1;
		Test.StopTest();
	}


	static testmethod void positiveCreateLaborMiscReimbursementExternal(){
		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		store1.Active_Store_Configuration__c = storeConfig1.id;
		update store1;
		storeConfig1.Standard_Hourly_Rate__c = 100;
		storeConfig1.Location_Number__c = '123';
		update storeConfig1;
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling1.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store1.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									BillToContactId = contact1.id, 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		
		Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
		RbA_Work_Order__c workOrder1 = new RbA_Work_Order__c(  	RecordTypeId = serviceOrderVisitRecordTypeId, 
															                Sold_Order__c = order1.id 
															                    );
		insert workOrder1;
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1234');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2234');
		insert finacialAccountNumber2;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Misc Reimbursement',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Id laborMiscReimbursementRecordTypeId = UtilityMethods.retrieveRecordTypeId('Misc_Reimbursement', 'Labor__c');
		
			

		Id partnerProfileId = [select id from profile where name='Partner Community User'].id;
       
      	UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
		Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
		
		User portalAccountOwner1 = new User(
			UserRoleId = portalRole.Id,
			ProfileId = profile1.Id,
			Username = System.now().millisecond() + 'test2@test.com',
		   	Alias = 'batman',
			Email='bruce.wayne@wayneenterprises.com',
			EmailEncodingKey='UTF-8',
			Firstname='Bruce',
			Lastname='Wayne',
			LanguageLocaleKey='en_US',
			LocaleSidKey='en_US',
			TimeZoneSidKey='America/Chicago'
		);
		insert portalAccountOwner1;
       
        Account communityUserAccount = new Account(name ='Community User Account', Baan_Business_Partner_Number__c = '12345', OwnerId = portalAccountOwner1.Id);
        insert communityUserAccount; 
       
        Contact communityContact = new Contact(LastName ='testCon',AccountId = communityUserAccount.Id);
        insert communityContact;  
                  
        User communityUser = new User(	Alias = 'test123', 
										Email = 'test123@noemail.com',
		               					EmailEncodingKey ='UTF-8', 
		               					FirstName = 'first',
		               					LastName='Testing', 
		               					LanguageLocaleKey='en_US',
		                				LocaleSidKey='en_US', 
		                				ProfileID = partnerProfileId,
		                				Country = 'United States',
		                				IsActive = true,
						                ContactId = communityContact.Id,
						                TimeZoneSidKey = 'America/Los_Angeles', 
						                Username = 'tester@noemail.com',  
						                PortalRole = 'Worker',
						                CommunityNickname = 'financialTest'
						                );
       
        insert communityUser;
 		
 		Resource__c	resource1 = new Resource__c(Name='Resource1', Active__c = true, Resource_Type__c = 'Install Crew', RbA_User__c = communityUser.id);
		insert resource1;
		
		Labor__c labor1 = new Labor__c(	Related_Work_Order__c = workOrder1.id,
												Hours_Applied__c = 1,
												RecordTypeId = laborMiscReimbursementRecordTypeId,
												//Standard_Hourly_Rate__c=100,
												External_Labor_Amount__c = 100,
												Store_Location__c = store1.id,
												Date_Applied__c = Date.Today(),
												Installer__c = resource1.id,
												GL_Account__c = finacialAccountNumber1.id
												);
		Test.StartTest();
		insert labor1;
		labor1.Hours_Applied__c = 2;
		update labor1;
		Test.StopTest();
	}


	static testmethod void positiveCreateAsset(){
		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		store1.Active_Store_Configuration__c = storeConfig1.id;
		update store1;
		storeConfig1.Standard_Hourly_Rate__c = 100;
		update storeConfig1;
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling1.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store1.Id,
									Opportunity = opp1, 									
									Status ='Draft',
									BillToContactId = contact1.id, 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		
		Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
		RbA_Work_Order__c workOrder1 = new RbA_Work_Order__c(  	RecordTypeId = serviceOrderVisitRecordTypeId, 
															                Sold_Order__c = order1.id 
															                    );
		insert workOrder1;
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Inventory Received - External Vendor',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Financial_Account_Number__c finacialAccountNumber3 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '3');
		insert finacialAccountNumber3;
		Financial_Account_Number__c finacialAccountNumber4 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '4');
		insert finacialAccountNumber4;
		
		Financial_Transaction__c finacialTransaction2 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Inventory Write-Off',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction2;
		
		Id assetInstalledProductsRecordTypeId = UtilityMethods.retrieveRecordTypeId('Installed_Products', 'Asset');
		
		Account account1 = testMethods.createDwellingAccount('account1');
		account1.Store_Location__c = store1.id;
		account1.Baan_Business_Partner_Number__c = '12345';
		insert account1;
	
		Asset asset1 = new Asset(	Unit_Wholesale_Cost__c = 100,
									Quantity = 10,
									Sold_Order__c = order1.id,
									RecordTypeId = assetInstalledProductsRecordTypeId,
									Store_Location__c = store1.id,
									Name = 'asset1',
									AccountId = dwelling1.id,
									ContactId = contact1.id
		);
		

		insert asset1;
		
		asset1.Quantity = 2;
		
		update asset1;
		
		List<Journal_Entry__c> JEList = [SELECT Id, Sent_to_BaanERP__c FROM Journal_Entry__c];
		
		for(Journal_Entry__c je : JEList){
			je.Sent_to_BaanERP__c = true;
		}
		update JEList;
		
		Test.startTest();
		asset1.Quantity = 3;
		update asset1;
		
		asset1.Quantity = 1;
		update asset1;
		
		asset1.Quantity_Written_Off__c = 1;
		update asset1;
		
		
		asset1.Quantity = 10;
		update asset1;

		
		Test.stopTest();
		
		for(Journal_Entry__c je : JEList){
			je.Sent_to_BaanERP__c = false;
		}
		update JEList;
		delete asset1;
	}
	
	
	static testmethod void positiveCreateOrder(){
		TestUtilityMethods testMethods = new TestUtilityMethods();

		testMethods.createOrderTestRecords();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		store1.Active_Store_Configuration__c = storeConfig1.id;
		update store1;
		storeConfig1.Standard_Hourly_Rate__c = 100;
		update storeConfig1;
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
		Id orderCORORecordTypeRecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Record_Type', 'Order');
		
		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];


		soldOrder.RecordTypeId = orderCORORecordTypeRecordTypeId;
		soldOrder.Revenue_Recognized_Date__c = null;
		soldOrder.Status = 'Job Close';
		update soldOrder;
		
		Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
		RbA_Work_Order__c workOrder1 = new RbA_Work_Order__c(  	RecordTypeId = serviceOrderVisitRecordTypeId, 
															                Sold_Order__c = soldOrder.id 
															                    );
		insert workOrder1;
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Deposit',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Financial_Account_Number__c finacialAccountNumber3 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '3');
		insert finacialAccountNumber3;
		Financial_Account_Number__c finacialAccountNumber4 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '4');
		insert finacialAccountNumber4;
		
		Financial_Transaction__c finacialTransactionLabor = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Labor',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransactionLabor;
		
		Financial_Account_Number__c finacialAccountNumber5 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '5');
		insert finacialAccountNumber5;
		Financial_Account_Number__c finacialAccountNumber6 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '6');
		insert finacialAccountNumber6;
		
		Financial_Transaction__c finacialTransaction2 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Deposit',
																						Debit_Account_Number__c = finacialAccountNumber3.id,
																						Credit_Account_Number__c = finacialAccountNumber4.id);
		insert finacialTransaction2;
		
		
		Financial_Account_Number__c finacialAccountNumber7 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '7');
		insert finacialAccountNumber7;
		Financial_Account_Number__c finacialAccountNumber8 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '8');
		insert finacialAccountNumber8;
		
		Financial_Transaction__c finacialTransaction3 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Refund Deposit',
																						Debit_Account_Number__c = finacialAccountNumber7.id,
																						Credit_Account_Number__c = finacialAccountNumber8.id);
		insert finacialTransaction3;
		Financial_Transaction__c finacialTransaction4 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Internal Labor',
																						Debit_Account_Number__c = finacialAccountNumber7.id,
																						Credit_Account_Number__c = finacialAccountNumber8.id);
		insert finacialTransaction4;
		
		Financial_Transaction__c finacialTransaction5 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Gross Sales',
																						Debit_Account_Number__c = finacialAccountNumber7.id,
																						Credit_Account_Number__c = finacialAccountNumber8.id);
		insert finacialTransaction5;
		
		Financial_Transaction__c finacialTransaction6 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Discount',
																						Debit_Account_Number__c = finacialAccountNumber7.id,
																						Credit_Account_Number__c = finacialAccountNumber8.id);
		insert finacialTransaction6;
		
		
		Financial_Transaction__c finacialTransaction7 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - AR',
																						Debit_Account_Number__c = finacialAccountNumber7.id,
																						Credit_Account_Number__c = finacialAccountNumber8.id);
		insert finacialTransaction7;
		Financial_Transaction__c finacialTransaction8 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Finance Fees',
																						Debit_Account_Number__c = finacialAccountNumber7.id,
																						Credit_Account_Number__c = finacialAccountNumber8.id);
		insert finacialTransaction8;
		Test.startTest();
		Id paymentDespositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = soldOrder.id,
												RecordTypeId = paymentDespositRecordTypeId,
												Payment_Type__c = 'Deposit',
												Store_Location__c = store1.id,
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		insert payment1;
		
		soldOrder.Revenue_Recognized_Date__c = Date.Today();
		update soldOrder;
		Test.stopTest();
	}
	
	
	static testmethod void positiveCreateRefund(){
		TestUtilityMethods testMethods = new TestUtilityMethods();

		testMethods.createOrderTestRecords();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		store1.Active_Store_Configuration__c = storeConfig1.id;
		update store1;
		storeConfig1.Standard_Hourly_Rate__c = 100;
		update storeConfig1;
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
		Id orderCORORecordTypeRecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Record_Type', 'Order');
		
		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];


		soldOrder.RecordTypeId = orderCORORecordTypeRecordTypeId;
		soldOrder.Revenue_Recognized_Date__c = null;
		soldOrder.Status = 'Job Close';
		soldOrder.Payments_Received__c = 10000.00;
		update soldOrder;
		
		Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
		RbA_Work_Order__c workOrder1 = new RbA_Work_Order__c(  	RecordTypeId = serviceOrderVisitRecordTypeId, 
															                Sold_Order__c = soldOrder.id 
															                    );
		insert workOrder1;
		
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Deposit',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Financial_Account_Number__c finacialAccountNumber3 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '3');
		insert finacialAccountNumber3;
		Financial_Account_Number__c finacialAccountNumber4 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '4');
		insert finacialAccountNumber4;
		
		Financial_Transaction__c finacialTransactionLabor = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Final Payment',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransactionLabor;
		


		Refund__c refund1 = new Refund__c(	Order__c = soldOrder.id, 
											Amount__c = 10, 
											Store_Location__c = store1.id, 
											Refund_Method__c = 'Check'
											);
		
		Test.startTest();
		insert refund1;
		
		refund1.Amount__c = 20;
		update refund1;
		Test.stopTest();
	}
	
	
	
	//Business_Adjustment__c
	static testmethod void positiveCreateBusinessAdjustment(){
		TestUtilityMethods testMethods = new TestUtilityMethods();

		testMethods.createOrderTestRecords();
		
		Account store1 = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];
		Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
		store1.Active_Store_Configuration__c = storeConfig1.id;
		update store1;
		storeConfig1.Standard_Hourly_Rate__c = 100;
		update storeConfig1;
		
		Account dwelling1 = testMethods.createDwellingAccount('dwelling1');
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		Contact contact1 = testMethods.createContact(dwelling1.id, 'contact1');
		insert contact1;
		
		Opportunity opp1 = testMethods.createOpportunity(dwelling1.id, 'Draft');
		insert opp1;
		Id orderCORORecordTypeRecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Record_Type', 'Order');
		
		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];


		soldOrder.RecordTypeId = orderCORORecordTypeRecordTypeId;
		soldOrder.Revenue_Recognized_Date__c = null;
		soldOrder.Status = 'Job Close';
		soldOrder.Payments_Received__c = 10000.00;
		update soldOrder;
		
		Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
		RbA_Work_Order__c workOrder1 = new RbA_Work_Order__c(  	RecordTypeId = serviceOrderVisitRecordTypeId, 
															                Sold_Order__c = soldOrder.id 
															                    );
		insert workOrder1;
		
		Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '1');
		insert finacialAccountNumber1;
		Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '2');
		insert finacialAccountNumber2;
		
		Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'AR write-off',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Financial_Account_Number__c finacialAccountNumber3 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '3');
		insert finacialAccountNumber3;
		Financial_Account_Number__c finacialAccountNumber4 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '4');
		insert finacialAccountNumber4;
		
		Financial_Transaction__c finacialTransactionLabor = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Install Adjustment',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransactionLabor;
		


		Business_Adjustment__c busAdj = new Business_Adjustment__c(	Order__c = soldOrder.id, 
																	Amount__c = 10, 
																	Store_Location__c = store1.id, 
																	Type__c = 'AR write-off'
																	);
		insert busAdj;
		busAdj.Amount__c = 5;
		update busAdj;
	}
	
	public class anException extends Exception {}
}
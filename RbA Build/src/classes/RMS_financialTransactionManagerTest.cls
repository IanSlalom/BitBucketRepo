@isTest
public with sharing class RMS_financialTransactionManagerTest {

	static testmethod void positiveCreate(){
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
		Payment__c payment1 = new Payment__c(	Order__c = order1.id,
												RecordTypeId = paymentDespositRecordTypeId,
												Payment_Type__c = 'Deposit',
												Store_Location__c = store1.id,
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		insert payment1;
		
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
	/*
	static testmethod void positiveCreateFinalPayment(){
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
																						Transaction_Type__c = 'Final Payment',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Id paymentDespositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = order1.id,
												RecordTypeId = paymentDespositRecordTypeId,
												Payment_Type__c = 'Final Payment',
												Store_Location__c = store1.id,
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		insert payment1;
		
	}
	*/
		
	static testmethod void positiveEdit(){
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
	
	static testmethod void positiveDelete(){
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
	
	static testmethod void noContact(){
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
	
	static testmethod void noFinancialRecordAndTwoFinancialRecords(){
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
	
	static testmethod void noCreditOrDebitNumber(){
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
	
	static testmethod void noPaymentAmount(){
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
	
	static testmethod void noOrder(){
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
		Financial_Account_Number__c glAccount1 = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = '3', Account_Type__c = 'Misc Cash Receipt');
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
	/* NEEDS COMMUNITIES ACTIVATED
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
																						Transaction_Type__c = 'Internal Labor',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Id laborLaborRecordTypeId = UtilityMethods.retrieveRecordTypeId('Labor', 'Labor__c');
		Labor__c labor1 = new Labor__c(	Related_Work_Order__c = workOrder1.id,
												Hours_Applied__c = 1,
												//Standard_Hourly_Rate__c=100,
												External_Labor_Amount__c = 100,
												Store_Location__c = store1.id,
												Date_Applied__c = Date.Today()
												);
		insert labor1;
		
		labor1.Hours_Applied__c = 2;
		
		update labor1;
		
	}
	*/
	
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
		insert labor1;
		
		labor1.Hours_Applied__c = 2;
		
		update labor1;
		delete labor1;
	}

	/* need communities
	static testmethod void positiveCreateAndEditMiscReimbursementExternal(){
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
																						Transaction_Type__c = 'Misc Reimbursement',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		Id laborMiscReimbursementRecordTypeId = UtilityMethods.retrieveRecordTypeId('Misc_Reimbursement', 'Labor__c');
		
		Account account1 = testMethods.createDwellingAccount('account1');
		account1.Store_Location__c = store1.id;
		account1.Baan_Business_Partner_Number__c = '12345';
		insert account1;
		
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
		User installer = testMethods.createUser(p.id);
		installer.AccountId = account1.id;
		insert installer;

		Labor__c labor1 = new Labor__c(	Related_Work_Order__c = workOrder1.id,
												Hours_Applied__c = 1,
												RecordTypeId = laborMiscReimbursementRecordTypeId,
												//Standard_Hourly_Rate__c=100,
												External_Labor_Amount__c = 100,
												Store_Location__c = store1.id,
												Date_Applied__c = Date.Today(),
												Installer__c = installer.id
												);
		insert labor1;
		
		labor1.Hours_Applied__c = 2;
		
		update labor1;
		
	}
	
	*/
	

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
																						Transaction_Type__c = 'Inventory Received',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
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
		delete asset1;
	}
	
	
	static testmethod void positiveCreateAndEditOrder(){
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
																						Transaction_Type__c = 'Internal Labor',
																						Debit_Account_Number__c = finacialAccountNumber1.id,
																						Credit_Account_Number__c = finacialAccountNumber2.id);
		insert finacialTransaction1;
		
		soldOrder.Revenue_Recognized_Date__c = Date.Today();
		update soldOrder;
//		delete soldOrder; cannot delete activated order
	}
	
	
	
	public class anException extends Exception {}
}
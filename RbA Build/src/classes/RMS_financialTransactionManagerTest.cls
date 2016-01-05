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
									Store_Location2__c = store1.Id,
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
									Store_Location2__c = store1.Id,
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
									Store_Location2__c = store1.Id,
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
									Store_Location2__c = store1.Id,
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
									Store_Location2__c = store1.Id,
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
									Store_Location2__c = store1.Id,
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
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		
		try{
			insert payment1;
			throw new anException('An exception should have been thrown by the trigger but was not.'); // 1. If we get to this line it means an error was not added and the test class should throw an exception here. 2. MyException class extends Exception.
		}
		catch(Exception e)
		{
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
									Store_Location2__c = store1.Id,
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
									Store_Location2__c = store1.Id,
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
	
	public class anException extends Exception {}
}
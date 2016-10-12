/*******************************************************//**

@class	RMS_financialTransManRefundTest

@brief	Test Class for RMS_financialTransactionManager. 

		Separated the original test class into multiple test classes. This one focuses
		on the refund test classes (refunds, check refunds)

@author  Creston Kuenzi (Slalom.CDK)

@version	2016-10-5  Slalom.CDK
	Created.

@see		RMS_financialTransactionManager

@copyright  (c)2016 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_financialTransManRefundTest {

	/*******************************************************
					setupData
	*******************************************************/
	@testSetup static void setupData(){

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

			
		
		Account vend1 = testMethods.createIntercompanyVendorAccount('Intercompany');
		Account vend2 = testMethods.createIntercompanyCCVendorAccount('IntercompanyCC');
		Account vend3 = testMethods.createExternalVendorAccount('External');
		List<Account> vendsToInsert = new List<Account>{vend1,vend2,vend3};
		
		insert vendsToInsert;
		
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

		testMethods.createAllFinancialRecords(storeConfig1);


	}

	/*******************************************************
					positiveCreateEditDepositRefund
	*******************************************************/
	static testmethod void positiveCreateEditDepositRefund(){
		Order soldOrder = [SELECT Id, AccountId, BillToContactId FROM Order where Name='Sold Order 1'];		
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Id paymentDepositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = soldOrder.id,
												RecordTypeId = paymentDepositRecordTypeId,
												Payment_Type__c = 'Deposit',
												Store_Location__c = store.id,
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		insert payment1;
		
		Refund__c refund1 = new Refund__c(	Order__c = soldOrder.id, 
											Amount__c = 10, 
											Store_Location__c = store.id, 
											Refund_Method__c = 'Credit'
											);
		Financial_Account_Number__c depAcctNumberDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANDepositDebit'];
		Financial_Account_Number__c depAcctNumberCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANDepositCredit'];
		
		Test.startTest();
		insert refund1;
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Refund - Deposit']; 
		System.AssertEquals(10, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers are the reverse of the deposit debit/credit
		System.AssertEquals(depAcctNumberDebit.Name, je.Credit_General_Ledger_Account__c);
		System.AssertEquals(depAcctNumberCredit.Name, je.Debit_General_Ledger_Account__c);
		
		refund1.Amount__c = 20;
		update refund1;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Refund - Deposit']; 
		System.AssertEquals(20, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());
		
		// Verify the account numbers are the reverse of the deposit debit/credit
		System.AssertEquals(depAcctNumberDebit.Name, je.Credit_General_Ledger_Account__c);
		System.AssertEquals(depAcctNumberCredit.Name, je.Debit_General_Ledger_Account__c);
		delete refund1;
		Test.stopTest();
	}

	/*******************************************************
					positiveCreateEditDepositCheckRefund
	*******************************************************/
	static testmethod void positiveCreateEditDepositCheckRefund(){
		Order soldOrder = [SELECT Id, AccountId, BillToContactId FROM Order where Name='Sold Order 1'];		
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Id paymentDepositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = soldOrder.id,
												RecordTypeId = paymentDepositRecordTypeId,
												Payment_Type__c = 'Check',
												Store_Location__c = store.id,
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		insert payment1;
		
		Refund__c refund1 = new Refund__c(	Order__c = soldOrder.id, 
											Amount__c = 10, 
											Store_Location__c = store.id, 
											Refund_Method__c = 'Check'
											);
		Financial_Account_Number__c depCheckRefundAcctNumberDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANDepositCheckRefundDebit'];
		Financial_Account_Number__c depCheckRefundAcctNumberCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANDepositCheckRefundCredit'];
		
		Test.startTest();
		insert refund1;
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Refund - Deposit']; 
		System.AssertEquals(10, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers are not the reverse of the deposit debit/credit
		System.AssertEquals(depCheckRefundAcctNumberDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(depCheckRefundAcctNumberCredit.Name, je.Credit_General_Ledger_Account__c);
		
		refund1.Amount__c = 20;
		update refund1;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Refund - Deposit']; 
		System.AssertEquals(20, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());
		
		// Verify the account numbers are the reverse of the deposit debit/credit
		System.AssertEquals(depCheckRefundAcctNumberDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(depCheckRefundAcctNumberCredit.Name, je.Credit_General_Ledger_Account__c);
		delete refund1;
		Test.stopTest();
	}

	/*******************************************************
					positiveCreateEditFinalPaymentRefund
	*******************************************************/
	static testmethod void positiveCreateEditFinalPaymentRefund(){
		Order soldOrder = [SELECT Id, AccountId, BillToContactId FROM Order where Name='Sold Order 1'];		
		soldOrder.Revenue_Recognized_Date__c = System.today();
		update soldOrder;
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Id paymentDepositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = soldOrder.id,
												RecordTypeId = paymentDepositRecordTypeId,
												Payment_Type__c = 'Deposit',
												Store_Location__c = store.id,
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		insert payment1;
		
		Refund__c refund1 = new Refund__c(	Order__c = soldOrder.id, 
											Amount__c = 10, 
											Store_Location__c = store.id, 
											Refund_Method__c = 'Credit'
											);
		Financial_Account_Number__c finalPaymentAcctNumberDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANFinalPaymentDebit'];
		Financial_Account_Number__c finalPaymentAcctNumberCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANFinalPaymentCredit'];
		
		Test.startTest();
		insert refund1;
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Refund - Final Payment']; 
		System.AssertEquals(10, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers are the reverse of the deposit debit/credit
		System.AssertEquals(finalPaymentAcctNumberDebit.Name, je.Credit_General_Ledger_Account__c);
		System.AssertEquals(finalPaymentAcctNumberCredit.Name, je.Debit_General_Ledger_Account__c);
		
		refund1.Amount__c = 20;
		update refund1;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Refund - Final Payment']; 
		System.AssertEquals(20, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());
		
		// Verify the account numbers are the reverse of the deposit debit/credit
		System.AssertEquals(finalPaymentAcctNumberDebit.Name, je.Credit_General_Ledger_Account__c);
		System.AssertEquals(finalPaymentAcctNumberCredit.Name, je.Debit_General_Ledger_Account__c);
		delete refund1;
		Test.stopTest();
	}

	/*******************************************************
					positiveCreateEditFinalPaymentCheckRefund
	*******************************************************/
	static testmethod void positiveCreateEditFinalPaymentCheckRefund(){
		Order soldOrder = [SELECT Id, AccountId, BillToContactId FROM Order where Name='Sold Order 1'];		
		soldOrder.Revenue_Recognized_Date__c = System.today();
		update soldOrder;
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Id paymentDepositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = soldOrder.id,
												RecordTypeId = paymentDepositRecordTypeId,
												Payment_Type__c = 'Check',
												Store_Location__c = store.id,
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		insert payment1;
		
		Refund__c refund1 = new Refund__c(	Order__c = soldOrder.id, 
											Amount__c = 10, 
											Store_Location__c = store.id, 
											Refund_Method__c = 'Check'
											);
		Financial_Account_Number__c finalPaymentCheckRefundAcctNumberDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANFinalPaymentCheckRefundDebit'];
		Financial_Account_Number__c finalPaymentCheckRefundAcctNumberCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANFinalPaymentCheckRefundCredit'];
		
		Test.startTest();
		insert refund1;
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Refund - Final Payment']; 
		System.AssertEquals(10, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers are the reverse of the deposit debit/credit
		System.AssertEquals(finalPaymentCheckRefundAcctNumberDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(finalPaymentCheckRefundAcctNumberCredit.Name, je.Credit_General_Ledger_Account__c);
		
		refund1.Amount__c = 20;
		update refund1;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Refund - Final Payment']; 
		System.AssertEquals(20, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());
		
		// Verify the account numbers
		System.AssertEquals(finalPaymentCheckRefundAcctNumberDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(finalPaymentCheckRefundAcctNumberCredit.Name, je.Credit_General_Ledger_Account__c);
		delete refund1;
		Test.stopTest();
	}

	public class anException extends Exception {}

}
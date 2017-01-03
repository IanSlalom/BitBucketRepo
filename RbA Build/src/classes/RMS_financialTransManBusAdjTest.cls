/*******************************************************//**

@class	RMS_financialTransManBusAdjTest

@brief	Test Class for RMS_financialTransactionManager. 

		Separated the original test class into multiple test classes. This one focuses
		on the business adjustment test classes (ar-write off, install adjustments, non-sufficient funds)

@author  Creston Kuenzi (Slalom.CDK)

@version	2016-10-5  Slalom.CDK
	Created.

@see		RMS_financialTransactionManager

@copyright  (c)2016 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_financialTransManBusAdjTest {

	/*******************************************************
					setupData
	*******************************************************/
	@testSetup static void setupData(){

		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Account store1 = [SELECT id, Active_Store_Configuration__c FROM Account WHERE Name='77 - Twin Cities, MN'];
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
					positiveCreateEditARWriteOff
	*******************************************************/
	static testmethod void positiveCreateEditARWriteOff(){
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

		Business_Adjustment__c busAdj = new Business_Adjustment__c(	Order__c = soldOrder.id, 
																	Amount__c = 10, 
																	Store_Location__c = store.id, 
																	Type__c = 'AR write-off'
																	);
		insert busAdj;
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'AR write-off']; 
		System.AssertEquals(10, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());
		busAdj.Amount__c = 5;

		update busAdj;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'AR write-off']; 
		System.AssertEquals(5, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		delete busAdj;
	}

	/*******************************************************
					positiveCreateEditInstallAdjustment
	*******************************************************/
	static testmethod void positiveCreateEditInstallAdjustment(){
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

		Business_Adjustment__c busAdj = new Business_Adjustment__c(	Order__c = soldOrder.id, 
																	Amount__c = 10, 
																	Store_Location__c = store.id, 
																	Type__c = 'Install Adjustment'
																	);
		insert busAdj;

		Financial_Account_Number__c installAdjustmentDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANInstallAdjustmentDebit'];
		Financial_Account_Number__c installAdjustmentCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANInstallAdjustmentCredit'];

		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
		 FROM Journal_Entry__c WHERE Order__c =: soldOrder.Id AND Type__c = 'Install Adjustment']; 
		System.AssertEquals(10, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account number is the store location number inserted in the the gl account number
		System.AssertEquals(installAdjustmentDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(installAdjustmentCredit.Name, je.Credit_General_Ledger_Account__c);

		busAdj.Amount__c = 5;

		update busAdj;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
		 FROM Journal_Entry__c WHERE Order__c =: soldOrder.Id AND Type__c = 'Install Adjustment']; 
		System.AssertEquals(5, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account number is the store location number inserted in the the gl account number
		System.AssertEquals(installAdjustmentDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(installAdjustmentCredit.Name, je.Credit_General_Ledger_Account__c);

		delete busAdj;
	}	

	/*******************************************************
					positiveCreateEditPostRecognizedInstallAdjustment
	*******************************************************/
	static testmethod void positiveCreateEditPostRecognizedInstallAdjustment(){

		test.startTest();
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

		Business_Adjustment__c busAdj = new Business_Adjustment__c(	Order__c = soldOrder.id, 
																	Amount__c = 10, 
																	Store_Location__c = store.id, 
																	Type__c = 'Install Adjustment'
																	);
		insert busAdj;

		Financial_Account_Number__c installAdjustmentPRDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANPRInstallAdjustmentDebit'];
		Financial_Account_Number__c installAdjustmentPRCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANPRInstallAdjustmentCredit'];

		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
		 FROM Journal_Entry__c WHERE Order__c =: soldOrder.Id AND Type__c = 'Post Recognized Install Adjustment']; 
		System.AssertEquals(10, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account number is the store location number inserted in the the gl account number
		System.AssertEquals(installAdjustmentPRDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(installAdjustmentPRCredit.Name, je.Credit_General_Ledger_Account__c);

		busAdj.Amount__c = 5;

		update busAdj;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c , Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
		FROM Journal_Entry__c WHERE Order__c =: soldOrder.Id AND Type__c = 'Post Recognized Install Adjustment']; 
		System.AssertEquals(5, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account number is the store location number inserted in the the gl account number
		System.AssertEquals(installAdjustmentPRDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(installAdjustmentPRCredit.Name, je.Credit_General_Ledger_Account__c);

		delete busAdj;
		test.stopTest();
	}	


	/*******************************************************
					positiveCreateEditNonSufficientDeposit
	*******************************************************/
	static testmethod void positiveCreateEditNonSufficientDeposit(){
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

		Business_Adjustment__c busAdj = new Business_Adjustment__c(	Order__c = soldOrder.id, 
																	Amount__c = 10, 
																	Store_Location__c = store.id, 
																	Type__c = 'Non-sufficient Funds - Deposit'
																	);
		insert busAdj;
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Non-sufficient Funds - Deposit']; 
		System.AssertEquals(10, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());
		busAdj.Amount__c = 5;

		update busAdj;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Non-sufficient Funds - Deposit']; 
		System.AssertEquals(5, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		delete busAdj;
	}	

	/*******************************************************
					positiveCreateEditNonSufficientFinalPayment
	*******************************************************/
	static testmethod void positiveCreateEditNonSufficientFinalPayment(){
		Order soldOrder = [SELECT Id, Revenue_Recognized_Date__c FROM Order where Name='Sold Order 1'];		
		soldOrder.Revenue_Recognized_Date__c = System.today();
		update soldOrder;
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];				

		Id paymentDepositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = soldOrder.id,
												RecordTypeId = paymentDepositRecordTypeId,
												Payment_Type__c = 'Final Payment',
												Store_Location__c = store.id,
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		insert payment1;

		Business_Adjustment__c busAdj = new Business_Adjustment__c(	Order__c = soldOrder.id, 
																	Amount__c = 10, 
																	Store_Location__c = store.id, 
																	Type__c = 'Non-sufficient Funds - Final Payment'
																	);
		insert busAdj;
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Non-sufficient Funds - Final Payment']; 
		System.AssertEquals(10, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());
		busAdj.Amount__c = 5;

		update busAdj;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Non-sufficient Funds - Final Payment']; 
		System.AssertEquals(5, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		delete busAdj;
	}	

	public class anException extends Exception {}


}
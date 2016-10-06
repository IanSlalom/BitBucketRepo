/*******************************************************//**

@class	RMS_financialTransManInventoryTest

@brief	Test Class for RMS_financialTransactionManager

		Separated the original test class into multiple test classes. This one focuses
		on the inventory test classes 

@author  Creston Kuenzi (Slalom.CDK)

@version	2016-10-5  Slalom.CDK
	Created.

@see		RMS_financialTransactionManager

@copyright  (c)2016 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_financialTransManInventoryTest {

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
					positiveCreateIntercompanyAsset
	*******************************************************/
	static testmethod void positiveCreateIntercompanyAsset(){
		test.starttest();
		Order soldOrder = [SELECT Id, AccountId, BillToContactId FROM Order where Name='Sold Order 1'];		
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Store_Configuration__c storeConfig = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store.id ];
		storeConfig.Standard_Hourly_Rate__c = 100;
		storeConfig.Location_Number__c = '123';
		update storeConfig;
		
		Id assetInstalledProductsRecordTypeId = UtilityMethods.retrieveRecordTypeId('Installed_Products', 'Asset');
		
		Account vendor = [SELECT Id from Account where Vendor_Account_Type__c = 'Intercompany'];

		Financial_Account_Number__c interCompanyDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANInventoryReceivedIntercompanyDebit'];
		Financial_Account_Number__c interCompanyCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANInventoryReceivedIntercompanyCredit'];
	
		Asset asset1 = new Asset(	Unit_Wholesale_Cost__c = 100,
									Quantity = 10,
									Sold_Order__c = soldOrder.id,
									RecordTypeId = assetInstalledProductsRecordTypeId,
									Store_Location__c = store.id,
									Name = 'asset1',
									AccountId = soldOrder.AccountId,
									ContactId = soldOrder.BillToContactId,
									Vendor__c = vendor.id
		);
		

		insert asset1;
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Inventory Received - Intercompany']; 
		System.AssertEquals(1000, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(interCompanyDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(interCompanyCredit.Name, je.Credit_General_Ledger_Account__c);
		
		
		asset1.Quantity = 2;
		
		update asset1;

		je = [SELECT Id, Amount__c, Type__c, Sent_to_BaanERP__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Inventory Received - Intercompany']; 
		System.AssertEquals(200, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());
		
		// Verify the account numbers 
		System.AssertEquals(interCompanyDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(interCompanyCredit.Name, je.Credit_General_Ledger_Account__c);
		
		je.Sent_to_BaanERP__c = true;
		update je;		
		
		asset1.Quantity = 3;
		update asset1;

		Journal_Entry__c je2 = [SELECT Id, Amount__c, Type__c, Sent_to_BaanERP__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Inventory Received - Intercompany' AND Sent_to_BaanERP__c = false]; 

		System.AssertEquals(100, je2.Amount__c);
		System.AssertEquals(System.today(), je2.Date__c.date());
		// Verify the account numbers 
		System.AssertEquals(interCompanyDebit.Name, je2.Debit_General_Ledger_Account__c);
		System.AssertEquals(interCompanyCredit.Name, je2.Credit_General_Ledger_Account__c);
// TODO		
//		asset1.Quantity = 3;
//		update asset1;

/*		je2 = [SELECT Id, Amount__c, Type__c, Sent_to_BaanERP__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Inventory Received - Intercompany' AND Sent_to_BaanERP__c = false]; 

		System.AssertEquals(100, je2.Amount__c);
		System.AssertEquals(System.today(), je2.Date__c.date());
		// Verify the account numbers 
		System.AssertEquals(interCompanyDebit.Name, je2.Credit_General_Ledger_Account__c);
		System.AssertEquals(interCompanyCredit.Name, je2.Debit_General_Ledger_Account__c);*/
		
		Test.stopTest();
	}

	/*******************************************************
					positiveCreateIntercompanyCCAsset
	*******************************************************/
	static testmethod void positiveCreateIntercompanyCCAsset(){
		test.starttest();
		Order soldOrder = [SELECT Id, AccountId, BillToContactId FROM Order where Name='Sold Order 1'];		
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Store_Configuration__c storeConfig = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store.id ];
		storeConfig.Standard_Hourly_Rate__c = 100;
		storeConfig.Location_Number__c = '123';
		update storeConfig;
		
		Id assetInstalledProductsRecordTypeId = UtilityMethods.retrieveRecordTypeId('Installed_Products', 'Asset');
		
		Account vendor = [SELECT Id from Account where Vendor_Account_Type__c = 'Intercompany Consolidation Center'];

		Financial_Account_Number__c interCompanyCCDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANInventoryReceivedIntercompanyCCDebit'];
		Financial_Account_Number__c interCompanyCCCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANInventoryReceivedIntercompanyCCCredit'];
	
		Asset asset1 = new Asset(	Unit_Wholesale_Cost__c = 100,
									Quantity = 10,
									Sold_Order__c = soldOrder.id,
									RecordTypeId = assetInstalledProductsRecordTypeId,
									Store_Location__c = store.id,
									Name = 'asset1',
									AccountId = soldOrder.AccountId,
									ContactId = soldOrder.BillToContactId,
									Vendor__c = vendor.id
		);
		

		insert asset1;
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Inventory Received - Intercompany Consolidation Center']; 
		System.AssertEquals(1000, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(interCompanyCCDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(interCompanyCCCredit.Name, je.Credit_General_Ledger_Account__c);
		
		
		asset1.Quantity = 2;
		
		update asset1;

		je = [SELECT Id, Amount__c, Type__c, Sent_to_BaanERP__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Inventory Received - Intercompany Consolidation Center']; 
		System.AssertEquals(200, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());
		
		// Verify the account numbers 
		System.AssertEquals(interCompanyCCDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(interCompanyCCCredit.Name, je.Credit_General_Ledger_Account__c);
		
		je.Sent_to_BaanERP__c = true;
		update je;		
		
		asset1.Quantity = 3;
		update asset1;

		Journal_Entry__c je2 = [SELECT Id, Amount__c, Type__c, Sent_to_BaanERP__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Inventory Received - Intercompany Consolidation Center' AND Sent_to_BaanERP__c = false]; 

		System.AssertEquals(100, je2.Amount__c);
		System.AssertEquals(System.today(), je2.Date__c.date());
		// Verify the account numbers 
		System.AssertEquals(interCompanyCCDebit.Name, je2.Debit_General_Ledger_Account__c);
		System.AssertEquals(interCompanyCCCredit.Name, je2.Credit_General_Ledger_Account__c);
// TODO		
//		asset1.Quantity = 3;
//		update asset1;

/*		je2 = [SELECT Id, Amount__c, Type__c, Sent_to_BaanERP__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Inventory Received - Intercompany' AND Sent_to_BaanERP__c = false]; 

		System.AssertEquals(100, je2.Amount__c);
		System.AssertEquals(System.today(), je2.Date__c.date());
		// Verify the account numbers 
		System.AssertEquals(interCompanyDebit.Name, je2.Credit_General_Ledger_Account__c);
		System.AssertEquals(interCompanyCredit.Name, je2.Debit_General_Ledger_Account__c);*/
		
		Test.stopTest();
	}

	/*******************************************************
					positiveCreateExternalVendorAsset
	*******************************************************/
	static testmethod void positiveCreateExternalVendorAsset(){
		test.starttest();
		Order soldOrder = [SELECT Id, AccountId, BillToContactId FROM Order where Name='Sold Order 1'];		
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Store_Configuration__c storeConfig = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store.id ];
		storeConfig.Standard_Hourly_Rate__c = 100;
		storeConfig.Location_Number__c = '123';
		update storeConfig;
		
		Id assetInstalledProductsRecordTypeId = UtilityMethods.retrieveRecordTypeId('Installed_Products', 'Asset');
		
		Account vendor = [SELECT Id from Account where Vendor_Account_Type__c = 'External'];

		Financial_Account_Number__c externalVendorDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANInventoryReceivedExternalDebit'];
		Financial_Account_Number__c externalVendorCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANInventoryReceivedExternalCredit'];
	
		Asset asset1 = new Asset(	Unit_Wholesale_Cost__c = 100,
									Quantity = 10,
									Sold_Order__c = soldOrder.id,
									RecordTypeId = assetInstalledProductsRecordTypeId,
									Store_Location__c = store.id,
									Name = 'asset1',
									AccountId = soldOrder.AccountId,
									ContactId = soldOrder.BillToContactId,
									Vendor__c = vendor.id
		);
		

		insert asset1;
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Inventory Received - External Vendor']; 
		System.AssertEquals(1000, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(externalVendorDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(externalVendorCredit.Name, je.Credit_General_Ledger_Account__c);
		
		
		asset1.Quantity = 2;
		
		update asset1;

		je = [SELECT Id, Amount__c, Type__c, Sent_to_BaanERP__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Inventory Received - External Vendor']; 
		System.AssertEquals(200, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());
		
		// Verify the account numbers 
		System.AssertEquals(externalVendorDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(externalVendorCredit.Name, je.Credit_General_Ledger_Account__c);
		
		je.Sent_to_BaanERP__c = true;
		update je;		
		
		asset1.Quantity = 3;
		update asset1;

		Journal_Entry__c je2 = [SELECT Id, Amount__c, Type__c, Sent_to_BaanERP__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Inventory Received - External Vendor' AND Sent_to_BaanERP__c = false]; 

		System.AssertEquals(100, je2.Amount__c);
		System.AssertEquals(System.today(), je2.Date__c.date());
		// Verify the account numbers 
		System.AssertEquals(externalVendorDebit.Name, je2.Debit_General_Ledger_Account__c);
		System.AssertEquals(externalVendorCredit.Name, je2.Credit_General_Ledger_Account__c);
// TODO		
//		asset1.Quantity = 3;
//		update asset1;

/*		je2 = [SELECT Id, Amount__c, Type__c, Sent_to_BaanERP__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Inventory Received - Intercompany' AND Sent_to_BaanERP__c = false]; 

		System.AssertEquals(100, je2.Amount__c);
		System.AssertEquals(System.today(), je2.Date__c.date());
		// Verify the account numbers 
		System.AssertEquals(interCompanyDebit.Name, je2.Credit_General_Ledger_Account__c);
		System.AssertEquals(interCompanyCredit.Name, je2.Debit_General_Ledger_Account__c);*/
		
		Test.stopTest();
	}

	/*******************************************************
					positiveInventoryWriteOffAsset
	*******************************************************/
	static testmethod void positiveInventoryWriteOffAsset(){
		test.starttest();
		Order soldOrder = [SELECT Id, AccountId, BillToContactId FROM Order where Name='Sold Order 1'];		
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Store_Configuration__c storeConfig = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store.id ];
		storeConfig.Standard_Hourly_Rate__c = 100;
		storeConfig.Location_Number__c = '123';
		update storeConfig;
		
		Id assetInstalledProductsRecordTypeId = UtilityMethods.retrieveRecordTypeId('Installed_Products', 'Asset');
		
		Account vendor = [SELECT Id from Account where Vendor_Account_Type__c = 'External'];

		Financial_Account_Number__c invWriteOffDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANInventoryWriteOffDebit'];
		Financial_Account_Number__c invWriteOffCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANInventoryWriteOffCredit'];
	
		Asset asset1 = new Asset(	Unit_Wholesale_Cost__c = 100,
									Quantity = 10,
									Sold_Order__c = soldOrder.id,
									RecordTypeId = assetInstalledProductsRecordTypeId,
									Store_Location__c = store.id,
									Name = 'asset1',
									AccountId = soldOrder.AccountId,
									ContactId = soldOrder.BillToContactId,
									Vendor__c = vendor.id
		);
		

		insert asset1;

		asset1.Quantity_Written_Off__c = 1;
		
		update asset1;

		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Sent_to_BaanERP__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Inventory Write-Off']; 

		System.AssertEquals(100, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(invWriteOffDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(invWriteOffCredit.Name, je.Credit_General_Ledger_Account__c);
		
		
		asset1.Quantity_Written_Off__c = 2;
		update asset1;

		je = [SELECT Id, Amount__c, Type__c, Sent_to_BaanERP__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Inventory Write-Off']; 
		System.AssertEquals(200, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());
		
		// Verify the account numbers 
		System.AssertEquals(invWriteOffDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(invWriteOffCredit.Name, je.Credit_General_Ledger_Account__c);

		// Delete the Asset and verify the journal entry is deleted
		delete asset1;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Inventory Write-Off']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);
		
		
		Test.stopTest();
	}
}
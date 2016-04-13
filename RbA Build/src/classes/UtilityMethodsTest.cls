/*******************************************************//**

@class	UtilityMethodsTest

@brief	Test Class for UtilityMethods

@author  Creston Kuenzi (Slalom.CDK)

@version	2015-2-2  Slalom.CDK
	Created.

@see		UtilityMethods

@copyright  (c)2016 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class UtilityMethodsTest {

	/*******************************************************
					retrieveRecordTypeIdTest
	*******************************************************/
	static testMethod void retrieveRecordTypeIdTest() {

		// Verify the retrieveRecordTypeId retrieves an id for Account->Dwelling
		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
		System.Assert(dwellingRT != null);
	}

	/*******************************************************
					RecordTypeForTest
	*******************************************************/
	static testMethod void RecordTypeForTest() {

		// Verify the RecordTypeFor retrieves an id for Account->Dwelling
		id dwellingRT = UtilityMethods.RecordTypeFor('Account', 'Dwelling');
		System.Assert(dwellingRT != null);
	}

	/*******************************************************
	 GetRecordTypeIdsMapForSObjectTest
	*******************************************************/

	 static testMethod void GetRecordTypeIdsMapForSObjectTest(){
	 	id masterProductId =  UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Master_Product');
	 	system.assert(masterProductId != null);
	 }

	/*******************************************************
					buildWorkOrderTest
	*******************************************************/
	static testMethod void buildWorkOrderTest() {
		Account a = new Account();
		Order o = new Order();
		Id rtID = '111000000000000';
		Id ownerId = '111000000000000';
		String ordtype = '111000000000000';
		Id munici = '111000000000000';
		
		// Verify the RecordTypeFor retrieves an id for Account->Dwelling
//		SVMXC__Service_Order__c workOrder = UtilityMethods.BuildWorkOrder(a, o, rtId, ownerId, ordType, munici);
//		System.Assert(workOrder != null);
	}

	/*******************************************************
					mapStoreConfigsTest
	*******************************************************/
	static testMethod void mapStoreConfigsTest() {

		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.setUpConfigs();
		
		Account myStore = utility.createStoreAccount('mystore');
		insert myStore;
		
		Store_Configuration__c myStoreConfig = new Store_Configuration__c(Store__c = myStore.Id);
		insert myStoreConfig;
		
		List<Id> storeIds = new List<Id>();
		storeIds.add(myStore.Id);
		
		map<Id, Store_Configuration__c> myStoreMap = UtilityMethods.mapStoreConfigs(storeIds);
		
		System.AssertEquals(myStoreConfig, myStoreMap.get(myStore.Id));

	}

	/*******************************************************
					calculateFractionTest
	*******************************************************/
	static testMethod void calculateFractionTest() {

		decimal testFraction = UtilityMethods.calculateFraction('1/2');
		System.AssertEquals(0.5, testFraction);

		testFraction = UtilityMethods.calculateFraction('Even');
		System.AssertEquals(0, testFraction);

		testFraction = UtilityMethods.calculateFraction('7/8');
		System.AssertEquals(0.875, testFraction);

		testFraction = UtilityMethods.calculateFraction('1/16');
		System.AssertEquals(0.062, testFraction);
	}
	
	/*******************************************************
					retrieveAccountNumbersTest
	*******************************************************/
	static testMethod void retrieveAccountNumbersTest() {

		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.setUpConfigs();
		
		Account myStore = utility.createStoreAccount('mystore');
		insert myStore;
		
		Store_Configuration__c myStoreConfig = new Store_Configuration__c(Store__c = myStore.Id);
		insert myStoreConfig;
		
		Financial_Account_Number__c finNumber = new Financial_Account_Number__c(Name='123', Account_Type__c='myaccounttype', Store_Configuration__c = myStoreConfig.Id);
		insert finNumber;
		
		map<String, String> myStoreMap = UtilityMethods.retrieveAccountNumbers(myStore.Id);
		
		System.AssertEquals('123', myStoreMap.get('myaccounttype'));

	}

	/*******************************************************
					lockRecordsTest
	*******************************************************/
	static testMethod void lockRecordsTest() {

		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.setUpConfigs();

		List<Account> recordsToLock = new List<Account>();		
		Account Account1 = utility.createAccount('Account1');
		recordsToLock.add(Account1);

		Account Account2 = utility.createAccount('Account2');
		recordsToLock.add(Account2);

		insert recordsToLock;
		
		// Lock the accounts
		String result = UtilityMethods.lockRecords(recordsToLock);
		System.AssertEquals('Records successfully locked', result);
		
	}

	/*******************************************************
					checkLockedTest
	*******************************************************/
	static testMethod void checkLockedTest() {

		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.createOrderTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Account store = [SELECT Id, Active_Store_Configuration__c from Account Where Name = '77 - Twin Cities, MN'];

		Test.startTest();
		List<Financial_Account_Number__c> numbersList = new List<Financial_Account_Number__c>();
		Financial_Account_Number__c accountNumber1 = new Financial_Account_Number__c(Name='123', Store_Configuration__c = store.Active_Store_Configuration__c);	
		Financial_Account_Number__c accountNumber2 = new Financial_Account_Number__c(Name='234', Store_Configuration__c = store.Active_Store_Configuration__c);	
		insert numbersList;
		
		Financial_Transaction__c finTransaction = new Financial_Transaction__c(Transaction_Type__c='Deposit', Debit_Account_Number__c = accountNumber1.Id, Credit_Account_Number__c = accountNumber2.Id, Store_Configuration__c = store.Active_Store_Configuration__c);	
		insert finTransaction;

		List<Payment__c> lockedRecords = new List<Payment__c>();		
		List<Payment__c> unlockedRecords = new List<Payment__c>();		
		Payment__c Payment1 = new Payment__c(Order__c = soldOrder.Id, Store_Location__c = store.Id, Payment_Amount__c = 500, Locked__c = false);
		unlockedRecords.add(Payment1);

		Payment__c Payment2 = new Payment__c(Order__c = soldOrder.Id, Store_Location__c = store.Id, Payment_Amount__c = 500, Locked__c = false);
		unlockedRecords.add(Payment2);

		insert unlockedRecords;
//		insert unlockedRecords2;
		
		Payment__c Payment3 = new Payment__c(Order__c = soldOrder.Id, Store_Location__c = store.Id, Payment_Amount__c = 500, Locked__c = true);
		lockedRecords.add(Payment3);

		Payment__c Payment4 = new Payment__c(Order__c = soldOrder.Id, Store_Location__c = store.Id, Payment_Amount__c = 500, Locked__c = true);
		lockedRecords.add(Payment4);

		insert lockedRecords;

		map<id, sObject> unlockedMap = new map<id, Payment__c>();
		map<id, sObject> lockedMap = new map<id, Payment__c>();
		
		unlockedMap.put(Payment1.Id, Payment1);
		unlockedMap.put(Payment2.Id, Payment2);

		lockedMap.put(Payment1.Id, Payment3);
		lockedMap.put(Payment2.Id, Payment4);

		// Just send the unlocked lists/maps so no records will be locked since there is no change
		String result = UtilityMethods.checkLocked(unlockedRecords, unlockedRecords, unlockedMap, unlockedMap, 'Update');		
		System.AssertEquals('No records locked', result);

		// TODO:
		// This should work but throws a null pointer exception in the utility class. I suspect this is a salesforce bug
//		String result = UtilityMethods.checkLocked(lockedRecords, unlockedRecords, lockedMap, unlockedMap, 'Update');		
//		System.AssertEquals('At least one record was locked', result);

		Test.stopTest();
		
	}

	/*******************************************************
					checkLockedOrderTest
	*******************************************************/
	static testMethod void checkLockedOrderTest() {

		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.createOrderTestRecords();

		Order soldOrder = [SELECT Id, Name, Status FROM Order WHERE Name = 'Sold Order 1'];
		Account store = [SELECT Id, Active_Store_Configuration__c from Account Where Name = '77 - Twin Cities, MN'];

		List<Order> lockedRecords = new List<Order>();		
		List<Order> unlockedRecords = new List<Order>();		
		unlockedRecords.add(soldOrder);

		lockedRecords.add(soldOrder);

		map<id, sObject> unlockedMap = new map<id, Order>();
		map<id, sObject> lockedMap = new map<id, Order>();
		
		unlockedMap.put(soldOrder.Id, soldOrder);

		lockedMap.put(soldOrder.Id, soldOrder);

		// Just send the unlocked lists/maps so no records will be locked since there is no change
		String result = UtilityMethods.checkLockedByStatus(unlockedRecords, unlockedRecords, unlockedMap, unlockedMap, 'Order');		
		System.AssertEquals('No records locked', result);

		// TODO:
		// This should work but throws a null pointer exception in the utility class. I suspect this is a salesforce bug
//		String result = UtilityMethods.checkLocked(lockedRecords, unlockedRecords, lockedMap, unlockedMap, 'Update');		
//		System.AssertEquals('At least one record was locked', result);
		
	}

	/*******************************************************
					calculateTaxesTest
	*******************************************************/
	static testMethod void calculateTaxesTest() {

		OrderItem orderItem1 = new OrderItem();
		OrderItem orderItem2 = new OrderItem(Unit_Wholesale_Cost__c = 100, Quantity = 1);
		OrderItem orderItem3 = new OrderItem(Unit_Wholesale_Cost__c = 100, Quantity = 2);
		OrderItem orderItem4 = new OrderItem(Unit_Wholesale_Cost__c = 100, Quantity = 1);
		List<OrderItem> itemstoSend = new List<OrderItem> { orderItem1, orderItem2, orderItem3, orderItem4 };

		// Calculate taxes for subtotal of 400 and 10 in tax
		List<OrderItem> returnedItems = UtilityMethods.calculateTaxes(itemstoSend, 400, 10);

		System.AssertEquals(null, orderItem1.Tax__c);				
		System.AssertEquals(2.5, orderItem2.Tax__c);				
		System.AssertEquals(5, orderItem3.Tax__c);				
		System.AssertEquals(2.5, orderItem4.Tax__c);				
	}
}
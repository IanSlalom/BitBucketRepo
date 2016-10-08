/*******************************************************//**

@class	RMS_financialTransManRevRecognitionTest

@brief	Test Class for RMS_financialTransactionManager. 

		Separated the original test class into multiple test classes. This one focuses
		on revenue recognition.

@author  Creston Kuenzi (Slalom.CDK)

@version	2016-10-5  Slalom.CDK
	Created.

@see		RMS_financialTransactionManager

@copyright  (c)2016 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_financialTransManRevRecognitionTest {

	/*******************************************************
					setupData
	*******************************************************/
	@testSetup static void setupData(){

		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();

        User u = [select Id from User WHERE Id =: UserInfo.getUserId()];

        System.runAs(u) {

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
                  
        User communityUser = new User(  Alias = 'test123', 
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
                                        Username = 'tester9837589@noemail.com',  
                                        PortalRole = 'Worker',
                                        CommunityNickname = 'financialTest'
                                        );
       
        insert communityUser;
       }
		
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
									Pricebook2Id = Test.getStandardPricebookId(),
                             		recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Record_Type', 'Order')
								);
        Order order2 =  new Order(  Name='Service Order 1', 
                             AccountId = dwelling1.id, 
                             EffectiveDate= Date.Today(), 
                             Store_Location__c = store1.Id,                               
                             Status ='New', 
                             Sold_Order__c = order1.Id,
                             Customer_Pickup_All__c = TRUE,
                             Sales_Tax_Percent__c = 10,
                             BilltoContactId = contact1.id,
                             Service_Type__c = 'Service',                                             
                             Pricebook2Id = Test.getStandardPricebookId(),
                             recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order')
                            );

        Order order3 =  new Order(  Name='Service Order JIP', 
                             AccountId = dwelling1.id, 
                             EffectiveDate= Date.Today(), 
                             Store_Location__c = store1.Id,                               
                             Status ='New', 
                             Sold_Order__c = order1.Id,
                             Customer_Pickup_All__c = FALSE,
                             BilltoContactId = contact1.id,
                             Service_Type__c = 'Job In Progress',                                             
                             Pricebook2Id = Test.getStandardPricebookId(),
                             recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order')
                            );
        
        List<Order> ordersToInsert = new List<Order>{order1, order2, order3};  
        insert ordersToInsert;

			
		
		Account vend1 = testMethods.createIntercompanyVendorAccount('Intercompany');
		Account vend2 = testMethods.createIntercompanyCCVendorAccount('IntercompanyCC');
		Account vend3 = testMethods.createExternalVendorAccount('External');
		List<Account> vendsToInsert = new List<Account>{vend1,vend2,vend3};
		
		insert vendsToInsert;
		
		Pricebook2 pricebook1 =  testMethods.createPricebook2Name('Standard Price Book');
		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = vend1.id,
			recordTypeId=UtilityMethods.retrieveRecordTypeId('Master_Product', 'Product2')
		);

		insert product1;

		Product2 product2 = new Product2(
			Name='Service Product',
			Vendor__c = vend1.id,
			recordTypeId=UtilityMethods.retrieveRecordTypeId('Service_Product', 'Product2')
		);

		insert product2;
		
		PricebookEntry pricebookEntry1 = testMethods.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		PricebookEntry pricebookEntry2 = testMethods.createPricebookEntry(Test.getStandardPricebookId(), product2.id);
		List<PricebookEntry> pbsToInsert = new List<PricebookEntry>{pricebookEntry1,pricebookEntry2};
		insert pbsToInsert;

		
		OrderItem orderItem1 = new OrderItem(OrderId = order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 10000 );
		insert orderItem1;	

        OrderItem serviceOrderItem = new OrderItem(OrderId = order2.id, Customer_Pickup__c = 'Yes', Quote_Accepted__c = TRUE, Parent_Order_Item__c = orderItem1.id, PricebookentryId = pricebookEntry2.Id, Quanity_Ordered__c = 2, Service__c = true, Quantity = 2, UnitPrice = 100, Quote_Amount__c = 100);
		insert serviceOrderItem;	
		
		testMethods.createAllFinancialRecords(storeConfig1);

	}

	/*******************************************************
					positiveRevRecognizeDeposit
	*******************************************************/
	static testmethod void positiveRevRecognizeDeposit(){
		test.starttest();
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
		
		soldOrder.Revenue_Recognized_Date__c = Date.Today();
		update soldOrder;
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Rev Recognized - Deposit']; 
		System.AssertEquals(100, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Delete the Rev Recognized Date and verify the journal entry is deleted
		soldOrder.Revenue_Recognized_Date__c = null;
		update soldOrder;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Rev Recognized - Deposit']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);

		Test.stopTest();
	}

	/*******************************************************
					positiveRevRecognizeDiscount
	*******************************************************/
	static testmethod void positiveRevRecognizeDiscount(){
		test.starttest();
		Order soldOrder = [SELECT Id, AccountId, BillToContactId FROM Order where Name='Sold Order 1'];		
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Store_Configuration__c storeConfig = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store.id ];
		Store_Discount__c storeDiscount = new Store_Discount__c(Store_Configuration__c = storeConfig.Id );
		insert storeDiscount;
		Order_Discount__c orderDiscount = new Order_Discount__c(Store_Location__c = store.Id, Store_Discount__c = storeDiscount.Id, Order__c = soldOrder.Id, Discount_Amount__c = 50);
		insert orderDiscount;
		Id paymentDepositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = soldOrder.id,
												RecordTypeId = paymentDepositRecordTypeId,
												Payment_Type__c = 'Deposit',
												Store_Location__c = store.id,
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		insert payment1;
		
		soldOrder.Revenue_Recognized_Date__c = Date.Today();
		update soldOrder;
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Rev Recognized - Discount']; 
		System.AssertEquals(50, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Delete the Rev Recognized Date and verify the Discount journal entry is deleted
		soldOrder.Revenue_Recognized_Date__c = null;
		update soldOrder;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Rev Recognized - Discount']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);

		Test.stopTest();
	}

	/*******************************************************
					positiveRevRecognizeFinanceFees
	*******************************************************/
	static testmethod void positiveRevRecognizeFinanceFees(){
		test.starttest();
		Order soldOrder = [SELECT Id, AccountId, BillToContactId FROM Order where Name='Sold Order 1'];		
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Store_Configuration__c storeConfig = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store.id ];
		Store_Finance_Program__c storeFinance = new Store_Finance_Program__c(Store_Configuration__c = storeConfig.Id );
		insert storeFinance;
		Order_Financing__c orderFinancing = new Order_Financing__c(Store_Location__c = store.Id, Store_Finance_Program__c = storeFinance.Id, Related_Order__c = soldOrder.Id, Program_Fee__c = 50);
		insert orderFinancing;
		Id paymentDepositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Payment__c payment1 = new Payment__c(	Order__c = soldOrder.id,
												RecordTypeId = paymentDepositRecordTypeId,
												Payment_Type__c = 'Deposit',
												Store_Location__c = store.id,
												Payment_Amount__c = 100,
												Payment_Date__c = Date.Today()
												);
		insert payment1;
		
		soldOrder.Revenue_Recognized_Date__c = Date.Today();
		update soldOrder;
//TODO
//		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c FROM Journal_Entry__c 
//								WHERE Order__c =: soldOrder.Id AND Type__c = 'Rev Recognized - Finance Fees']; 
//		System.AssertEquals(50, je.Amount__c);
//		System.AssertEquals(System.today(), je.Date__c.date());

		// Delete the Rev Recognized Date and verify the journal entry is deleted
		soldOrder.Revenue_Recognized_Date__c = null;
		update soldOrder;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Rev Recognized - Finance Fees']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);

		Test.stopTest();
	}

	/*******************************************************
					positiveRevRecognizeAR
	*******************************************************/
	static testmethod void positiveRevRecognizeAR(){
		test.starttest();
		Order soldOrder = [SELECT Id, AccountId, BillToContactId FROM Order where Name='Sold Order 1'];		
		
		soldOrder.Revenue_Recognized_Date__c = Date.Today();
		update soldOrder;
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Rev Recognized - AR']; 
		System.AssertEquals(20000, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());
		
		// Delete the Rev Recognized Date and verify the journal entry is deleted
		soldOrder.Revenue_Recognized_Date__c = null;
		update soldOrder;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Rev Recognized - AR']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);
		
		Test.stopTest();
	}

	/*******************************************************
					positiveRevRecognizeServiceAR
	*******************************************************/
	static testmethod void positiveRevRecognizeServiceAR(){
		test.starttest();
		Order servicerequest = [SELECT Id, AccountId, BillToContactId FROM Order where Name='Service Order 1'];		

		Financial_Account_Number__c serviceARDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANRRServiceARDebit'];
		Financial_Account_Number__c serviceARCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANRRServiceARCredit'];
		
		servicerequest.Revenue_Recognized_Date__c = Date.Today();
		update servicerequest;
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: servicerequest.Id AND Type__c = 'Rev Recognized - Service AR']; 
		System.AssertEquals(100, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(serviceARDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(serviceARCredit.Name, je.Credit_General_Ledger_Account__c);
		
		// Delete the Rev Recognized Date and verify the journal entry is deleted
		servicerequest.Revenue_Recognized_Date__c = null;
		update servicerequest;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Rev Recognized - Service AR']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);
		
		Test.stopTest();
	}

	/*******************************************************
					positiveRevRecognizeServiceSalesTax
	*******************************************************/
	static testmethod void positiveRevRecognizeServiceSalesTax(){
		test.starttest();
		Order servicerequest = [SELECT Id, AccountId, BillToContactId, Sales_Tax__c, Billable_Tax_Amount__c, Sales_Tax_Percent__c FROM Order where Name='Service Order 1'];		

		Financial_Account_Number__c serviceSalesTaxDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANRRServiceTaxDebit'];
		Financial_Account_Number__c serviceSalesTaxCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANRRServiceTaxCredit'];
		
		servicerequest.Revenue_Recognized_Date__c = Date.Today();
		update servicerequest;
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c FROM Journal_Entry__c 
								WHERE Order__c =: servicerequest.Id AND Type__c = 'Rev Recognized - Service Tax']; 

		System.AssertEquals(10, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(serviceSalesTaxDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(serviceSalesTaxCredit.Name, je.Credit_General_Ledger_Account__c);
		
		// Delete the Rev Recognized Date and verify the journal entry is deleted
		servicerequest.Revenue_Recognized_Date__c = null;
		update servicerequest;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Rev Recognized - Service Tax']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);
		
		Test.stopTest();
	}

	/*******************************************************
					positiveRevRecognizeRefund
	*******************************************************/
	static testmethod void positiveRevRecognizeRefund(){
		test.starttest();
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
		insert refund1;
		
		soldOrder.Revenue_Recognized_Date__c = Date.Today();
		update soldOrder;
		
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Rev Recognized - Refund Deposit']; 
		System.AssertEquals(10, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());
		
		// Delete the Rev Recognized Date and verify the journal entry is deleted
		soldOrder.Revenue_Recognized_Date__c = null;
		update soldOrder;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Rev Recognized - AR']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);
		
		Test.stopTest();
	}

	/*******************************************************
					positiveRevRecognizeExternalLabor
	*******************************************************/
	static testmethod void positiveRevRecognizeExternalLabor(){

		test.starttest();
		Order soldOrder = [SELECT Id FROM Order where Name='Sold Order 1'];		
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Store_Configuration__c storeConfig = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store.id ];
		Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
		RbA_Work_Order__c workOrder1 = new RbA_Work_Order__c(  	RecordTypeId = serviceOrderVisitRecordTypeId, 
															    Sold_Order__c = soldOrder.id 
															 );
		insert workOrder1;		

        User communityUser = [SELECT Id FROM User WHERE username = 'tester9837589@noemail.com'];
 
		Resource__c res = new Resource__c(
			Active__c = true,
			Crew_Size__c = 5,
			Resource_Type__c = 'Installer',
			Retail_Location__c = storeConfig.Id,
			RbA_User__c = communityUser.Id
		);	
		insert res;
	
		Id laborLaborRecordTypeId = UtilityMethods.retrieveRecordTypeId('Labor', 'Labor__c');
		Labor__c labor1 = new Labor__c(	Related_Work_Order__c = workOrder1.id,
										Hours_Applied__c = 1,
										//Standard_Hourly_Rate__c=100,
										External_Labor_Amount__c = 100,
										Store_Location__c = store.id,
										Date_Applied__c = Date.Today(),
										Installer__c = res.Id
										);
		
		insert labor1;

		soldOrder.Revenue_Recognized_Date__c = Date.Today();
		update soldOrder;
		
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Rev Recognized - External Labor']; 
		System.AssertEquals(100, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());
		
		// Delete the Rev Recognized Date and verify the journal entry is deleted
		soldOrder.Revenue_Recognized_Date__c = null;
		update soldOrder;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Rev Recognized - AR']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);
		
		Test.stopTest();

	}

	/*******************************************************
					positiveCreateAndEditServiceLaborRevRecognizeExternal
	*******************************************************/
	/* NEEDS COMMUNITIES ACTIVATED */
	static testmethod void positiveCreateAndEditServiceLaborRevRecognizeExternal(){
		test.starttest();
		Order serviceRequest = [SELECT Id FROM Order where Name='Service Order 1'];		

		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Store_Configuration__c storeConfig = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store.id ];
		Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
		RbA_Work_Order__c workOrder1 = new RbA_Work_Order__c(  	RecordTypeId = serviceOrderVisitRecordTypeId, 
															    Sold_Order__c = serviceRequest.id 
															 );
		insert workOrder1;		

        User communityUser = [SELECT Id FROM User WHERE username = 'tester9837589@noemail.com'];
 
		Resource__c res = new Resource__c(
			Active__c = true,
			Crew_Size__c = 5,
			Resource_Type__c = 'Installer',
			Retail_Location__c = storeConfig.Id,
			RbA_User__c = communityUser.Id
		);	
		insert res;
	
		Id laborLaborRecordTypeId = UtilityMethods.retrieveRecordTypeId('Labor', 'Labor__c');
		Labor__c labor1 = new Labor__c(	Related_Work_Order__c = workOrder1.id,
										Hours_Applied__c = 1,
										//Standard_Hourly_Rate__c=100,
										External_Labor_Amount__c = 100,
										Store_Location__c = store.id,
										Date_Applied__c = Date.Today(),
										Installer__c = res.Id
										);
		
		insert labor1;

		serviceRequest.Revenue_Recognized_Date__c = Date.Today();
		update serviceRequest;

		Financial_Account_Number__c extServiceRRLaborDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANServiceRRExternalLaborDebit'];
		Financial_Account_Number__c extServiceRRLaborCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANServiceRRExternalLaborCredit'];

		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
								FROM Journal_Entry__c WHERE Labor__c =: labor1.Id AND Type__c = 'Rev Recognized - Service External Labor']; 
		System.AssertEquals(100, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(extServiceRRLaborDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(extServiceRRLaborCredit.Name, je.Credit_General_Ledger_Account__c);


		// Delete the Rev Recognized Date and verify the journal entry is deleted
		serviceRequest.Revenue_Recognized_Date__c = null;
		update serviceRequest;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Rev Recognized - Service External Labor']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);
		test.stoptest();

	}	

	/*******************************************************
					positiveCreateAndEditServiceJIPLaborPostRecognizedExternal
	*******************************************************/
	/* NEEDS COMMUNITIES ACTIVATED */
	static testmethod void positiveCreateAndEditServiceJIPLaborPostRecognizedExternal(){
		test.starttest();
		Order serviceRequest = [SELECT Id FROM Order where Name='Service Order JIP'];		
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Store_Configuration__c storeConfig = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store.id ];
		Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
		RbA_Work_Order__c workOrder1 = new RbA_Work_Order__c(  	RecordTypeId = serviceOrderVisitRecordTypeId, 
															    Sold_Order__c = serviceRequest.id 
															 );
		insert workOrder1;		

        User communityUser = [SELECT Id FROM User WHERE username = 'tester9837589@noemail.com'];
 
		Resource__c res = new Resource__c(
			Active__c = true,
			Crew_Size__c = 5,
			Resource_Type__c = 'Installer',
			Retail_Location__c = storeConfig.Id,
			RbA_User__c = communityUser.Id
		);	
		insert res;
	
		Id laborLaborRecordTypeId = UtilityMethods.retrieveRecordTypeId('Labor', 'Labor__c');
		Labor__c labor1 = new Labor__c(	Related_Work_Order__c = workOrder1.id,
										Hours_Applied__c = 1,
										//Standard_Hourly_Rate__c=100,
										External_Labor_Amount__c = 100,
										Store_Location__c = store.id,
										Date_Applied__c = Date.Today(),
										Installer__c = res.Id
										);
		
		insert labor1;

		serviceRequest.Revenue_Recognized_Date__c = Date.Today();
		update serviceRequest;

		Financial_Account_Number__c extServiceLaborRRJIPDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANServiceRRExternalLaborJIPDebit'];
		Financial_Account_Number__c extServiceLaborRRJIPCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANServiceRRExternalLaborJIPCredit'];

		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
								FROM Journal_Entry__c WHERE Labor__c =: labor1.Id AND Type__c = 'Rev Recognized - Service External Labor - JIP']; 
		System.AssertEquals(100, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(extServiceLaborRRJIPDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(extServiceLaborRRJIPCredit.Name, je.Credit_General_Ledger_Account__c);

		// Delete the Rev Recognized Date and verify the journal entry is deleted
		serviceRequest.Revenue_Recognized_Date__c = null;
		update serviceRequest;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Rev Recognized - Service External Labor - JIP']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);
		test.stoptest();

	}	

	/*******************************************************
					positiveRevRecognizeCOGS
	*******************************************************/
	static testmethod void positiveRevRecognizeCOGS(){
		test.starttest();
		Order soldOrder = [SELECT Id, AccountId, BillToContactId FROM Order where Name='Sold Order 1'];		
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Store_Configuration__c storeConfig = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store.id ];
		storeConfig.Standard_Hourly_Rate__c = 100;
		storeConfig.Location_Number__c = '123';
		update storeConfig;
		
		Id assetInstalledProductsRecordTypeId = UtilityMethods.retrieveRecordTypeId('Installed_Products', 'Asset');
		
		Account vendor = [SELECT Id from Account where Vendor_Account_Type__c = 'Intercompany'];
	
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
		
		soldOrder.Revenue_Recognized_Date__c = Date.Today();
		update soldOrder;
		
		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c FROM Journal_Entry__c 
								WHERE Order__c =: soldOrder.Id AND Type__c = 'Rev Recognized - COGS']; 
		System.AssertEquals(1000, je.Amount__c);
		System.AssertEquals(System.today(), je.Date__c.date());
		
		// Delete the Rev Recognized Date and verify the journal entry is deleted
		soldOrder.Revenue_Recognized_Date__c = null;
		update soldOrder;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Rev Recognized - COGS']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);
		
		Test.stopTest();
	}

	public class anException extends Exception {}

}
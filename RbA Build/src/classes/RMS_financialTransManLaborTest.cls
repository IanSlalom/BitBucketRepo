/*******************************************************//**

@class	RMS_financialTransManLaborTest

@brief	Test Class for RMS_financialTransactionManager

		Separated the original test class into multiple test classes. This one focuses
		on the labor test classes 

@author  Creston Kuenzi (Slalom.CDK)

@version	2016-10-5  Slalom.CDK
	Created.

@see		RMS_financialTransactionManager

@copyright  (c)2016 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_financialTransManLaborTest {

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
        
        Order order1 = new Order(   Name='Sold Order 1', 
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
                             Customer_Pickup_All__c = FALSE,
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
                    noInstallerLabor
    *******************************************************/
    /* NEEDS COMMUNITIES ACTIVATED */
    static testmethod void noInstallerLabor(){
        test.starttest();
        Order soldOrder = [SELECT Id FROM Order where Name='Sold Order 1'];     
        Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];     
        Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
        RbA_Work_Order__c workOrder1 = new RbA_Work_Order__c(   RecordTypeId = serviceOrderVisitRecordTypeId, 
                                                                Sold_Order__c = soldOrder.id 
                                                             );
        insert workOrder1;      

        
        Id laborLaborRecordTypeId = UtilityMethods.retrieveRecordTypeId('Labor', 'Labor__c');
        Labor__c labor1 = new Labor__c( Related_Work_Order__c = workOrder1.id,
                                        Hours_Applied__c = 1,
                                        //Standard_Hourly_Rate__c=100,
                                        External_Labor_Amount__c = 100,
                                        Store_Location__c = store.id,
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
        test.stoptest();
    }
    
    /*******************************************************
                    positiveCreateAndEditLaborExternal
    *******************************************************/
    /* NEEDS COMMUNITIES ACTIVATED */
    static testmethod void positiveCreateAndEditLaborExternal(){
        test.starttest();
        Order soldOrder = [SELECT Id FROM Order where Name='Sold Order 1'];     
        Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];     
        Store_Configuration__c storeConfig = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store.id ];
        Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
        RbA_Work_Order__c workOrder1 = new RbA_Work_Order__c(   RecordTypeId = serviceOrderVisitRecordTypeId, 
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
        Labor__c labor1 = new Labor__c( Related_Work_Order__c = workOrder1.id,
                                        Hours_Applied__c = 1,
                                        //Standard_Hourly_Rate__c=100,
                                        External_Labor_Amount__c = 100,
                                        Store_Location__c = store.id,
                                        Date_Applied__c = Date.Today(),
                                        Installer__c = res.Id
                                        );
        
        insert labor1;

        Financial_Account_Number__c extLaborDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANExternalLaborDebit'];
        Financial_Account_Number__c extLaborCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANExternalLaborCredit'];

        Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
                                FROM Journal_Entry__c WHERE Labor__c =: labor1.Id AND Type__c = 'External Labor']; 
        System.AssertEquals(100, je.Amount__c);
        System.AssertEquals('External Labor', je.Type__c);
        System.AssertEquals(System.today(), je.Date__c.date());

        // Verify the account numbers 
        System.AssertEquals(extLaborDebit.Name, je.Debit_General_Ledger_Account__c);
        System.AssertEquals(extLaborCredit.Name, je.Credit_General_Ledger_Account__c);

        labor1.External_Labor_Amount__c = 200;
        update labor1;
        je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
                    FROM Journal_Entry__c WHERE Labor__c =: labor1.Id AND Type__c = 'External Labor']; 
        System.AssertEquals(200, je.Amount__c);
        System.AssertEquals('External Labor', je.Type__c);
        System.AssertEquals(System.today(), je.Date__c.date());

        // Verify the account numbers 
        System.AssertEquals(extLaborDebit.Name, je.Debit_General_Ledger_Account__c);
        System.AssertEquals(extLaborCredit.Name, je.Credit_General_Ledger_Account__c);

        // Delete the Labor and verify the journal entry is deleted
        delete labor1;

        decimal jeCount = 0;
        for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'External Labor']) {
            jeCount += 1;
        }

        System.AssertEquals(0, jeCount);
        test.stoptest();

    }   


	/*******************************************************
					positiveCreateAndEditPostRecognizedLaborExternal
	*******************************************************/
	/* NEEDS COMMUNITIES ACTIVATED */
	static testmethod void positiveCreateAndEditPostRecognizedLaborExternal(){
		test.starttest();
		Order soldOrder = [SELECT Id FROM Order where Name='Sold Order 1'];		
		soldOrder.Revenue_Recognized_Date__c = Date.Today();
		update soldOrder;
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

		Financial_Account_Number__c extPRLaborDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANPRExternalLaborDebit'];
		Financial_Account_Number__c extPRLaborCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANPRExternalLaborCredit'];

		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
								FROM Journal_Entry__c WHERE Labor__c =: labor1.Id AND Type__c = 'Post Recognized External Labor']; 
		System.AssertEquals(100, je.Amount__c);
		System.AssertEquals('Post Recognized External Labor', je.Type__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(extPRLaborDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(extPRLaborCredit.Name, je.Credit_General_Ledger_Account__c);

		labor1.External_Labor_Amount__c = 200;
		update labor1;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
					FROM Journal_Entry__c WHERE Labor__c =: labor1.Id AND Type__c = 'Post Recognized External Labor']; 
		System.AssertEquals(200, je.Amount__c);
		System.AssertEquals('Post Recognized External Labor', je.Type__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(extPRLaborDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(extPRLaborCredit.Name, je.Credit_General_Ledger_Account__c);

		// Delete the Labor and verify the journal entry is deleted
		delete labor1;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Post Recognized External Labor']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);
		test.stoptest();

	}	

	/*******************************************************
					positiveCreateAndEditServiceLaborExternal
	*******************************************************/
	/* NEEDS COMMUNITIES ACTIVATED */
	static testmethod void positiveCreateAndEditServiceLaborExternal(){
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

		Financial_Account_Number__c extServiceLaborDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANServiceExternalLaborDebit'];
		Financial_Account_Number__c extServiceLaborCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANServiceExternalLaborCredit'];

		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
								FROM Journal_Entry__c WHERE Labor__c =: labor1.Id]; 
		System.AssertEquals(100, je.Amount__c);
		System.AssertEquals('Service External Labor', je.Type__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(extServiceLaborDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(extServiceLaborCredit.Name, je.Credit_General_Ledger_Account__c);

		labor1.External_Labor_Amount__c = 200;
		update labor1;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
					FROM Journal_Entry__c WHERE Labor__c =: labor1.Id]; 
		System.AssertEquals(200, je.Amount__c);
		System.AssertEquals('Service External Labor', je.Type__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(extServiceLaborDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(extServiceLaborCredit.Name, je.Credit_General_Ledger_Account__c);

		// Delete the Labor and verify the journal entry is deleted
		delete labor1;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Service External Labor']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);
		test.stoptest();

	}	

	/*******************************************************
					positiveCreateAndEditServiceLaborPostRecognizedExternal
	*******************************************************/
	/* NEEDS COMMUNITIES ACTIVATED */
	static testmethod void positiveCreateAndEditServiceLaborPostRecognizedExternal(){
		test.starttest();
		Order serviceRequest = [SELECT Id FROM Order where Name='Service Order 1'];		
		serviceRequest.Revenue_Recognized_Date__c = Date.Today();
		update serviceRequest;

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

		Financial_Account_Number__c extServicePRLaborDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANServicePRExternalLaborDebit'];
		Financial_Account_Number__c extServicePRLaborCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANServicePRExternalLaborCredit'];

		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
								FROM Journal_Entry__c WHERE Labor__c =: labor1.Id]; 
		System.AssertEquals(100, je.Amount__c);
		System.AssertEquals('Post Recognized Service External Labor', je.Type__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(extServicePRLaborDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(extServicePRLaborCredit.Name, je.Credit_General_Ledger_Account__c);

		labor1.External_Labor_Amount__c = 200;
		update labor1;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
					FROM Journal_Entry__c WHERE Labor__c =: labor1.Id]; 
		System.AssertEquals(200, je.Amount__c);
		System.AssertEquals('Post Recognized Service External Labor', je.Type__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(extServicePRLaborDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(extServicePRLaborCredit.Name, je.Credit_General_Ledger_Account__c);

		// Delete the Labor and verify the journal entry is deleted
		delete labor1;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Post Recognized Service External Labor']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);
		test.stoptest();

	}	


	/*******************************************************
					positiveCreateAndEditServiceJIPLaborExternal
	*******************************************************/
	/* NEEDS COMMUNITIES ACTIVATED */
	static testmethod void positiveCreateAndEditServiceJIPLaborExternal(){
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

		Financial_Account_Number__c extServiceLaborJIPDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANServiceExternalLaborJIPDebit'];
		Financial_Account_Number__c extServiceLaborJIPCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANServiceExternalLaborJIPCredit'];

		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
								FROM Journal_Entry__c WHERE Labor__c =: labor1.Id]; 
		System.AssertEquals(100, je.Amount__c);
		System.AssertEquals('Service External Labor - JIP', je.Type__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(extServiceLaborJIPDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(extServiceLaborJIPCredit.Name, je.Credit_General_Ledger_Account__c);

		labor1.External_Labor_Amount__c = 200;
		update labor1;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
					FROM Journal_Entry__c WHERE Labor__c =: labor1.Id]; 
		System.AssertEquals(200, je.Amount__c);
		System.AssertEquals('Service External Labor - JIP', je.Type__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(extServiceLaborJIPDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(extServiceLaborJIPCredit.Name, je.Credit_General_Ledger_Account__c);

		// Delete the Labor and verify the journal entry is deleted
		delete labor1;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Service External Labor - JIP']) {
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
		serviceRequest.Revenue_Recognized_Date__c = Date.Today();
		update serviceRequest;
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

		Financial_Account_Number__c extServiceLaborPRJIPDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANServicePRExternalLaborJIPDebit'];
		Financial_Account_Number__c extServiceLaborPRJIPCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANServicePRExternalLaborJIPCredit'];

		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
								FROM Journal_Entry__c WHERE Labor__c =: labor1.Id]; 
		System.AssertEquals(100, je.Amount__c);
		System.AssertEquals('Post Recognized Service External Labor - JIP', je.Type__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(extServiceLaborPRJIPDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(extServiceLaborPRJIPCredit.Name, je.Credit_General_Ledger_Account__c);

		labor1.External_Labor_Amount__c = 200;
		update labor1;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
					FROM Journal_Entry__c WHERE Labor__c =: labor1.Id]; 
		System.AssertEquals(200, je.Amount__c);
		System.AssertEquals('Post Recognized Service External Labor - JIP', je.Type__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(extServiceLaborPRJIPDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(extServiceLaborPRJIPCredit.Name, je.Credit_General_Ledger_Account__c);

		// Delete the Labor and verify the journal entry is deleted
		delete labor1;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Post Recognized Service External Labor - JIP']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);
		test.stoptest();

	}	
	
	/*******************************************************
					positiveCreateAndEditLaborInternal
	*******************************************************/
	static testmethod void positiveCreateAndEditLaborInternal(){
		test.starttest();
		Order soldOrder = [SELECT Id FROM Order where Name='Sold Order 1'];		
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Store_Configuration__c storeConfig = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store.id ];
		storeConfig.Standard_Hourly_Rate__c = 100;
		update storeConfig;
		Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
		RbA_Work_Order__c workOrder1 = new RbA_Work_Order__c(  	RecordTypeId = serviceOrderVisitRecordTypeId, 
															    Sold_Order__c = soldOrder.id 
															 );
		insert workOrder1;		
		
		Id laborLaborRecordTypeId = UtilityMethods.retrieveRecordTypeId('Labor', 'Labor__c');
		Labor__c labor1 = new Labor__c(			Related_Work_Order__c = workOrder1.id,
												Hours_Applied__c = 1,
												//Standard_Hourly_Rate__c=100,
												//External_Labor_Amount__c = 100,
												Store_Location__c = store.id,
												Date_Applied__c = Date.Today()
												);
		insert labor1;

		Financial_Account_Number__c intLaborDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANInternalLaborDebit'];
		Financial_Account_Number__c intLaborCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANInternalLaborCredit'];

		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
									FROM Journal_Entry__c WHERE Labor__c =: labor1.Id AND Type__c = 'Internal Labor']; 
		System.AssertEquals(100, je.Amount__c);
		System.AssertEquals('Internal Labor', je.Type__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(intLaborDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(intLaborCredit.Name, je.Credit_General_Ledger_Account__c);
		
		labor1.Hours_Applied__c = 2;
		update labor1;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
						FROM Journal_Entry__c WHERE Labor__c =: labor1.Id AND Type__c = 'Internal Labor']; 
		System.AssertEquals(200, je.Amount__c);
		System.AssertEquals('Internal Labor', je.Type__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account numbers 
		System.AssertEquals(intLaborDebit.Name, je.Debit_General_Ledger_Account__c);
		System.AssertEquals(intLaborCredit.Name, je.Credit_General_Ledger_Account__c);

		// Delete the Labor and verify the journal entry is deleted
		delete labor1;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Internal Labor']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);

		Test.StopTest();
	}

	/*******************************************************
					positiveCreateLaborMiscReimbursement
	*******************************************************/
	static testmethod void positiveCreateLaborMiscReimbursement(){
		test.starttest();
		Order soldOrder = [SELECT Id FROM Order where Name='Sold Order 1'];		
		Account store = [SELECT id FROM Account WHERE Name='77 - Twin Cities, MN'];		
		Store_Configuration__c storeConfig = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store.id ];
		storeConfig.Standard_Hourly_Rate__c = 100;
		storeConfig.Location_Number__c = 'SLN';
		update storeConfig;

		Id laborMiscReimbursementRecordTypeId = UtilityMethods.retrieveRecordTypeId('Misc_Reimbursement', 'Labor__c');

        Financial_Account_Number__c glAccount1 = new Financial_Account_Number__c (  Store_Configuration__c = storeConfig.id, Name = 'GLAccountNumber', Account_Type__c = 'Misc Reimbursement');
        insert glAccount1;

        User communityUser = [SELECT Id FROM User WHERE username = 'tester9837589@noemail.com'];
 		
		Resource__c res = new Resource__c(
			Active__c = true,
			Crew_Size__c = 5,
			Resource_Type__c = 'Installer',
			Retail_Location__c = storeConfig.Id,
			RbA_User__c = communityUser.Id
		);	
		insert res;
		
		Labor__c labor1 = new Labor__c(			RecordTypeId = laborMiscReimbursementRecordTypeId,
												//Standard_Hourly_Rate__c=100,
												External_Labor_Amount__c = 100,
												Store_Location__c = store.id,
												Date_Applied__c = Date.Today(),
												Installer__c = res.id,
												GL_Account__c = glAccount1.id
												);
		insert labor1;

		Financial_Account_Number__c miscReimbursementDebit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANMiscReimbursementDebit'];
		Financial_Account_Number__c miscReimbursementCredit = [Select Id, Name From Financial_Account_Number__c Where Name = 'FANMiscReimbursementCredit'];

		Journal_Entry__c je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
									FROM Journal_Entry__c WHERE Labor__c =: labor1.Id AND Type__c = 'Misc Reimbursement']; 
		System.AssertEquals(100, je.Amount__c);
		System.AssertEquals('Misc Reimbursement', je.Type__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account number is the store location number inserted in the the gl account number
		System.AssertEquals('GLAccountNumSLNber', je.Debit_General_Ledger_Account__c);
		System.AssertEquals(miscReimbursementCredit.Name, je.Credit_General_Ledger_Account__c);

		labor1.External_Labor_Amount__c = 200;
		update labor1;
		je = [SELECT Id, Amount__c, Type__c, Order__c, Store_Location__c, Date__c, Debit_General_Ledger_Account__c, Credit_General_Ledger_Account__c 
				FROM Journal_Entry__c WHERE Labor__c =: labor1.Id AND Type__c = 'Misc Reimbursement']; 
		System.AssertEquals(200, je.Amount__c);
		System.AssertEquals('Misc Reimbursement', je.Type__c);
		System.AssertEquals(System.today(), je.Date__c.date());

		// Verify the account number is the store location number + the gl account number
// TODO - this is not working
//		System.AssertEquals('GLAccountNumSLNber', je.Debit_General_Ledger_Account__c);
		System.AssertEquals(miscReimbursementCredit.Name, je.Credit_General_Ledger_Account__c);

		// Delete the Labor and verify the journal entry is deleted
		delete labor1;

		decimal jeCount = 0;
		for (Journal_Entry__c j : [SELECT Id from Journal_Entry__c WHERE Type__c = 'Misc Reimbursement']) {
			jeCount += 1;
		}

		System.AssertEquals(0, jeCount);

		Test.StopTest();
	}
					
	public class anException extends Exception {}
}
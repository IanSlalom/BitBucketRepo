/*
Testing utility methods Anthony Strafaccia 2015
	
This is a class designed to aid in the creating of data during tests.
	
Currently the following objects are included:
	Account
	Contact
	User
	Pricebook2
	Product2
	PricebookEntry
	Opportunity
	OpportunityLineItem
	Quote
	QuoteLineItem

Custom Objects to be added in RbA Project
	Account/Contact junction object
	Measurements

*/
@isTest
public with sharing class TestUtilityMethods {

    public TestUtilityMethods() {}
	 
	
	public void setUpConfigs(){
		//Creating RMS_Settings__c
    	RMS_Settings__c customSetting1 = new RMS_Settings__c(Value__c = '1234567890', Name='Data Loading Profile ID');
		insert customSetting1;
		
		Account store1 = createStoreAccount('77 - Twin Cities, MN');
		insert store1;
		
		//Creating RMS_Queue_Settings__c
		Group Order_Queue = createQueue('Order_Queue');
		insert Order_Queue;
		QueueSobject Order_Queue_Link = createQueueSobject(Order_Queue.id ,'Order');
		insert Order_Queue_Link;
		
		
    	Group Install_Work_Order_Queue = createQueue('Install_Work_Order_Queue');
		insert Install_Work_Order_Queue;
		QueueSobject Install_Work_Order_Link = createQueueSobject(Install_Work_Order_Queue.id ,'RbA_Work_Order__c');
		insert Install_Work_Order_Link;
		
		Group Tech_Measure_Work_Order_Queue = createQueue('Tech_Measure_Work_Order');
		insert Tech_Measure_Work_Order_Queue;
		QueueSobject Tech_Measure_Work_Order_Link = createQueueSobject(Tech_Measure_Work_Order_Queue.id ,'RbA_Work_Order__c');
		insert Tech_Measure_Work_Order_Link;
		
		Group Permit_Work_Order_Queue = createQueue('Permit_Work_Order');
		insert Permit_Work_Order_Queue;
		QueueSobject Permit_Work_Order_Link = createQueueSobject(Permit_Work_Order_Queue.id ,'RbA_Work_Order__c');
		insert Permit_Work_Order_Link;
		
		Group Action_Work_Order_Queue = createQueue('Action_Work_Order');
		insert Action_Work_Order_Queue;
		QueueSobject Action_Work_Order_Link = createQueueSobject(Action_Work_Order_Queue.id ,'RbA_Work_Order__c');
		insert Action_Work_Order_Link;
		
		Group LSWP_Work_Order_Queue = createQueue('LSWP_Work_Order');
		insert LSWP_Work_Order_Queue;
		QueueSobject LSWP_Work_Order_Link = createQueueSobject(LSWP_Work_Order_Queue.id ,'RbA_Work_Order__c');
		insert LSWP_Work_Order_Link;
		
    	Store_Configuration__c storeConfig = new Store_Configuration__c(
    		Store__c = store1.id,
        	Order_Queue_Id__c = Order_Queue.id,
    		Install_Work_Order_Queue_Id__c = Install_Work_Order_Queue.id,
        	Tech_Measure_Work_Order_Queue_Id__c = Tech_Measure_Work_Order_Queue.id,
        	//Permit_Work_Order_Queue_Id__c = Permit_Work_Order_Queue.id,
        	//Action_Work_Order_Queue_Id__c = Action_Work_Order_Queue.id,
        	
        	Building_Permit_Work_Order_Queue_Id__c = Permit_Work_Order_Queue.id,
        	Historical_Work_Order_Queue_Id__c = Action_Work_Order_Queue.id,
        	HOA_Work_Order_Queue_Id__c = Action_Work_Order_Queue.id,
        	LSWP_WO_Owner_ID__c = LSWP_Work_Order_Queue.id
        	
        	);
    	insert storeConfig;

    	store1.Active_Store_Configuration__c = storeConfig.Id;
    	update store1;
		
		
		Back_Office_Checklist_Configuration__c backOfficeChecklist1 = new Back_Office_Checklist_Configuration__c(
			Store_Configuration__c = storeConfig.id,
			Contract_Signed__c = true,
			Lien_Rights_Signed__c = true
			);
		insert backOfficeChecklist1;
		
		
		
	}
	
	
	
    public Account createAccount(String x){
        Account theAccount = new Account(
            Name = x+'Test Account',
            AccountNumber = x+'1234567890',
            Phone = '(763) 555-2000'
        );
        return theAccount;
    }

    public Account createDwellingAccount(String x){
        Account theAccount = new Account(
            Name = x,
            AccountNumber = x+'1234567890',
            Phone = '(763) 555-2000',
            recordTypeId = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account')	
        );
        return theAccount;
    }
    
    public Account createStoreAccount(String x){
        Account theAccount = new Account(
            Name = x,
            AccountNumber = x+'1234567890',
            Phone = '(763) 555-2000',
            recordTypeId = UtilityMethods.retrieveRecordTypeId('Store', 'Account')	
        );
        return theAccount;
    }

    public Account createVendorAccount(String x){
		Account account1 = createAccount(x);
		account1.recordTypeId = UtilityMethods.retrieveRecordTypeId('Vendor', 'Account'); 	
		return account1;
    }
    
    
	public Contact createContact(Id accountId, String x){
        Contact testContact = new Contact(
            AccountId = accountId,
            FirstName = x+'Test',
            LastName = x+'Contact',
            Email = x+'test@testing.com',
            Phone = '(763) 555-0000'
        );
        return testContact;
    }
    

    public User createUser(Id profileID){
    	User testUser = new User(
    		FirstName = 'TestFirst',
    		LastName = 'TestLast',
    		Username = 'apextest@test.com', 
    		Email = 'test@test.com', 
    		Alias = 'test', 
    		CommunityNickname = 'test', 
    		TimeZoneSidKey = 'America/Mexico_City', 
    		LocaleSidKey = 'en_US', 
    		EmailEncodingKey= 'UTF-8', 
    		ProfileId = profileID, 
    		LanguageLocaleKey = 'en_US'
    		
    	);
    	return testUser;
    }
  
    public Pricebook2 createPricebook2(){
    	Pricebook2 testPricebook = new Pricebook2(
    		Name = 'Test PriceBook'
    	);
		return testPricebook;
    }
    public Pricebook2 createPricebook2Name(String name){
    	Pricebook2 testPricebook = new Pricebook2(
    		Name = name
    	);
		return testPricebook;
    }
    public Product2 createProduct(){
    	Product2 testProduct = new Product2(
    		Name='Test Product',
    		IsActive=true
		);
		return testProduct;
    } 
     
    public PricebookEntry createPricebookEntry(Id priceBookId, Id productId){
    	PricebookEntry testPricebookEntry = new PricebookEntry(
    		Pricebook2Id = priceBookId, 
    		Product2Id = productId,
    		UnitPrice = 1,
    		IsActive = true
    	);
		return 	testPricebookEntry;
    }
    

    public Opportunity createOpportunity(Id accountId, String stage){
        Opportunity testOpportunity = new Opportunity(
            Name = 'TestOpportunity',
            AccountId = accountId,
            StageName = stage
        );
        if( stage.contains('Closed') ){
        	testOpportunity.CloseDate = Date.today().adddays(-1);
        }else{
            testOpportunity.CloseDate = Date.today().addYears(1);
        }
        
        return testOpportunity;
    }
          

	public OpportunityLineItem createOpportunityLineItem(Id opportunityId, Id pricebookEntryId){
    	OpportunityLineItem theOLI = new OpportunityLineItem(
	    //	Product2Id = productId,
	    	Quantity = 1,
	    	TotalPrice = 1,
	    	OpportunityId = opportunityId,
	    	PricebookEntryId = pricebookEntryId
    	);
    	return theOLI;
    }
 
     
	public Quote createQuote(Id oppId, Id pricebook2Id){
    	Quote testQuote = new Quote(
    		Name='testQuote',
    		isSold__c = true,
    		OpportunityId = oppId,
    		Pricebook2Id = pricebook2Id
    	);
    	return testQuote;
	}
    
    
    public QuoteLineItem createQuoteLineItem(Id pricebookEntryId, Id quoteId){
    	QuoteLineItem QLI = new QuoteLineItem(
    	PricebookEntryId = pricebookEntryId,
    	QuoteId = quoteId,
    	Quantity = 1,
    	UnitPrice = 1
    	);
    	return QLI;
    }
    
    public Group createQueue(String groupName){
	    Group theQueue = new Group(Name = groupName, Type = 'Queue');
		return theQueue;
	}
	
	public QueueSobject createQueueSobject(Id groupId, String typeOfObject){
		QueueSobject theQueueSobject = new QueueSObject(QueueId = groupId, SobjectType = typeOfObject);
		return theQueueSobject;
	}

	public Municipality__c createMunicipality(Id storeId, Id recordTypeId){
		Municipality__c muni = new Municipality__c(For_Retail_Location__c = storeId, RecordTypeId = recordTypeId);
		return muni;
	}

	public Municipality_Match__c createMunicipalityMatch(Id municipalityId, String zipcode, String city){
		Municipality_Match__c mm = new Municipality_Match__c(Agency_Name__c = municipalityId, Zip_Code__c = zipcode, City_Township__c = city );
		return mm;
	}
 	
 	public void createSalesAppt(Id userId, Datetime apptStartDateTime, boolean createWithOrder){
 		setUpConfigs();
 		Account dwelling1 = createDwellingAccount('1');
 		insert dwelling1;
 		
 		Account store1 = [SELECT id FROM Account Where Name = '77 - Twin Cities, MN'][0];
 		dwelling1.Store_Location__c = store1.id;
 		update dwelling1;
 		
 		Contact contact1 = createContact(dwelling1.id , '1');
 		insert contact1;
 		
 		Opportunity opp1 = createOpportunity(dwelling1.id, 'New');
 		insert opp1;
 		
 		Event event1 = new Event(WhatId = opp1.id, StartDateTime = apptStartDateTime, WhoId = contact1.id, OwnerId = userId, DurationInMinutes = 60);
 		insert event1;
 		
 		OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId = contact1.id, OpportunityId = opp1.id, Role = 'Business User');
 		insert ocr1;
 		
 		if(createWithOrder = true){
	 		
	 		Quote quote1 = createQuote(opp1.id,Test.getStandardPricebookId());
			insert quote1;
			Product2 prod1 = createProduct();
			insert prod1;

			PricebookEntry pbEntry1 = createPricebookEntry(Test.getStandardPricebookId(), prod1.id);
			insert pbEntry1;
    		
			QuoteLineItem qli1 = createQuoteLineItem(pbEntry1.Id, quote1.Id);
			insert  qli1;
			
			opp1.SyncedQuoteId = quote1.id;
			update opp1;
			
			opp1.StageName = 'Closed Won';
			update opp1;
	
 		}
 	}
 	
 	public void createTMAppt(Id userId, Datetime apptStartDateTime){
 		setUpConfigs();
 		Account dwelling1 = createDwellingAccount('1');
 		insert dwelling1;
 		
 		Account store1 = [SELECT id FROM Account Where Name = '77 - Twin Cities, MN'][0];
 		dwelling1.Store_Location__c = store1.id;
 		update dwelling1;
 		
 		Contact contact1 = createContact(dwelling1.id , '1');
 		insert contact1;
 		
 		Opportunity opp1 = createOpportunity(dwelling1.id, 'New');
 		insert opp1;
 		
 		Quote quote1 = createQuote(opp1.id,Test.getStandardPricebookId());
		insert quote1;
		Product2 prod1 = createProduct();
		insert prod1;

		PricebookEntry pbEntry1 = createPricebookEntry(Test.getStandardPricebookId(), prod1.id);
		insert pbEntry1;
    		
		QuoteLineItem qli1 = createQuoteLineItem(pbEntry1.Id, quote1.Id);
		insert  qli1;
			
		opp1.SyncedQuoteId = quote1.id;
		update opp1;
		
		
		Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
		RbA_Work_Order__c techWorkOrder = new RbA_Work_Order__c(  	RecordTypeId = serviceOrderVisitRecordTypeId, 
															                Opportunity__c = opp1.id,
															                Order_Type__c = 'Tech Measure'  
															                    );
    	insert techWorkOrder;
		
		opp1.StageName = 'Closed Won';
		update opp1;
		
		Order ord1 = [SELECT Id FROM Order WHERE OpportunityId = :opp1.id][0];
		
		List<RbA_Work_Order__c> workOrder = [SELECT Id FROM RbA_Work_Order__c  WHERE Opportunity__c = :opp1.id AND Sold_Order__c = :ord1.id];
		
		Event event1 = new Event(WhatId = workOrder[0].id, StartDateTime = apptStartDateTime, WhoId = contact1.id, OwnerId = userId, DurationInMinutes = 60);
 		insert event1;
		
		OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId = contact1.id, OpportunityId = opp1.id, Role = 'Business User');
 		insert ocr1;
 	}
 	
	public void createOrderTestRecords(){
		
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.setUpConfigs();
		
		Account account1 = utility.createVendorAccount('Vendor Account 1 ');
		insert account1;

		Account account2 = new Account(	Name = 'RbA',
										AccountNumber = '1234567890',
										Phone = '(763) 555-2000'
									);
		insert account2;

		Account dwelling = utility.createDwellingAccount('Dwelling Account');

		Account store = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
		dwelling.Store_Location__c = store.Id;
		insert dwelling;
	
		Contact contact = new Contact(LastName = 'Jones', AccountId = dwelling.Id);
		insert contact;

		Pricing_Configuration__c pricingConfig= new Pricing_Configuration__c(
			Name='Pricing Config'
		);
		
		insert pricingConfig;

		
//		Pricebook2 pricebook1 =  utility.createPricebook2Name('Standard Price Book');
//		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Master Product',
			Vendor__c = account1.id,
			RecordTypeId = UtilityMethods.RecordTypeFor('Product2', 'Master_Product')
//			Product_Configuration__c = prodConfig.Id
		);
		
		insert product1;

		Product_Configuration__c prodConfig= new Product_Configuration__c(
			Name='Product Config',
			Product__c = product1.Id
		);
		
		insert prodConfig;

		Product2 product2 = new Product2(
			Name='Child Product',
			Vendor__c = account1.id,
			UI_Minimum__c = 0,
			UI_Maximum__c = 40,
			
			Master_Product__c = product1.Id,
			RecordTypeId = UtilityMethods.RecordTypeFor('Product2', 'Child_Product')
		);
		
		insert product2;

		Opportunity opp1 = utility.createOpportunity(dwelling.id, 'Closed - Won');
		insert opp1;
		
		PricebookEntry pricebookEntry1 = utility.createPricebookEntry(Test.getStandardPricebookId(), product1.id);		
		pricebookEntry1.Pricing_Configuration__c = pricingConfig.Id;
		insert pricebookEntry1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store.Id,
									BillToContactId = contact.Id,
									Opportunity = opp1, 									
									Status ='Draft', 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		
		OrderItem orderItem1 = new OrderItem(OrderId = Order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100 );
		insert orderItem1;		
		System.Debug('***************Test.getStandardPricebookId()=' +Test.getStandardPricebookId());
//		System.Debug('***************pricebook1=' +pricebook1.Id);



	}
 	
 /*
Tech Measure Appointment
method createTMAppt (Id userId, Datetime apptStartDateTime) should create
 	dwelling
 	contact
 	opportunity linked to dwelling
 	SVMAX work order linked to opportunity and order
 	event - StartDateTime should be set to the parameter 
 	
 	WhatId should be the SVMAX work order Id
 	Who Id should be the primary contact
 	Owner should be the passed in User
 	OpportunityConactRole links contact to the Opportunity
 	create a quote with line items and an order with line items linked to the opportunity
 	
 */
 	
 	
 	
}
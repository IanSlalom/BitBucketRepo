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

		User u = [select Id from User WHERE Id =: UserInfo.getUserId()];
		u.Store_Locations__c = '77 - Twin Cities, MN';
		u.Default_Store_Location__c = '77 - Twin Cities, MN';
		update u;
		system.runAs(u){
			id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
			id storeRT = UtilityMethods.retrieveRecordTypeId('Store', 'Account');
		
			Account store1 = createStoreAccount('77 - Twin Cities, MN');
			store1.Store_Number__c = '0123';
			insert store1;

			Account masterAccount = new Account(name = 'Unassigned Account', RecordTypeId = dwellingRT);
			insert masterAccount;

			RMS_Settings__c customSetting2 = new RMS_Settings__c(Value__c = masterAccount.Id, Name='Unassigned Account Id');
			insert customSetting2;
		
		
			//Creating RMS_Queue_Settings__c
			List<SObject> list2 = new List<SObject>();
			List<SObject> list1 = new List<SObject>();
			Group Order_Queue = createQueue('Order_Queue');
			list1.add(Order_Queue);
			Group Install_Work_Order_Queue = createQueue('Install_Work_Order_Queue');
			list1.add(Install_Work_Order_Queue);
			Group Tech_Measure_Work_Order_Queue = createQueue('Tech_Measure_Work_Order');
			list1.add(Tech_Measure_Work_Order_Queue);
			Group Permit_Work_Order_Queue = createQueue('Permit_Work_Order');
			list1.add(Permit_Work_Order_Queue);
			Group Action_Work_Order_Queue = createQueue('Action_Work_Order');
			list1.add(Action_Work_Order_Queue);
			Group LSWP_Work_Order_Queue = createQueue('LSWP_Work_Order');
			list1.add(LSWP_Work_Order_Queue);
			insert list1;

			QueueSobject Order_Queue_Link = createQueueSobject(Order_Queue.id ,'Order');
			list2.add(Order_Queue_Link);
			QueueSobject Install_Work_Order_Link = createQueueSobject(Install_Work_Order_Queue.id ,'RbA_Work_Order__c');
			list2.add(Install_Work_Order_Link);
			QueueSobject Tech_Measure_Work_Order_Link = createQueueSobject(Tech_Measure_Work_Order_Queue.id ,'RbA_Work_Order__c');
			list2.add(Tech_Measure_Work_Order_Link);
			QueueSobject Permit_Work_Order_Link = createQueueSobject(Permit_Work_Order_Queue.id ,'RbA_Work_Order__c');
			list2.add(Permit_Work_Order_Link);
			QueueSobject Action_Work_Order_Link = createQueueSobject(Action_Work_Order_Queue.id ,'RbA_Work_Order__c');
			list2.add(Action_Work_Order_Link);
			QueueSobject LSWP_Work_Order_Link = createQueueSobject(LSWP_Work_Order_Queue.id ,'RbA_Work_Order__c');
			list2.add(LSWP_Work_Order_Link);
		
			Store_Configuration__c storeConfig = new Store_Configuration__c(
				Store__c = store1.id,
				Order_Queue_Id__c = Order_Queue.id,
				Install_Work_Order_Queue_Id__c = Install_Work_Order_Queue.id,
				Tech_Measure_Work_Order_Queue_Id__c = Tech_Measure_Work_Order_Queue.id,
				Standard_Hourly_Rate__c = 50,		   
				Building_Permit_Work_Order_Queue_Id__c = Permit_Work_Order_Queue.id,
				Historical_Work_Order_Queue_Id__c = Action_Work_Order_Queue.id,
				HOA_Work_Order_Queue_Id__c = Action_Work_Order_Queue.id,
				LSWP_WO_Owner_ID__c = LSWP_Work_Order_Queue.id,
				Location_Number__c = '777',
				Order_Number__c = 0000001
				);
			list2.add(storeConfig);
			insert list2;

			store1.Active_Store_Configuration__c = storeConfig.Id;
			update store1;
			
			rSuite_Configuration__c rc = new rSuite_Configuration__c();
			rc.Store_Configuration__c = storeConfig.Id;
			rc.Unsold_Age_In_Months__c = 4;
			insert rc;
			
			storeConfig.rSuite_Configuration__c = rc.Id;
			update storeConfig;
		
			Back_Office_Checklist_Configuration__c backOfficeChecklist1 = new Back_Office_Checklist_Configuration__c(
				Store_Configuration__c = storeConfig.id,
				Contract_Signed__c = true,
				Lien_Rights_Signed__c = true
				);
			insert backOfficeChecklist1;
		}
			
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
			recordTypeId = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account'),
			ShippingPostalCode = '11111',
			ShippingStreet = x   
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
		account1.Baan_Business_Partner_Number__c = '12345';
		return account1;
	}
	
	public Account createIntercompanyVendorAccount(String x) {
		Account account1 = createVendorAccount(x);
		account1.Vendor_Account_Type__c = 'Intercompany';   
		return account1;		
	}
	public Account createIntercompanyCCVendorAccount(String x) {
		Account account1 = createVendorAccount(x);
		account1.Vendor_Account_Type__c = 'Intercompany Consolidation Center';   
		return account1;		
	}
	public Account createExternalVendorAccount(String x) {
		Account account1 = createVendorAccount(x);
		account1.Vendor_Account_Type__c = 'External';   
		return account1;		
	}	 
	
	public Contact createContact(Id accountId, String x){
		Contact testContact = new Contact(
			AccountId = accountId,
			FirstName = x+'Test',
			LastName = x+'Contact',
			Email = x+'test@testing.com',
			Phone = '(763) 555-0000',
			HomePhone = '(763) 555-1111',
			MobilePhone = '(763) 555-2222',
			Salutation = 'Mr.',
			Comments__c = 'This is a comment.',
			Preferred_Method_of_Contact__c = 'Mobile Phone'
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
			CommunityNickname = 'test' + String.valueOf(System.currentTimeMillis()),
			TimeZoneSidKey = 'America/Mexico_City', 
			LocaleSidKey = 'en_US', 
			EmailEncodingKey= 'UTF-8', 
			ProfileId = profileID, 
			LanguageLocaleKey = 'en_US'
			
		);
		return testUser;
	}
  
	public Pricebook2 createPricebook2(){
		return createPricebook2('Test PriceBook', null);
	}

	public Pricebook2 createPricebook2(String Name, Id storeConfigId){
		Pricebook2 testPricebook = new Pricebook2();
		testPricebook.Name = Name;
		testPricebook.IsActive = true;
		if (storeConfigId != null) {
			testPricebook.Store_Configuration__c = storeConfigId;
		}
		return testPricebook;
	}

	public Pricebook2 createPricebook2Name(String name){
		return createPricebook2(name, null);
	}

	public Product2 createProduct(){
		return createProduct('Test Product', null);
	} 

	public Product2 createProduct(String Name, Id recordTypeId){
		Product2 testProduct = new Product2(
			Name= Name,
			IsActive=true
		);
		if (recordTypeId != null) {
			testProduct.RecordTypeId = recordTypeId;
		}
		return testProduct;
	} 
	 
	public PricebookEntry createPricebookEntry(Id priceBookId, Id productId){
		PricebookEntry testPricebookEntry = new PricebookEntry(
			Pricebook2Id = priceBookId, 
			Product2Id = productId,
			UnitPrice = 1,
			IsActive = true
		);
		return  testPricebookEntry;
	}
	

	public Opportunity createOpportunity(String name, Id accountId, String stage, Id ownerId, Date closeDate){
		Opportunity testOpportunity = new Opportunity(
			Name = name,
			AccountId = accountId,
			StageName = stage
		);
		if( stage.contains('Closed') ){
			if (closeDate == null) {
				testOpportunity.CloseDate = Date.today().adddays(-1);
			} else {
				testOpportunity.CloseDate = closeDate;
			}
		}else{
			if (closeDate == null) {
				testOpportunity.CloseDate = Date.today().addYears(1);
			} else {
				testOpportunity.CloseDate = closeDate;
			}
		}
		if (ownerId != null)
			testOpportunity.OwnerId = ownerId;
		
		return testOpportunity;
	}

	public Opportunity createOpportunity(String name, Id accountId, String stage, Id ownerId){
		return createOpportunity(name, accountId, stage, ownerId, null);
	}
	public Opportunity createOpportunity(Id accountId, String stage){
		return createOpportunity('TestOpportunity', accountId, stage, null);
	}
		  

	public OpportunityLineItem createOpportunityLineItem(Id opportunityId, Id pricebookEntryId){
		OpportunityLineItem theOLI = new OpportunityLineItem(
		//  Product2Id = productId,
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
	
	
	public QuoteLineItem createQuoteLineItem(Id masterProdId, Id quoteId, Id childProdId){
		QuoteLineItem QLI = new QuoteLineItem(
		PricebookEntryId = masterProdId,
		QuoteId = quoteId,
		Quantity = 1,
		UnitPrice = 1,
		Child_Product_Pricebook_Entry_Id__c = childProdId,
		Calculated_Price__c = 100
		);
		return QLI;
	}
	
	public QuoteLineItem createQuoteLineItem(Id pricebookEntryId, Id quoteId){
		return createQuoteLineItem(pricebookEntryId, quoteId, null);
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
		return this.createMunicipality(storeId, recordTypeId, '12345', 'Bedrock', 'Granite', 'MN');
	}

	public Municipality__c createMunicipality(Id storeId, Id recordTypeId, String zip, String city, String county, String state){
		Municipality__c muni = new Municipality__c(For_Retail_Location__c = storeId, RecordTypeId = recordTypeId, County__c = county, City_Township__c = city,
				  State__c = state, Name = zip + ',' + city + ' ' + state);
		return muni;
	}

	public Municipality_Match__c createMunicipalityMatch(Id municipalityId, String zipcode, String city){
		Municipality_Match__c mm = new Municipality_Match__c(Agency_Name__c = municipalityId, Zip_Code__c = zipcode, City_Township__c = city );
		return mm;
	}
	
	static Integer counter = 0;
	public void createSalesAppt(Id userId, Datetime apptStartDateTime, boolean createWithOrder, boolean createWithQuote){
		createSalesAppt(userId, apptStartDateTime, createWithOrder, createWithQuote, 'New', '22');
	}
	public void createSalesAppt(Id userId, Datetime apptStartDateTime, boolean createWithOrder, boolean createWithQuote, String oppStage){
		createSalesAppt(userId, apptStartDateTime, createWithOrder, createWithQuote, oppStage, '22');
	}
	public void createSalesAppt(Id userId, Datetime apptStartDateTime, boolean createWithOrder, boolean createWithQuote, String oppStage, String testName){
		Account store1 = [SELECT id, Active_Store_Configuration__c FROM Account Where Name = '77 - Twin Cities, MN'][0];
		Account dwelling1 = createDwellingAccount(testName + System.now());
		dwelling1.Store_Location__c = store1.id;
		insert dwelling1;
		
		List<SObject> itemsToInsert = new List<SObject>();		
		Contact contact1 = createContact(dwelling1.id , testName + counter++);
		itemsToInsert.add(contact1);
		
		Opportunity opp1 =  createOpportunity('TestOpp1', dwelling1.id, oppStage, userId, apptStartDateTime.date());
//		Opportunity opp1 = createOpportunity(dwelling1.id, oppStage, apptStartDateTime.date());
		opp1.OwnerId = userId;
		opp1.rSuite_Id__c = 'examplersuiteId' + counter;
		opp1.Store_Location__c = store1.Id;
		itemsToInsert.add(opp1);
		insert itemsToInsert;
		
		//clean out the list
		itemsToInsert.clear();

		Event event1 = new Event(WhatId = opp1.id, StartDateTime = apptStartDateTime, WhoId = contact1.id, OwnerId = userId, DurationInMinutes = 60, Type = 'Sales Appointment');
		itemsToInsert.add(event1);
		
		OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId = contact1.id, OpportunityId = opp1.id, Role = 'Business User');
		itemsToInsert.add(ocr1);
		insert itemsToInsert;
		
		if(createWithQuote || createWithOrder){
			//clean out the list
			itemsToInsert.clear();

			Pricebook2 pb = createPricebook2('SATestPB' + testName, store1.Active_Store_Configuration__c);
			itemsToInsert.add(pb);
			insert itemsToInsert;
			itemsToInsert.clear();

			Quote quote1 = createQuote(opp1.id, pb.Id);
			quote1.isSold__c = true;
			itemsToInsert.add(quote1);
			insert itemsToInsert;
			
			QuoteLineItem qli1 = createQLIMasterChildProducts(pb.Id, quote1.Id);
			insert  qli1;
			
			// generate the order
			if (createWithOrder) {
				opp1.StageName = 'Sold';
				update opp1;
			}

		}
	}
	
	/* creates a tech measure apptment 
	 * with an opportunity, quote and order
	 */
	public void createTMAppt(Id userId, Datetime apptStartDateTime){

		Account store1 = [SELECT id, Name, Active_Store_Configuration__c FROM Account Where Name = '77 - Twin Cities, MN'][0];
		Account dwelling1 = createDwellingAccount('1');
		dwelling1.Store_Location__c = store1.id;
		dwelling1.OwnerId = userId;
		insert dwelling1;

		List<SObject> itemsToInsert = new List<SObject>();		
		Contact contact1 = createContact(dwelling1.id , '1');
		itemsToInsert.add(contact1);
		
		Opportunity opp1 = createOpportunity('TMAppt',dwelling1.id, 'New', userId);
		opp1.OwnerId = userId;
		opp1.rSuite_Id__c = 'examplersuiteId';
		opp1.Store_Location__c = store1.Id;
		itemsToInsert.add(opp1);
		insert itemsToInsert;

		//clean out the list
		itemsToInsert.clear();
		
		OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId = contact1.id, OpportunityId = opp1.id, Role = 'Business User');
		itemsToInsert.add(ocr1);

		Pricebook2 pb = createPricebook2('TMTestPB', store1.Active_Store_Configuration__c);
		itemsToInsert.add(pb);
		insert itemsToInsert;
		itemsToInsert.clear();

		Quote quote1 = createQuote(opp1.id, pb.Id);
		quote1.isSold__c = true;
		itemsToInsert.add(quote1);
		insert itemsToInsert;
			
		QuoteLineItem qli1 = createQLIMasterChildProducts(pb.Id, quote1.Id);
		insert  qli1;
			
		// generate the order
		opp1.StageName = 'Sold';
		update opp1;
		
		// setup the event
		Order ord1 = [SELECT Id FROM Order WHERE OpportunityId = :opp1.id][0];
		List<RbA_Work_Order__c> workOrder = [SELECT Id FROM RbA_Work_Order__c  WHERE Opportunity__c = :opp1.id AND Sold_Order__c = :ord1.id];
		Event event1 = new Event(WhatId = workOrder[0].id, StartDateTime = apptStartDateTime, WhoId = contact1.id, OwnerId = userId, DurationInMinutes = 60, Type = 'Tech Measure');
		insert event1;
		
	}
	
	/* creates quoteline item. master product and child product, pricebook entries 
	 */
	public QuoteLineItem createQLIMasterChildProducts(Id pbId, Id quoteId){

		Id rtId = UtilityMethods.RecordTypeFor('Product2', 'Master_Product');
		List<Product2> masterProdList = [select Id, Name, RecordTypeId from Product2 where Name = 'Master Product' and RecordTypeId = :rtId];
		Product2 masterProd = null;
		if (masterProdList.size() == 0) {
			masterProd = createProduct('Master Product', rtId);
			insert masterProd;
		} else {
			masterProd = masterProdList[0];
		}

		rtId = UtilityMethods.RecordTypeFor('Product2', 'Child_Product');
		List<Product2> childProdList = [select Id, Name, RecordTypeId from Product2 where Name = 'Child Product' and RecordTypeId = :rtId];
		Product2 childProd = null;
		if (childProdList.size() == 0) {
			childProd = createProduct('Child Product', rtId);
			childProd.Master_Product__c = masterProd.Id;
			insert childProd;
		} else {
			childProd = childProdList[0];
		}

		Id standardPBId = Test.getStandardPricebookId();
		List<PricebookEntry> pbeList = [select Id, Product2Id, Pricebook2Id, UnitPrice, isActive from PricebookEntry where Pricebook2Id in (:pbId, :standardPBId)];
		PricebookEntry pbEntry1 = null;
		PricebookEntry pbEntry2 = null;
		PricebookEntry pbEntry3 = null;
		PricebookEntry pbEntry4 = null;
		
		for (PricebookEntry pbe : pbeList) {
			if (pbe.Product2Id == childProd.Id && pbe.Pricebook2Id == standardPBId) {
				pbEntry2 = pbe;
			}
			if (pbe.Product2Id == masterProd.Id && pbe.Pricebook2Id == standardPBId) {
				pbEntry1 = pbe;
			}
			if (pbe.Product2Id == childProd.Id && pbe.Pricebook2Id == pbId) {
				pbEntry4 = pbe;
			}
			if (pbe.Product2Id == masterProd.Id && pbe.Pricebook2Id == pbId) {
				pbEntry3 = pbe;
			}
		}
		
		if (pbEntry1 == null) {
			pbEntry1 = createPricebookEntry(standardPBId, masterProd.id);
			insert pbEntry1;
		}
		if (pbEntry2 == null) {
			pbEntry2 = createPricebookEntry(standardPBId, childProd.id);
			insert pbEntry2;
		}
		if (pbEntry3 == null) {
			pbEntry3 = createPricebookEntry(pbId, masterProd.id);
			insert pbEntry3;
		}
		if (pbEntry4 == null) {
			pbEntry4 = createPricebookEntry(pbId, childProd.id);
			insert pbEntry4;
		}
			
		QuoteLineItem qli1 = createQuoteLineItem(pbEntry3.Id, quoteId, pbEntry4.Id);
		return  qli1;
	}
	
	/* creates quote discount and store discount 
	 */
	public Quote_Discount__c createQuoteDiscount(Id storeId, Id quoteId){

		Id rtId = UtilityMethods.RecordTypeFor('Store_Discount__c', 'dollar_off');
		List<Store_Discount__c> storeDiscountList = [select Id, Name, RecordTypeId from Store_Discount__c where Store_Configuration__c = :storeId];
		Store_Discount__c storeDiscount = null;
		if (storeDiscountList.size() == 0) {
			storeDiscount = new Store_Discount__c();
			storeDiscount.RecordTypeId = rtId;
			storeDiscount.Store_Configuration__c = storeId;
			storeDiscount.Active__c = true;
			storeDiscount.Discount_Amount__c = 1;
			storeDiscount.Discount_Product__c = 'Unit';
			storeDiscount.Name = 'TestStoreDiscount';
			insert storeDiscount;
		} else {
			storeDiscount = storeDiscountList[0];
		}

		Quote_Discount__c qd = new Quote_Discount__c();
		qd.Quote__c = quoteId;
		qd.Discount_Amount__c = 1;
		qd.Store_Discount__c = storeDiscount.Id;
		return qd;
	}

	/* creates quote financing and store financinig 
	 */
	public Quote_Financing__c createQuoteFinancing(Id storeId, Id quoteId){

		Id rtId = UtilityMethods.RecordTypeFor('Store_Finance_Program__c', 'Cash_Payment');
		List<Store_Finance_Program__c> storeFPList = [select Id, Name, RecordTypeId from Store_Finance_Program__c where Store_Configuration__c = :storeId];
		Store_Finance_Program__c storeFP = null;
		if (storeFPList.size() == 0) {
			storeFP = new Store_Finance_Program__c();
			storeFP.RecordTypeId = rtId;
			storeFP.Store_Configuration__c = storeId;
			storeFP.Active__c = true;
			storeFP.Name = 'TestStoreFinanceProgram';
			insert storeFP;
		} else {
			storeFP = storeFPList[0];
		}

		Quote_Financing__c qf = new Quote_Financing__c();
		qf.Related_Quote__c = quoteId;
		qf.Amount_Financed__c = 1;
		qf.Store_Finance_Program__c = storeFP.Id;
		return qf;
	}

	public void createOrderTestRecords(){
		
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.setUpConfigs();
		
		Account account1 = utility.createVendorAccount('Vendor Account 1 ');
		insert account1;

		Account account2 = new Account( Name = 'RbA',
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

		Product2 product1 = new Product2(
			Name='Master Product',
			Vendor__c = account1.id,
			RecordTypeId = UtilityMethods.RecordTypeFor('Product2', 'Master_Product')
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
		
		Order order1 = new Order(   Name='Sold Order 1', 
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
//	  System.Debug('***************pricebook1=' +pricebook1.Id);

	}

	public void createAllFinancialRecords(Store_Configuration__c storeConfig1){

		List<Financial_Account_Number__c> FANSToInsert = new List<Financial_Account_Number__c>();

		// Create all financial account numbers
		// Payments
		Financial_Account_Number__c FANDepositDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANDepositDebit');
		FANSToInsert.add(FANDepositDebit);
		Financial_Account_Number__c FANDepositCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANDepositCredit');
		FANSToInsert.add(FANDepositCredit);
		Financial_Account_Number__c FANDepositCheckRefundDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANDepositCheckRefundDebit');
		FANSToInsert.add(FANDepositCheckRefundDebit);
		Financial_Account_Number__c FANDepositCheckRefundCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANDepositCheckRefundCredit');
		FANSToInsert.add(FANDepositCheckRefundCredit);
		Financial_Account_Number__c FANFinalPaymentDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANFinalPaymentDebit');
		FANSToInsert.add(FANFinalPaymentDebit);
		Financial_Account_Number__c FANFinalPaymentCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANFinalPaymentCredit');
		FANSToInsert.add(FANFinalPaymentCredit);
		Financial_Account_Number__c FANFinalPaymentCheckRefundDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANFinalPaymentCheckRefundDebit');
		FANSToInsert.add(FANFinalPaymentCheckRefundDebit);
		Financial_Account_Number__c FANFinalPaymentCheckRefundCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANFinalPaymentCheckRefundCredit');
		FANSToInsert.add(FANFinalPaymentCheckRefundCredit);
		Financial_Account_Number__c FANNonSufficientFundsDepositDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANNonSufficientFundsDepositDebit');
		FANSToInsert.add(FANNonSufficientFundsDepositDebit);
		Financial_Account_Number__c FANNonSufficientFundsDepositCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANNonSufficientFundsDepositCredit');
		FANSToInsert.add(FANNonSufficientFundsDepositCredit);
		Financial_Account_Number__c FANNonSufficientFundsFinalPaymentDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANNonSufficientFundsFinalPaymentDebit');
		FANSToInsert.add(FANNonSufficientFundsFinalPaymentDebit);
		Financial_Account_Number__c FANNonSufficientFundsFinalPaymentCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANNonSufficientFundsFinalPaymentCredit');
		FANSToInsert.add(FANNonSufficientFundsFinalPaymentCredit);
		Financial_Account_Number__c FANRRDepositDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANRRDepositDebit');
		FANSToInsert.add(FANRRDepositDebit);
		Financial_Account_Number__c FANRRDepositCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANRRDepositCredit');
		FANSToInsert.add(FANRRDepositCredit);
		Financial_Account_Number__c FANRRDepositRefundDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANRRDepositRefundDebit');
		FANSToInsert.add(FANRRDepositRefundDebit);
		Financial_Account_Number__c FANRRDepositRefundCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANRRDepositRefundCredit');
		FANSToInsert.add(FANRRDepositRefundCredit);

		// Inventory
		Financial_Account_Number__c FANInventoryReceivedIntercompanyDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANInventoryReceivedIntercompanyDebit');
		FANSToInsert.add(FANInventoryReceivedIntercompanyDebit);
		Financial_Account_Number__c FANInventoryReceivedIntercompanyCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANInventoryReceivedIntercompanyCredit');
		FANSToInsert.add(FANInventoryReceivedIntercompanyCredit);
		Financial_Account_Number__c FANInventoryReceivedIntercompanyCCDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANInventoryReceivedIntercompanyCCDebit');
		FANSToInsert.add(FANInventoryReceivedIntercompanyCCDebit);
		Financial_Account_Number__c FANInventoryReceivedIntercompanyCCCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANInventoryReceivedIntercompanyCCCredit');
		FANSToInsert.add(FANInventoryReceivedIntercompanyCCCredit);
		Financial_Account_Number__c FANInventoryReceivedExternalDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANInventoryReceivedExternalDebit');
		FANSToInsert.add(FANInventoryReceivedExternalDebit);
		Financial_Account_Number__c FANInventoryReceivedExternalCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANInventoryReceivedExternalCredit');
		FANSToInsert.add(FANInventoryReceivedExternalCredit);
		Financial_Account_Number__c FANInventoryWriteOffDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANInventoryWriteOffDebit');
		FANSToInsert.add(FANInventoryWriteOffDebit);
		Financial_Account_Number__c FANInventoryWriteOffCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANInventoryWriteOffCredit');
		FANSToInsert.add(FANInventoryWriteOffCredit);
		Financial_Account_Number__c FANPRInventoryWriteOffDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANPRInventoryWriteOffDebit');
		FANSToInsert.add(FANPRInventoryWriteOffDebit);
		Financial_Account_Number__c FANPRInventoryWriteOffCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANPRInventoryWriteOffCredit');
		FANSToInsert.add(FANPRInventoryWriteOffCredit);

		Financial_Account_Number__c FANServiceInventoryReceivedIntercompanyDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANServiceInventoryReceivedIntercompanyDebit');
		FANSToInsert.add(FANServiceInventoryReceivedIntercompanyDebit);
		Financial_Account_Number__c FANServiceInventoryReceivedIntercompanyCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANServiceInventoryReceivedIntercompanyCredit');
		FANSToInsert.add(FANServiceInventoryReceivedIntercompanyCredit);
		Financial_Account_Number__c FANServiceInventoryReceivedIntercompanyCCDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANServiceInventoryReceivedIntercompanyCCDebit');
		FANSToInsert.add(FANServiceInventoryReceivedIntercompanyCCDebit);
		Financial_Account_Number__c FANServiceInventoryReceivedIntercompanyCCCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANServiceInventoryReceivedIntercompanyCCCredit');
		FANSToInsert.add(FANServiceInventoryReceivedIntercompanyCCCredit);
		Financial_Account_Number__c FANServiceInventoryReceivedExternalDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANServiceInventoryReceivedExternalDebit');
		FANSToInsert.add(FANServiceInventoryReceivedExternalDebit);
		Financial_Account_Number__c FANServiceInventoryReceivedExternalCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANServiceInventoryReceivedExternalCredit');
		FANSToInsert.add(FANServiceInventoryReceivedExternalCredit);

		Financial_Account_Number__c FANCostProductReceivedDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANCostProductReceivedDebit');
		FANSToInsert.add(FANCostProductReceivedDebit);
		Financial_Account_Number__c FANCostProductReceivedCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANCostProductReceivedCredit');
		FANSToInsert.add(FANCostProductReceivedCredit);

		// Labor
		Financial_Account_Number__c FANInternalLaborDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANInternalLaborDebit');
		FANSToInsert.add(FANInternalLaborDebit);
		Financial_Account_Number__c FANInternalLaborCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANInternalLaborCredit');
		FANSToInsert.add(FANInternalLaborCredit);
		Financial_Account_Number__c FANPRInternalLaborDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANPRInternalLaborDebit');
		FANSToInsert.add(FANPRInternalLaborDebit);
		Financial_Account_Number__c FANPRInternalLaborCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANPRInternalLaborCredit');
		FANSToInsert.add(FANPRInternalLaborCredit);
		Financial_Account_Number__c FANExternalLaborDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANExternalLaborDebit');
		FANSToInsert.add(FANExternalLaborDebit);
		Financial_Account_Number__c FANExternalLaborCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANExternalLaborCredit');
		FANSToInsert.add(FANExternalLaborCredit);
		Financial_Account_Number__c FANRRExternalLaborDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANRRExternalLaborDebit');
		FANSToInsert.add(FANRRExternalLaborDebit);
		Financial_Account_Number__c FANRRExternalLaborCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANRRExternalLaborCredit');
		FANSToInsert.add(FANRRExternalLaborCredit);
		Financial_Account_Number__c FANPRExternalLaborDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANPRExternalLaborDebit');
		FANSToInsert.add(FANPRExternalLaborDebit);
		Financial_Account_Number__c FANPRExternalLaborCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANPRExternalLaborCredit');
		FANSToInsert.add(FANPRExternalLaborCredit);

		Financial_Account_Number__c FANServiceExternalLaborDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANServiceExternalLaborDebit');
		FANSToInsert.add(FANServiceExternalLaborDebit);
		Financial_Account_Number__c FANServiceExternalLaborCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANServiceExternalLaborCredit');
		FANSToInsert.add(FANServiceExternalLaborCredit);
		Financial_Account_Number__c FANServiceRRExternalLaborDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANServiceRRExternalLaborDebit');
		FANSToInsert.add(FANServiceRRExternalLaborDebit);
		Financial_Account_Number__c FANServiceRRExternalLaborCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANServiceRRExternalLaborCredit');
		FANSToInsert.add(FANServiceRRExternalLaborCredit);
		Financial_Account_Number__c FANServicePRExternalLaborDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANServicePRExternalLaborDebit');
		FANSToInsert.add(FANServicePRExternalLaborDebit);
		Financial_Account_Number__c FANServicePRExternalLaborCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANServicePRExternalLaborCredit');
		FANSToInsert.add(FANServicePRExternalLaborCredit);

		Financial_Account_Number__c FANServiceExternalLaborJIPDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANServiceExternalLaborJIPDebit');
		FANSToInsert.add(FANServiceExternalLaborJIPDebit);
		Financial_Account_Number__c FANServiceExternalLaborJIPCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANServiceExternalLaborJIPCredit');
		FANSToInsert.add(FANServiceExternalLaborJIPCredit);
		Financial_Account_Number__c FANServiceRRExternalLaborJIPDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANServiceRRExternalLaborJIPDebit');
		FANSToInsert.add(FANServiceRRExternalLaborJIPDebit);
		Financial_Account_Number__c FANServiceRRExternalLaborJIPCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANServiceRRExternalLaborJIPCredit');
		FANSToInsert.add(FANServiceRRExternalLaborJIPCredit);
		Financial_Account_Number__c FANServicePRExternalLaborJIPDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANServicePRExternalLaborJIPDebit');
		FANSToInsert.add(FANServicePRExternalLaborJIPDebit);
		Financial_Account_Number__c FANServicePRExternalLaborJIPCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANServicePRExternalLaborJIPCredit');
		FANSToInsert.add(FANServicePRExternalLaborJIPCredit);

		// Revenue Recognized
		Financial_Account_Number__c FANRRARDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANRRARDebit');
		FANSToInsert.add(FANRRARDebit);
		Financial_Account_Number__c FANRRARCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANRRARCredit');
		FANSToInsert.add(FANRRARCredit);
		Financial_Account_Number__c FANRRDiscountDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANRRDiscountDebit');
		FANSToInsert.add(FANRRDiscountDebit);
		Financial_Account_Number__c FANRRDiscountCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANRRDiscountCredit');
		FANSToInsert.add(FANRRDiscountCredit);
		Financial_Account_Number__c FANRRFinanceFeesDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANRRFinanceFeesDebit');
		FANSToInsert.add(FANRRFinanceFeesDebit);
		Financial_Account_Number__c FANRRFinanceFeesCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANRRFinanceFeesCredit');
		FANSToInsert.add(FANRRFinanceFeesCredit);
		Financial_Account_Number__c FANRRCOGSDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANRRCOGSDebit');
		FANSToInsert.add(FANRRCOGSDebit);
		Financial_Account_Number__c FANRRCOGSCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANRRCOGSCredit');
		FANSToInsert.add(FANRRCOGSCredit);
		Financial_Account_Number__c FANRRGrossSalesDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANRRGrossSalesDebit');
		FANSToInsert.add(FANRRGrossSalesDebit);
		Financial_Account_Number__c FANRRGrossSalesCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANRRGrossSalesCredit');
		FANSToInsert.add(FANRRGrossSalesCredit);

		Financial_Account_Number__c FANRRServiceTaxDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANRRServiceTaxDebit');
		FANSToInsert.add(FANRRServiceTaxDebit);
		Financial_Account_Number__c FANRRServiceTaxCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANRRServiceTaxCredit');
		FANSToInsert.add(FANRRServiceTaxCredit);
		Financial_Account_Number__c FANRRServiceARDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANRRServiceARDebit');
		FANSToInsert.add(FANRRServiceARDebit);
		Financial_Account_Number__c FANRRServiceARCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANRRServiceARCredit');
		FANSToInsert.add(FANRRServiceARCredit);
		
		// Business Adjustments
		Financial_Account_Number__c FANARWriteOffDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANARWriteOffDebit');
		FANSToInsert.add(FANARWriteOffDebit);
		Financial_Account_Number__c FANARWriteOffCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANARWriteOffCredit');
		FANSToInsert.add(FANARWriteOffCredit);
		Financial_Account_Number__c FANInstallAdjustmentDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANInstallAdjustmentDebit');
		FANSToInsert.add(FANInstallAdjustmentDebit);
		Financial_Account_Number__c FANInstallAdjustmentCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANInstallAdjustmentCredit');
		FANSToInsert.add(FANInstallAdjustmentCredit);
		Financial_Account_Number__c FANPRInstallAdjustmentDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANPRInstallAdjustmentDebit');
		FANSToInsert.add(FANPRInstallAdjustmentDebit);
		Financial_Account_Number__c FANPRInstallAdjustmentCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANPRInstallAdjustmentCredit');
		FANSToInsert.add(FANPRInstallAdjustmentCredit);
		
		// Misc Reimbursement/Cash Receipt
		Financial_Account_Number__c FANMiscReimbursementDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANMiscReimbursementDebit');
		FANSToInsert.add(FANMiscReimbursementDebit);
		Financial_Account_Number__c FANMiscReimbursementCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANMiscReimbursementCredit');
		FANSToInsert.add(FANMiscReimbursementCredit);
		Financial_Account_Number__c FANMiscCashReceiptDebit = new Financial_Account_Number__c (	Store_Configuration__c = storeConfig1.id, Name = 'FANMiscCashReceiptDebit');
		FANSToInsert.add(FANMiscCashReceiptDebit);
		Financial_Account_Number__c FANMiscCashReceiptCredit = new Financial_Account_Number__c (Store_Configuration__c = storeConfig1.id, Name = 'FANMiscCashReceiptCredit');
		FANSToInsert.add(FANMiscCashReceiptCredit);

		insert FANSToInsert;

		
		List<Financial_Transaction__c> FTSToInsert = new List<Financial_Transaction__c>();

		// Deposits
		Financial_Transaction__c FANDeposit = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Deposit',
																						Debit_Account_Number__c = FANDepositDebit.id,
																						Credit_Account_Number__c = FANDepositCredit.id);
		FTSToInsert.add(FANDeposit);
		Financial_Transaction__c FANDepositCheckRefund = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Deposit - Check Refund',
																						Debit_Account_Number__c = FANDepositCheckRefundDebit.id,
																						Credit_Account_Number__c = FANDepositCheckRefundCredit.id);
		FTSToInsert.add(FANDepositCheckRefund);
		Financial_Transaction__c FANFinalPayment = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Final Payment',
																						Debit_Account_Number__c = FANFinalPaymentDebit.id,
																						Credit_Account_Number__c = FANFinalPaymentCredit.id);
		FTSToInsert.add(FANFinalPayment);
		Financial_Transaction__c FANFinalPaymentCheckRefund = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Final Payment - Check Refund',
																						Debit_Account_Number__c = FANFinalPaymentCheckRefundDebit.id,
																						Credit_Account_Number__c = FANFinalPaymentCheckRefundCredit.id);
		FTSToInsert.add(FANFinalPaymentCheckRefund);
		Financial_Transaction__c FANNonSufficientFundsDeposit = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Non-sufficient Funds - Deposit',
																						Debit_Account_Number__c = FANNonSufficientFundsDepositDebit.id,
																						Credit_Account_Number__c = FANNonSufficientFundsDepositCredit.id);
		FTSToInsert.add(FANNonSufficientFundsDeposit);
		Financial_Transaction__c FANNonSufficientFundsFinalPayment = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Non-sufficient Funds - Final Payment',
																						Debit_Account_Number__c = FANNonSufficientFundsFinalPaymentDebit.id,
																						Credit_Account_Number__c = FANNonSufficientFundsFinalPaymentCredit.id);
		FTSToInsert.add(FANNonSufficientFundsFinalPayment);
		Financial_Transaction__c FANRRDeposit = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Deposit',
																						Debit_Account_Number__c = FANRRDepositDebit.id,
																						Credit_Account_Number__c = FANRRDepositCredit.id);
		FTSToInsert.add(FANRRDeposit);
		Financial_Transaction__c FANRRDepositRefund = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Refund Deposit',
																						Debit_Account_Number__c = FANRRDepositRefundDebit.id,
																						Credit_Account_Number__c = FANRRDepositRefundCredit.id);
		FTSToInsert.add(FANRRDepositRefund);

		// Inventory
		Financial_Transaction__c FANInventoryReceivedIntercompany = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Inventory Received - Intercompany',
																						Debit_Account_Number__c = FANInventoryReceivedIntercompanyDebit.id,
																						Credit_Account_Number__c = FANInventoryReceivedIntercompanyCredit.id);
		FTSToInsert.add(FANInventoryReceivedIntercompany);
		Financial_Transaction__c FANInventoryReceivedIntercompanyCC = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Inventory Received - Intercompany Consolidation Center',
																						Debit_Account_Number__c = FANInventoryReceivedIntercompanyCCDebit.id,
																						Credit_Account_Number__c = FANInventoryReceivedIntercompanyCCCredit.id);
		FTSToInsert.add(FANInventoryReceivedIntercompanyCC);
		Financial_Transaction__c FANInventoryReceivedExternal = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Inventory Received - External Vendor',
																						Debit_Account_Number__c = FANInventoryReceivedExternalDebit.id,
																						Credit_Account_Number__c = FANInventoryReceivedExternalCredit.id);
		FTSToInsert.add(FANInventoryReceivedExternal);
		Financial_Transaction__c FANInventoryWriteOff = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Inventory Write-Off',
																						Debit_Account_Number__c = FANInventoryWriteOffDebit.id,
																						Credit_Account_Number__c = FANInventoryWriteOffCredit.id);
		FTSToInsert.add(FANInventoryWriteOff);
		Financial_Transaction__c FANPRInventoryWriteOff = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Post Recognized Inventory Write-Off',
																						Debit_Account_Number__c = FANPRInventoryWriteOffDebit.id,
																						Credit_Account_Number__c = FANPRInventoryWriteOffCredit.id);
		FTSToInsert.add(FANPRInventoryWriteOff);
		Financial_Transaction__c FANServiceInventoryReceivedIntercompany = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Service Inventory Received - Intercompany',
																						Debit_Account_Number__c = FANServiceInventoryReceivedIntercompanyDebit.id,
																						Credit_Account_Number__c = FANServiceInventoryReceivedIntercompanyCredit.id);
		FTSToInsert.add(FANServiceInventoryReceivedIntercompany);
		Financial_Transaction__c FANServiceInventoryReceivedIntercompanyCC = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Service Inventory Received - Intercompany Consolidation Center',
																						Debit_Account_Number__c = FANServiceInventoryReceivedIntercompanyCCDebit.id,
																						Credit_Account_Number__c = FANServiceInventoryReceivedIntercompanyCCCredit.id);
		FTSToInsert.add(FANServiceInventoryReceivedIntercompanyCC);
		Financial_Transaction__c FANServiceInventoryReceivedExternal = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Service Inventory Received - External Vendor',
																						Debit_Account_Number__c = FANServiceInventoryReceivedExternalDebit.id,
																						Credit_Account_Number__c = FANServiceInventoryReceivedExternalCredit.id);
		FTSToInsert.add(FANServiceInventoryReceivedExternal);
		Financial_Transaction__c FANCostProductReceived = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Cost Product Received',
																						Debit_Account_Number__c = FANCostProductReceivedDebit.id,
																						Credit_Account_Number__c = FANCostProductReceivedCredit.id);
		FTSToInsert.add(FANCostProductReceived);

		// Labor
		Financial_Transaction__c FANInternalLabor = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Internal Labor',
																						Debit_Account_Number__c = FANInternalLaborDebit.id,
																						Credit_Account_Number__c = FANInternalLaborCredit.id);
		FTSToInsert.add(FANInternalLabor);
		Financial_Transaction__c FANPRInternalLabor = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Post Recognized Internal Labor',
																						Debit_Account_Number__c = FANPRInternalLaborDebit.id,
																						Credit_Account_Number__c = FANPRInternalLaborCredit.id);
		FTSToInsert.add(FANPRInternalLabor);
		Financial_Transaction__c FANExternalLabor = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'External Labor',
																						Debit_Account_Number__c = FANExternalLaborDebit.id,
																						Credit_Account_Number__c = FANExternalLaborCredit.id);
		FTSToInsert.add(FANExternalLabor);
		Financial_Transaction__c FANRRExternalLabor = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - External Labor',
																						Debit_Account_Number__c = FANRRExternalLaborDebit.id,
																						Credit_Account_Number__c = FANRRExternalLaborCredit.id);
		FTSToInsert.add(FANRRExternalLabor);
		Financial_Transaction__c FANPRExternalLabor = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Post Recognized External Labor',
																						Debit_Account_Number__c = FANPRExternalLaborDebit.id,
																						Credit_Account_Number__c = FANPRExternalLaborCredit.id);
		FTSToInsert.add(FANPRExternalLabor);
		Financial_Transaction__c FANServiceExternalLabor = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Service External Labor',
																						Debit_Account_Number__c = FANServiceExternalLaborDebit.id,
																						Credit_Account_Number__c = FANServiceExternalLaborCredit.id);
		FTSToInsert.add(FANServiceExternalLabor);
		Financial_Transaction__c FANServiceRRExternalLabor = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Service External Labor',
																						Debit_Account_Number__c = FANServiceRRExternalLaborDebit.id,
																						Credit_Account_Number__c = FANServiceRRExternalLaborCredit.id);
		FTSToInsert.add(FANServiceRRExternalLabor);
		Financial_Transaction__c FANServicePRExternalLabor = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Post Recognized Service External Labor',
																						Debit_Account_Number__c = FANServicePRExternalLaborDebit.id,
																						Credit_Account_Number__c = FANServicePRExternalLaborCredit.id);
		FTSToInsert.add(FANServicePRExternalLabor);
		Financial_Transaction__c FANServiceExternalLaborJIP = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Service External Labor - JIP',
																						Debit_Account_Number__c = FANServiceExternalLaborJIPDebit.id,
																						Credit_Account_Number__c = FANServiceExternalLaborJIPCredit.id);
		FTSToInsert.add(FANServiceExternalLaborJIP);
		Financial_Transaction__c FANServiceRRExternalLaborJIP = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Service External Labor - JIP',
																						Debit_Account_Number__c = FANServiceRRExternalLaborJIPDebit.id,
																						Credit_Account_Number__c = FANServiceRRExternalLaborJIPCredit.id);
		FTSToInsert.add(FANServiceRRExternalLaborJIP);
		Financial_Transaction__c FANServicePRExternalLaborJIP = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Post Recognized Service External Labor - JIP',
																						Debit_Account_Number__c = FANServicePRExternalLaborJIPDebit.id,
																						Credit_Account_Number__c = FANServicePRExternalLaborJIPCredit.id);
		FTSToInsert.add(FANServicePRExternalLaborJIP);

		// Revenue Recognized
		Financial_Transaction__c FANRRAR = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - AR',
																						Debit_Account_Number__c = FANRRARDebit.id,
																						Credit_Account_Number__c = FANRRARCredit.id);
		FTSToInsert.add(FANRRAR);
		Financial_Transaction__c FANRRDiscount = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Discount',
																						Debit_Account_Number__c = FANRRDiscountDebit.id,
																						Credit_Account_Number__c = FANRRDiscountCredit.id);
		FTSToInsert.add(FANRRDiscount);
		Financial_Transaction__c FANRRFinanceFees = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Finance Fees',
																						Debit_Account_Number__c = FANRRFinanceFeesDebit.id,
																						Credit_Account_Number__c = FANRRFinanceFeesCredit.id);
		FTSToInsert.add(FANRRFinanceFees);
		Financial_Transaction__c FANRRCOGS = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - COGS',
																						Debit_Account_Number__c = FANRRCOGSDebit.id,
																						Credit_Account_Number__c = FANRRCOGSCredit.id);
		FTSToInsert.add(FANRRCOGS);
		Financial_Transaction__c FANRRGrossSales = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Gross Sales',
																						Debit_Account_Number__c = FANRRGrossSalesDebit.id,
																						Credit_Account_Number__c = FANRRGrossSalesCredit.id);
		FTSToInsert.add(FANRRGrossSales);
		Financial_Transaction__c FANRRServiceTax = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Service Tax',
																						Debit_Account_Number__c = FANRRServiceTaxDebit.id,
																						Credit_Account_Number__c = FANRRServiceTaxCredit.id);
		FTSToInsert.add(FANRRServiceTax);
		Financial_Transaction__c FANRRServiceAR = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Rev Recognized - Service AR',
																						Debit_Account_Number__c = FANRRServiceARDebit.id,
																						Credit_Account_Number__c = FANRRServiceARCredit.id);
		FTSToInsert.add(FANRRServiceAR);

		// Business Adjustments
		Financial_Transaction__c FANARWriteOff = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'AR write-off',
																						Debit_Account_Number__c = FANARWriteOffDebit.id,
																						Credit_Account_Number__c = FANARWriteOffCredit.id);
		FTSToInsert.add(FANARWriteOff);
		Financial_Transaction__c FANInstallAdjustment = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Install Adjustment',
																						Debit_Account_Number__c = FANInstallAdjustmentDebit.id,
																						Credit_Account_Number__c = FANInstallAdjustmentCredit.id);
		FTSToInsert.add(FANInstallAdjustment);

		Financial_Transaction__c FANPRInstallAdjustment = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Post Recognized Install Adjustment',
																						Debit_Account_Number__c = FANPRInstallAdjustmentDebit.id,
																						Credit_Account_Number__c = FANPRInstallAdjustmentCredit.id);
		FTSToInsert.add(FANPRInstallAdjustment);

		// Misc Reimbursement/Cash Receipt
		Financial_Transaction__c FANMiscReimbursement = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Misc Reimbursement',
																						Debit_Account_Number__c = FANMiscReimbursementDebit.id,
																						Credit_Account_Number__c = FANMiscReimbursementCredit.id);
		FTSToInsert.add(FANMiscReimbursement);
		Financial_Transaction__c FANMiscCashReceipt = new Financial_Transaction__c(	Store_Configuration__c = storeConfig1.id,
																						Transaction_Type__c = 'Misc Cash Receipt',
																						Debit_Account_Number__c = FANMiscCashReceiptDebit.id,
																						Credit_Account_Number__c = FANMiscCashReceiptCredit.id);
		FTSToInsert.add(FANMiscCashReceipt);

		insert FTSToInsert;	
	}
	
}
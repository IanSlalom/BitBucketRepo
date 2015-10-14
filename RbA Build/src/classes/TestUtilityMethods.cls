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
		Account store1 = createStoreAccount('77 - Twin Cities, MN');
		insert store1;
		
		//Creating RMS_Settings__c
    	RMS_Settings__c customSetting1 = new RMS_Settings__c(Value__c = '1234567890', Name='Data Loading Profile ID');
		insert customSetting1;
		
		//Creating RMS_Queue_Settings__c
		Group Order_Queue = createQueue('Order_Queue');
		insert Order_Queue;
		QueueSobject Order_Queue_Link = createQueueSobject(Order_Queue.id ,'Order');
		insert Order_Queue_Link;
		
		
    	Group Install_Work_Order_Queue = createQueue('Install_Work_Order_Queue');
		insert Install_Work_Order_Queue;
		QueueSobject Install_Work_Order_Link = createQueueSobject(Install_Work_Order_Queue.id ,'SVMXC__Service_Order__c');
		insert Install_Work_Order_Link;
		
		Group Tech_Measure_Work_Order_Queue = createQueue('Tech_Measure_Work_Order');
		insert Tech_Measure_Work_Order_Queue;
		QueueSobject Tech_Measure_Work_Order_Link = createQueueSobject(Tech_Measure_Work_Order_Queue.id ,'SVMXC__Service_Order__c');
		insert Tech_Measure_Work_Order_Link;
		
    	Store_Configuration__c storeConfig = new Store_Configuration__c(
    		Store__c = store1.id,
        	Order_Queue_Id__c = Order_Queue.id,
    		Install_Work_Order_Queue_Id__c = Install_Work_Order_Queue.id,
        	Tech_Measure_Work_Order_Queue_Id__c = Tech_Measure_Work_Order_Queue.id
        	);
    	insert storeConfig;
		
		
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
    		Name='Test Product'
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

 
}
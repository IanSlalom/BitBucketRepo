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
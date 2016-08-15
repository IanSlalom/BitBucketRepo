@isTest
public with sharing class RMS_opportunityUtilitiesTest {

	static testmethod void convertOpportunityTest(){
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
		
		RMS_opportunityUtilities.convertOpportunity(String.ValueOf(opp1.id));
		
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
		
		Quote quote1 = testMethods.createQuote(opp1.id,Test.getStandardPricebookId());
		insert quote1;
		
		Product2 prod1 = testMethods.createProduct();
		insert prod1;

		PricebookEntry pbEntry1 = testMethods.createPricebookEntry(Test.getStandardPricebookId(), prod1.id);
		insert pbEntry1;
    		
		QuoteLineItem qli1 = testMethods.createQuoteLineItem(pbEntry1.Id, quote1.Id);
		insert  qli1;
			
		opp1.SyncedQuoteId = quote1.id;
		update opp1;

		test.startTest();		
		RMS_opportunityUtilities.convertOpportunity(String.ValueOf(opp1.id));
		
		
		opp1.StageName = 'Closed Won';
		update opp1;

		RMS_opportunityUtilities.convertOpportunity(String.ValueOf(opp1.id));
		test.stopTest();
	}
	 
	

}
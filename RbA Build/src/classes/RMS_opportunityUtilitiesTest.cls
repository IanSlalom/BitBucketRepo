@isTest
public with sharing class RMS_opportunityUtilitiesTest {

	static testmethod void convertOpportunityTest(){

		// Set up test data
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

		Quote quote1 = testMethods.createQuote(opp1.id,Test.getStandardPricebookId());
		insert quote1;
		
		Product2 prod1 = testMethods.createProduct();
		insert prod1;

		PricebookEntry pbEntry1 = testMethods.createPricebookEntry(Test.getStandardPricebookId(), prod1.id);
		insert pbEntry1;
    		
		QuoteLineItem qli1 = testMethods.createQuoteLineItem(pbEntry1.Id, quote1.Id);
		insert  qli1;
			
		opp1.SyncedQuoteId = quote1.id;
		opp1.StageName = 'New';
		update opp1;

		// Convert opportunity when not won -- no order should be created
		RMS_opportunityUtilities.convertOpportunity(String.ValueOf(opp1.id));
		System.AssertEquals(0, [SELECT Id, Status FROM Order WHERE OpportunityId = :opp1.Id].size());		
		
		test.startTest();		

		// Change the status to a closed won status, an order should now be created
		opp1.StageName = 'Measured';
		update opp1;
		System.AssertEquals(1, [SELECT Id, Status FROM Order WHERE OpportunityId = :opp1.Id].size());		

		// Run the convert after an order has already been created, only one order should be there
		RMS_opportunityUtilities.convertOpportunity(String.ValueOf(opp1.id));
		System.AssertEquals(1, [SELECT Id, Status FROM Order WHERE OpportunityId = :opp1.Id].size());		

		// Delete the order and run the convert, should be one new order there
		List<Order> orderList = [SELECT Id, Status FROM Order WHERE OpportunityId = :opp1.Id];
		delete orderList;
		RMS_opportunityUtilities.convertOpportunity(String.ValueOf(opp1.id));
		System.AssertEquals(1, [SELECT Id, Status FROM Order WHERE OpportunityId = :opp1.Id].size());		
		test.stopTest();
	}
	 
	

}
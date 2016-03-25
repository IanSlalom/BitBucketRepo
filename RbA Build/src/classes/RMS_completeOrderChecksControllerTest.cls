@isTest
public with sharing class RMS_completeOrderChecksControllerTest {
	
	static testmethod void testCompleteOrderChecksController(){	
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
		
		Back_Office_Check__c BoC1 = new Back_Office_Check__c(	Name = 'BoC1', 
																Completed__c = true, 
																Signed_Date__c = Date.Today(), 
																Order__c = order1.id);
		insert BoC1;													
		Back_Office_Check__c BoC2 = new Back_Office_Check__c(	Name = 'BoC2', 
																Completed__c = true, 
																Signed_Date__c = Date.Today(), 
																Order__c = order1.id);
		insert BoC2;														
		Back_Office_Check__c BoC3 = new Back_Office_Check__c(	Name = 'BoC3', 
																Completed__c = true, 
																Signed_Date__c = Date.Today(), 
																Order__c = order1.id);
		insert BoC3;
		
		list<Back_Office_Check__c> BoCList = new list<Back_Office_Check__c>();
		BoCList.add(BoC1);
		BoCList.add(BoC2);
		BoCList.add(BoC3);
		
		Test.setCurrentPageReference(new PageReference('Page.myPage')); 
		System.currentPageReference().getParameters().put('Id', order1.id);
		
		//ApexPages.StandardController sc = new ApexPages.StandardController(BoCList);
		RMS_completeOrderChecksController controller = new RMS_completeOrderChecksController(new ApexPages.StandardSetController( BoCList ));
 		
 		controller.save();
	}

}
/*******************************************************//**

@class	RMS_completeOrderChecksControllerTest

@brief	Test Class for RMS_completeOrderChecksController
@author  Kai Ruan (Slalom.CDK)

@version	2016-2-22  Slalom.CDK
	Created.

@see		RMS_completeOrderChecksController

@copyright  (c)2016 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
public with sharing class RMS_completeOrderChecksControllerTest {
	
	static testmethod void testCompleteOrderChecksController(){	

		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;

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

		//Order needs to have an associated order product for the Status field to be updated successfully
		Product2 masterProduct = new Product2(	name = 'master',
												IsActive = true, 
												recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Master_Product')
											);
		
		List<Product2> products = new List<Product2>{masterProduct};
		insert products;
		PricebookEntry pricebookEntryMaster= testMethods.createPricebookEntry(Test.getStandardPricebookId(), masterProduct.id);		
		List<PriceBookEntry> pbEntries = new List<PricebookEntry>{pricebookEntryMaster};
		insert pbEntries;
		OrderItem orderItemMaster = new OrderItem(OrderId = Order1.id, PricebookentryId = pricebookEntryMaster.Id, Quantity = 2, UnitPrice = 100 );
		insert orderItemMaster;
		
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
																Completed__c = false, 
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

 		//Verify Order Status does not change as not all Back Office Checks are Completed.
 		order1 = [select Id, Status from Order where Id =: order1.Id];

 		System.assertEquals(order1.Status, 'Draft');

 		//Update all checks to completed and verify Order Status is updated to Tech Measure Needed.
 		for(Back_Office_Check__c check: controller.selectedChecks){
 			check.Completed__c = true;
 		}

 		controller.save();
 		order1 = [select Id, Status from Order where Id =: order1.Id];
 		System.assertEquals(order1.Status, 'Tech Measure Needed');

 		//Verify Order Status is updated to Tech Measure Scheduled when Tech Measure Status field = Scheduled

 		order1.Tech_Measure_Status__c = 'Scheduled';
 		order1.Status = 'Draft';
 		order1.Apex_Context__c = true;
 		update order1;
 		controller.save();
 		order1 = [select Id, Status, Order_Processed_Date__c from Order where Id =: order1.Id];
 		System.assertEquals(order1.Status, 'Tech Measure Scheduled');
 		System.assertEquals(System.Today(), order1.Order_Processed_Date__c);

	}

}
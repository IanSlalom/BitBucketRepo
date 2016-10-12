@isTest
public with sharing class RMS_viewRelatedWorkOrdersControllerTest {


	static testMethod void testingConstructor(){
		
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();
		
		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
		Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];
		Account newDwelling = new Account(Name='test1', Store_Location__c = store.id, RecordTypeId = dwellingRT, BillingPostalCode = '55429' , BillingCity = 'Blaine' );
		insert newDwelling;
		
		//CREATE AN ORDER RELATED TO OPPORTUNITY
		Order ord1 = new Order( AccountId = newDwelling.id ,
								Status = 'Draft', 
								EffectiveDate = Date.Today(),
								Pricebook2Id = Test.getStandardPricebookId()
								);
		insert ord1;
		
		PageReference pageRef = new PageReference('/apex/RMS_viewRelatedWorkOrdersActions'); 
		Test.setCurrentPage(pageRef);
			
		ApexPages.StandardController stdController = new ApexPages.StandardController(ord1);
		RMS_viewRelatedWorkOrdersController customController  = new RMS_viewRelatedWorkOrdersController(stdController);
		
		PageReference pageRef2 = new PageReference('/apex/RMS_viewRelatedWorkOrdersVisit'); 
		Test.setCurrentPage(pageRef2);
		
		ApexPages.StandardController stdController2 = new ApexPages.StandardController(ord1);
		RMS_viewRelatedWorkOrdersController customController2  = new RMS_viewRelatedWorkOrdersController(stdController2);
		
	}


}
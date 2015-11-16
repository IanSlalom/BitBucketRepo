@isTest
public with sharing class RMS_backOfficeChecklistManagerTest {
	
	
	
	static testmethod void matchingBackOfficeChecks(){
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();

		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
		id muniPermitRT = UtilityMethods.retrieveRecordTypeId('Permit', 'Municipality__c');
		
		Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];
		
		Account newDwelling = new Account(Name='test1', Store_Location__c = store.id, RecordTypeId = dwellingRT, BillingPostalCode = '55429' , BillingCity = 'Blaine' );
		insert newDwelling;
		
		Order ord1 = new Order( AccountId = newDwelling.id ,
								Status = 'Draft', 
								EffectiveDate = Date.Today()
								);
		insert ord1;
		
		list<Back_Office_Check__c> checks = [SELECT Id, Order__c FROM Back_Office_Check__c WHERE Order__c = :ord1.id];
		
		System.assertEquals(checks.size(), 2);

	} 
	
	static testmethod void notMatchingBackOfficeChecks(){
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();

		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
		id muniPermitRT = UtilityMethods.retrieveRecordTypeId('Permit', 'Municipality__c');
		
		Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];

		Account newDwelling = new Account(Name='test1', Store_Location__c = store.id, RecordTypeId = dwellingRT, BillingPostalCode = '55429' , BillingCity = 'Blaine' );
		insert newDwelling;
		
		
		Account dwelling = [SELECT Id, Building_Permit__c FROM Account WHERE Id = :newDwelling.id];
		
		Back_Office_Checklist_Configuration__c bocc = [SELECT id, Contract_Signed__c, Lien_Rights_Signed__c FROM Back_Office_Checklist_Configuration__c];
		
		bocc.Contract_Signed__c = false;
		bocc.Lien_Rights_Signed__c = false;
		update bocc;
		
		Order ord1 = new Order( AccountId = newDwelling.id ,
								Status = 'Draft', 
								EffectiveDate = Date.Today()
								);
		insert ord1;
		
		list<Back_Office_Check__c> checks = [SELECT Id, Order__c FROM Back_Office_Check__c WHERE Order__c = :ord1.id];
		
		System.assertEquals(checks.size(), 0);
	}


}
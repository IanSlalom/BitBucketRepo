@isTest
public with sharing class RMS_backOfficeChecklistManagerTest {
	
	static testmethod void matchingBackOfficeChecks(){
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();

		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
		id muniPermitRT = UtilityMethods.retrieveRecordTypeId('Permit', 'Municipality__c');
		
		Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];
		
		Municipality__c muni1 = utility.createMunicipality(store.id, muniPermitRT);
		insert muni1;
		
		Municipality__c muni2 = utility.createMunicipality(store.id, muniPermitRT);
		insert muni2;
		
		Municipality_Match__c mm1 = utility.createMunicipalityMatch(muni1.id, '55429', 'Blaine');
		insert mm1;
		
		Municipality_Match__c mm2 = utility.createMunicipalityMatch(muni1.id, '55444', 'Blaine');
		insert mm2;

		Account newDwelling = new Account(Name='test1', Store_Location__c = store.id, RecordTypeId = dwellingRT, BillingPostalCode = '55429' , BillingCity = 'Blaine' );
		insert newDwelling;
		
		Account dwelling = [SELECT Id, Building_Permit__c FROM Account WHERE Id = :newDwelling.id];
		
		System.assertEquals(dwelling.Building_Permit__c, muni1.id);

	}
	
	static testmethod void notMatchingBackOfficeChecks(){
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();

		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
		id muniPermitRT = UtilityMethods.retrieveRecordTypeId('Permit', 'Municipality__c');
		
		Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];
		
		Municipality__c muni1 = utility.createMunicipality(store.id, muniPermitRT);
		insert muni1;
		
		Municipality__c muni2 = utility.createMunicipality(store.id, muniPermitRT);
		insert muni2;

		Municipality_Match__c mm2 = utility.createMunicipalityMatch(muni1.id, '55444', 'Blaine');
		insert mm2;

		Account newDwelling = new Account(Name='test1', Store_Location__c = store.id, RecordTypeId = dwellingRT, BillingPostalCode = '55429' , BillingCity = 'Blaine' );
		insert newDwelling;
		
		
		Account dwelling = [SELECT Id, Building_Permit__c FROM Account WHERE Id = :newDwelling.id];
		
		System.assertEquals(dwelling.Building_Permit__c, null);
	}


}
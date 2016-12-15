@isTest
public with sharing class RMS_MunicipalityMatchManagerTest {
	
	static testmethod void municipalityMatchPositive(){ 
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();

		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
		id muniPermitRT = UtilityMethods.retrieveRecordTypeId('Permit', 'Municipality__c');
		
		Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];
		
		Municipality__c muni1 = utility.createMunicipality(store.id, muniPermitRT, '55555', 'Blaine', 'Anoka', 'MN');
		insert muni1;
		
		Municipality_Match__c mm1 = utility.createMunicipalityMatch(muni1.id, '55429', 'Blaine');
		insert mm1;
		
		Municipality_Match__c mm2 = utility.createMunicipalityMatch(muni1.id, '55444', 'Blaine');
		insert mm2;

		Test.startTest();
        Account newDwelling = new Account(Name='test1', Store_Location__c = store.id, RecordTypeId = dwellingRT, ShippingStreet = '123 Buckway', ShippingPostalCode = '55429' , ShippingCity = 'Blaine' );
		insert newDwelling;
		Test.stopTest();
        Account dwelling = [SELECT id, Name, Building_Permit__c FROM Account WHERE Id = :newDwelling.Id];
		System.assertEquals(dwelling.Building_Permit__c , muni1.id);
	}

	static testmethod void municipalityMatchBulkTest(){ 
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();

		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
		id muniPermitRT = UtilityMethods.retrieveRecordTypeId('Permit', 'Municipality__c');
		
		Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];
		
		Municipality__c muni1 = utility.createMunicipality(store.id, muniPermitRT, '55555', 'Blaine', 'Anoka', 'MN');
		insert muni1;
		
		Municipality_Match__c mm1 = utility.createMunicipalityMatch(muni1.id, '55429', 'Blaine');
		insert mm1;
		
		Municipality_Match__c mm2 = utility.createMunicipalityMatch(muni1.id, '55444', 'Blaine');
		insert mm2;

		List<Account> newDwellings = new List<Account>();
		Account newDwelling = null;

		for (Integer i = 0; i < 200; i++) {
			newDwelling = new Account(Name='test1' + i, Store_Location__c = store.id, RecordTypeId = dwellingRT, ShippingStreet = '123 Buckway', ShippingPostalCode = '55429' , ShippingCity = 'Blaine' );
			newDwellings.add(newDwelling);
		}
		insert newDwellings;
		
		Account dwelling = [SELECT id, Building_Permit__c FROM Account WHERE Id In :newDwellings limit 1];
		System.assertEquals(dwelling.Building_Permit__c , muni1.id);
	}
	
	static testmethod void municipalityMatchNoZipCode(){ 
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();

		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
		id muniPermitRT = UtilityMethods.retrieveRecordTypeId('Permit', 'Municipality__c');
		
		Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];
		
		Municipality__c muni1 = utility.createMunicipality(store.id, muniPermitRT, '55555', 'Blaine', 'Anoka', 'MN');
		insert muni1;
		
		Municipality_Match__c mm1 = utility.createMunicipalityMatch(muni1.id, '55429', 'Blaine');
		insert mm1;

		Account newDwelling = new Account(Name='test1', Store_Location__c = store.id, RecordTypeId = dwellingRT, ShippingStreet = '123 Buckway', ShippingPostalCode = null , ShippingCity = 'Blaine' );
		insert newDwelling;
		
		Account dwelling = [SELECT id, Building_Permit__c FROM Account WHERE Id = :newDwelling.Id];
		System.assertEquals(dwelling.Building_Permit__c , null);
	}
	
	static testmethod void municipalityMatchNoMunicipalityMatch(){ 
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();

		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
		id muniPermitRT = UtilityMethods.retrieveRecordTypeId('Permit', 'Municipality__c');
		
		Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];
		
		Municipality__c muni1 = utility.createMunicipality(store.id, muniPermitRT, '55555', 'Blaine', 'Anoka', 'MN');
		insert muni1;

		Account newDwelling = new Account(Name='test1', Store_Location__c = store.id, RecordTypeId = dwellingRT, ShippingStreet = '123 Buckway', ShippingPostalCode = null , ShippingCity = 'Blaine' );
		insert newDwelling;
		
		Account dwelling = [SELECT id, Building_Permit__c FROM Account WHERE Id = :newDwelling.Id];
		System.assertEquals(dwelling.Building_Permit__c , null);
	}
	

}
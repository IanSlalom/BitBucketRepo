@isTest
public with sharing class AccountTriggerHandlerTest {
	
	//TODO: more test methods 'neg cases'
	
	static testmethod void test1(){ 
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();
		
		
		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
		id muniPermitRT = UtilityMethods.retrieveRecordTypeId('Permit', 'Municipality__c');
		
		Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];
		
		Municipality__c muni1 = new Municipality__c(For_Retail_Location__c = store.id, RecordTypeId = muniPermitRT);
		insert muni1;
		
		Municipality_Match__c mm1 = new Municipality_Match__c(Agency_Name__c = muni1.id, Zip_Code__c = '55429', City_Township__c = 'Blaine' );
		insert mm1;
		
		Account newDwelling = new Account(Name='test1', Store_Location__c = store.id, RecordTypeId = dwellingRT, BillingPostalCode = '55429' , BillingCity = 'Blaine'  );
		insert newDwelling;
		
		//TODO:assertions
		
	}
}
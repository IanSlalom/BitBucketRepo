@isTest
public with sharing class testRMS_MunicipalityManager {
    static testmethod void createTestRecords() {    
        RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name = 'Turn Financial Transactions Off', Value__c = 'Yes');
        insert turnOffFinancialTrigger;
        
        TestUtilityMethods utility = new TestUtilityMethods();
        utility.setUpConfigs();
        
        id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        id muniPermitRT = UtilityMethods.retrieveRecordTypeId('Permit', 'Municipality__c');
        
        Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];
        
        List<Municipality__c> muniList = new List<Municipality__c>();
        Municipality__c muni1 = new Municipality__c( name = 'Muni 1', recordTypeId=muniPermitRT, City_Township__c = 'Chicago', State__c = 'IL', Zip_Code__c = '60618', County__c = 'Cook', Phone__c = '555-555-5555', For_Retail_Location__c = store.Id);
        muniList.add(muni1);
        Municipality__c muni2 = new Municipality__c( name = 'Muni 1', recordTypeId=muniPermitRT, City_Township__c = 'Chicago', State__c = 'IL', Zip_Code__c = '60618', County__c = 'Cook', Phone__c = '555-555-5555', For_Retail_Location__c = store.Id);
        muniList.add(muni2);
        insert muniList;
        
        System.assertEquals(muniList.size(), 2);
        
        
    }
}
@isTest
public with sharing class testRMS_addApplicationNotes {
    
    static testMethod void createRecords(){
        TestUtilityMethods utility = new TestUtilityMethods();
        utility.setUpConfigs();
        
        id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        id muniPermitRT = UtilityMethods.retrieveRecordTypeId('Permit', 'Municipality__c');
        
        Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];
        
        List<Municipality__c> muniList = new List<Municipality__c>();
        Municipality__c muni1 = new Municipality__c( name = 'Muni 1', recordTypeId=muniPermitRT, Application_Notes__c = 'Testing Notes', City_Township__c = 'Chicago', State__c = 'IL', Zip_Code__c = '60618', County__c = 'Cook', Phone__c = '555-555-5555', For_Retail_Location__c = store.Id);
        muniList.add(muni1);
        Municipality__c muni2 = new Municipality__c( name = 'Muni 1', recordTypeId=muniPermitRT, Application_Notes__c = 'Testing Notes', City_Township__c = 'Chicago', State__c = 'IL', Zip_Code__c = '60618', County__c = 'Cook', Phone__c = '555-555-5555', For_Retail_Location__c = store.Id);
        muniList.add(muni2);
        insert muniList;
        
        System.assertEquals(muniList.size(), 2);
        
        
        Id actionWORecordTypeId = UtilityMethods.retrieveRecordTypeId('Actions', 'RbA_Work_Order__c');
        Id permitWORecordTypeId = UtilityMethods.retrieveRecordTypeId('Permit', 'RbA_Work_Order__c');
        
        List<RbA_Work_Order__c> woList = new List<RbA_Work_Order__c>();
        RbA_Work_Order__c wo1 = new RbA_Work_Order__c(  RecordTypeId = actionWORecordTypeId,  
                                                      Work_Order_Type__c = 'HOA',
                                                      Municipality__c = muni1.id
                                                     );
        woList.add(wo1);
        RbA_Work_Order__c wo2 = new RbA_Work_Order__c(  RecordTypeId = actionWORecordTypeId,  
                                                      Work_Order_Type__c = 'Historical',
                                                      Municipality__c = muni1.id
                                                     );
        woList.add(wo2);
        RbA_Work_Order__c wo3 = new RbA_Work_Order__c(  RecordTypeId = permitWORecordTypeId,  
                                                      Work_Order_Type__c = 'Building Permit',
                                                      Municipality__c = muni1.id
                                                     );
        woList.add(wo3);
        insert woList;
        
        System.assertEquals(woList.size(),3);
        
        
    }
    
    static testMethod void updateRecords(){
        TestUtilityMethods utility = new TestUtilityMethods();
        utility.setUpConfigs();
        
        id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        id muniPermitRT = UtilityMethods.retrieveRecordTypeId('Permit', 'Municipality__c');
        
        Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];
        
        List<Municipality__c> muniList = new List<Municipality__c>();
        Municipality__c muni1 = new Municipality__c( name = 'Muni 1', recordTypeId=muniPermitRT, Application_Notes__c = 'Testing Notes', City_Township__c = 'Chicago', State__c = 'IL', Zip_Code__c = '60618', County__c = 'Cook', Phone__c = '555-555-5555', For_Retail_Location__c = store.Id);
        muniList.add(muni1);
        Municipality__c muni2 = new Municipality__c( name = 'Muni 1', recordTypeId=muniPermitRT, Application_Notes__c = 'Testing Notes', City_Township__c = 'Chicago', State__c = 'IL', Zip_Code__c = '60618', County__c = 'Cook', Phone__c = '555-555-5555', For_Retail_Location__c = store.Id);
        muniList.add(muni2);
        insert muniList;
        
        System.assertEquals(muniList.size(), 2);
        
        
        Id actionWORecordTypeId = UtilityMethods.retrieveRecordTypeId('Actions', 'RbA_Work_Order__c');
        Id permitWORecordTypeId = UtilityMethods.retrieveRecordTypeId('Permit', 'RbA_Work_Order__c');
        
        List<RbA_Work_Order__c> woList = new List<RbA_Work_Order__c>();
        RbA_Work_Order__c wo1 = new RbA_Work_Order__c(  RecordTypeId = actionWORecordTypeId,  
                                                      Work_Order_Type__c = 'HOA'                                        
                                                     );
        woList.add(wo1);
        RbA_Work_Order__c wo2 = new RbA_Work_Order__c(  RecordTypeId = actionWORecordTypeId,  
                                                      Work_Order_Type__c = 'Historical'
                                                     );
        woList.add(wo2);
        RbA_Work_Order__c wo3 = new RbA_Work_Order__c(  RecordTypeId = permitWORecordTypeId,  
                                                      Work_Order_Type__c = 'Building Permit'
                                                     );
        woList.add(wo3);
        insert woList;
        
        System.assertEquals(woList.size(),3);
        
        wo1.Municipality__c = muni1.Id;
        update wo1;
        wo2.Municipality__c = muni1.Id;
        update wo2;
        wo3.Municipality__c = muni1.Id;
        update wo3;
        
        
    }
    
    
}
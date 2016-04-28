/*******************************************************//**

@class  testRMS_createContactHistoryMgr

@brief  Test Class for RMS_createContactHistoryManager

@author  Brianne Wilson (Slalom.CDK)

@version    2015-4-19  Slalom.CDK
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
@isTest
public with sharing class testRMS_createContactHistoryMgr {
    static testmethod void createTestRecords() {
        TestUtilityMethods utility = new TestUtilityMethods();
        utility.setUpConfigs();
        
        List<Account> dwellingsToInsert = new List<Account>();  
        Account dwelling1 = utility.createDwellingAccount('Dwelling Account');
        Account dwelling2 = utility.createDwellingAccount('Dwelling Account 2');
        Account store1 = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
        Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
        dwelling1.Store_Location__c = store1.Id;
        dwelling2.Store_Location__c = store1.Id; 
        dwellingsToInsert.add(dwelling1);
        dwellingsToInsert.add(dwelling2);
        insert dwellingsToInsert; 
        
        List<Contact> contactsToInsert = new List<Contact>();       
        Contact contact1 = new contact ( FirstName='Contact',LastName='1',AccountId=dwelling1.id,Primary_Contact__c=True,Primary_Dwelling_for_Contact__c=true);
        contactsToInsert.add(contact1);
        insert contactsToInsert;
        
        contact1.AccountId = dwelling2.id;
        update contact1;
    }
    
}
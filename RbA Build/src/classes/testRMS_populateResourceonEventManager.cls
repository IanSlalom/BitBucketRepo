/*************************************************************
@brief  Test Class for RMS_populateResourceonEventManager

@author  Brianne Wilson (Slalom.BLW)

@version    2016-5-11  Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
@isTest 
public with sharing class testRMS_populateResourceonEventManager {
    
    static testmethod void createTestRecords(){
        
        TestUtilityMethods utility = new TestUtilityMethods();
        utility.setUpConfigs();
        
        List<Account> vendorToInsert = new List<Account>();       
        
        Account vendor1 = utility.createVendorAccount('Vendor Account');
        vendorToInsert.add(vendor1);
        insert vendorToInsert;
        
        Account store1 = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
        Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
        
        List<Contact> contactsToInsert = new List<Contact>();       
        Contact contact1 = new contact ( FirstName='Testy',LastName='McTest',AccountId=vendor1.id);
        contactsToInsert.add(contact1);
        insert contactsToInsert;
        
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name LIKE '%z-Partner-Temp%' Limit 1];
        User u = new User(
            Username = System.now().millisecond() + 'test12345@test.com',
            ContactId = contact1.Id,
            ProfileId = portalProfile.Id,
            Alias = 'test123',
            Email = 'test12345@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'McTesty',
            CommunityNickname = 'test12345',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US'          
        );
        insert u;
        
        List<Resource__c> resourceToInsert = new List<Resource__c>();
        Resource__c resource1 = new Resource__c(RbA_User__c=u.Id, Name='Resource1', Resource_Type__c='Tech Measure', Retail_Location__c=storeConfig1.id, Active__c=TRUE);
        insert resource1;
        
        List<Event> eventToInsert = new List<Event>();
        Event event1 = new Event(Subject='Test Event', StartDateTime=system.now(), EndDateTime=system.now()+10, Type='Tech Measure', OwnerId=u.Id);
        insert event1;
        
        event1.Primary_Resource__c = true;
        update event1;
        
        
        
        vendor1.Inactive_Date__c = system.today()-10;
        resource1.Active__c = false;
        
        update vendor1;
        update resource1;
        
        vendor1.Inactive_Date__c = system.today()+10;
        
        Resource__c res = [select id,Active__c,RbA_User__r.Contact.Account.Inactive_Date__c from Resource__c where id =: resource1.id];
        
    }
    
    
}
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
        Contact contact1 = new contact ( FirstName='Contact',LastName='1',AccountId=dwelling1.id, Primary_Contact__c = True);
        contactsToInsert.add(contact1);
        Contact contact2 = new contact ( FirstName='Contact',LastName='2',AccountId=dwelling1.id);
        contactsToInsert.add(contact2);
        Contact contact3 = new contact ( FirstName='Contact',LastName='3',AccountId=dwelling2.id);
        contactsToInsert.add(contact3);
        insert contactsToInsert;
        
        dwelling1.Primary_Contact__c = 'Contact 1';
        update dwelling1;
        
        List<Contact_History__c> chList1 = [SELECT Id, Dwelling__c,Contact__c, Type__c, Primary_Contact__c, Update_Contact_Account__c FROM Contact_History__c WHERE Dwelling__c =:dwelling1.Id];
        List<Contact_History__c> chList2 = [SELECT Id, Dwelling__c,Contact__c, Type__c, Primary_Contact__c, Update_Contact_Account__c FROM Contact_History__c WHERE Dwelling__c =:dwelling2.Id];
        
    }
    
    static testmethod void updateAccountAddress(){
        createTestRecords();
        Account aid = [Select Id FROM Account WHERE Name = '11111, Dwelling Account'];
        Test.startTest();
        RMS_addressManager controller = new RMS_addressManager();
        aid.ShippingStreet = 'New Street Address';
        aid.BillingStreet = 'New Billing Address';
        update aid;
        Test.stopTest(); 
        
    }
    
    static testmethod void updateContactAccount(){
        createTestRecords();
        Contact con = [SELECT Id, AccountId, LastName FROM Contact WHERE LastName = '1'];
        Account acc = [SELECT Id, ShippingStreet FROM Account WHERE Name = '11111, Dwelling Account 2'];
        Test.startTest();
        RMS_addressManager controller = new RMS_addressManager();
        con.AccountId = acc.Id;
        update con;
        Test.stopTest(); 
        
    }
    
    static testmethod void newPrimary(){
        createTestRecords();
        Account aid = [Select Id,Primary_Contact__c FROM Account WHERE Name = '11111, Dwelling Account'];
        Account aid2 = [Select Id FROM Account WHERE Name = '11111, Dwelling Account 2'];
        
        
        Contact cont = new Contact(AccountId = aid.Id, FirstName = 'Testing', LastName = 'Primary', Primary_Contact__c = True);
        Contact cont2 = new Contact(AccountId = aid2.Id, FirstName = 'Testing', LastName = 'Primary2', Primary_Contact__c = False);
        insert new List<Contact>{cont,cont2};

        Test.startTest();
        
        Contact_History__c ch = new Contact_History__c(Dwelling__c = aid.Id, Contact__c = cont2.id, Primary_Contact__c = True, Update_Contact_Account__c = true);
        insert ch;
        update cont2;
        aid.Primary_Contact__c = ch.Full_Name__c;
        update aid;
        Test.stopTest(); 
    }
    
    static testmethod void contactHistoryManager2(){
        createTestRecords();
        Account aid = [Select Id,Primary_Contact__c FROM Account WHERE Name = '11111, Dwelling Account'];
        Account aid2 = [Select Id FROM Account WHERE Name = '11111, Dwelling Account 2'];
        
        
        Contact cont = new Contact(AccountId = aid.Id, FirstName = 'Testing', LastName = 'Primary', Primary_Contact__c = True);
        Contact cont2 = new Contact(AccountId = aid2.Id, FirstName = 'Testing', LastName = 'Primary2', Primary_Contact__c = False);
        insert new List<Contact>{cont,cont2};
        Test.startTest();
        
        Contact_History__c ch = new Contact_History__c(Dwelling__c = aid.Id, Contact__c = cont2.id, Primary_Contact__c = True, Update_Contact_Account__c = False);
        insert ch;
        ch.Update_Contact_Account__c = true;
        update cont2;
        aid.Primary_Contact__c = ch.Full_Name__c;
        update aid;
        Test.stopTest(); 
    }
    
    static testmethod void addExistingP1(){
        createTestRecords();
        Test.startTest();
        Account aid = [Select Id,Primary_Contact__c,Name FROM Account WHERE Name = '11111, Dwelling Account'];
        Account aid2 = [Select Id FROM Account WHERE Name = '11111, Dwelling Account 2'];
        
        Contact pc = [Select Id,Full_Name__c FROM Contact WHERE AccountId = :aid.Id AND Primary_Contact__c = TRUE];
        Contact con = new Contact(FirstName = 'Test', LastName='Test', AccountId = aid2.Id);
        insert con;
        
        Contact_History__c ch = new Contact_History__C (Dwelling__c = aid.Id, Contact__c = con.Id, Type__c='Current Resident');
        insert ch;
        
        Test.setCurrentPage(Page.RMS_addExistingContact);
        ApexPages.currentPage().getParameters().put('aid',aid.id);
        ApexPages.currentPage().getParameters().put('aname',aid.Name);               
        ApexPages.StandardController sc = new ApexPages.StandardController(ch);
        RMS_addExistingContactManager TE = new RMS_addExistingContactManager(sc);
        Pagereference pr = TE.saveCH();   
        
        Contact_History__c cHist = [select Dwelling__c from Contact_History__c where id =: ch.id];
        System.Assertequals(cHist.Dwelling__c, aid.Id);
        Test.stopTest(); 
    }
    
    static testmethod void addExistingP1Pt2(){
        createTestRecords();
        Test.startTest();
        Account aid = [Select Id,Primary_Contact__c,Name FROM Account WHERE Name = '11111, Dwelling Account'];
        Account aid2 = [Select Id FROM Account WHERE Name = '11111, Dwelling Account 2'];
        
        Contact pc = [Select Id,Full_Name__c FROM Contact WHERE AccountId = :aid.Id AND Primary_Contact__c = TRUE];
        Contact con = new Contact(FirstName = 'Test', LastName='Test', AccountId = aid2.Id);
        insert con;
        
        Contact_History__c ch = new Contact_History__C (Dwelling__c = aid.Id, Contact__c = con.Id, Type__c='Past Resident');
        insert ch;
        
        Test.setCurrentPage(Page.RMS_addExistingContact);
        ApexPages.currentPage().getParameters().put('aid',aid.id);
        ApexPages.currentPage().getParameters().put('aname',aid.Name);               
        ApexPages.StandardController sc = new ApexPages.StandardController(ch);
        RMS_addExistingContactManager TE = new RMS_addExistingContactManager(sc);
        Pagereference pr = TE.saveCH();   
        
        Contact_History__c cHist = [select Dwelling__c from Contact_History__c where id =: ch.id];
        System.Assertequals(cHist.Dwelling__c, aid.Id);
        Test.stopTest(); 
    }
    
    static testmethod void addExistingP1Pt3(){
        createTestRecords();
        Test.startTest();
        Account aid = [Select Id,Primary_Contact__c,Name FROM Account WHERE Name = '11111, Dwelling Account'];
        Account aid2 = [Select Id FROM Account WHERE Name = '11111, Dwelling Account 2'];
        
        Contact pc = [Select Id,Full_Name__c FROM Contact WHERE AccountId = :aid.Id AND Primary_Contact__c = TRUE];
        Contact con = new Contact(FirstName = 'Test', LastName='Test', AccountId = aid2.Id);
        insert con;
        
        Contact_History__c ch = new Contact_History__C (Dwelling__c = aid.Id, Contact__c = con.Id, Type__c='Current Resident');
        insert ch;
        
        Test.setCurrentPage(Page.RMS_addExistingContact);
        ApexPages.currentPage().getParameters().put('aid',aid.id);
        ApexPages.currentPage().getParameters().put('aname',aid.Name);               
        ApexPages.StandardController sc = new ApexPages.StandardController(ch);
        RMS_addExistingContactManager TE = new RMS_addExistingContactManager(sc);
        ch.Contact__c = null;            
        Pagereference pr = TE.saveCH();          
        
        try {            
            upsert ch;
        } catch (DmlException saveEx) {
            //Assert Error Message
            system.assertEquals(true, ApexPages.hasMessages());
            
        } //catch  
        
        Test.stopTest(); 
    }
    
    static testmethod void addExistingP2Pt1(){
        createTestRecords();
        Test.startTest();
        Account aid = [Select Id,Primary_Contact__c,Name FROM Account WHERE Name = '11111, Dwelling Account'];
        Account aid2 = [Select Id FROM Account WHERE Name = '11111, Dwelling Account 2'];
        
        Contact pc = [Select Id,Full_Name__c FROM Contact WHERE AccountId = :aid.Id AND Primary_Contact__c = TRUE];
        Contact con = new Contact(FirstName = 'Test', LastName='Test', AccountId = aid2.Id);
        insert con;
        
        Contact_History__c ch = new Contact_History__C (Dwelling__c = aid.Id, Contact__c = con.Id, Type__c='Current Resident');
        insert ch;
        
        Test.setCurrentPage(Page.RMS_addExistingContactUpdateDwelling);             
        ApexPages.StandardController sc = new ApexPages.StandardController(ch);
        RMS_addExistingContactManager TE = new RMS_addExistingContactManager(sc);
        ch.Update_Contact_Account__c = True; 
        Pagereference pr = TE.saveCH2();          
        
        try {            
            upsert ch;
        } catch (DmlException saveEx) {
            //Assert Error Message
            system.assertEquals(true, ApexPages.hasMessages());
            
        } //catch  
        
        Test.stopTest(); 
    }
    
    static testmethod void addExistingP2Pt2(){
        createTestRecords();
        Test.startTest();
        Account aid = [Select Id,Primary_Contact__c,Name FROM Account WHERE Name = '11111, Dwelling Account'];
        Account aid2 = [Select Id FROM Account WHERE Name = '11111, Dwelling Account 2'];
        
        Contact pc = [Select Id,Full_Name__c FROM Contact WHERE AccountId = :aid.Id AND Primary_Contact__c = TRUE];
        Contact con = new Contact(FirstName = 'Test', LastName='Test', AccountId = aid2.Id);
        insert con;
        
        Contact_History__c ch = new Contact_History__C (Dwelling__c = aid.Id, Contact__c = con.Id, Type__c='Current Resident');
        insert ch;
        
        Test.setCurrentPage(Page.RMS_addExistingContactUpdateDwelling);             
        ApexPages.StandardController sc = new ApexPages.StandardController(ch);
        RMS_addExistingContactManager TE = new RMS_addExistingContactManager(sc);
        ch.Update_Contact_Account__c = True;
        ch.Contact__c = null;
        Pagereference pr = TE.saveCH2();          
        
        try {            
            upsert ch;
        } catch (DmlException saveEx) {
            //Assert Error Message
            system.assertEquals(true, ApexPages.hasMessages());
            
        } //catch  
        
        Test.stopTest(); 
    }
    
}
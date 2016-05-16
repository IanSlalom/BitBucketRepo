/*************************************************************
@brief  Test Class for RMS_editableTaskList 

@author  Brianne Wilson (Slalom.BLW)

@version    2016-5-11  Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
@isTest
private class testRMS_editableTaskList 
{ 
    /*
* Mock implementation of abstract class used for testing
*/
    private class MockEditableList extends RMS_editableTaskList
    {
        public MockEditableList(ApexPages.StandardController stdController)
        {
            super(stdController);
        } 
    }
    
    private static RbA_Work_Order__c rwo;
    private static Task myTask1;
    private static Task myTask2;
    
    private static void setupData()
    {
        
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
        
        Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (  Store_Configuration__c = storeConfig1.id, Name = '1');
        insert finacialAccountNumber1;
        Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (  Store_Configuration__c = storeConfig1.id, Name = '2');
        insert finacialAccountNumber2;
        
        Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(  Store_Configuration__c = storeConfig1.id,
                                                                                     Transaction_Type__c = 'Inventory Received - External Vendor',
                                                                                     Debit_Account_Number__c = finacialAccountNumber1.id,
                                                                                     Credit_Account_Number__c = finacialAccountNumber2.id);
        insert finacialTransaction1;
        
        Product2 masterProduct = new Product2( name = 'master',IsActive = true, recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Master_Product'));
        Product2 servProduct = new Product2( name = 'service',IsActive = true, recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Service_Product'),Master_Product__c = masterProduct.Id);
        Product2 servProduct2 = new Product2(name = 'service2',IsActive = true, recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Service_Product'),Master_Product__c = masterProduct.Id);
        
        Id pricebookId = Test.getStandardPricebookId();
        system.debug(pricebookId);
        
        List<Product2> products = new List<Product2>{masterProduct,servProduct,servProduct2};
            insert products;
        PricebookEntry pricebookEntryMaster= utility.createPricebookEntry(pricebookId, masterProduct.id);     
        PricebookEntry pricebookEntryServ = utility.createPricebookEntry(pricebookId, servProduct.id);    
        PricebookEntry pricebookEntryServ2 = utility.createPricebookEntry(pricebookId, servProduct2.id);      
        List<PriceBookEntry> pbEntries = new List<PricebookEntry>{pricebookEntryMaster,pricebookEntryServ,pricebookEntryServ2};
            insert pbEntries;
        
        List<Order> ordersToInsert = new List<Order>();
        
        Order order =  new Order(   Name='Sold Order 1', 
                                 AccountId = dwelling1.id, 
                                 BilltoContactId = contact1.id,
                                 EffectiveDate= Date.Today(), 
                                 Store_Location__c = store1.Id,                           
                                 Status ='Draft', 
                                 Pricebook2Id = pricebookId
                                );
        ordersToInsert.add(order);
        
        Order order2 =  new Order(   Name='Sold Order 2', 
                                  AccountId = dwelling2.id, 
                                  BilltoContactId = contact1.id,
                                  EffectiveDate= Date.Today(), 
                                  Store_Location__c = store1.Id,                           
                                  Status ='Draft', 
                                  Pricebook2Id = pricebookId,
                                  recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order')
                                 );
        ordersToInsert.add(order2);
        insert ordersToInsert;
        
        OrderItem orderItemMaster = new OrderItem(OrderId = Order.id, PricebookentryId = pricebookEntryMaster.Id, Quantity = 2, UnitPrice = 100, Charge_Cost_To__c = 'Customer-Replace' );
        insert orderItemMaster;
        
        rwo = new RbA_Work_Order__c();
        rwo.recordTypeId=UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
        rwo.Sold_Order__c = order2.Id;
        rwo.Account__c = dwelling1.id;
        rwo.Contact__c = contact1.id;
        rwo.Work_Order_Status__c = 'To be Scheduled';
        rwo.Work_Order_Type__c = 'Service';
        insert rwo;
        
        myTask1 = new Task();
        myTask1.Subject = 'test';
        myTask1.WhatId = rwo.Id;
        myTask1.Status = 'Open';
        myTask1.Service_Type__c = 'Service Task';
        insert myTask1;
        
        myTask2 = new Task();
        myTask2.Subject = 'test';
        myTask2.WhatId = rwo.Id;
        myTask2.Status = 'Open';
        myTask2.Service_Type__c = 'Service Material';
        insert myTask2;
    }
    
    @isTest static void test_EditableList() 
    {
        setupData();
        
        Test.startTest();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        Test.stopTest();
        
        System.assertEquals(0, mock.ZERO);
        System.assertEquals(0, mock.childList.size());
        System.assertEquals(0, mock.removeChildList.size());
    }
    
    @isTest static void test_getHasChildren()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        Test.startTest();
        
        System.assertEquals(false, mock.getHasChildren());
        
        mock.childList.add(new Task());
        
        System.assertEquals(true, mock.getHasChildren());
        
        Test.stopTest();
    }
    
    @isTest static void test_initChildRecord()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        Test.startTest();
        
        System.assert(mock.initChildRecord() instanceof Task);
        
        Test.stopTest();
    }
    
    @isTest static void test_addToList()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        System.assertEquals(0, mock.childList.size());
        
        Test.startTest();
        
        mock.addToList();
        
        Test.stopTest();
        
        System.assertEquals(1, mock.childList.size());
    }
    
    @isTest static void test_removeFromList()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        mock.childList.add(myTask1);
        mock.childList.add(myTask2);
        
        Test.startTest();
        
        mock.removeIndex = '1';
        mock.removeFromList();
        
        Test.stopTest();
        
        System.assertEquals(1, mock.childList.size());
        System.assertEquals(myTask2.Id, mock.childList[0].Id);
        System.assertEquals(1, mock.removeChildList.size());
        System.assertEquals(myTask1.Id, mock.removeChildList[0].Id);
    }
    
    @isTest static void test_getSuccessURL_param()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        String retURL = '/test';
        PageReference pr = new PageReference('/');
        pr.getParameters().put('retURL', retURL);
        
        Test.setCurrentPageReference(pr);
        Test.startTest();
        
        System.assertEquals(retURL, mock.getSuccessURL().getUrl());
        
        Test.stopTest();
    }
    
    @isTest static void test_getSuccessURL_noParam()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        PageReference pr = new PageReference('/');
        
        Test.setCurrentPageReference(pr);
        Test.startTest();
        
        System.assertEquals(std.view().getUrl(), mock.getSuccessURL().getUrl());
        
        Test.stopTest();
    }
    
    @isTest static void test_save_failure()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        mock.childList.add(myTask1);
        mock.removeChildList.add(myTask2);
        
        // Purposely leave out required Service Type
        Task newTask = new Task();
        newTask.WhatId = rwo.Id;
        
        mock.childList.add(newTask);
        
        Test.startTest();
        
        //System.assertEquals(null, mock.save());
        
        Test.stopTest();
        
        System.assertEquals(0, ApexPages.getMessages().size());
        //System.assertEquals(ApexPages.Severity.ERROR, ApexPages.getMessages()[0].getSeverity());
        
    }
    
    @isTest static void test_save_success()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        mock.childList.add(myTask1);
        mock.removeChildList.add(myTask2);
        
        Task newTask = new Task();
        newTask.Service_Type__c = 'Service Task';
        newTask.WhatId = rwo.Id;
        
        mock.childList.add(newTask);
        
        Test.startTest();
        
        System.assertEquals(mock.getSuccessURL().getUrl(), mock.save().getUrl());
        
        Test.stopTest();
        
        List<sObject> results = [SELECT Id FROM Task WHERE WhatId =: rwo.Id ORDER BY CreatedDate];
        System.assertEquals(2, results.size());
        System.assertEquals(myTask1.Id, results[0].Id);
        System.assertNotEquals(myTask2.Id, results[1].Id);
    }
}
@isTest
private class testRMS_editableTaskListExt 
{
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
        
        Service_Product__c servProd1 = new Service_Product__c(Service_Product__c = servProduct.Id, Master_Product__c = masterProduct.Id);
        Service_Product__c servProd2 = new Service_Product__c(Service_Product__c = servProduct2.Id, Master_Product__c = masterProduct.Id);
        List<Service_Product__c> sprods = new List<Service_Product__c>{servProd1,servProd2};
        insert sprods;
        
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
        
        OrderItem orderItemMaster = new OrderItem(OrderId = Order.id, PricebookentryId = pricebookEntryMaster.Id, Quantity = 2, UnitPrice = 100);
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
    
    @isTest static void test_EditableTaskListExtension()
    {
        setupData();
        
        Test.startTest();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        RMS_EditableTaskListExt ext = new RMS_EditableTaskListExt(std);
        
        Test.stopTest();
        
        System.assertEquals(0, ext.ZERO);
        System.assertEquals(0, ext.removeChildList.size());
        System.assertEquals(2, ext.childList.size());
    }
    
    @isTest static void test_getChildren()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        RMS_EditableTaskListExt ext = new RMS_EditableTaskListExt(std);
        
        Test.startTest();
        
        System.assert(ext.getChildren() instanceof List<Task>);
        
        Test.stopTest();    
    }
    
    @isTest static void test_initChildRecord()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        RMS_EditableTaskListExt ext = new RMS_EditableTaskListExt(std);
        
        Test.startTest();
        
        System.assert(ext.initChildRecord() instanceof Task);
        Task myTask = (Task)ext.initChildRecord();
        
        Test.stopTest();
        
        System.assertEquals(rwo.Id, myTask.WhatId);
    }
}
/*******************************************************//**

@class  testRMS_OrderItemExtension

@brief  Test Class for RMS_OrderItemExtension

@author  Brianne Wilson (Slalom.CDK)

@version    2015-3-15  Slalom.CDK
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
@isTest 
public with sharing class testRMS_OrderItemExtension {
    
    static testmethod void createTestRecords() {  
        RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name = 'Turn Financial Transactions Off', Value__c = 'Yes');
        insert turnOffFinancialTrigger;
        
        TestUtilityMethods utility = new TestUtilityMethods();
        utility.setUpConfigs();
        
        
        Account dwelling1 = utility.createDwellingAccount('Dwelling Account');       
        Account store1 = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
        Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
        dwelling1.Store_Location__c = store1.Id;         
        insert dwelling1;       
        
        Contact contact1 = new contact ( FirstName='Contact',LastName='1',AccountId=dwelling1.id);
        insert contact1;
        
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
        //utility.createOrderTestRecords();
        //
        
        Service_Product__c servProd1 = new Service_Product__c(name = 'service', Service_Product__c = servProduct.Id, Master_Product__c = masterProduct.Id);
        Service_Product__c servProd2 = new Service_Product__c(name = 'service2', Service_Product__c = servProduct2.Id, Master_Product__c = masterProduct.Id);
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
        Order o =  new Order(     Name='Service Order 1', 
                             AccountId = dwelling1.id, 
                             EffectiveDate= Date.Today(), 
                             Store_Location__c = store1.Id,                               
                             Status ='Draft', 
                             Sold_Order__c = order.Id,
                             BilltoContactId = contact1.id,
                             Service_Type__c = 'Job in Progress',                                             
                             Pricebook2Id = pricebookId
                            );
        ordersToInsert.add(o);
        insert ordersToInsert;
        
        
        OrderItem orderItemMaster = new OrderItem(OrderId = Order.id, PricebookentryId = pricebookEntryMaster.Id, Quantity = 2, UnitPrice = 100, Charge_Cost_To__c = 'Customer-Replace' );
        insert orderItemMaster;
        
        Asset asset = new Asset (     Name='Asset1',
                                 Original_Order_Product__c = orderItemMaster.Id,
                                 Product2Id= masterProduct.Id,
                                 AccountId = dwelling1.id,
                                 ContactId = contact1.id,
                                 Variant_Number__c = '1234ABC',
                                 Unit_Wholesale_Cost__c = 200,
                                 Store_Location__c = store1.id,
                                 Quantity = 1,
                                 Price = 100,
                                 Status = 'Installed',
                                 Sold_Order__c = order.Id,
                                 PurchaseDate = Date.Today()
                                );
        
        insert asset;  
        
        
        
        OrderItem serviceOrderItem = new OrderItem(Sold_Order_Product_Asset__c = asset.Id, Installed_Product_Asset__c = asset.Id,OrderId = o.id, Parent_Order_Item__c = orderItemMaster.id, PricebookentryId = pricebookEntryServ.Id, Quanity_Ordered__c = 2, Service__c = true, Quantity = 2, UnitPrice = 100, Charge_Cost_To__c = 'Local - Remake', Primary_Reason__c = 'Goodwill', Secondary_Reason__c = 'Customer Satisfaction' );
        insert serviceOrderItem;
        
        List<Service_Symptom_List__c> ssToInsert = new List<Service_Symptom_List__c>();
        Service_Symptom_List__c ssl1 = new Service_Symptom_List__c(name='SS1');
        ssToInsert.add(ssl1);
        Service_Symptom_List__c ssl2 = new Service_Symptom_List__c(name='SS2');
        ssToInsert.add(ssl2);
        Service_Symptom_List__c ssl3 = new Service_Symptom_List__c(name='SS3');
        ssToInsert.add(ssl3);        
        insert ssToInsert;
        System.assertEquals(ssToInsert.size() , 3); 
        
        List <Service_Symptom__c> servSympToInsert = new List<Service_Symptom__c>();
        Service_Symptom__c ss1 = new Service_Symptom__c(Service_Product__c = serviceOrderItem.Id, Service_Symptom__c = ssl1.Id);
        servSympToInsert.add(ss1);
        Service_Symptom__c ss2 = new Service_Symptom__c(Service_Product__c = serviceOrderItem.Id, Service_Symptom__c = ssl2.Id);
        servSympToInsert.add(ss2);
        insert servSympToInsert;
        System.assertEquals(servSympToInsert.size(),2);      
    }
    
    static testmethod void saveCloseTabTest(){
        createTestRecords();
        Test.startTest();
        Order order = [SELECT Id,AccountId FROM Order WHERE Name = 'Service Order 1'];
        OrderItem orderItem = [SELECT Id,OrderId,Charge_Cost_To__c FROM OrderItem WHERE OrderId =: order.id];        
        
        Test.setCurrentPage(Page.RMS_editServiceProduct);
        ApexPages.StandardController sc = new ApexPages.StandardController(OrderItem);
        RMS_OrderItemExtension TE = new RMS_OrderItemExtension(sc);
        Pagereference pr = TE.saveCloseTab();        
        OrderItem oi = [select id,Charge_Cost_To__c from OrderItem where id =: orderItem.id All rows];
        System.Assertequals(oi.Charge_Cost_To__c, 'Local - Remake');
        system.assertEquals(false, ApexPages.hasMessages());
        Test.stopTest();              
    }
    
    static testmethod void orderRedirectTest(){
        createTestRecords();
        Test.startTest();
        Order order = [SELECT Id,AccountId FROM Order WHERE Name = 'Service Order 1'];
        OrderItem orderItem = [SELECT Id,OrderId,Charge_Cost_To__c,Service__c FROM OrderItem WHERE OrderId =: order.id];        
        
        Test.setCurrentPage(Page.RMS_viewOrderItemRedirect);
        ApexPages.StandardController sc = new ApexPages.StandardController(OrderItem);
        RMS_OrderItemExtension TE = new RMS_OrderItemExtension(sc);
        Pagereference pr = TE.orderItemRedirect();        
        OrderItem oi = [select id,OrderId from OrderItem where id =: orderItem.id All rows];
        System.Assertequals(oi.OrderId, order.Id);
        system.assertEquals(false, ApexPages.hasMessages());
        Test.stopTest();              
    }
    
    
    static testmethod void orderRedirectTest2(){
        createTestRecords();
        Test.startTest();
        Order order = [SELECT Id,AccountId FROM Order WHERE Name = 'Service Order 1'];
        OrderItem orderItem = [SELECT Id,OrderId,Service__c FROM OrderItem WHERE OrderId =: order.id];        
        
        Test.setCurrentPage(Page.RMS_viewOrderItemRedirect);
        ApexPages.StandardController sc = new ApexPages.StandardController(OrderItem);
        RMS_OrderItemExtension TE = new RMS_OrderItemExtension(sc);
        orderItem.Service__c = false;
        update orderItem;
        Pagereference pr = TE.orderItemRedirect();        
        OrderItem oi = [select id,OrderId from OrderItem where id =: orderItem.id All rows];
        System.Assertequals(oi.OrderId, order.Id);
        system.assertEquals(false, ApexPages.hasMessages());
        Test.stopTest();              
    }
    
    static testmethod void saveCloseTabTestError(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,AccountId FROM Order WHERE Name = 'Service Order 1'];
        Asset asset = [Select Id FROM Asset WHERE Variant_Number__c = '1234ABC'];
        Id pricebookId = Test.getStandardPricebookId();
        Product2 masterProduct = new Product2( name = 'master',IsActive = true, recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Master_Product'));
        Product2 servProduct = [SELECT Id from Product2 WHERE name = 'service'];
        PricebookEntry pricebookEntryServ = [SELECT Id FROM PricebookEntry WHERE Product2Id = :servProduct.id];
        OrderItem orderItem = new OrderItem(Installed_Product_Asset__c = asset.Id,OrderId = order.id, PricebookentryId = pricebookEntryServ.Id, Quanity_Ordered__c = 2, Service__c = true, Quantity = 2, UnitPrice = 100);
        
        
        Test.setCurrentPage(Page.RMS_editServiceProduct);
        ApexPages.StandardController sc = new ApexPages.StandardController(OrderItem);
        RMS_OrderItemExtension TE = new RMS_OrderItemExtension(sc);
        Pagereference pr = TE.saveCloseTab(); 
        Test.stopTest();
        // TODO: fix assertion
        //        system.assertEquals(true, ApexPages.hasMessages());
        
        
        
    }
    
    static testmethod void editOrderItemTest(){
        createTestRecords();
        Test.startTest();
        Order order = [SELECT Id,AccountId FROM Order WHERE Name = 'Service Order 1'];
        OrderItem orderItem = [SELECT Id,OrderId,Charge_Cost_To__c,Service__c FROM OrderItem WHERE OrderId =: order.id];        
        
        Test.setCurrentPage(Page.RMS_viewServiceOrderItem);
        ApexPages.StandardController sc = new ApexPages.StandardController(OrderItem);
        RMS_OrderItemExtension TE = new RMS_OrderItemExtension(sc);
        Pagereference pr = TE.editOrderItem();        
        OrderItem oi = [select id,OrderId from OrderItem where id =: orderItem.id All rows];
        System.Assertequals(oi.OrderId, order.Id);
        system.assertEquals(false, ApexPages.hasMessages());
        Test.stopTest();              
    }
    
    static testmethod void cancelOrderItemTest(){
        createTestRecords();
        Test.startTest();
        Order order = [SELECT Id,AccountId FROM Order WHERE Name = 'Service Order 1'];
        OrderItem orderItem = [SELECT Id,OrderId,Charge_Cost_To__c,Service__c FROM OrderItem WHERE OrderId =: order.id];        
        
        Test.setCurrentPage(Page.RMS_editServiceProduct);
        ApexPages.StandardController sc = new ApexPages.StandardController(OrderItem);
        RMS_OrderItemExtension TE = new RMS_OrderItemExtension(sc);
        Pagereference pr = TE.cancelOrderItem();        
        OrderItem oi = [select id,OrderId from OrderItem where id =: orderItem.id All rows];
        System.Assertequals(oi.OrderId, order.Id);
        system.assertEquals(false, ApexPages.hasMessages());
        Test.stopTest();              
    }
    
    static testmethod void addResponsibilityTest(){
        createTestRecords();
        Test.startTest();
        Order order = [SELECT Id,AccountId FROM Order WHERE Name = 'Service Order 1'];
        OrderItem orderItem = [SELECT Id,OrderId,Charge_Cost_To__c,Service__c FROM OrderItem WHERE OrderId =: order.id];        
        
        Test.setCurrentPage(Page.RMS_viewServiceOrderItem);
        ApexPages.StandardController sc = new ApexPages.StandardController(OrderItem);
        RMS_OrderItemExtension TE = new RMS_OrderItemExtension(sc);
        Pagereference pr = TE.addResponsibility();        
        OrderItem oi = [select id,OrderId from OrderItem where id =: orderItem.id All rows];
        System.Assertequals(oi.OrderId, order.Id);
        system.assertEquals(false, ApexPages.hasMessages());
        Test.stopTest();              
    }
    
    static testmethod void addWarrantyTest(){
        createTestRecords();
        Test.startTest();
        Order order = [SELECT Id,AccountId FROM Order WHERE Name = 'Service Order 1'];
        OrderItem orderItem = [SELECT Id,OrderId,Charge_Cost_To__c,Service__c FROM OrderItem WHERE OrderId =: order.id];        
        
        Test.setCurrentPage(Page.RMS_viewServiceOrderItem);
        ApexPages.StandardController sc = new ApexPages.StandardController(OrderItem);
        RMS_OrderItemExtension TE = new RMS_OrderItemExtension(sc);
        Pagereference pr = TE.addWarranty();        
        OrderItem oi = [select id,OrderId from OrderItem where id =: orderItem.id All rows];
        System.Assertequals(oi.OrderId, order.Id);
        system.assertEquals(false, ApexPages.hasMessages());
        Test.stopTest();              
    }
    
    static testmethod void addServiceSymptomTest(){
        createTestRecords();
        Test.startTest();
        Order order = [SELECT Id,AccountId FROM Order WHERE Name = 'Service Order 1'];
        OrderItem orderItem = [SELECT Id,Product_Name__c,Sold_Order_Product_Asset__c,Installed_Product_Name__c,OrderId,Charge_Cost_To__c,Service__c FROM OrderItem WHERE OrderId =: order.id];        
        
        Test.setCurrentPage(Page.RMS_viewServiceOrderItem);
        ApexPages.StandardController sc = new ApexPages.StandardController(OrderItem);
        RMS_OrderItemExtension TE = new RMS_OrderItemExtension(sc);
        String ssSp = orderItem.Id;
        String oiLabel = orderItem.Installed_Product_Name__c;
        Pagereference pr = TE.addServiceSymptom();        
        OrderItem oi = [select id,OrderId from OrderItem where id =: orderItem.id All rows];
        System.Assertequals(oi.OrderId, order.Id);
        system.assertEquals(false, ApexPages.hasMessages());
        Test.stopTest();              
    }
    
    
    
    
    
}
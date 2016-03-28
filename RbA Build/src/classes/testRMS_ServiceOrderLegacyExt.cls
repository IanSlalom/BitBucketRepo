/*******************************************************//**

@class  testRMS_ServiceOrderLegacyExt

@brief  Test Class for RMS_ServiceOrderLegacyExt

@author  Brianne Wilson (Slalom.CDK)

@version    2015-3-15  Slalom.CDK
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
@isTest 
public with sharing class testRMS_ServiceOrderLegacyExt {
    
    static testmethod void createTestRecords() {
        TestUtilityMethods utility = new TestUtilityMethods();
        utility.setUpConfigs();
        
        
        Account dwelling1 = utility.createDwellingAccount('Dwelling Account');
        Account dwelling2 = utility.createDwellingAccount('Dwelling Account 2');
        Account dwelling3 = utility.createDwellingAccount('Dwelling Account 3');
        Account store1 = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
        Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
        dwelling1.Store_Location__c = store1.Id;
        dwelling2.Store_Location__c = store1.Id; 
        dwelling3.Store_Location__c = store1.Id;         
        insert dwelling1;
        insert dwelling2;
        insert dwelling3;        
        
        Contact contact1 = new contact ( FirstName='Contact',LastName='1',AccountId=dwelling1.id);
        insert contact1;
        Contact contact2 = new contact ( FirstName='Contact',LastName='2',AccountId=dwelling2.id);
        insert contact2;
        
        Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (  Store_Configuration__c = storeConfig1.id, Name = '1');
        insert finacialAccountNumber1;
        Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (  Store_Configuration__c = storeConfig1.id, Name = '2');
        insert finacialAccountNumber2;
        
        Financial_Transaction__c finacialTransaction1 = new Financial_Transaction__c(  Store_Configuration__c = storeConfig1.id,
                                                                                     Transaction_Type__c = 'Inventory Received',
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
        Order order =  new Order(   Name='Sold Order 1', 
                                 AccountId = dwelling1.id, 
                                 BilltoContactId = contact1.id,
                                 EffectiveDate= Date.Today(), 
                                 Store_Location__c = store1.Id,                           
                                 Status ='Draft', 
                                 Pricebook2Id = pricebookId
                                );
        insert order;   
        
        Order order2 =  new Order(   Name='Sold Order 2', 
                                  AccountId = dwelling2.id, 
                                  BilltoContactId = contact2.id,
                                  EffectiveDate= Date.Today(), 
                                  Store_Location__c = store1.Id,                           
                                  Status ='Draft', 
                                  Pricebook2Id = pricebookId,
                                  recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order')
                                 );
        insert order2;   
        
        
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
        
        Asset asset2 = new Asset (     Name='Asset2',
                                  Original_Order_Product__c = orderItemMaster.Id,
                                  Product2Id= masterProduct.Id,
                                  AccountId = dwelling2.id,
                                  ContactId = contact2.id,
                                  Variant_Number__c = '1234ABCD',
                                  Unit_Wholesale_Cost__c = 200,
                                  Store_Location__c = store1.id,
                                  Quantity = 1,
                                  Price = 100,
                                  Status = 'Installed',
                                  Sold_Order__c = order.Id,
                                  PurchaseDate = Date.Today()
                                 );
        
        insert asset2;         
        
        
        
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
        insert o;
        
        OrderItem serviceOrderItem = new OrderItem(Installed_Product_Asset__c = asset.Id,OrderId = o.id, Parent_Order_Item__c = orderItemMaster.id, PricebookentryId = pricebookEntryServ.Id, Quanity_Ordered__c = 2, Service__c = true, Quantity = 2, UnitPrice = 100, Charge_Cost_To__c = 'Local - Remake', Primary_Reason__c = 'Goodwill', Secondary_Reason__c = 'Customer Satisfaction' );
        insert serviceOrderItem;
    }
    
    static testmethod void customDeleteTest(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId FROM Order WHERE Name = 'Sold Order 1'];        
        
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt TE = new RMS_ServiceOrderLegacyExt(sc);
        Pagereference pr = TE.customDelete();        
        Order delOrd = [select id,isdeleted from Order where id =: order.id All rows];
        System.Assertequals(delOrd.isdeleted, true);
                        
    }
    
        static testmethod void testOptionList(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt TE = new RMS_ServiceOrderLegacyExt(sc);
        list<SelectOption> testoptions = TE.getPickLstValue();
        
        system.assertEquals(3,testoptions.size());
        
    }
    
    
    static testmethod void testProductWrapperManufacturer(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Product2 prod = [SELECT id FROM Product2 WHERE Id = :pbe.Product2Id];
        OrderItem oi = [SELECT id, Charge_Cost_To__c, Primary_Reason__c, Secondary_Reason__c, OrderId FROM OrderItem WHERE OrderId =: order.id];
        
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt.ProductWrapper TE = new RMS_ServiceOrderLegacyExt.ProductWrapper(prod);
        
        TE.cost = 'Manufacturer - Replace';
        for(SelectOption primOpt : TE.getPrimaries()){
            primOpt.getValue();
        }  
        
    }
    
    static testmethod void testProductWrapperLocal(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Product2 prod = [SELECT id FROM Product2 WHERE Id = :pbe.Product2Id];
        OrderItem oi = [SELECT id, Charge_Cost_To__c, Primary_Reason__c, Secondary_Reason__c, OrderId FROM OrderItem WHERE OrderId =: order.id];
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt.ProductWrapper TE = new RMS_ServiceOrderLegacyExt.ProductWrapper(prod);
        
        TE.cost = 'Local - Remake';
        for(SelectOption primOpt : TE.getPrimaries()){
            primOpt.getValue();
        }  
        
    }
    
    static testmethod void testProductWrapperGoodwill(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Product2 prod = [SELECT id FROM Product2 WHERE Id = :pbe.Product2Id];
        OrderItem oi = [SELECT id, Charge_Cost_To__c, Primary_Reason__c, Secondary_Reason__c, OrderId FROM OrderItem WHERE OrderId =: order.id];
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt.ProductWrapper TE = new RMS_ServiceOrderLegacyExt.ProductWrapper(prod);
        
        TE.primary = 'Goodwill';
        for(SelectOption secOpt : TE.getSecondaries()){
            secOpt.getValue();
        }  
        
    }
    
    static testmethod void testProductWrapperInstallation(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Product2 prod = [SELECT id FROM Product2 WHERE Id = :pbe.Product2Id];
        OrderItem oi = [SELECT id, Charge_Cost_To__c, Primary_Reason__c, Secondary_Reason__c, OrderId FROM OrderItem WHERE OrderId =: order.id];
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt.ProductWrapper TE = new RMS_ServiceOrderLegacyExt.ProductWrapper(prod);        
        
        TE.primary = 'Installation';
        for(SelectOption secOpt : TE.getSecondaries()){
            secOpt.getValue();
        }  
        
    }
    
    static testmethod void testProductWrapperManagement(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Product2 prod = [SELECT id FROM Product2 WHERE Id = :pbe.Product2Id];
        OrderItem oi = [SELECT id, Charge_Cost_To__c, Primary_Reason__c, Secondary_Reason__c, OrderId FROM OrderItem WHERE OrderId =: order.id];
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt.ProductWrapper TE = new RMS_ServiceOrderLegacyExt.ProductWrapper(prod);        
        
        TE.primary = 'Management';
        for(SelectOption secOpt : TE.getSecondaries()){
            secOpt.getValue();
        }  
        
    }
    
    static testmethod void testProductWrapperOE(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Product2 prod = [SELECT id FROM Product2 WHERE Id = :pbe.Product2Id];
        OrderItem oi = [SELECT id, Charge_Cost_To__c, Primary_Reason__c, Secondary_Reason__c, OrderId FROM OrderItem WHERE OrderId =: order.id];
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt.ProductWrapper TE = new RMS_ServiceOrderLegacyExt.ProductWrapper(prod);        
        
        TE.primary = 'Order Entry';
        for(SelectOption secOpt : TE.getSecondaries()){
            secOpt.getValue();
        }  
        
    }
    
    static testmethod void testProductWrapperSales(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Product2 prod = [SELECT id FROM Product2 WHERE Id = :pbe.Product2Id];
        OrderItem oi = [SELECT id, Charge_Cost_To__c, Primary_Reason__c, Secondary_Reason__c, OrderId FROM OrderItem WHERE OrderId =: order.id];
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt.ProductWrapper TE = new RMS_ServiceOrderLegacyExt.ProductWrapper(prod);        
        
        TE.primary = 'Sales';
        for(SelectOption secOpt : TE.getSecondaries()){
            secOpt.getValue();
        }  
        
    }
    
    static testmethod void testProductWrapperService(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Product2 prod = [SELECT id FROM Product2 WHERE Id = :pbe.Product2Id];
        OrderItem oi = [SELECT id, Charge_Cost_To__c, Primary_Reason__c, Secondary_Reason__c, OrderId FROM OrderItem WHERE OrderId =: order.id];
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt.ProductWrapper TE = new RMS_ServiceOrderLegacyExt.ProductWrapper(prod);        
        
        TE.primary = 'Service';
        for(SelectOption secOpt : TE.getSecondaries()){
            secOpt.getValue();
        }  
        
    }
    
    static testmethod void testProductWrapperStaining(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Product2 prod = [SELECT id FROM Product2 WHERE Id = :pbe.Product2Id];
        OrderItem oi = [SELECT id, Charge_Cost_To__c, Primary_Reason__c, Secondary_Reason__c, OrderId FROM OrderItem WHERE OrderId =: order.id];
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt.ProductWrapper TE = new RMS_ServiceOrderLegacyExt.ProductWrapper(prod);        
        
        TE.primary = 'Staining';
        for(SelectOption secOpt : TE.getSecondaries()){
            secOpt.getValue();
        }  
        
    }
    
    static testmethod void testProductWrapperTechMeasure(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Product2 prod = [SELECT id FROM Product2 WHERE Id = :pbe.Product2Id];
        OrderItem oi = [SELECT id, Charge_Cost_To__c, Primary_Reason__c, Secondary_Reason__c, OrderId FROM OrderItem WHERE OrderId =: order.id];
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt.ProductWrapper TE = new RMS_ServiceOrderLegacyExt.ProductWrapper(prod);        
        
        TE.primary = 'Tech Measure';
        for(SelectOption secOpt : TE.getSecondaries()){
            secOpt.getValue();
        }  
        
    }
    
    static testmethod void testProductWrapperWarehouse(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Product2 prod = [SELECT id FROM Product2 WHERE Id = :pbe.Product2Id];
        OrderItem oi = [SELECT id, Charge_Cost_To__c, Primary_Reason__c, Secondary_Reason__c, OrderId FROM OrderItem WHERE OrderId =: order.id];
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt.ProductWrapper TE = new RMS_ServiceOrderLegacyExt.ProductWrapper(prod);        
        
        TE.primary = 'Warehouse';
        for(SelectOption secOpt : TE.getSecondaries()){
            secOpt.getValue();
        }  
        
    }
    
    static testmethod void testProductWrapperHomeOwner(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Product2 prod = [SELECT id FROM Product2 WHERE Id = :pbe.Product2Id];
        OrderItem oi = [SELECT id, Charge_Cost_To__c, Primary_Reason__c, Secondary_Reason__c, OrderId FROM OrderItem WHERE OrderId =: order.id];
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt.ProductWrapper TE = new RMS_ServiceOrderLegacyExt.ProductWrapper(prod);        
        
        TE.primary = 'Home Owner';
        for(SelectOption secOpt : TE.getSecondaries()){
            secOpt.getValue();
        }  
        
    }
    
    static testmethod void testDependentPicklist(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Product2 prod = [SELECT id FROM Product2 WHERE Id = :pbe.Product2Id];
        Boolean isSelected = true;
        Asset asset = [Select Id FROM Asset WHERE Variant_Number__c = '1234ABC'];
        
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt.ProductWrapper TE = new RMS_ServiceOrderLegacyExt.ProductWrapper(prod);
        list<SelectOption> costoptions = TE.getCosts();
        list<SelectOption> primaryoptions = TE.getPrimaries();
        list<SelectOption> secondaryoptions = TE.getSecondaries();
        String cost = TE.getCost();
        String primary = TE.getPrimary();
        String secondary = TE.getSecondary();        
        
        system.assertEquals(null,cost);
        system.assertEquals(null,primary);
        system.assertEquals(null,secondary);
        
        
        
    }
    
    
    static testmethod void saveClosetest(){
        createTestRecords();
        Order order = [SELECT Id,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Service Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];
        
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderLegacyExt TE = new RMS_ServiceOrderLegacyExt(sc);
        Boolean hasValidationErrors = false;
        String propPickValSelected = TE.getpropPickValSelected();
        Pagereference pr = TE.saveClose();        
        Order ord = [select id,Name from Order where id =: order.id];
        System.Assertequals(ord.Name, 'Service Order 1');
    }
    
    
    
}
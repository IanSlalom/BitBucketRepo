/*******************************************************//**

@class  testRMS_ServiceOrderExtMgr

@brief  Test Class for RMS_ServiceOrderExtMgr

@author  Brianne Wilson (Slalom.BLW)

@version    2015-3-15  Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
@isTest 
public with sharing class testRMS_ServiceOrderExtMgr {
    
    static testmethod void createTestRecords() {
        RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name = 'Turn Financial Transactions Off', Value__c = 'Yes');
        	insert turnOffFinancialTrigger;

        TestUtilityMethods utility = new TestUtilityMethods();
        utility.setUpConfigs();
        
        List<Account> dwellingsToInsert = new List<Account>();       
        
        Account dwelling1 = utility.createDwellingAccount('Dwelling Account');
        Account dwelling2 = utility.createDwellingAccount('Dwelling Account 2');
        Account dwelling3 = utility.createDwellingAccount('Dwelling Account 3');
        Account store1 = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
        Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
        storeConfig1.Sales_Tax__c = 5;
        update storeConfig1;
        dwelling1.Store_Location__c = store1.Id;
        dwelling2.Store_Location__c = store1.Id; 
        dwelling3.Store_Location__c = store1.Id;         
        dwellingsToInsert.add(dwelling1);
        dwellingsToInsert.add(dwelling2);
        dwellingsToInsert.add(dwelling3);        
        insert dwellingsToInsert;        
        
        List<Contact> contactsToInsert = new List<Contact>();       
        Contact contact1 = new contact ( FirstName='Contact',LastName='1',AccountId=dwelling1.id, Primary_Contact__c =true, Primary_Dwelling_for_Contact__c=true );
        contactsToInsert.add(contact1);
        Contact contact2 = new contact ( FirstName='Contact',LastName='2',AccountId=dwelling2.id, Primary_Contact__c =true, Primary_Dwelling_for_Contact__c=true );
        contactsToInsert.add(contact2);
        Contact contact3 = new contact ( FirstName='Contact',LastName='3',AccountId=dwelling3.id, Primary_Contact__c =true, Primary_Dwelling_for_Contact__c=true );
        contactsToInsert.add(contact3);
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
        //utility.createOrderTestRecords();
        
        List<Order> ordersToInsert = new List<Order>();
        
        Order order =  new Order(   Name='Sold Order 1', 
                                 AccountId = dwelling1.id, 
                                 BilltoContactId = contact1.id,
                                 EffectiveDate= Date.Today(), 
                                 Store_Location__c = store1.Id,                           
                                 Status ='Draft', 
                                 Pricebook2Id = pricebookId,
                                 Customer_Pickup_All__c = FALSE,
                                 Installation_Date__c = system.today()-1 
                                );
        ordersToInsert.add(order);
        
        Order order2 =  new Order(   Name='Sold Order 2', 
                                  AccountId = dwelling2.id, 
                                  BilltoContactId = contact2.id,
                                  EffectiveDate= Date.Today(), 
                                  Store_Location__c = store1.Id,                           
                                  Status ='Draft',
                                  Customer_Pickup_All__c = FALSE,
                                  Pricebook2Id = pricebookId,
                                  Installation_Date__c = system.today()-60,
                                  recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order')
                                 );
        ordersToInsert.add(order2);
        
        Order o =  new Order(     Name='Service Order 1', 
                             AccountId = dwelling1.id, 
                             EffectiveDate= Date.Today(), 
                             Store_Location__c = store1.Id,                               
                             Status ='Draft', 
                             Sold_Order__c = order.Id,
                             Customer_Pickup_All__c = FALSE,
                             BilltoContactId = contact1.id,
                             Service_Type__c = 'Job in Progress',                                             
                             Pricebook2Id = pricebookId
                            );
        ordersToInsert.add(o);
        insert ordersToInsert;
        
        
        OrderItem orderItemMaster = new OrderItem(OrderId = Order.id, PricebookentryId = pricebookEntryMaster.Id, Quantity = 2, UnitPrice = 100, Charge_Cost_To__c = 'Customer-Replace',Quote_Accepted__c = FALSE );
        insert orderItemMaster;
        
        List<Asset> assetsToInsert = new List<Asset>();
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
        
        assetsToInsert.add(asset);         
        
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
        
        assetsToInsert.add(asset2);         
        insert assetsToInsert;                                  
        
        OrderItem serviceOrderItem = new OrderItem(Installed_Product_Asset__c = asset.Id,OrderId = o.id, Quote_Accepted__c = FALSE, Parent_Order_Item__c = orderItemMaster.id, PricebookentryId = pricebookEntryServ.Id, Quanity_Ordered__c = 2, Service__c = true, Quantity = 2, UnitPrice = 100, Charge_Cost_To__c = 'Local - Remake', Primary_Reason__c = 'Goodwill', Secondary_Reason__c = 'Customer Satisfaction' );
        insert serviceOrderItem;
        
        Service_Product__c spr = new Service_Product__c(Master_Product__c = masterProduct.Id, Service_Product__c = servProduct.Id, Name = servProduct.Name);
        insert spr;
    }
    
    static testmethod void customDeleteTest(){
        createTestRecords();
        
                Test.startTest();
        Order order = [SELECT Id,Service_Type__c,AccountId FROM Order WHERE Name = 'Sold Order 1'];        
                       
        Test.setCurrentPage(Page.RMS_createServiceRequestP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        Pagereference pr = TE.customDelete();                    
        Order delOrd = [select id,isdeleted from Order where id =: order.id All rows];
        System.Assertequals(delOrd.isdeleted, true);
        
        Test.stopTest(); 
        
        
    }
    
    static testmethod void saveOrderTest(){
        createTestRecords();
        
        Order order = [SELECT Id,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        
        Test.startTest();
        
        Test.setCurrentPage(Page.RMS_createServiceRequestRedirect);
        ApexPages.currentPage().getParameters().put('aid',aid.id);
        ApexPages.currentPage().getParameters().put('slid',slid.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        Integer num_orders = TE.getnumorders();
        Integer num_assets = TE.getnumassets();
        String propPickValSelected = TE.getpropPickValSelected();        
        
        Pagereference pr = TE.saveOrder();        
        Order ord = [select id,Name from Order where id =: order.id];
        
        System.Assertequals(ord.Name, 'Sold Order 1');
        System.assertEquals(2, num_orders);
        System.assertEquals(1, num_assets);  
        
        Test.stopTest();       
    }
    static testmethod void saveOrderTest2(){
        createTestRecords();
        
        Account acct = [Select Id FROM Account WHERE Name = 'Dwelling Account 2'];
        Contact cont = [Select Id FROM Contact Where LastName = '2'];
        Account store1 = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        
        Test.startTest();
        
        Test.setCurrentPage(Page.RMS_createServiceRequestRedirect);
        ApexPages.currentPage().getParameters().put('aid',acct.id);
        ApexPages.currentPage().getParameters().put('slid',store1.id);
        
        Order order2 =  new Order(   Name='Sold Order 2', 
                                  AccountId = acct.id, 
                                  BilltoContactId = cont.id,
                                  EffectiveDate= Date.Today(), 
                                  Store_Location__c = store1.Id,                           
                                  Status ='Draft',
                                  recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order')
                                 );
        insert order2;
        
        ApexPages.StandardController sc2 = new ApexPages.StandardController(order2);
        RMS_ServiceOrderExtensionMgr TE2 = new RMS_ServiceOrderExtensionMgr(sc2);
        Pagereference pr2 = TE2.saveOrder();        
        Order ord2 = [select id,Name from Order where id =: order2.id];
        System.Assertequals(ord2.Name, 'Sold Order 2');
        
        Test.stopTest();
    }
    
    static testmethod void saveOrderTest3(){
        createTestRecords();
        
        Account acct3 = [Select Id FROM Account WHERE Name = 'Dwelling Account 3'];
        Account store1 = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        
        Test.startTest();
        Test.setCurrentPage(Page.RMS_createServiceRequestRedirect);
        ApexPages.currentPage().getParameters().put('aid',acct3.id);
        ApexPages.currentPage().getParameters().put('slid',store1.id);
        
        Order order3 =  new Order(   Name='Sold Order 3', 
                                  AccountId = acct3.id, 
                                  EffectiveDate= Date.Today(), 
                                  Store_Location__c = store1.Id,                           
                                  Status ='Draft',
                                  recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order')
                                 );
        insert order3;
        
        ApexPages.StandardController sc3 = new ApexPages.StandardController(order3);
        RMS_ServiceOrderExtensionMgr TE3 = new RMS_ServiceOrderExtensionMgr(sc3);
        Pagereference pr3 = TE3.saveOrder();        
        Order ord3 = [select id,Name from Order where id =: order3.id];
        System.Assertequals(ord3.Name, 'Sold Order 3');
        
        Test.stopTest();
        
        
    } 
    
    static testmethod void testOptionList(){
        createTestRecords();
        
        Order order = [SELECT Id,Service_Type__c,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        
        Test.startTest();
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        list<SelectOption> testoptions = TE.getOrds();
        
        system.assertEquals(1,testoptions.size());
        
        Test.stopTest();
        
    }
    
    static testmethod void testOptionListP2(){
        createTestRecords();
        
        Order order = [SELECT Id,Service_Type__c,AccountId,Installation_Date__c,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        
        Test.startTest();        
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP2);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        list<SelectOption> testoptions = TE.getPickLstValue();
        
        system.assertEquals(2,testoptions.size());
        
        Test.stopTest();        
    }
    
    static testmethod void testServiceType(){
        createTestRecords();
        
        Order order = [SELECT Id,Service_Type__c,AccountId,Installation_Date__c,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        
        Test.startTest();        
        
        Test.setCurrentPage(Page.RMS_updateServiceType);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        list<SelectOption> testoptions = TE.getPickLstValue2();
        String propPickValSelected2 = TE.getpropPickValSelected2();
        
        system.assertEquals(2,testoptions.size());
        
        Test.stopTest();        
    }

    
    static testmethod void testDependentPicklist(){
        createTestRecords();
        
        
        Test.startTest();  
        Order order = [SELECT Id,Service_Type__c,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Service_Product__c prod = [SELECT id, Service_Product__c FROM Service_Product__c WHERE Service_Product__c = :pbe.Product2Id];
        Boolean isSelected = true;
        Asset asset = [Select Id FROM Asset WHERE Variant_Number__c = '1234ABC'];

        
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP2);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr.ProductWrapper TE = new RMS_ServiceOrderExtensionMgr.ProductWrapper(prod);
       
        
        Test.stopTest();
        
    }
    
    
    static testmethod void saveP2test(){
        createTestRecords();
        
        Test.startTest(); 
        Order order = [SELECT Id,Service_Type__c,Sales_Tax_Percent__c,AccountId,pricebook2id,BilltoContactId,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id,Sales_Tax__c FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Contact contact = [Select Id FROM Contact WHERE id =:order.BilltoContactId];
        
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        Pagereference pr = TE.saveP2();        
        Order ord = [select id,Name,BilltoContactId from Order where id =: order.id];
        System.Assertequals(ord.Name, 'Sold Order 1');
        System.Assertequals(ord.BilltoContactId, contact.id);
        Test.stopTest();        
    }
    
    static testmethod void saveClosetest(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Service Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP2);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        Pagereference pr = TE.saveClose();        
        Order ord = [select id,Name from Order where id =: order.id];
        System.Assertequals(ord.Name, 'Service Order 1');
        
        Test.stopTest();
    }
    
    static testmethod void saveServiceTypePage(){
        createTestRecords();
        
        Order order = [SELECT Id,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        
        Test.startTest();
        
        Test.setCurrentPage(Page.RMS_updateServiceType);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        String propPickValSelected2 = TE.getpropPickValSelected2();        
        
        Pagereference pr = TE.saveST();        
        Order ord = [select id,Name from Order where id =: order.id];
        
        System.Assertequals(ord.Name, 'Sold Order 1');
        
        Test.stopTest();       
    }
    
    static testmethod void saveNewProducts(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,Validate_Service_Order__c,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP2);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        String propPickValSelected = TE.getpropPickValSelected();        
        
        Pagereference pr = TE.saveNewProducts();        
        Order ord = [select id,Name,Validate_Service_Order__c from Order where id =: order.id];
        
        System.Assertequals(ord.Name, 'Sold Order 1');
        System.Assertequals(ord.Validate_Service_Order__c, true);
        
        Test.stopTest();       
    }
    
    private testMethod static void testSuccess() {
        RMS_serviceRequestListViewMgr con = new RMS_serviceRequestListViewMgr();
        String propPickValSelected = con.getpropPickValSelected(); 
        con.listName = 'Service Requests - All';
        con.propPickValSelected = 'Service Requests - All';
        for(SelectOption listView : con.getPickLstValue()){
            listView.getValue();
        } 
        System.assert(con.listId != null);
    }
    
    private testMethod static void testFailure() {
        RMS_serviceRequestListViewMgr con = new RMS_serviceRequestListViewMgr();
        con.listName = 'BADLISTNAME';
        System.assert(con.listId == null);
        
    }
    
    static testmethod void listView(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,Validate_Service_Order__c,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];               
        
        
        Test.setCurrentPage(Page.RMS_serviceRequestListView);
        //ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_serviceRequestListViewMgr TE = new RMS_serviceRequestListViewMgr();
        String propPickValSelected = TE.getpropPickValSelected();   
        TE.propPickValSelected = 'Service Requests - All';
        for(SelectOption listView : TE.getPickLstValue()){
            listView.getValue();
        } 
        
        
        Test.stopTest();       
    }
}
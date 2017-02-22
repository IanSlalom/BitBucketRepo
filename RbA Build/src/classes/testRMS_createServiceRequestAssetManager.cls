@isTest 
public with sharing class testRMS_createServiceRequestAssetManager {
    
    static testmethod void createTestRecords() {      
        RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name = 'Turn Financial Transactions Off', Value__c = 'Yes');
        insert turnOffFinancialTrigger;
        
        TestUtilityMethods utility = new TestUtilityMethods();
        utility.setUpConfigs();
        
        List<Account> dwellingsToInsert = new List<Account>();               
        Account dwelling1 = utility.createDwellingAccount('Dwelling Account');
        Account dwelling2 = utility.createDwellingAccount('Dwelling Account 2');        
        Account store1 = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];        
        Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
        storeConfig1.Sales_Tax__c = 5;
        update storeConfig1;
        dwelling1.Store_Location__c = store1.Id;
        dwelling2.Store_Location__c = store1.Id;        
        dwellingsToInsert.add(dwelling1);
        dwellingsToInsert.add(dwelling2);      
        insert dwellingsToInsert;        
        
        List<Contact> contactsToInsert = new List<Contact>();       
        Contact contact1 = new contact ( FirstName='Contact',LastName='1',AccountId=dwelling1.id, Primary_Contact__c =true);
        contactsToInsert.add(contact1);
        Contact contact2 = new contact ( FirstName='Contact',LastName='2',AccountId=dwelling2.id, Primary_Contact__c =true);
        contactsToInsert.add(contact2);
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
        
        Id pricebookId = Test.getStandardPricebookId();
        system.debug(pricebookId);
        
        Pricebook2 pricebook1 =  utility.createPricebook2Name('Standard Price Book');
        insert pricebook1;
        
        List<Product2> products = new List<Product2>{masterProduct};
            insert products;
        
        PricebookEntry pricebookEntryMaster= utility.createPricebookEntry(pricebookId, masterProduct.id);             
        
        List<PriceBookEntry> pbEntries = new List<PricebookEntry>{pricebookEntryMaster};
            insert pbEntries;
        
        
        List<Order> ordersToInsert = new List<Order>();
        
        Order order =  new Order(   Name='Sold Order 1', 
                                 AccountId = dwelling1.id, 
                                 BilltoContactId = contact1.id,
                                 EffectiveDate= Date.Today(), 
                                 Store_Location__c = store1.Id,                           
                                 Status ='Install Complete', 
                                 Pricebook2Id = Test.getStandardPricebookId(),
                                 Customer_Pickup_All__c = FALSE,
                                 Installation_Date__c = system.today()-1 
                                );
        ordersToInsert.add(order);
        
        
        insert ordersToInsert;
        
        System.assertEquals(ordersToInsert.size() , 1); 
        
        
        OrderItem orderItemMaster = new OrderItem(OrderId = Order.id, PricebookentryId = pricebookEntryMaster.Id, Quantity = 2, UnitPrice = 100,Quote_Accepted__c = FALSE );
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
        
        
        insert assetsToInsert;  
        System.assertEquals(assetsToInsert.size() , 1);                                 
        
    }
    
    //createServiceRequestRedirectMethods
    
    
    static testmethod void saveAsset(){
        createTestRecords();
        
        Account aid = [Select Id FROM Account WHERE Name = '11111, Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        
        Test.startTest();
        
        Order order = new Order(AccountId = aid.Id, Store_Location__c = slid.Id, EffectiveDate= Date.Today(), Status ='Install Complete', Pricebook2Id = Test.getStandardPricebookId());
        insert order;
        
        Test.setCurrentPage(Page.RMS_createServiceRequestRedirect);
        ApexPages.currentPage().getParameters().put('aid',aid.id);
        ApexPages.currentPage().getParameters().put('slid',slid.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        Integer num_orders = TE.getnumorders();
        Integer num_assets = TE.getnumassets();
        String propPickValSelected = TE.getpropPickValSelected();        
        
        Pagereference pr = TE.saveOrder();        
        Order ord = [select AccountId from Order where id =: order.id];
        
        System.Assertequals(ord.AccountId, aid.Id);
        System.assertEquals(2, num_orders);
        System.assertEquals(1, num_assets);  
        
        Test.stopTest();       
    }
    
    
    static testmethod void saveAssetTest2(){
        createTestRecords();
        
        Account acct = [Select Id FROM Account WHERE Name = '11111, Dwelling Account 2'];
        Contact cont = [Select Id FROM Contact Where LastName = '2'];
        Account store1 = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        
        Test.startTest();
        
        Test.setCurrentPage(Page.RMS_createAssetRedirect);
        ApexPages.currentPage().getParameters().put('aid',acct.id);
        ApexPages.currentPage().getParameters().put('slid',store1.id);
        
        Asset asset2 = new Asset (     Name='Asset2',                             
                                  AccountId = acct.id,
                                  ContactId = cont.id,                                  
                                  Store_Location__c = store1.id,                                  
                                  Status = 'Installed',                                 
                                  PurchaseDate = Date.Today()
                                 );
        
        
        insert asset2;
        
        ApexPages.StandardController sc2 = new ApexPages.StandardController(asset2);
        RMS_createServiceRequestAssetManager TE2 = new RMS_createServiceRequestAssetManager(sc2);
        Pagereference pr2 = TE2.saveAsset();        
        
        Test.stopTest();
    }
    
    static testmethod void saveContinuetest(){
        createTestRecords();
        
        Test.startTest();        
        Account aid = [Select Id,Name FROM Account WHERE Name = '11111, Dwelling Account'];
        Account slid = [Select Id, Name FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, AccountId FROM Asset WHERE AccountId =:aid.id];        
        
        Test.setCurrentPage(Page.RMS_createServiceRequestAsset);
        ApexPages.StandardController sc = new ApexPages.StandardController(asset);
        RMS_createServiceRequestAssetManager TE = new RMS_createServiceRequestAssetManager(sc); 
        
        asset.AccountId = aid.Id;
        Pagereference pr = TE.saveContinueAsset();        
        
        
        Test.stopTest();        
    }
    
    static testmethod void saveContinuetestFail(){
        createTestRecords();
        
        Test.startTest();        
        Account aid = [Select Id,Name FROM Account WHERE Name = '11111, Dwelling Account'];
        Account slid = [Select Id, Name FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, AccountId FROM Asset WHERE AccountId =:aid.id];        
        
        Test.setCurrentPage(Page.RMS_createServiceRequestAsset);
        ApexPages.StandardController sc = new ApexPages.StandardController(asset);
        RMS_createServiceRequestAssetManager TE = new RMS_createServiceRequestAssetManager(sc); 
        
        asset.AccountId = null;
        Pagereference pr = TE.saveContinueAsset();        
        
        
        Test.stopTest();        
    }
    
    static testmethod void customDeleteTest(){
        
        createTestRecords();
        Test.startTest();
        Asset asset = [SELECT Id,AccountId FROM Asset WHERE Name = 'Asset1'];        
        
        Test.setCurrentPage(Page.RMS_createServiceRequestAsset);
        ApexPages.StandardController sc = new ApexPages.StandardController(asset);
        RMS_createServiceRequestAssetManager TE = new RMS_createServiceRequestAssetManager(sc);
        Pagereference pr = TE.customDelete();                    
        Asset delAsst = [select id,isdeleted from Asset where id =: asset.id All rows];
        System.Assertequals(delAsst.isdeleted, true);
        
        Test.stopTest();         
        
    }
    
}
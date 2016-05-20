/*******************************************************//**

@class  testRMS_viewServiceOrderProductsCtlr

@brief  Test Class for RMS_viewServiceOrderProductsCtlr

@author  Brianne Wilson (Slalom.CDK)

@version    2015-3-15  Slalom.CDK
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
@isTest 
public with sharing class testRMS_viewServiceOrderProductsCtlr {
    
    static testmethod void createTestRecords() {
		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;

        TestUtilityMethods utility = new TestUtilityMethods();
        utility.setUpConfigs();
        
        
        Account dwelling1 = utility.createDwellingAccount('Dwelling Account');        
        Account store1 = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
        Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
        dwelling1.Store_Location__c = store1.Id;        
        insert dwelling1;      
        
        Contact contact1 = new contact ( FirstName='Contact',LastName='1',AccountId=dwelling1.id,Primary_Contact__c = true, Primary_Dwelling_for_Contact__c = true);
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
        
        Id pricebookId = Test.getStandardPricebookId();
        system.debug(pricebookId);
        
        List<Product2> products = new List<Product2>{masterProduct,servProduct};
            insert products;
        PricebookEntry pricebookEntryMaster= utility.createPricebookEntry(pricebookId, masterProduct.id);     
        PricebookEntry pricebookEntryServ = utility.createPricebookEntry(pricebookId, servProduct.id);    
        List<PriceBookEntry> pbEntries = new List<PricebookEntry>{pricebookEntryMaster,pricebookEntryServ};
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
    

    
    static testmethod void testWrapper(){
        createTestRecords();
        
        Order order = [SELECT Id,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Service Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Product2 prod = [SELECT id FROM Product2 WHERE Id = :pbe.Product2Id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];
        Asset asset = [Select Id FROM Asset WHERE Variant_Number__c = '1234ABC'];

        Test.startTest();
        Test.setCurrentPage(Page.RMS_viewServiceOrderProducts);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_viewServiceOrderProductsCtlr.OrderItemWrapper TE = new RMS_viewServiceOrderProductsCtlr.OrderItemWrapper(oi);
        Test.stopTest();

        
        
    }

 static testmethod void testController() {
    createTestRecords();
         
    Order order = [SELECT Id,AccountId,pricebook2id,RecordTypeId,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Service Order 1']; 
     Test.startTest();
     RMS_viewServiceOrderProductsCtlr controller = new RMS_viewServiceOrderProductsCtlr(new ApexPages.StandardController(order));
    System.assert(controller.OrderItemWrappers.size() == 1);
    OrderItem orderItemServ = [Select Id from OrderItem where Pricebookentry.Product2.Name = 'service'];
    system.assertEquals(controller.OrderItemWrappers[0].OrderItem.Id,orderItemServ.Id);
     Test.stopTest();
  }
    

    
    
}
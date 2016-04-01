/*******************************************************//**

@class  RMS_serviceRequestTests

@brief  Test Class for all Service Request pages

@author  Brianne Wilson (Slalom.CDK)

@version    2015-3-15  Slalom.CDK
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
@isTest
public with sharing class RMS_serviceRequestTests {
    
    static testMethod void setupData() {
        TestUtilityMethods utility = new TestUtilityMethods();
        utility.setUpConfigs();
        
        
        Account dwelling1 = utility.createDwellingAccount('Dwelling Account');
        Account store1 = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
        Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
        dwelling1.Store_Location__c = store1.Id;
        insert dwelling1;
        
        Contact contact1 = new contact ( FirstName='Contact',
                                        LastName='1',
                                        AccountId=dwelling1.id
                                       );
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
        
        Product2 masterProduct = new Product2(  name = 'master',
                                              IsActive = true, 
                                              recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Master_Product')
                                             );
        Product2 servProduct = new Product2(    name = 'service',
                                            IsActive = true, 
                                            recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Service_Product')
                                           );
        Product2 servProduct2 = new Product2(   name = 'service2',
                                             IsActive = true, 
                                             recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Service_Product')
                                            );
        
        
        List<Product2> products = new List<Product2>{masterProduct,servProduct,servProduct2};
            insert products;
        PricebookEntry pricebookEntryMaster= utility.createPricebookEntry(Test.getStandardPricebookId(), masterProduct.id);     
        PricebookEntry pricebookEntryServ = utility.createPricebookEntry(Test.getStandardPricebookId(), servProduct.id);    
        PricebookEntry pricebookEntryServ2 = utility.createPricebookEntry(Test.getStandardPricebookId(), servProduct2.id);      
        List<PriceBookEntry> pbEntries = new List<PricebookEntry>{pricebookEntryMaster,pricebookEntryServ,pricebookEntryServ2};
            insert pbEntries;
        //utility.createOrderTestRecords();
        Order order =  new Order(   Name='Sold Order 1', 
                                 AccountId = dwelling1.id, 
                                 BilltoContactId = contact1.id,
                                 EffectiveDate= Date.Today(), 
                                 Store_Location__c = store1.Id,                           
                                 Status ='Draft', 
                                 Pricebook2Id = Test.getStandardPricebookId()
                                );
        insert order;
        
        
        OrderItem orderItemMaster = new OrderItem(OrderId = Order.id, PricebookentryId = pricebookEntryMaster.Id, Quantity = 2, UnitPrice = 100 );
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
                             Pricebook2Id = Test.getStandardPricebookId()
                            );
        upsert o;
        
        list<Order> serviceOrder = [SELECT Id, AccountId, Sold_Order__c, Store_Location__c FROM Order WHERE AccountId = :dwelling1.id AND Sold_Order__c = :order.id AND Store_Location__c = :store1.id];
        System.assertEquals(serviceOrder.size() , 1);
        System.assertEquals(serviceOrder[0].AccountId, dwelling1.id);
        System.assertEquals(serviceOrder[0].Sold_Order__c, order.id);
        System.assertEquals(serviceOrder[0].Store_Location__c, store1.id);
        
        
        OrderItem oi = new OrderItem(OrderId = o.id, PricebookentryId = pricebookEntryServ.Id, Quantity = 2, UnitPrice = 100, Parent_Order_Item__c = orderItemMaster.id, Installed_Product_Asset__c = asset.id, Charge_Cost_To__c = 'Customer - Replace');    
        insert oi;
        
        list<OrderItem> listOI = [SELECT Id, Charge_Cost_To__c,OrderId FROM OrderItem WHERE OrderId = :o.id];
        for(OrderItem oit : listOI){      
        System.assertEquals(listOI.size() , 1);
        System.assertEquals(listOI[0].OrderId, o.id);
        System.assertEquals(listOI[0].Charge_Cost_To__c, 'Customer - Replace');
        }

    }
   
    
    
}
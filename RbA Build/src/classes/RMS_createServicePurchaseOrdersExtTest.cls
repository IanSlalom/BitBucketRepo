/*******************************************************//**

@class  RMS_createServicePurchaseOrdersExtTest

@brief  Test Class for RMS_createServicePurchaseOrdersExtension

@author  Creston Kuenzi (Slalom.CDK)

@version    2016-9-16  Slalom.CDK
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
@isTest 
public with sharing class RMS_createServicePurchaseOrdersExtTest {
    
    private static Order ord;
    
	@testSetup static void setupData(){
		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;

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
        Contact contact1 = new contact ( FirstName='Contact',LastName='1',AccountId=dwelling1.id);
        contactsToInsert.add(contact1);
        insert contactsToInsert;
        
        Financial_Account_Number__c finacialAccountNumber1 = new Financial_Account_Number__c (  Store_Configuration__c = storeConfig1.id, Name = '1');
        Financial_Account_Number__c finacialAccountNumber2 = new Financial_Account_Number__c (  Store_Configuration__c = storeConfig1.id, Name = '2');
        
		insert new List<Financial_Account_Number__c>{finacialAccountNumber1,finacialAccountNumber2};
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
        
        Order order2 =  new Order(   Name='Service Order', 
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

      	Purchase_Order__c po1 = new Purchase_Order__c(	Order__c = order2.Id, 
      								RecordTypeId = UtilityMethods.retrieveRecordTypeId( 'Service_Purchase_Order','Purchase_Order__c'),
									Store_Location__c = store1.Id);
		insert po1;

        List<OrderItem> orderItemsToInsert = new  List<OrderItem> ();
        OrderItem rwo = new OrderItem();
        rwo.OrderId = Order.id;
        rwo.PricebookentryId = pricebookEntryServ.Id;
        rwo.Quantity = 1;
        rwo.UnitPrice = 100;
        orderItemsToInsert.add(rwo);

        OrderItem rwo2 = new OrderItem();
        rwo2.OrderId = Order.id;
        rwo2.PricebookentryId = pricebookEntryServ.Id;
        rwo2.Quantity = 1;
        rwo2.UnitPrice = 100;
        rwo2.Purchase_Order__c = po1.Id;
        orderItemsToInsert.add(rwo2);
        insert orderItemsToInsert;
        
        Charge__c charge = new Charge__c(Service_Request__c = order2.Id, Charge_Cost_To__c = 'Retailer', Category__c = 'Goodwill', What_Where__c='Customer Satisfaction', Service_Product__c=rwo.Id);

        Charge__c charge2 = new Charge__c(Service_Request__c = order2.Id, Charge_Cost_To__c = 'Manufacturing', Category__c = 'DGW (M)', What_Where__c = 'Renewal by Andersen', Service_Product__c=rwo2.Id);
        
        insert new List<Charge__c>{charge,charge2};
                      
        
    }
    
    @isTest static void ExtensionContructorTest()
    {
        
        Test.startTest();
        ord = [SELECT Id FROM Order WHERE Name = 'Service Order'];

        ApexPages.StandardController std = new ApexPages.StandardController(ord);
        RMS_createServicePurchaseOrdersExtension ext = new RMS_createServicePurchaseOrdersExtension(std);
        
        Test.stopTest();
        
    }
    
    @isTest static void SaveTest()
    {
                
        Test.startTest();
        ord = [SELECT Id, Store_Location__c FROM Order WHERE Name = 'Service Order'];

        ApexPages.StandardController std = new ApexPages.StandardController(ord);
        RMS_createServicePurchaseOrdersExtension ext = new RMS_createServicePurchaseOrdersExtension(std);
 
 		// Save none selected
        ext.Save();

		ext.chargesWrapperList[0].isSelected = true;

 		// Save one selected
        ext.Save();
        
		ext.Cancel();
        Test.stopTest();    
    }

}
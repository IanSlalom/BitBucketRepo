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
        Account dwelling4 = utility.createDwellingAccount('Dwelling Account 4');
        Account store1 = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];        
        Store_Configuration__c storeConfig1 = [SELECT id FROM Store_Configuration__c WHERE Store__c = :store1.id ];
        storeConfig1.Sales_Tax__c = 5;
        update storeConfig1;
        dwelling1.Store_Location__c = store1.Id;
        dwelling2.Store_Location__c = store1.Id; 
        dwelling3.Store_Location__c = store1.Id;
        dwelling4.Store_Location__c = store1.Id;
        dwellingsToInsert.add(dwelling1);
        dwellingsToInsert.add(dwelling2);
        dwellingsToInsert.add(dwelling3);  
        dwellingsToInsert.add(dwelling4);  
        insert dwellingsToInsert;        
        
        List<Contact> contactsToInsert = new List<Contact>();       
        Contact contact1 = new contact ( FirstName='Contact',LastName='1',AccountId=dwelling1.id, Primary_Contact__c =true, Primary_Dwelling_for_Contact__c=true );
        contactsToInsert.add(contact1);
        Contact contact2 = new contact ( FirstName='Contact',LastName='2',AccountId=dwelling2.id, Primary_Contact__c =true, Primary_Dwelling_for_Contact__c=true );
        contactsToInsert.add(contact2);
        Contact contact3 = new contact ( FirstName='Contact',LastName='3',AccountId=dwelling3.id, Primary_Contact__c =true, Primary_Dwelling_for_Contact__c=true );
        contactsToInsert.add(contact3);
        Contact contact4 = new contact ( FirstName='Contact',LastName='4',AccountId=dwelling4.id, Primary_Contact__c =true, Primary_Dwelling_for_Contact__c=true );
        contactsToInsert.add(contact4);
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
        Product2 servProduct = new Product2( name = 'service',IsActive = true, recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Service_Product'));
        Product2 servProduct2 = new Product2(name = 'service2',IsActive = true, recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Service_Product'));
        
        Id pricebookId = Test.getStandardPricebookId();
        system.debug(pricebookId);
        
        Pricebook2 pricebook1 =  utility.createPricebook2Name('Standard Price Book');
        insert pricebook1;
        
        List<Product2> products = new List<Product2>{masterProduct,servProduct,servProduct2};
            insert products;
        
        PricebookEntry pricebookEntryMaster= utility.createPricebookEntry(pricebookId, masterProduct.id);     
        PricebookEntry pricebookEntryServ = utility.createPricebookEntry(pricebookId, servProduct.id);    
        PricebookEntry pricebookEntryServ2 = utility.createPricebookEntry(pricebookId, servProduct2.id);      
        
        List<PriceBookEntry> pbEntries = new List<PricebookEntry>{pricebookEntryMaster,pricebookEntryServ,pricebookEntryServ2};
            insert pbEntries;
        //utility.createOrderTestRecords();
        
        List<Service_Product__c> serviceProductsToInsert = new List<Service_Product__c>();
        Service_Product__c servProd1 = new Service_Product__c(name = 'service', Record_Name_Unique__c ='service',Service_Product__c = servProduct.Id, Master_Product__c = masterProduct.Id);
        serviceProductsToInsert.add(servProd1);
        Service_Product__c servProd2 = new Service_Product__c(name = 'service2', Record_Name_Unique__c ='service2',Service_Product__c = servProduct2.Id, Master_Product__c = masterProduct.Id);
        serviceProductsToInsert.add(servProd2);
        insert serviceProductsToInsert;
        
        System.assertEquals(serviceProductsToInsert.size() , 2);            
        
        List<Problem_Component_List__c> probCsToInsert = new List<Problem_Component_List__c>();
        Problem_Component_List__c probC1 = new Problem_Component_List__c(name='Prob1');
        probCsToInsert.add(probC1);
        Problem_Component_List__c probC2 = new Problem_Component_List__c(name='Prob2');
        probCsToInsert.add(probC2);
        Problem_Component_List__c probC3 = new Problem_Component_List__c(name='Prob3');
        probCsToInsert.add(probC3);      
        insert probCsToInsert;
        System.assertEquals(probCsToInsert.size() , 3); 
        
        
        List<Service_Symptom_List__c> ssToInsert = new List<Service_Symptom_List__c>();
        Service_Symptom_List__c ssl1 = new Service_Symptom_List__c(name='SS1');
        ssToInsert.add(ssl1);
        Service_Symptom_List__c ssl2 = new Service_Symptom_List__c(name='SS2');
        ssToInsert.add(ssl2);
        Service_Symptom_List__c ssl3 = new Service_Symptom_List__c(name='SS3');
        ssToInsert.add(ssl3);        
        insert ssToInsert;
        System.assertEquals(ssToInsert.size() , 3);             
        
        List<Procedure_Code__c> pcToInsert = new List<Procedure_Code__c>();
        Procedure_Code__c procC1 = new Procedure_Code__c(name='Proc1',Description__c='Description',Time_Minutes_Each__c=15);
        pcToInsert.add(procC1);
        Procedure_Code__c procC2 = new Procedure_Code__c(name='Proc2',Description__c='Description',Time_Minutes_Each__c=15);
        pcToInsert.add(procC2);
        Procedure_Code__c procC3 = new Procedure_Code__c(name='Proc3',Description__c='Description',Time_Minutes_Each__c=15);
        pcToInsert.add(procC3);        
        insert pcToInsert;
        System.assertEquals(pcToInsert.size() , 3); 
        
        
        List<Procedure_Code_Assignment__c> pcaToInsert = new List<Procedure_Code_Assignment__c>();        
        Procedure_Code_Assignment__c pca1 = new Procedure_Code_Assignment__c(Service_Product__c=servProduct.Id, Procedure_Code__c = procC1.Id);
        pcaToInsert.add(pca1);
        Procedure_Code_Assignment__c pca2 = new Procedure_Code_Assignment__c(Service_Product__c=servProduct.Id, Procedure_Code__c = procC2.Id);
        pcaToInsert.add(pca2);
        Procedure_Code_Assignment__c pca3 = new Procedure_Code_Assignment__c(Service_Product__c=servProduct.Id, Procedure_Code__c = procC3.Id);
        pcaToInsert.add(pca3);
        Procedure_Code_Assignment__c pca4 = new Procedure_Code_Assignment__c(Service_Product__c=servProduct2.Id, Procedure_Code__c = procC1.Id); 
        pcaToInsert.add(pca4);
        Procedure_Code_Assignment__c pca5 = new Procedure_Code_Assignment__c(Service_Product__c=servProduct2.Id, Procedure_Code__c = procC2.Id);        
        pcaToInsert.add(pca5);
        Procedure_Code_Assignment__c pca6 = new Procedure_Code_Assignment__c(Service_Product__c=servProduct2.Id, Procedure_Code__c = procC3.Id);
        pcaToInsert.add(pca6);        
        insert pcaToInsert;
        System.assertEquals(pcaToInsert.size() , 6); 
        
        List<Service_Symptom_Assignment__c> ssaToInsert = new List<Service_Symptom_Assignment__c>();
        Service_Symptom_Assignment__c ssa1 = new Service_Symptom_Assignment__c(Name='Test',Procedure_Code__c=procC1.Id,Service_Symptom__c=ssl1.Id);
        ssaToInsert.add(ssa1);
        Service_Symptom_Assignment__c ssa2 = new Service_Symptom_Assignment__c(Name='Test',Procedure_Code__c=procC2.Id,Service_Symptom__c=ssl1.Id);
        ssaToInsert.add(ssa2);
        Service_Symptom_Assignment__c ssa3 = new Service_Symptom_Assignment__c(Name='Test',Procedure_Code__c=procC3.Id,Service_Symptom__c=ssl1.Id);
        ssaToInsert.add(ssa3);
        Service_Symptom_Assignment__c ssa4 = new Service_Symptom_Assignment__c(Name='Test',Procedure_Code__c=procC1.Id,Service_Symptom__c=ssl2.Id);
        ssaToInsert.add(ssa4);
        Service_Symptom_Assignment__c ssa5 = new Service_Symptom_Assignment__c(Name='Test',Procedure_Code__c=procC2.Id,Service_Symptom__c=ssl2.Id);
        ssaToInsert.add(ssa5);
        Service_Symptom_Assignment__c ssa6 = new Service_Symptom_Assignment__c(Name='Test',Procedure_Code__c=procC3.Id,Service_Symptom__c=ssl2.Id);
        ssaToInsert.add(ssa6);
        Service_Symptom_Assignment__c ssa7 = new Service_Symptom_Assignment__c(Name='Test',Procedure_Code__c=procC1.Id,Service_Symptom__c=ssl3.Id);
        ssaToInsert.add(ssa7);
        Service_Symptom_Assignment__c ssa8 = new Service_Symptom_Assignment__c(Name='Test',Procedure_Code__c=procC2.Id,Service_Symptom__c=ssl3.Id);
        ssaToInsert.add(ssa8);
        Service_Symptom_Assignment__c ssa9 = new Service_Symptom_Assignment__c(Name='Test',Procedure_Code__c=procC3.Id,Service_Symptom__c=ssl3.Id);
        ssaToInsert.add(ssa9);
        
        insert ssaToInsert;
        System.assertEquals(ssaToInsert.size() , 9); 
        
        List<Problem_Component_Config__c> pccToInsert = new List<Problem_Component_Config__c>();
        Problem_Component_Config__c pcc1 = new Problem_Component_Config__c(Name='Test',Problem_Component__c=probC1.Id,Service_Symptom__c=ssl1.Id);
        pccToInsert.add(pcc1);
        Problem_Component_Config__c pcc2 = new Problem_Component_Config__c(Name='Test',Problem_Component__c=probC2.Id,Service_Symptom__c=ssl1.Id);
        pccToInsert.add(pcc2);
        Problem_Component_Config__c pcc3 = new Problem_Component_Config__c(Name='Test',Problem_Component__c=probC3.Id,Service_Symptom__c=ssl1.Id);
        pccToInsert.add(pcc3);
        Problem_Component_Config__c pcc4 = new Problem_Component_Config__c(Name='Test',Problem_Component__c=probC1.Id,Service_Symptom__c=ssl2.Id);
        pccToInsert.add(pcc4);
        Problem_Component_Config__c pcc5 = new Problem_Component_Config__c(Name='Test',Problem_Component__c=probC2.Id,Service_Symptom__c=ssl2.Id);
        pccToInsert.add(pcc5);
        Problem_Component_Config__c pcc6 = new Problem_Component_Config__c(Name='Test',Problem_Component__c=probC3.Id,Service_Symptom__c=ssl2.Id);
        pccToInsert.add(pcc6);
        Problem_Component_Config__c pcc7 = new Problem_Component_Config__c(Name='Test',Problem_Component__c=probC1.Id,Service_Symptom__c=ssl3.Id);
        pccToInsert.add(pcc7);
        Problem_Component_Config__c pcc8 = new Problem_Component_Config__c(Name='Test',Problem_Component__c=probC2.Id,Service_Symptom__c=ssl3.Id);
        pccToInsert.add(pcc8);
        Problem_Component_Config__c pcc9 = new Problem_Component_Config__c(Name='Test',Problem_Component__c=probC3.Id,Service_Symptom__c=ssl3.Id);
        pccToInsert.add(pcc9);        
        insert pccToInsert;
        System.assertEquals(pccToInsert.size() , 9); 
        
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
        
        
        Order order2 =  new Order(   Name='Sold Order 2', 
                                  AccountId = dwelling2.id, 
                                  BilltoContactId = contact2.id,
                                  EffectiveDate= Date.Today(), 
                                  Store_Location__c = store1.Id,                           
                                  Status ='Install Complete',
                                  Customer_Pickup_All__c = FALSE,
                                  Pricebook2Id = Test.getStandardPricebookId(),
                                  Installation_Date__c = system.today()-60);                                  
        ordersToInsert.add(order2);
        
        Order order3 =  new Order(   Name='Sold Order 3', 
                                  AccountId = dwelling1.id, 
                                  BilltoContactId = contact1.id,
                                  EffectiveDate= Date.Today(), 
                                  Store_Location__c = store1.Id,                           
                                  Status ='Install Complete', 
                                  Pricebook2Id = Test.getStandardPricebookId(),
                                  Customer_Pickup_All__c = FALSE,
                                  Installation_Date__c = system.today()-1 
                                 );
        ordersToInsert.add(order3);
        
        Order o =  new Order(     Name='Service Order 1', 
                             AccountId = dwelling1.id, 
                             EffectiveDate= Date.Today(), 
                             Store_Location__c = store1.Id,                               
                             Status ='New', 
                             Sold_Order__c = order.Id,
                             Customer_Pickup_All__c = FALSE,
                             BilltoContactId = contact1.id,
                             Service_Type__c = 'Job in Progress',                                             
                             Pricebook2Id = Test.getStandardPricebookId(),
                             recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order')
                            );
        ordersToInsert.add(o);       
        
        Order so =  new Order(     Name='Service Order 2', 
                              AccountId = dwelling1.id, 
                              EffectiveDate= Date.Today(), 
                              Store_Location__c = store1.Id,                               
                              Status ='New', 
                              Sold_Order__c = order.Id,
                              Customer_Pickup_All__c = FALSE,
                              BilltoContactId = contact1.id,
                              Service_Type__c = 'Job in Progress',                                             
                              Pricebook2Id = Test.getStandardPricebookId(),
                              recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order')
                             );
        ordersToInsert.add(so);
        insert ordersToInsert;
        
        System.assertEquals(ordersToInsert.size() , 5); 
        
        
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
        
        Asset asset3 = new Asset (     Name='Asset2',                                  
                                  Product2Id= masterProduct.Id,
                                  AccountId = dwelling4.id,
                                  ContactId = contact4.id,
                                  Variant_Number__c = '1234ABCD',
                                  Unit_Wholesale_Cost__c = 200,
                                  Store_Location__c = store1.id,
                                  Quantity = 1,
                                  Price = 100,
                                  Status = 'Installed',                                  
                                  PurchaseDate = Date.Today()
                                 );
        
        assetsToInsert.add(asset3); 		
        
        insert assetsToInsert;  
        System.assertEquals(assetsToInsert.size() , 3);                                 
        
        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        OrderItem serviceOrderItem = new OrderItem(Installed_Product_Asset__c = asset.Id,OrderId = o.id, Quote_Accepted__c = FALSE, Parent_Order_Item__c = orderItemMaster.id, PricebookentryId = pricebookEntryServ.Id, Quanity_Ordered__c = 2, Service__c = true, Quantity = 2, UnitPrice = 100);
        orderItemsToInsert.add(serviceOrderItem);
        System.assertEquals(orderItemsToInsert.size() , 1); 
        
        List<Charge__c> chargesToInsert = new List<Charge__c>();
        Charge__c charge = new Charge__c(Charge_Cost_To__c = 'Retailer', Category__c = 'Goodwill', What_Where__c='Customer Satisfaction', Service_Product__c=serviceOrderItem.Id, Service_Request__c = so.Id, Validate_Service_Order__c=TRUE);
        chargesToInsert.add(charge);       
        Charge__c charge2 = new Charge__c(Charge_Cost_To__c = 'Manufacturing', Category__c = 'DGW (M)', What_Where__c = 'Renewal by Andersen', Service_Product__c=serviceOrderItem.Id, Service_Request__c = so.Id, Validate_Service_Order__c=TRUE);
        chargesToInsert.add(charge2);
        insert chargesToInsert;
        System.assertEquals(chargesToInsert.size() , 2); 
        
        Warranty__C warranty = new Warranty__C(Charge_Cost_To__c=charge2.Id,Procedure_Code__c=pca1.Id,Quantity__c=2, Service_Product__c=serviceOrderItem.Id);
        insert warranty;
        
    }
    
    //createServiceRequestRedirectMethods
    
    
    static testmethod void saveOrderTest(){
        createTestRecords();
        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
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
        System.assertEquals(3, num_orders);
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
                                  Status ='Install Complete',
                                  Pricebook2Id = Test.getStandardPricebookId(),
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
                                  Status ='New',
                                  Pricebook2Id = Test.getStandardPricebookId(),
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
    
    static testmethod void saveOrderTest4(){
        createTestRecords();
        
        Account acct3 = [Select Id FROM Account WHERE Name = 'Dwelling Account 4'];
        Account store1 = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        
        Test.startTest();
        Test.setCurrentPage(Page.RMS_createServiceRequestRedirect);
        ApexPages.currentPage().getParameters().put('aid',acct3.id);
        ApexPages.currentPage().getParameters().put('slid',store1.id);
        
        Order order3 =  new Order(   Name='Sold Order 3', 
                                  AccountId = acct3.id, 
                                  EffectiveDate= Date.Today(), 
                                  Store_Location__c = store1.Id,                           
                                  Status ='New',
                                  Pricebook2Id = Test.getStandardPricebookId(),
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
    
    static testmethod void saveOrderTest5(){
        createTestRecords();
        
        Account acct3 = [Select Id FROM Account WHERE Name = 'Dwelling Account 4'];
        Account store1 = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        
        Test.startTest();
        Test.setCurrentPage(Page.RMS_createServiceRequestRedirect);
        ApexPages.currentPage().getParameters().put('aid',acct3.id);
        ApexPages.currentPage().getParameters().put('slid',store1.id);
        
        Order order3 =  new Order(   Name='Sold Order 3', 
                                  //AccountId = acct3.id, 
                                  //EffectiveDate= Date.Today(), 
                                  Store_Location__c = store1.Id,                           
                                  //Status ='New',
                                  Pricebook2Id = Test.getStandardPricebookId(),
                                  recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order')
                                 );
        
        
        ApexPages.StandardController sc3 = new ApexPages.StandardController(order3);
        RMS_ServiceOrderExtensionMgr TE3 = new RMS_ServiceOrderExtensionMgr(sc3);
        Pagereference pr3 = TE3.saveOrder();        
        try {
            insert order3;
        } catch (DmlException saveEx) {
            //Assert Error Message
            system.assertEquals(true, ApexPages.hasMessages());
            
        } //catch
        
        Test.stopTest();
        
    } 
    
    
    
    //createServiceRequestP1 Methods
    
    static testmethod void customDeleteTest(){
        
        createTestRecords();
        Test.startTest();
        Order order = [SELECT Id,Service_Type__c,AccountId FROM Order WHERE Name = 'Service Order 1'];        
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        Pagereference pr = TE.customDelete();                    
        Order delOrd = [select id,isdeleted from Order where id =: order.id All rows];
        System.Assertequals(delOrd.isdeleted, true);
        
        Test.stopTest();         
        
    }
    
    static testmethod void testOptionList(){
        createTestRecords();
        
        Order order = [SELECT Id,Service_Type__c,AccountId,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Service Order 1']; 
        
        Test.startTest();
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        list<SelectOption> testoptions = TE.getOrds();
        
        system.assertEquals(3,testoptions.size());
        
        Test.stopTest();
        
    }
    
    //with Bill to Contact
    static testmethod void saveP2test(){
        createTestRecords();
        
        Test.startTest(); 
        Order soldOrder = [Select Id, BilltoContactId FROm Order WHERE Name = 'Sold Order 1'];
        //Order order = [SELECT Id,Service_Type__c,Sales_Tax_Percent__c,AccountId,pricebook2id,BilltoContactId,Name FROM Order WHERE Name = 'Service Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id,Sales_Tax__c FROM Account WHERE Name = '77 - Twin Cities, MN'];
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Contact contact = [Select Id FROM Contact WHERE id =:soldOrder.BilltoContactId];
        
        Order order =  new Order(   Name='Service Order 3', 
                                 AccountId = aid.id, 
                                 EffectiveDate= Date.Today(), 
                                 Store_Location__c = slid.Id,                           
                                 Status ='New',
                                 Pricebook2Id = Test.getStandardPricebookId(),
                                 recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order')
                                );
        insert order;
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        order.Sold_Order__c = soldOrder.Id;        
        Pagereference pr = TE.saveP2();        
        
        Order ord = [select id,Name,BilltoContactId from Order where id =: order.id];
        
        System.Assertequals(ord.Name, 'Service Order 3');
        System.Assertequals(ord.BilltoContactId, contact.id);
        
        Test.stopTest();        
    }
    
    static testmethod void saveP2test2(){
        createTestRecords();
        
        Test.startTest(); 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Order order = [SELECT Id,Service_Type__c,Sales_Tax_Percent__c,AccountId,pricebook2id,BilltoContactId,Name FROM Order WHERE Name = 'Service Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id,Sales_Tax__c FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Contact contact = [Select Id FROM Contact WHERE id =:order.BilltoContactId];
        
        Order o = New Order (Sold_Order__c = order.Id, 
                             Service_Type__c = 'Service',
                             AccountId = aid.id, 
                             EffectiveDate= Date.Today(), 
                             Store_Location__c = slid.Id,                           
                             Status ='New',
                             Pricebook2Id = Test.getStandardPricebookId(),
                             BilltoContactId = contact.Id,
                             recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order'));
        
        insert o;
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        Pagereference pr = TE.saveP2();        
        Order ord = [select id,Name,BilltoContactId from Order where id =: o.id];        
        System.Assertequals(ord.BilltoContactId, contact.id);
        Test.stopTest();        
    }  
    
    static testmethod void saveP2test3(){
        createTestRecords();
        
        Test.startTest(); 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Order order = [SELECT Id,Service_Type__c,Sales_Tax_Percent__c,AccountId,pricebook2id,BilltoContactId,Name FROM Order WHERE Name = 'Service Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id,Sales_Tax__c FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Contact contact = [Select Id FROM Contact WHERE id =:order.BilltoContactId];
        
        Order o = New Order (Sold_Order__c = order.Id, 
                             Service_Type__c = 'Service',
                             AccountId = aid.id, 
                             EffectiveDate= Date.Today(), 
                             Store_Location__c = slid.Id,                           
                             Status ='New',
                             Pricebook2Id = Test.getStandardPricebookId(),
                             BilltoContactId = contact.Id,
                             recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order'));
        
        insert o;
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(o);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);     
        o.Service_Type__c = 'Save';
        o.Save_Reason__c = null;
        Pagereference pr = TE.saveP2();        
        
        try {            
            upsert o;
        } catch (DmlException saveEx) {
            //Assert Error Message
            system.assertEquals(true, ApexPages.hasMessages());
            
        } //catch
        Test.stopTest();        
    }
    
    
    
    //RMS_createServiceRequestP2 Methods
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
    
    static testmethod void saveClosetest(){
        createTestRecords();
        
        Test.startTest();
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Order order = [SELECT Id,Validate_Service_Order__c,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP2);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);  
        String propPickValSelected = TE.getpropPickValSelected();               
        Boolean isSelected = true;
        Boolean manufacturer = true;
        Boolean local = true;
        Boolean customer = true;
        
        Pagereference pr = TE.saveClose();        
        
        Order ord = [select id,Name from Order where id =: order.id];
        System.Assertequals(ord.Name, 'Sold Order 1');
        
        Test.stopTest();
    }
    
    static testmethod void saveCloseTestFail(){
        createTestRecords();
        
        Test.startTest();
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Order order = [SELECT Id,Validate_Service_Order__c,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP2);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);  
        String propPickValSelected = TE.getpropPickValSelected();               
        Boolean isSelected = true;
        Boolean manufacturer = true;
        Boolean local = true;
        Boolean customer = true;
        order.Service_Type__c = 'Save';
        order.AccountId = null;
        Pagereference pr = TE.saveClose();        
        
        try {            
            upsert order;
        } catch (DmlException saveEx) {
            //Assert Error Message
            system.assertEquals(true, ApexPages.hasMessages());
            
        } //catch  
        
        Test.stopTest();
    }
    
    static testmethod void saveContinuetest(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,Validate_Service_Order__c,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP2);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc); 
        String propPickValSelected = TE.getpropPickValSelected();               
        Boolean isSelected = true;
        Boolean manufacturer = true;
        Boolean local = true;
        Boolean customer = true;
        Integer invalidRequest = 0;
        
        Pagereference pr = TE.saveContinue();        
        
        Order ord = [select id,Name,Validate_Service_Order__c from Order where id =: order.id];
        
        System.Assertequals(ord.Name, 'Sold Order 1');
        System.Assertequals(ord.Validate_Service_Order__c, true);
        //System.Assertequals(0,invalidRequest);
        
        Test.stopTest();        
    }
    
    static testmethod void saveContinueTestFail(){
        createTestRecords();
        
        Test.startTest();
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Order order = [SELECT Id,Validate_Service_Order__c,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP2);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);  
        String propPickValSelected = TE.getpropPickValSelected();               
        Boolean isSelected = true;
        Boolean manufacturer = true;
        Boolean local = true;
        Boolean customer = true;
        order.Service_Type__c = 'Save';
        order.AccountId = null;
        Pagereference pr = TE.saveContinue();        
        
        try {            
            upsert order;
        } catch (DmlException saveEx) {
            //Assert Error Message
            system.assertEquals(true, ApexPages.hasMessages());
            
        } //catch  
        
        Test.stopTest();
    }
    
    static testmethod void saveContinueInvalidTest(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Service Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        //OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP2);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);  
        Boolean isSelected = false;
        Boolean manufacturer = true;
        Boolean local = true;
        Boolean customer = true;
        Integer invalidRequest = 1;
        
        Pagereference pr = TE.saveContinue();        
        
        //System.Assertequals(1,invalidRequest);
        
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
        
        
        Test.setCurrentPage(Page.RMS_addServiceProduct);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        String propPickValSelected = TE.getpropPickValSelected();        
        
        Pagereference pr = TE.saveNewProducts();        
        Order ord = [select id,Name,Validate_Service_Order__c from Order where id =: order.id];
        
        System.Assertequals(ord.Name, 'Sold Order 1');
        System.Assertequals(ord.Validate_Service_Order__c, true);
        
        Test.stopTest();       
    }
    
    static testmethod void saveNewProductsFail(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,Validate_Service_Order__c,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        
        
        Test.setCurrentPage(Page.RMS_addServiceProduct);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        String propPickValSelected = TE.getpropPickValSelected();        
        order.Service_Type__c = 'Save';
        order.AccountId = null;
        Pagereference pr = TE.saveNewProducts();        
        
        try {            
            upsert order;
        } catch (DmlException saveEx) {
            //Assert Error Message
            system.assertEquals(true, ApexPages.hasMessages());
            
        } //catch  
        
        Test.stopTest();       
    }    
    
    static testmethod void saveContinueNewProducts(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,Validate_Service_Order__c,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        
        
        Test.setCurrentPage(Page.RMS_addServiceProduct);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        String propPickValSelected = TE.getpropPickValSelected();        
        
        Pagereference pr = TE.saveNewProductsContinue();        
        Order ord = [select id,Name,Validate_Service_Order__c from Order where id =: order.id];
        
        System.Assertequals(ord.Name, 'Sold Order 1');
        System.Assertequals(ord.Validate_Service_Order__c, true);
        
        Test.stopTest();       
    }
    
    static testmethod void saveNewProductsContinueFail(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,Validate_Service_Order__c,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        
        
        Test.setCurrentPage(Page.RMS_addServiceProduct);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        String propPickValSelected = TE.getpropPickValSelected();        
        order.Service_Type__c = 'Save';
        order.AccountId = null;
        Pagereference pr = TE.saveNewProductsContinue();        
        
        try {            
            upsert order;
        } catch (DmlException saveEx) {
            //Assert Error Message
            system.assertEquals(true, ApexPages.hasMessages());
            
        } //catch  
        
        Test.stopTest();       
    }      
    
    //RMS_addServiceProductLegacy Methods
    
    static testmethod void saveNewProductsLegacy(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,Validate_Service_Order__c,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        
        
        Test.setCurrentPage(Page.RMS_addServiceProductLegacy);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        String propPickValSelected = TE.getpropPickValSelected();        
        
        Pagereference pr = TE.saveNewProductsLegacy();        
        Order ord = [select id,Name,Validate_Service_Order__c from Order where id =: order.id];
        
        System.Assertequals(ord.Name, 'Sold Order 1');
        System.Assertequals(ord.Validate_Service_Order__c, true);
        
        Test.stopTest();       
    }
    
    static testmethod void saveNewProductsLegacyFail(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,Validate_Service_Order__c,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        
        
        Test.setCurrentPage(Page.RMS_addServiceProductLegacy);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        String propPickValSelected = TE.getpropPickValSelected();        
        
        order.Service_Type__c = 'Save';
        order.Save_Reason__c = null;
        order.AccountId = null;
        
        Pagereference pr = TE.saveNewProductsLegacy();        
        try {            
            upsert order;
        } catch (DmlException saveEx) {
            //Assert Error Message
            system.assertEquals(true, ApexPages.hasMessages());
            
        } //catch  
        
        Test.stopTest();       
    }
    
    static testmethod void saveNewProductsLegacyContinue(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,Validate_Service_Order__c,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        
        
        Test.setCurrentPage(Page.RMS_addServiceProductLegacy);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        String propPickValSelected = TE.getpropPickValSelected();        
        
        Pagereference pr = TE.saveNewProductsLegacyContinue();        
        Order ord = [select id,Name,Validate_Service_Order__c from Order where id =: order.id];
        
        System.Assertequals(ord.Name, 'Sold Order 1');
        System.Assertequals(ord.Validate_Service_Order__c, true);
        
        Test.stopTest();       
    }
    
    static testmethod void saveNewProductsLegacyContinueFail(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,Validate_Service_Order__c,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        
        
        Test.setCurrentPage(Page.RMS_addServiceProductLegacy);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        String propPickValSelected = TE.getpropPickValSelected();        
        
        order.Service_Type__c = 'Save';
        order.Save_Reason__c = null;
        order.AccountId = null;
        
        Pagereference pr = TE.saveNewProductsLegacyContinue();        
        try {            
            upsert order;
        } catch (DmlException saveEx) {
            //Assert Error Message
            system.assertEquals(true, ApexPages.hasMessages());
            
        } //catch  
        
        Test.stopTest();       
    }
    
    //RMS_createServiceRequestP3 Methods
    
    static testmethod void saveChargesTest(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        Charge__c charge = new Charge__c(Charge_Cost_To__c = 'Retailer', Category__c = 'Goodwill', What_Where__c='Customer Satisfaction', Service_Product__c=oi.Id);
        insert charge;
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP3);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);         
        Pagereference pr = TE.saveCharges();        
        
        Charge__c ch = [SELECT Charge_Cost_To__c FROM Charge__c WHERE id =: charge.Id];
        
        System.Assertequals(ch.Charge_Cost_To__c,'Retailer');
        Test.stopTest();       
        
        
    }
    
    static testmethod void saveChargesTestFail(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];
        OrderItem oi = [Select Id, UnitPrice, OrderId, PriceBookEntryId, Installed_Product_Asset__c, Quanity_Ordered__c, Quantity, Service__c, Parent_Order_Item__c, Charge_Cost_To__c FROM OrderItem WHERE OrderId =:order.Id];        
        Charge__c charge = new Charge__c(Charge_Cost_To__c = 'Retailer', Category__c = 'Goodwill', What_Where__c='Customer Satisfaction', Service_Product__c=oi.Id);
        insert charge;
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP3);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);         
        charge.Category__c = null;
        charge.What_Where__c = null;
        Pagereference pr = TE.saveCharges();        
        try {            
            upsert charge;
        } catch (DmlException saveEx) {
            //Assert Error Message
            system.assertEquals(true, ApexPages.hasMessages());
            
        } //catch  
        Test.stopTest();       
        
        
    }
    
    static testmethod void cancelP3Test(){
        createTestRecords();
        
        Test.startTest();
        Order order = [SELECT Id,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Service Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Asset asset = [Select Id, Sold_Order__c,Original_Order_Product__c FROM Asset WHERE AccountId =:aid.id];        
        Charge__c charge = [Select Id, Service_Request__c,Charge_Cost_To__c, Category__c, What_Where__c, Service_Product__c FROM Charge__c WHERE Charge_Cost_To__c = 'Manufacturing'];
        
        Test.setCurrentPage(Page.RMS_createServiceRequestP3);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);         
        Pagereference pr = TE.cancelP3();    
        Test.stopTest();                   
        
    }
    
    
    //RMS_UpdateServiceType Methods
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
    
    static testmethod void cancelServiceTypeUpdateTest(){
        createTestRecords();
        
        Order order = [SELECT Id,Service_Type__c,AccountId,pricebook2id,Name FROM Order WHERE Name = 'Sold Order 1'];        
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        
        Test.startTest();
        
        Test.setCurrentPage(Page.RMS_updateServiceType);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        String propPickValSelected2 = TE.getpropPickValSelected2();        
        
        Pagereference pr = TE.cancelUpdate();        
        Order ord = [select id,Name from Order where id =: order.id];
        
        System.Assertequals(ord.Name, 'Sold Order 1');
        
        Test.stopTest();       
    }
    
    //RMS_ServiceRequestLegacy1
    static testmethod void customDeleteTest2(){
        createTestRecords();
        
        Test.startTest(); 
        Order order = [SELECT Id,AccountId,Service_Type__c FROM Order WHERE Name = 'Sold Order 1'];                
        
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        Pagereference pr = TE.customDelete();        
        Order delOrd = [select id,isdeleted from Order where id =: order.id All rows];
        System.Assertequals(delOrd.isdeleted, true);
        Test.stopTest();  
        
    }
    
    static testmethod void testOptionList2(){
        createTestRecords();
        
        Test.startTest(); 
        Order order = [SELECT Id,AccountId,Service_Type__c,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        list<SelectOption> testoptions = TE.getPickLstValueLegacy();
        
        system.assertEquals(2,testoptions.size());
        Test.stopTest();  
    }
    
    static testmethod void testDependentPicklist2(){
        createTestRecords();
        
        Test.startTest(); 
        Order order = [SELECT Id,AccountId,Service_Type__c,pricebook2id,Name,OrderNumber,Activated_Date__c,Status FROM Order WHERE Name = 'Sold Order 1']; 
        PricebookEntry pbe = [Select Id, Product2Id FROM pricebookentry WHERE name = 'Service'];
        Service_Product__c prod = [SELECT id,Service_Product__c FROM Service_Product__c WHERE Service_Product__c     = :pbe.Product2Id];
        Boolean isSelected = true;
        Asset asset = [Select Id FROM Asset WHERE Variant_Number__c = '1234ABC'];
        
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr.ProductWrapper2 TE = new RMS_ServiceOrderExtensionMgr.ProductWrapper2(prod);
        
        Test.stopTest();          
        
    }
    
    static testmethod void saveCloseLegacytest(){
        createTestRecords();
        
        Test.startTest();
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account 3'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Id pricebookId = Test.getStandardPricebookId();
        Order order = new Order(Name='Service Order 2', 
                                AccountId = aid.id, 
                                EffectiveDate= Date.Today(), 
                                Store_Location__c = slid.Id,                               
                                Status ='New',                             
                                Customer_Pickup_All__c = FALSE,                             
                                Service_Type__c = 'Job in Progress',                                             
                                Pricebook2Id = Test.getStandardPricebookId(),
                                recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order'));
        insert order;        
        
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        Boolean hasValidationErrors = false;
        String propPickValSelectedLegacy = TE.getpropPickValSelectedLegacy();
        Boolean isSelected = true;
        Boolean manufacturer = true;
        Boolean local = true;
        Boolean customer = true;
        Integer invalidRequest = 0;
        Pagereference pr = TE.saveCloseLegacy();        
        Order ord = [select id,Name from Order where id =: order.id];
        System.Assertequals(ord.Name, 'Service Order 2');
        Test.stopTest();
    }
    
    static testmethod void saveCloseLegacytestFail(){
        createTestRecords();
        
        Test.startTest();
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account 3'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Id pricebookId = Test.getStandardPricebookId();
        Order order = new Order(Name='Service Order 2', 
                                AccountId = aid.id, 
                                EffectiveDate= Date.Today(), 
                                Store_Location__c = slid.Id,                               
                                Status ='New',                             
                                Customer_Pickup_All__c = FALSE,                             
                                Service_Type__c = 'Job in Progress',                                             
                                Pricebook2Id = Test.getStandardPricebookId(),
                                recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order'));
        insert order;        
        
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        Boolean hasValidationErrors = false;
        String propPickValSelectedLegacy = TE.getpropPickValSelectedLegacy();
        Boolean isSelected = true;
        Boolean manufacturer = true;
        Boolean local = true;
        Boolean customer = true;
        Integer invalidRequest = 0;
        order.Service_Type__c = 'Save';
        order.Save_Reason__c = null;
        Pagereference pr = TE.saveCloseLegacy();  
        try {            
            upsert order;
        } catch (DmlException saveEx) {
            //Assert Error Message
            system.assertEquals(true, ApexPages.hasMessages());
            
        } //catch  
        
        Test.stopTest();
    }
    
    
    static testmethod void saveContinueLegacytest(){
        createTestRecords();
        
        Test.startTest();
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account 3'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Id pricebookId = Test.getStandardPricebookId();
        Order order = new Order(Name='Service Order 2', 
                                AccountId = aid.id, 
                                EffectiveDate= Date.Today(), 
                                Store_Location__c = slid.Id,                               
                                Status ='New',                             
                                Customer_Pickup_All__c = FALSE,                             
                                Service_Type__c = 'Job in Progress',                                             
                                Pricebook2Id = Test.getStandardPricebookId(),
                                recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order'));
        insert order; 
        
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        Boolean hasValidationErrors = false;
        String propPickValSelectedLegacy = TE.getpropPickValSelectedLegacy();
        Boolean isSelected = true;
        Boolean manufacturer = true;
        Boolean local = true;
        Boolean customer = true;
        Integer invalidRequest = 0;
        Pagereference pr = TE.saveContinueLegacy();        
        Order ord = [select id,Name from Order where id =: order.id];
        System.Assertequals(ord.Name, 'Service Order 2');
        Test.stopTest();
    }    
    
    static testmethod void saveContinueLegacytestFail(){
        createTestRecords();
        
        Test.startTest();
        Account aid = [Select Id FROM Account WHERE Name = 'Dwelling Account 3'];
        Account slid = [Select Id FROM Account WHERE Name = '77 - Twin Cities, MN'];
        Id pricebookId = Test.getStandardPricebookId();
        Order order = new Order(Name='Service Order 2', 
                                AccountId = aid.id, 
                                EffectiveDate= Date.Today(), 
                                Store_Location__c = slid.Id,                               
                                Status ='New',                             
                                Customer_Pickup_All__c = FALSE,                             
                                Service_Type__c = 'Job in Progress',                                             
                                Pricebook2Id = Test.getStandardPricebookId(),
                                recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order'));
        insert order;        
        
        Test.setCurrentPage(Page.RMS_serviceRequestLegacyP1);
        ApexPages.StandardController sc = new ApexPages.StandardController(order);
        RMS_ServiceOrderExtensionMgr TE = new RMS_ServiceOrderExtensionMgr(sc);
        Boolean hasValidationErrors = false;
        String propPickValSelectedLegacy = TE.getpropPickValSelectedLegacy();
        Boolean isSelected = true;
        Boolean manufacturer = true;
        Boolean local = true;
        Boolean customer = true;
        Integer invalidRequest = 0;
        order.Service_Type__c = 'Save';
        order.Save_Reason__c = null;
        Pagereference pr = TE.saveContinueLegacy();  
        try {            
            upsert order;
        } catch (DmlException saveEx) {
            //Assert Error Message
            system.assertEquals(true, ApexPages.hasMessages());
            
        } //catch  
        
        Test.stopTest();
    }
    
    
    //RMS_serviceRequestListView Methods        
    private testMethod static void testSuccess() {
        Test.startTest();       
        RMS_serviceRequestListViewMgr con = new RMS_serviceRequestListViewMgr();
        String propPickValSelected = con.getpropPickValSelected(); 
        con.listName = 'Service Requests - All';
        con.propPickValSelected = 'Service Requests - All';
        for(SelectOption listView : con.getPickLstValue()){
            listView.getValue();
        } 
        System.assert(con.listId != null);
        Test.stopTest();       
    }
    
    private testMethod static void testFailure() {
        Test.startTest();       
        RMS_serviceRequestListViewMgr con = new RMS_serviceRequestListViewMgr();
        con.listName = 'BADLISTNAME';
        System.assert(con.listId == null);
        Test.stopTest();
        
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
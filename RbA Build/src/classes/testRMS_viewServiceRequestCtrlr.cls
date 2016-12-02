@isTest 
public with sharing class testRMS_viewServiceRequestCtrlr {
    
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
        Contact contact1 = new contact ( FirstName='Contact',LastName='1',AccountId=dwelling1.id);
        contactsToInsert.add(contact1);
        Contact contact2 = new contact ( FirstName='Contact',LastName='2',AccountId=dwelling2.id);
        contactsToInsert.add(contact2);
        Contact contact3 = new contact ( FirstName='Contact',LastName='3',AccountId=dwelling3.id);
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
        Service_Product__c servProd1 = new Service_Product__c(Record_Name_Unique__c ='service',Service_Product__c = servProduct.Id, Master_Product__c = masterProduct.Id);
        serviceProductsToInsert.add(servProd1);
        Service_Product__c servProd2 = new Service_Product__c(Record_Name_Unique__c ='service2',Service_Product__c = servProduct2.Id, Master_Product__c = masterProduct.Id);
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
        Procedure_Code__c procC1 = new Procedure_Code__c(name='Pr1',Description__c='Description',Time_Minutes_Each__c=15);
        pcToInsert.add(procC1);
        Procedure_Code__c procC2 = new Procedure_Code__c(name='Pr2',Description__c='Description',Time_Minutes_Each__c=15);
        pcToInsert.add(procC2);
        Procedure_Code__c procC3 = new Procedure_Code__c(name='Pr3',Description__c='Description',Time_Minutes_Each__c=15);
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
                                 recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Record_Type', 'Order'),                                 
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
                                  recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Record_Type', 'Order'),                                  
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
                                  Installation_Date__c = system.today()-1,
                                  recordTypeId=UtilityMethods.retrieveRecordTypeId('CORO_Record_Type', 'Order')
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
                              Status ='Warranty Submitted', 
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
        insert assetsToInsert;  
        System.assertEquals(assetsToInsert.size() , 2);                                 
        
        List<OrderItem> orderItemsToInsert = new List<OrderItem>();
        OrderItem serviceOrderItem = new OrderItem(Installed_Product_Asset__c = asset.Id,OrderId = o.id, Quote_Accepted__c = FALSE, Parent_Order_Item__c = orderItemMaster.id, PricebookentryId = pricebookEntryServ.Id, Quanity_Ordered__c = 2, Service__c = true, Quantity = 2, UnitPrice = 100);
        orderItemsToInsert.add(serviceOrderItem);
        System.assertEquals(orderItemsToInsert.size() , 1);
        
        Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
        Id lswpRecordTypeId = UtilityMethods.retrieveRecordTypeId('LSWP', 'RbA_Work_Order__c');
        
        List<RbA_Work_Order__c> wosToInsert = new List<RbA_Work_Order__c>();
        RbA_Work_Order__c wo1 = new RbA_Work_Order__c(RecordTypeId = serviceOrderVisitRecordTypeId, Work_Order_Type__c = 'Tech Measure', Sold_Order__c = o.Id, Account__c = dwelling1.Id, Work_Order_Status__c = 'Scheduled & Assigned', Appointment_Duration__c = 1);
        wosToInsert.add(wo1);
        RbA_Work_Order__c wo2 = new RbA_Work_Order__c(RecordTypeId = lswpRecordTypeId, Work_Order_Type__c = 'LSWP', Sold_Order__c = o.Id, Account__c = dwelling1.Id, Work_Order_Status__c = 'New', Appointment_Duration__c = 1);
        wosToInsert.add(wo2);
        insert wosToInsert;
        System.assertEquals(wosToInsert.size(), 2);
    }
    
    static testmethod void updateServiceTypeTest(){
        createTestRecords();
        Test.startTest();
        
        Order prod = [SELECT Id, Name,RecordType.Name, RecordTypeId FROM Order WHERE Name = 'Service Order 1'];
        
        Test.setCurrentPage(Page.RMS_viewServiceRequest);
        ApexPages.StandardController sc = new ApexPages.StandardController(prod);
        RMS_viewServiceRequestCtrlr TE = new RMS_viewServiceRequestCtrlr(sc);
        Pagereference pr = TE.updateServiceType();
        
        Test.stopTest();              
    }  
    
    static testmethod void editServiceRequestTest(){
        createTestRecords();
        Test.startTest();
        
        Order prod = [SELECT Id, Name FROM Order WHERE Name = 'Service Order 1'];
        
        Test.setCurrentPage(Page.RMS_viewServiceRequest);
        ApexPages.StandardController sc = new ApexPages.StandardController(prod);
        RMS_viewServiceRequestCtrlr TE = new RMS_viewServiceRequestCtrlr(sc);
        Pagereference pr = TE.editServiceRequest();
        
        Test.stopTest();              
    } 
    
    static testmethod void serviceOrderRedirectTest(){
        createTestRecords();
        Test.startTest();
        
        Order prod = [SELECT Id, RecordType.Name, RecordTypeId, Lock_Service_Request__c, Status, Name FROM Order WHERE Name = 'Service Order 1'];
        
        Test.setCurrentPage(Page.RMS_viewOrderRedirect);
        ApexPages.StandardController sc = new ApexPages.StandardController(prod);
        RMS_viewServiceRequestCtrlr TE = new RMS_viewServiceRequestCtrlr(sc);
        Pagereference pr = TE.orderRedirect();
        
        Test.stopTest();              
    }  
    
    static testmethod void lockServiceOrderRedirectTest(){
        createTestRecords();
        Test.startTest();
        
        Order prod = [SELECT Id, RecordType.Name, RecordTypeId, Lock_Service_Request__c, Status, Name FROM Order WHERE Name = 'Service Order 2'];
        
        Test.setCurrentPage(Page.RMS_viewOrderRedirect);
        ApexPages.StandardController sc = new ApexPages.StandardController(prod);
        RMS_viewServiceRequestCtrlr TE = new RMS_viewServiceRequestCtrlr(sc);
        Pagereference pr = TE.orderRedirect();
        
        Test.stopTest();              
    }  
    
    static testmethod void viewOrderRedirectTest(){
        createTestRecords();
        Test.startTest();
        
        Order prod = [SELECT Id, RecordType.Name, RecordTypeId, Lock_Service_Request__c, Status, Name FROM Order WHERE Name = 'Sold Order 2'];
        
        Test.setCurrentPage(Page.RMS_viewOrderRedirect);
        ApexPages.StandardController sc = new ApexPages.StandardController(prod);
        RMS_viewServiceRequestCtrlr TE = new RMS_viewServiceRequestCtrlr(sc);
        Pagereference pr = TE.orderRedirect();
        
        Test.stopTest();              
    } 
    
    static testmethod void cancelOrderTest(){
        createTestRecords();
        Test.startTest();
        
        Order prod = [SELECT Id, Name, Status FROM Order WHERE Name = 'Service Order 1'];
        
        Test.setCurrentPage(Page.RMS_viewServiceRequest);
        ApexPages.StandardController sc = new ApexPages.StandardController(prod);
        RMS_viewServiceRequestCtrlr TE = new RMS_viewServiceRequestCtrlr(sc);
        Pagereference pr = TE.cancelOrder();
        
        Test.stopTest();              
    } 

    static testmethod void getWOs(){
        createTestRecords();
        Test.startTest();
        
        Order prod = [SELECT Id, Name, Status FROM Order WHERE Name = 'Service Order 1'];
        
        Test.setCurrentPage(Page.RMS_viewServiceRequest);
        ApexPages.StandardController sc = new ApexPages.StandardController(prod);
        RMS_viewServiceRequestCtrlr TE = new RMS_viewServiceRequestCtrlr(sc);
        TE.getVisitWOs();
        TE.getactionWOs();
        
        Test.stopTest();              
    }       
    
}
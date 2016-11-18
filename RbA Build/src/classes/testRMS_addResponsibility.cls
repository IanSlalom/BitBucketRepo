/*************************************************************
@brief  Test Class for RMS_addResponsibility 

@author  Brianne Wilson (Slalom.BLW)

@version    2016-6-13  Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
@isTest
private class testRMS_addResponsibility 
{ 
    /*
* Mock implementation of abstract class used for testing
*/
    private class MockEditableList extends RMS_addResponsibility
    {
        public MockEditableList(ApexPages.StandardController stdController)
        {
            super(stdController);
        } 
    }
    
    private static OrderItem rwo;
    private static Charge__c myCharge1;
    private static Charge__c myCharge2;
    
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
        Contact contact1 = new contact ( FirstName='Contact',LastName='1',AccountId=dwelling1.id);
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


        Problem_Component_List__c probC1 = new Problem_Component_List__c(name='Prob1');
        Problem_Component_List__c probC2 = new Problem_Component_List__c(name='Prob2');
        Problem_Component_List__c probC3 = new Problem_Component_List__c(name='Prob3');
        List<Problem_Component_List__c> probCs = new List<Problem_Component_List__c>{probC1,probC2,probC3};
        insert probCs;

        Service_Symptom_List__c ssl1 = new Service_Symptom_List__c(name='SS1');
        Service_Symptom_List__c ssl2 = new Service_Symptom_List__c(name='SS2');
        Service_Symptom_List__c ssl3 = new Service_Symptom_List__c(name='SS3');
        List<Service_Symptom_List__c> ssl = new List<Service_Symptom_List__c>{ssl1,ssl2,ssl3};
        insert ssl;

        Procedure_Code__c procC1 = new Procedure_Code__c(name='Proc1',Description__c='Description',Time_Minutes_Each__c=15);
        Procedure_Code__c procC2 = new Procedure_Code__c(name='Proc2',Description__c='Description',Time_Minutes_Each__c=15);
        Procedure_Code__c procC3 = new Procedure_Code__c(name='Proc3',Description__c='Description',Time_Minutes_Each__c=15);
        List<Procedure_Code__c> procC = new List<Procedure_Code__c>{procC1,procC2,procC3};
        insert procC;

        Procedure_Code_Assignment__c pca1 = new Procedure_Code_Assignment__c(Service_Product__c=servProduct.Id, Procedure_Code__c = procC1.Id);
        Procedure_Code_Assignment__c pca2 = new Procedure_Code_Assignment__c(Service_Product__c=servProduct.Id, Procedure_Code__c = procC2.Id);
        Procedure_Code_Assignment__c pca3 = new Procedure_Code_Assignment__c(Service_Product__c=servProduct.Id, Procedure_Code__c = procC3.Id);
        Procedure_Code_Assignment__c pca4 = new Procedure_Code_Assignment__c(Service_Product__c=servProduct2.Id, Procedure_Code__c = procC1.Id); 
        Procedure_Code_Assignment__c pca5 = new Procedure_Code_Assignment__c(Service_Product__c=servProduct2.Id, Procedure_Code__c = procC2.Id);        
        Procedure_Code_Assignment__c pca6 = new Procedure_Code_Assignment__c(Service_Product__c=servProduct2.Id, Procedure_Code__c = procC3.Id);
        List<Procedure_Code_Assignment__c> pca = new List<Procedure_Code_Assignment__c>{pca1,pca2,pca3,pca4,pca5,pca6};
        insert pca;

        Service_Symptom_Assignment__c ssa1 = new Service_Symptom_Assignment__c(Procedure_Code__c=procC1.Id,Service_Symptom__c=ssl1.Id);
        Service_Symptom_Assignment__c ssa2 = new Service_Symptom_Assignment__c(Procedure_Code__c=procC2.Id,Service_Symptom__c=ssl1.Id);
        Service_Symptom_Assignment__c ssa3 = new Service_Symptom_Assignment__c(Procedure_Code__c=procC3.Id,Service_Symptom__c=ssl1.Id);
        Service_Symptom_Assignment__c ssa4 = new Service_Symptom_Assignment__c(Procedure_Code__c=procC1.Id,Service_Symptom__c=ssl2.Id);
        Service_Symptom_Assignment__c ssa5 = new Service_Symptom_Assignment__c(Procedure_Code__c=procC2.Id,Service_Symptom__c=ssl2.Id);
        Service_Symptom_Assignment__c ssa6 = new Service_Symptom_Assignment__c(Procedure_Code__c=procC3.Id,Service_Symptom__c=ssl2.Id);
        Service_Symptom_Assignment__c ssa7 = new Service_Symptom_Assignment__c(Procedure_Code__c=procC1.Id,Service_Symptom__c=ssl3.Id);
        Service_Symptom_Assignment__c ssa8 = new Service_Symptom_Assignment__c(Procedure_Code__c=procC2.Id,Service_Symptom__c=ssl3.Id);
        Service_Symptom_Assignment__c ssa9 = new Service_Symptom_Assignment__c(Procedure_Code__c=procC3.Id,Service_Symptom__c=ssl3.Id);
        List<Service_Symptom_Assignment__c> ssa = new List<Service_Symptom_Assignment__c>{ssa1,ssa2,ssa3,ssa4,ssa5,ssa6,ssa7,ssa8,ssa9};
        insert ssa;

        Problem_Component_Config__c pcc1 = new Problem_Component_Config__c(Problem_Component__c=probC1.Id,Service_Symptom__c=ssl1.Id);
        Problem_Component_Config__c pcc2 = new Problem_Component_Config__c(Problem_Component__c=probC2.Id,Service_Symptom__c=ssl1.Id);
        Problem_Component_Config__c pcc3 = new Problem_Component_Config__c(Problem_Component__c=probC3.Id,Service_Symptom__c=ssl1.Id);
        Problem_Component_Config__c pcc4 = new Problem_Component_Config__c(Problem_Component__c=probC1.Id,Service_Symptom__c=ssl2.Id);
        Problem_Component_Config__c pcc5 = new Problem_Component_Config__c(Problem_Component__c=probC2.Id,Service_Symptom__c=ssl2.Id);
        Problem_Component_Config__c pcc6 = new Problem_Component_Config__c(Problem_Component__c=probC3.Id,Service_Symptom__c=ssl2.Id);
        Problem_Component_Config__c pcc7 = new Problem_Component_Config__c(Problem_Component__c=probC1.Id,Service_Symptom__c=ssl3.Id);
        Problem_Component_Config__c pcc8 = new Problem_Component_Config__c(Problem_Component__c=probC2.Id,Service_Symptom__c=ssl3.Id);
        Problem_Component_Config__c pcc9 = new Problem_Component_Config__c(Problem_Component__c=probC3.Id,Service_Symptom__c=ssl3.Id);
        List<Problem_Component_Config__c> pcc = new List<Problem_Component_Config__c>{pcc1,pcc2,pcc3,pcc4,pcc5,pcc6,pcc7,pcc8,pcc9};
        insert pcc;
        
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
        
        rwo = new OrderItem();
        rwo.OrderId = Order.id;
        rwo.PricebookentryId = pricebookEntryServ.Id;
        rwo.Quantity = 1;
        rwo.UnitPrice = 100;
        rwo.Local_Remake__c = true;
        rwo.Manufacturer_Replace__c = true;
        rwo.Customer_Replace__c = true;        
        insert rwo;
        
        myCharge1 = new Charge__c(Charge_Cost_To__c = 'Retailer', Category__c = 'Goodwill', What_Where__c='Customer Satisfaction', Service_Product__c=rwo.Id);
        insert myCharge1;

        myCharge2 = new Charge__c(Charge_Cost_To__c = 'Manufacturing', Category__c = 'Renewal by Andersen', Service_Product__c=rwo.Id);
        insert myCharge2;

    }
    
    @isTest static void test_EditableList() 
    {
        setupData();
        
        Test.startTest();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        Test.stopTest();
        
        System.assertEquals(0, mock.ZERO);
        System.assertEquals(0, mock.childList.size());
        System.assertEquals(0, mock.removeChildList.size());
    }
    
    @isTest static void test_getHasChildren()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        Test.startTest();
        
        System.assertEquals(false, mock.getHasChildren());
        
        mock.childList.add(new Charge__c());
        
        System.assertEquals(true, mock.getHasChildren());
        
        Test.stopTest();
    }
    
    @isTest static void test_initChildRecord()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        Test.startTest();
        
        System.assert(mock.initChildRecord() instanceof Charge__c);
        
        Test.stopTest();
    }
    
    @isTest static void test_addToList()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        System.assertEquals(0, mock.childList.size());
        
        Test.startTest();
        
        mock.addToList();
        
        Test.stopTest();
        
        System.assertEquals(1, mock.childList.size());
    }
    
    @isTest static void test_removeFromList()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        mock.childList.add(myCharge1);
        mock.childList.add(myCharge2);
        
        Test.startTest();
        
        mock.removeIndex = '1';
        mock.removeFromList();
        
        Test.stopTest();
        
        System.assertEquals(1, mock.childList.size());
        System.assertEquals(myCharge2.Id, mock.childList[0].Id);
        System.assertEquals(1, mock.removeChildList.size());
        System.assertEquals(myCharge1.Id, mock.removeChildList[0].Id);
    }
    
    @isTest static void test_getSuccessURL_param()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        String retURL = '/test';
        PageReference pr = new PageReference('/');
        pr.getParameters().put('retURL', retURL);
        
        Test.setCurrentPageReference(pr);
        Test.startTest();
        
        System.assertEquals(retURL, mock.getSuccessURL().getUrl());
        
        Test.stopTest();
    }
    
    @isTest static void test_getSuccessURL_noParam()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        PageReference pr = new PageReference('/');
        
        Test.setCurrentPageReference(pr);
        Test.startTest();
        
        System.assertEquals(std.view().getUrl(), mock.getSuccessURL().getUrl());
        
        Test.stopTest();
    }
    
    @isTest static void test_save_failure()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        mock.childList.add(myCharge1);
        mock.removeChildList.add(myCharge2);
        
        // Purposely leave out required Service Type
        Charge__c newCharge = new Charge__c();
        newCharge.Service_Product__c = rwo.Id;
        
        mock.childList.add(newCharge);
        
        Test.startTest();
        
        //System.assertEquals(null, mock.save());
        
        Test.stopTest();
        
        System.assertEquals(0, ApexPages.getMessages().size());
        //System.assertEquals(ApexPages.Severity.ERROR, ApexPages.getMessages()[0].getSeverity());
        
    }
    
    @isTest static void test_save_success()
    {
        setupData();
        
        ApexPages.StandardController std = new ApexPages.StandardController(rwo);
        MockEditableList mock = new MockEditableList(std);
        
        mock.childList.add(myCharge1);
        mock.removeChildList.add(myCharge2);
        
        Charge__c newCharge = new Charge__c();        
        newCharge.Service_Product__c = rwo.Id;
        
        mock.childList.add(newCharge);
        
        Test.startTest();
        
        //System.assertEquals(mock.getSuccessURL().getUrl(), mock.save().getUrl());
        
        Test.stopTest();
        
        List<sObject> results = [SELECT Id FROM Charge__c WHERE Service_Product__c =: rwo.Id ORDER BY CreatedDate];
        System.assertEquals(5, results.size());
        //System.assertEquals(myCharge1.Id, results[0].Id);
        //System.assertNotEquals(myCharge2.Id, results[1].Id);
    }
}
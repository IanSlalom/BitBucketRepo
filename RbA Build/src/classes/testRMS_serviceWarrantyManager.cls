@isTest 
public with sharing class testRMS_serviceWarrantyManager {
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
        
        List<Product2> products = new List<Product2>();
        Product2 masterProduct = new Product2( name = 'master',IsActive = true, recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Master_Product'));
        products.add(masterProduct);
        Product2 servProduct = new Product2( name = 'service',IsActive = true, recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Service_Product'));
        products.add(servProduct);
        Product2 servProduct2 = new Product2(name = 'service2',IsActive = true, recordTypeId=UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Service_Product'));
        products.add(servProduct2);
        Id pricebookId = Test.getStandardPricebookId();
        system.debug(pricebookId);
        
        
        insert products;
        
        System.assertEquals(products.size(), 3);
        
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
        
        List<Service_Field_Ids__c> customSettings = new List<Service_Field_Ids__c>();
        Service_Field_Ids__c spMP = new Service_Field_Ids__c(Name='Service Product - Master Product', Value__c = 'CF0000000000000');
        customSettings.add(spMP);
        Service_Field_Ids__c spSP = new Service_Field_Ids__c(Name='Service Product - Service Product', Value__c = 'CF0000000000000');
        customSettings.add(spSP);
        Service_Field_Ids__c pcSP = new Service_Field_Ids__c(Name='Procedure Code - Service Product', Value__c = 'CF0000000000000');
        customSettings.add(pcSP);
        insert customSettings;
        System.AssertEquals(customSettings.size(),3);
        
        
    }
    
    static testmethod void addServiceProductTest(){
        createTestRecords();
        Test.startTest();
        
        Product2 prod = [SELECT Id, Name FROM Product2 WHERE Name = 'service'];
        
        Test.setCurrentPage(Page.RMS_viewServiceProduct);
        ApexPages.StandardController sc = new ApexPages.StandardController(prod);
        RMS_serviceWarrantyManager TE = new RMS_serviceWarrantyManager(sc);
        Pagereference pr = TE.addServiceProduct();
        
        Test.stopTest();              
    }
    
    static testmethod void addMasterProductTest(){
        createTestRecords();
        Test.startTest();
        
        Product2 prod = [SELECT Id, Name FROM Product2 WHERE Name = 'master'];
        
        Test.setCurrentPage(Page.RMS_viewServiceProduct);
        ApexPages.StandardController sc = new ApexPages.StandardController(prod);
        RMS_serviceWarrantyManager TE = new RMS_serviceWarrantyManager(sc);
        Pagereference pr = TE.addMasterProduct();
        
        Test.stopTest();              
    }
    
    static testmethod void addProcedureCodeTest(){
        createTestRecords();
        Test.startTest();
        
        Product2 prod = [SELECT Id, Name FROM Product2 WHERE Name = 'service'];
        
        Test.setCurrentPage(Page.RMS_viewServiceProduct);
        ApexPages.StandardController sc = new ApexPages.StandardController(prod);
        RMS_serviceWarrantyManager TE = new RMS_serviceWarrantyManager(sc);
        Pagereference pr = TE.addProcedureCode();
        
        Test.stopTest();              
    }        
    
}
/*******************************************************//**
@brief test class for view pages in the data setup app:
RMS_viewPCLCtrlr
RMS_viewPCCtrlr
RMS_viewSSLCtrlr

@author  Brianne Wilson (Slalom.BLW)

@version    2016-6-2  Slalom.BLW
Created.

@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
@isTest 
public with sharing class testRMS_dataSetupClasses {
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
        
        List<Service_Field_Ids__c> customSettings = new List<Service_Field_Ids__c>();
        Service_Field_Ids__c ssSP = new Service_Field_Ids__c(Name='Problem Component - Problem Component', Value__c = 'CF0000000000000');
        customSettings.add(ssSP);
        Service_Field_Ids__c ssPC = new Service_Field_Ids__c(Name='Service Symptom - Procedure Code', Value__c = 'CF0000000000000');
        customSettings.add(ssPC);
        Service_Field_Ids__c pcSS = new Service_Field_Ids__c(Name='Problem Component - Service Symptom', Value__c = 'CF0000000000000');
        customSettings.add(pcSS);
        Service_Field_Ids__c pcPC = new Service_Field_Ids__c(Name='Procedure Code - Procedure Code', Value__c = 'CF0000000000000');
        customSettings.add(pcPC);
        insert customSettings;
        //        System.AssertEquals(customSettings.size(),3);
        
        
    }
    
    static testmethod void addServiceSymptomTest(){
        createTestRecords();
        Test.startTest();
        
        Problem_Component_List__c prod = [SELECT Id, Name FROM Problem_Component_List__c WHERE Name = 'Prob1'];
        
        Test.setCurrentPage(Page.RMS_viewProblemComponent);
        ApexPages.StandardController sc = new ApexPages.StandardController(prod);
        RMS_viewPCLCtrlr TE = new RMS_viewPCLCtrlr(sc);
        Pagereference pr = TE.addServiceSymptom();
        
        Test.stopTest();              
    }
    
    static testmethod void addProcedureCodeTest(){
        createTestRecords();
        Test.startTest();
        
        Service_Symptom_List__c prod = [SELECT Id, Name FROM Service_Symptom_List__c WHERE Name = 'SS1'];
        
        Test.setCurrentPage(Page.RMS_viewServiceSymptomList);
        ApexPages.StandardController sc = new ApexPages.StandardController(prod);
        RMS_viewSSLCtrlr TE = new RMS_viewSSLCtrlr(sc);
        Pagereference pr = TE.addProcedureCode();
        
        Test.stopTest();              
    }
    
    static testmethod void addProblemComponentsTest(){
        createTestRecords();
        Test.startTest();
        
        Service_Symptom_List__c prod = [SELECT Id, Name FROM Service_Symptom_List__c WHERE Name = 'SS1'];
        
        Test.setCurrentPage(Page.RMS_viewServiceSymptomList);
        ApexPages.StandardController sc = new ApexPages.StandardController(prod);
        RMS_viewSSLCtrlr TE = new RMS_viewSSLCtrlr(sc);
        Pagereference pr = TE.addProblemComponent();
        
        Test.stopTest();              
    }
    
    static testmethod void addServiceProductTest(){
        createTestRecords();
        Test.startTest();
        
        Procedure_Code__c prod = [SELECT Id, Name FROM Procedure_Code__c WHERE Name = 'Proc1'];
        
        Test.setCurrentPage(Page.RMS_viewProcedureCode);
        ApexPages.StandardController sc = new ApexPages.StandardController(prod);
        RMS_viewPCCtrlr TE = new RMS_viewPCCtrlr(sc);
        Pagereference pr = TE.addServiceProduct();
        
        Test.stopTest();              
    }
    
    static testmethod void addSerSymptomTest(){
        createTestRecords();
        Test.startTest();
        
        Procedure_Code__c prod = [SELECT Id, Name FROM Procedure_Code__c WHERE Name = 'Proc1'];
        
        Test.setCurrentPage(Page.RMS_viewProcedureCode);
        ApexPages.StandardController sc = new ApexPages.StandardController(prod);
        RMS_viewPCCtrlr TE = new RMS_viewPCCtrlr(sc);
        Pagereference pr = TE.addServiceSymptom();
        
        Test.stopTest();              
    }
    
}
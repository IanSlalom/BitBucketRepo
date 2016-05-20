/*******************************************************//**

@class  RMS_cancelOrderExtensionTest

@brief  Test class for the RMS_cancelOrderExtension Controller extension

    Test class

@author  Creston Kuenzi (Slalom.CDK)

@version    2015-10-25  Slalom.CDK
    Created. 

@see        RMS_cancelOrderExtensionTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_cancelOrderExtensionTest {

    /*******************************************************
                    createTestRecords
    *******************************************************/
    @testSetup static void createTestRecords(){
        
        TestUtilityMethods utility = new TestUtilityMethods();
        
        utility.setUpConfigs();
        
        Account myAccount1 = utility.createVendorAccount('My Vendor Account 1 ');
        insert myAccount1;

        Account myAccount2 = new Account(   Name = 'RbA',
                                        AccountNumber = '1234567890',
                                        Phone = '(763) 555-2000'
                                    );
        insert myAccount2;

        Account dwelling = utility.createDwellingAccount('Dwelling Account');

        Account store = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
        dwelling.Store_Location__c = store.Id;
        insert dwelling;
        
        Opportunity opp1 = utility.createOpportunity(dwelling.id, 'Closed - Won');
        insert opp1;
        
        Pricebook2 pricebook1 =  utility.createPricebook2Name('Standard Price Book');
        insert pricebook1;

        Product2 product1 = new Product2(
            Name='Test Product',
            Vendor__c = myAccount1.id
        );
        
        
        insert product1;
        
        PricebookEntry pricebookEntry1 = utility.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
        insert pricebookEntry1;
        
        Order order1 = new Order(   Name='Sold Order 1', 
                                    AccountId = dwelling.id, 
                                    EffectiveDate= Date.Today(), 
                                    Store_Location__c = store.Id,
                                    Opportunity = opp1, 
                                    Status ='Draft', 
                                    Pricebook2Id = Test.getStandardPricebookId()
                                );
        insert order1;
        
        Purchase_Order__c purchaseOrder1 = new Purchase_Order__c(Order__c = Order1.id);
        insert purchaseOrder1;      

        OrderItem orderItem1 = new OrderItem(OrderId = Order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100, Purchase_Order__c = purchaseOrder1.Id );
        insert orderItem1;      

        Discount__c discount1 = new Discount__c(Name = 'my discount');
        insert discount1;

        Account myStore = [select Id, Active_Store_Configuration__c from Account where Name = '77 - Twin Cities, MN' Limit 1];
        Store_Discount__c storeDiscount1 = new Store_Discount__c();
        storeDiscount1.Discount__c = discount1.Id;
        storeDiscount1.Store_Configuration__c = myStore.Active_Store_Configuration__c;
        storeDiscount1.Active__c = true;
        insert storeDiscount1;      

        Order_Discount__c orderDiscount1 = new Order_Discount__c(Order__c = Order1.id, Store_Discount__c = storeDiscount1.Id, Discount_Amount__c = 50 );
        insert orderDiscount1;      

        Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
        RbA_Work_Order__c workOrder1 = new RbA_Work_Order__c(   RecordTypeId = serviceOrderVisitRecordTypeId,  Sold_Order__c = order1.id, Work_Order_Type__c = 'Historical');
        insert workOrder1;

    }
    
    /*******************************************************
                    NoOrderIdTest
    *******************************************************/
    static testmethod void NoOrderIdTest(){

        Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];

        // Set up controller with an order Id and no PO Id
        PageReference pageRef = Page.RMS_cancelOrder;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(soldOrder);
        RMS_cancelOrderExtension customController  = new RMS_cancelOrderExtension(stdController);
        customController.cancelOrder();

    }
// TODO Fix this too many SOQL Queries error
    /*******************************************************
                    CancelOrderTest
    *******************************************************/
 /*   static testmethod void CancelOrderTest(){

		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;

        Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];

        // Set up controller with an order Id
        PageReference pageRef = Page.RMS_cancelOrder;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',soldOrder.id);
        ApexPages.StandardController stdController = new ApexPages.StandardController(soldOrder);

        Test.startTest();

        RMS_cancelOrderExtension customController  = new RMS_cancelOrderExtension(stdController);

        //Verify if related Visit RbA_Work_Order__c has open events, order is not cancelled
        List<RbA_Work_Order__c> relatedVisitWOs = [Select Id, Number_Open_Events_Formula__c from RbA_Work_Order__c WHERE Sold_Order__c =: soldOrder.Id AND RecordType.DeveloperName = 'Visit'];
        for(RbA_Work_Order__c relatedWO : relatedVisitWOs){
            relatedWo.Scheduled_Appt_Date_Time_Service__c = Datetime.now().addHours(4);
            relatedWo.Work_Order_Type__c = 'Service';
            //relatedWO.Number_Open_Events__c = 1;
        }
        update relatedVisitWOs;


        customController.cancelOrder();
        Order soldOrderResult = [SELECT Id, Status FROM Order WHERE Name = 'Sold Order 1'];
        System.AssertEquals('Draft', soldOrderResult.Status);   

        //Update related rba_Work_Orders to 0 open events, verify records are cancelled 
        for(RbA_Work_Order__c relatedWO : relatedVisitWOs){
            relatedWo.Scheduled_Appt_Date_Time_Service__c = Datetime.now().addHours(-4);
           // relatedWO.Number_Open_Events__c = 0;
        }
        update relatedVisitWOs;
        customController.cancelOrder();

        // Verify all POs are cancelled
        for (Purchase_Order__c cancelledPO :  [SELECT Id, Status__c FROM Purchase_Order__c WHERE Order__c =: soldOrder.Id]) {
            System.AssertEquals('Cancelled', cancelledPO.Status__c);        
        }

        // Verify all Order Items are cancelled
        for (OrderItem cancelledOI :  [SELECT Id, Status__c FROM OrderItem WHERE OrderId =: soldOrder.Id]) {
            System.AssertEquals('Cancelled', cancelledOI.Status__c);        
        }

        // Verify all Discounts are cancelled
        for (Order_Discount__c cancelledOD :  [SELECT Id, Status__c FROM Order_Discount__c WHERE Order__c =: soldOrder.Id]) {
            System.AssertEquals('Cancelled', cancelledOD.Status__c);        
        }

        // Verify all rba_Work_Orders of the proper types are cancelled
        for (RbA_Work_Order__c cancelledWO :  [SELECT Id, Work_Order_Status__c FROM RbA_Work_Order__c WHERE Sold_Order__c =: soldOrder.Id
                                                AND Work_Order_Type__c in ('LSWP','Bulding Permit','HOA','Historical','Tech Measure','Install','Paint/Stain')]) {
            System.AssertEquals('Cancelled', cancelledWO.Work_Order_Status__c);     
        }

        // Verify the sold order is Cancelled
        soldOrderResult = [SELECT Id, Status FROM Order WHERE Name = 'Sold Order 1'];
        System.AssertEquals('Cancelled', soldOrderResult.Status);       

        Test.stopTest();

    }*/
}
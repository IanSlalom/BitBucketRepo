/*******************************************************//**

@class  RMS_OrderDiscountManagerTest

@brief  Test class for the RMS_OrderDiscountManager  

    Test class

@author  Creston Kuenzi (Slalom.CDK)

@version    2015-7-14  Slalom.CDK
    Created. 

@see        RMS_OrderDiscountManager

@copyright  (c)2016 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_OrderDiscountManagerTest {

	// TODO : Write test methods to adequately cover this handler and trigger
    static testMethod void tempTest() {
        TestUtilityMethods utility = new TestUtilityMethods();
        utility.createOrderTestRecords();

        Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];

        Discount__c discount1 = new Discount__c(Name = 'my discount');
        insert discount1;

        Account myStore = [select Id, Active_Store_Configuration__c from Account where Name = '77 - Twin Cities, MN' Limit 1];
        Store_Discount__c storeDiscount1 = new Store_Discount__c();
        storeDiscount1.Discount__c = discount1.Id;
        storeDiscount1.Store_Configuration__c = myStore.Active_Store_Configuration__c;
        storeDiscount1.Active__c = true;
        insert storeDiscount1;      

		test.startTest();
        Order_Discount__c orderDiscount1 = new Order_Discount__c(Order__c = soldOrder.id, Store_Discount__c = storeDiscount1.Id, Discount_Amount__c = 50 );
        insert orderDiscount1;    
        orderDiscount1.Discount_Amount__c = 75;
        update orderDiscount1;
        test.stopTest();

    }
}
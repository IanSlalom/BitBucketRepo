@isTest
private class warrantyTriggerTest {

    static testMethod void warrantyTriggerTest() {
         TestUtilityMethods utility = new TestUtilityMethods();       
         utility.setUpConfigs();
        Charge__c cct = new Charge__c(Category__c = 'Renewal by Andersen');
        insert cct;
        Warranty__c newWarranty = new Warranty__c(Charge_Cost_To__c = cct.Id);
        insert newWarranty;    }
}
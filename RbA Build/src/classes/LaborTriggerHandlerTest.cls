/*******************************************************//**

@class	  LaborTriggerHandlerTest

@brief	 Test class for Handler for the labor trigger

@author	 Creston Kuenzi (Slalom.CDK)

@version	2016-6-23  Slalom.CDK
	Created

@see		LaborTriggerHandler

@copyright  (c)2016 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class LaborTriggerHandlerTest {

	// Tests the entire trigger by inserting updating user records
	static testMethod void testTrigger() {
		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;

		// Set up the test utilities
		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();

		// Find the store account record
		Account store = [SELECT Id FROM Account Where Name = '77 - Twin Cities, MN'];

		// Create a labor record
		Labor__c labRecord = new Labor__c(Store_Location__c = store.Id, Hours_Applied__c = 5);		
		Test.startTest();

		// Insert the labor record
		insert labRecord;
		
		// Retrieve the inserted labor record and verify the internal cost has been calculated correctly
		Labor__c resultInsert = [SELECT Id, Internal_Cost__c FROM Labor__c Where Id = : labRecord.Id];

		// The result should be 250 because the hourly rate is set to 50 in the 
		// setupconfigs and the hours applied is 5
		System.AssertEquals(250, resultInsert.Internal_Cost__c);


		Test.stopTest();
	}
}
/*******************************************************//**

@class	  UserTriggerHandlerTest

@brief	 Test class for Handler for the user trigger

@author	 Creston Kuenzi (Slalom.CDK)

@version	2016-5-25  Slalom.CDK
	Created

@see		UserTriggerHandler

@copyright  (c)2016 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class UserTriggerHandlerTest {

	// Tests the entire trigger by inserting updating user records
	static testMethod void testTrigger() {
		// Set up the test utilities
		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();

		// Retrieve a profile and create a user
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 

		// Set the user's Store Location multi-select
		User u = tUtil.createUser(p.id);
		String storeLocationText = 'store1;store2';
		u.Store_Locations__c = storeLocationText;
		
		Test.startTest();

		// Insert the user
		insert u;
		
		// Retrieve the inserted user and verify the text has been updated with the store locations
		User resultInsert = [SELECT Id, Store_Location_Text__c FROM User Where Id = : u.Id];
		System.AssertEquals(storeLocationText, resultInsert.Store_Location_Text__c);

		// Now update the user's store locations
		String storeLocationUpdateText = 'store1;store2;store3';
		u.Store_Locations__c = storeLocationUpdateText;
		update u;

		// Retrieve the updated user and verify the text has been updated with the store locations
		User resultUpdate = [SELECT Id, Store_Location_Text__c FROM User Where Id = : u.Id];
		System.AssertEquals(storeLocationUpdateText, resultUpdate.Store_Location_Text__c);

		Test.stopTest();
	}
}
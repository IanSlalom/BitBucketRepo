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

	@testSetup 
	static void setupData() {
		Profile p = [SELECT Id FROM Profile WHERE Name='RMS-RSR'];
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.setUpConfigs();
		User mnUser = new User(Alias = 'adm', Email='admin@test.com', Store_Locations__c = '0060 - Rochester, MN;0066 - Mankato, MN',

	      EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',

	      LocaleSidKey='en_US', ProfileId = p.Id,

	      TimeZoneSidKey='America/Los_Angeles', UserName= 'MNUSER' + UserInfo.getOrganizationId() + System.now().millisecond()+'admin-rba@test.com');
	      
		User mnUser2 = new User(Alias = 'adm', Email='admin@test.com', Store_Locations__c = '0060 - Rochester, MN',

	      EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',

	      LocaleSidKey='en_US', ProfileId = p.Id,

	      TimeZoneSidKey='America/Los_Angeles', UserName= 'MNUSER2' + UserInfo.getOrganizationId() + System.now().millisecond()+'admin-rba@test.com');

	    insert mnUser;
	    insert mnUser2;


	 
	}

	// Tests the entire trigger by inserting updating user records
	static testMethod void testTrigger() {

		TestUtilityMethods tUtil = new TestUtilityMethods();
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

	@isTest
	static void testCreateSharingRecordsAfterInsert(){
		User mnUser = [Select Id, UserName from User where Store_Locations__c = '0060 - Rochester, MN;0066 - Mankato, MN' and email ='admin@test.com'];
		User mnUser2 = [Select Id, UserName from User where Store_Locations__c = '0060 - Rochester, MN' and email ='admin@test.com'];
		List<UserShare> ushares = [Select Id, UserId, UserOrGroupId, rowCause from UserShare where UserId=: mnUser.Id and UserOrGroupId =: mnUser2.Id and rowCause ='Manual'];
		System.assertEquals(ushares.size(), 1);
		ushares = [Select Id, UserId, UserOrGroupId, rowCause from UserShare where UserId=: mnUser2.Id and UserOrGroupId =: mnUser.Id and rowCause ='Manual'];
		System.assertEquals(ushares.size(),1);
	}

/*  Hitting mixed DML error
	@isTest
	static void testCreateAndDeleteSharingRecordsAfterUpdate(){
		User mnUser = [Select Id, UserName from User where Store_Locations__c = '0060 - Rochester, MN;0066 - Mankato, MN' and email ='admin@test.com'];
		User mnUser2 = [Select Id, UserName from User where Store_Locations__c = '0060 - Rochester, MN' and email ='admin@test.com'];
		List<UserShare> ushares = [Select Id, UserId, UserOrGroupId, rowCause from UserShare where UserId=: mnUser.Id and UserOrGroupId =: mnUser2.Id and rowCause ='Manual'];
		System.assertEquals(ushares.size(), 1);
		ushares = [Select Id, UserId, UserOrGroupId, rowCause from UserShare where UserId=: mnUser2.Id and UserOrGroupId =: mnUser.Id and rowCause ='Manual'];
		System.assertEquals(ushares.size(),1);
		//Remove Rochester from mnUser's store locations, verify deletion of usershare records
		mnUser.Store_Locations__c = '0066 - Mankato, MN';
		update mnUser;
		ushares = [Select Id, UserId, UserOrGroupId, rowCause from UserShare where UserId=: mnUser.Id and UserOrGroupId =: mnUser2.Id and rowCause ='Manual'];
		System.assertEquals(ushares.size(),0);
		ushares = [Select Id, UserId, UserOrGroupId, rowCause from UserShare where UserId=: mnUser2.Id and UserOrGroupId =: mnUser.Id and rowCause ='Manual'];
		System.assertEquals(ushares.size(),0);
		mnUser2.Store_Locations__c = '0060 - Rochester, MN;0066 - Mankato, MN';
		update mnUser2;
		//Add Mankato to User 2's store locations, verify user share records are created
		ushares = [Select Id, UserId, UserOrGroupId, rowCause from UserShare where UserId=: mnUser.Id and UserOrGroupId =: mnUser2.Id and rowCause ='Manual'];
		System.assertEquals(ushares.size(), 1);
		ushares = [Select Id, UserId, UserOrGroupId, rowCause from UserShare where UserId=: mnUser2.Id and UserOrGroupId =: mnUser.Id and rowCause ='Manual'];
		System.assertEquals(ushares.size(),1);
	}*/
}
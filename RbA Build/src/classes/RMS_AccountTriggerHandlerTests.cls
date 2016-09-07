@isTest
public with sharing class RMS_AccountTriggerHandlerTests {
	@testSetup 
	static void setupData() {
		Profile p = [SELECT Id FROM Profile WHERE Name='RMS-RSR'];
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.setUpConfigs();
		User mnUser = new User(Alias = 'adm', Email='admin@test.com', Store_Locations__c = '0060 - Rochester, MN;0066 - Mankato, MN',

	      EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',

	      LocaleSidKey='en_US', ProfileId = p.Id,

	      TimeZoneSidKey='America/Los_Angeles', UserName= 'MNUSER' + UserInfo.getOrganizationId() + System.now().millisecond()+'admin-rba@test.com');
	      
		User txUser = new User(Alias = 'adm', Email='admin@test.com', Store_Locations__c = '0730 - Austin, TX;0731 - Houston, TX',

	      EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',

	      LocaleSidKey='en_US', ProfileId = p.Id,

	      TimeZoneSidKey='America/Los_Angeles', UserName= 'TXUSER' + UserInfo.getOrganizationId() + System.now().millisecond()+'admin-rba@test.com');

	    insert mnUser;
	    insert txUser;
	    List<Account> storeAccounts = new List<Account>{utility.createStoreAccount('0060 - Rochester, MN'),
	    												utility.createStoreAccount('0066 - Mankato, MN'),
	    												utility.createStoreAccount('0730 - Austin, TX'),
	    												utility.createStoreAccount('0731 - Houston, TX')};
	    insert storeAccounts;

	    Account rochesterVendor = utility.createVendorAccount('RochestorVendor');
	    rochesterVendor.Store_Location__c = storeAccounts[0].Id;
	    Account mankatoVendor = utility.createVendorAccount('MankatoVendor');
	    mankatoVendor.Store_Location__c = storeAccounts[1].Id;
	    Account austinVendor = utility.createVendorAccount('AustinVendor');
	    austinVendor.Store_Location__c = storeAccounts[2].Id;
	    Account houstonVendor = utility.createVendorAccount('HoustonVendor');
	    houstonVendor.Store_Location__c = storeAccounts[3].Id;
	   	List<Account> vendorAccounts = new List<Account>{rochesterVendor,mankatoVendor,austinVendor,houstonVendor};
	   	insert vendorAccounts;
	 
	}

	//Test that the insertion of accounts causes sharing records to be created;
	@isTest
	static void testCreateSharingRecordsAfterInsert(){
		User mnUser = [Select Id from User where Store_Locations__c = '0060 - Rochester, MN;0066 - Mankato, MN'];
		User txUser = [Select Id from USer where Store_Locations__c = '0730 - Austin, TX;0731 - Houston, TX'];
		System.debug(mnUser.Id + '  ' + txUser.Id);
		List<String> acctNames = new List<String>{'0060 - Rochester, MN','0066 - Mankato, MN','0730 - Austin, TX','0731 - Houston, TX'};
		List<Account> storeAccounts = [Select Id, Name from Account where Name in : acctNames];
		List<Account> vendorAccounts = [ Select Id, Name from Account where Store_Location__c in: storeAccounts];
		System.assertEquals(storeAccounts.size(), acctNames.size());
		System.assertEquals(storeAccounts.size(), vendorAccounts.size());
		List<AccountShare> acctShares = [Select Id, UserOrGroupId,AccountAccessLevel, rowCause from AccountShare where AccountId in: vendorAccounts and rowCause = 'Manual'];
		System.assertEquals(acctShares.size(), vendorAccounts.size());
		for(AccountShare share : acctShares){
			system.debug(share.UserOrGroupId);
			system.debug(share.AccountAccessLevel);
			system.debug(share.rowCause);
			User u =[Select Name from User where Id =: share.UserOrGroupId];
			system.assert(share.UserOrGroupId == mnUser.Id || share.UserOrGroupId == txUser.Id);
		}

	}

		//Test that the update of accounts causes sharing records to be deleted/created as appropriate;
	@isTest
	static void testCreateDeleteSharingRecordsAfterUpdate(){
		User mnUser = [Select Id from User where Store_Locations__c = '0060 - Rochester, MN;0066 - Mankato, MN'];
		User txUser = [Select Id from USer where Store_Locations__c = '0730 - Austin, TX;0731 - Houston, TX'];
		System.debug(mnUser.Id + '  ' + txUser.Id);
		List<String> acctNames = new List<String>{'0060 - Rochester, MN'};
		List<Account> storeAccounts = [Select Id, Name from Account where Name in : acctNames];
		List<Account> vendorAccounts = [ Select Id, Name from Account where Store_Location__c in: storeAccounts];
		System.assertEquals(storeAccounts.size(), acctNames.size());
		System.assertEquals(storeAccounts.size(), vendorAccounts.size());
		List<AccountShare> acctShares = [Select Id, UserOrGroupId,AccountAccessLevel, rowCause from AccountShare where AccountId in: vendorAccounts and rowCause = 'Manual'];
		System.assertEquals(acctShares.size(), vendorAccounts.size());
		for(AccountShare share : acctShares){
			system.assert(share.UserOrGroupId == mnUser.Id );
		}
		Account austinAccount = [Select Id from Account where Name Like '%Austin, TX%'];
		Account vendorAccount = [Select Id, Name, OwnerId from Account where Store_Location__c =: austinAccount.Id];
		//Update the storelocation from Austin to Rochester
		vendorAccount.Store_Location__c = storeAccounts[0].Id;
		update vendorAccount;
		//verify sharing record is created for mnUser
		acctShares = [Select Id, UserOrGroupId,AccountAccessLevel, rowCause from AccountShare where AccountId =:vendorAccount.Id and 
										 UserOrGroupId =: mnUser.Id and rowCause = 'Manual'];
		System.assertEquals(acctShares.size(), 1);
		//verify the sharing record is deleted for txUser
		acctShares = [Select Id, UserOrGroupId,AccountAccessLevel, rowCause from AccountShare where AccountId =:vendorAccount.Id and 
										 UserOrGroupId =: txUser.Id and rowCause = 'Manual'];
		System.assertEquals(acctShares.size(),0);
		system.debug(vendorAccount.OwnerId);
		vendorAccount.OwnerId = txUser.Id;
		update vendorAccount;
		//Manual sharing records are deleted when owner of record changes, verify sharing record is reinserted when the Owner for the Account changes.
		acctShares = [Select Id, UserOrGroupId,AccountAccessLevel, rowCause from AccountShare where AccountId =:vendorAccount.Id and 
										 UserOrGroupId =: mnUser.Id and rowCause = 'Manual'];
		System.assertEquals(acctShares.size(), 1);
	}
}
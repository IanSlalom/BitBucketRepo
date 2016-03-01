/**
 *@class	RMS_mobileAppContactHelperTests
 *@brief	Test class for RMS_mobileAppContactHelper
 *@author   Kai Ruan
 *@version	2016-3/1 Created
 *@copyright  (c)2016 Slalom.  All Rights Reserved.	Unauthorized use is prohibited.
 */
 @isTest
private class RMS_mobileAppContactHelperTests {
	
	@testSetup static void setupData(){
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();
		Account dwelling = utility.createDwellingAccount('Dwelling Account');
		Account store = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
		dwelling.Store_Location__c = store.Id;
		insert dwelling;
		Opportunity opp = utility.createOpportunity(dwelling.Id, 'New');
		insert opp;
	}
	
	@isTest
	public static void testSaveNewContact(){
		TestUtilityMethods utility = new TestUtilityMethods();
		Account dwelling = [Select Id from Account where Name = 'Dwelling Account'];
		Opportunity opp = [Select Id from Opportunity where AccountId =: dwelling.Id limit 1];
		Contact c = utility.createContact(dwelling.ID, 'TestName1');
		RMS_mobileAppContactHelper.DTOContact dtoContact = new RMS_mobileAppContactHelper.DTOContact();
		dtoContact.AccountId = dwelling.Id;
		dtoContact.OpportunityId = opp.Id;
		dtoContact.contact = c;
		String jsonResult = RMS_mobileAppContactHelper.saveNewContact(JSON.serialize(dtoContact));
		//Assert Contact is created
		List<Contact> cList = [select Id, AccountId from Contact where AccountId =: dwelling.Id AND FirstName Like '%TestName1%'];
		System.assert(!cList.isEmpty());
		//Assert Contact History is created
		List<Contact_History__c> cHistList = [select Contact__c, Dwelling__c, Type__c from Contact_History__c where Contact__c =: clist[0].Id];
		System.assert(!cHistList.isEmpty());
		System.assertEquals(cHistList[0].Dwelling__c, dwelling.Id);
		System.assertEquals(cHistList[0].Type__c, 'Current Resident');
		//Assert Opportunity Contact Role is created
		List<OpportunityContactRole> cRoleList = [select ContactId, OpportunityId,Role from OpportunityContactRole where ContactId =: clist[0].Id];
		System.assert(!cRoleList.isEmpty());
		System.assertEquals(cRoleList[0].OpportunityId, opp.Id);
		System.assertEquals(cRoleList[0].Role, 'Decision Maker');
		//Assert Json response contains contact Id
		System.assert(jsonResult.contains(clist[0].Id));		
	}

	@isTest
	public static void testSaveNewContactWithoutAccountId(){
		TestUtilityMethods utility = new TestUtilityMethods();
		Account dwelling = [Select Id from Account where Name = 'Dwelling Account'];
		Opportunity opp = [Select Id from Opportunity where AccountId =: dwelling.Id limit 1];
		Contact c = utility.createContact(dwelling.ID, 'TestName1');
		RMS_mobileAppContactHelper.DTOContact dtoContact = new RMS_mobileAppContactHelper.DTOContact();
		dtoContact.AccountId = null;
		dtoContact.OpportunityId = opp.Id;
		dtoContact.contact = c;
		String jsonResult = RMS_mobileAppContactHelper.saveNewContact(JSON.serialize(dtoContact));
		//Assert Contact is created
		List<Contact> cList = [select Id, AccountId from Contact where FirstName Like '%TestName1%'];
		System.assert(!cList.isEmpty());		
		//Assert Contact History is not created
		List<Contact_History__c> cHistList = [select Contact__c, Dwelling__c, Type__c from Contact_History__c where Contact__c =: clist[0].Id];
		System.assert(cHistList.isEmpty());
	}

	@isTest
	public static void testSaveNewContactWithoutOpportunityId(){
		TestUtilityMethods utility = new TestUtilityMethods();
		Account dwelling = [Select Id from Account where Name = 'Dwelling Account'];
		Opportunity opp = [Select Id from Opportunity where AccountId =: dwelling.Id limit 1];
		Contact c = utility.createContact(dwelling.ID, 'TestName1');
		RMS_mobileAppContactHelper.DTOContact dtoContact = new RMS_mobileAppContactHelper.DTOContact();
		dtoContact.AccountId = dwelling.Id;
		dtoContact.OpportunityId = null;
		dtoContact.contact = c;
		String jsonResult = RMS_mobileAppContactHelper.saveNewContact(JSON.serialize(dtoContact));
		//Assert Contact is created
		List<Contact> cList = [select Id, AccountId from Contact where AccountId =: dwelling.Id AND FirstName Like '%TestName1%'];
		System.assert(!cList.isEmpty());
		//Assert Contact History is created
		List<Contact_History__c> cHistList = [select Contact__c, Dwelling__c, Type__c from Contact_History__c where Contact__c =: clist[0].Id];
		System.assert(!cHistList.isEmpty());
		System.assertEquals(cHistList[0].Dwelling__c, dwelling.Id);
		System.assertEquals(cHistList[0].Type__c, 'Current Resident');
		//Assert Opportunity Contact Role is not created
		List<OpportunityContactRole> cRoleList = [select ContactId, OpportunityId,Role from OpportunityContactRole where ContactId =: clist[0].Id];
		System.assert(cRoleList.isEmpty());
		//Assert Json response contains contact Id
		System.assert(jsonResult.contains(clist[0].Id));
	}
}
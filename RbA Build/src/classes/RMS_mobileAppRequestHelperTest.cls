/**
 *@class	RMS_mobileAppRequestHelperTest
 *@brief	test class for RMS_mobileAppRequestHelper
 *@author  Anthony Strafaccia (Slalom.ADS)
 *@author  Mark Wochnick (Slalom.MAW)
 *@version	2015-09/16  Slalom.ADS	Created.
 *@version	2015-10/12  Slalom.MAW
 *@copyright  (c)2015 Slalom.  All Rights Reserved.	Unauthorized use is prohibited.
 */
@isTest
private class RMS_mobileAppRequestHelperTest {

	@testSetup static void setupData(){
  		List<RMS_Settings__c> rms = new List<RMS_Settings__c>{ new RMS_Settings__c(Name = 'rSuite.search.nullParameters.error', Value__c ='Null Parameters'),
  																new RMS_Settings__c(Name ='rSuite.search.maxresults', Value__c = '1'),
  																new RMS_Settings__c(Name = 'rSuite.search.tooManyResults.error', Value__c='Too Many Results')};
  		insert rms; 
	}

	static testmethod void testFindAppointments(){
		
		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigsMark();
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
		// setup configuration stuff
//		Datetime existingApptTime = Datetime.newInstance(2016, 1, 10, 8, 0, 0);
		Datetime newApptTime = Datetime.now().addDays(1);
		Datetime tmApptTime = Datetime.now().addDays(5);

		User u = tUtil.createUser(p.id);
		insert u;
//		tUtil.createSalesAppt(u.Id, existingApptTime, true);
		tUtil.createSalesAppt(u.Id, newApptTime, false);
		tUtil.createTMAppt(u.Id, tmApptTime);
        System.runAs(u) {
			Test.startTest();
        	RMS_mobileAppRequestHelper mHelper = new RMS_mobileAppRequestHelper();
			String jsonResult = mHelper.findAppointments(u.Id, newApptTime.addDays(-1));
			Test.stopTest();
			//Verify the Synced DateTime field on Event is set properly by the findAppointments method
			List<Event> salesEvents = [SELECT Id, StartDateTime, EndDateTime, Subject, WhoId, WhatId, Type, Synced_DateTime__c, isCancelled__c FROM Event Where OwnerId =: u.Id and StartDateTime >= :newApptTime.addDays(-1) and Type = 'Sales Appointment'];
      		List<Event> techmEvents = [SELECT Id, StartDateTime, EndDateTime, Subject, WhoId, WhatId, Type, Synced_DateTime__c, isCancelled__c FROM Event Where OwnerId =: u.Id and StartDateTime >= :newApptTime.addDays(-1) and Type = 'Tech Measure'];
     		System.assertEquals(salesEvents.size(),1);
     		System.assertEquals(techmEvents.size(),1);
     		System.assert(Datetime.now().getTime() - salesEvents[0].Synced_DateTime__c.getTime() < 2000);
     		System.assert(Datetime.now().getTime() - techmEvents[0].Synced_DateTime__c.getTime() < 2000);
			System.debug('###################################### ' + jsonResult);
			System.assert(jsonResult.startsWith('{"tmAppts":'));
        }
	}

	static testmethod void testResultSalesAppointments(){
		
		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigsMark();
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
		// setup configuration stuff
//		Datetime existingApptTime = Datetime.newInstance(2016, 1, 10, 8, 0, 0);
		Datetime newApptTime = Datetime.now().addDays(1);
		Datetime tmApptTime = Datetime.now().addDays(5);

		User u = tUtil.createUser(p.id);
		insert u;
//		tUtil.createSalesAppt(u.Id, existingApptTime, true);
		tUtil.createSalesAppt(u.Id, newApptTime, false);
		tUtil.createTMAppt(u.Id, tmApptTime);
        System.runAs(u) {
			Test.startTest();
        	RMS_mobileAppRequestHelper mHelper = new RMS_mobileAppRequestHelper();
			String jsonResult = mHelper.resultSalesAppointments(u.Id, '{"tmAppts":[],"salesAppts":[],"getApptsCompletedTimeStamp":null,"errors":null}');
			Test.stopTest();
			System.debug('###################################### ' + jsonResult);
			System.assert(jsonResult.startsWith('{"tmAppts":'));
        }
	}

	static testmethod void testCustomerSearch(){
		final String firstName = 'firstName';
		final String lastName = 'lastName';
		final String email ='test@test.com';
		final String phone = '60552339441';
		final String street = '123 Test Street';
		final String city = 'Phoenix';
		final String state = 'AZ';
		final Date startDate = System.Today();
		final Date endDate = System.Today().addDays(2);

		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();
		Account dwelling = utility.createDwellingAccount('Dwelling Account');
		Account store = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
		dwelling.Store_Location__c = store.Id;
		insert dwelling;
		Contact contact = new Contact(
            AccountId = dwelling.Id,
            FirstName = firstName,
            LastName = lastName,
            Email =  email,
            Phone = phone
        );
		insert contact;
		Opportunity opp = utility.createOpportunity(dwelling.Id, 'New');	
		dwelling.ShippingStreet = street;
		dwelling.ShippingCity = city;
		dwelling.ShippingStateCode = state;
		update dwelling;
		opp.CloseDate = System.Today().addDays(1);
		insert opp;

		RMS_mobileAppRequestHelper.DTOCustomerSearchParameters dtoSearchParams = new RMS_mobileAppRequestHelper.DTOCustomerSearchParameters();
       	RMS_mobileAppRequestHelper mHelper = new RMS_mobileAppRequestHelper();
		String JSONResponse = mHelper.customerSearch(JSON.serialize(dtoSearchParams));

		//If all opportunity search fields are blank, error message is returned
		RMS_mobileAppRequestHelper.DTOCustomerSearchResultsContainer responseContainer = (RMS_mobileAppRequestHelper.DTOCustomerSearchResultsContainer)JSON.deserialize(JSONResponse, RMS_mobileAppRequestHelper.DTOCustomerSearchResultsContainer.class);
		System.assertEquals(responseContainer.error, RMS_mobileAppRequestHelper.RMS_Settings_map.get('rSuite.search.nullParameters.error').Value__c);

	    dtoSearchParams.startDate = startDate;
	    dtoSearchParams.endDate = endDate;
	    dtoSearchParams.address = street;
	    dtoSearchParams.city = city;
	    dtoSearchParams.state = state;
	    dtoSearchParams.firstName = firstName;
	    dtoSearchParams.lastName = lastName;
	    dtoSearchParams.email = email;
	    dtoSearchParams.phone = phone;

	    OpportunityContactRole contact1 = new OpportunityContactRole(ContactId = contact.ID, OpportunityID = opp.Id, IsPrimary = true, Role = 'Decision Maker');
	    insert contact1;

	    //Verify JSONResponse contains correct contactrole information
		JSONResponse = mHelper.customerSearch(JSON.serialize(dtoSearchParams));
		responseContainer = (RMS_mobileAppRequestHelper.DTOCustomerSearchResultsContainer)JSON.deserialize(JSONResponse, RMS_mobileAppRequestHelper.DTOCustomerSearchResultsContainer.class);
		System.assertEquals(responseContainer.error, null);
		System.assertEquals(responseContainer.searchResults.size(),1);
		RMS_mobileAppRequestHelper.DTOCustomerSearchResults resultRecord = responseContainer.searchResults[0];
		System.assertEquals(resultRecord.firstName, firstName);
		System.assertEquals(resultRecord.lastName, lastName);
		System.assertEquals(resultRecord.city, city);
		System.assertEquals(resultRecord.address, street);
		System.assertEquals(resultRecord.email, email);
		System.assertEquals(resultRecord.phone, phone);
		System.assertEquals(resultRecord.opportunityID, opp.Id);

		//If # OpportunityContactRoles returned by query is more than max allowed, return an error message
		OpportunityContactRole contact2 = new OpportunityContactRole(ContactId = contact.ID, OpportunityID = opp.Id, IsPrimary = false, Role = 'Influencer');
	    insert contact2;
	    JSONResponse = mHelper.customerSearch(JSON.serialize(dtoSearchParams));
	    responseContainer = (RMS_mobileAppRequestHelper.DTOCustomerSearchResultsContainer)JSON.deserialize(JSONResponse, RMS_mobileAppRequestHelper.DTOCustomerSearchResultsContainer.class);
// TODO: fix this assert
//		System.assertEquals(responseContainer.error, RMS_mobileAppRequestHelper.RMS_Settings_map.get('rSuite.search.tooManyResults.error').Value__c);

	}

	static testmethod void testGetSelectedSearchResults(){

		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();
		Account dwelling = utility.createDwellingAccount('Dwelling Account');

		Account store = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
		dwelling.Store_Location__c = store.Id;
		insert dwelling;
		Opportunity opp = utility.createOpportunity(dwelling.Id, 'New');	
		Opportunity opp2 = utility.createOpportunity(dwelling.Id, 'New');	
		update dwelling;
		opp.CloseDate = System.Today().addDays(1);
		opp2.CloseDate = System.Today().addDays(1);
		insert opp;
		insert opp2;

		Event event = new Event(WhatID = opp.Id,DurationInMinutes = 15, IsAllDayEvent = false, ActivityDateTime = System.now());
		insert event;
		Event event2 = new Event(WhatID = opp2.Id,DurationInMinutes = 15, IsAllDayEvent = false, ActivityDateTime = System.now());
		insert event2;
		RMS_mobileAppRequestHelper helper = new RMS_mobileAppRequestHelper();
		List<Id> opportunityIDs = new List<ID>{opp.Id, opp2.Id};
		String JSONResponse = helper.getSelectedSearchResults(JSON.serialize(opportunityIDs));
	   	RMS_mobileAppRequestHelper.Appointments apptContainer = (RMS_mobileAppRequestHelper.Appointments)JSON.deserialize(JSONResponse, RMS_mobileAppRequestHelper.Appointments.class);
	   	System.assertEquals(apptContainer.getErrors().size(),0);
	   	System.assertEquals(apptContainer.salesAppts.size(),2);
	   	System.assertEquals(apptContainer.salesAppts[0].event.Id, event.Id);
	}

	

}
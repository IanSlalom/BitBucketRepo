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
		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;
		
		TestUtilityMethods tUtil = new TestUtilityMethods();
//		tUtil.setUpConfigsMark();
		tUtil.setUpConfigs();
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
     		System.assert(Datetime.now().getTime() - salesEvents[0].Synced_DateTime__c.getTime() < 120000);
     		System.assert(Datetime.now().getTime() - techmEvents[0].Synced_DateTime__c.getTime() < 120000);
			System.debug('###################################### ' + jsonResult);
			System.assert(jsonResult.startsWith('{"tmAppts":'));
        }
	}

	static testmethod void testResultSalesAppointments(){
		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;
		
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
		Opportunity opp2 = utility.createOpportunity(dwelling.Id, 'New2');	
		opp2.CloseDate = System.Today().addDays(1);
		insert opp2;
		OpportunityContactRole contact2 = new OpportunityContactRole(ContactId = contact.ID, OpportunityID = opp2.Id, IsPrimary = true, Role = 'Influencer');
	    insert contact2;
	    JSONResponse = mHelper.customerSearch(JSON.serialize(dtoSearchParams));
	    responseContainer = (RMS_mobileAppRequestHelper.DTOCustomerSearchResultsContainer)JSON.deserialize(JSONResponse, RMS_mobileAppRequestHelper.DTOCustomerSearchResultsContainer.class);
		System.assertEquals(responseContainer.error, RMS_mobileAppRequestHelper.RMS_Settings_map.get('rSuite.search.tooManyResults.error').Value__c);

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

	static testmethod void testSaveTechMeasure(){

		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;

		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 

		Datetime newApptTime = Datetime.now().addDays(1);
		Datetime tmApptTime = Datetime.now().addDays(5);

		User u = tUtil.createUser(p.id);
		insert u;

		//tUtil.createSalesAppt(u.Id, newApptTime, false);
		tUtil.createTMAppt(u.Id, tmApptTime);
		Account dwelling = [select Id from Account where Name = '1'];
		Opportunity opp = [select Id, StageName from Opportunity where AccountId =: dwelling.id];
		opp.StageName = 'Sold';
		List<Product2> productList = [Select Id from Product2 where Name = 'Test Product'];
		Order ord1 = [Select Id, Status from Order where OpportunityID =: opp.Id];
		ord1.Status = 'Ready to Order';
		List<RbA_Work_Order__c> workOrder = [SELECT Id FROM RbA_Work_Order__c  WHERE Opportunity__c = :opp.id AND Sold_Order__c = :ord1.id];
		workOrder[0].Work_Order_Status__c = 'Scheduled';
		PricebookEntry pricebookEntry1 = [Select Id from PricebookEntry where Product2Id =: productList[0].Id];
		OrderItem oiToUpdate = new OrderItem(OrderId = ord1.Id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100 );
		insert oiToUpdate;
		oiToUpdate.Quantity =1;
		OrderItem oiToInsert = new OrderItem(OrderId = ord1.Id, PricebookentryId = pricebookEntry1.Id, Quantity = 10, UnitPrice = 10 );
		TM_OffSet__C tmOffsetToUpdate = new TM_OffSet__C(Order_Line__c = oiToUpdate.Id,Description__c = 'New Description', Measurement__c = 1 );
		insert tmOffsetToUpdate;
		tmOffsetToUpdate.Description__c = 'Updated Description';
		TM_OffSet__c tmOffsetToInsert = new TM_Offset__C(Order_Line__c = oiToUpdate.Id,Description__c = 'Insert Description TMO', Measurement__c = 2 );

		RMS_mobileAppRequestHelper.OrderItemContainer oiContainerUpdate = new RMS_mobileAppRequestHelper.OrderItemContainer();
		oiContainerUpdate.oi = oiToUpdate;
		oiContainerUpdate.tmOffSetList = new List<TM_Offset__C>{tmOffsetToUpdate};
		RMS_mobileAppRequestHelper.OrderItemContainer oiContainerInsert = new RMS_mobileAppRequestHelper.OrderItemContainer();
		oiContainerInsert.oi = oiToInsert;
		oiContainerInsert.tmOffSetList = new List<TM_Offset__C>{tmOffsetToInsert};
		RMS_mobileAppRequestHelper.OrderContainer orderContainerUpsert = new RMS_mobileAppRequestHelper.OrderContainer();
		orderContainerUpsert.anOrder = ord1;
		orderContainerUpsert.oiContainerList = new List<RMS_mobileAppRequestHelper.OrderItemContainer>{oiContainerUpdate,oiContainerInsert};
		RMS_mobileAppRequestHelper.OpportunityContainer oppContainerUpsert = new RMS_mobileAppRequestHelper.OpportunityContainer();
		oppContainerUpsert.anOrderContainer = orderContainerUpsert;
		oppContainerUpsert.oppty = opp;
		RMS_mobileAppRequestHelper.TechMeasureAppointment tmApptUpdate = new RMS_mobileAppRequestHelper.TechMeasureAppointment();
		tmApptUpdate.account = dwelling;
		tmApptUpdate.workOrder = workOrder[0];
		tmApptUpdate.opptyContainer = oppContainerUpsert;
		RMS_mobileAppRequestHelper.Appointments appUpdate = new RMS_mobileAppRequestHelper.Appointments();
		appUpdate.tmAppts = new List<RMS_mobileAppRequestHelper.TechMeasureAppointment>{tmApptUpdate};	

        System.runAs(u) {
        	Test.StartTest();
        	RMS_mobileAppRequestHelper helper = new RMS_mobileAppRequestHelper();
			String input = JSON.serialize(appUpdate);
//			System.debug('################ - the JSON:' + input);
			helper.saveTechMeasure(input);
			Test.StopTest();

			//Assert Opportunity Status is updated
			opp = [Select StageName from Opportunity where Id =: opp.Id];
			System.assertEquals(opp.StageName,'Sold');
			//Assert Order status is updated
			ord1 = [Select Status from Order where Id =: ord1.Id];
			System.assertEquals(ord1.Status, 'Ready to Order');
			//assert OrderItems are updated/inserted
			oiToUpdate = [Select Quantity from OrderItem where Id =: oiToUpdate.Id];
			System.assertEquals(oiToUpdate.Quantity, 1);
			List<OrderItem> oiInsertedList = [Select Id from OrderItem where Quantity = 10];
			System.assertEquals(oiInsertedList.size(), 1);
			//Assert Tech Measure Offsets are updated/serted
			tmOffsetToUpdate = [Select Description__c from TM_Offset__C where Id =: tmOffsetToUpdate.Id];
			System.assertEquals(tmOffsetToUpdate.Description__c,'Updated Description');
			List<TM_Offset__C> tmoInsertedList = [Select Id from TM_Offset__C where Description__c = 'Insert Description TMO'];
			System.assertEquals(tmoInsertedList.size(),1);
			//Assert RBA Work Order is updated 
			List<RbA_Work_Order__c> rbaUpdatedList = [Select Id from RbA_Work_Order__c where Work_Order_Status__c = 'Scheduled'];
			System.assertEquals(rbaUpdatedList.size(),1);
        }
	
	}

	static testmethod void testSaveQuotes(){

		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 

		Datetime newApptTime = Datetime.now().addDays(1);
		Datetime tmApptTime = Datetime.now().addDays(5);

		User u = tUtil.createUser(p.id);
		insert u;

		//tUtil.createSalesAppt(u.Id, newApptTime, false);
		tUtil.createTMAppt(u.Id, tmApptTime);
		Account dwelling = [select Id from Account where Name = '1'];
		Opportunity opp = [select Id, StageName from Opportunity where AccountId =: dwelling.id];
		opp.StageName = 'Sold';
		List<Product2> productList = [Select Id from Product2 where Name = 'Test Product'];
		Quote quoteToUpdate = tUtil.createQuote(opp.Id, Test.getStandardPriceBookId());
		insert quoteToUpdate;
		quoteToUpdate.Description = 'UPDATED DESCRIPTION';
		Quote quoteToInsert = tUtil.createQuote(opp.Id, Test.getStandardPriceBookId());
		quoteToInsert.Description = 'INSERT THIS QUOTE';
		RMS_mobileAppRequestHelper.QuoteContainer quoteContainer = new RMS_mobileAppRequestHelper.QuoteContainer();
		quoteContainer.aQuote = quoteToUpdate;
		RMS_mobileAppRequestHelper.QuoteContainer quoteContainerInsert = new RMS_mobileAppRequestHelper.QuoteContainer();
		quoteContainerInsert.aQuote = quoteToInsert;
		RMS_mobileAppRequestHelper.OpportunityContainer oppContainer = new RMS_mobileAppRequestHelper.OpportunityContainer();
		oppContainer.oppty = opp;
		oppContainer.quoteContainerList = new List<RMS_mobileAppRequestHelper.QuoteContainer>{quoteContainer,quoteContainerInsert};
		RMS_mobileAppRequestHelper.SalesAppointment salesAppt = new RMS_mobileAppRequestHelper.SalesAppointment();
		salesAppt.account = dwelling;
		salesAppt.opptyContainer = oppContainer;
		RMS_mobileAppRequestHelper.Appointments appt = new RMS_mobileAppRequestHelper.Appointments();
		appt.salesAppts = new List<RMS_mobileAppRequestHelper.SalesAppointment>{salesAppt};	

        System.runAs(u) {
        	Test.StartTest();
        	RMS_mobileAppRequestHelper helper = new RMS_mobileAppRequestHelper();
			helper.saveQuotes(appt);
			Test.StopTest();

			//Assert Quote Description field is updated
			quoteToUpdate = [SELECT Description from Quote where Id =: quoteToUpdate.Id];
			System.assertEquals(quoteToUpdate.Description, 'UPDATED DESCRIPTION');
			//Assert quoteToInsert is inserted
			System.assert(quoteToInsert.Id != null);
        }
	
	}

	static testmethod void testSaveQuoteLineItemsDiscountsandFinancing(){

		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;

		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 

		Datetime newApptTime = Datetime.now().addDays(1);
		Datetime tmApptTime = Datetime.now().addDays(5);

		User u = tUtil.createUser(p.id);
		insert u;

		//tUtil.createSalesAppt(u.Id, newApptTime, false);
		tUtil.createTMAppt(u.Id, tmApptTime);
		Account dwelling = [select Id from Account where Name = '1'];
		Opportunity opp = [select Id, StageName from Opportunity where AccountId =: dwelling.id];
		opp.StageName = 'Sold';
		List<Product2> productList = [Select Id from Product2 where Name = 'Test Product'];
		PricebookEntry pricebookEntry1 = [Select Id from PricebookEntry where Product2Id =: productList[0].Id];
		Quote quote = tUtil.createQuote(opp.Id, Test.getStandardPriceBookId());
		insert quote;

		QuoteLineItem lineItemToUpdate = tUtil.createQuoteLineItem(pricebookEntry1.Id, quote.Id);
		insert lineItemToUpdate;
		lineItemToUpdate.Description ='UPDATED QLI DESCRIPTION';
		QuoteLineItem lineItemToInsert = tUtil.createQuoteLineItem(pricebookEntry1.Id, quote.Id);
		System.assertEquals(lineItemToInsert.Id, null);

		Account myStore = [select Id, Active_Store_Configuration__c from Account where Name = '77 - Twin Cities, MN' Limit 1];
		Discount__c discount1 = new Discount__c(Name = 'my discount');
		insert discount1;
		Store_Discount__c storeDiscount1 = new Store_Discount__c();
		storeDiscount1.Discount__c = discount1.Id;
		storeDiscount1.Store_Configuration__c = myStore.Active_Store_Configuration__c;
		storeDiscount1.Active__c = true;
		insert storeDiscount1;		

		Quote_Discount__c discountToUpdate = new Quote_Discount__c(Quote__c = quote.Id, Store_Discount__c = storeDiscount1.Id);
		insert discountToUpdate;
		discountToUpdate.Status__c = 'Cancelled';
		Quote_Discount__c discountToInsert = new Quote_Discount__c(Quote__c = quote.Id, Store_Discount__c = storeDiscount1.Id);

		Store_Finance_Program__c storeFinance = new Store_Finance_Program__c(Store_Configuration__c = myStore.Active_Store_Configuration__c, Active__c = true);
		insert storeFinance;
		Quote_Financing__c financeToUpdate = new Quote_Financing__c(Related_Quote__c = quote.Id, Store_Finance_Program__c = storeFinance.Id);
		insert financeToUpdate;
		financeToUpdate.Program_Rate__c = 20;
		Quote_Financing__c financeToInsert = new Quote_Financing__c(Related_Quote__c = quote.Id, Store_Finance_Program__c = storeFinance.Id);

		RMS_mobileAppRequestHelper.QuoteContainer quoteContainer = new RMS_mobileAppRequestHelper.QuoteContainer();
		quoteContainer.aQuote = quote;
		quoteContainer.quoteLineItems = new List<QuoteLineItem>{lineItemToUpdate,lineItemToInsert};
		quoteContainer.quoteDiscountList = new List<Quote_Discount__c>{discountToUpdate,discountToInsert};
		quoteContainer.quoteFinancingList = new List<Quote_Financing__c>{financeToUpdate,financeToInsert};
		RMS_mobileAppRequestHelper.OpportunityContainer oppContainer = new RMS_mobileAppRequestHelper.OpportunityContainer();
		oppContainer.oppty = opp;
		oppContainer.quoteContainerList = new List<RMS_mobileAppRequestHelper.QuoteContainer>{quoteContainer};
		RMS_mobileAppRequestHelper.SalesAppointment salesAppt = new RMS_mobileAppRequestHelper.SalesAppointment();
		salesAppt.account = dwelling;
		salesAppt.opptyContainer = oppContainer;
		RMS_mobileAppRequestHelper.Appointments appt = new RMS_mobileAppRequestHelper.Appointments();
		appt.salesAppts = new List<RMS_mobileAppRequestHelper.SalesAppointment>{salesAppt};	

        System.runAs(u) {
        	Test.StartTest();
        	RMS_mobileAppRequestHelper helper = new RMS_mobileAppRequestHelper();
			helper.saveQuoteLineItemsDiscountsandFinancing(appt);
			Test.StopTest();

			//Assert Quote Line Items are Upserted
			lineItemToUpdate = [SELECT Description from QuoteLineItem where Id =: lineItemToUpdate.Id];
			System.assertEquals(lineItemToUpdate.Description, 'UPDATED QLI DESCRIPTION');
			System.assert(lineItemToInsert.Id != null);

			//Assert Quote Discounts are Upserted
			discountToUpdate = [SELECT Status__c from Quote_Discount__c where Id =: discountToUpdate.Id];
			System.assertEquals(discountToUpdate.Status__c,'Cancelled');
			System.assert(discountToInsert.Id != null);

			//Assert Quote Line Items are Upserted
			financeToUpdate = [SELECT Program_Rate__c from Quote_Financing__c where Id =: financeToUpdate.Id];
			System.assertEquals(financeToUpdate.Program_Rate__c, 20);
			System.assert(financeToInsert.Id != null);
        }
	
	}

}
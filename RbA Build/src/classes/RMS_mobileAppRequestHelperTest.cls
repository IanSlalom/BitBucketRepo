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

	/* 
	 * testFindAppointments
	 */
	static testmethod void testFindAppointments(){
		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;
		
		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
		// setup configuration stuff
		Datetime newApptTime = Datetime.now().addDays(1);
		Datetime tmApptTime = Datetime.now().addDays(5);
		User u = tUtil.createUser(p.id);
		insert u;
		tUtil.createSalesAppt(u.Id, newApptTime, false);
		tUtil.createTMAppt(u.Id, tmApptTime);

        System.runAs(u) {
		    Test.startTest();
        	RMS_mobileAppRequestHelper mHelper = new RMS_mobileAppRequestHelper();
			String jsonResult = mHelper.findAppointments(u.Id, newApptTime.addDays(-1));
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
		Test.stopTest();
	} 

	/* 
	 * testResultSalesAppointments
	 */
	static testmethod void testResultSalesAppointments(){
		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;
		
		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();
		Profile p = [SELECT Id FROM Profile WHERE Name='RMS-Sales']; 
		// setup configuration stuff
		Datetime tmApptTime = Datetime.now().addDays(5);

		User u = tUtil.createUser(p.id);
		insert u;
		tUtil.createSalesAppt(u.Id, tmApptTime, false);
		// build out the container
		Account store1 = [SELECT id, Active_Store_Configuration__c FROM Account Where Name = '77 - Twin Cities, MN'][0];
		Id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        Account dwelling = [Select Id from Account where Name != 'RbA' AND Name != 'Unassigned Account' AND RecordTypeId =: dwellingRT];
		Opportunity opp = [select Id, StageName, rSuite_Id__c from Opportunity where AccountId =: dwelling.id];
		opp.StageName = 'In Progress';

		// create pricebook
		Pricebook2 pb = tutil.createPricebook2('SATestPB2', store1.Active_Store_Configuration__c);
		insert pb;

		//create existing quote
		Quote quoteToUpdate = tUtil.createQuote(opp.Id, pb.Id);
		insert quoteToUpdate;
		quoteToUpdate.Description = 'UPDATED QUOTE DESCRIPTION';
		// create new quote
		Quote quoteToInsert = tUtil.createQuote(opp.Id, pb.Id);
		quoteToInsert.Description = 'INSERT THIS QUOTE';
		// create new quote without line items
		Quote quoteNoLines = tUtil.createQuote(opp.Id, pb.Id);
		quoteNoLines.Description = 'Quote no line items';
		// create existing quote lines
		QuoteLineItem qli1 = tUtil.createQLIMasterChildProducts(pb.Id, quotetoUpdate.Id);
		insert qli1;
		QuoteLineItem qli2 = tUtil.createQLIMasterChildProducts(pb.Id, quotetoUpdate.Id);
		insert qli2;
		// creete quote lines to insert - as they would come in from rSuite - with a child product set but not the master
		QuoteLineItem qli3 = tUtil.createQLIMasterChildProducts(pb.Id, quoteToInsert.Id);
		qli3.PricebookEntryId = null;
		QuoteLineItem qli4 = tUtil.createQLIMasterChildProducts(pb.Id, quoteToInsert.Id);
		qli4.PricebookEntryId = null;


		RMS_mobileAppRequestHelper.QuoteContainer quoteContainer = new RMS_mobileAppRequestHelper.QuoteContainer();
		quoteContainer.aQuote = quoteToUpdate;
		quoteContainer.quoteLineItems = new List<QuoteLineItem>();
		quoteContainer.quoteLineItems.add(qli1);
		quoteContainer.quoteLineItems.add(qli2);

		RMS_mobileAppRequestHelper.QuoteContainer quoteContainerInsert = new RMS_mobileAppRequestHelper.QuoteContainer();
		quoteContainerInsert.aQuote = quoteToInsert;
		quoteContainerInsert.quoteLineItems = new List<QuoteLineItem>();
		quoteContainerInsert.quoteLineItems.add(qli3);
		quoteContainerInsert.quoteLineItems.add(qli4);

		RMS_mobileAppRequestHelper.QuoteContainer quoteContainerNoLines = new RMS_mobileAppRequestHelper.QuoteContainer();
		quoteContainerNoLines.aQuote = quoteNoLines;
		// validate data is setup correctly
		System.assert(qli3.PricebookEntryId == null);
		System.assert(qli4.PricebookEntryId == null);
		System.assert(qli3.Id == null);
		System.assert(qli4.Id == null);
		System.assert(quoteToInsert.Id == null);

		RMS_mobileAppRequestHelper.OpportunityContainer oppContainer = new RMS_mobileAppRequestHelper.OpportunityContainer();
		oppContainer.oppty = opp;
		oppContainer.quoteContainerList = new List<RMS_mobileAppRequestHelper.QuoteContainer>{quoteContainer,quoteContainerInsert,quoteContainerNoLines};
		RMS_mobileAppRequestHelper.SalesAppointment salesAppt = new RMS_mobileAppRequestHelper.SalesAppointment();
		salesAppt.account = dwelling;
		salesAppt.opptyContainer = oppContainer;
		
		String jsonInput = JSON.serialize(salesAppt);
		System.assert(salesAppt.opptyContainer.oppty.rSuite_Id__c != null);
		System.debug('###################################### ' + jsonInput);
		System.assert(jsonInput.countMatches('Child_Product_Pricebook_Entry_Id__c') == 4);
		System.assert(jsonInput.countMatches('"PricebookEntryId":null') == 2);
		System.assert(jsonInput.countMatches('"QuoteLineItem","url":') == 2);

        System.runAs(u) {
			Test.startTest();
        	RMS_mobileAppRequestHelper mHelper = new RMS_mobileAppRequestHelper();
			String jsonResult = mHelper.resultSalesAppointments(u.Id, jsonInput);
			Test.stopTest();
			System.debug('######################################: result:' + jsonResult);
			RMS_mobileAppRequestHelper.SalesAppointment appt = (RMS_mobileAppRequestHelper.SalesAppointment)JSON.deserialize(jsonResult, RMS_mobileAppRequestHelper.SalesAppointment.class);
			System.assert(jsonResult.startsWith('{"opptyContainer":{'));
			System.assert(appt.isSaveSuccessful);
			List<Quote> quoteList = [select Id, Name from Quote where OpportunityId = :opp.Id];
			System.assert(quoteList.size() == 3);
        }
	}

	/*
	 * testAddMasterProducts
	 */
	static testmethod void testAddMasterProducts(){
		TestUtilityMethods tUtil = new TestUtilityMethods();
		// create the pricebook
		Pricebook2 pb = tutil.createPricebook2('SATestAddProducts', null);
		insert pb;
		// create the procducts
		Id rtId = UtilityMethods.retrieveRecordTypeId(Constants.MASTER_PRODUCT_RECORD_TYPE_NAME, 'Product2');
		Product2 mpWindow = tUtil.createProduct('masterWindow', rtId);
		mpWindow.rSuite_Product_Type__c = 'Window';
		insert mpWindow;
		Product2 mpMullion = tUtil.createProduct('masterMullion', rtId);
		mpMullion.rSuite_Product_Type__c = 'Mullion';
		insert mpMullion;
		Product2 mpSpecialty = tUtil.createProduct('masterSpecialty', rtId);
		mpSpecialty.rSuite_Product_Type__c = 'Specialty';
		insert mpSpecialty;
		Product2 mpSpecialtyChord = tUtil.createProduct('masterSpecialtyChord', rtId);
		mpSpecialtyChord.rSuite_Product_Type__c = 'Specialty';
		mpSpecialtyChord.Master_Product__c = mpSpecialty.Id;
		insert mpSpecialtyChord;

		rtId = UtilityMethods.retrieveRecordTypeId(Constants.CHILD_PRODUCT_RECORD_TYPE_NAME, 'Product2');
		Product2 cpWindow = tUtil.createProduct('childWindow', rtId);
		cpWindow.rSuite_Product_Type__c = 'Window';
		cpWindow.Master_Product__c = mpWindow.Id;
		insert cpWindow;
		Product2 cpSpecialtyChord = tUtil.createProduct('childSpecialtyChord', rtId);
		cpSpecialtyChord.rSuite_Product_Type__c = 'Specialty';
		cpSpecialtyChord.Master_Product__c = mpSpecialtyChord.Id;
		insert cpSpecialtyChord;

		rtId = UtilityMethods.retrieveRecordTypeId(Constants.MULLION_PRODUCT_RECORD_TYPE_NAME, 'Product2');
		Product2 cpMullion = tUtil.createProduct('childMullion', rtId);
		cpMullion.rSuite_Product_Type__c = 'Mullion';
		cpMullion.Master_Product__c = mpMullion.Id;
		insert cpMullion;

		rtId = UtilityMethods.retrieveRecordTypeId(Constants.CONSTRUCTION_MATERIALS_PRODUCT_RECORD_TYPE_NAME, 'Product2');
		Product2 constructP = tUtil.createProduct('constructionMat', rtId);
		insert constructP;

		rtId = UtilityMethods.retrieveRecordTypeId(Constants.MISC_JOB_AND_UNIT_CHARGES_PRODUCT_RECORD_TYPE_NAME, 'Product2');
		Product2 miscJob = tUtil.createProduct('MiscJobcharge', rtId);
		miscJob.rSuite_Product_Type__c = 'Misc';
		insert miscJob;
		// create the pricebook entries
		Id pbId = Test.getStandardPricebookId();
		List<PricebookEntry> standardPBEList = new List<PricebookEntry>();
		PricebookEntry pbe = tUtil.createPricebookEntry(pbId, mpWindow.Id);
		standardPBEList.add(pbe);
		pbe = tUtil.createPricebookEntry(pbId, mpMullion.Id);
		standardPBEList.add(pbe);
		pbe = tUtil.createPricebookEntry(pbId, mpSpecialty.Id);
		standardPBEList.add(pbe);
		pbe = tUtil.createPricebookEntry(pbId, mpSpecialtyChord.Id);
		standardPBEList.add(pbe);
		pbe = tUtil.createPricebookEntry(pbId, cpWindow.Id);
		standardPBEList.add(pbe);
		pbe = tUtil.createPricebookEntry(pbId, cpSpecialtyChord.Id);
		standardPBEList.add(pbe);
		pbe = tUtil.createPricebookEntry(pbId, cpMullion.Id);
		standardPBEList.add(pbe);
		pbe = tUtil.createPricebookEntry(pbId, constructP.Id);
		standardPBEList.add(pbe);
		pbe = tUtil.createPricebookEntry(pbId, miscJob.Id);
		standardPBEList.add(pbe);
		insert standardPBEList;

		List<PricebookEntry> pbeList = new List<PricebookEntry>();
		pbe = tUtil.createPricebookEntry(pb.Id, mpWindow.Id);
		pbeList.add(pbe);
		pbe = tUtil.createPricebookEntry(pb.Id, mpMullion.Id);
		pbeList.add(pbe);
		pbe = tUtil.createPricebookEntry(pb.Id, mpSpecialty.Id);
		pbeList.add(pbe);
		pbe = tUtil.createPricebookEntry(pb.Id, mpSpecialtyChord.Id);
		pbeList.add(pbe);
		pbe = tUtil.createPricebookEntry(pb.Id, cpWindow.Id);
		pbeList.add(pbe);
		pbe = tUtil.createPricebookEntry(pb.Id, cpSpecialtyChord.Id);
		pbeList.add(pbe);
		pbe = tUtil.createPricebookEntry(pb.Id, cpMullion.Id);
		pbeList.add(pbe);
		pbe = tUtil.createPricebookEntry(pb.Id, constructP.Id);
		pbeList.add(pbe);
		pbe = tUtil.createPricebookEntry(pb.Id, miscJob.Id);
		pbeList.add(pbe);
		insert pbeList;
		// create the quoteline items
		List<QuoteLineItem> qliList = new List<QuoteLineItem>();

		QuoteLineItem qliAlreadySet = tUtil.createQuoteLineItem(pbeList[1].Id, null, pbeList[4].Id);
		qliList.add(qliAlreadySet);

		QuoteLineItem qliChildWindow = tUtil.createQuoteLineItem(null, null, pbeList[4].Id);
		qliList.add(qliChildWindow);
		QuoteLineItem qliChildSpecialty = tUtil.createQuoteLineItem(null, null, pbeList[5].Id);
		qliList.add(qliChildSpecialty);
		QuoteLineItem qliChildMullion = tUtil.createQuoteLineItem(null, null, pbeList[6].Id);
		qliList.add(qliChildMullion);
		QuoteLineItem qliConstruct = tUtil.createQuoteLineItem(null, null, pbeList[7].Id);
		qliList.add(qliConstruct);
		QuoteLineItem qliMiscJob = tUtil.createQuoteLineItem(null, null, pbeList[8].Id);
		qliList.add(qliMiscJob);
		// run the test
		Test.startTest();
		RMS_mobileAppRequestHelper mhelper = new RMS_mobileAppRequestHelper();
		List<QuoteLineItem> processedList = mHelper.addMasterProducts(qliList);
		Test.stopTest();
		System.assert(qliMiscJob.PricebookEntryId != null);
		System.assert(qliMiscJob.PricebookEntryId == qliMiscJob.Child_Product_Pricebook_Entry_Id__c);
		System.assert(qliConstruct.PricebookEntryId != null);
		System.assert(qliConstruct.PricebookEntryId == qliConstruct.Child_Product_Pricebook_Entry_Id__c);
		System.assert(qliChildMullion.PricebookEntryId != null);
		System.assert(qliChildMullion.PricebookEntryId == pbeList[1].Id);
		System.assert(qliChildSpecialty.PricebookEntryId != null);
		System.assert(qliChildSpecialty.PricebookEntryId == pbeList[2].Id);
		System.assert(qliChildWindow.PricebookEntryId != null);
		System.assert(qliChildWindow.PricebookEntryId == pbeList[0].Id);
		System.assert(qliAlreadySet.PricebookEntryId == pbeList[1].Id);
	}

	/* 
	 * testhandleDeletes
	 */
	static testmethod void testProcessDeletes(){
		// for this test 4 quotes are needed structured as follows
		// two with committed commiteed to saleforce and two that have not been inserted
		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;
		
		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();
		Profile p = [SELECT Id FROM Profile WHERE Name='RMS-Sales']; 
		// setup configuration stuff
		Datetime tmApptTime = Datetime.now().addDays(5);

		User u = tUtil.createUser(p.id);
		insert u;
		tUtil.createSalesAppt(u.Id, tmApptTime, false);
		// build out the container
		Account store1 = [SELECT id, Active_Store_Configuration__c FROM Account Where Name = '77 - Twin Cities, MN'][0];
		Id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        Account dwelling = [Select Id from Account where Name != 'RbA' AND Name != 'Unassigned Account' AND RecordTypeId =: dwellingRT];
		Opportunity opp = [select Id, StageName, rSuite_Id__c from Opportunity where AccountId =: dwelling.id];
		opp.StageName = 'In Progress';

		// create pricebook
		Pricebook2 pb = tutil.createPricebook2('SATestPB2', store1.Active_Store_Configuration__c);
		insert pb;

		//create existing quote
		Quote quoteToUpdate = tUtil.createQuote(opp.Id, pb.Id);
		quoteToUpdate.Name = 'quoteToUpdate';
		insert quoteToUpdate;
		Quote quoteToDelete = tUtil.createQuote(opp.Id, pb.Id);
		quoteToDelete.Name = 'quoteToDelete';
		insert quoteToDelete;
		// create new quote
		Quote quoteToInsert = tUtil.createQuote(opp.Id, pb.Id);
		quoteToInsert.Name = 'quoteToInsert';
		Quote quoteToDelete2 = tUtil.createQuote(opp.Id, pb.Id);
		quoteToDelete2.Name = 'quoteToDelete2';
		// create existing quote lines
		QuoteLineItem qli1 = tUtil.createQLIMasterChildProducts(pb.Id, quotetoUpdate.Id);
		qli1.Description = 'qliToDelete';
		qli1.UnitPrice = 30;
		insert qli1;
		QuoteLineItem qli2 = tUtil.createQLIMasterChildProducts(pb.Id, quotetoUpdate.Id);
		qli2.Description = 'qliToRemain';
		insert qli2;
		QuoteLineItem qli21 = tUtil.createQLIMasterChildProducts(pb.Id, quoteToDelete.Id);
		qli21.Description = 'QLIShouldBeDeleted';
		qli21.UnitPrice = 30;
		insert qli21;
		QuoteLineItem qli22 = tUtil.createQLIMasterChildProducts(pb.Id, quoteToDelete.Id);
		qli22.Description = 'QLIShouldBeDeleted';
		insert qli22;
		// creete quote lines to insert - as they would come in from rSuite - with a child product set but not the master
		QuoteLineItem qli3 = tUtil.createQLIMasterChildProducts(pb.Id, quoteToInsert.Id);
		qli3.PricebookEntryId = null;
		qli3.Description = 'qliToDeleteFromInsert';
		qli3.UnitPrice = 30;
		QuoteLineItem qli4 = tUtil.createQLIMasterChildProducts(pb.Id, quoteToInsert.Id);
		qli4.Description = 'qliToInsert';
		qli4.PricebookEntryId = null;
		QuoteLineItem qli23 = tUtil.createQLIMasterChildProducts(pb.Id, quoteToDelete2.Id);
		qli23.Description = 'qliNeverInserted';
		qli23.UnitPrice = 30;
		qli23.PricebookEntryId = null;
		QuoteLineItem qli24 = tUtil.createQLIMasterChildProducts(pb.Id, quoteToDelete2.Id);
		qli24.Description = 'qliNeverInserted';
		qli24.PricebookEntryId = null;
		// create quote financing
		Quote_Financing__c qf1 = tUtil.createQuoteFinancing(store1.Active_Store_Configuration__c, quotetoUpdate.Id);
		insert qf1;
		Quote_Financing__c qf2 = tUtil.createQuoteFinancing(store1.Active_Store_Configuration__c, quotetoUpdate.Id);
		qf2.Amount_Financed__c = 4;
		insert qf2; // this one will be deleted
		Quote_Financing__c qf3 = tUtil.createQuoteFinancing(store1.Active_Store_Configuration__c, quoteToDelete.Id);
		insert qf3;  // this one will be deleted by cascading delete
		Quote_Financing__c qf4 = tUtil.createQuoteFinancing(store1.Active_Store_Configuration__c, quoteToDelete.Id);
		insert qf4;  // this one will be deleted by cascading delete
		Quote_Financing__c qf5 = tUtil.createQuoteFinancing(store1.Active_Store_Configuration__c, quoteToInsert.Id);
		Quote_Financing__c qf6 = tUtil.createQuoteFinancing(store1.Active_Store_Configuration__c, quoteToInsert.Id);
		qf6.Amount_Financed__c = 4; // this one will never be inserted
		// these two should never be inserted because of a cascading delete
		Quote_Financing__c qf7 = tUtil.createQuoteFinancing(store1.Active_Store_Configuration__c, quoteToDelete2.Id);
		Quote_Financing__c qf8 = tUtil.createQuoteFinancing(store1.Active_Store_Configuration__c, quoteToDelete2.Id);

		// create quote discounts
		Quote_Discount__c qd1 = tUtil.createQuoteDiscount(store1.Active_Store_Configuration__c, quotetoUpdate.Id);
		insert qd1;
		Quote_Discount__c qd2 = tUtil.createQuoteDiscount(store1.Active_Store_Configuration__c, quotetoUpdate.Id);
		qd2.Discount_Amount__c = 4;
		insert qd2; // this one will be deleted
		Quote_Discount__c qd3 = tUtil.createQuoteDiscount(store1.Active_Store_Configuration__c, quoteToDelete.Id);
		insert qd3; // this one will be deleted by cascading delete
		Quote_Discount__c qd4 = tUtil.createQuoteDiscount(store1.Active_Store_Configuration__c, quoteToDelete.Id);
		insert qd4; // this one will be deleted by cascading delete
		Quote_Discount__c qd5 = tUtil.createQuoteDiscount(store1.Active_Store_Configuration__c, quoteToInsert.Id);
		Quote_Discount__c qd6 = tUtil.createQuoteDiscount(store1.Active_Store_Configuration__c, quoteToInsert.Id);
		qd6.Discount_Amount__c = 4; // this one will not be inserted
		// these two should never be inserted because of a cascading delete
		Quote_Discount__c qd7 = tUtil.createQuoteDiscount(store1.Active_Store_Configuration__c, quoteToDelete2.Id);
		Quote_Discount__c qd8 = tUtil.createQuoteDiscount(store1.Active_Store_Configuration__c, quoteToDelete2.Id);



		RMS_mobileAppRequestHelper.QuoteContainer quoteContainer = new RMS_mobileAppRequestHelper.QuoteContainer();
		quoteContainer.aQuote = quoteToUpdate;
		quoteContainer.quoteLineItems = new List<QuoteLineItem>();
		quoteContainer.quoteLineItems.add(qli1);
		quoteContainer.quoteLineItems.add(qli2);
		quoteContainer.quoteDiscountList = new List<Quote_Discount__c>();
		quoteContainer.quoteDiscountList.add(qd1);
		quoteContainer.quoteDiscountList.add(qd2);
		quoteContainer.quoteFinancingList = new List<Quote_Financing__c>();
		quoteContainer.quoteFinancingList.add(qf1);
		quoteContainer.quoteFinancingList.add(qf2);

		RMS_mobileAppRequestHelper.QuoteContainer quoteContainerDelete = new RMS_mobileAppRequestHelper.QuoteContainer();
		quoteContainerDelete.aQuote = quoteToDelete;
		quoteContainerDelete.quoteLineItems = new List<QuoteLineItem>();
		quoteContainerDelete.quoteLineItems.add(qli21);
		quoteContainerDelete.quoteLineItems.add(qli22);
		quoteContainerDelete.quoteDiscountList = new List<Quote_Discount__c>();
		quoteContainerDelete.quoteDiscountList.add(qd3);
		quoteContainerDelete.quoteDiscountList.add(qd4);
		quoteContainerDelete.quoteFinancingList = new List<Quote_Financing__c>();
		quoteContainerDelete.quoteFinancingList.add(qf3);
		quoteContainerDelete.quoteFinancingList.add(qf4);

		RMS_mobileAppRequestHelper.QuoteContainer quoteContainerInsert = new RMS_mobileAppRequestHelper.QuoteContainer();
		quoteContainerInsert.aQuote = quoteToInsert;
		quoteContainerInsert.quoteLineItems = new List<QuoteLineItem>();
		quoteContainerInsert.quoteLineItems.add(qli3);
		quoteContainerInsert.quoteLineItems.add(qli4);
		quoteContainerInsert.quoteDiscountList = new List<Quote_Discount__c>();
		quoteContainerInsert.quoteDiscountList.add(qd5);
		quoteContainerInsert.quoteDiscountList.add(qd6);
		quoteContainerInsert.quoteFinancingList = new List<Quote_Financing__c>();
		quoteContainerInsert.quoteFinancingList.add(qf5);
		quoteContainerInsert.quoteFinancingList.add(qf6);

		RMS_mobileAppRequestHelper.QuoteContainer quoteContainerDelete2 = new RMS_mobileAppRequestHelper.QuoteContainer();
		quoteContainerDelete2.aQuote = quoteToDelete2;
		quoteContainerDelete2.quoteLineItems = new List<QuoteLineItem>();
		quoteContainerDelete2.quoteLineItems.add(qli23);
		quoteContainerDelete2.quoteLineItems.add(qli24);
		quoteContainerDelete2.quoteDiscountList = new List<Quote_Discount__c>();
		quoteContainerDelete2.quoteDiscountList.add(qd7);
		quoteContainerDelete2.quoteDiscountList.add(qd8);
		quoteContainerDelete2.quoteFinancingList = new List<Quote_Financing__c>();
		quoteContainerDelete2.quoteFinancingList.add(qf7);
		quoteContainerDelete2.quoteFinancingList.add(qf8);

		RMS_mobileAppRequestHelper.OpportunityContainer oppContainer = new RMS_mobileAppRequestHelper.OpportunityContainer();
		oppContainer.oppty = opp;
		oppContainer.quoteContainerList = new List<RMS_mobileAppRequestHelper.QuoteContainer>{quoteContainer, quoteContainerDelete, quoteContainerInsert, quoteContainerDelete2};
		RMS_mobileAppRequestHelper.SalesAppointment salesAppt = new RMS_mobileAppRequestHelper.SalesAppointment();
		salesAppt.account = dwelling;
		salesAppt.opptyContainer = oppContainer;
		
		String jsonInput = JSON.serialize(salesAppt);
		// add the isDeleted = true to the quotes
		jsonInput = jsonInput.replace('"Name":"quoteToDelete"','"IsDeleted":true,"Name":"quoteToDelete"');
		jsonInput = jsonInput.replace('"Name":"quoteToDelete2"','"IsDeleted":true,"Name":"quoteToDelete2"');
		jsonInput = jsonInput.replace('"Description":"qliToDelete"','"IsDeleted":true,"Description":"qliToDelete"');
		jsonInput = jsonInput.replace('"Description":"qliToDeleteFromInsert"','"IsDeleted":true,"Description":"qliToDeleteFromInsert"');
		jsonInput = jsonInput.replace('"Discount_Amount__c":4','"IsDeleted":true,"Discount_Amount__c":4');
		jsonInput = jsonInput.replace('"Amount_Financed__c":4','"IsDeleted":true,"Amount_Financed__c":4');
System.debug('###################################### Input: ' + jsonInput);
		RMS_mobileAppRequestHelper.SalesAppointment appt = (RMS_mobileAppRequestHelper.SalesAppointment)JSON.deserialize(jsonInput, RMS_mobileAppRequestHelper.SalesAppointment.class);

        System.runAs(u) {
			Test.startTest();
			// test processing of deletes
        	RMS_mobileAppRequestHelper mHelper = new RMS_mobileAppRequestHelper();
			RMS_mobileAppRequestHelper.SalesAppointment processedAppt = mHelper.processDeletes(appt);
			List<Quote> remainingQuotes = [select Id, Name, OpportunityId from Quote where OpportunityId = :opp.Id];
			System.assert(remainingQuotes.size() == 1);
			List<QuoteLineItem> remainingQLI = [select Id, Description, QuoteId from QuoteLineItem where QuoteId in :remainingQuotes];
			System.assert(remainingQLI.size() == 1);
			List<Quote_Discount__c> remainingQD = [select Id, Name, Quote__c from Quote_Discount__c where Quote__c in :remainingQuotes];
			System.assert(remainingQD.size() == 1);
			List<Quote_Financing__c> remainingQF = [select Id, Name, Related_Quote__c from Quote_Financing__c where Related_Quote__c in :remainingQuotes];
			System.assert(remainingQF.size() == 1);
			System.assert(processedAppt.opptyContainer.quoteContainerList.size() == 2);
			System.assert(processedAppt.opptyContainer.quoteContainerList[0].quoteLineItems.size() == 1);
			System.assert(processedAppt.opptyContainer.quoteContainerList[0].quoteDiscountList.size() == 1);
			System.assert(processedAppt.opptyContainer.quoteContainerList[0].quoteFinancingList.size() == 1);
			System.assert(processedAppt.opptyContainer.quoteContainerList[1].quoteLineItems.size() == 1);
			System.assert(processedAppt.opptyContainer.quoteContainerList[1].quoteDiscountList.size() == 1);
			System.assert(processedAppt.opptyContainer.quoteContainerList[1].quoteFinancingList.size() == 1);
			if (processedAppt.opptyContainer.quoteContainerList[0].aQuote.Id == null) {
				System.assert(processedAppt.opptyContainer.quoteContainerList[0].quoteLineItems[0].Description.equals('qliToInsert'));
				System.assert(processedAppt.opptyContainer.quoteContainerList[0].aQuote.Name.equals('quoteToInsert'));
				System.assert(processedAppt.opptyContainer.quoteContainerList[1].quoteLineItems[0].Description.equals('qliToRemain'));
				System.assert(processedAppt.opptyContainer.quoteContainerList[1].aQuote.Name.equals('quoteToUpdate'));
			} else {
				System.assert(processedAppt.opptyContainer.quoteContainerList[1].quoteLineItems[0].Description.equals('qliToInsert'));
				System.assert(processedAppt.opptyContainer.quoteContainerList[1].aQuote.Name.equals('quoteToInsert'));
				System.assert(processedAppt.opptyContainer.quoteContainerList[0].quoteLineItems[0].Description.equals('qliToRemain'));
				System.assert(processedAppt.opptyContainer.quoteContainerList[0].aQuote.Name.equals('quoteToUpdate'));
			}
			//make sure that the saving of quotes and quoteline items still works as well
			processedAppt = mHelper.saveQuotes(processedAppt);
			processedAppt = mHelper.saveQuoteLineItemsDiscountsandFinancing(processedAppt);
			Test.stopTest();
System.debug('###########################: ' + processedAppt);
			remainingQuotes = [select Id, Name, OpportunityId from Quote where OpportunityId = :opp.Id];
System.debug('###########################: ' + remainingQuotes);
			System.assert(remainingQuotes.size() == 2);
			remainingQLI = [select Id, Description, QuoteId from QuoteLineItem where QuoteId in :remainingQuotes];
System.debug('###########################: ' + remainingQLI);
			System.assert(remainingQLI.size() == 2);
        }
	}

	/* 
	 * testCustomerSearch
	 */
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

	/* 
	 * testGetSelectedSearchResults
	 */
	static testmethod void testGetSelectedSearchResults(){

		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();

		Test.startTest();
		Account dwelling = utility.createDwellingAccount('Dwelling Account');

		Account store = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
		dwelling.Store_Location__c = store.Id;
		insert dwelling;
		Opportunity opp = utility.createOpportunity(dwelling.Id, 'New');	
		Opportunity opp2 = utility.createOpportunity(dwelling.Id, 'New');	
		update dwelling;
		List<Opportunity> oppsToInsert = new List<Opportunity>();
		opp.CloseDate = System.Today().addDays(1);
		opp2.CloseDate = System.Today().addDays(1);
		oppsToInsert.add(opp);
		oppsToInsert.add(opp2);
		insert oppsToInsert;

		Order order1 = new Order(   Name='Sold Order 1', 
									AccountId = dwelling.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store.Id,
									OpportunityId = opp.Id,									 
									Status ='Draft', 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;


		List<Event> eventsToInsert = new List<Event>();
		Event event = new Event(WhatID = opp.Id,DurationInMinutes = 15, IsAllDayEvent = false, ActivityDateTime = System.now());
		eventsToInsert.add(event);
		Event event2 = new Event(WhatID = opp2.Id,DurationInMinutes = 15, IsAllDayEvent = false, ActivityDateTime = System.now());
		eventsToInsert.add(event2);
		insert eventsToInsert;
		RMS_mobileAppRequestHelper helper = new RMS_mobileAppRequestHelper();
		List<Id> opportunityIDs = new List<ID>{opp.Id, opp2.Id};
		String JSONResponse = helper.getSelectedSearchResults(JSON.serialize(opportunityIDs));
	   	RMS_mobileAppRequestHelper.Appointments apptContainer = (RMS_mobileAppRequestHelper.Appointments)JSON.deserialize(JSONResponse, RMS_mobileAppRequestHelper.Appointments.class);
	   	System.assertEquals(apptContainer.getErrors().size(),0);
	   	System.assertEquals(apptContainer.salesAppts.size(),2);
	   	System.assertEquals(apptContainer.salesAppts[0].event.Id, event.Id);
		Test.stopTest();
	}


	/* 
	 * testSaveTechMeasure
	 */
	static testmethod void testSaveTechMeasure(){
		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;

		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();
		Profile p = [SELECT Id FROM Profile WHERE Name='RMS-Field Service']; 

		Datetime newApptTime = Datetime.now().addDays(1);
		Datetime tmApptTime = Datetime.now().addDays(5);

		User u = tUtil.createUser(p.id);
		insert u;

		tUtil.createTMAppt(u.Id, tmApptTime);
		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        Account dwelling = [Select Id from Account where OwnerId = :u.Id AND RecordTypeId =: dwellingRT];
		Opportunity opp = [select Id, StageName from Opportunity where AccountId =: dwelling.id];
		opp.StageName = 'Measured';

		Order ord1 = [Select Id, Status, rSuite_Id__c from Order where OpportunityID =: opp.Id];
		ord1.Status = 'Ready to Order';
		List<RbA_Work_Order__c> workOrder = [SELECT Id FROM RbA_Work_Order__c  WHERE Opportunity__c = :opp.id AND Sold_Order__c = :ord1.id];
		workOrder[0].Work_Order_Status__c = 'Scheduled';
		OrderItem oiToUpdate = [select Id, Quantity, PricebookEntryId, PricebookEntry.Pricebook2Id from OrderItem where OrderId = :ord1.Id limit 1];
		oiToUpdate.Quantity =1;

		PricebookEntry cpbe = [select id, Name from PricebookEntry where Product2.RecordType.DeveloperName = 'Child_Product' and Pricebook2Id = :oiToUpdate.PricebookEntry.Pricebook2Id limit 1];
		PricebookEntry mpbe = [select id, Name from PricebookEntry where Product2.RecordType.DeveloperName = 'Master_Product' and Pricebook2Id = :oiToUpdate.PricebookEntry.Pricebook2Id limit 1];
		OrderItem oiToInsert = new OrderItem(OrderId = ord1.Id, PricebookentryId = mpbe.Id, Child_Product_Pricebook_Entry_Id__c=cpbe.Id, Quantity = 10, UnitPrice = 10 );
		// create an existing tm offset
		TM_OffSet__C tmOffsetToUpdate = new TM_OffSet__C(Order_Line__c = oiToUpdate.Id,Description__c = 'New Description', Measurement__c = 1 );
		insert tmOffsetToUpdate;
		tmOffsetToUpdate.Description__c = 'Updated Description';
		// create a new TM offset
		TM_OffSet__c tmOffsetToInsert = new TM_Offset__C(Order_Line__c = oiToUpdate.Id,Description__c = 'Insert Description TMO', Measurement__c = 2 );


		RMS_mobileAppRequestHelper.OrderItemContainer oiContainerUpdate = new RMS_mobileAppRequestHelper.OrderItemContainer();
		oiContainerUpdate.oi = oiToUpdate;
		oiContainerUpdate.tmOffSetList = new List<TM_Offset__C>{tmOffsetToUpdate,tmOffsetToInsert};
		RMS_mobileAppRequestHelper.OrderItemContainer oiContainerInsert = new RMS_mobileAppRequestHelper.OrderItemContainer();
		oiContainerInsert.oi = oiToInsert;
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

        System.runAs(u) {
        	RMS_mobileAppRequestHelper helper = new RMS_mobileAppRequestHelper();
			String input = JSON.serialize(tmApptUpdate);
			System.debug('################ - the JSON:' + input);
			Test.startTest();
			String result = helper.saveTechMeasure(input);
			Test.StopTest();
			System.debug('###########: ' + result);

			//Assert Opportunity Status is updated
			Opportunity updatedOpp = [Select Id, Name, isWon, isClosed, StageName from Opportunity where Id =: opp.Id];
			System.debug('############### opp = ' + opp); 
			System.debug('############### updateOpp = ' + updatedOpp); 
			System.assertEquals(updatedOpp.StageName,'Measured');
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

	/* 
	 * testSaveQuotes
	 */
	static testmethod void testSaveQuotes(){

		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();
		Profile p = [SELECT Id FROM Profile WHERE Name='RMS-Sales']; 

		Datetime newApptTime = Datetime.now().addDays(1);
		Datetime tmApptTime = Datetime.now().addDays(5);

		User u = tUtil.createUser(p.id);
		insert u;

		tUtil.createSalesAppt(u.Id, newApptTime, false);
		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        Account dwelling = [Select Id from Account where Name != 'RbA' AND Name != 'Unassigned Account' AND RecordTypeId =: dwellingRT];
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

        System.runAs(u) {
        	Test.StartTest();
        	RMS_mobileAppRequestHelper helper = new RMS_mobileAppRequestHelper();
			helper.saveQuotes(salesAppt);
			Test.StopTest();

			//Assert Quote Description field is updated
			quoteToUpdate = [SELECT Description from Quote where Id =: quoteToUpdate.Id];
			System.assertEquals(quoteToUpdate.Description, 'UPDATED DESCRIPTION');
			//Assert quoteToInsert is inserted
			System.assert(quoteToInsert.Id != null);
        }
	
	}

	/* 
	 * testSaveQuotesNoQuotes
	 */
	static testmethod void testSaveQuotesNoQuotes(){

		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();
		Profile p = [SELECT Id FROM Profile WHERE Name='RMS-Sales']; 

		Datetime newApptTime = Datetime.now().addDays(1);

		User u = tUtil.createUser(p.id);
		insert u;

		tUtil.createSalesAppt(u.Id, newApptTime, false);
		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        Account dwelling = [Select Id from Account where Name != 'RbA' AND Name != 'Unassigned Account' AND RecordTypeId =: dwellingRT];
		Opportunity opp = [select Id, StageName from Opportunity where AccountId =: dwelling.id];
		opp.StageName = 'Sold';

		RMS_mobileAppRequestHelper.OpportunityContainer oppContainer = new RMS_mobileAppRequestHelper.OpportunityContainer();
		oppContainer.oppty = opp;
		oppContainer.quoteContainerList = new List<RMS_mobileAppRequestHelper.QuoteContainer>();
		RMS_mobileAppRequestHelper.SalesAppointment salesAppt = new RMS_mobileAppRequestHelper.SalesAppointment();
		salesAppt.account = dwelling;
		salesAppt.opptyContainer = oppContainer;

        System.runAs(u) {
        	Test.StartTest();
        	RMS_mobileAppRequestHelper helper = new RMS_mobileAppRequestHelper();
			try {
				helper.saveQuotes(salesAppt);
				// should throw exception should not hit next line
				System.assert(false);
			} catch (RMS_mobileAppRequestHelper.NoQuotesException e) {
				// should throw this exception
				System.assert(true);	
			} catch (Exception e) {
				// should not throw a different exception
				System.assert(false);
			}
			Test.StopTest();
        }
	}

	/* 
	 * testSaveQuoteLineItemsDiscountsandFinancing
	 */
	static testmethod void testSaveQuoteLineItemsDiscountsandFinancing(){

		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;

		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();
		Profile p = [SELECT Id FROM Profile WHERE Name='RMS-Sales']; 

		Datetime newApptTime = Datetime.now().addDays(1);
		Datetime tmApptTime = Datetime.now().addDays(5);

		User u = tUtil.createUser(p.id);
		insert u;

		tUtil.createSalesAppt(u.Id, newApptTime, false);

		Account store1 = [SELECT id, Name, Active_Store_Configuration__c FROM Account Where Name = '77 - Twin Cities, MN'][0];
		Account dwelling1 = tUtil.createDwellingAccount('456');
		dwelling1.Store_Location__c = store1.id;
		dwelling1.OwnerId = u.Id;
		insert dwelling1;

		List<SObject> itemsToInsert = new List<SObject>();		
		
		Opportunity opp1 = tutil.createOpportunity('TMAppt',dwelling1.id, 'New', u.Id);
		opp1.OwnerId = u.Id;
		itemsToInsert.add(opp1);
		// create the store discounts
		Store_Discount__c storeDiscount1 = new Store_Discount__c();
		storeDiscount1.Store_Configuration__c = store1.Active_Store_Configuration__c;
		storeDiscount1.Active__c = true;
		itemsToInsert.add(storeDiscount1);
		// create the store finance programs
		Store_Finance_Program__c storeFinance = new Store_Finance_Program__c(Store_Configuration__c = store1.Active_Store_Configuration__c, Active__c = true);
		itemsToInsert.add(storeFinance);

		insert itemsToInsert;
		//clean out the list
		itemsToInsert.clear();
		
		Pricebook2 pb = tutil.createPricebook2('saveQuoteTest', store1.Active_Store_Configuration__c);
		itemsToInsert.add(pb);
		insert itemsToInsert;
		itemsToInsert.clear();

		Quote quote1 = tutil.createQuote(opp1.id, pb.Id);
		quote1.isSold__c = true;
		itemsToInsert.add(quote1);
		insert itemsToInsert;
		//clean out the list
		itemsToInsert.clear();
			
		// qli to update
		QuoteLineItem qli1 = tutil.createQLIMasterChildProducts(pb.Id, quote1.Id);
		qli1.Description = 'original description';
		itemsToInsert.add(qli1);
		// qli to insert
		QuoteLineItem qli2 = tutil.createQLIMasterChildProducts(pb.Id, quote1.Id);
		qli2.PricebookEntryId = null;
		System.assert(qli2.Id == null);

		// qd to update
		Quote_Discount__c discountToUpdate = new Quote_Discount__c(Quote__c = quote1.Id, Store_Discount__c = storeDiscount1.Id);
		itemsToInsert.add(discountToUpdate);
		// qd to insert
		Quote_Discount__c discountToInsert = new Quote_Discount__c(Quote__c = quote1.Id, Store_Discount__c = storeDiscount1.Id);

		// qf to update
		Quote_Financing__c financeToUpdate = new Quote_Financing__c(Related_Quote__c = quote1.Id, Store_Finance_Program__c = storeFinance.Id);
		itemsToInsert.add(financeToUpdate);
		// qf to insert
		Quote_Financing__c financeToInsert = new Quote_Financing__c(Related_Quote__c = quote1.Id, Store_Finance_Program__c = storeFinance.Id);

		insert itemsToInsert;
		//clean out the list
		itemsToInsert.clear();
		// updates
		opp1.StageName = 'Sold';
		qli1.Description = 'UPDATED QLI DESCRIPTION';
		discountToUpdate.Status__c = 'Cancelled';
		financeToUpdate.Program_Rate__c = 20;

		RMS_mobileAppRequestHelper.QuoteContainer quoteContainer = new RMS_mobileAppRequestHelper.QuoteContainer();
		quoteContainer.aQuote = quote1;
		quoteContainer.quoteLineItems = new List<QuoteLineItem>{qli1,qli2};
		quoteContainer.quoteDiscountList = new List<Quote_Discount__c>{discountToUpdate,discountToInsert};
		quoteContainer.quoteFinancingList = new List<Quote_Financing__c>{financeToUpdate,financeToInsert};
		RMS_mobileAppRequestHelper.OpportunityContainer oppContainer = new RMS_mobileAppRequestHelper.OpportunityContainer();
		oppContainer.oppty = opp1;
		oppContainer.quoteContainerList = new List<RMS_mobileAppRequestHelper.QuoteContainer>{quoteContainer};
		RMS_mobileAppRequestHelper.SalesAppointment salesAppt = new RMS_mobileAppRequestHelper.SalesAppointment();
		salesAppt.opptyContainer = oppContainer;

        System.runAs(u) {
        	Test.StartTest();
        	RMS_mobileAppRequestHelper helper = new RMS_mobileAppRequestHelper();
			helper.saveQuoteLineItemsDiscountsandFinancing(salesAppt);
			Test.StopTest();

			//Assert Quote Line Items are Upserted
			QuoteLineItem lineItemUpdated = [SELECT Description from QuoteLineItem where Id =: qli1.Id];
			System.assertEquals(lineItemUpdated.Description, 'UPDATED QLI DESCRIPTION');
			System.assert(qli2.Id != null);

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

	/* 
	 * Cancel Order Test
	 */
	static testmethod void testCancelOrderNoOrder(){
		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;

		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();
		Profile p = [SELECT Id FROM Profile WHERE Name='RMS-Sales']; 

		Datetime newApptTime = Datetime.now().addDays(1);
		Datetime tmApptTime = Datetime.now().addDays(5);

		User u = tUtil.createUser(p.id);
		insert u;

       Test.StartTest();
        // create a sales appt without an order
		tUtil.createSalesAppt(u.Id, newApptTime, false);
 
		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        List<Account> dwelling = [Select Id, Name from Account where Name like '%22' AND RecordTypeId =: dwellingRT];
		Opportunity opp = [select Id, StageName, Store_Location__c from Opportunity where AccountId =: dwelling[0].id];

       System.runAs(u) {
			// Instantiate the mobileapp helper and call the cancelOrder method passing the
			// opportunity id
			RMS_mobileAppRequestHelper helper = new RMS_mobileAppRequestHelper();
			List<Id> opportunityIDs = new List<ID>{opp.Id};
			String JSONResponse = helper.cancelOrder(JSON.serialize(opportunityIDs));

			// Retrieve the Appointment container from the JSON response
	   		RMS_mobileAppRequestHelper.Appointments apptContainer = (RMS_mobileAppRequestHelper.Appointments)JSON.deserialize(JSONResponse, RMS_mobileAppRequestHelper.Appointments.class);

			// do an assertion that there was one error since there is no order to cancel
	   		System.assert(apptContainer.getErrors()[0].contains('Order could not be found.'));
	   		System.assertEquals(1, apptContainer.getErrors().size());
        }
		Test.StopTest();
	}

	/*
	 * testCancelOrderMultipleOrders
	 */
	static testmethod void testCancelOrderMultipleOrders(){

		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;

		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigs();
		Profile p = [SELECT Id FROM Profile WHERE Name='RMS-Sales']; 

		Datetime newApptTime = Datetime.now().addDays(1);
		Datetime tmApptTime = Datetime.now().addDays(5);

		User u = tUtil.createUser(p.id);
		insert u;

		tUtil.createSalesAppt(u.Id, newApptTime, false);
 
		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        List<Account> dwelling = [Select Id, Name from Account where Name like '%22' AND RecordTypeId =: dwellingRT];
		Opportunity opp = [select Id, StageName, Store_Location__c from Opportunity where AccountId =: dwelling[0].id];

		Order order1 = new Order(   Name='Sold Order 1', 
									AccountId = dwelling[0].id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = opp.Store_Location__c,
									OpportunityId = opp.Id,									 
									Status ='Draft', 
									Pricebook2Id = Test.getStandardPricebookId(),
									OwnerId = u.Id
								);
		Order order2 = new Order(   Name='Sold Order 1', 
									AccountId = dwelling[0].id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = opp.Store_Location__c,
									OpportunityId = opp.Id,									 
									Status ='Draft', 
									Pricebook2Id = Test.getStandardPricebookId(),
									OwnerId = u.Id
								);
		insert new List<Order>{order1,order2};
        Test.StartTest();

        System.runAs(u) {
			// Instantiate the mobileapp helper and call the cancelOrder method passing the
			// opportunity id
			RMS_mobileAppRequestHelper helper = new RMS_mobileAppRequestHelper();
			List<Id> opportunityIDs = new List<ID>{opp.Id};
			String JSONResponse = helper.cancelOrder(JSON.serialize(opportunityIDs));

			// Retrieve the Appointment container from the JSON response
	   		RMS_mobileAppRequestHelper.Appointments apptContainer = (RMS_mobileAppRequestHelper.Appointments)JSON.deserialize(JSONResponse, RMS_mobileAppRequestHelper.Appointments.class);

			// Assert that there was one error since there were multiple orders
	   		System.assertEquals(1, apptContainer.getErrors().size());
	   		System.debug('##########: ' + apptContainer.getErrors());
	   		System.assert(apptContainer.getErrors()[0].contains('More than one order is linked to this opportunity.'));
        }
		Test.StopTest();
	}

	/* 
	 * testCancelOrderNoEligibleOrder
	 */
	static testmethod void testCancelOrderNoEligibleOrder(){

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

        Test.StartTest();
		tUtil.createSalesAppt(u.Id, newApptTime, false);
 
		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        List<Account> dwelling = [Select Id, Name from Account where Name like '%22' AND RecordTypeId =: dwellingRT];
		Opportunity opp = [select Id, StageName, Store_Location__c from Opportunity where AccountId =: dwelling[0].id];

		Order order1 = new Order(   Name='Sold Order 1', 
									AccountId = dwelling[0].id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = opp.Store_Location__c,
									OpportunityId = opp.Id,									 
									Status ='Install Complete', 
									Pricebook2Id = Test.getStandardPricebookId(),
									OwnerId = u.Id
								);
		insert new List<Order>{order1};

        System.runAs(u) {
			// Instantiate the mobileapp helper and call the cancelOrder method passing the
			// opportunity id
			RMS_mobileAppRequestHelper helper = new RMS_mobileAppRequestHelper();
			List<Id> opportunityIDs = new List<ID>{opp.Id};
			String JSONResponse = helper.cancelOrder(JSON.serialize(opportunityIDs));

			// Retrieve the Appointment container from the JSON response
	   		RMS_mobileAppRequestHelper.Appointments apptContainer = (RMS_mobileAppRequestHelper.Appointments)JSON.deserialize(JSONResponse, RMS_mobileAppRequestHelper.Appointments.class);

			// do an assertion that there was one error since there were multiple orders
	   		System.assertEquals(1, apptContainer.getErrors().size());
	   		System.assert(apptContainer.getErrors()[0].contains('Order is not cancellable.'));
        }
		Test.StopTest();
	}


	/* 
	 * testCancelOrderNoEligibleOrder
	 */
	static testmethod void testCancelOrderEligible(){

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

		tUtil.createSalesAppt(u.Id, newApptTime, true);
 
		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        List<Account> dwelling = [Select Id, Name from Account where Name like '%22' AND RecordTypeId =: dwellingRT];
		Opportunity opp = [select Id, StageName from Opportunity where AccountId =: dwelling[0].id];
		Quote quote = [SELECT Id, OpportunityId FROM Quote WHERE OpportunityId =: opp.Id];

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

		Store_Finance_Program__c storeFinance = new Store_Finance_Program__c(Store_Configuration__c = myStore.Active_Store_Configuration__c, Active__c = true);
		insert storeFinance;

		Quote_Financing__c financeToUpdate = new Quote_Financing__c(Related_Quote__c = quote.Id, Store_Finance_Program__c = storeFinance.Id);
		insert financeToUpdate;

		Order order1 = [SELECT Id FROM Order WHERE OpportunityId = :opp.id limit 1];

        System.runAs(u) {
			Test.StartTest();
			// Instantiate the mobileapp helper and call the cancelOrder method passing the
			// opportunity id
			RMS_mobileAppRequestHelper helper = new RMS_mobileAppRequestHelper();
			List<Id> opportunityIDs = new List<ID>{opp.Id};
			String JSONResponse = helper.cancelOrder(JSON.serialize(opportunityIDs));

			// First verify the results in the json response
			
			// Retrieve the Appointment container from the JSON response
	   		RMS_mobileAppRequestHelper.Appointments apptContainer = (RMS_mobileAppRequestHelper.Appointments)JSON.deserialize(JSONResponse, RMS_mobileAppRequestHelper.Appointments.class);

			// Assert that there were no errors and one sales appt
	   		System.assertEquals(0, apptContainer.getErrors().size());
	   		System.assertEquals(1, apptContainer.salesAppts.size());
	   		
	   		RMS_mobileAppRequestHelper.SalesAppointment salesApptContainer = apptContainer.salesAppts[0];
	   		RMS_mobileAppRequestHelper.OpportunityContainer oppContainer = salesApptContainer.opptyContainer;

			// Assert that there is one quote within the opportunity container
	   		System.assertEquals(1, oppContainer.quoteContainerList.size());

			// Assert that there is no orders within the opp container since it is now pending cancellation
	   		RMS_mobileAppRequestHelper.OrderContainer ordContainer = oppContainer.anOrderContainer;
	   		System.assertEquals(null, ordContainer);

			// Assert that there is one line item, discount, and financing
	   		RMS_mobileAppRequestHelper.QuoteContainer quotContainer = oppContainer.quoteContainerList[0];
	   		System.assertEquals(1, quotContainer.quoteLineItems.size());
	   		System.assertEquals(1, quotContainer.quoteDiscountList.size());
	   		System.assertEquals(1, quotContainer.quoteFinancingList.size());	   		

			Test.StopTest();
			// Now verify the results in the database
			
			// Retrieve the quotes
			List<Quote> quoteResults = [SELECT Id, isSold__c, Status, Opportunity.StageName from Quote ];
			// Assert there are 2 quotes
			System.AssertEquals(2, quoteResults.size());
			
			integer oldcount = 0;
			integer newcount = 0;
			
			for (Quote qr : quoteResults) {
				if (qr.isSold__c == false && qr.Status == 'Cancelled' && qr.Opportunity.StageName == 'Quoted')
					oldCount =+ 1;
				if (qr.isSold__c == false && qr.Status == 'Pending Cancellation' && qr.Opportunity.StageName == 'Quoted')
					newCount =+ 1;
			}
			// Assert there are 1 quote is cancelled and 1 quote is pending cancellation
			System.AssertEquals(1, oldCount);
			System.AssertEquals(1, newCount);

			List<QuoteLineItem> quoteLineItemsResults = [SELECT Id, QuoteId from QuoteLineItem ];
			//Assert there are two quote line items in the system
			System.AssertEquals(2, quoteLineItemsResults.size());
			//Assert the old quote and new quote reference are not equal
			System.Assert(quoteLineItemsResults[0].QuoteId != quoteLineItemsResults[1].QuoteId);

			List<Quote_Financing__c> quoteFinancingResults = [SELECT Id, Related_Quote__c from Quote_Financing__c ];
			//Assert there are two quote financing records in the system
			System.AssertEquals(2, quoteFinancingResults.size());
			//Assert the old quote and new quote reference are not equal
			System.Assert(quoteFinancingResults[0].Related_Quote__c != quoteFinancingResults[1].Related_Quote__c);

			List<Quote_Discount__c> quoteDiscountResults = [SELECT Id, Quote__c from Quote_Discount__c ];
			//Assert there are two quote discount records in the system
			System.AssertEquals(2, quoteDiscountResults.size());
			//Assert the old quote and new quote reference are not equal
			System.Assert(quoteDiscountResults[0].Quote__c != quoteDiscountResults[1].Quote__c);

			List<Order> orderResults = [SELECT Id, Status from Order ];
			//Assert there is one order record in the system
			System.AssertEquals(1, orderResults.size());
			//Assert the order is set to Pending Cancellation
			System.AssertEquals('Pending Cancellation', orderResults[0].Status);
        }
	}
}
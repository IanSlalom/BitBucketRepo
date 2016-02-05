/*
 *@class	RMS_mobileAppRequestHelper
 *@brief	Help class for handling api call business logic
 *@author  Anthony Strafaccia (Slalom.ADS)
 *@author  Mark Wochnick (Slalom.MAW)
 *@version	2015-09/16  Slalom.ADS	Created.
 *@version	2015-10/12  Slalom.MAW
 *@copyright  (c)2015 Slalom.  All Rights Reserved.	Unauthorized use is prohibited.
 */

public with sharing class RMS_mobileAppRequestHelper {

	/* @method: findAppointments(Id userId)
	 * @param: Id userId - user who the appointements are assigned to
	 * @param: Datatime afterTimestamp
	 * @return: String - JSON string of the appointments data
	 */
	public String findAppointments(Id userId, Datetime afterTimeStamp){
		try {
			List<Event> salesEvents = [SELECT Id, StartDateTime, EndDateTime, Subject, WhoId, WhatId, Type, isCancelled__c FROM Event Where OwnerId =: userId and StartDateTime >= :afterTimeStamp and Type = 'Sales Appointment'];
			List<Event> techmEvents = [SELECT Id, StartDateTime, EndDateTime, Subject, WhoId, WhatId, Type, isCancelled__c FROM Event Where OwnerId =: userId and StartDateTime >= :afterTimeStamp and Type = 'Tech Measure'];
			Appointments myAppts = new Appointments();

			// process the sales appointments
			if (salesEvents.size() > 0) {
				myAppts.salesAppts = this.populateSalesAppointments(salesEvents);
			}

			// process the tech measure appointmsnts
			if (techmEvents.size() > 0) {
				myAppts.tmAppts = this.populateTMAppointments(techmEvents);
			}

			myAppts.getApptsCompletedTimeStamp = Datetime.now();
			return JSON.serialize(myAppts);
		} catch (Exception e) {
			System.debug(LoggingLevel.ERROR, e);
			return JSON.serialize(e);
		}
	}

	/* @method: populateSalesAppointments(List<Id> opptyIds)
	 * @param: List<Id> opptyIds - list of opportunity ids that will be used to build the sales appointments
	 * @return: String - JSON string with of SFDC ids of quotes, orders and discounts
	 */
	public List<SalesAppointment> populateSalesAppointments(List<Event> salesEvents) {
		List<SalesAppointment> salesAppts = new List<SalesAppointment>();
		List<Id> accountIdList = new List<Id>();
		// get the opportunity ids
		List<Id> opportunityIdList = new List<Id>();
		for(Event e : salesEvents){
			opportunityIdList.add(e.whatId);
		}
		// get the opportunities with quotes and orders
		Map<Id, OpportunityContainer> relatedOCs = populateOpportunityStructure(opportunityIdList);

		// get the Accounts(Dwellings)
		for (OpportunityContainer oc: relatedOCs.values()) {
			accountIdList.add(oc.oppty.AccountId);
		}
		Map<Id, Account> relatedAccountMap = new Map<Id, Account>([SELECT Id, Name, Dwelling_Style__c, Shipping_County__c, ShippingCity, ShippingCountryCode, ShippingLatitude, 
			ShippingLongitude, ShippingPostalCode, ShippingStateCode, ShippingStreet, Year_Built__c, Historical__r.Name, HOA__r.Name 
			FROM Account WHERE Id IN :accountIdList and isDeleted = false]);

		// get the historic opportunites
		Map<Id, List<OpportunityContainer>> hocListMap = populateHistoricOpportunities(accountIdList, opportunityIdList);

		// get the contacts using the OpportunityContactRoles
		List<OpportunityContactRole> relatedOppContacts = [select Id, contactId, isPrimary, opportunityId, Role, 
			Contact.Id, Contact.FirstName, Contact.LastName, Contact.Email, Contact.HomePhone, 
			Contact.MobilePhone, Contact.OtherPhone, Contact.Phone, Contact.Salutation, 
			Contact.Comments__c, Contact.Preferred_Method_of_Contact__c, Contact.Spouse__c
			from OpportunityContactRole where isDeleted = false and opportunityId in :opportunityIdList order by opportunityId];

		// map the contacts to the opportunity
		Map<id,list<Contact>> opportunityIdtoContactListMap = new Map<id, list<Contact>>();
		for(OpportunityContactRole ocr : relatedOppContacts){
			Contact c = new Contact(Id=ocr.Contact.Id, FirstName = ocr.Contact.FirstName, LastName = ocr.Contact.LastName, Email = ocr.Contact.Email, HomePhone = ocr.Contact.HomePhone, 
			MobilePhone = ocr.Contact.MobilePhone, OtherPhone = ocr.Contact.OtherPhone, Phone = ocr.Contact.Phone, Salutation = ocr.Contact.Salutation,
			Comments__c = ocr.Contact.Comments__c, Preferred_Method_of_Contact__c = ocr.Contact.Preferred_Method_of_Contact__c, Spouse__c = ocr.Contact.Spouse__c);
			if(opportunityIdtoContactListMap.containsKey(ocr.opportunityId)){
				opportunityIdtoContactListMap.get(ocr.opportunityId).add(c);
			}else{
				opportunityIdtoContactListMap.put(ocr.opportunityId, new list<Contact>{c});
			}
		}
					
		
		for(Event e : salesEvents){
			SalesAppointment sapt = new SalesAppointment();
			sapt.event = e;
			sapt.opptyContainer = relatedOCs.get(e.WhatId);
			sapt.contactList = opportunityIdtoContactListMap.get(e.WhatId);
			sapt.account = relatedAccountMap.get(sapt.opptyContainer.oppty.AccountId);
			sapt.historicOpptyContainerList = hocListMap.get(sapt.opptyContainer.oppty.AccountId); 
			salesAppts.add(sapt);
		}	

		return salesAppts;
	}
		
	/* @method: populateTMAppointments(List<Id> opptyIds)
	 * @param: List<Id> opptyIds - list of opportunity ids that will be used to build the sales appointments
	 * @return: String - JSON string with of SFDC ids of quotes, orders and discounts
	 */
	public List<TechMeasureAppointment> populateTMAppointments(List<Event> tmEvents) {
		List<TechMeasureAppointment> tmAppts = new List<TechMeasureAppointment>();
		List<Id> accountIdList = new List<Id>();
		// get the workOrder Ids
		List<Id> workOrderIdList = new List<Id>();
		for(Event e : tmEvents){
			workOrderIdList.add(e.whatId);
		}

		// get the work orders
		List<RbA_Work_Order__c> workOrderList = [SELECT Id, Name, Opportunity__c, Account__c, Sold_Order__c, Sold_Order__r.OpportunityId, Sold_Order__r.Opportunity.AccountId from RbA_Work_Order__c where isDeleted = false and Id in :workOrderIdList];

		// opportunity ids
		// account ids
		List<Id> opportunityIds = new List<Id>();
		List<Id> accountIds = new List<Id>();
		for (RbA_Work_Order__c wo : workOrderList) {
			opportunityIds.add(wo.Sold_Order__r.OpportunityId);
			accountIds.add(wo.Sold_Order__r.Opportunity.AccountId);
		}

		// get the accounts
		Map<Id, Account> relatedAccountMap = new Map<Id, Account>([SELECT Id, Name, Dwelling_Style__c, Shipping_County__c, ShippingCity, ShippingCountryCode, ShippingLatitude, 
			ShippingLongitude, ShippingPostalCode, ShippingStateCode, ShippingStreet, Year_Built__c, Historical__r.Name, HOA__r.Name 
			FROM Account WHERE Id IN :accountIds and isDeleted = false]);

		// get the opportunities with quotes and orders
		Map<Id, OpportunityContainer> relatedOCs = populateOpportunityStructure(opportunityIds);

		// get the contacts using the OpportunityContactRoles
		List<OpportunityContactRole> relatedOppContacts = [select Id, contactId, isPrimary, opportunityId, Role, 
			Contact.Id, Contact.FirstName, Contact.LastName, Contact.Email, Contact.HomePhone, 
			Contact.MobilePhone, Contact.OtherPhone, Contact.Phone, Contact.Salutation,
			Contact.Comments__c, Contact.Preferred_Method_of_Contact__c, Contact.Spouse__c
			from OpportunityContactRole where isDeleted = false and opportunityId in :opportunityIds order by opportunityId];

		// map the contacts to the opportunity
		Map<id,list<Contact>> opportunityIdtoContactListMap = new Map<id, list<Contact>>();
		for(OpportunityContactRole ocr : relatedOppContacts){
			Contact c = new Contact(Id=ocr.Contact.Id, FirstName = ocr.Contact.FirstName, LastName = ocr.Contact.LastName, Email = ocr.Contact.Email, HomePhone = ocr.Contact.HomePhone, 
			MobilePhone = ocr.Contact.MobilePhone, OtherPhone = ocr.Contact.OtherPhone, Phone = ocr.Contact.Phone, Salutation = ocr.Contact.Salutation,
			Comments__c = ocr.Contact.Comments__c, Preferred_Method_of_Contact__c = ocr.Contact.Preferred_Method_of_Contact__c, Spouse__c = ocr.Contact.Spouse__c);
			if(opportunityIdtoContactListMap.containsKey(ocr.opportunityId)){
				opportunityIdtoContactListMap.get(ocr.opportunityId).add(c);
			}else{
				opportunityIdtoContactListMap.put(ocr.opportunityId, new list<Contact>{c});
			}
		}
					
		// build out the Tech Measure Appointments
		for (Event e : tmEvents) {
			TechMeasureAppointment tma = new TechMeasureAppointment();
			tma.event = e;
			// find and assign the workOrder
			for (RbA_Work_Order__c wo : workOrderList) {
				if (wo.Id == e.WhatId) {
					tma.workOrder = wo;
					break;
				}
			}
			// find and assign the opportunity container
			tma.opptyContainer = relatedOCs.get(tma.workOrder.Sold_Order__r.OpportunityId);
			// find and assign the account
			tma.account = relatedAccountMap.get(tma.workOrder.Sold_Order__r.Opportunity.AccountId);
			// find and assign the contact list
			tma.contactList = opportunityIdtoContactListMap.get(tma.workOrder.Sold_Order__r.OpportunityId);

			// add the appointment to the results list
			tmAppts.add(tma);
		}
		return tmAppts;
	}
		
	/* @method: populateHistoricOpportunities(List<Id> opptyIds)
	 * @param: List<Id> accoutnIds - list of accountIds that will be used to find the opportunities
	 * @param: List<Id> opportunityIds - list of opportunities to exclude from this list
	 * @return:Map of List of OpportunityContainers mapped to account (dwelling Ids) excluding the passed in oppIds
	 */
	public Map<Id, List<OpportunityContainer>> populateHistoricOpportunities(List<Id> acctIds, List<Id> oppIds) {
		Map<Id, Opportunity> hoMap = new Map<Id, Opportunity>([SELECT Id from Opportunity where Id NOT in :oppIds and AccountId in :acctIds]);
		Map<Id, OpportunityContainer> hocsMap = populateOpportunityStructure(new List<Id>(hoMap.keySet()));

		// now put then into a map by account
		Map<Id, List<OpportunityContainer>> acctToOppMap = new Map<Id, List<OpportunityContainer>>();
		for (OpportunityContainer oc: hocsMap.values()) {
			if (acctToOppMap.containsKey(oc.oppty.AccountId)) {
				acctToOppMap.get(oc.oppty.AccountId).add(oc);
			} else {
				List<OpportunityContainer> ocList = new List<OpportunityContainer>();
				ocList.add(oc);
				acctToOppMap.put(oc.oppty.AccountId, ocList);
			}
		}
		return acctToOppMap;
	}

	/* @method: populateOpportunityStructure(List<Id> opptyIds)
	 * @param: List<Id> opptyIds - list of opportunity ids that will be used to build the sales appointments
	 * @return: Map<Id, OpportunityContainer> containing all new appointment opportunities
	 */
	public Map<Id, OpportunityContainer> populateOpportunityStructure(List<Id> oppIds) {
		Map<Id, OpportunityContainer> ocMap = new Map<Id, OpportunityContainer>();
		Map<Id, Opportunity> relatedOpportunityMap = new Map<Id, Opportunity> ([SELECT Id, Name, CloseDate, StageName, AccountId, isClosed, Pricebook2Id, Window_Problems__c FROM Opportunity WHERE Id IN :oppIds]);

		// get the quotes
		Map<Id, Quote> quoteMap = new Map<Id, Quote>([SELECT Id, Name, 	isSold__c, OpportunityId, Pricebook2Id, QuoteNumber, Subtotal, Discount_Amount__c, Total__c from Quote where OpportunityId in :oppIds and isDeleted = false]);
		// get the quote line items
		List<QuoteLineItem> qliList = [SELECT Id, Description, LineNumber, ListPrice, PricebookEntryId, Quantity, QuoteId, Subtotal, TotalPrice, UnitPrice, 
			Astragal__c, Breather_Tubes__c, Brickmould_Applied__c, Brickmould_Location__c, Casing_Location__c, Casing_Profile__c, Casing_Species__c,
			Checkrail_Style__c, Colonial_Grille_Lites_High_S1__c, Colonial_Grille_Lites_High_S2__c, Colonial_Grille_Lites_Wide_S1__c, Colonial_Grille_Lites_Wide_S2__c, 
			Corrosion_Resistant_Hardware__c, Custom_Grille_Details_S1__c, Custom_Grille_Details_S2__c, Drip_Cap_Pieces__c, EJ_Color__c, EJ_Frame__c, 
			EJ_Species__c, EJ_Thickness__c, EJ_Wall_Depth__c, Exterior_Color__c, Exterior_Grille_Color__c, Exterior_Trim__c, Exterior_Trim_Color__c, 
			Fibrex_L_Trim__c, Finger_Lifts__c, Frame_Type__c, Glass_Pattern_S1__c, Glass_Pattern_S2__c, Glass_Pattern_S3__c, Glazing_S1__c, Glazing_S2__c, 
			Glazing_S3__c, Gliding_Screen__c, Grille_Pattern_S1__c, Grille_Pattern_S2__c, Grille_Style__c, Handing__c, Hardware_Color__c, Hardware_Finish__c, 
			Hardware_Option__c, Hardware_Style__c, Hubs__c, Insect_Screen_Style__c, Interior_Color__c, Interior_Grille_Color__c, Interior_Sash_Color__c, 
			Interior_Trim__c, Jamb_Liner_Color__c, Lifts_Pulls__c, Locks_Sash__c, Permanently_Applied_Interior_Wood_Grille__c, Sales_Height_Inches__c, 
			Sales_Width_Inches__c, Sash_Operation__c, Sash_Ratio__c, Screen_Color__c, Screen_Type__c, Screen_Vaneer_Type__c, Spokes__c, Tax_Credit_Qualified__c, 
			Tempered_S1__c, Tempered_S2__c, Tempered_S3__c, Unit_Id__c, Wide_Bar__c
			from QuoteLineItem where QuoteId in :quoteMap.keySet() and isDeleted = false];
		// get the quote discounts
		List<Quote_Discount__c> qdList = [SELECT Id, Name, Discount_Amount__c, Discount__c, Discount_Description__c, Status__c, Quote__c from Quote_Discount__c where Quote__c in :quoteMap.keySet() and isDeleted = false];
		// build the quote containers
		List<QuoteContainer> qcList = new List<QuoteContainer>();
		for (Quote q : quoteMap.values()) {
			QuoteContainer qc = new QuoteContainer();
			qc.aQuote = q;
			qc.quoteLineItems = new List<QuoteLineItem>();
			for (QuoteLineItem qli : qliList) {
				if (qli.QuoteId == q.Id) {
					qc.quoteLineItems.add(qli);
				}
			}
			qc.quoteDiscountList = new List<Quote_Discount__c>();
			for (Quote_Discount__c qd : qdList) {
				if (qd.Quote__c == q.Id) {
					qc.quoteDiscountList.add(qd);
				}
			}
			qcList.add(qc);
		}

		// get the orders
		Map<Id, Order> orderMap = new Map<Id, Order>([SELECT Id, AccountId, Name, OpportunityId,
			Discount_Amount__c, Installation_Date__c, Reason__c, Retail_Subtotal__c, Retail_Total__c, Store_Location__c, Tech_Measure_Date__c
			from Order where OpportunityId in :oppIds and isDeleted = false]);
		// get the order line items
		List<OrderItem> oiList = [SELECT Id, Description, ListPrice, OrderItemNumber, OrderId, PricebookEntryId, Quantity, QuoteLineItemId, UnitPrice,
			Apply_to_All_Sashes_Glass__c, Apply_to_All_Sashes_Grilles__c, Astragal__c, Breather_Tubes__c, Brickmould_Applied__c, Brickmould_Location__c, 
			Casing_Location__c, Casing_Profile__c, Casing_Species__c, Checkrail_Style__c, Colonial_Grille_Lites_High_S1__c, Colonial_Grille_Lites_High_S2__c, 
			Colonial_Grille_Lites_High_S3__c, Colonial_Grille_Lites_Wide_S1__c, Colonial_Grille_Lites_Wide_S2__c, Colonial_Grille_Lites_Wide_S3__c, 
			Corrosion_Resistant_Hardware__c, Custom_Grille_Details_S1__c, Custom_Grille_Details_S2__c, Custom_Grille_Details_S3__c, Drip_Cap_Pieces__c, 
			EJ_Color__c, EJ_Frame__c, EJ_Species__c, EJ_Thickness__c, EJ_Wall_Depth__c, Exterior_Color__c, Exterior_Grille_Color__c, Exterior_Trim__c, 
			Exterior_Trim_Color__c, Fibrex_L_Trim__c, Finger_Lifts__c, Frame_Type__c, Glass_Pattern_S1__c, Glass_Pattern_S2__c, Glass_Pattern_S3__c, 
			Glazing_S1__c, Glazing_S2__c, Glazing_S3__c, Gliding_Screen__c, Grille_Pattern__c, Grille_Pattern_S1__c, Grille_Pattern_S2__c, 
			Grille_Pattern_S3__c, Grille_Style__c, Handing__c, Hardware_Color__c, Hardware_Finish__c, 
			Hardware_Option__c, Hardware_Style__c, Height_Inches__c, Height_Fraction__c, Hubs__c, Insect_Screen_Style__c, Install_Holes_Location__c, 
			Install_Track_Location__c, Interior_Color__c, Interior_Grille_Color__c, Interior_Sash_Color__c, Interior_Trim__c, Jamb_Liner_Color__c, 
			Left_Leg_Inches__c, Left_Leg_Fraction__c, Lifts_Pulls__c, Locks_Sash__c, Mfg_Mull_Sequence__c, Mull_Sequence_Mullion__c, NSPR__c, Part_of_Bay__c, 
			Part_of_Bow__c, Perm_Applied_Int_Wood_Grille__c, Right_Leg_Inches__c, Right_Leg_Fraction__c, Room__c, Room_Description__c, 
			Sales_Height_Fraction__c, Sales_Height_Inches__c, Sales_Width_Fraction__c, Sales_Width_Inches__c, Sash_Operation__c, Sash_Ratio__c, 
			Screen_Color__c,Screen_Type__c, Screen_Vaneer_Type__c, Sill_Angle__c, Special_Options__c, Spokes__c, Storm_Window__c, Storm_Window_Color__c, 
			Storm_Window_Style__c, SW_Grille_Alignment__c, Tax_Credit_Qualified__c, Tempered_S1__c, Tempered_S2__c, Tempered_S3__c, Total_Retail_Price__c, 
			Total_Wholesale_Cost__c, Unit_Id__c, Variant_Number__c, Unit_Wholesale_Cost__c, Wide_Bar__c, Width_Fraction__c, Width_Inches__c
			from OrderItem where OrderId in :orderMap.keySet() and isDeleted = false];
		// get the order discounts
		List<Order_Discount__c> odList = [SELECT Id, Name, Discount_Amount__c, Discount__c, Discount_Description__c, Status__c, Order__c from Order_Discount__c where Order__c in :orderMap.keySet() and isDeleted = false];
		// build the orderContainers
		List<OrderContainer> orcList = new List<OrderContainer>();
		for (Order ord : orderMap.values()) {
			OrderContainer orc = new OrderContainer();
			orc.anOrder = ord;
			orc.oiList = new List<OrderItem>();
			for (OrderItem oi : oiList) {
				if (oi.OrderId == ord.Id) {
					orc.oiList.add(oi);
				}
			}
			orc.orderDiscountList = new List<Order_Discount__c>();
			for (Order_Discount__c od : odList) {
				if (od.Order__c == ord.Id) {
					orc.orderDiscountList.add(od);
				}
			}
			orcList.add(orc);
		}

		// build the opportunityContainers
		for (Opportunity oppty: relatedOpportunityMap.values()) {
			OpportunityContainer oc = new OpportunityContainer();
			oc.oppty = oppty;
			// add the order - assumption is one order per opportunity
			for (OrderContainer orc : orcList) {
				if (orc.anOrder.OpportunityId == oppty.Id) {
					oc.anOrderContainer = orc;
				}
			}

			// add the quotes
			oc.quoteContainerList = new List<QuoteContainer>();
			for (QuoteContainer qc : qcList) {
				if (qc.aQuote.OpportunityId == oppty.Id) {
					oc.quoteContainerList.add(qc);
				}
			}
			// add the container to the map
			ocMap.put(oppty.Id, oc);			
		}
		return ocMap;
	}
		
	/* @method: updateOpportunity(Id OppId, String status)
	 * @param: Id oppId
	 * @param: String status
	 * @return: String - JSON string with of SFDC ids of quotes, orders and discounts
	 */
    public String resultSalesAppointments(Id userId, String input){
		// parse the input JSON string into an Opportunity Container
		Appointments appts = (Appointments)JSON.deserialize(input, Appointments.class);
		// now that we've parsed it, put sequence numbers on the 
//		appts = addSequenceNums(appts);

		// now lets save the quotes to the opportunitiez
		appts = saveQuotes(appts);
		// now lets save the quote line items and discounts to the quotes
		// note that we will need to add the quote ids to quote line items before we can save the quotes
		appts=saveQuoteLineItemsAndDiscounts(appts);
		// now save the opportunity changes
// do the opportunity update

		// now that we are done lets return the updated records to the client

		return 'SUCCESS: ' + JSON.serialize(appts);
	}


	/* @method: saveQuotesLinteItems(Appointments appts)
	 * @param: Appointments appts
	 * @return: Appointments - comes back with committed quotes and/or error messages
	 */
	public Appointments saveQuotes(Appointments appts) {
		List<Quote> quotes = new List<Quote>();
		for (SalesAppointment sa : appts.salesAppts) {
			for (QuoteContainer qc : sa.opptyContainer.quoteContainerList) {
				if (qc.aQuote != null) {
					quotes.add(qc.aQuote);
				}
			}
		}
		if (quotes.size() > 0) {
			try {
				insert quotes;
			} catch (DMLException dmle) {
				if (appts.errors == null) {
					appts.errors = new String[]{};
				}
				appts.errors.add('Insert error on quotes: ' + dmle.getMessage());
			}
		} else {
			if (appts.errors == null) {
				appts.errors = new String[]{};
			}
			appts.errors.add('No Quotes Found');
		}
		return appts;
	}

	/* @method: saveQuoteLineItemsAndDiscounts(Appointments appts)
	 * @param: Appointments appts
	 * @return: Appointments - comes back with committed quote line items, quote discounts and/or error messages
	 */
	public Appointments saveQuoteLineItemsAndDiscounts(Appointments appts) {
		List<QuoteLineItem> qliList = new List<QuoteLineItem>();
		List<Quote_Discount__c> qdList = new List<Quote_Discount__c>();
		
		for (SalesAppointment sa : appts.salesAppts) {
			for (QuoteContainer qc: sa.opptyContainer.quoteContainerList) {
				// add the quote id to the quote line items and put the quote line items in the list to be inserted
				for (QuoteLineItem qli : qc.quoteLineItems) {
					qli.QuoteId = qc.aQuote.Id;
					qliList.add(qli);
				}
				// add the quote id to the quote discounts and put the quote discounts in the list to be inserted
				for (Quote_Discount__c qd : qc.quoteDiscountList) {
					qd.Quote__c = qc.aQuote.Id;
					qdList.add(qd);
				}
			}
		}
		try {
			if (qliList.size() > 0) {
				Database.SaveResult[] lsr = Database.insert(qliList, false);
				for(Database.SaveResult sr : lsr){
					if (!sr.isSuccess()) {
						if (appts.errors == null) {
							appts.errors = new String[]{};
						}
						// add error messages 
						// Operation failed, so get all errors               
						for(Database.Error err : sr.getErrors()) {
							appts.errors.add(err.getStatusCode() + ': ' + err.getMessage() + ': qli fields that affected this error: ' + err.getFields());
						}
					}
				}
//				insert qliList;
			} else {
				if (appts.errors == null) {
					appts.errors = new String[]{};
				}
				appts.errors.add('No Quote Line Items Found');
			}
		} catch (Exception e) {
		}
		try {
			if (qdList.size() > 0) {
				insert qdList;
			}
		} catch (Exception e) {
		}
		return appts;
	}

		// we should have an opportunity with a list of quotes and quote line items
		// the opportunity should be marked as sold won/lost and if sold a quote should be marked as the quote that sold.
		


/*		
    	List<Opportunity> opp = [SELECT Id, Name, AccountId FROM Opportunity WHERE Id = :oppId];
    	if(opp.size() == 0){
    		return 'No Opportunity found with that Id';
    	}else{
    		//map<String, RMS_Queue_Settings__c> RMS_Queue_Settings_map = RMS_Queue_Settings__c.getAll(); 
    		//RMS_Queue_Settings__c queueSetting = RMS_Queue_Settings_map.get(opp[0].AccountId);
			
			////////THIS IS BEING USED FOR DEMO UNTIL ACCOUNT IS POPULATED INSIDE THE ORDER///////////
	    	Account testAccount = [SELECT id FROM Account Where Name = '77 - Twin Cities, MN'];
	    	//////////////////////////////////////////////////////////////////////////////////////////
	    	
    		list<Store_Configuration__c> storeConfig = [SELECT 	Id, 
    															Store__c, 
    															Install_Work_Order_Queue_Id__c, 
    															Tech_Measure_Work_Order_Queue_Id__c, 
    															Order_Queue_Id__c
    															FROM Store_Configuration__c
    															WHERE Store__r.id =: testAccount.id];
    															//WHERE Store__r.id =: opp[0].AccountId];
    		
    		//ORDER related to the Opp
    		Order ord = new Order(
    			AccountId = opp[0].AccountId,
    			OwnerId = storeConfig[0].Order_Queue_Id__c,
    			Status = 'Draft',
    			EffectiveDate = Date.today(),
    			Opportunity = opp 
    		);
    		insert ord;
    		//Unable to create order with Activated status
    		
    		//Create products on order here
    		
    		//ord.Status = 'Activated';
    		//update ord;
    		
    		
    		RecordType serviceOrderScheduleRecordType = [SELECT id FROM RecordType WHERE SobjectType = 'RbA_Work_Order__c' AND Name = 'Schedule'];
    		//CREATE WORK ORDER (TECH MEASURE)
    		RbA_Work_Order__c techWO = new RbA_Work_Order__c(
    			Sold_Order__c = ord.id,
    			RecordType = serviceOrderScheduleRecordType,
    			Order_Type__c = 'Tech Measure',
    			OwnerId = storeConfig[0].Tech_Measure_Work_Order_Queue_Id__c
    		);
    		 	
    		 	system.debug('ads storeConfig[0].Tech_Measure_Work_Order_Queue_Id__c: '+storeConfig[0].Tech_Measure_Work_Order_Queue_Id__c);
    		 	list<QueueSobject> x = [SELECT id, sobjectType, QueueId  FROM QueueSobject WHERE QueueId =: storeConfig[0].Tech_Measure_Work_Order_Queue_Id__c];
				system.debug('ads checking queue type');
				system.debug('ads: '+ x[0].sobjectType);
    		
    		
    		insert techWO;
    		
    		
    		//CREATE WORK ORDER (INSTALL)
    		RbA_Work_Order__c installWO = new RbA_Work_Order__c(
    			Sold_Order__c = ord.id, 
    			RecordType =  serviceOrderScheduleRecordType,
    			Order_Type__c = 'Install',
    			OwnerId = storeConfig[0].Install_Work_Order_Queue_Id__c
    		);
    		insert installWO;
*/
//		return 'Created Order, Install Work Order and Tech Measure Work Order';


	public class Appointments {
		public List<SalesAppointment> salesAppts;
		public List<TechMeasureAppointment> tmAppts;
		public Datetime getApptsCompletedTimeStamp;
		String[] errors;
	}

	public class SalesAppointment{
		public Event event {get; set;}
		public OpportunityContainer opptyContainer {get; set;}
   		public Account account {get; set;}
        public List<Contact> contactList {get; set;}
		public List<OpportunityContainer> historicOpptyContainerList {get; set;}

        public SalesAppointment() {}
    }
    
	public class TechMeasureAppointment{
		public Event event {get; set;}
   		public RbA_Work_Order__c workOrder {get; set;}
   		public Account account {get; set;}
        public List<Contact> contactList {get; set;}
		public OpportunityContainer opptyContainer {get; set;}
   		
        public TechMeasureAppointment() {}
    }

	public class OpportunityContainer {
		public Opportunity oppty {get; set;}
		public OrderContainer anOrderContainer {get; set;}
		public List<QuoteContainer> quoteContainerList {get; set;}
	}

	public class OrderContainer {
		public Order anOrder {get; set;}
		public List<OrderItem>  oiList {get; set;}
		public List<Order_Discount__c> orderDiscountList {get; set;}
	}

	public class QuoteContainer {
		public Quote aQuote {get; set;}
		public List<QuoteLineItem>  quoteLineItems {get; set;}
		public List<Quote_Discount__c> quoteDiscountList {get; set;}
	}

}
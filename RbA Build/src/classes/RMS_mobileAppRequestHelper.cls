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
			List<Event> salesEvents = [SELECT Id, StartDateTime, EndDateTime, Subject, WhoId, WhatId, Type FROM Event Where OwnerId =: userId and StartDateTime >= :afterTimeStamp and Type = 'Sales Appointment'];
			List<Event> techmEvents = [SELECT Id, StartDateTime, EndDateTime, Subject, WhoId, WhatId, Type FROM Event Where OwnerId =: userId and StartDateTime >= :afterTimeStamp and Type = 'Tech Measure'];
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
		Map<Id, Account> relatedAccountMap = new Map<Id, Account>([SELECT Id, Name, Dwelling_Style__c, Shipping_County__c, ShippingCity, ShippingCountryCode, ShippingLatitude, ShippingLongitude, ShippingPostalCode, ShippingStateCode, ShippingStreet, Year_Built__c FROM Account WHERE Id IN :accountIdList and isDeleted = false]);

		// get the contacts using the OpportunityContactRoles
		List<OpportunityContactRole> relatedOppContacts = [select Id, contactId, isPrimary, opportunityId, Role, 
			Contact.Id, Contact.FirstName, Contact.LastName, Contact.Email, Contact.HomePhone, 
			Contact.MobilePhone, Contact.OtherPhone, Contact.Phone, Contact.Salutation
			from OpportunityContactRole where isDeleted = false and opportunityId in :opportunityIdList order by opportunityId];

		// map the contacts to the opportunity
		Map<id,list<Contact>> opportunityIdtoContactListMap = new Map<id, list<Contact>>();
		for(OpportunityContactRole ocr : relatedOppContacts){
			Contact c = new Contact(Id=ocr.Contact.Id, FirstName = ocr.Contact.FirstName, LastName = ocr.Contact.LastName, Email = ocr.Contact.Email, HomePhone = ocr.Contact.HomePhone, 
			MobilePhone = ocr.Contact.MobilePhone, OtherPhone = ocr.Contact.OtherPhone, Phone = ocr.Contact.Phone, Salutation = ocr.Contact.Salutation);
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
		List<SVMXC__Service_Order__c> workOrderList = [SELECT Id, Name, Opportunity__c, Company__c, Sold_Order__c, Sold_Order__r.OpportunityId, Sold_Order__r.Opportunity.AccountId from SVMXC__Service_Order__c where isDeleted = false and Id in :workOrderIdList];

		// opportunity ids
		// account ids
		List<Id> opportunityIds = new List<Id>();
		List<Id> accountIds = new List<Id>();
		for (SVMXC__Service_Order__c wo : workOrderList) {
			opportunityIds.add(wo.Sold_Order__r.OpportunityId);
			accountIds.add(wo.Sold_Order__r.Opportunity.AccountId);
		}

		// get the accounts
		Map<Id, Account> relatedAccountMap = new Map<Id, Account>([SELECT Id, Name, Dwelling_Style__c, Shipping_County__c, ShippingCity, ShippingCountryCode, ShippingLatitude, ShippingLongitude, ShippingPostalCode, ShippingStateCode, ShippingStreet, Year_Built__c FROM Account WHERE Id IN :accountIds and isDeleted = false]);

		// get the opportunities with quotes and orders
		Map<Id, OpportunityContainer> relatedOCs = populateOpportunityStructure(opportunityIds);

		// get the contacts using the OpportunityContactRoles
		List<OpportunityContactRole> relatedOppContacts = [select Id, contactId, isPrimary, opportunityId, Role, 
			Contact.Id, Contact.FirstName, Contact.LastName, Contact.Email, Contact.HomePhone, 
			Contact.MobilePhone, Contact.OtherPhone, Contact.Phone, Contact.Salutation
			from OpportunityContactRole where isDeleted = false and opportunityId in :opportunityIds order by opportunityId];

		// map the contacts to the opportunity
		Map<id,list<Contact>> opportunityIdtoContactListMap = new Map<id, list<Contact>>();
		for(OpportunityContactRole ocr : relatedOppContacts){
			Contact c = new Contact(Id=ocr.Contact.Id, FirstName = ocr.Contact.FirstName, LastName = ocr.Contact.LastName, Email = ocr.Contact.Email, HomePhone = ocr.Contact.HomePhone, 
			MobilePhone = ocr.Contact.MobilePhone, OtherPhone = ocr.Contact.OtherPhone, Phone = ocr.Contact.Phone, Salutation = ocr.Contact.Salutation);
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
			for (SVMXC__Service_Order__c wo : workOrderList) {
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
		
	/* @method: populateOpportunityStructure(List<Id> opptyIds)
	 * @param: List<Id> opptyIds - list of opportunity ids that will be used to build the sales appointments
	 * @return: String - JSON string with of SFDC ids of quotes, orders and discounts
	 */
	public Map<Id, OpportunityContainer> populateOpportunityStructure(List<Id> oppIds) {
		Map<Id, OpportunityContainer> ocMap = new Map<Id, OpportunityContainer>();
		Map<Id, Opportunity> relatedOpportunityMap = new Map<Id, Opportunity> ([SELECT Id, Name, StageName, AccountId, isClosed FROM Opportunity WHERE Id IN :oppIds]);

		// get the quotes
		Map<Id, Quote> quoteMap = new Map<Id, Quote>([SELECT Id, Name, IsSyncing, OpportunityId, Pricebook2Id, QuoteNumber, Subtotal, Tax, TotalPrice from Quote where OpportunityId in :oppIds and isDeleted = false]);
		// get the quote line items
		List<QuoteLineItem> qliList = [SELECT Id, LineNumber, PricebookEntryId, Product2Id, Quantity, QuoteId, Subtotal, TotalPrice, UnitPrice from QuoteLineItem where QuoteId in :quoteMap.keySet() and isDeleted = false];
		// get the quote discounts
		List<Quote_Discount__c> qdList = [SELECT Id, Name, Quote__c from Quote_Discount__c where Quote__c in :quoteMap.keySet() and isDeleted = false];
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
		Map<Id, Order> orderMap = new Map<Id, Order>([SELECT Id, Name, OpportunityId from Order where OpportunityId in :oppIds and isDeleted = false]);
		// get the order line items
		List<OrderItem> oiList = [SELECT Id, OrderItemNumber, OrderId from OrderItem where OrderId in :orderMap.keySet() and isDeleted = false];
		// get the order discounts
		List<Order_Discount__c> odList = [SELECT Id, Name, Order__c from Order_Discount__c where Order__c in :orderMap.keySet() and isDeleted = false];
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
    public String updateOpportunity(Id oppId, String status){
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
    		
    		
    		RecordType serviceOrderScheduleRecordType = [SELECT id FROM RecordType WHERE SobjectType = 'SVMXC__Service_Order__c' AND Name = 'Schedule'];
    		//CREATE WORK ORDER (TECH MEASURE)
    		SVMXC__Service_Order__c techWO = new SVMXC__Service_Order__c(
    			Sold_Order__c = ord.id,
    			RecordType = serviceOrderScheduleRecordType,
    			SVMXC__Order_Type__c = 'Tech Measure',
    			OwnerId = storeConfig[0].Tech_Measure_Work_Order_Queue_Id__c
    		);
    		 	
    		 	system.debug('ads storeConfig[0].Tech_Measure_Work_Order_Queue_Id__c: '+storeConfig[0].Tech_Measure_Work_Order_Queue_Id__c);
    		 	list<QueueSobject> x = [SELECT id, sobjectType, QueueId  FROM QueueSobject WHERE QueueId =: storeConfig[0].Tech_Measure_Work_Order_Queue_Id__c];
				system.debug('ads checking queue type');
				system.debug('ads: '+ x[0].sobjectType);
    		
    		
    		insert techWO;
    		
    		
    		//CREATE WORK ORDER (INSTALL)
    		SVMXC__Service_Order__c installWO = new SVMXC__Service_Order__c(
    			Sold_Order__c = ord.id, 
    			RecordType =  serviceOrderScheduleRecordType,
    			SVMXC__Order_Type__c = 'Install',
    			OwnerId = storeConfig[0].Install_Work_Order_Queue_Id__c
    		);
    		insert installWO;
			
			return 'Created Order, Install Work Order and Tech Measure Work Order';
    	}
    }

	public class Appointments {
		public List<SalesAppointment> salesAppts;
		public List<TechMeasureAppointment> tmAppts;
		public Datetime getApptsCompletedTimeStamp;
	}

	public class SalesAppointment{
		public Event event {get; set;}
   		public Opportunity oppty {get; set;}
		public OpportunityContainer opptyContainer {get; set;}
   		public Account account {get; set;}
        public List<Contact> contactList {get; set;}
		public List<OpportunityContainer> historicOpptyContainerList {get; set;}

        public SalesAppointment() {}
        public SalesAppointment(Event e, Opportunity o, Account a, List<Contact> cl ) {
            event = e;
            oppty = o;
            account = a;
            contactList = cl;
        }                            
    }
    
	public class TechMeasureAppointment{
		public Event event {get; set;}
   		public SVMXC__Service_Order__c workOrder {get; set;}
   		public Account account {get; set;}
        public List<Contact> contactList {get; set;}
		public OpportunityContainer opptyContainer {get; set;}
   		
        public TechMeasureAppointment() {}
        public TechMeasureAppointment(Event e, SVMXC__Service_Order__c wo, Account a, List<Contact> cl, OpportunityContainer oc ) {
            event = e;
            workOrder = wo;
            account = a;
            contactList = cl;
			opptyContainer = oc;
        }                            
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
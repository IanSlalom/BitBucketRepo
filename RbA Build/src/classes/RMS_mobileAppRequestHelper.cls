/*
 *@class  RMS_mobileAppRequestHelper
 *@brief  Help class for handling api call business logic
 *@author  Anthony Strafaccia (Slalom.ADS)
 *@author  Mark Wochnick (Slalom.MAW)
 *@version  2015-09/16  Slalom.ADS  Created.
 *@version  2015-10/12  Slalom.MAW
 *@copyright  (c)2015 Slalom.  All Rights Reserved.  Unauthorized use is prohibited.
 */

public with sharing class RMS_mobileAppRequestHelper {

	public static map<String, RMS_Settings__c> RMS_Settings_map = RMS_Settings__c.getAll(); 
	private static String SHARED_FIELDS;
	// fields unique to Quote line items
	private static final String QLI_QUERY_START = 'SELECT LineNumber, QuoteId, Subtotal, TotalPrice, Parent_Quote_Line_Item__c, isInactive__c, isDeleted';
	private static final String QLI_WHERE_CLAUSE = 'from QuoteLineItem where QuoteId in :quoteIds and isDeleted = false order by Unit_Id__c, Product_Class__c';

	// fields unique to Order line items
	private static final String OLI_QUERY_START = 'SELECT Cancelled__c, Cancelled_Date__c, Charge_Cost_To__c, isTechMeasureComplete__c, Parent_Order_Item__c, ' + 
	'OrderItemNumber, OrderId, QuoteLineItemId, Height_Inches__c, Height_Fraction__c, NSPR__c, NSPR_Number__c, Sill_Angle__c, ' + 
	'Variant_Number__c, Unit_Wholesale_Cost__c, Width_Fraction__c, Width_Inches__c, Unit_of_Measure__c,' +
	'Meet_Rail_Dimension__c, Is_Height_L_or_R_Leg_Height__c, Leg_Height_Interior_Whole_Inch__c, Leg_Height_Interior_Fraction__c,' +
	'Leg_Height_Exterior_Whole_Inch__c, Leg_Height_Exterior_Fraction__c, Is_Leg_Height_L_or_R_Leg_Height__c';
	private static final String OLI_WHERE_CLAUSE = 'from OrderItem where OrderId in :orderIds and isDeleted = false order by Unit_Id__c, Product_Class__c';

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
        for(Event e : salesEvents){
          e.Synced_DateTime__c = Datetime.now();
        }
        update salesEvents;
      }

      // process the tech measure appointmsnts
      if (techmEvents.size() > 0) {
        myAppts.tmAppts = this.populateTMAppointments(techmEvents);
        for(Event e : techmEvents){
          e.Synced_DateTime__c = Datetime.now();
        }
         update techmEvents;
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

  /* @method: buildQLIQuery()
   * @return: String quote line item query
   */
  public String buildQLIQuery() {
	if (SHARED_FIELDS == null || SHARED_FIELDS.equals('')) {
		SHARED_FIELDS = buildSharedFields();
	}
	String qliQuery = QLI_QUERY_START + SHARED_FIELDS + QLI_WHERE_CLAUSE;
	return qliQuery;
  }

  /* @method: buildOLIQuery()
   * @return: String order line item query
   */
  public String buildOLIQuery() {
	if (SHARED_FIELDS == null || SHARED_FIELDS.equals('')) {
		SHARED_FIELDS = buildSharedFields();
	}
	String oliQuery = OLI_QUERY_START + SHARED_FIELDS + OLI_WHERE_CLAUSE;
	return oliQuery;
  }

  /* @method: buildSharedFields()
   * @description: uses a quote line item field set to dynamically build the query
   * @return: String shared fields from between quote line item and order line item
   */
  public String buildSharedFields() {
	String sharedQueryFields = '';
	// get the field set
	Schema.FieldSet fs1 = Schema.SObjectType.QuoteLineItem.fieldSets.rsuite_api_fields;
	for (FieldSetMember fsm : fs1.getFields()) {
		sharedQueryFields = sharedQueryFields + ', ' + fsm.getFieldPath();
	}
	sharedQueryFields += ' '; //add a trailing space
	return sharedQueryFields;
  }

  /* @method: populateOpportunityStructure(List<Id> opptyIds)
   * @param: List<Id> opptyIds - list of opportunity ids that will be used to build the sales appointments
   * @return: Map<Id, OpportunityContainer> containing all new appointment opportunities
   */
  public Map<Id, OpportunityContainer> populateOpportunityStructure(List<Id> oppIds) {
    Map<Id, OpportunityContainer> ocMap = new Map<Id, OpportunityContainer>();
    Map<Id, Opportunity> relatedOpportunityMap = new Map<Id, Opportunity> (
    [SELECT Id, Name, CloseDate, StageName, AccountId, isClosed, 
    Pricebook2Id, Window_Problems__c, rSuite_Id__c,
    rSuite_Id_1st_Selected_Quote__c, rSuite_Id_2nd_Selected_Quote__c,
    First_Selected_Quote__c, Second_Selected_Quote__c
    FROM Opportunity WHERE Id IN :oppIds]);

    // get the quotes 
    Map<Id, Quote> quoteMap = new Map<Id, Quote>([SELECT Id, Name, isSold__c, OpportunityId, Pricebook2Id, QuoteNumber, Subtotal, Discount_Amount__c, Total__c, rSuite_Id__c, Sub_Total__c from Quote where OpportunityId in :oppIds and isDeleted = false]);
	List<Id> quoteIds = new List<Id> (quoteMap.keySet());
    // get the quote line items
	String qliQuery = this.buildQLIQuery();
	List<QuoteLineItem> qliList = Database.query(qliQuery);

    // get the quote discounts
    List<Quote_Discount__c> qdList = [SELECT Id, Name, Discount_Amount__c, Store_Discount__c, Discount_Description__c, Status__c, Quote__c, rSuite_Id__c from Quote_Discount__c where Quote__c in :quoteMap.keySet() and isDeleted = false];
    // get the quote financing
    List<Quote_Financing__c> qfList = [SELECT Id, Name, Amount_Financed__c, Store_Finance_Program__c, Related_Quote__c, Authorization_Code__c, Expiration_Date__c, Program_Rate__c, Program_Fee__c, rSuite_Id__c from Quote_Financing__c where Related_Quote__c in :quoteMap.keySet() and isDeleted = false];
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
      qc.quoteFinancingList = new List<Quote_Financing__c>();
      for (Quote_Financing__c qf : qfList) {
        if (qf.Related_Quote__c == q.Id) {
          qc.quoteFinancingList.add(qf);
        }
      }

      qcList.add(qc);
    }

    // build the orderContainers
    List<OrderContainer> orcList = buildOrderContainers(oppIds);

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
    
  /* @method: buildOrderContainers(List<Id> opptyIds)
   * @param: List<Id> opptyIds
   * @return: List<OrderContainer>
   */
  public List<OrderContainer> buildOrderContainers(List<Id> opptyIds){
    // get the orders
    Map<Id, Order> orderMap = queryOrders(opptyIds);
    // get the order line items
    List<OrderItem> oiList = queryOrderItems(orderMap.keySet());
    // get the tech measure offsets
    List<TM_Offset__c> tmoList = [select Id, Name, Description__c, Dimension__c, 
    Location__c, Measurement__c, Order_Line__c, rSuite_Id__c, createdDate 
    from TM_Offset__c where isDeleted = false and Order_Line__c in :oiList 
    Order By createdDate asc];

	//get the change histories
	List<Change_History__c> chList = [Select Id, Name, Order_Product__c, Changes__c, Responsible_Party__c, Retail_Price__c, Retail_Price_Change__c, createdDate
		from Change_History__c where isDeleted = false and Order_Product__c in : oiList and RecordType.DeveloperName = 'Order_Product_Change'
		Order By LastModifiedDate];
    // get the order discounts
    List<Order_Discount__c> odList = queryOrderDiscounts(orderMap.keySet());
	// get the order financing
	List<Order_Financing__c> ofList = queryOrderFinancing(orderMap.keySet());

    // build the orderContainers
    List<OrderContainer> orcList = new List<OrderContainer>();
	for (Order ord : orderMap.values()) {
		OrderContainer orc = new OrderContainer();
		orc.anOrder = ord;
		orc.oiContainerList = new List<OrderItemContainer>();
		for (OrderItem oi : oiList) {
		if (oi.OrderId == ord.Id) {
			OrderItemContainer oic = new OrderItemContainer();
			oic.oi = oi;
			// now add the TM offsets to the order item container
			for (TM_Offset__c tmo: tmoList) {
				if (tmo.Order_Line__c == oi.Id) {
					if (oic.tmOffsetList == null) {
						oic.tmOffsetList = new List<TM_Offset__c>();
					}
					oic.tmOffSetList.add(tmo);
				}
			}
			// Add the Change Histories to the Order Item Container
			for(Change_History__c ch: chList){
				if(ch.Order_Product__c == oi.Id){
					if(oic.changeHistoryList == null){
						oic.changeHistoryList = new List<Change_History__c>();
					}
					oic.changeHistoryList.add(ch);
				}
			}
			// now add the order item containter to the list
			orc.oiContainerList.add(oic);
		}
	}
      orc.orderDiscountList = new List<Order_Discount__c>();
      for (Order_Discount__c od : odList) {
        if (od.Order__c == ord.Id) {
          orc.orderDiscountList.add(od);
        }
      }
	  orc.orderFinancingList = new List<Order_Financing__c>();
	  for (Order_Financing__c ofin : ofList) {
		if(ofin.Related_Order__c == ord.Id) {
			orc.orderFinancingList.add(ofin);
		}
	  }
      orcList.add(orc);
    }
    return orcList;
  }

  /* @method: queryOrders(List<Id> opptyIds)
   * @param: List<Id> opptyIds
   * @return: Map<Id, Order>
   */
    public Map<Id, Order> queryOrders(List<Id> opptyIds){
    Map<Id, Order> orderMap = new Map<Id, Order>([SELECT Id, AccountId, Name, OpportunityId,
      Discount_Amount__c, Installation_Date__c, Install_Notes__c, Reason__c, 
      Retail_Subtotal__c, Retail_Total__c, Store_Location__c, Tech_Measure_Date__c, 
      Comments_and_Questions__c, Estimated_Install_Duration__c,
	  Sales_Rep__c, Sales_Rep_Email__c, Sales_Rep_Phone__c,
	  Primary_Tech_Measure_Name__c, Primary_Tech_Measure_Phone__c, Primary_Tech_Measure_Email__c
      from Order where OpportunityId in :opptyIds and isDeleted = false]);

    return orderMap;
  }

  /* @method: queryOrderDiscounts(List<Id> orderIds)
   * @param: List<Id> orderIds
   * @return: List<Order_Discount__c>
   */
    public List<Order_Discount__c> queryOrderDiscounts(Set<Id> orderIds){
    List<Order_Discount__c> odList = [SELECT Id, Name, Discount_Amount__c, Store_Discount__c, Discount_Description__c, Status__c, Order__c from Order_Discount__c where Order__c in :orderIds and isDeleted = false];
    return odList;
  }

  /* @method: queryOrderFinancing(List<Id> orderIds)
   * @param: List<Id> orderIds
   * @return: List<Order_Financing__c>
   */
    public List<Order_Financing__c> queryOrderFinancing(Set<Id> orderIds){
    List<Order_Financing__c> ofList = [SELECT Id, Name, Store_Finance_Program__c, Related_Order__c, Amount_Financed__c, Authorization_Code__c, Expiration_Date__c, Program_Fee__c, Program_Rate__c, rSuite_Id__c from Order_Financing__c where Related_Order__c in :orderIds and isDeleted = false];
    return ofList;
  }

  /* @method: queryOrderItems(List<Id> orderIds)
   * @param: List<Id> orderIds
   * @return: List<OrderItem>
   */
	public List<OrderItem> queryOrderItems(Set<Id> orderIdSet){
		List<Id> orderIds = new List<Id> (orderIdSet);
		String oliQuery = this.buildOLIQuery();
		List<OrderItem> oiList = Database.query(oliQuery);
		return oiList;    
	}


  /* @method: updateOpportunity(Id OppId, String status)
   * @param: Id oppId
   * @param: String status
   * @return: String - JSON string with of SFDC ids of quotes, orders and discounts
   */
    public String resultSalesAppointments(Id userId, String input){
    // parse the input JSON string into an Opportunity Container
    Appointments appts = (Appointments)JSON.deserialize(input, Appointments.class);

//TODO: do some validation before saving the results
// can this opportunity be updated?
// can the quote be updated?
// can the order be updated?
// field level validation?
// how to report errors to rSuite
	//only attempt to save quotes if sales appointments exist
	if (appts.salesAppts != null) {
		// now lets save the quotes to the opportunitiez
		appts = saveQuotes(appts);
		// now lets save the quote line items and discounts to the quotes
		// note that we will need to add the quote ids to quote line items before we can save the quotes
		appts=saveQuoteLineItemsDiscountsandFinancing(appts);
		// now save the opportunity changes
		appts=saveOpportunities(appts);
		// now that we are done lets return the updated records to the client
		// most everything is updated but we need to add the order details that were generated from any closed won opportunities
		appts = updateAppts(appts);
		// process any closed won opportunities by creating work order activities
	} else {
		appts.getErrors().add('No Sales Appointments Found');
	}
    return JSON.serialize(appts);
  }


  /* @method: saveQuotes(Appointments appts)
   * @param: Appointments appts
   * @return: Appointments - comes back with committed quotes and/or error messages
   */
  public Appointments saveQuotes(Appointments appts) {
	List<Quote> quotes = new List<Quote>();
	for (SalesAppointment sa : appts.salesAppts) {
		for (QuoteContainer qc : sa.opptyContainer.quoteContainerList) {
			if (qc.aQuote != null) {
				// When JSON desrializes an Id field - if the Id field is set to "ID=" in the JSON an exception occurs
				// when trying to do an upsert.  This code is to handle that situation
				if (qc.aQuote.Id != null) {
					String temp = (String)qc.aQuote.Id;
					if (temp.equals('')) {
						qc.aQuote.Id = null;
					}	
				}
				// END ID patch
				quotes.add(qc.aQuote);
			}
		}
	}
	if (quotes.size() > 0) {
		// lets set a database save point
		System.SavePoint sp = Database.setSavePoint();
		try {
			Database.UpsertResult[] lsr = Database.upsert(quotes, false);
			for(Database.UpsertResult sr : lsr){
				if (!sr.isSuccess()) {
				// add error messages 
				// Operation failed, so get all errors               
					for(Database.Error err : sr.getErrors()) {
						appts.getErrors().add(err.getStatusCode() + ': ' + err.getMessage() + ': quote fields that affected this error: ' + err.getFields());
					}
				}
			}
		} catch (Exception e) {
			// we've got another error
			// rollback the inserts if possible
			Database.rollBack(sp);
			// put the errors in the appts errors
			appts.getErrors().add('Unhandled exception : ' + e.getMessage() + ' : ' + e.getStackTraceString());
			System.debug(LoggingLevel.ERROR, 'RMS_mobileAppRequestHelper.saveQuotes: Unhandled exception : ' + e.getMessage() + ' : ' + e.getStackTraceString());
		}
	} else {
		appts.getErrors().add('No Quotes Found');
	}
	return appts;
  }

  /* @method: saveQuoteLineItemsDiscountsandFinancing(Appointments appts)
   * @param: Appointments appts
   * @return: Appointments - comes back with committed quote line items, quote discounts and/or error messages
   */
  public Appointments saveQuoteLineItemsDiscountsandFinancing(Appointments appts) {
    List<QuoteLineItem> qliList = new List<QuoteLineItem>();
    List<Quote_Discount__c> qdList = new List<Quote_Discount__c>();
    List<Quote_Financing__c> qfList = new List<Quote_Financing__c>();
    
    for (SalesAppointment sa : appts.salesAppts) {
      for (QuoteContainer qc: sa.opptyContainer.quoteContainerList) {
        // add the quote id to the quote line items and put the quote line items in the list to be inserted
        for (QuoteLineItem qli : qc.quoteLineItems) {
			if (qli.QuoteId == null) {
				// since this is used in inserts and updates we need to set the id only when the qli is net new
				qli.QuoteId = qc.aQuote.Id;
			}
			qliList.add(qli);
        }
        // add the quote id to the quote discounts and put the quote discounts in the list to be inserted
		if (qc.quoteDiscountList != null) {
			for (Quote_Discount__c qd : qc.quoteDiscountList) {
				if (qd.Quote__c == null) {
					// since this is used in inserts and updates we need to set the id only when the qli is net new
					qd.Quote__c = qc.aQuote.Id;
				}
			  qdList.add(qd);
			}
		}
        // add the quote id to the quote financing and put the quote financing in the list to be inserted
		if (qc.quoteFinancingList != null) {
			for (Quote_Financing__c qf : qc.quoteFinancingList) {
				if (qf.Related_Quote__c == null) {
					// since this is used in inserts and updates we need to set the id only when the qli is net new
					qf.Related_Quote__c = qc.aQuote.Id;
				}
			  qfList.add(qf);
			}
		}
      }
    }
    // lets set a database save point
    System.SavePoint sp = Database.setSavePoint();
    try {
      // attempt to insert the quote line item record
      if (qliList.size() > 0) {
        Database.UpsertResult[] lsr = Database.upsert(qliList, false);
        for(Database.UpsertResult sr : lsr){
          if (!sr.isSuccess()) {
            // add error messages 
            // Operation failed, so get all errors               
            for(Database.Error err : sr.getErrors()) {
              appts.getErrors().add(err.getStatusCode() + ': ' + err.getMessage() + ': qli fields that affected this error: ' + err.getFields());
            }
          }
        }
      } else {
        appts.getErrors().add('No Quote Line Items Found');
      }
      // attempt to insert the qoute discount records
      if (qdList.size() > 0) {
        Database.UpsertResult[] lsr = Database.upsert(qdList, false);
        for(Database.UpsertResult sr : lsr){
          if (!sr.isSuccess()) {
            // add error messages 
            // Operation failed, so get all errors               
            for(Database.Error err : sr.getErrors()) {
              appts.getErrors().add(err.getStatusCode() + ': ' + err.getMessage() + ': qoute discount fields that affected this error: ' + err.getFields());
            }
          }
        }
      }
      // attempt to insert the qoute financing records
      if (qfList.size() > 0) {
        Database.UpsertResult[] lsr = Database.upsert(qfList, false);
        for(Database.UpsertResult sr : lsr){
          if (!sr.isSuccess()) {
            // add error messages 
            // Operation failed, so get all errors               
            for(Database.Error err : sr.getErrors()) {
              appts.getErrors().add(err.getStatusCode() + ': ' + err.getMessage() + ': qoute financing fields that affected this error: ' + err.getFields());
            }
          }
        }
      }
    } catch (Exception e) {
      // we've got another error
      // rollback the inserts if possible
      Database.rollBack(sp);
      // put the errors in the appts errors
      appts.getErrors().add('Unhandled exception : ' + e.getMessage() + ' : ' + e.getStackTraceString());
      System.debug(LoggingLevel.ERROR, 'RMS_mobileAppRequestHelper.saveQuoteLineItemsAndDiscounts: Unhandled exception : ' + e.getMessage() + ' : ' + e.getStackTraceString());
    }
    return appts;
  }

  /* @method: saveOpportunities(Appointments appts)
   * @param: Appointments appts
   * @return: Appointments - comes back with committed opportunities and/or error messages
   */
  public Appointments saveOpportunities(Appointments appts) {
    List<Opportunity> oppList = new List<Opportunity>();
    for (SalesAppointment sa : appts.salesAppts) {
      oppList.add(sa.opptyContainer.oppty);
    }
    update oppList;
    return appts;
  }

  /* @method: updateAppts(Appointments appts)
   * @param: Appointments appts
   * @return: Appointments - comes back with any newly created orders, orderitems and orderDiscounts on Closed Won opportunities and/or error messages
   */
  public Appointments updateAppts(Appointments appts) {
    // first find the closed won opportunities
    List<Id> oppIds = new List<Id>();
    for (SalesAppointment sa: appts.salesAppts) {
      if (sa.opptyContainer.oppty.StageName.equals('Closed Won') && sa.opptyContainer.anOrderContainer == null) {
        oppIds.add(sa.opptyContainer.oppty.Id);
      }
    }

    // build the orderContainers
    List<OrderContainer> orcList = buildOrderContainers(oppIds);

    // update the appointments
    for (SalesAppointment sa: appts.salesAppts) {
      if (sa.opptyContainer.oppty.StageName.equals('Closed Won') && sa.opptyContainer.anOrderContainer == null) {
        for (OrderContainer orc : orcList) {
          if (sa.opptyContainer.oppty.Id == orc.anOrder.OpportunityId) {
            sa.opptyContainer.anOrderContainer = orc;
          }
        }
      }
    }
    return appts;
  }

  /* @method: createWorkOrders(Appointments appts)
   * @param: Appointments appts
   * @return: void
   */
/* This is being done in the OrderTrigger now
  public void createWorkOrders(Appointments appts) {
    // first find the closed won opportunities
    List<Order> ordList = new List<Order>();
    List<Id> dwellingIds = new List<Id>();
    for (SalesAppointment sa: appts.salesAppts) {
      if (sa.opptyContainer.oppty.StageName.equals('Closed Won')) {
        ordList.add(sa.opptyContainer.anOrderContainer.anOrder);
        dwellingIds.add(sa.account.Id);
      }
    }
    // get some setup information
    // get record types
       RecordType visitOrderScheduleRecordType = [SELECT id FROM RecordType WHERE SobjectType = 'RbA_Work_Order__c' AND DeveloperName = 'Visit'];
    // get store configruation information through the dwellings
    Map<Id, Account> accountsWithStoresMap = new Map<Id, Account>([select Id, Store_Location__c, Store_Location__r.Active_Store_Configuration__c,
      Store_Location__r.Active_Store_Configuration__r.Install_Work_Order_Queue_Id__c, Store_Location__r.Active_Store_Configuration__r.Tech_Measure_Work_Order_Queue_Id__c
      from Account where Id in : dwellingIds]);
    // now create the tech measure and install work orders for each order
    List<RbA_Work_Order__c> woList = new List<RbA_Work_Order__c>();
    for (Order ord : ordList) {
      // find the Store config to use for this order
      Account ac = accountsWithStoresMap.get(ord.AccountId);
      // build the tech measure work order
        RbA_Work_Order__c techWO = new RbA_Work_Order__c();
        techWO.Sold_Order__c = ord.Id;
        techWO.RecordType = visitOrderScheduleRecordType;
        techWO.Work_Order_Type__c = 'Tech Measure';
        techWO.OwnerId = ac.Store_Location__r.Active_Store_Configuration__r.Tech_Measure_Work_Order_Queue_Id__c;
      // add it to the list
      woList.add(techWO);

      // build the install work order
        RbA_Work_Order__c installWO = new RbA_Work_Order__c();
        installWO.Sold_Order__c = ord.Id;
        installWO.RecordType = visitOrderScheduleRecordType;
        installWO.Work_Order_Type__c = 'Install';
        installWO.OwnerId = ac.Store_Location__r.Active_Store_Configuration__r.Install_Work_Order_Queue_Id__c;
      woList.add(installWO);
    }
    if (woList.size() > 0) {
      // TODO: use Database insert with rollback to catch errors.
      insert woList;
    }
  }
*/
  /* @method: customerSearch(String inputJSON)
   * @param: String inputJSON
   * @return: String
   */
  public String customerSearch(String inputJSON){
	// setup
    DTOCustomerSearchResultsContainer container = new DTOCustomerSearchResultsContainer();
    container.searchResults = new List<DTOCustomerSearchResults>();
	// parse the JSON
    DTOCustomerSearchParameters dtoSearchParams = (DTOCustomerSearchParameters)JSON.deserialize(inputJSON, DTOCustomerSearchParameters.class);

    try{
      //validate that All fields used for query are not null
      if(dtoSearchParams.startDate == null && dtoSearchParams.endDate == null 
		&& String.isBlank(dtoSearchParams.address) && String.isBlank(dtoSearchParams.city) && String.isBlank(dtoSearchParams.state)
		&& String.isBlank(dtoSearchParams.firstName) && String.isBlank(dtoSearchParams.lastName)
		&& String.isBlank(dtoSearchParams.phone) && String.isBlank(dtoSearchParams.email)) {

        container.error = RMS_Settings_map.get('rSuite.search.nullParameters.error').Value__c;
        return JSON.serialize(container);
      }
      String contactRoleQuery = 'Select isPrimary, OpportunityId, Opportunity.CloseDate, Opportunity.Account.ShippingStreet, '+ 
                                'Opportunity.Account.ShippingCity, Opportunity.Account.ShippingStateCode, Contact.FirstName,'+
                                'Contact.LastName, Contact.Email, Contact.Phone FROM OpportunityContactRole WHERE isDeleted = false AND ';

      if(dtoSearchParams.startDate != null){
        Date startDate = dtoSearchParams.startDate;
        contactRoleQuery += 'Opportunity.CloseDate >=: startDate AND ';
      }
      if(dtoSearchParams.endDate != null){
        Date endDate = dtoSearchParams.endDate;
        contactRoleQuery += 'Opportunity.CloseDate <=: endDate AND ';
      }
      if(String.isNotBlank(dtoSearchParams.address)){
        String address = '%'+dtoSearchParams.address+'%';
        contactRoleQuery += 'Opportunity.Account.ShippingStreet Like :address AND ';
      }
      if(String.isNotBlank(dtoSearchParams.city)){
        String city = '%'+dtoSearchParams.city+'%';
        contactRoleQuery += 'Opportunity.Account.ShippingCity Like :city AND ';
      }
      if(String.isNotBlank(dtoSearchParams.state)){
        String state = '%'+dtoSearchParams.state+'%';
        contactRoleQuery += 'Opportunity.Account.ShippingStateCode Like :state AND ';
      }
      if(String.isNotBlank(dtoSearchParams.firstName)){
        String firstName = '%'+dtoSearchParams.firstName+'%';
        contactRoleQuery += 'Contact.FirstName Like :firstName AND ';
      }
      if(String.isNotBlank(dtoSearchParams.lastName)){
        String lastName = '%'+dtoSearchParams.lastName+'%';
        contactRoleQuery += 'Contact.LastName Like :lastName AND ';
      }
      if(String.isNotBlank(dtoSearchParams.email)){
        String email = '%'+dtoSearchParams.email+'%';
        contactRoleQuery += 'Contact.Email Like :email AND ';
      }
      if(String.isNotBlank(dtoSearchParams.phone)){
        String phone = '%'+dtoSearchParams.phone+'%';
        contactRoleQuery += 'Contact.Phone Like :phone ';
      }

      contactRoleQuery = contactRoleQuery.removeEnd('AND ');

      List<OpportunityContactRole> contactRoleResults = Database.query(contactRoleQuery);
      System.debug(contactRoleResults);

		// let's eliminate duplicate opportunities
		Map<Id, OpportunityContactRole> oppIdtoContactRoleMap = new Map<Id, OpportunityContactRole>();
        for(OpportunityContactRole cRole: contactRoleResults){
			if(!oppIdtoContactRoleMap.containsKey(cRole.OpportunityId) || cRole.isPrimary) {
				oppIdtoContactRoleMap.put(cRole.OpportunityId, cRole);
			}
		}
		// check the search result size
		if(oppIdtoContactRoleMap.size() > Integer.valueOf(RMS_Settings_map.get('rSuite.search.maxresults').Value__c)){
			container.error = RMS_Settings_map.get('rSuite.search.tooManyResults.error').Value__c;
			return JSON.serialize(container);
		} else {
			for(OpportunityContactRole cRole: oppIdtoContactRoleMap.values()){
				DTOCustomerSearchResults resultRecord = new DTOCustomerSearchResults();
				resultRecord.firstName = cRole.Contact.FirstName;
				resultRecord.lastName = cRole.Contact.LastName;
				resultRecord.email = cRole.Contact.Email;
				resultRecord.phone = cRole.Contact.Phone;
				resultRecord.address = cRole.Opportunity.Account.ShippingStreet;
				resultRecord.city = cRole.Opportunity.Account.ShippingCity;
				resultRecord.opportunityID = cRole.OpportunityId;
				container.searchResults.add(resultRecord);
			}
		}

    }catch(Exception e){
		System.debug('################## Search Step Exception: ' + e.getMessage());
		System.debug('################## Exception: ' + e.getStackTraceString());
      container.error = e.getMessage();
    }
    return JSON.serialize(container);

  }

  //Should this method be static like customerSearch?
  public String getSelectedSearchResults(String inputJSON){
    
    try{
      List<Id> opportunityIds = (List<Id>)JSON.deserialize(inputJSON, List<Id>.class);
      // get the related events
      List<Event> salesEvents = [SELECT Id, StartDateTime, EndDateTime, Subject, WhoId, WhatId, Type, isCancelled__c FROM Event Where WhatId in :opportunityIds];
      Appointments myAppts = new Appointments();

      // process the sales appointments
      if (salesEvents.size() > 0) {
        myAppts.salesAppts = this.populateSalesAppointments(salesEvents);
      }

      myAppts.getApptsCompletedTimeStamp = Datetime.now();
      return JSON.serialize(myAppts);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e);
      return JSON.serialize(e.getMessage() + ' : ' + e.getStackTraceString());
    }
  }

  public String saveTechMeasure(String inputJSON){
  
    Appointments appt = (Appointments)JSON.deserialize(inputJSON,Appointments.class);
    System.SavePoint sp = Database.setSavePoint();
    try{
      List<Order> ordToUpdate = new List<Order>();
      List<OrderItemContainer> oiContainersToUpsert = new List<OrderItemContainer>();
      List<OrderItem> oiToUpsert = new List<OrderItem>();
      List<TM_Offset__c> TMOffsetToUpsert = new List<TM_Offset__c>();
      List<Opportunity> oppToUpdate = new List<Opportunity>();  
      List<RbA_Work_Order__c> rbaWorkOrdersToUpdate = new List<RbA_Work_Order__c>();
     
      for(TechMeasureAppointment tmAppt: appt.tmAppts){
        oppToUpdate.add(tmAppt.opptyContainer.oppty);
        rbaWorkOrdersToUpdate.add(tmAppt.workOrder);
        OrderContainer oContainer = tmAppt.opptyContainer.anOrderContainer;
        ordToUpdate.add(oContainer.anOrder);  
        oiContainersToUpsert.addAll(oContainer.oiContainerList); 
      }  

      

      Database.SaveResult[] lsr  = Database.update(oppToUpdate, false);
      for(Database.SaveResult sr : lsr){
        if (!sr.isSuccess()) {            
          for(Database.Error err : sr.getErrors()) {
            appt.getErrors().add(err.getStatusCode() + ': ' + err.getMessage() + ': Opportunity fields that affected this error: ' + err.getFields());
          }
        }
      }
      
      lsr = Database.update(rbaWorkOrdersToUpdate, false);
      for(Database.SaveResult sr : lsr){
        if (!sr.isSuccess()) {            
          for(Database.Error err : sr.getErrors()) {
            appt.getErrors().add(err.getStatusCode() + ': ' + err.getMessage() + ': RBA Work Order fields that affected this error: ' + err.getFields());
          }
        }
      }

      for(OrderItemContainer oiCon: oiContainersToUpsert){
        oiToUpsert.add(oiCon.oi);
      }    

      Database.UpsertResult[] lur = Database.upsert(oiToUpsert, false);
      for(Database.UpsertResult ur : lur){
        if (!ur.isSuccess()) {        
          for(Database.Error err : ur.getErrors()) {
            appt.getErrors().add(err.getStatusCode() + ': ' + err.getMessage() + ': Order Item fields that affected this error: ' + err.getFields());
          }
        }
      }

      for(OrderItemContainer oiCon: oiContainersToUpsert){
		if (oiCon.tmOffSetList != null) {
			for(TM_Offset__c tmOff: oiCon.tmOffSetList){
			  tmOff.Order_Line__c = oiCon.oi.Id;
			  TMOffsetToUpsert.add(tmOff);
			}     
		}
      }   
     
     lur = Database.upsert(TMOffsetToUpsert, false);
      for(Database.UpsertResult ur : lur){
        if (!ur.isSuccess()) {            
          for(Database.Error err : ur.getErrors()) {
            appt.getErrors().add(err.getStatusCode() + ': ' + err.getMessage() + ': Tech Measure Offset fields that affected this error: ' + err.getFields());
          }
        }
      }

      //Update Order last, as activated orders do not allow addition of orderitems
     lsr = Database.update(ordToUpdate, false);
      for(Database.SaveResult sr : lsr){
        if (!sr.isSuccess()) {            
          for(Database.Error err : sr.getErrors()) {
            appt.getErrors().add(err.getStatusCode() + ': ' + err.getMessage() + ': Order fields that affected this error: ' + err.getFields());
          }
        }
      }

    }catch(Exception e){
      Database.rollBack(sp);
      appt.getErrors().add('Unhandled exception : ' + e.getMessage() + ' : ' + e.getStackTraceString());
    }

    return JSON.serialize(appt);
  
  }
  
  public class Appointments {
    public List<SalesAppointment> salesAppts;
    public List<TechMeasureAppointment> tmAppts;
    public Datetime getApptsCompletedTimeStamp;
    private String[] errors;
    public String[] getErrors() { 
      if (errors == null) { 
        errors = new String[]{};
      } 
      return errors;
    }
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
    public List<Order_Discount__c> orderDiscountList {get; set;}
    public List<Order_Financing__c> orderFinancingList {get; set;}
    public List<OrderItemContainer> oiContainerList{get;set;}
  }

  public class OrderItemContainer{
    public OrderItem oi {get;set;}
    public List<TM_Offset__c> tmOffSetList {get;set;}
    public List<Change_History__c> changeHistoryList {get;set;}
  }

  public class QuoteContainer {
    public Quote aQuote {get; set;}
    public List<QuoteLineItem>  quoteLineItems {get; set;}
    public List<Quote_Discount__c> quoteDiscountList {get; set;}
    public List<Quote_Financing__c> quoteFinancingList {get; set;}
  }

  public class DTOCustomerSearchParameters{
    public String firstName {get;set;}
    public String lastName {get;set;}
    public String address {get;set;}
    public String city {get;set;}
    public String state {get;set;}
    public String phone {get;set;}
    public String email {get;set;}
    public Date startDate {get;set;}
    public Date endDate {get;set;}
  }

  public class DTOCustomerSearchResultsContainer{
    public List<DTOCustomerSearchResults> searchResults{get;set;}
    public String error{get;set;}
  }
  public class DTOCustomerSearchResults{
    public String firstName {get;set;}
    public String lastName {get;set;}
    public String address {get;set;}
    public String city {get;set;}
    public String phone {get;set;}
    public String email {get;set;}
    public String opportunityID {get;set;}
  }

}
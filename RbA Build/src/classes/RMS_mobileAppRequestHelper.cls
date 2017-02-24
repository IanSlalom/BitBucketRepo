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
	private static final String SINGLE_ERROR_HEADER = 'An error occured while attempting to save appointement {0}: Please contact technical support.  Error Id:{1}\n';
	private static final String MULTILE_ERROR_HEADER = 'Multipe errors occured while attempting to save appointment {0}: Please contact technical support.  Error Id:{1}\n';
	private static final String RECORD_ERROR_MESSAGE = 'Object:{0} :Fields:{1} :Error Status Code:{2} :Error Message:{3}\n';
	private static final String EXCEPTION_ERROR_MESSAGE = 'Object:{0} :Unhandled Exception:{1} :Exception Stack Trace:{2}\n';
	private static final String GET_APPTS_EXCEPTION_ERROR_MESSAGE = 'GetAppointments:Unhandled Exception:{0} :Exception Stack Trace:{1}: Error Id:{2}\n';
	private static String SHARED_FIELDS;
	// fields unique to Quote line items
	private static final String QLI_QUERY_START = 'SELECT LineNumber, QuoteId, Subtotal, TotalPrice, Parent_Quote_Line_Item__c, isInactive__c, isDeleted';
	private static final String QLI_WHERE_CLAUSE = 'from QuoteLineItem where QuoteId in :quoteIds and isDeleted = false order by Unit_Id__c, Product_Class__c';

	// fields unique to Order line items
	private static final String OLI_QUERY_START = 'SELECT Cancelled__c, Cancelled_Date__c, isTechMeasureComplete__c, Parent_Order_Item__c, ' + 
	'OrderItemNumber, OrderId, QuoteLineItemId, Height_Inches__c, Height_Fraction__c, NSPR__c, NSPR_Number__c, Sill_Angle__c, ' + 
	'Variant_Number__c, Unit_Wholesale_Cost__c, Width_Fraction__c, Width_Inches__c, Unit_of_Measure__c,' +
	'Meet_Rail_Dimension__c, Is_Height_L_or_R_Leg_Height__c, Leg_Height_Interior_Whole_Inch__c, Leg_Height_Interior_Fraction__c,' +
	'Leg_Height_Exterior_Whole_Inch__c, Leg_Height_Exterior_Fraction__c, Is_Leg_Height_L_or_R_Leg_Height__c,' +
	'isJobMaterial__c, isJobConstructionDetail__c' ;
	private static final String OLI_WHERE_CLAUSE = 'from OrderItem where OrderId in :orderIds and isDeleted = false order by Unit_Id__c, Product_Class__c';
	// Opporunity Query
	private static final String OPP_QUERY = 'SELECT Id, Name, CloseDate, StageName, AccountId, isClosed, Pricebook2Id, Window_Problems__c, rSuite_Id__c,' +
	    	'rSuite_Id_1st_Selected_Quote__c, rSuite_Id_2nd_Selected_Quote__c, First_Selected_Quote__c, Second_Selected_Quote__c, ' +
	    	'Sales_Rep_Name__c, Sales_Rep_Email__c, Sales_Rep_Phone__c FROM Opportunity';
	
  /* @method: getUnsoldAge(Id userId)
   * @param: Id userId - user who the appointements are assigned to
   * @return: Integer
   */
  public Integer getUnsoldAge(Id userId){
	User u = [select Username, Default_Store_Location__c from User where Id = :userId limit 1];
	Account a = [select Active_Store_Configuration__r.rSuite_Configuration__r.Unsold_Age_In_Months__c from Account where Name = :u.Default_Store_Location__c and RecordType.DeveloperName = 'Store' limit 1];
	return a.Active_Store_Configuration__r.rSuite_Configuration__r.Unsold_Age_In_Months__c.intValue();
  }

  /* @method: findAppointments(Id userId)
   * @param: Id userId - user who the appointements are assigned to
   * @return: String - JSON string of the appointments data
   */
  public String findAppointments(Id userId){
    try {
	  //get all sales opportunities assigned to me excluding old ones
	  Integer unSoldAge = getUnsoldAge(userId);
	  Date afterDate = Date.today().addMonths(-unSoldAge);
	  String whereClause = 'where OwnerId = :userId and isDeleted = false and ((StageName != \'Canceled\' and ' +
	  	'StageName != \'New\' and StageName != \'In Progress\' and StageName != \'Quoted\') or ' +
	  	'((StageName = \'New\' or StageName = \'In Progress\' or StageName = \'Quoted\') and CloseDate > :afterDate))';	  
	  String query = OPP_QUERY + ' ' + whereClause;
	  Map<Id, Opportunity> salesOpportunityMap = new Map<Id, Opportunity>((List<Opportunity>)Database.query(query));

	  filterOppbyOrderStatus(salesOpportunityMap);
      List<Event> salesEvents = [SELECT Id, StartDateTime, EndDateTime, Synced_DateTime__c, Subject, WhoId, WhatId, Type, isCancelled__c FROM Event Where OwnerId =: userId and WhatId in: salesOpportunityMap.keySet()];

      // get all my appoints in the last year and going forward
      Datetime myTimeStamp = Datetime.now().addYears(-1);
      List<Event> techmEvents = [SELECT Id, StartDateTime, EndDateTime, Synced_DateTime__c, Subject, WhoId, WhatId, Type, isCancelled__c FROM Event Where OwnerId =: userId and StartDateTime >= :myTimeStamp and Type = 'Tech Measure'];
      System.debug('RMS_mobileAppRequestHelper.findAppointments: salesEvents: ' + salesEvents);
      System.debug('RMS_mobileAppRequestHelper.findAppointments: tmEvents: ' + techmEvents);

      Appointments myAppts = new Appointments();
      // process the sales appointments
      if (salesEvents.size() > 0) {
        myAppts.salesAppts = this.populateSalesAppointments(salesEvents,salesOpportunityMap);
        for(Event e : salesEvents){
		  //only set this if its not been set
		  if (e.Synced_DateTime__c == null) {
	          e.Synced_DateTime__c = Datetime.now();
		  }
        }
        update salesEvents;
      }

      // process the tech measure appointmsnts
      if (techmEvents.size() > 0) {
        myAppts.tmAppts = this.populateTMAppointments(techmEvents);
        for(Event e : techmEvents){
		  //only set this if its not been set
		  if (e.Synced_DateTime__c == null) {
	          e.Synced_DateTime__c = Datetime.now();
		  }
        }
         update techmEvents;
      }
      myAppts.getApptsCompletedTimeStamp = Datetime.now();
      return JSON.serialize(myAppts);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e);
	  System.debug(LoggingLevel.Error, e.getStackTraceString());
	  String message = e.getMessage() + '::' + e.getStackTraceString();
	  Id supportLogId = UtilityMethods.supportLog('RMS', 'RMS_mobileApplicationAPIController.doGet', message, null, userId);
	  String[] errParms = new String[]{e.getMessage(), e.getStackTraceString(), supportLogId};
	  String formattedMessage = String.format(GET_APPTS_EXCEPTION_ERROR_MESSAGE, errParms);
      Appointments myAppts = new Appointments();
      myAppts.getErrors().add(formattedMessage);
      return JSON.serialize(myAppts);
    }
  }

	/* @method: filterOppbyOrderStatus(Map<Id, Opportunity> oppsToFilter)
	 * @param: Map<Id,Opportunity> oppsToFilter - map of opportunities that will be filtered by attached orders
	 * @return: void
	 */
	public void filterOppbyOrderStatus(Map<Id,Opportunity> oppsToFilter) {
	    /* this method will use CORO and ARO orders to filter out opportunities that should not be returned by get appointments
	     * this means that Service Orders will not be used to filter opportunities
	     * - a point of clarification Service Orders will not be attached to opportunities so we only need to worry about CORO and ARO Order Statuses
	     */
	    List<String> orderFilter = new List<String>{'Pending Cancellation','Cancelled','Job Closed','Activated'};
		
	    List<Order> filterOrders = [select Id, OpportunityId, Status from Order where Status not in :orderFilter and OpportunityId in :oppsToFilter.keySet()];
	    // remove rows found
	    for (Opportunity opp : oppsToFilter.values()) {
	    	Boolean found = false;
	    	if (opp.StageName != 'New' && opp.StageName != 'In Progress' && opp.StageName != 'Quoted') {
	    		for (Order ord : filterOrders) {
	    			if (ord.OpportunityId == opp.Id) {
	    				found = true;
	    				break;
	    			}
	    		}
	    		if (found == false) {
	    			oppsToFilter.remove(opp.Id);
	    		} 
	    	}
	    }
	}

  /* @method: populateSalesAppointments(List<Id> opptyIds)
   * @param: List<Id> opptyIds - list of opportunity ids that will be used to build the sales appointments
   * @return: String - JSON string with of SFDC ids of quotes, orders and discounts
   */
  public List<SalesAppointment> populateSalesAppointments(List<Event> salesEvents, Map<Id, Opportunity> salesOppsMap) {
    List<SalesAppointment> salesAppts = new List<SalesAppointment>();
    List<Id> accountIdList = new List<Id>();
    // get the opportunities with quotes and orders
    Map<Id, OpportunityContainer> relatedOCs = populateOpportunityStructure(salesOppsMap);

    // get the Accounts(Dwellings)
    for (OpportunityContainer oc: relatedOCs.values()) {
      accountIdList.add(oc.oppty.AccountId);
    }
	//TODO: Validate that these fields are nut null, otherwise this will blow up
    Map<Id, Account> relatedAccountMap = new Map<Id, Account>([SELECT Id, Name, Dwelling_Style__c, Shipping_County__c, ShippingCity, ShippingCountryCode, ShippingLatitude, 
      ShippingLongitude, ShippingPostalCode, ShippingStateCode, ShippingStreet, Year_Built__c, Historical__r.Name, HOA__r.Name 
      FROM Account WHERE Id IN :accountIdList and isDeleted = false]);

    // get the historic opportunites
    /* not currently used by rSuite
    Map<Id, List<OpportunityContainer>> hocListMap = populateHistoricOpportunities(accountIdList, opportunityIdList);
    */

    // get the contacts using the OpportunityContactRoles
    List<OpportunityContactRole> relatedOppContacts = [select Id, contactId, isPrimary, opportunityId, Role, 
      Contact.Id, Contact.FirstName, Contact.LastName, Contact.Email, Contact.HomePhone, 
      Contact.MobilePhone, Contact.OtherPhone, Contact.Phone, Contact.Salutation, 
      Contact.Comments__c, Contact.Preferred_Method_of_Contact__c, Contact.Spouse__c
      from OpportunityContactRole where isDeleted = false and opportunityId in :salesOppsMap.keySet() order by opportunityId];

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
	  // rSuite currently does not support historic opportunities
	  //sapt.historicOpptyContainerList = hocListMap.get(sapt.opptyContainer.oppty.AccountId); 
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
	//TODO: Validate that these fields are nut null, otherwise this will blow up

    // opportunity ids
    // account ids
    List<Id> opportunityIds = new List<Id>();
    List<Id> accountIds = new List<Id>();
    for (RbA_Work_Order__c wo : workOrderList) {
      opportunityIds.add(wo.Sold_Order__r.OpportunityId);
      accountIds.add(wo.Sold_Order__r.Opportunity.AccountId);
    }
	String whereClause = 'where Id in :opportunityIds';
	String query = OPP_QUERY + ' ' + whereClause;
	Map<Id, Opportunity> relatedOpportunityMap = new Map<Id, Opportunity>((List<Opportunity>)Database.query(query));

    // get the accounts
	//TODO: Validate that these fields are nut null, otherwise this will blow up
    Map<Id, Account> relatedAccountMap = new Map<Id, Account>([SELECT Id, Name, Dwelling_Style__c, Shipping_County__c, ShippingCity, ShippingCountryCode, ShippingLatitude, 
      ShippingLongitude, ShippingPostalCode, ShippingStateCode, ShippingStreet, Year_Built__c, Historical__r.Name, HOA__r.Name 
      FROM Account WHERE Id IN :accountIds and isDeleted = false]);

    // get the opportunities with quotes and orders
    Map<Id, OpportunityContainer> relatedOCs = populateOpportunityStructure(relatedOpportunityMap);

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
    
  /* This is not currently used by rSuite - commenting out the code */
  /* @method: populateHistoricOpportunities(List<Id> opptyIds)
   * @param: List<Id> accoutnIds - list of accountIds that will be used to find the opportunities
   * @param: List<Id> opportunityIds - list of opportunities to exclude from this list
   * @return:Map of List of OpportunityContainers mapped to account (dwelling Ids) excluding the passed in oppIds
   */
/*  public Map<Id, List<OpportunityContainer>> populateHistoricOpportunities(List<Id> acctIds, List<Id> oppIds) {
    Map<Id, Opportunity> hoMap = new Map<Id, Opportunity>([SELECT Id from Opportunity where Id NOT in :oppIds and AccountId in :acctIds]);
    Map<Id, OpportunityContainer> hocsMap = populateOpportunityStructure(hoMap);

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
*/

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
   * @param: Map<Id, Opportunity> relatedOpportunityMap - map of opportunities that will be used to build the sales appointments
   * @return: Map<Id, OpportunityContainer> containing all new appointment opportunities
   */
  public Map<Id, OpportunityContainer> populateOpportunityStructure(Map<Id, Opportunity> relatedOpportunityMap) {
    Map<Id, OpportunityContainer> ocMap = new Map<Id, OpportunityContainer>();
    // get the quotes 
    Map<Id, Quote> quoteMap = new Map<Id, Quote>([SELECT Id, Name, isSold__c, OpportunityId, Pricebook2Id, QuoteNumber, Subtotal, Discount_Amount__c, Total__c, rSuite_Id__c, Sub_Total__c from Quote where OpportunityId in :relatedOpportunityMap.keySet() and isDeleted = false and Status != 'Cancelled']);
	List<Id> quoteIds = new List<Id> (quoteMap.keySet());
	// note that the variable quoteIds is used in the query
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
    List<OrderContainer> orcList = buildOrderContainers(new List<Id>(relatedOpportunityMap.keySet()));

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
		from Change_History__c where isDeleted = false and Order_Product__c in : oiList and RecordType.DeveloperName = 'Order_Product' and Subtype__c = 'Change'
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
	  Primary_Tech_Measure_Name__c, Primary_Tech_Measure_Phone__c, Primary_Tech_Measure_Email__c,
	  Cancel_Eligible__c, Apex_Context__c, QuoteId
      from Order where OpportunityId in :opptyIds and isDeleted = false and Status != 'Cancelled' and Status != 'Pending Cancellation']);

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
		System.debug('RMS_mobileAppRequestHelper.resultSalesAppointments input JSON: ' + input);
		SalesAppointment appt = (SalesAppointment)JSON.deserialize(input, SalesAppointment.class);
		System.Debug('RMS_mobileAppRequestHelper.resultSalesAppointments parsed JSON structure =' +appt);

		// TODO: do some validation before saving the results
		// can this opportunity be updated?
		// can the quote be updated?
		// can the order be updated?
		// field level validation?
		// only attempt to save quotes if sales appointments exist
		if (appt != null) {
			System.SavePoint sp = Database.setSavePoint();
			// process deletes
			appt = processDeletes(appt);
			try {
				// note that the appt.getErrors.size check is made multiple times because errors can be added each step alson the way
				// now lets save the quotes to the opportunitiez
				if (appt.getErrors().size() == 0) {
					appt = saveQuotes(appt);
				}
				// now lets save the quote line items and discounts to the quotes - if we don't have an error
				if (appt.getErrors().size() == 0) {
					appt=saveQuoteLineItemsDiscountsandFinancing(appt);
				}
			} catch (NoQuotesException e) {
				// this is a no-op -basically there were no quotes on the appointment so nothing to save
			}
			// now save the opportunity changes - if we don't have an error
			if (appt.getErrors().size() == 0 && appt.opptyContainer != null && appt.opptyContainer.oppty != null) {
				Database.SaveResult sr  = Database.update(appt.opptyContainer.oppty, false);
				if (!sr.isSuccess()) {            
					String[] errParms = null;
					for(Database.Error err : sr.getErrors()) {
						String fields = '';
						for (String field : err.getFields()) {
							fields = fields + field + ', ';
						}
						errParms = new String[]{'Opportunity',fields, err.getStatusCode().name(), err.getMessage()};
						String formattedMessage = String.format(RECORD_ERROR_MESSAGE, errParms);
						appt.getErrors().add(formattedMessage);
					}
				}
			}
			// roll back if we have errors
			if (appt.getErrors().size() > 0) {
				Database.rollBack(sp);
				appt.isSaveSuccessful = false;
			}
		} else {
			appt.getErrors().add('No Sales Appointments Found');
			appt.isSaveSuccessful = false;
		}
		// write any errors to the support log
		String apptName = null;
		if (appt.opptyContainer != null && appt.opptyContainer.oppty != null) {
			apptName = appt.opptyContainer.oppty.Name;
		}
		appt.errors = formatandLogErrors(appt.getErrors(), 'RMS_mobileAppRequestHelper.resultSalesAppointments', apptName, input);
		appt.saClear();
		return JSON.serialize(appt);
	}


  /* @method: saveQuotes(SalesAppointment sa)
   * @param: SalesAppointment sa
   * @return: SalesAppointment - comes back with committed quotes and/or error messages
   */
  public SalesAppointment saveQuotes(SalesAppointment sa) {
	List<Quote> quotes = new List<Quote>();
	if (sa.opptyContainer != null  && sa.opptyContainer.quoteContainerList != null) {
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
		try {
			Database.UpsertResult[] lsr = Database.upsert(quotes, false);
			for(Database.UpsertResult sr : lsr){
				if (!sr.isSuccess()) {
					// add error messages 
					// Operation failed, so get all errors
					String[] errParms = null;
					for(Database.Error err : sr.getErrors()) {
						String fields = '';
						for (String field : err.getFields()) {
							fields = fields + field + ', ';
						}
						errParms = new String[]{'Quote',fields, err.getStatusCode().name(), err.getMessage()};
						String formattedMessage = String.format(RECORD_ERROR_MESSAGE, errParms);
						sa.getErrors().add(formattedMessage);
					}
				}
			}
		} catch (Exception e) {
			// we've got another error
			// put the errors in the appts errors
			String[] errParms = new String[]{'Quote', e.getMessage(), e.getStackTraceString()};
			String formattedMessage = String.format(EXCEPTION_ERROR_MESSAGE, errParms);
			sa.getErrors().add(formattedMessage);
			System.debug(LoggingLevel.ERROR, 'RMS_mobileAppRequestHelper.saveQuotes:' + formattedMessage);
		}
	} else {
		throw new NoQuotesException();
	}
	return sa;
  }

  /* @method: saveQuoteLineItemsDiscountsandFinancing(SalesAppointment sa)
   * @param: SalesAppointment sa
   * @return: SalesAppointment - comes back with committed quote line items, quote discounts and/or error messages
   */
  public SalesAppointment saveQuoteLineItemsDiscountsandFinancing(SalesAppointment sa) {
    List<QuoteLineItem> qliList = new List<QuoteLineItem>();
    List<Quote_Discount__c> qdList = new List<Quote_Discount__c>();
    List<Quote_Financing__c> qfList = new List<Quote_Financing__c>();
    
    for (QuoteContainer qc: sa.opptyContainer.quoteContainerList) {
		// add the quote id to the quote line items and put the quote line items in the list to be inserted
		if (qc.quoteLineItems != null) {
			for (QuoteLineItem qli : qc.quoteLineItems) {
				if (qli.QuoteId == null) {
					// since this is used in inserts and updates we need to set the id only when the qli is net new
					qli.QuoteId = qc.aQuote.Id;
				}
				qliList.add(qli);
			}
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
	// now set the master product on the qli if its not set - the child product might only be set
	// also link the line items together in parent/child relationships
	List<QuoteLineItem> clist = new List<QuoteLineItem>();
	if (qliList.size() > 0) {
		qliList = addMasterProducts(qliList);
		// now separate the qlis into two buckets - one of parent line items and one of child line items
		// child line items will need to be linked to their parents
		for(QuoteLineItem qli : qliList) {
			if (qli.Parent_Unit_rSuite_Id__c != null && !qli.Parent_Unit_rSuite_Id__c.equals('')) {
				// only if the parent unit is not set prep it for update
				if (qli.Parent_Quote_Line_Item__c == null) {
					clist.add(qli);
				}
			}
		}
	}

    try {
      // attempt to insert the quote line item record
      if (qliList.size() > 0) {
        Database.UpsertResult[] lsr = Database.upsert(qliList, false);
        for(Database.UpsertResult sr : lsr){
          if (!sr.isSuccess()) {
            // add error messages 
            // Operation failed, so get all errors               
			String[] errParms = null;
			for(Database.Error err : sr.getErrors()) {
				String fields = '';
				for (String field : err.getFields()) {
					fields = fields + field + ', ';
				}
				errParms = new String[]{'Quote Line Item',fields, err.getStatusCode().name(), err.getMessage()};
				String formattedMessage = String.format(RECORD_ERROR_MESSAGE, errParms);
				sa.getErrors().add(formattedMessage);
			}
          }
        }
        // now link the children to the parents
        if (clist.size() > 0) {
        	for (QuoteLineItem cqli: clist) {
        		for (QuoteLineItem qli: qliList) {
        			if (cqli.Parent_Unit_rSuite_Id__c.equals(qli.rSuite_Id__c)) {
        				cqli.Parent_Quote_Line_Item__c = qli.Id;
        				break;
        			}
        		}
        	}
        	// now update these records
        	Database.SaveResult[] ulsr = Database.update(cList, false);
        	for (Database.SaveResult ur: ulsr) {
	          if (!ur.isSuccess()) {
	            // add error messages 
	            // Operation failed, so get all errors               
				String[] errParms = null;
				for(Database.Error err : ur.getErrors()) {
					String fields = '';
					for (String field : err.getFields()) {
						fields = fields + field + ', ';
					}
					errParms = new String[]{'Quote Line Item',fields, err.getStatusCode().name(), err.getMessage()};
					String formattedMessage = String.format(RECORD_ERROR_MESSAGE, errParms);
					sa.getErrors().add(formattedMessage);
				}
	          }
        	}
        }
      }
      // attempt to insert the qoute discount records
      if (qdList.size() > 0) {
        Database.UpsertResult[] lsr = Database.upsert(qdList, false);
        for(Database.UpsertResult sr : lsr){
          if (!sr.isSuccess()) {
            // add error messages 
            // Operation failed, so get all errors               
			String[] errParms = null;
			for(Database.Error err : sr.getErrors()) {
				String fields = '';
				for (String field : err.getFields()) {
					fields = fields + field + ', ';
				}
				errParms = new String[]{'Quote Discount',fields, err.getStatusCode().name(), err.getMessage()};
				String formattedMessage = String.format(RECORD_ERROR_MESSAGE, errParms);
				sa.getErrors().add(formattedMessage);
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
			String[] errParms = null;
			for(Database.Error err : sr.getErrors()) {
				String fields = '';
				for (String field : err.getFields()) {
					fields = fields + field + ', ';
				}
				errParms = new String[]{'Quote Financing',fields, err.getStatusCode().name(), err.getMessage()};
				String formattedMessage = String.format(RECORD_ERROR_MESSAGE, errParms);
				sa.getErrors().add(formattedMessage);
			}
          }
        }
      }
    } catch (Exception e) {
      // we've got another error
      // put the errors in the appts errors
		String[] errParms = new String[]{'QuoteLineItem,QuoteDiscount,QuoteFinancing', e.getMessage(), e.getStackTraceString()};
		String formattedMessage = String.format(EXCEPTION_ERROR_MESSAGE, errParms);
		sa.getErrors().add(formattedMessage);
		System.debug(LoggingLevel.ERROR, 'RMS_mobileAppRequestHelper.saveQuoteLineItemsAndDiscounts:' + formattedMessage);
    }
    return sa;
  }

  /* @method: addMasterProducts(List<QuoteLineItem> qlis)
   * @param: Appointments appts
   * @return: List<QuoteLineItem> - updated quote line item list - with the master product in the PricebookEntryId field
   */
  public List<QuoteLineItem> addMasterProducts(List<QuoteLineItem> qlis) {
	// get the PBE's for the child products
	Set<Id> childProductPBESet = new Set<Id>();
	for (QuoteLineItem qli: qlis) {
		if (qli.Child_Product_Pricebook_Entry_Id__c != null && qli.Child_Product_Pricebook_Entry_Id__c != '' &&
			qli.PricebookEntryId == null) {
			childProductPBESet.add(qli.Child_Product_Pricebook_Entry_Id__c);
		}
	}
	// get the larger child product PBEs with product, master product and Pricebook ids
	Map<Id, PricebookEntry> cpPBEMap = new Map<Id, PricebookEntry>([
		select Id, Product2Id, Pricebook2Id, Product2.rSuite_Product_Type__c, Product2.RecordType.DeveloperName, Product2.Master_Product__c, Product2.Master_Product__r.Master_Product__c 
		from PricebookEntry 
		where Id in :childProductPBESet and 
		(Product2.RecordType.DeveloperName = :Constants.CHILD_PRODUCT_RECORD_TYPE_NAME or 
		Product2.RecordType.DeveloperName = :Constants.MULLION_PRODUCT_RECORD_TYPE_NAME)
		order by Pricebook2Id ASC
	]);
	
	// now group the master products by pricebook
	Map<Id,List<Id>> pbToMasterProductListMap = new Map<Id,List<Id>>();
	for (PricebookEntry cpPBE : cpPBEMap.values()) {
		If (cpPBE.Product2.Master_Product__c != null) {
			List<Id> masterProductIdList = pbToMasterProductListMap.get(cpPBE.Pricebook2Id);
			if (masterProductIdList == null) {
				// create a new list and add it to the map
				masterProductIdList = new List<Id>();
				pbToMasterProductListMap.put(cpPBE.Pricebook2Id,masterProductIdList);
			}
			// add the master product to the list
			if (cpPBE.Product2.Master_Product__r.Master_Product__c != null && cpPBE.Product2.rSuite_Product_Type__c.equals('Specialty')) {
				masterProductIdList.add(cpPBE.Product2.Master_Product__r.Master_Product__c);
			} else {
				masterProductIdList.add(cpPBE.Product2.Master_Product__c);
			}
		}
	}

	// now select the pbes for the master products and pricebook
	List<PricebookEntry> mpPBEList = new List<PricebookEntry>();
	For (Id pbId : pbToMasterProductListMap.keySet()) {
		List<Id> masterProdIds = pbToMasterProductListMap.get(pbId);
		List<PricebookEntry> tempList = [
			select Id, Product2Id, Pricebook2Id from PricebookEntry 
			where Product2Id in :masterProdIds and Pricebook2Id = :pbId
		];
		mpPBEList.addAll(tempList);
	}

	// finally update the qlis
	for (QuoteLineItem qli: qlis) {
		if (qli.Child_Product_Pricebook_Entry_Id__c != null && qli.Child_Product_Pricebook_Entry_Id__c != '' &&
			qli.PricebookEntryId == null) {
			PricebookEntry cpPBE = cpPBEMap.get(qli.Child_Product_Pricebook_Entry_Id__c);
			if (cpPBE != null) {
				for (PricebookEntry mpPBE : mpPBEList) {
					if (cpPBE.Product2.rSuite_Product_Type__c != null && 
						cpPBE.Product2.rSuite_Product_Type__c.equals('Specialty') && 
						cpPBE.Product2.Master_Product__r.Master_Product__c != null) {
						if (mpPBE.Pricebook2Id == cpPBE.Pricebook2Id && mpPBE.Product2Id == cpPBE.Product2.Master_Product__r.Master_Product__c) {
							// we have a match
							qli.PricebookEntryId = mpPBE.Id;
							break;
						}
					} else {
						if (mpPBE.Pricebook2Id == cpPBE.Pricebook2Id && mpPBE.Product2Id == cpPBE.Product2.Master_Product__c) {
							// we have a match
							qli.PricebookEntryId = mpPBE.Id;
							break;
						}
					}
				}
			}
		}
	}

	// now handle any non chlld products
	for (QuoteLineItem qli: qlis) {
		if (qli.Child_Product_Pricebook_Entry_Id__c != null && qli.Child_Product_Pricebook_Entry_Id__c != '' &&
			qli.PricebookEntryId == null) {
			qli.PricebookEntryId = qli.Child_Product_Pricebook_Entry_Id__c;
		}
	}

    return qlis;
  }

  /* @method: processDeletes(SalesAppointment sa)
   * @param: SalesAppointment sa
   * @return: SalesAppointment - comes back with any deleted records deleted from SF and removed from the SalesAppointment
   *          structure and/or errors
   */
  public SalesAppointment processDeletes(SalesAppointment sa) {
	List<Id> recordsToDelete = new List<Id>();
	if (sa.opptyContainer != null  && sa.opptyContainer.quoteContainerList != null) {
		for (Integer i = 0; i < sa.opptyContainer.quoteContainerList.size(); i++) {
			QuoteContainer qc = sa.opptyContainer.quoteContainerList[i];
			if (qc.aQuote != null) {
				if (qc.aQuote.IsDeleted != null && qc.aQuote.IsDeleted == true) {
					// we have a quote to delete from the structure
					// When JSON desrializes an Id field - if the Id field is set to "ID=" in the JSON it sets the ID to a blank
					// string so we need to handle that situation
					if (qc.aQuote.Id != null && !((String)(qc.aQuote.Id)).equals('')) {
						// we have a quote that can be deleted from Salesforce
						recordsToDelete.add(qc.aQuote.Id);
					}
					// remove the quote from in memory structure
					sa.opptyContainer.quoteContainerList.remove(i);
					//decrement because the list got shorter
					i--;
				} else {
					//check for deleted QuoteLineItems, Quote Discounts and Quote Financing records
					// delete quote line items
					if (qc.quoteLineItems != null) {
						for (Integer j = 0; j < qc.quoteLineItems.size(); j++) {
							QuoteLineItem qli = qc.quoteLineItems[j];
							if (qli.isDeleted != null && qli.isDeleted == true) {
								// we have a qli marked for deletion
								if (qli.Id != null && !((String)(qli.Id)).equals('')) {
									// we have a quote line item that can be deleted from Salesforce
									recordsToDelete.add(qli.Id);
								}
								// remove from the in memory qli list
								qc.quoteLineItems.remove(j);
								//decrement because the list got shorter
								j--;
							}
						}
					}
					// delete quote discounts
					if (qc.quoteDiscountList != null) {
						for (Integer j = 0; j < qc.quoteDiscountList.size(); j++) {
							Quote_Discount__c qd = qc.quoteDiscountList[j];
							if (qd.isDeleted != null && qd.isDeleted == true) {
								// we have a qli marked for deletion
								if (qd.Id != null && !((String)(qd.Id)).equals('')) {
									// we have a quote line item that can be deleted from Salesforce
									recordsToDelete.add(qd.Id);
								}
								// remove from the in memory qli list
								qc.quoteDiscountList.remove(j);
								//decrement because the list got shorter
								j--;
							}
						}
					}
					// delete quote financing
					if (qc.quoteFinancingList != null) {
						for (Integer j = 0; j < qc.quoteFinancingList.size(); j++) {
							Quote_Financing__c qf = qc.quoteFinancingList[j];
							if (qf.isDeleted != null && qf.isDeleted == true) {
								// we have a qli marked for deletion
								if (qf.Id != null && !((String)(qf.Id)).equals('')) {
									// we have a quote line item that can be deleted from Salesforce
									recordsToDelete.add(qf.Id);
								}
								// remove from the in memory qli list
								qc.quoteFinancingList.remove(j);
								//decrement because the list got shorter
								j--;
							}
						}
					}
				}
			}
		}
		// delete the records from Salesforce
		if (recordsToDelete.size() > 0) {
			Database.DeleteResult[] ldr = Database.delete(recordsToDelete, false);
			for(Database.DeleteResult dr : ldr){
				if (!dr.isSuccess()) {
					// add error messages 
					// Operation failed, so get all errors               
					String[] errParms = null;
					for(Database.Error err : dr.getErrors()) {
						String fields = '';
						for (String field : err.getFields()) {
							fields = fields + field + ', ';
						}
						errParms = new String[]{'Quote,QuoteLineItem,QuoteDiscount,QuoteFinancing',fields, err.getStatusCode().name(), err.getMessage()};
						String formattedMessage = String.format(RECORD_ERROR_MESSAGE, errParms);
						sa.getErrors().add(formattedMessage);
					}
				}
			}
		}
	}
	return sa;
  }

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
		// we've got another error
		String[] errParms = new String[]{' ', e.getMessage(), e.getStackTraceString()};
		String formattedMessage = String.format(EXCEPTION_ERROR_MESSAGE, errParms);
		String[] messages = new String[]{formattedMessage};
		messages = formatandLogErrors(messages, 'RMS_mobileAppRequestHelper.customerSearch', null, inputJSON);
		System.debug(LoggingLevel.ERROR, 'RMS_mobileAppRequestHelper.customerSearch:' + formattedMessage);
		container.error = messages[0];
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
		  String whereClause = 'where Id in :opportunityIds';
		  String query = OPP_QUERY + ' ' + whereClause;
		  Map<Id, Opportunity> selectedOpportunityMap = new Map<Id, Opportunity>((List<Opportunity>)Database.query(query));
		  myAppts.salesAppts = this.populateSalesAppointments(salesEvents, selectedOpportunityMap);
      }

      myAppts.getApptsCompletedTimeStamp = Datetime.now();
      return JSON.serialize(myAppts);
    } catch (Exception e) {
      System.debug(LoggingLevel.ERROR, e);
      return JSON.serialize(e.getMessage() + ' : ' + e.getStackTraceString());
    }
  }

  
  /* @method: saveTechMeasure(String inputJSON)
   * @param: String inputJSON
   * @return: String
   */
  public String saveTechMeasure(String inputJSON){
	TechMeasureAppointment tmAppt = (TechMeasureAppointment)JSON.deserialize(inputJSON,TechMeasureAppointment.class);
	System.SavePoint sp = Database.setSavePoint();
    try{
		List<OrderItemContainer> oiContainersToUpsert = new List<OrderItemContainer>();
		List<OrderItem> oiToUpsert = new List<OrderItem>();
		List<TM_Offset__c> TMOffsetToUpsert = new List<TM_Offset__c>();
		oiContainersToUpsert = tmAppt.opptyContainer.anOrderContainer.oiContainerList; 
		// save the opportunity
		Database.SaveResult opptysr  = Database.update(tmAppt.opptyContainer.oppty, false);
		if (!opptysr.isSuccess()) {            
			String[] errParms = null;
			for(Database.Error err : opptysr.getErrors()) {
				String fields = '';
				for (String field : err.getFields()) {
					fields = fields + field + ', ';
				}
				errParms = new String[]{'Opportunity',fields, err.getStatusCode().name(), err.getMessage()};
				String formattedMessage = String.format(RECORD_ERROR_MESSAGE, errParms);
				tmAppt.getErrors().add(formattedMessage);
			}
		}
		// save the work order
		if (tmAppt.workOrder != null) {
			Database.SaveResult wosr = Database.update(tmAppt.workOrder, false);
	        if (!wosr.isSuccess()) {            
				String[] errParms = null;
				for(Database.Error err : wosr.getErrors()) {
					String fields = '';
					for (String field : err.getFields()) {
						fields = fields + field + ', ';
					}
					errParms = new String[]{'Work Order',fields, err.getStatusCode().name(), err.getMessage()};
					String formattedMessage = String.format(RECORD_ERROR_MESSAGE, errParms);
					tmAppt.getErrors().add(formattedMessage);
				}
	        }
		}
		// save the order items
		for(OrderItemContainer oiCon: oiContainersToUpsert){
			// link the orderItem to the order for new line items
			if(oiCon.oi != null && oiCon.oi.Id == null && oiCon.oi.OrderId == null) {
				oiCon.oi.OrderId = tmAppt.opptyContainer.anOrderContainer.anOrder.Id;
			}
			oiToUpsert.add(oiCon.oi);
		}
		Database.UpsertResult[] oilur = Database.upsert(oiToUpsert, false);
		for(Database.UpsertResult ur : oilur){
			if (!ur.isSuccess()) {        
				String[] errParms = null;
				for(Database.Error err : ur.getErrors()) {
					String fields = '';
					for (String field : err.getFields()) {
						fields = fields + field + ', ';
					}
					errParms = new String[]{'Order Item',fields, err.getStatusCode().name(), err.getMessage()};
					String formattedMessage = String.format(RECORD_ERROR_MESSAGE, errParms);
					tmAppt.getErrors().add(formattedMessage);
				}
			}
		}
		// save the tm offsets
		for(OrderItemContainer oiCon: oiContainersToUpsert){
			if (oiCon.tmOffSetList != null) {
				for(TM_Offset__c tmOff: oiCon.tmOffSetList){
					tmOff.Order_Line__c = oiCon.oi.Id;
					TMOffsetToUpsert.add(tmOff);
				}     
			}
		}   

		if (TMOffsetToUpsert.size() > 0) {
			Database.UpsertResult[] tmolur = Database.upsert(TMOffsetToUpsert, false);
			for(Database.UpsertResult ur : tmolur){
				if (!ur.isSuccess()) {            
					String[] errParms = null;
					for(Database.Error err : ur.getErrors()) {
						String fields = '';
						for (String field : err.getFields()) {
							fields = fields + field + ', ';
						}
						errParms = new String[]{'Tech Measure Offset',fields, err.getStatusCode().name(), err.getMessage()};
						String formattedMessage = String.format(RECORD_ERROR_MESSAGE, errParms);
						tmAppt.getErrors().add(formattedMessage);
					}
				}
			}
		}

		//Update Order last, as activated orders do not allow addition of orderitems
		Database.SaveResult ordersr = Database.update(tmAppt.opptyContainer.anOrderContainer.anOrder, false);
		if (!ordersr.isSuccess()) {            
			String[] errParms = null;
			for(Database.Error err : ordersr.getErrors()) {
				String fields = '';
				for (String field : err.getFields()) {
					fields = fields + field + ', ';
				}
				errParms = new String[]{'Order',fields, err.getStatusCode().name(), err.getMessage()};
				String formattedMessage = String.format(RECORD_ERROR_MESSAGE, errParms);
				tmAppt.getErrors().add(formattedMessage);
			}
		}
		// roll back if we have errors
		if (tmAppt.getErrors().size() > 0) {
			Database.rollBack(sp);
			tmAppt.isSaveSuccessful = false;
		}
	} catch(Exception e) {
		Database.rollBack(sp);
		tmAppt.isSaveSuccessful = false;
        // we've got another error
        // put the errors in the appts errors
		String[] errParms = new String[]{' ', e.getMessage(), e.getStackTraceString()};
		String formattedMessage = String.format(EXCEPTION_ERROR_MESSAGE, errParms);
		tmAppt.getErrors().add(formattedMessage);
		System.debug(LoggingLevel.ERROR, 'RMS_mobileAppRequestHelper.saveTechMeasure:' + formattedMessage);
    }
	// write any errors to the support log
	String apptName = null;
	if (tmAppt.opptyContainer != null && tmAppt.opptyContainer.oppty != null) {
		apptName = tmAppt.opptyContainer.oppty.Name;
	}
	tmAppt.errors = formatandLogErrors(tmAppt.getErrors(), 'RMS_mobileAppRequestHelper.saveTechMeasure', apptName, inputJSON);
	// get rid of everything but the opportunity and the status
	tmAppt.tmClear();
	return JSON.serialize(tmAppt);
  }

  /* @method: formatandLogErrors(String[] errorArray, String operation, String apptName, String inputJSON)
   * @param: String inputJSON
   * @return: String[]
   */
	private String[] formatandLogErrors(String[] errorArray, String operation, String apptName, String inputJSON){
		Integer errorListSize = errorArray.size();
		if (errorListSize > 0) {
			String message = '';
			for (String err : errorArray) {
				message = message + err;
			}
			if (errorListSize == 1) {
				message = SINGLE_ERROR_HEADER + message;
			} else {
				message = MULTILE_ERROR_HEADER + message;
			}
			String[] msgParms = null;
			if (apptName != null) {
				msgParms = new String[]{apptName};
			} else {
				msgParms = new String[]{' '};
			}
			message = String.format(message, msgParms);
			Id supportLogId = UtilityMethods.supportLog('RMS', operation, message, inputJSON.left(131072), Userinfo.getUserId());
			msgParms = new String[]{' ',supportLogId};
			message = String.format(message,msgParms);
			errorArray.clear();
			errorArray.add(message);
		}
		return errorArray;
	}

	/* @method: cancelOrder(String inputJSON)
	 * @param: String inputJSON
	 * @return: String
	 */
	public String cancelOrder(String inputJSON){
	    try{
			List<Id> opportunityIds = (List<Id>)JSON.deserialize(inputJSON, List<Id>.class);
			if (opportunityIds.size() != 1) {
				Appointments appts = new Appointments();
				appts.getErrors().add('Only one Opportunity can be submitted for cancellation. This request had ' + opportunityIds.size() + '.');
				return JSON.serialize(appts);
			}
			// get the related orders
			Map<Id, Order> orderMap = queryOrders(opportunityIds);
			// If the order does not exist return an error.
			if (orderMap.size() == 0) {
				String apptsString = getSelectedSearchResults(inputJSON);
				Appointments appts = (Appointments)JSON.deserialize(apptsString, Appointments.class);
				appts.getErrors().add('This Opportunity Id:[' + opportunityIds[0] + '] does not have an order.  There is nothing to cancel.');
				return JSON.serialize(appts);
			}
			// If there is more than one order return an error.
			if (orderMap.size() > 1) {
				String apptsString = getSelectedSearchResults(inputJSON);
				Appointments appts = (Appointments)JSON.deserialize(apptsString, Appointments.class);
				appts.getErrors().add('This Opportunity Id:[' + opportunityIds[0] + '] has multiple Orders and cannot be cancelled.');
				return JSON.serialize(appts);
			}
			// Loop through the orders and check if it is cancellable. If not, throw an error
			for (Order ord : orderMap.values()) {
				if (!ord.Cancel_Eligible__c) {
					String apptsString = getSelectedSearchResults(inputJSON);
					Appointments appts = (Appointments)JSON.deserialize(apptsString, Appointments.class);
					appts.getErrors().add('Order is not cancellable.');
					return JSON.serialize(appts);
				}
				ord.Status = 'Pending Cancellation';
				ord.Apex_Context__c = true;
			}
			// get the opportunities with quotes and orders
			String whereClause = 'where Id in :opportunityIds';
			String query = OPP_QUERY + ' ' + whereClause;
			Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>((List<Opportunity>)Database.query(query));
			Map<Id, OpportunityContainer> relatedOCs = populateOpportunityStructure(oppMap);

			List<Opportunity> oppsToUpdate = new List<Opportunity>();
			List<Quote> quotesToUpdate = new List<Quote>();
			List<QuoteLineItem> quoteLineItemsToUpdate = new List<QuoteLineItem>();
			List<Quote_Discount__c> quoteDiscountsToUpdate = new List<Quote_Discount__c>();
			List<Quote_Financing__c> quoteFinancingToUpdate = new List<Quote_Financing__c>();
			// loop through the opportunity containers and retrieve the opps, quotes,
			// quote line items, quote discounts, and quote financing records
			for (OpportunityContainer oc: relatedOCs.values()) {
				oc.oppty.StageName = 'Quoted';
				oppsToUpdate.add(oc.oppty);
				// process the related quotes
				for(QuoteContainer qc : oc.quoteContainerList) {
					if (qc.aQuote.isSold__c == true && oc.anOrderContainer.anOrder.QuoteId == qc.aQuote.Id) {
						// these are the only quotes that need to be modified
						// change quote settings before cloning
						qc.aQuote.Status = 'Draft';
						qc.aQuote.isSold__c = false;
						qc.aQuote.Cloned_Quote_Id__c = qc.aQuote.Id;
						quotesToUpdate.add(qc.aQuote);
						// capture the related sub items
						for(QuoteLineItem qli : qc.quoteLineItems) {
							quoteLineItemsToUpdate.add(qli);
						}
						for(Quote_Discount__c qd : qc.quoteDiscountList) {
							quoteDiscountsToUpdate.add(qd);
						}	
						for(Quote_Financing__c qf : qc.quoteFinancingList) {
							quoteFinancingToUpdate.add(qf);
						}	
					}
				}
			}
			// next clone the lists
			List<Quote> quotesToInsert = quotesToUpdate.deepClone(false, false, false);
			List<QuoteLineItem> quoteLineItemsToInsert = quoteLineItemsToUpdate.deepClone(false, false, false);
			List<Quote_Discount__c> quoteDiscountsToInsert = quoteDiscountsToUpdate.deepClone(false, false, false);
			List<Quote_Financing__c> quoteFinancingToInsert = quoteFinancingToUpdate.deepClone(false, false, false);

			// change quote settings after cloning
			for (Quote q: quotesToUpdate) {
				q.Status = 'Cancelled';
				q.Cloned_Quote_Id__c = null;
			}
			// modify the cloned quotes
			for (Quote q: quotesToInsert) {
				q.rSuite_Id__c = null;
			}
			// Update the orders Cancelled Status
			update orderMap.values();
			// Update the opps to Quoted
			update oppsToUpdate;
			// Update the quotes to Cancelled
			update quotesToUpdate;
			// Insert the new cloned quotes, line items, discounts, and financing
			insert quotesToInsert;
			// Need to map the quote items, discounts, and financing to the new quote, so 
			// create a map from the old quote to the new quote ids.
			Map<Id,Id> oldQuoteToNewQuoteMap = new Map<Id,Id>();
			for (Quote qti : quotesToInsert) {
				oldQuoteToNewQuoteMap.put(qti.Cloned_Quote_Id__c, qti.Id);
			}
			// Loop through the quote line items to insert and update the quote reference
			// Then insert them
			for (QuoteLineItem qliti : quoteLineItemsToInsert) {
				qliti.QuoteId = oldQuoteToNewQuoteMap.get(qliti.QuoteId);
				qliti.rSuite_Id__c = null;
			}
			insert quoteLineItemsToInsert;
			// Loop through the quote discounts to insert and update the quote reference
			// Then insert them
			for (Quote_Discount__c qdti : quoteDiscountsToInsert) {
				qdti.Quote__c = oldQuoteToNewQuoteMap.get(qdti.Quote__c);
				qdti.rSuite_Id__c = null;
			}
			insert quoteDiscountsToInsert;
			// Loop through the quote discounts to insert and update the quote reference
			// Then insert them
			for (Quote_Financing__c qfti : quoteFinancingToInsert) {
				qfti.Related_Quote__c = oldQuoteToNewQuoteMap.get(qfti.Related_Quote__c);
				qfti.rSuite_Id__c = null;
			}
			insert quoteFinancingToInsert;
			// call the getselectedsearchresults 
			return getSelectedSearchResults(inputJSON);
      
		} catch (Exception e) {
			String[] errParms = new String[]{' ', e.getMessage(), e.getStackTraceString()};
			String formattedMessage = String.format(EXCEPTION_ERROR_MESSAGE, errParms);
			System.debug(LoggingLevel.ERROR, 'RMS_mobileAppRequestHelper.cancelOrder:' + formattedMessage);
			Appointments appts = new Appointments();
			appts.getErrors().add(formattedMessage);
			appts.errors = formatandLogErrors(appts.getErrors(), 'RMS_mobileAppRequestHelper.cancelOrder', null, inputJSON);
			return JSON.serialize(appts);
		}
	}

  
  public class Appointments {
    public List<SalesAppointment> salesAppts;
    public List<TechMeasureAppointment> tmAppts;
    public Datetime getApptsCompletedTimeStamp;
    public String[] errors;
    public String[] getErrors() { 
      if (errors == null) { 
        errors = new String[]{};
      } 
      return errors;
    }
  }

  public abstract class Appointment{
    public Event event {get; set;}
    public OpportunityContainer opptyContainer {get; set;}
    public Account account {get; set;}
    public List<Contact> contactList {get; set;}
    public List<OpportunityContainer> historicOpptyContainerList {get; set;}
    public String[] errors;
	public Boolean isSaveSuccessful = true;
    public String[] getErrors() { 
      if (errors == null) { 
        errors = new String[]{};
      } 
      return errors;
    }
	public void clear() {
		event = null;
		account = null;
		historicOpptyContainerList = null;
		contactList = null;
		if (opptyContainer != null) {
			opptyContainer.anOrderContainer = null;
			opptyContainer.quoteContainerList = null;
		}

	}
  }

  public class SalesAppointment extends Appointment{
    public SalesAppointment() { super(); }
	public void saClear() {
		super.clear();
	}
  }
    
  public class TechMeasureAppointment extends Appointment{
    public RbA_Work_Order__c workOrder {get; set;}
    public TechMeasureAppointment() { super(); }
	public void tmClear() {
		super.clear();
		workOrder = null;
	}
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

  public Class NoQuotesException extends Exception {}

}
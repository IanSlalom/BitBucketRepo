/*
 *@class	RMS_salesOrderManager
 *@brief	class used to create orders from quotes
 *@author  Anthony Strafaccia (Slalom.ADS)
 *@author  Mark Wochnick (Slalom.MAW)
 *@version	2015/12/21  Slalom.MAW
 *@copyright  (c)2015 Slalom.  All Rights Reserved.	Unauthorized use is prohibited.
 */

public with sharing class RMS_salesOrderManager {

	/* @method: createSalesOrderOnOpportunityClosedWon(List<Opportunity> listOld, List<Opportunity> listNew, Map<Id, Opportunity> mapOld, Map<Id, Opportunity> mapNew)
	 * @param: List<Opportunity> listOld
	 * @param: List<Opportunity> listNew
	 * @param: Map<Id, Opportunity> mapOld
	 * @param: Map<Id, Opportunity> mapNew
	 * @return: void
	 */
	 public void createSalesOrderOnOpportunityClosedWon(List<Opportunity> listOld, 
		List<Opportunity> listNew, 
		Map<Id, Opportunity> mapOld, 
		Map<Id, Opportunity> mapNew) {

	 	system.debug('****** Inside RMS_salesOrderManager/createSalesOrderOnOpportunityClosedWon');
	 	
	 	//CREATE AND POPULATE LIST OF ONLY OPPORTUNITIES THAT HAVE BEEN CLOSED/WON AND HAVE A SYNCED QUOTE TO PREFORM LOGIC ON
	 	List<Opportunity> closedWonOpportunities = new List<Opportunity>();
	 	List<Id> closedWonOpportunitiesIds = new List<Id>();

	 	for(Opportunity opp : listNew){
	 		if(	opp.IsWon == true  &&  !mapOld.get(opp.id).IsWon){
		 		closedWonOpportunitiesIds.add(opp.id);
	 		}
	 	}
		// only do the following if we have closed won opportunities
		if (closedWonOpportunitiesIds.size() > 0) {
			// get the quotes, quote line items, quote discounts, quote financing of the sold quote and the primary contact for each close won opportunity
			List<Quote> soldQuoteList = [select Id, OpportunityId, Pricebook2Id, isSold__c, Name,
				Opportunity.AccountId, Opportunity.Store_Location__c, Opportunity.OwnerId, Opportunity.Account.BillingStreet,
				Opportunity.Account.BillingCity, Opportunity.Account.BillingStateCode, Opportunity.Account.BillingPostalCode, 
				Opportunity.Account.BillingCountryCode,	Opportunity.Description, Opportunity.CloseDate, Opportunity.Pricebook2Id
				from Quote where isSold__c = true and OpportunityId in :closedWonOpportunitiesIds];

			List<Quote_Discount__c> qdList = [select Id, Name, Discount_Amount__c, Store_Discount__c, Discount_Description__c, Status__c, Quote__c,
				Quote__r.OpportunityId 
				from Quote_Discount__c where Quote__c in :soldQuoteList];

			// get the quote financing
			List<Quote_Financing__c> qfList = [SELECT Id, Name, Amount_Financed__c, Store_Finance_Program__c, Related_Quote__c,
				Related_Quote__r.OpportunityId
				from Quote_Financing__c where Related_Quote__c in :soldQuoteList];

		 	//Dynamicaly query for all QuoteLineItem fields
	    	SObjectType qliType = Schema.getGlobalDescribe().get('QuoteLineItem');
			Map<String,Schema.SObjectField> qliFieldsMap = qliType.getDescribe().fields.getMap();

			// build the query string		    
			String qliQuery = 'SELECT ';
			// add the qli fields
			for(String qliField : qliFieldsMap.KeySet()){
				qliQuery = qliQuery + qliField + ', ';
			}
			// add other needed fields 
			qliQuery = qliQuery + 'Quote.OpportunityId';
			// add the from and where clause
			qliQuery = qliQuery + ' FROM QuoteLineItem WHERE QuoteId in :soldQuoteList AND isDeleted = false';
			// run the query 
		 	List<QuoteLineItem> qliList= Database.query(qliQuery);

			List<OpportunityContactRole> primaryContacts = [select Id, ContactId, OpportunityId, Contact.FirstName, Contact.LastName, isPrimary
				from OpportunityContactRole where OpportunityId in :closedWonOpportunitiesIds and isPrimary = true];

			//Get the attachments for the closed Opportunities
			List<Attachment> attachments = [Select Id, Name, Body, ParentId,OwnerId, Description, IsPrivate from Attachment Where ParentId in: closedWonOpportunitiesIds];
			// create the orders from the quotes
			List<Order> newOrders = createOrders(soldQuoteList, primaryContacts);
			if (newOrders.size() > 0) {
				insert newOrders;

				// create the order line items from the quote line items
				List<OrderItem> oiList = createOrderItems(qliList, newOrders, qliFieldsMap);
				if (oiList.size() > 0) {
					insert oiList;
				}

				// create the order discounts from the quote discounts
				if (qdList.size() > 0) {
					List<Order_Discount__c> odList = createOrderDiscounts(qdList, newOrders);
					if (odList.size() > 0) {
						insert odList;
					}
				}

				// create the order finanicing from the quote financing
				if (qfList.size() > 0) {
					List<Order_Financing__c> ofList = createOrderFinancing(qfList, newOrders);
					if (ofList.size() > 0) {
						insert ofList;
					}
				}

				//Insert the new attachments to the orders and delete the old attachments
				if(attachments.size() > 0){
					try{
						List<Attachment> attList = reparentAttachments(newOrders,attachments);
						if(attList.size() > 0){
							insert attList;
							delete attachments;
						}
					}catch(Exception e){
						System.debug('Exception occurred reparenting attachments in RMS_salesOrderManager.cls: ' + e.getMessage());
					}
				}
			}
		}
	 }// END OF createSalesOrderOnOpportunityClosedWon METHOD

	/* @method: createOrders(List<Quote> quoteList)
	 * @param: List<Quote> quoteList - list of Quote used as a source for the Orders
	 * @param: List<OpportunityContactRole> primaryContacts - list of Primary Contacts used for populate order fields
	 * @return: List<Order> a list of Order that are ready to be inserted
	 */
	public List<Order> createOrders(List<Quote> quoteList, List<OpportunityContactRole> primaryContacts){
		List<Order> newOrders = new List<Order> ();
		for (Quote qt : quoteList) {
			Order ord = new Order();
			ord.OpportunityId = qt.OpportunityId;
			ord.AccountId = qt.Opportunity.AccountId;
			ord.Store_Location__c = qt.Opportunity.Store_Location__c;
			ord.OwnerId = qt.Opportunity.OwnerId;
			ord.Description = qt.Opportunity.Description;
			ord.QuoteId = qt.Id;
			ord.Pricebook2Id = qt.Pricebook2Id;
			ord.BillingStreet = qt.Opportunity.Account.BillingStreet;
			ord.BillingCity = qt.Opportunity.Account.BillingCity;
			ord.BillingStateCode = qt.Opportunity.Account.BillingStateCode;
			ord.BillingPostalCode = qt.Opportunity.Account.BillingPostalCode;
			ord.BillingCountryCode = qt.Opportunity.Account.BillingCountryCode;
			ord.Status = 'Draft';
			ord.EffectiveDate = qt.Opportunity.CloseDate;
			ord.RecordTypeId = UtilityMethods.RecordTypeFor('Order', 'CORO_Record_Type');
			// spin through the primary contacts and assign the name and primary contact
			for (OpportunityContactRole ocr : primaryContacts) {
				if (ocr.OpportunityId == qt.OpportunityId) {
					// we have a match
					ord.BillToContactId = ocr.ContactId;
					ord.Name = ocr.Contact.LastName + ' - ' + ord.BillingStreet + ' - ' + ord.EffectiveDate.format();
					break;
				}
			}
			// set the name if the primary contact is not found for some reason
			if (ord.Name == null) {
				ord.Name = 'No Primary Contact - ' + ord.BillingStreet + ' - ' + ord.EffectiveDate.format();
			}
			// add the order to the list
			newOrders.add(ord);
		}
		return newOrders;
	}

	/* @method: createOrderItems(List<QuoteLineItem> qliList, List<Order> theOrders)
	 * @param: List<QuoteLineItem> qliList - list of QuoteLineItems used as a source for the OrderItems
	 * @param: List<Order> theOrders - orders to link the Order Discounts to
	 * @param: Map<String,Schema.SObjectField> qliFieldsMapRO
	 * @return: List<OrderItem> a list of OrderItems that are ready to be inserted
	 */
	public List<OrderItem> createOrderItems(List<QuoteLineItem> qliList, List<Order> theOrders, Map<String,Schema.SObjectField> qliFieldsMapRO) {
		// since the field map is read only we need to clone it so we can remove the standard fields that can't be copied by name
		Map<String,Schema.SObjectField> qliFieldsMap = qliFieldsMapRO.clone();
		// remove the standard and custom fields from the qli field mapping that can't be copied
		qliFieldsMap.remove('Id');
		qliFieldsMap.remove('isDeleted');
		qliFieldsMap.remove('ListPrice');
		qliFieldsMap.remove('CreateDate');
		qliFieldsMap.remove('Parent_Quote_Line_Item__c');
		qliFieldsMap.remove('Parent_Unit_rSuite_Id__c');
		qliFieldsMap.remove('rSuite_Id__c');

		// lets get the OrderLineItem fields for dynamic assignment
 		SObjectType oiType = Schema.getGlobalDescribe().get('OrderItem');
		Map<String,Schema.SObjectField> oiFieldsMap = oiType.getDescribe().fields.getMap();

		List<OrderItem> oiList = new List<OrderItem> ();
		// generate the OrderItems from the QuoteLineItems
		for (QuoteLineItem qli : qliList) {
			OrderItem oi = new OrderItem();
			// populate fields not include in dynamic setup
			oi.QuoteLineItemId = qli.Id;
			oi.PricebookEntryId = qli.PricebookEntryId;

			//populate the dyanmic fields
			for(String qliField : qliFieldsMap.keySet()) {
				SObjectField oiField = oiFieldsMap.get(qliField);
				if (oiField != null) {
					// we found the field can we update?
					if (oiField.getDescribe().isUpdateable()) {
						// yes check if the value is null
						if (qli.get(qliField) != null) {
							// its not null set the value
							oi.put(oiField, qli.get(qliField));
						}
					}
				}
			}
			//assign the correct order to the order item
			for (Order ord : theOrders) {
				if (ord.QuoteId == qli.QuoteId) {
					oi.OrderId = ord.Id;
					break;
				}
			}
			// add the new order item to the list to be returned
			oiList.add(oi);		
		}
		return oiList;
	}

	/* @method: createOrderDiscounts(List<Quote_Discount__c> qdList, List<Order> theOrders)
	 * @param: List<Quote_Discount__c> qdList - list of Quote Discounts used as a source for the Order Discounts
	 * @param: List<Order> theOrders - orders to link the Order Discounts to
	 * @return: List<Order_Discount__c> a list of Order Discounts that are ready to be inserted
	 */
	public List<Order_Discount__c> createOrderDiscounts(List<Quote_Discount__c> qdList, List<Order> theOrders) {
		List<Order_Discount__c> odList = new List<Order_Discount__c> ();
		for (Quote_Discount__c qd : qdList) {
			Order_Discount__c od = new Order_Discount__c();
			od.Store_Discount__c = qd.Store_Discount__c;
			od.Discount_Amount__c = qd.Discount_Amount__c;
			od.Per_Unit_Discount__c = qd.Per_Unit_Discount__c;
			od.Status__c = qd.Status__c;
			//assign the correct order to the order discount
			for (Order ord : theOrders) {
				if (ord.QuoteId == qd.Quote__c) {
					od.Order__c = ord.Id;
					break;
				}
			}
			// add the new order discount to the list to be returned
			odList.add(od);		
		}
		return odList;
	}

	/* @method: createOrderDiscounts(List<Quote_Financing__c> qfList, List<Order> theOrders)
	 * @param: List<Quote_Financing__c> qdList - list of Quote Financing used as a source for the Order Financing
	 * @param: List<Order> theOrders - orders to link the Order Financing to
	 * @return: List<Order_Financing__c> a list of Order Financing that are ready to be inserted
	 */
	public List<Order_Financing__c> createOrderFinancing(List<Quote_Financing__c> qfList, List<Order> theOrders) {
		List<Order_Financing__c> ofList = new List<Order_Financing__c> ();
		for (Quote_Financing__c qf : qfList) {
			Order_Financing__c ordf = new Order_Financing__c();
			ordf.Amount_Financed__c = qf.Amount_Financed__c;
			ordf.Store_Finance_Program__c = qf.Store_Finance_Program__c;
			ordf.Authorization_Code__c = qf.Authorization_Code__c;
			ordf.Expiration_Date__c = qf.Expiration_Date__c;
			ordf.Program_Rate__c = qf.Program_Rate__c;
			ordf.Program_Fee__c = qf.Program_Fee__c;

			//assign the correct order to the order discount
			for (Order ord : theOrders) {
				if (ord.QuoteId == qf.Related_Quote__c) {
					ordf.Related_Order__c = ord.Id;
					break;
				}
			}
			// add the new order financing to the list to be returned
			ofList.add(ordf);		
		}
		return ofList;
	}	 

	/* @method: reparentAttachments(List<Order> orderList, List<Attachment> attachmentList)
	 * @param: List<Order> orderList - list of Orders for attachments to reparent to
	 * @param: List<Attachment> attachmentList - list of Attachments for the closed Opportunities
	 * @return: List<Attachment> a list of Attachments to insert
	 */
	public List<Attachment> reparentAttachments(List<Order> orderList, List<Attachment> attachmentList){

		List<Attachment> attachmentsToInsert = new List<Attachment>();
		Map<Id,Order> mapOpportunityIdToOrder = new Map<Id,Order>();
		for(Order o: orderList){
			mapOpportunityIdToOrder.put(o.OpportunityId,o);
		}
		for(Attachment a: attachmentList){
			if(mapOpportunityIdToOrder.containsKey(a.ParentId)){
				attachmentsToInsert.add(new Attachment(Name = a.Name, 
														Body = a.Body, 
														OwnerId = a.OwnerId, 
														ParentId = mapOpportunityIdToOrder.get(a.ParentId).Id, 
														IsPrivate = a.IsPrivate,
														Description = a.Description ));
			}
		}
		
		return attachmentsToInsert;

	}
}
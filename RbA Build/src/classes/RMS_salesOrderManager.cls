public with sharing class RMS_salesOrderManager {

	 public void createSalesOrderOnOpportunityClosedWon(List<Opportunity> listOld, List<Opportunity> listNew, Map<Id, Opportunity> mapOld, Map<Id, Opportunity> mapNew){
	 	system.debug('****** Inside RMS_salesOrderManager/createSalesOrderOnOpportunityClosedWon');
	 	
	 	
	 	//CREATE AND POPULATE LIST OF ONLY OPPORTUNITIES THAT HAVE BEEN CLOSED/WON AND HAVE A SYNCED QUOTE TO PREFORM LOGIC ON
	 	list<Opportunity> closedWonOpportunities = new list<Opportunity>();
	 	list<Id> closedWonOpportunitiesIds = new list<Id>();

	 	
	 	for(Opportunity opp : listNew){
	 		if(	opp.IsWon == true  &&  mapOld.get(opp.id).IsWon != true  &&  opp.SyncedQuoteId != null ){
		 		closedWonOpportunitiesIds.add(opp.id);
	 		}
	 	}
		//QUERY FOR ADDITIONAL FIELDS NOT PASSED BY TRIGGER
		closedWonOpportunities = [SELECT 	id,
											AccountId,
											Store_Location__r.id,
											OwnerId,
											Description,
											SyncedQuoteId,
											Pricebook2Id,
											Account.BillingStreet,
											Account.BillingCity,
											Account.BillingStateCode,
											Account.BillingPostalCode, 
											Account.BillingCountryCode,
											CloseDate
											
								FROM Opportunity WHERE Id IN :closedWonOpportunitiesIds];	
		
		//CREATE MAP OF OPPORTUNITYID TO OPPORTUNITYCONTACTROLE LIST TO BE USED TO ASSIGN ORDER BILL TO CONTACT
		list<OpportunityContactRole> relatedOpportunityContactRole = [SELECT Id, IsPrimary, OpportunityId, ContactId, Contact.LastName FROM OpportunityContactRole WHERE OpportunityId IN :closedWonOpportunitiesIds];
		map<id, list<OpportunityContactRole>> oppIdToListofOpportunityContactRoleMap = new map<id, list<OpportunityContactRole>>();
		for(OpportunityContactRole ocr : relatedOpportunityContactRole){
	 		if(oppIdToListofOpportunityContactRoleMap.containsKey(ocr.OpportunityId)){
				oppIdToListofOpportunityContactRoleMap.get(ocr.OpportunityId).add(ocr);
			}else{
				oppIdToListofOpportunityContactRoleMap.put(ocr.OpportunityId, new list<OpportunityContactRole>{ocr});
			}	
	 	}
	 	
	 	//CREATE MAP OF OPPORTUNITYID TO Opportunity_Discount__c LIST TO BE USED TO BUILD OrderDiscountS
		list<Opportunity_Discount__c > relatedOpportunityDiscount = [SELECT Status__c, Discount__c, Discount_Amount__c, Opportunity__c  FROM Opportunity_Discount__c WHERE Opportunity__c IN :closedWonOpportunitiesIds];
		map<id, list<Opportunity_Discount__c>> oppIdToListofOpportunityDiscountMap = new map<id, list<Opportunity_Discount__c>>();
		
		for(Opportunity_Discount__c oppD : relatedOpportunityDiscount){
	 		if(oppIdToListofOpportunityDiscountMap.containsKey(oppD.Opportunity__c)){
				oppIdToListofOpportunityDiscountMap.get(oppD.Opportunity__c).add(oppD);
			}else{
				oppIdToListofOpportunityDiscountMap.put(oppD.Opportunity__c, new list<Opportunity_Discount__c>{oppD});
			}	
	 	}
		 
		
	 	system.debug('****** closedWonOpportunities.size(): '+closedWonOpportunities.size());
	 	if(closedWonOpportunities.size() > 0){
		 	//DYNAMICLY QUERY FOR ALL OPPORTUNITYLINEITEM FIELDS
	    	SObjectType OLIx = Schema.getGlobalDescribe().get('OpportunityLineItem');
			map<String,Schema.SObjectField> OLIFieldsMap = OLIx.getDescribe().fields.getMap();
		    
		    String oliQuery = 'SELECT ';
		    
			for(String oliField : OLIFieldsMap.KeySet()){
				oliQuery = oliQuery + oliField + ', ';
		    }
		     
		    oliQuery = oliQuery.substring(0,oliQuery.length()-2);
		    oliQuery = oliQuery + ' FROM OpportunityLineItem WHERE OpportunityId IN :closedWonOpportunities';
		 	list<OpportunityLineItem> relatedOLI= Database.query(oliQuery);
		 	
		 	
		 	//CREATE A MAP OF OPPORTUNITY ID TO LIST OF OPPORTUNITYLINEITEMS
		 	map<Id, list<OpportunityLineItem>> opportunityIdToOLIListMap = new map<Id, list<OpportunityLineItem>>();
		 	for(OpportunityLineItem oli : relatedOLI){
		 		if(opportunityIdToOLIListMap.containsKey(oli.OpportunityId)){
					opportunityIdToOLIListMap.get(oli.OpportunityId).add(oli);
				}else{
					opportunityIdToOLIListMap.put(oli.OpportunityId, new list<OpportunityLineItem>{oli});
				}	
		 		
		 	}
		 	
		 	//CREATE A MAP OF ORDER ITEM FIELD NAMES
		 	SObjectType OrderItemx = Schema.getGlobalDescribe().get('OrderItem');
			map<String,Schema.SObjectField> OrderItemFieldsMapReadOnly = OrderItemx.getDescribe().fields.getMap();
			map<String,Schema.SObjectField> OrderItemFieldsMap = OrderItemFieldsMapReadOnly.Clone();
			
		 	//LOOP THROUGH ALL ORDERITEM FIELDS AND CHECK IF THERE IS A FIELD WITH SAME NAME
		 	for(String OrderItemField : OrderItemFieldsMap.KeySet()){
		 		Boolean matchMade = false;
		 		for(String oliField : OLIFieldsMap.KeySet()){
		 			//IF FIELD MATCHES IN NAME THEN SET MATCH MADE TO TRUE AND BREAK
		 			if(oliField == OrderItemField){
		 				matchMade = true;
		 				break;
		 			}
		 		}
		 		//AFTER LOOP IF NO MATCHES FOUND THEN REMOVE ORDERITEMFIELD
		 		if(matchMade == false){
		 			OrderItemFieldsMap.remove(OrderItemField);
		 		}
		 		
		 			OrderItemFieldsMap.remove('isdeleted');
		 			OrderItemFieldsMap.remove('listprice');
		 			OrderItemFieldsMap.remove('id');
		 			OrderItemFieldsMap.remove('createdate');
		 	}
		 	
		 	
		 	
		 	
		 	list<Order> ordersToAdd = new list<Order>();
			list<sObject> orderItemsToAdd = new list<sObject>();
		 	list<Order_Discount__c> orderDiscountsToAdd = new list<Order_Discount__c>();
		 	
		 	map<id, Order> opportunityIdToOrderMap = new map<id, Order>();
		 	
		 	for(Opportunity opp : closedWonOpportunities){
				
				//DECIDE WHO IS PRIMARY CONTACT
				OpportunityContactRole primaryContactRole;
				Boolean foundPrimary = false;
				if(oppIdToListofOpportunityContactRoleMap.get(opp.id) != null){
					for(OpportunityContactRole contactRole : oppIdToListofOpportunityContactRoleMap.get(opp.id)){
						if(contactRole.IsPrimary == true){
							primaryContactRole = contactRole;
							foundPrimary = true;
							break;
						}
					}
					if(foundPrimary == false){
						primaryContactRole = oppIdToListofOpportunityContactRoleMap.get(opp.id)[0];
					}
				}
				
				
				Id primaryContactId;
				String orderName;
				if(primaryContactRole != null){
					primaryContactId = primaryContactRole.ContactId;
					orderName = primaryContactRole.Contact.LastName + ' - ';
				}
				orderName = orderName + opp.Account.BillingStreet + ' - ' + opp.CloseDate;
				
				
				//CREATE ORDER
				Order ord = new Order(	
										Name = orderName,
										OpportunityId = opp.id, 
										AccountId = opp.AccountId, 
										Store_Location2__c = opp.Store_Location__r.id,
										OwnerId = opp.OwnerId,
										Description = opp.Description,
										QuoteId = opp.SyncedQuoteId,
										Pricebook2Id = opp.Pricebook2Id,
										BillingStreet = opp.Account.BillingStreet,
										BillingCity = opp.Account.BillingCity,
										BillingStateCode = opp.Account.BillingStateCode,
										BillingPostalCode = opp.Account.BillingPostalCode, 
										BillingCountryCode = opp.Account.BillingCountryCode,
										Status = 'Draft',
										EffectiveDate = opp.CloseDate,
										BillToContactId = primaryContactId
										);
				ordersToAdd.add(ord);
				opportunityIdToOrderMap.put(opp.id, ord);
		 	}
		 	
		 	insert ordersToAdd;
		
			
		 	for(Opportunity opp : closedWonOpportunities){
				//FOR EACH OPPORTUNITYLINEITEM CREATE A ORDERLINE ITEM
				for(OpportunityLineItem oli : opportunityIdToOLIListMap.get(opp.id)){
					
					//CREATE NEW SOBJECT ORDER
					sObject orderItem = Schema.getGlobalDescribe().get('OrderItem').newSObject();
					
					orderItem.put('OrderId', opportunityIdToOrderMap.get(opp.id).id );
					orderItem.put('PricebookEntryId', oli.get('PricebookEntryId') );
					
					for(String orderItemField : OrderItemFieldsMap.keySet()){
						if(OrderItemFieldsMap.get(orderItemField).getDescribe().isUpdateable()){
							orderItem.put(orderItemField , oli.get(orderItemField) );
						}
					}
					
					orderItemsToAdd.add(orderItem);
				}
				
				//FOR EACH OPPORTUNITY DISCOUNT CREATE AN ORDER DISCOUNT
				if(oppIdToListofOpportunityDiscountMap.get(opp.id) != null){
			 		for(Opportunity_Discount__c oppDiscount : oppIdToListofOpportunityDiscountMap.get(opp.id)){
			 			Order_Discount__c orderDiscount = new Order_Discount__c(
	 																			Discount__c = oppDiscount.Discount__c,
	 																			Discount_Amount__c = oppDiscount.Discount_Amount__c,
	 																			Status__c = oppDiscount.Status__c,
	 																			Order__c = opportunityIdToOrderMap.get(opp.id).id
	 																			);
	 					orderDiscountsToAdd.add(orderDiscount);													
			 		}
				}
		 	}//END OF closedWonOpportunities LOOP
			
			//CAST SOBJECT LIST TO ORDERITEM LIST FOR INSERT
			list<OrderItem> orderItemsToAdd2 = orderItemsToAdd;
			insert orderItemsToAdd2;
			insert orderDiscountsToAdd;
			
			
	 	}//END OF closedWonOpportunities.size() > 0 IF
	 }// END OF createSalesOrderOnOpportunityClosedWon METHOD
	  
	 
}//EOF
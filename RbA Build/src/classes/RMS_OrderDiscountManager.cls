/*******************************************************//**

@trigger OrderDiscountManager

@brief	manager to handle logic for Order_Discount__c trigger

@author  Anthony Strafaccia (Slalom.ADS)

@version	2016-5/09  Slalom.ADS Created.
 
@see		OrderDiscountManagerTest

@copyright  (c)2016 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/



public with sharing class RMS_OrderDiscountManager {
	public void setUpChangeHistoryOnCreate(list<Order_Discount__c> newList, map<id,Order_Discount__c> newMap){
		
		system.debug('ads creating new change history: '+ newList);
		list<Change_History__c> changeHistoryToInsert = new list<Change_History__c>();
		for(Order_Discount__c od : newlist){
			if(od.Status__c == 'Applied' ){
				Change_History__c ch = new Change_History__c();
				ch.Order_Discount__c = od.Id; 
				ch.Retail_Price__c = od.Discount_Amount__c * -1;
				ch.Retail_Price_Change__c =  od.Discount_Amount__c * -1;
				ch.RecordtypeId = UtilityMethods.RecordTypeFor('Change_History__c', 'Order_Discount');
				ch.Subtype__c = 'Initial';
				ch.Line_Processed_Date__c = System.today();
				ch.Order_Booking_Date__c = od.Order_Booking_Date__c;
				ch.Order_Revenue_Recognition_Date__c = od.Order_Revenue_Recognition_Date__c;
				changeHistoryToInsert.add(ch);
			}
		}
		
		if(changeHistoryToInsert.size() > 0){
			insert changeHistoryToInsert;
		}
	}
	
	public void updateChangeHistoryOnUpdate(list<Order_Discount__c> newList, list<Order_Discount__c> oldList, map<id,Order_Discount__c> newMap, map<id,Order_Discount__c> oldMap){
		
		set<id> newListIds = newMap.keyset(); 
		list<Change_History__c> changeHistoryToUpsert = new list<Change_History__c>();
		
		list<Change_History__c> relatedChangeHistories = [SELECT 	id, 
																	Changes__c, 
																	Order_Product__c, 
																	Retail_Price__c, 
																	Retail_Price_Change__c,
																	Order_Discount__c
																	FROM Change_History__c 
																	WHERE Order_Discount__c 
																	IN :newListIds
																	AND CreatedById = :UserInfo.getUserId() 
																	AND CreatedDate = TODAY
																	order by CreatedDate desc];
																	
		map<id, list<Change_History__c>> orderDiscountIdToListChangeHistory = new map<id, list<Change_History__c>>();

		for(Change_History__c ch : relatedChangeHistories){
			if(orderDiscountIdToListChangeHistory.containsKey(ch.Order_Discount__c)){
				orderDiscountIdToListChangeHistory.get(ch.Order_Discount__c).add(ch);
			}else{
				orderDiscountIdToListChangeHistory.put(ch.Order_Discount__c, new list<Change_History__c>{ch});
			}
		}
		
		//DYNAMICLY QUERY ALL FIELDS ON ORDER DISCOUNT
		SObjectType xOD = Schema.getGlobalDescribe().get('Order_Discount__c');
		map<String,Schema.SObjectField> odFieldsMap = xOD.getDescribe().fields.getMap();
		String odQuery = 'SELECT ';
		for(String odField : odFieldsMap.KeySet()){
			odQuery = odQuery + odField + ', ';
	    }
	    odQuery = odQuery.substring(0,odQuery.length()-2);
	    odQuery = odQuery + ' FROM Order_Discount__c WHERE Id IN :newListIds';
	    list<Order_Discount__c> extraFieldsList = Database.query(odQuery); 
                                                     
		
		for(Order_Discount__c od : extraFieldsList){
			
			
			//IF NO CHANGE HISTORY CREATED BY CURRENT USER TODAY	 		
			Change_History__c rCH = new Change_History__c();
			
			String typeOfChange;
			
			
			system.debug('ads oldmap.get(od.id).Status__c:'+oldmap.get(od.id).Status__c);
			system.debug('ads newmap.get(od.id).Status__c:'+newmap.get(od.id).Status__c);
			//NO STATUS CHANGE DISCOUNT CHANGE
			if(oldmap.get(od.id).Status__c == newmap.get(od.id).Status__c && oldmap.get(od.id).Discount_Amount__c != newmap.get(od.id).Discount_Amount__c){
				typeOfChange = 'justDiscount';
			}
			//STATUS CHANGE FROM APPLIED TO CANCELLED(TREAT NEW DISCOUNT AMOUNT AS ZERO)
			else if(oldmap.get(od.id).Status__c == 'Applied' && newmap.get(od.id).Status__c == 'Cancelled'){
				typeOfChange = 'statusAppliedToCancelled';
			}
			//STATUS CHANGE FROM CANCELLED TO APPLIED(TREAT OLD DISCOUNT AMOUNT AS ZERO)
			else if(oldmap.get(od.id).Status__c == 'Cancelled' && newmap.get(od.id).Status__c == 'Applied'){
				typeOfChange = 'statusCancelledToApplied';
			}	
			
			system.debug('ads typeOfChange: '+typeOfChange);
			system.debug('ads orderDiscountIdToListChangeHistory.get(od.id): '+orderDiscountIdToListChangeHistory.get(od.id));
			system.debug('ads newMap.get(od.id).Discount_Amount__c: '+newMap.get(od.id).Discount_Amount__c);
			system.debug('ads oldMap.get(od.id).Discount_Amount__c: '+oldMap.get(od.id).Discount_Amount__c);

			rCH.RecordtypeId = UtilityMethods.RecordTypeFor('Change_History', 'Order_Discount');
			rCH.Line_Processed_Date__c = System.today();
			rCH.Order_Booking_Date__c = od.Order_Booking_Date__c;
			rCH.Order_Revenue_Recognition_Date__c = od.Order_Revenue_Recognition_Date__c;
			rCH.Subtype__c = 'Change';

			
			if(	orderDiscountIdToListChangeHistory.get(od.id) == null || 
				orderDiscountIdToListChangeHistory.get(od.id).size() == 0){
				rCH.Order_Discount__c = od.Id;
				if(typeOfChange == 'justDiscount'){
					rCh.Retail_Price__c = newMap.get(od.id).Discount_Amount__c * -1;
					rCH.Retail_Price_Change__c =  (oldMap.get(od.id).Discount_Amount__c - newMap.get(od.id).Discount_Amount__c); 
				}else if(typeOfChange == 'statusAppliedToCancelled'){
					rCh.Retail_Price__c = 0;
					rCH.Retail_Price_Change__c =  (oldMap.get(od.id).Discount_Amount__c - 0);
				}else if(typeOfChange == 'statusCancelledToApplied'){
					rCh.Retail_Price__c = newMap.get(od.id).Discount_Amount__c * -1;
					rCH.Retail_Price_Change__c =  (0 - newMap.get(od.id).Discount_Amount__c);
				}
			}

			//GET MOST RECENTLY CREATED CHANGE HISTORY			
			else {
				rCH = OrderDiscountIdToListChangeHistory.get(od.id)[0];
				
				if(typeOfChange == 'justDiscount'){
					rCh.Retail_Price__c = newMap.get(od.id).Discount_Amount__c * -1;
					rCH.Retail_Price_Change__c =  ((oldMap.get(od.id).Discount_Amount__c - newMap.get(od.id).Discount_Amount__c)+rCH.Retail_Price_Change__c);
				}else if(typeOfChange == 'statusAppliedToCancelled'){
					rCh.Retail_Price__c = 0;
					rCH.Retail_Price_Change__c =  ((oldMap.get(od.id).Discount_Amount__c - 0)+rCH.Retail_Price_Change__c);
				}else if(typeOfChange == 'statusCancelledToApplied'){ 
					rCh.Retail_Price__c = newMap.get(od.id).Discount_Amount__c * -1;
					rCH.Retail_Price_Change__c =  ((0 - newMap.get(od.id).Discount_Amount__c)+rCH.Retail_Price_Change__c);
				}
			}
			changeHistoryToUpsert.add(rCH);	
		}
		system.debug('ads changeHistoryToUpsert: '+changeHistoryToUpsert);
		upsert changeHistoryToUpsert;
	}
}
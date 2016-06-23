public with sharing class RMS_OrderItemManager {
	
	public void setUpChangeHistoryOnCreate(list<OrderItem> newList, map<id,OrderItem> newMap){
		system.debug('ads creating new change history: '+ newList);
		list<Change_History__c> changeHistoryToInsert = new list<Change_History__c>();
		for(OrderItem oi : newlist){
			Change_History__c ch = new Change_History__c();
			ch.Order_Product__c = oi.Id;
			ch.Retail_Price__c = oi.Total_Retail_Price__c;
			ch.Retail_Price_Change__c =  oi.Total_Retail_Price__c;
			ch.Responsible_Party__c = oi.Responsible_Party__c;
			changeHistoryToInsert.add(ch);
		}
		insert changeHistoryToInsert;
	}
	
	public void updateChangeHistoryOnUpdate(list<OrderItem> newList, list<OrderItem> oldList, map<id,OrderItem> newMap, map<id,OrderItem> oldMap){
		list<Change_History__c> changeHistoryToUpsert = new list<Change_History__c>();
		
		list<Change_History__c> relatedChangeHistories = [SELECT 	id, 
																	Changes__c, 
																	Order_Product__c, 
																	Retail_Price__c, 
																	Retail_Price_Change__c 
																	FROM Change_History__c 
																	WHERE Order_Product__c 
																	IN :oldMap.Keyset()
																	AND CreatedById = :UserInfo.getUserId() 
																	AND CreatedDate = TODAY
																	order by CreatedDate desc];
																	
		map<id, list<Change_History__c>> orderItemIdToListChangeHistory = new map<id, list<Change_History__c>>();

		for(Change_History__c ch : relatedChangeHistories){
			if(orderItemIdToListChangeHistory.containsKey(ch.Order_Product__c)){
				orderItemIdToListChangeHistory.get(ch.Order_Product__c).add(ch);
			}else{
				orderItemIdToListChangeHistory.put(ch.Order_Product__c, new list<Change_History__c>{ch});
			}
		}
		
		//DYNAMICLY QUERY ALL FIELDS ON ORDER ITEM
		SObjectType xOI = Schema.getGlobalDescribe().get('OrderItem');
		map<String,Schema.SObjectField> oiFieldsMap = xOI.getDescribe().fields.getMap();
	    set<id> newListIds = newMap.keyset(); 
		String oiQuery = 'SELECT ';
		for(String oiField : oiFieldsMap.KeySet()){
			oiQuery = oiQuery + oiField + ', ';
	    }
	    oiQuery = oiQuery.substring(0,oiQuery.length()-2);
	    oiQuery = oiQuery + ' FROM OrderItem WHERE Id IN :newListIds';
	    list<OrderItem> extraFieldsList = Database.query(oiQuery);
                                                     
		
		for(OrderItem oi : extraFieldsList){
			//IF NO CHANGE HISTORY CREATED BY CURRENT USER TODAY	 		
				
			Change_History__c rCH = new Change_History__c();
			if(	orderItemIdToListChangeHistory.get(oi.id) == null || 
				orderItemIdToListChangeHistory.get(oi.id).size() == 0 || 
				oldMap.get(oi.id).Total_Retail_Price__c != newMap.get(oi.id).Total_Retail_Price__c ||
				oldMap.get(oi.id).UnitPrice != newMap.get(oi.id).UnitPrice){
					
				rCH.Order_Product__c = oi.Id;
				rCH.Retail_Price__c = oi.Total_Retail_Price__c;
				rCH.Retail_Price_Change__c =  oi.Total_Retail_Price__c - oldMap.get(oi.id).Total_Retail_Price__c;
			}
			//GET MOST RECENTLY CREATED CHANGE HISTORY			
			else {
				rCH = orderItemIdToListChangeHistory.get(oi.id)[0];
			}
			Boolean somethingChanged = false;
			//LOOP THROUGH ALL FIELDS AND DETERMINES IF THE OLD VALUE DIFFERENT THAN THE NEW VALUE
			for(String oiField : oiFieldsMap.KeySet()){ 
				string oldValue = string.valueOf(oldMap.get(oi.id).get(oiField));
				string newValue = string.valueOf(newMap.get(oi.id).get(oiField));
				string oiLabel = oiFieldsMap.get(oiField).getDescribe().getLabel();
				
				if(oldValue != newValue && !oiField.equalsIgnoreCase('Responsible_Party__c')){
					somethingChanged = true;
					if(oldValue == null){
						oldValue = 'none'; 
					}
					if(newValue == null){
						newValue = 'none';
					}
					system.debug('ads oi: '+oi);
					system.debug('ads rCH: '+rCH);
					system.debug('ads oiField: '+oiField); 
					system.debug('ads oiLabel: '+oiLabel);
					system.debug('ads oldValue: '+oldValue);
					system.debug('ads newValue: '+newValue);
					
					//IF THAT FIELD HAS NOT BEEN CHANGED ALREADY
					if(rCH.Changes__c == null){
						rCH.Changes__c = '*'+oiLabel+'* : '+oldValue+' -> '+newValue+',';
					}else if(rCH.Changes__c.contains('*'+oiLabel+'*') == false){
						rCH.Changes__c = rCH.Changes__c+' *'+oiLabel+'* : '+oldValue+' -> '+newValue+',';
					}
					//IF THAT FIELD HAS BEEN CHANGED
					else if(rCH.Changes__c != null || rCH.Changes__c.contains('*'+oiLabel+'*') == true){
						
						
						string regex = '\\*'+oiLabel+'\\* :([\\s\\S]*?),';
						Matcher match = Pattern.compile(regex).matcher(rCH.Changes__c);
						system.debug('ads regex: '+regex);
						system.debug('ads rCH.Changes__c: '+rCH.Changes__c);
						match.find();
						string fieldsChangeHistory = match.group(0);
				
						system.debug('ads fieldsChangeHistory: ' + fieldsChangeHistory);
						String newFieldChangeHistory = fieldsChangeHistory.removeEnd(',') + ' -> '+newValue+',';
						rCH.Changes__c = rCH.Changes__c.replace(fieldsChangeHistory, newFieldChangeHistory);
					}
				}
			}
			if(somethingChanged == true && orderItemIdToListChangeHistory.get(oi.id) != null && orderItemIdToListChangeHistory.get(oi.id).size() != 0){
				rCH.Retail_Price__c = newMap.get(oi.id).Total_Retail_Price__c;
				
				Decimal newPrice = newMap.get(oi.id).Total_Retail_Price__c;
				Decimal oldPrice = oldMap.get(oi.id).Total_Retail_Price__c;
				if (newPrice == null) newPrice = 0;
				if (oldPrice == null) oldPrice = 0;
				if (rCH.Retail_Price_Change__c == null) rCH.Retail_Price_Change__c = 0;
				rCH.Retail_Price_Change__c = (newPrice - oldPrice) + rCH.Retail_Price_Change__c;
			}  
			changeHistoryToUpsert.add(rCH);	
		
			
	
		}
		upsert changeHistoryToUpsert;
	}
	
	
	
	
	
}
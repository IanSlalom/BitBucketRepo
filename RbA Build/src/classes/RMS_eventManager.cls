public with sharing class RMS_eventManager {
	
	public void createChangeHistoryOnDelete(list<Event> listOld, map<Id, Event> mapOld){
		list<Change_History__c> changeHistroyToInsert = new list<Change_History__c>();
		

		list<Event> extraFieldsEvents = [SELECT Id, 
												StartDateTime, 
												EndDateTime, 
												OwnerId, 
												RecordTypeId, 
												WhatId 
												FROM Event Where Id IN: mapOld.keySet()];
		
		list<id> relatedWhatIds = new list<id>();
		list<id> relatedOwnerIds = new list<id>();
		for(Event e : extraFieldsEvents){
			relatedWhatIds.add(e.WhatId);
			relatedOwnerIds.add(e.OwnerId);
		}
		
		list<RbA_Work_Order__c> relatedWorkOrdersList = [SELECT id, Cancel_Reason__c, Cancel_Date__c FROM RbA_Work_Order__c WHERE id IN:relatedWhatIds AND Cancel_Reason__c != null AND Cancel_Date__c != null];
		set<id> relatedWorkOrderIdSet = new set<id>();
		map<id, RbA_Work_Order__c> idToWorkOrder = new map<id, RbA_Work_Order__c>();
		for(RbA_Work_Order__c wo : relatedWorkOrdersList){
			relatedWorkOrderIdSet.add(wo.id);
			idToWorkOrder.put(wo.id, wo);
		}
		
		list<User> relatedUserList = [SELECT id, FirstName, LastName FROM User WHERE id IN :relatedOwnerIds];
		map<id, String> userIdToNameMap = new map<id, String>();
		for(User u : relatedUserList){
			userIdToNameMap.put(u.id, u.FirstName+' '+u.LastName);
		}

		Id workOrderEventRecordTypeId = UtilityMethods.retrieveRecordTypeId('Work_Order_Event', 'Event');
		for(Event e : extraFieldsEvents){
			if(e.RecordTypeId == workOrderEventRecordTypeId && relatedWorkOrderIdSet.contains(e.WhatId) ){
				RbA_Work_Order__c rWO = idToWorkOrder.get(e.WhatId);
				//String cancelDate = rWO.Cancel_Date__c.substring(0,9);
				Change_History__c ch = new Change_History__c();
				ch.RbA_Work_Order__c = e.WhatId;
				ch.Changes__c = 'Cancel Reason: '+rWO.Cancel_Reason__c+'\r\n'+
								'Cancel Date: '+rWO.Cancel_Date__c.format()+'\r\n'+
								'Start Date Time: '+e.StartDateTime.format()+'\r\n'+ 
								'End Date Time: '+e.EndDateTime.format()+'\r\n'+
				 				'Assigned To: '+userIdToNameMap.get(e.OwnerId)+'\r\n';
 				changeHistroyToInsert.add(ch);
			} 
		}
		insert changeHistroyToInsert;
	} 
	
}
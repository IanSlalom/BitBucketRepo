/*
Trigger framework Anthony Strafaccia 2015

This trigger is a framework for Order object. It is designed to be the only trigger needed for the Order object and allows for the customization of the order of execution.  

All logic should be handled on the OrderTriggerHandler class.
*/

trigger OrderTrigger on Order (before insert, before update, before delete, 
                                            after insert, after undelete, after update, after delete) {

	map<String, RMS_Settings__c> RMS_Settings_map = RMS_Settings__c.getAll(); 
	//map<String, Foundation_States__c> allstates = Foundation_States__c.getAll();
	
	if(RMS_Settings_map.get('Data Loading Profile ID') == null ){
		if(Trigger.isDelete){
			Trigger.old[0].addError(RMS_ErrorMessages.DATA_LOADING_CUSTOM_SETTING_REQUIRED);
		}else{
			Trigger.new[0].addError(RMS_ErrorMessages.DATA_LOADING_CUSTOM_SETTING_REQUIRED);
		}
	}
	else if(!(UserInfo.getProfileId() == RMS_Settings_map.get('Data Loading Profile ID').Value__c ) ){
		OrderTriggerHandler handler = new OrderTriggerHandler();
            
		// Before Insert
		/*
		if(Trigger.isInsert && Trigger.isBefore){
		    handler.OnBeforeInsert(Trigger.new);
		}
		*/
		//  Before Update
		/*
		else if(Trigger.isUpdate && Trigger.isBefore){
		    handler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.newMap, Trigger.oldMap); 
		}
		*/
	
		// Before Delete
		/*
		else if(Trigger.isDelete && Trigger.isBefore){
		    handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
		}
		*/
		
		// After Insert
		
		/*
		else 
		*/ 
		if(Trigger.isInsert && Trigger.isAfter){
			handler.OnAfterInsert(Trigger.new, Trigger.newMap);
		}
		 
		// After Update
		/*
		else if(Trigger.isUpdate && Trigger.isAfter){
		    handler.onAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
		}
		*/
		            
		//After Delete
		/*
		else if(Trigger.isDelete && Trigger.isAfter){
		    handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
		}
		*/
		
		// After Undelete 
		/*
		else if(Trigger.isUnDelete){
		    handler.OnUndelete(Trigger.new);
		}
		*/
	}
}
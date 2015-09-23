/*
Trigger framework Anthony Strafaccia 2015

This trigger is a framework for Opportunity object. It is designed to be the only trigger needed for the Opportunity object and allows for the customization of the order of execution.  

All logic should be handled on the OpportunityTriggerHandler class.
*/

trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, 
                                            after insert, after undelete, after update, after delete) {

	map<String, RMS_Settings__c> RMS_Settings_map = RMS_Settings__c.getAll(); 
	//map<String, Foundation_States__c> allstates = Foundation_States__c.getAll();
	
	

	if(!(UserInfo.getProfileId() == RMS_Settings_map.get('Data Loading Profile ID').Value__c ) ){
		OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
            
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
		else if(Trigger.isInsert && Trigger.isAfter){
		handler.OnAfterInsert(Trigger.new, Trigger.newMap);
		}
		*/
		 
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
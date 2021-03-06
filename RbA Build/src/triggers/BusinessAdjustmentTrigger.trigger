/*******************************************************//**

@trigger BusinessAdjustmentTrigger

@brief	trigger framework to secure order of operation

@author  Anthony Strafaccia (Slalom.ADS)

@version	2016-02/17  Slalom.ADS Created

@see		BusinessAdjustmentTriggerTest 
 
@copyright  (c)2016 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/ 

trigger BusinessAdjustmentTrigger on Business_Adjustment__c (after delete, after insert, after undelete, 
																after update, before delete, before insert, before update) {
//GET ALL RMS SETTINGS CUSTOM SETTINGS
	map<String, RMS_Settings__c> RMS_Settings_map = RMS_Settings__c.getAll(); 

	//CHECK IF DATA LOADING PROFILE
	if(RMS_Settings_map.get('Data Loading Profile ID') == null ){
		if(Trigger.isDelete){
			Trigger.old[0].addError(RMS_ErrorMessages.DATA_LOADING_CUSTOM_SETTING_REQUIRED);
		}else{
			Trigger.new[0].addError(RMS_ErrorMessages.DATA_LOADING_CUSTOM_SETTING_REQUIRED);
		}
	}
	//IF NOT DATA LOADING PROFILE RUN LOGIC
	else if(!(UserInfo.getProfileId() == RMS_Settings_map.get('Data Loading Profile ID').Value__c ) ){
		
		//HANDLERS AND MANAGERS
       	RMS_financialTransactionManager financialTransactionManager = new RMS_financialTransactionManager();
		List<SObject> orders = new List<SObject>();
	     
		
		// Before Insert
		/*
		if(Trigger.isInsert && Trigger.isBefore){
		    handler.OnBeforeInsert(Trigger.New);
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
		else 
		*/
		if(Trigger.isDelete && Trigger.isBefore){
		    financialTransactionManager.onBeforeDeleteOrder(Trigger.old, Trigger.oldMap);
		}
		
		// After Insert
		
		else if(Trigger.isInsert && Trigger.isAfter){
			financialTransactionManager.onAfterInsertAsset(Trigger.new, Trigger.newMap);
			orders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
		}
		
		 
		// After Update
		
		else if(Trigger.isUpdate && Trigger.isAfter){
		    financialTransactionManager.onAfterUpdateOrder(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
			orders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
		}
		
		            
		//After Delete
		else if(Trigger.isDelete && Trigger.isAfter){
			orders = (List<SObject>) dlrs.RollupService.rollup(trigger.old);
		}
		// After Undelete 
		else if(Trigger.isUnDelete){
			orders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
		}

		// Try - Catch to catch any dml errors doing the order rollup and displaying
		// errors on the payment records
		try { update orders;} 
		catch(System.DmlException e) {
			if (Trigger.isDelete) for (sObject obj : trigger.old) { obj.addError(e.getDmlMessage(0)); }
			else for (sObject obj : trigger.new) { obj.addError(e.getDmlMessage(0)); }
		}

	}
}
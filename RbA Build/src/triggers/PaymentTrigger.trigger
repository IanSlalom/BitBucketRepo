/*******************************************************//**

@trigger PaymentTrigger

@brief	trigger framework to secure order of operation

@author  Anthony Strafaccia (Slalom.ADS)

@version	2015-12/25  Slalom.ADS
	Created.

@see		PaymentTriggerTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/

trigger PaymentTrigger on Payment__c (after delete, after insert, after undelete, 
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
		    handler.onBeforeInsert(Trigger.new);
		}
		*/
		//  Before Update
		
		if(Trigger.isUpdate && Trigger.isBefore){
		//	List<Payment__c> newList = (List<Payment__c>)Trigger.new;
			
			UtilityMethods.checkLocked(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, 'Update');
		}
		 

		// Before Delete
		//else 
		if(Trigger.isDelete && Trigger.isBefore){
			UtilityMethods.checkLocked(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, 'Delete');
		    financialTransactionManager.onBeforeDeletePayment(Trigger.old, Trigger.oldMap);
		}

		// After Insert
		else if(Trigger.isInsert && Trigger.isAfter){
			financialTransactionManager.onAfterInsertPayment(Trigger.new, Trigger.newMap);
			orders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
		} 
		 
		// After Update
		else if(Trigger.isUpdate && Trigger.isAfter){
		    financialTransactionManager.onAfterUpdatePayment(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
			orders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
		}
		
		            
		//After Delete
		
		else if(Trigger.isDelete && Trigger.isAfter){
//		    handler.onAfterDelete(Trigger.old, Trigger.oldMap);
			orders = (List<SObject>) dlrs.RollupService.rollup(trigger.old);
		}
		
		
		// After Undelete 
		
		else if(Trigger.isUnDelete){
//		    financialTransactionManager.onUndelete(Trigger.new, Trigger.newMap);
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
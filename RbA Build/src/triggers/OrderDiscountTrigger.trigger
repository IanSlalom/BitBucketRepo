

/*******************************************************//**

@trigger OrderDiscountTrigger

@brief	trigger framework to secure order of operation

@author  Anthony Strafaccia (Slalom.ADS)

@version	2016-5/9  Slalom.ADS Created.
 
@see		OrderDiscountTriggerTest

@copyright  (c)2016 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/

trigger OrderDiscountTrigger on Order_Discount__c (after delete, after insert, after undelete, 
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
		RMS_OrderDiscountManager orderDiscountManager = new RMS_OrderDiscountManager();
		List<SObject> orders = new List<SObject>();
	   	/*     
		// Before Insert
		if(Trigger.isInsert && Trigger.isBefore){
		    orderItemManager.setUpChangeHistoryOnCreate(Trigger.new);
		} 
		else 
		*/
		//  Before Update
		if(Trigger.isUpdate && Trigger.isBefore){
			orderDiscountManager.updateChangeHistoryOnUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
		}
 
		// Before Delete
		/*
		else if(Trigger.isDelete && Trigger.isBefore){
			UtilityMethods.checkLocked(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, 'Delete');
		    financialTransactionManager.onBeforeDeletePayment(Trigger.old, Trigger.oldMap);
		}
		*/ 
		// After Insert
		else if(Trigger.isInsert && Trigger.isAfter){
			 orderDiscountManager.setUpChangeHistoryOnCreate(Trigger.new, Trigger.newMap);
		} 
		/* 
		// After Update
		else if(Trigger.isUpdate && Trigger.isAfter){
		    financialTransactionManager.onAfterUpdatePayment(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
			orders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
		}
		
		            
		//After Delete
		
		else if(Trigger.isDelete && Trigger.isAfter){
		    handler.onAfterDelete(Trigger.old, Trigger.oldMap);
		}
		
		
		// After Undelete 
		
		else if(Trigger.isUnDelete){
		    financialTransactionManager.onUndelete(Trigger.new, Trigger.newMap);
		}
		update orders;		
		*/
	}

}

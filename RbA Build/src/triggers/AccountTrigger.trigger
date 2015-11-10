/*******************************************************//**

@trigger AccountTrigger

@brief	trigger framework to secure order of operation

@author  Anthony Strafaccia (Slalom.ADS)

@version	2015-10/15  Slalom.ADS
	Created.

@see		AccountTriggerTest
 
@copyright  (c)2015 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/

trigger AccountTrigger on Account (before insert, before update, before delete, 
                                            after insert, after undelete, after update, after delete) {
	
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
        RMS_MunicipalityMatchManager municipalityMatchManager = new RMS_MunicipalityMatchManager(); 

		
		// Before Insert
		if(Trigger.isInsert && Trigger.isBefore){
		    municipalityMatchManager.matchBuildingPermitMunicipality(Trigger.New);
		}
		
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
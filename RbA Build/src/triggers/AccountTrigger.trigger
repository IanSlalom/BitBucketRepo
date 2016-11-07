/*******************************************************//**

@trigger AccountTrigger

@brief  trigger framework to secure order of operation

@author  Anthony Strafaccia (Slalom.ADS)

@version    2015-10/15  Slalom.ADS
    Created.

@see        AccountTriggerTest
 
@copyright  (c)2015 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/

trigger AccountTrigger on Account (before insert, before update, before delete, 
                                            after insert, after undelete, after update, after delete) {
	// Run for all profiles
    // Before Insert
    if(Trigger.isInsert && Trigger.isBefore){
        RMS_MunicipalityMatchManager municipalityMatchManager = new RMS_MunicipalityMatchManager(); 
        municipalityMatchManager.matchBuildingPermitMunicipality(Trigger.New);
    }
	
	// Begin logic to filter skip logic by profile    
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
        RMS_reactivateResource reactivateResource = new RMS_reactivateResource();
        RMS_addressManager addressManager = new RMS_addressManager();
        RMS_AccountTriggerHandler handler = new RMS_AccountTriggerHandler();
        // Before Insert
        if(Trigger.isInsert && Trigger.isBefore){
            //handler.OnBeforeInsert(Trigger.old, Trigger.new, Trigger.newMap, Trigger.oldMap); 
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
        
        else if(Trigger.isInsert && Trigger.isAfter){
            handler.OnAfterInsert(Trigger.new);
        }
        
         
        // After Update
        
        else if(Trigger.isUpdate && Trigger.isAfter){            
            reactivateResource.reactivateResource(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);            
            addressManager.updateContactAddresses(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);           
            handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
        }
        
                    
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
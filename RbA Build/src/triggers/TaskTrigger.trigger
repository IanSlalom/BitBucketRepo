/*******************************************************//**

@trigger TaskTrigger

@brief  trigger framework to secure order of operation

@author  Kai Ruan (Slalom)

@version    2016-5/11  Slalom
    Created.

@see        TaskTriggerTest

@copyright  (c)2016 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/

trigger TaskTrigger on Task (after update) {
    
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
        TaskTriggerHandler handler = new TaskTriggerHandler();

        if(Trigger.isUpdate && Trigger.isAfter){
        	handler.onAfterUpdate(Trigger.oldMap,Trigger.newMap);
        }

    }
}
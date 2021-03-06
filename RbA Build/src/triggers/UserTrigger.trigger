/*******************************************************//**

@trigger UserTrigger

@brief  trigger framework to secure order of operation

@author  Creston Kuenzi (Slalom.CDK)

@version    2016-5/25  Slalom.CDK
    Created.

@see        UserTriggerTest

@copyright  (c)2016 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/

trigger UserTrigger on User (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) 
{
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
        UserTriggerHandler handler = new UserTriggerHandler(Trigger.isExecuting,Trigger.size);       
           
        // Before Insert
        
        if(Trigger.isInsert && Trigger.isBefore){
            handler.OnBeforeInsert(Trigger.new);
        }
        
        //  Before Update
        
        if(Trigger.isUpdate && Trigger.isBefore){
            handler.onBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
          
    
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
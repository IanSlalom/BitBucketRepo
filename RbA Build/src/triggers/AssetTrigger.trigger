/*******************************************************//**

@trigger AssetTrigger

@brief  trigger framework to secure order of operation

@author  Anthony Strafaccia (Slalom.ADS)

@version    2016-1/7  Slalom.ADS
    Created.

@see        AssetTriggerTest

@copyright  (c)2016 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/

trigger AssetTrigger on Asset (after delete, after insert, after undelete, 
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
         for (Asset asset : Trigger.new) {
             if(asset.Legacy_Asset__c == FALSE){
        //HANDLERS AND MANAGERS
        RMS_financialTransactionManager financialTransactionManager = new RMS_financialTransactionManager();
            
        // Before Insert
        /*
        if(Trigger.isInsert && Trigger.isBefore){
            handler.onBeforeInsert(Trigger.new);
        }
        */
        //  Before Update
        /*
        if(Trigger.isUpdate && Trigger.isBefore){
            financialTransactionManager.onBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        }
         */

        // Before Delete
        //else  
        if(Trigger.isDelete && Trigger.isBefore){
            financialTransactionManager.onBeforeDeleteAsset(Trigger.old, Trigger.oldMap);
        }

        // After Insert
        else if(Trigger.isInsert && Trigger.isAfter){
            financialTransactionManager.onAfterInsertAsset(Trigger.new, Trigger.newMap);
        } 
         
        // After Update 
        else if(Trigger.isUpdate && Trigger.isAfter){
            financialTransactionManager.onAfterUpdateAsset(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        }
        
                    
        //After Delete
        /*
        else if(Trigger.isDelete && Trigger.isAfter){
            handler.onAfterDelete(Trigger.old, Trigger.oldMap);
        }
        */
        
        // After Undelete 
        /*
        else if(Trigger.isUnDelete){
            financialTransactionManager.onUndelete(Trigger.new, Trigger.newMap);
        }
        */
    }
         }
    }
}
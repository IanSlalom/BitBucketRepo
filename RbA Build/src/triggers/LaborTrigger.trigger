/*******************************************************//**

@trigger LaborTrigger

@brief  trigger framework to secure order of operation

@author  Anthony Strafaccia (Slalom.ADS)

@version    2016-1/7  Slalom.ADS
    Created.

@see        LaborTriggerTest

@copyright  (c)2016 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/

trigger LaborTrigger on Labor__c (after delete, after insert, after undelete, 
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
        List<SObject> wkorders = new List<SObject>();
            
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
            financialTransactionManager.onBeforeDeleteLabor(Trigger.old, Trigger.oldMap);
        }

        // After Insert
        else if(Trigger.isInsert && Trigger.isAfter){
            financialTransactionManager.onAfterInsertLabor(Trigger.new, Trigger.newMap);
            wkorders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        } 
         
        // After Update
        else if(Trigger.isUpdate && Trigger.isAfter){
            financialTransactionManager.onAfterUpdateLabor(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
            wkorders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }
        
                    
        //After Delete
        /*
        else if(Trigger.isDelete && Trigger.isAfter){
            handler.onAfterDelete(Trigger.old, Trigger.oldMap);
            wkorders = (List<SObject>) dlrs.RollupService.rollup(trigger.old);
        }
        */
        
        // After Undelete 
        /*
        else if(Trigger.isUnDelete){
            financialTransactionManager.onUndelete(Trigger.new, Trigger.newMap);
            wkorders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }
        */
        update wkorders;
    }
}
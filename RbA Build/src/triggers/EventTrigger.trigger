/*******************************************************//**

@trigger EventTrigger

@brief  trigger framework to secure order of operation

@author  Brianne Wilson (Slalom.BLW)

@version    2016-3/21  Slalom.BLW
    Created.


@copyright  (c)2016 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/

trigger EventTrigger on Event (after delete, after insert, after undelete, 
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
            
        }
         */

        // Before Delete
        //else  
        if(Trigger.isDelete && Trigger.isBefore){
            
        }

        // After Insert
        else if(Trigger.isInsert && Trigger.isAfter){
            
            wkorders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        } 
         
        // After Update
        else if(Trigger.isUpdate && Trigger.isAfter){
            
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
            
            wkorders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }
        */
        update wkorders;
    }
}
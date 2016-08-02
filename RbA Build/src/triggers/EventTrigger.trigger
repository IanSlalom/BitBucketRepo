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
        RMS_populateResourceonEventManager populateResourceonEventManager = new RMS_populateResourceonEventManager();
        RMS_acceptInvite acceptInvite = new RMS_acceptInvite();
        RMS_eventManager eventManager = new RMS_eventManager();

        // Before Insert
        if(Trigger.isInsert && Trigger.isBefore){
            populateResourceonEventManager.populateResourceonUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
             populateResourceonEventManager.populateInstallCrew(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        }
        
        //  Before Update
        if(Trigger.isUpdate && Trigger.isBefore){
            populateResourceonEventManager.populateResourceonUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);    
            populateResourceonEventManager.populateInstallCrew(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        }
         

        // Before Delete
        //else   
        if(Trigger.isDelete && Trigger.isBefore){
            wkorders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
            eventManager.createChangeHistoryOnDelete(Trigger.old, Trigger.oldmap);
        }

        // After Insert
        else if(Trigger.isInsert && Trigger.isAfter){
            acceptInvite.acceptInvite(Trigger.new, Trigger.newMap);            
            wkorders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
            
        } 
         
        // After Update
        else if(Trigger.isUpdate && Trigger.isAfter){           
            wkorders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }
        
                    
        //After Delete
        
        else if(Trigger.isDelete && Trigger.isAfter){
            
            wkorders = (List<SObject>) dlrs.RollupService.rollup(trigger.old);
        }
        
        
        // After Undelete 
        /*
        else if(Trigger.isUnDelete){
            
            wkorders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }
        */
        update wkorders;
    }
}
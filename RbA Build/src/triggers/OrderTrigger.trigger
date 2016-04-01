/*******************************************************//**

@trigger OrderTrigger

@brief  trigger framework to secure order of operation

@author  Anthony Strafaccia (Slalom.ADS)

@version    2015-10/15  Slalom.ADS
    Created.

@see        OrderTriggerTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/

trigger OrderTrigger on Order (before insert, before update, before delete, 
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
        RMS_WorkOrderCreationManager workOrderCreationManager = new RMS_WorkOrderCreationManager();
        RMS_backOfficeChecklistManager backOfficeCheckListManager = new RMS_backOfficeChecklistManager();
        RMS_financialTransactionManager financialTransactionManager = new RMS_financialTransactionManager();
        List<SObject> accounts = new List<SObject>();
           
        // Before Insert
        /*
        if(Trigger.isInsert && Trigger.isBefore){
            handler.OnBeforeInsert(Trigger.new);
        }
        */
        //  Before Update
        
        if(Trigger.isUpdate && Trigger.isBefore){
            UtilityMethods.checkLockedByStatus(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, 'Order');
            workOrderCreationManager.createWorkOrderOnOrderActivation(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        }
          
    
        // Before Delete
        /*
        else if(Trigger.isDelete && Trigger.isBefore){
            handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
        }
        */
        
        // After Insert 
        else if(Trigger.isInsert && Trigger.isAfter){
            workOrderCreationManager.createWorkOrderOnOrderCreation(Trigger.new, Trigger.newMap);
            backOfficeCheckListManager.createBackOfficeChecksOnOrderCreation(Trigger.new, Trigger.newMap);
                         accounts = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        } 
        
        // After Update
        else if(Trigger.isUpdate && Trigger.isAfter){

            	financialTransactionManager.onAfterUpdateOrder(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
                accounts = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }
                    
        //After Delete
        /*
        else if(Trigger.isDelete && Trigger.isAfter){
            handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
                         accounts = (List<SObject>) dlrs.RollupService.rollup(trigger.old);
        }
        */
        
        // After Undelete 
        /*
        else if(Trigger.isUnDelete){
            handler.OnUndelete(Trigger.new);
                         accounts = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }
        */
        
        update accounts;
    }
}
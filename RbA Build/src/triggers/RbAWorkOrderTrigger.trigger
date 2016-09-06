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

trigger RbAWorkOrderTrigger on RbA_Work_Order__c (after delete, after insert, after undelete, 
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
        RMS_WorkOrderCreationManager workOrderCreationManager = new RMS_WorkOrderCreationManager();
        RMS_addApplicationNotes applicationNotes = new RMS_addApplicationNotes();
        RMS_addSkilltoWO addSkilltoWO = new RMS_addSkilltoWO();       
        List<SObject> orders = new List<SObject>();
       
        // Before Insert
        
        if(Trigger.isInsert && Trigger.isBefore){
             applicationNotes.populateApplicationNotesCreate(Trigger.new, Trigger.newMap); 
        }
        
        
        //  Before Update
        else
        if(Trigger.isUpdate && Trigger.isBefore){
            workOrderCreationManager.createInstallWorkOrderOnTechMeasureComplete(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
            applicationNotes.populateApplicationNotesUpdate(Trigger.old,Trigger.new,Trigger.oldMap,Trigger.newMap);
        }
         
    
        // Before Delete
        /*
        else if(Trigger.isDelete && Trigger.isBefore){
            handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
        }
        */
        
        // After Insert 
       
      else if(Trigger.isInsert && Trigger.isAfter){
            // run the order rollup real-time if the order trigger
            // hasn't been run yet, otherwise run it @future         
          addSkilltoWO.addSkilltoWO(Trigger.new, Trigger.newMap);         
              if (UtilityMethods.hasOrderTriggerRan())
                RMS_FutureRollups.rollupWorkOrdersToOrders(trigger.newMap.keySet());
              else
                orders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        } 
     
        
        // After Update
        
        else if(Trigger.isUpdate && Trigger.isAfter){
            // run the order rollup real-time if the order trigger
            // hasn't been run yet, otherwise run it @future            
            addSkilltoWO.addSkillonUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
            if (UtilityMethods.hasOrderTriggerRan())
                RMS_FutureRollups.rollupWorkOrdersToOrders(trigger.newMap.keySet());
            else
                orders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }

       
                    
        //After Delete
        /*
        else if(Trigger.isDelete && Trigger.isAfter){
            handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
            orders = (List<SObject>) dlrs.RollupService.rollup(trigger.old);
        }
        */
        
        // After Undelete 
        /*
        else if(Trigger.isUnDelete){
            handler.OnUndelete(Trigger.new);
            orders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }
        */
        
        // run the order rollup real-time if the order trigger
        // hasn't been run yet, otherwise run it @future            
        if (UtilityMethods.hasOrderTriggerRan()) return;

 		// Try - Catch to catch any dml errors doing the order  rollup and displaying
		// errors on the rba work orders
		try { update orders;} 
		catch(System.DmlException e) {
			if (Trigger.isDelete) for (sObject obj : trigger.old) { obj.addError(e.getDmlMessage(0)); }
			else for (sObject obj : trigger.new) { obj.addError(e.getDmlMessage(0)); }
		}
    }
}
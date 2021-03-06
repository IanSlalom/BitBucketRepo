/*******************************************************//**

@trigger warrantyTrigger

@brief  trigger framework to secure order of operation

@author  Brianne Wilson (Slalom.BLW)

@version    2016-6-06  Slalom.BLW
    Created.

@see        

@copyright  (c)2016 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/

trigger warrantyTrigger on Warranty__c (after delete, after insert, after undelete, 
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
        List<SObject> orderitems = new List<SObject>();
       
        // Before Insert
        /*
        if(Trigger.isInsert && Trigger.isBefore){
            handler.OnBeforeInsert(Trigger.new);
        }
        */
        
        //  Before Update
        /*
        if(Trigger.isUpdate && Trigger.isBefore){
           
        }
         
    
        // Before Delete
        /*
        else if(Trigger.isDelete && Trigger.isBefore){
            handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
        }
        */
        
        // After Insert 
        // else       
        if(Trigger.isInsert && Trigger.isAfter){
            orderitems = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        } 
        // After Update
        else if(Trigger.isUpdate && Trigger.isAfter){
            orderitems = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }
        //After Delete
        else if(Trigger.isDelete && Trigger.isAfter){            
            orderitems = (List<SObject>) dlrs.RollupService.rollup(trigger.old);
        }
        // After Undelete 
        else if(Trigger.isUnDelete){
            orderitems = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }
        
        // run the order rollup real-time if the order trigger
        // hasn't been run yet, otherwise run it @future            
        if (UtilityMethods.hasOrderTriggerRan()) return;

 		// Try - Catch to catch any dml errors doing the order item rollup and displaying
		// errors on the warranty records
		try { update orderitems;} 
		catch(System.DmlException e) {
			if (Trigger.isDelete) for (sObject obj : trigger.old) { obj.addError(e.getDmlMessage(0)); }
			else for (sObject obj : trigger.new) { obj.addError(e.getDmlMessage(0)); }
		}
    }
}
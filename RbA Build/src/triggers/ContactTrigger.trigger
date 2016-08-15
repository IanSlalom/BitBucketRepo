/*******************************************************//**

@trigger ContactTrigger

@brief  trigger framework to secure order of operation

@author  Brianne Wilson (Slalom.BLW)

@version    2016-04/04  Slalom.BLW
    Created.

@see        ContactTriggerTest

@copyright  (c)2016 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/

trigger ContactTrigger on Contact (before insert, before update, before delete, 
                                            after insert, after undelete, after update, after delete) {
    
    //GET ALL RMS SETTINGS CUSTOM SETTINGS
    map<String, RMS_Settings__c> RMS_Settings_map = RMS_Settings__c.getAll(); 
    
    //CHECK IF DATA LOADING PROFILE 
    if(RMS_Settings_map.get('Data Loading Profile ID') == null || RMS_Settings_map.get('Unassigned Account Id') == null){
        if(Trigger.isDelete){
            Trigger.old[0].addError(RMS_ErrorMessages.CUSTOM_SETTING_REQUIRED);
        }else{
            Trigger.new[0].addError(RMS_ErrorMessages.CUSTOM_SETTING_REQUIRED);
        }
    }
    //IF NOT DATA LOADING PROFILE RUN LOGIC
    else if(!(UserInfo.getProfileId() == RMS_Settings_map.get('Data Loading Profile ID').Value__c ) ){
        
        //HANDLERS AND MANAGERS
        RMS_createContactHistoryManager contactHistoryCreationManager = new RMS_createContactHistoryManager();
		List<SObject> contacts = new List<SObject>();
           
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
         */ 
    
        // Before Delete
        /*
        else if(Trigger.isDelete && Trigger.isBefore){
            handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
        }
        */
        
        // After Insert 
        if(Trigger.isInsert && Trigger.isAfter){
            contactHistoryCreationManager.createContactHistoryonInsert(Trigger.new);
			contacts = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
            
        } 
        
        // After Update
        else if(Trigger.isUpdate && Trigger.isAfter){
            contactHistoryCreationManager.createContactHistoryonUpdate(Trigger.oldMap, Trigger.newMap);
			contacts = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
                         
        }
                    
		else if(Trigger.isDelete && Trigger.isAfter){
			contacts = (List<SObject>) dlrs.RollupService.rollup(trigger.old);
		}
		
		
		// After Undelete 
		
		else if(Trigger.isUnDelete){
//		    financialTransactionManager.onUndelete(Trigger.new, Trigger.newMap);
			contacts = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
		}
		update contacts;		        
       
    }
}
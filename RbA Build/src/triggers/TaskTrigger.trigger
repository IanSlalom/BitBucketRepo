/*******************************************************//**

@trigger TaskTrigger

@brief  trigger framework to secure order of operation

@author  Brianne Wilson (Slalom.BLW)

@version    2016-5/10  Slalom.BLW
    Created.


@copyright  (c)2016 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/

trigger TaskTrigger on Task (after delete, after insert, after undelete, 
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
        TaskTriggerHandler handler = new TaskTriggerHandler();        
        RMS_assignServiceTaskOwner assignServiceTaskOwner = new RMS_assignServiceTaskOwner();
        
         //Before Insert
        
        if(Trigger.isInsert && Trigger.isBefore){
            assignServiceTaskOwner.assignServiceTaskOwner(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);  
        }
        
        //  Before Update
        
        if(Trigger.isUpdate && Trigger.isBefore){
            assignServiceTaskOwner.assignServiceTaskOwner(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);  
        }
         

        /* Before Delete
        //else  
        if(Trigger.isDelete && Trigger.isBefore){
            
        }

        // After Insert
        //else 
        if(Trigger.isInsert && Trigger.isAfter){
          
            
        } 
         
        // After Update
        else 
        if(Trigger.isUpdate && Trigger.isAfter){
            assignServiceTaskOwner.assignServiceTaskOwner(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
            handler.onAfterUpdate(Trigger.oldMap,Trigger.newMap);
            
        }
        
                    
        /*After Delete
        
        else 
        if(Trigger.isDelete && Trigger.isAfter){
            
           
        }
        
        
        // After Undelete 
        /*
        else if(Trigger.isUnDelete){
            
        
        }
        */
        
    }
}
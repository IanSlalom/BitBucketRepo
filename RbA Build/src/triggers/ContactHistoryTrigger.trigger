trigger ContactHistoryTrigger on Contact_History__c (before insert, before update, before delete, after insert, after undelete, after update, after delete) {
    
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
        
        // Before Insert
        /*
if(Trigger.isInsert && Trigger.isBefore){

}

else

if(Trigger.isUpdate && Trigger.isBefore){


}


// Before Delete
/*
else if(Trigger.isDelete && Trigger.isBefore){
handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
}
*/
        
        // After Insert 
        //else 
        if(Trigger.isInsert && Trigger.isAfter){
            contactHistoryCreationManager.primaryContactController(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
            
        } 
        
        // After Update
        // 
        
        else 
            if(Trigger.isUpdate && Trigger.isAfter){
                contactHistoryCreationManager.updateContactAccount(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);                   
                contactHistoryCreationManager.contactManager(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);                                   
                contactHistoryCreationManager.primaryContactController(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);                            
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
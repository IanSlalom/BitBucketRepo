trigger changeHistoryTrigger on Change_History__c (before insert, before update, before delete, 
                                        after insert, after undelete, after update, after delete) {
//  }    
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
    List<SObject> orders = new List<SObject>();
       
    // Before Insert
    /*
    if(Trigger.isInsert && Trigger.isBefore){
        handler.OnBeforeInsert(Trigger.new);
    }
    /
    //  Before Update
    
    if(Trigger.isUpdate && Trigger.isBefore){
        
    }
      

    // Before Delete
    /*
    else if(Trigger.isDelete && Trigger.isBefore){
        
    }
    */
    
    // After Insert 
    //else 
    if(Trigger.isInsert && Trigger.isAfter){
     RMS_FutureRollups.rollupOrderItemsToOrders(trigger.newMap.keySet());
    } 
    
    // After Update
    else if(Trigger.isUpdate && Trigger.isAfter){
        RMS_FutureRollups.rollupOrderItemsToOrders(trigger.newMap.keySet());
    }
                
    //After Delete
    else if(Trigger.isDelete && Trigger.isAfter){    
        RMS_FutureRollups.rollupOrderItemsToOrders(trigger.oldMap.keySet());
    }
    
    // After Undelete 
    
    else if(Trigger.isUnDelete){
        
        RMS_FutureRollups.rollupOrderItemsToOrders(trigger.newMap.keySet());
    }
    
    // Try - Catch to catch any dml errors doing the sproduct rollup and displaying
    // errors on the charge records
    try { update orders;} 
    catch(System.DmlException e) {
        if (Trigger.isDelete) for (sObject obj : trigger.old) { obj.addError(e.getDmlMessage(0)); }
        else for (sObject obj : trigger.new) { obj.addError(e.getDmlMessage(0)); }
    }
}
}
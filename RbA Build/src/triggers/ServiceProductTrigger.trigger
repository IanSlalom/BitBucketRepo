/*******************************************************//**

@trigger ProductTrigger

@brief  trigger framework to secure order of operation

@author  Brianne Wilson (Slalom.BLW)

@version    2/13/2017  Slalom.BLW
Created.


@copyright  (c)2017 Slalom.  All Rights Reserved.
Unauthorized use is prohibited.

***********************************************************/

trigger ServiceProductTrigger on Service_Product__c (before insert, before update, before delete, after insert, after undelete, after update, after delete) {    
    
    UtilityMethods.setOrderTriggerRan();
    
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
        
        List<SObject> products = new List<SObject>();
        
        // Before Insert
        
        /*if(Trigger.isInsert && Trigger.isBefore){

}

//  Before Update

if(Trigger.isUpdate && Trigger.isBefore){

}


// Before Delete

else if(Trigger.isDelete && Trigger.isBefore){

}


// After Insert 
else */
        
        if(Trigger.isInsert && Trigger.isAfter){
            
            products = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
            
        } 
        
        // After Update
        else if(Trigger.isUpdate && Trigger.isAfter){
            
            products = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
            
            
        }
        
        //After Delete
        
        else if(Trigger.isDelete && Trigger.isAfter){
            
            products = (List<SObject>) dlrs.RollupService.rollup(trigger.old);
        }
        
        
        //After Undelete 
        
        else if(Trigger.isUnDelete){     
            products = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }
        
        // Try - Catch to catch any dml errors doing the account rollup and displaying
        // errors on the order records
        try { update products;} 
        catch(System.DmlException e) {
            if (Trigger.isDelete) for (sObject obj : trigger.old) { obj.addError(e.getDmlMessage(0)); }
            else for (sObject obj : trigger.new) { obj.addError(e.getDmlMessage(0)); }
        }
    }
}
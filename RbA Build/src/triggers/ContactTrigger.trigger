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

trigger ContactTrigger on Contact (before insert, before update, before delete, after insert, after undelete, after update, after delete) {
    
    
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
        RMS_addressManager addressManager =  new RMS_addressManager(); 
        
        // Before Insert
        
        if(Trigger.isInsert && Trigger.isBefore){
            addressManager.populateAccountAddressNewContact(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);             
        }
        
        //Before Update
        
        else
            if(Trigger.isUpdate && Trigger.isBefore){
                addressManager.populateAccountAddressNewAccount(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);   
                contactHistoryCreationManager.uncheckPrimary(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap); 
                
            }
        
        
        // Before Delete
        /*
else if(Trigger.isDelete && Trigger.isBefore){
handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
}
*/
        
        // After Insert 
        if(Trigger.isInsert && Trigger.isAfter){       
            contactHistoryCreationManager.createContactHistoryonInsert(Trigger.new);     
            
        } 
        
        // After Update
        else if(Trigger.isUpdate && Trigger.isAfter){
            contactHistoryCreationManager.createContactHistoryUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap); 
            contactHistoryCreationManager.uncheckFormerPrimary(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap); 
            
        }
        
        /*
else if(Trigger.isDelete && Trigger.isAfter){

}


// After Undelete 

else if(Trigger.isUnDelete){

}
*/
        
        
        
    }
}
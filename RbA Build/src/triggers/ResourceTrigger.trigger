/*******************************************************//**

@trigger ResourceTrigger

@brief  trigger framework to secure order of operation

@author  Brianne Wilson

@version    2016-12/7  
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved.
Unauthorized use is prohibited.

***********************************************************/
trigger ResourceTrigger on Resource__c (after delete, after insert, after undelete,after update, before delete, before insert, before update) {
    
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
        RMS_preventMultipleResourcesforSameUser preventMultipleResourcesforSameUser = new RMS_preventMultipleResourcesforSameUser();
        
        // Before Insert
        
        if(Trigger.isInsert && Trigger.isBefore){
            preventMultipleResourcesforSameUser.preventMultipleResourcesforSameUser(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);             
        }
        
        //Before Update
        
        else
            if(Trigger.isUpdate && Trigger.isBefore){
                preventMultipleResourcesforSameUser.preventMultipleResourcesforSameUser(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);                   
                
            }
        
        
        // Before Delete
        /*
else if(Trigger.isDelete && Trigger.isBefore){

}


// After Insert 
if(Trigger.isInsert && Trigger.isAfter){       


} 

// After Update
else if(Trigger.isUpdate && Trigger.isAfter){


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
/*******************************************************//**

@trigger ChargeTrigger

@brief  trigger framework to secure order of operation

@author  Brianne Wilson (Slalom.BLW)

@version    2016-06-22  Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved.
        Unauthorized use is prohibited.

***********************************************************/

trigger ChargeTrigger on Charge__c (before insert, before update, before delete, 
                                        after insert, after undelete, after update, after delete) {
// Set the order trigger to ran
if(Trigger.isUpdate)UtilityMethods.setOrderTriggerRan();

//  }    
System.Debug('************hasOrderTriggerRanAfter=' +UtilityMethods.hasOrderTriggerRan());
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
    List<SObject> sproducts = new List<SObject>();
       
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
       
     sproducts = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
       
    } 
    
    // After Update
    else if(Trigger.isUpdate && Trigger.isAfter){
        
                     sproducts = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        
    }
                
    //After Delete
    
    else if(Trigger.isDelete && Trigger.isAfter){    
                     sproducts = (List<SObject>) dlrs.RollupService.rollup(trigger.old);
    }
   
    
    // After Undelete 
    /*
    else if(Trigger.isUnDelete){
        
                     sproducts = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
    }
    */
    
    update sproducts;
}
}
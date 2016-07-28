trigger municipalityTrigger on Municipality__c (after delete, after insert, after undelete, 
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
        RMS_MunicipalityManager municipalityManager = new RMS_MunicipalityManager();
       
        // Before Insert
        /*
        if(Trigger.isInsert && Trigger.isBefore){
            handler.OnBeforeInsert(Trigger.new);
        }
        
        
         Before Update
        
        if(Trigger.isUpdate && Trigger.isBefore){
            
        }
         
    
        // Before Delete
       
        else if(Trigger.isDelete && Trigger.isBefore){
            
        }
        
        
        // After Insert 
       
      else */
        
          if(Trigger.isInsert && Trigger.isAfter){

            
          municipalityManager.createMunicipalityMatch(Trigger.new, Trigger.newMap);         

        } 
     
        /*
        // After Update
        
        else if(Trigger.isUpdate && Trigger.isAfter){
            
        }
                    
        //After Delete
       
        else if(Trigger.isDelete && Trigger.isAfter){
            
        }
       
        
        // After Undelete 
       
        else if(Trigger.isUnDelete){
            
        }
        */
           

    }
}
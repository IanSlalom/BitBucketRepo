/*******************************************************//**

@trigger AssignedResourceTrigger

@brief  trigger framework to secure order of operation

@author  Brianne Wilson

@version    2016-12/1  
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved.
Unauthorized use is prohibited.

***********************************************************/

trigger AssignedResourceTrigger on Assigned_Resources__c (after insert, after update) {
    
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
        
        
        
        Map<ID, Rba_Work_Order__c> parentWO = new Map<ID, Rba_Work_Order__c>(); 
        List<Id> listIds = new List<Id>();
        
        for (Assigned_Resources__c childObj : Trigger.new) {
            listIds.add(childObj.Work_Order__c);
        }
        
        
        parentWO = new Map<Id, Rba_Work_Order__c>([SELECT id, Work_Order_Type__c,Primary_Installer__c, Primary_Tech_Measure__c, Primary_Service__c,(SELECT ID, isPrimary__c, Work_Order_Type__c, Scheduled_Resource__c FROM Assigned_Resources__r) FROM Rba_Work_Order__c WHERE ID IN :listIds]);
        
        for (Assigned_Resources__c ar: Trigger.new){
            Rba_Work_Order__c myParentWO = parentWO.get(ar.Work_Order__c);
            If(myParentWO.Work_Order_Type__c == 'Tech Measure'){
                myParentWO.Primary_Tech_Measure__c = ar.Scheduled_Resource__c;
            }
            If(myParentWO.Work_Order_Type__c == 'Install'){
                myParentWO.Primary_Installer__c = ar.Scheduled_Resource__c;
            }
            If(myParentWO.Work_Order_Type__c == 'Service'){
                myParentWO.Primary_Service__c = ar.Scheduled_Resource__c;
            }
            
        }
        
        update parentWO.values();
    }
}
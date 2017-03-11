trigger PurchaseOrderTrigger on Purchase_Order__c ( after insert, after update, before update) {
    
    // This should be used in conjunction with the TriggerHandlerComprehensive.cls template
    // The origin of this pattern is http://www.embracingthecloud.com/2010/07/08/ASimpleTriggerTemplateForSalesforce.aspx
    // 
    
    
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
        
        PurchaseOrderTriggerHandler handler = new PurchaseOrderTriggerHandler(Trigger.isExecuting, Trigger.size);
        List<SObject> orders = new List<SObject>();
        if(Trigger.isUpdate && Trigger.isBefore){
            handler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        }
        if(Trigger.isUpdate && Trigger.isAfter){
            handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
            orders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }
        if(Trigger.isInsert && Trigger.isAfter){
            handler.OnAfterInsert(Trigger.new);
            orders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }
        if(Trigger.isDelete && Trigger.isAfter){
            orders = (List<SObject>) dlrs.RollupService.rollup(trigger.old);
        }
        if(Trigger.isUnDelete){
            orders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }
        
        // Try - Catch to catch any dml errors doing the order rollup and displaying
        // errors on the purchase order records
        try { update orders;} 
        catch(System.DmlException e) {
            if (Trigger.isDelete) for (sObject obj : trigger.old) { obj.addError(e.getDmlMessage(0)); }
            else for (sObject obj : trigger.new) { obj.addError(e.getDmlMessage(0)); }
        }
    }
}
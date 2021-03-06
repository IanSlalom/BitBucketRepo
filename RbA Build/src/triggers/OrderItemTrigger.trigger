/*******************************************************/
/**
    
    @trigger OrderItemTrigger
    
    @brief  trigger framework to secure order of operation
    
    @author  Anthony Strafaccia (Slalom.ADS)
    
    @version    2016-3/3  Slalom.ADS
    Created.
    
    @see        OrderItemTriggerTest
    
    @copyright  (c)2016 Slalom.  All Rights Reserved.
    Unauthorized use is prohibited.
    
    ***********************************************************/
trigger OrderItemTrigger on OrderItem(after delete, after insert, after undelete,
    after update, before delete, before insert, before update) {


    //GET ALL RMS SETTINGS CUSTOM SETTINGS
    map < String, RMS_Settings__c > RMS_Settings_map = RMS_Settings__c.getAll();

    //CHECK IF DATA LOADING PROFILE  
    if (RMS_Settings_map.get('Data Loading Profile ID') == null) {
        if (Trigger.isDelete) {
            Trigger.old[0].addError(RMS_ErrorMessages.DATA_LOADING_CUSTOM_SETTING_REQUIRED);
        } else {
            Trigger.new[0].addError(RMS_ErrorMessages.DATA_LOADING_CUSTOM_SETTING_REQUIRED);
        }
    }
    //IF NOT DATA LOADING PROFILE RUN LOGIC
    else if (!(UserInfo.getProfileId() == RMS_Settings_map.get('Data Loading Profile ID').Value__c)) {
        //HANDLERS AND MANAGERS
        RMS_OrderItemManager orderItemManager = new RMS_OrderItemManager();
        RMS_createCharges createCharges = new RMS_createCharges();
        List <SObject> orderItems = new List <SObject> ();

        // Before Insert
        if(Trigger.isInsert && Trigger.isBefore){
//	        orderItemManager.linkNewChildProducts(Trigger.new);
        } 
        //  Before Update
        else  if (Trigger.isUpdate && Trigger.isBefore) {
            orderItemManager.updateChangeHistoryOnUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
        }
        // Before Delete
        /*
		else if(Trigger.isDelete && Trigger.isBefore){
			UtilityMethods.checkLocked(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap, 'Delete');
			financialTransactionManager.onBeforeDeletePayment(Trigger.old, Trigger.oldMap);
		}
		*/
        // After Insert
        else if (Trigger.isInsert && Trigger.isAfter) {
            orderItemManager.setUpChangeHistoryOnCreate(Trigger.new, Trigger.newMap);
            createCharges.createCharge(Trigger.new, Trigger.newMap);
            RMS_FutureRollups.rollupOrderItemsToOrders(trigger.newMap.keySet());
//    		orderItems = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
        }
         
    	// After Update
    	else if(Trigger.isUpdate && Trigger.isAfter){
            RMS_FutureRollups.rollupOrderItemsToOrders(trigger.newMap.keySet());
//    		orderItems = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
    	}
    	//After Delete
    	else if(Trigger.isDelete && Trigger.isAfter){
//    		orderItems = (List<SObject>) dlrs.RollupService.rollup(trigger.old);
            RMS_FutureRollups.rollupOrderItemsToOrders(trigger.oldMap.keySet());
    	}
    	// After Undelete 
    	else if(Trigger.isUnDelete){
            RMS_FutureRollups.rollupOrderItemsToOrders(trigger.newMap.keySet());
//    		orderItems = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
    	}    
		// Try - Catch to catch any dml errors doing the order rollup and displaying
		// errors on the order item records
		try { update orderItems;} 
		catch(System.DmlException e) {
			if (Trigger.isDelete) for (sObject obj : trigger.old) { obj.addError(e.getDmlMessage(0)); }
			else for (sObject obj : trigger.new) { obj.addError(e.getDmlMessage(0)); }
		}

    }

}
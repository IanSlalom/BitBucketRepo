public with sharing class RMS_OrderTriggerHandler {
  // This should be used in conjunction with the ApexTriggerComprehensive.trigger template
  // The origin of this pattern is http://www.embracingthecloud.com/2010/07/08/ASimpleTriggerTemplateForSalesforce.aspx
  private boolean m_isExecuting = false;
  private integer BatchSize = 0;

  public Id COROServiceId = UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order');
  public ID CORORecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Record_Type', 'Order');
  public ID ChangeOrderRecordTypeId = UtilityMethods.retrieveRecordTypeId('Change_Order', 'Order');

  public RMS_OrderTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }


  public void OnBeforeInsert(Order[] newOrders){
    setPriceBookId(newOrders);
  }
 

  public void OnAfterInsert(Order[] newOrders){
    updateJIPCOROServiceOrders(newOrders);
  }
/*
  @future public static void OnAfterInsertAsync(Set<ID> newOrderIDs){
    //Example usage
    //List<Order> newOrders = [select Id, Name from Order where Id IN :newOrderIDs];
  }*/

  public void OnBeforeUpdate(Map<ID, Order>  oldMap, Map<ID, Order> newMap){

    updateOrderStatus(oldMap,newMap);
    updateOrderTimeStamps(oldMap,newMap);
    updateRevenueRecDate(oldMap,newMap);
    updateUniqueIdentifier(oldMap,newMap);
    updateChangeHistories(oldMap,newMap);
  }

  public void OnAfterUpdate(Map<ID, Order>  oldMap, Map<ID, Order> newMap){
    if(!UtilityMethods.hasOrderTriggerRan()) {
    	createOnHoldTasks(oldMap, newMap);
    }
  }

  /*  
  @future public static void OnAfterUpdateAsync(Set<ID> updatedOrderIDs){
    //List<Order> updatedOrders = [select Id, Name from Order where Id IN :updatedOrderIDs];
  }

  public void OnBeforeDelete(Order[] OrdersToDelete, Map<ID, Order> OrderMap){

  }

  public void OnAfterDelete(Order[] deletedOrders, Map<ID, Order> OrderMap){

  }

  @future public static void OnAfterDeleteAsync(Set<ID> deletedOrderIDs){

  }

  public void OnUndelete(Order[] restoredOrders){

  }*/
  
  public void setPriceBookId(List<Order> newOrders){
    List<Id> soldOrders = new List<Id>();
     for(Order o: newOrders){
      if(o.Sold_Order__c != null){
        soldOrders.add(o.Sold_Order__c);
      }
    }

    Map<Id,Order> soldOrderMap = new Map<Id,Order>([Select Id, PriceBook2Id from Order where Id in: soldOrders and Pricebook2Id != null]);
    for(Order o: newOrders){
      if( o.PriceBook2Id == null){
        if(soldOrderMap.containsKey(o.Sold_Order__c)){
          o.Pricebook2Id = soldOrderMap.get(o.Sold_Order__c).Pricebook2Id;
        }else{
          	o.addError('A valid pricebook could not be retrieved for this order. Please contact your Administrator for help.');
        }
      }
    }
    
    
  }

  public void updateOrderStatus(Map<ID, Order>  oldMap, Map<ID, Order> newMap){
    for(Order o: newMap.values()){   
      // Set the apex context to true so the Prevent Order Status Change validation rule
      // will be ignored if the status needs to be changed
      if(o.Status == 'Tech Measure Needed' && (o.Tech_Measure_Status__c == 'Pending Assignment' || o.Tech_Measure_Status__c == 'Scheduled & Assigned') && oldMap.get(o.Id).Tech_Measure_Status__c != o.Tech_Measure_Status__c){
	    o.Apex_Context__c = true;
        o.status = 'Tech Measure Scheduled';
      }else if(o.Status == 'Tech Measure Scheduled' && o.Tech_Measure_Status__c == 'Complete' && oldMap.get(o.Id).Tech_Measure_Status__c != o.Tech_Measure_Status__c){
	    o.Apex_Context__c = true;
        o.status = 'Ready to Order';
      }else if(o.Status == 'Install Needed' && (o.Install_Order_Status__c == 'Pending Assignment' || o.Install_Order_Status__c == 'Scheduled & Assigned') && oldMap.get(o.Id).Install_Order_Status__c != o.Install_Order_Status__c){
	    o.Apex_Context__c = true;
        o.status = 'Install Scheduled';
      }else if(O.Revenue_Recognized_Date__c != null && o.RecordtypeId == ChangeOrderRecordTypeId){
	    o.Apex_Context__c = true;
        o.status = 'Job Closed';
      }
    }
  }

   public void updateOrderTimeStamps(Map<ID, Order>  oldMap, Map<ID, Order> newMap){
    DateTime now = Datetime.now();
    for(Order o: newMap.values()){   
      if(o.Status != oldMap.get(o.Id).Status){
       if(o.Status == 'Draft'){
         o.Time_Draft__c = now;
        }else if(o.Status == 'On Hold'){
          o.Time_On_Hold__c = now;
        }else if(o.Status == 'Tech Measure Needed'){
          o.Time_Tech_Measure_Needed__c = now;
        }else if(o.Status == 'Tech Measure Scheduled'){
          o.Time_Tech_Measure_Scheduled__c = now;
        }else if(o.Status == 'Ready to Order'){
          o.Time_Ready_To_Order__c = now;
        }else if(o.Status == 'Order Released'){
          o.Time_Order_Released__c = now;
        }else if(o.Status == 'Install Needed'){
          o.Time_Install_Needed__c = now;
        }else if(o.Status == 'Install Scheduled'){
          o.Time_Install_Scheduled__c = now;
        }else if(o.Status == 'Install Complete'){
          o.Time_Install_Complete__c = now;
        }else if(o.Status == 'Job in Progress'){
          o.Time_Job_In_Progress__c = now;
        }else if(o.Status == 'Job Closed'){  
          o.Time_Job_Close__c = now;
          o.Job_Close_Date__c = Date.today();
        }else if(o.Status == 'Pending Cancellation'){
          o.Time_Pending_Cancellation__c = now;
        }else if(o.Status == 'Cancelled'){
          o.Time_Cancelled__c = now;
        }
      }
    }
  }


  public void updateJIPCOROServiceOrders(List<Order> newOrders){
    List<Order> ordersToUpdate = new List<Order>();
    for(Order o : [SELECT Id, Status, Apex_Context__c FROM Order 
                    WHERE RecordType.DeveloperName = 'CORO_Service' 
                    AND Service_Type__c = 'Job in Progress'
                    AND Sold_Order__r.Status = 'Install Scheduled'
                    AND Id in: newOrders]){
      // Allows the order status to be changed
      o.Apex_Context__c = true;
      o.Status = 'Job in Progress';
      ordersToUpdate.add(o);
    }
    update ordersToUpdate;
  }

  public void updateRevenueRecDate(Map<ID, Order>  oldMap, Map<ID, Order> newMap){
   
    for(Order o: newMap.values()){   
      if(o.RecordTypeId == COROServiceId && o.Status != oldMap.get(o.Id).Status &&
          ((o.Status == 'Closed' && o.Service_Type__c != 'Save')|| o.Status == 'Warranty Submitted' && o.Invoice_Subtotal__c > 0)){
          o.Revenue_Recognized_Date__c = System.Today();
      }
    }
  }

  public void createOnHoldTasks(Map<ID, Order>  oldMap, Map<ID, Order> newMap){
    Id onHoldTaskID = UtilityMethods.retrieveRecordTypeId('On_Hold', 'Task');
    List<Task> tasksToInsert = new List<Task>();
    for(Order o: newMap.values()){ 
      System.Debug('*************o.Status=' +o.Status);
      System.Debug('*************oldMap.get(o.Id).Status=' +oldMap.get(o.Id).Status);
      if( o.Status != oldMap.get(o.Id).Status && o.Status == 'On Hold'){
        tasksToInsert.add(new Task(WhatId = o.Id,Primary_Reason__c = '', Secondary_Reason__c = '', OwnerId = o.OwnerId, Subject = 'On Hold', RecordtypeId = onHoldTaskID));
      }
    }
    if(!tasksToInsert.isEmpty()){
      insert tasksToInsert;
    }
  }
  
  public void updateUniqueIdentifier(Map<ID, Order>  oldMap, Map<ID, Order> newMap){
    List<Order> ordersToProcess = new List<Order>();
    for(Order o: newMap.values()){   
      if(o.RecordTypeId == CORORecordTypeId && o.Status != oldMap.get(o.Id).Status &&
          o.Status != 'Cancelled' && oldMap.get(o.Id).Status == 'Draft'){
          ordersToProcess.add(o); 
      }
    }

    Set<Id> storeConfigIds = new Set<Id>();
    if(!ordersToProcess.isEmpty()){
      for(Order o: [SELECT Id, Store_Location__r.Store_Number__c, Store_Location__r.Active_Store_Configuration__r.Order_Number__c FROM Order  WHERE Id in: ordersToProcess]){
        if(o.Store_Location__r.Store_Number__c == null){
            // add the error to the original record not the selected record
            Order originalOrder = newMap.get(o.Id);
            originalOrder.addError('A valid store number could not be retrieved from the Store Location Account. Please contact your Administrator for help.');
//          o.addError('A valid store number could not be retrieved from the Store Location Account. Please contact your Administrator for help.');
        }
        else if(o.Store_Location__r.Active_Store_Configuration__r.Order_Number__c == null){
            // add the error to the original record not the selected record
            Order originalOrder = newMap.get(o.Id);
            originalOrder.addError('A valid order number could not be retrieved from the Store Configuration. Please contact your Administrator for help.');
//          o.addError('A valid order number could not be retrieved from the Store Configuration. Please contact your Administrator for help.');
        }else{
            storeConfigIds.add(o.Store_Location__r.Active_Store_Configuration__c);
        }
      }


    //Lock the Store Configuration records to prevent another transaction from altering the Order Number
    Map<Id,Store_Configuration__c> configsToLock = new Map<Id,Store_Configuration__c>([Select Id, Order_Number__c from Store_Configuration__c where Id in: storeConfigIds for update]);

    for(Order o: [SELECT Id, Store_Location__r.Store_Number__c, Store_Location__r.Active_Store_Configuration__c FROM Order  WHERE Id in: ordersToProcess 
                  AND Store_Location__r.Store_Number__c != null AND Store_Location__r.Active_Store_Configuration__c in: configsToLock.keyset()]){
        String storeNum = o.Store_Location__r.Store_Number__c;
        while(storeNum.length()<4){
          storeNum = '0'+storeNum;
        }
        String uniqueIDString = storeNum + configsToLock.get(o.Store_Location__r.Active_Store_Configuration__c).Order_Number__c.toPlainString();
        while(uniqueIdString.length() < 11){
          uniqueIdString = uniqueIdString.substring(0,4) + '0' + uniqueIdString.substring(4);
        }
        if(newMap.get(o.Id).Unique_Identifier__c == null){
          newMap.get(o.Id).Unique_Identifier__c = uniqueIdString;
          configsToLock.get(o.Store_Location__r.Active_Store_Configuration__c).Order_Number__c +=1;
        }
        
    }
    update configsToLock.values();
    }
  }

  public void updateChangeHistories(Map<ID, Order>  oldMap, Map<ID, Order> newMap){
    Set<Id> orderIdsToUpdateChangeHistory = new Set<Id>();
    for(Order o: newMap.values()){ 
      // If the revenue recognized date or booking date has changed on an order, 
      // for CORO Orders or Change Orders, add it to the list
      if( ((o.Revenue_Recognized_Date__c != oldMap.get(o.Id).Revenue_Recognized_Date__c) ||
      	   (o.EffectiveDate != oldMap.get(o.Id).EffectiveDate)) &&
      	  ((o.RecordTypeId == UtilityMethods.RecordTypeFor('Order', 'CORO_Record_Type') ||
      	   (o.RecordTypeId == UtilityMethods.RecordTypeFor('Order', 'Change_Order'))) )){
      	orderIdsToUpdateChangeHistory.add(o.Id);   	
      }
    }
    // If none of the updated orders meet the criteria above, just return
    if(orderIdsToUpdateChangeHistory.isEmpty()){
      return;
    }

	List<Change_History__c> changeHistoriesToUpdate = new List<Change_History__c>();
    // Now loop through all of the change histories linked to the orders in the set and update their
    // Rev Recognized and Booking dates
    for (Change_History__c ch : [SELECT Id, Order_Revenue_Recognition_Date__c, Order_Booking_Date__c, Order_Product__r.OrderId, Order_Discount__r.Order__r.Id FROM Change_History__c
    							 WHERE Order_Product__r.OrderId IN : orderIdsToUpdateChangeHistory OR Order_Discount__r.Order__r.Id IN : orderIdsToUpdateChangeHistory]) 
    {
    	// If this is an Order Product change history
    	if (orderIdsToUpdateChangeHistory.contains(ch.Order_Product__r.OrderId)) {
    		ch.Order_Revenue_Recognition_Date__c = newMap.get(ch.Order_Product__r.OrderId).Revenue_Recognized_Date__c;
    		ch.Order_Booking_Date__c = newMap.get(ch.Order_Product__r.OrderId).EffectiveDate;
    		changeHistoriesToUpdate.add(ch);
    	}

    	// If this is an Order Discount change history
    	if (orderIdsToUpdateChangeHistory.contains(ch.Order_Discount__r.Order__r.Id)) {
    		ch.Order_Revenue_Recognition_Date__c = newMap.get(ch.Order_Discount__r.Order__r.Id).Revenue_Recognized_Date__c;
    		ch.Order_Booking_Date__c = newMap.get(ch.Order_Discount__r.Order__r.Id).EffectiveDate;
    		changeHistoriesToUpdate.add(ch);    		
    	}
    }
    
    update changeHistoriesToUpdate;
    
  }
  
  
  
}
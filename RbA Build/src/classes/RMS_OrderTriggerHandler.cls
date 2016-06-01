public with sharing class RMS_OrderTriggerHandler {
  // This should be used in conjunction with the ApexTriggerComprehensive.trigger template
  // The origin of this pattern is http://www.embracingthecloud.com/2010/07/08/ASimpleTriggerTemplateForSalesforce.aspx
  private boolean m_isExecuting = false;
  private integer BatchSize = 0;

  public Id COROServiceId = UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order');
  public ID CORORecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Record_Type', 'Order');

  public RMS_OrderTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }

/*
  public void OnBeforeInsert(Order[] newOrders){
    
  }
 */

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
  }

  public void OnAfterUpdate(Map<ID, Order>  oldMap, Map<ID, Order> newMap){
    createOnHoldTasks(oldMap, newMap);
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

  public void updateOrderStatus(Map<ID, Order>  oldMap, Map<ID, Order> newMap){
    for(Order o: newMap.values()){   
      if(o.Status == 'Tech Measure Needed' && o.Tech_Measure_Status__c == 'Scheduled' && oldMap.get(o.Id).Tech_Measure_Status__c != o.Tech_Measure_Status__c){
        //Sets the Apex Context variable to true, enables bypassing validation rules that specify !Apex_Context (e.g. Status Update Through UI)
        //o.Apex_Context__c = true;
        o.status = 'Tech Measure Scheduled';
      }else if(o.Status == 'Tech Measure Scheduled' && o.Tech_Measure_Status__c == 'Complete' && oldMap.get(o.Id).Tech_Measure_Status__c != o.Tech_Measure_Status__c){
        //o.Apex_Context__c = true;
        o.status = 'Ready to Order';
      }else if(o.Status == 'Install Needed' && o.Install_Order_Status__c == 'Scheduled' && oldMap.get(o.Id).Install_Order_Status__c != o.Install_Order_Status__c){
        //o.Apex_Context__c = true;
        o.status = 'Install Scheduled';
      }/* removing per JETT-1601 else if(o.Status == 'Install Scheduled' && o.Install_Order_Status__c == 'Completed' && oldMap.get(o.Id).Install_Order_Status__c != o.Install_Order_Status__c){
        //o.Apex_Context__c = true;
        o.status = 'Install Complete';
      }*/
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
        }else if(o.Status == 'Cancelled'){
          o.Time_Cancelled__c = now;
        }
      }
    }
  }


  public void updateJIPCOROServiceOrders(List<Order> newOrders){
    List<Order> ordersToUpdate = new List<Order>();
    for(Order o : [SELECT Id, Status FROM Order 
                    WHERE RecordType.DeveloperName = 'CORO_Service' 
                    AND Service_Type__c = 'Job in Progress'
                    AND Sold_Order__r.Status = 'Install Scheduled'
                    AND Id in: newOrders]){
      o.Status = 'Job in Progress';
      ordersToUpdate.add(o);
    }
    update ordersToUpdate;
  }

  public void updateRevenueRecDate(Map<ID, Order>  oldMap, Map<ID, Order> newMap){
   
    for(Order o: newMap.values()){   
      if(o.RecordTypeId == COROServiceId && o.Status != oldMap.get(o.Id).Status &&
          (o.Status == 'Closed' || o.Status == 'Warranty Submitted' && o.Invoice_Subtotal__c > 0)){
          o.Revenue_Recognized_Date__c = System.Today();
      }
    }
  }

  public void createOnHoldTasks(Map<ID, Order>  oldMap, Map<ID, Order> newMap){
    Id onHoldTaskID = UtilityMethods.retrieveRecordTypeId('On_Hold', 'Task');
    List<Task> tasksToInsert = new List<Task>();
    for(Order o: newMap.values()){ 
      if( o.Status != oldMap.get(o.Id).Status && o.Status == 'On Hold'){
        tasksToInsert.add(new Task(WhatId = o.Id,Primary_Reason__c = 'PlaceHolder1', Secondary_Reason__c = 'PlaceHolder1', OwnerId = o.OwnerId, Subject = 'On Hold'));
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
          o.addError('A valid store number could not be retrieved from the Store Location Account. Please contact your Administrator for help.');
        }
        else if(o.Store_Location__r.Active_Store_Configuration__r.Order_Number__c == null){
          o.addError('A valid order number could not be retrieved from the Store Configuration. Please contact your Administrator for help.');
        }else{
            storeConfigIds.add(o.Store_Location__r.Active_Store_Configuration__c);
        }
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
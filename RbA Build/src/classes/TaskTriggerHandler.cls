public with sharing class TaskTriggerHandler {
  // This should be used in conjunction with the ApexTriggerComprehensive.trigger template
  // The origin of this pattern is http://www.embracingthecloud.com/2010/07/08/ASimpleTriggerTemplateForSalesforce.aspx


  public TaskTriggerHandler(){
  }

  
  //public void OnBeforeInsert(Task[] newTasks){
  //  /*
  //  //Example usage
  //  for(Task newTask : newTasks){
  //    if(newTask.AnnualRevenue == null){
  //      newTask.AnnualRevenue.addError('Missing annual revenue');
  //    }
  //  }
  //  */
  //}

  //public void OnAfterInsert(Task[] newTasks){

  //}

  //@future public static void OnAfterInsertAsync(Set<ID> newTaskIDs){
  //  //Example usage
  //  //List<Task> newTasks = [select Id, Name from Task where Id IN :newTaskIDs];
  //}

  //public void OnBeforeUpdate(Task[] oldTasks, Task[] updatedTasks, Map<ID, Task> TaskMap){
  //  //Example Map usage
  //  //Map<ID, Contact> contacts = new Map<ID, Contact>( [select Id, FirstName, LastName, Email from Contact where TaskId IN :TaskMap.keySet()] );
  //}

  public void OnAfterUpdate(Map<ID, Task> oldMap, Map<ID, Task> newMap){
    updateOrderStatus(oldMap,newMap);
  }

  //@future public static void OnAfterUpdateAsync(Set<ID> updatedTaskIDs){
  //  //List<Task> updatedTasks = [select Id, Name from Task where Id IN :updatedTaskIDs];
  //}

  //public void OnBeforeDelete(Task[] TasksToDelete, Map<ID, Task> TaskMap){

  //}

  //public void OnAfterDelete(Task[] deletedTasks, Map<ID, Task> TaskMap){

  //}

  //@future public static void OnAfterDeleteAsync(Set<ID> deletedTaskIDs){

  //}

  //public void OnUndelete(Task[] restoredTasks){

  //}

  public void updateOrderStatus(Map<Id,Task> oldMap, Map<Id, Task> newMap){
    Set<Id> relatedOrders = new Set<Id>();
    String orderPrefix = Schema.SObjectType.Order.getKeyPrefix();
    Id onHoldTaskId = UtilityMethods.retrieveRecordTypeId('On_Hold', 'Task');
    for(Task t: newMap.values()){
      if(t.RecordTypeId == onHoldTaskId && ((String)t.WhatId).startsWith(orderPrefix) && t.isClosed && !oldMap.get(t.Id).isClosed){
        relatedOrders.add(t.WhatId);
      }
    }

    for(Task t:[SELECT Id, WhatId FROM Task WHERE WhatId in: relatedOrders AND isClosed = false AND recordTypeId =: onHoldTaskId]){
      relatedOrders.remove(t.WhatId);
    }

    List<Order> ordersToUpdate = [Select Id, Status, Prior_Status__c, Apex_Context__c from Order Where Id in: relatedOrders];
    for(Order o: ordersToUpdate){
      if(o.Status == 'On Hold'){
        o.Status = o.Prior_Status__c;
        o.Apex_Context__c = true;
      }
    }
    update ordersToUpdate;
  }

}
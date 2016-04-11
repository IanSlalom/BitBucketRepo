public with sharing class PurchaseOrderTriggerHandler {
  // This should be used in conjunction with the ApexTriggerComprehensive.trigger template
  // The origin of this pattern is http://www.embracingthecloud.com/2010/07/08/ASimpleTriggerTemplateForSalesforce.aspx
  private boolean m_isExecuting = false;
  private integer BatchSize = 0;

  public PurchaseOrderTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }

  /*
  public void OnBeforeInsert(Purchase_Order__c[] newPurchaseOrders){

  }

  public void OnAfterInsert(Purchase_Order__c[] newPurchaseOrders){

  }

  @future public static void OnAfterInsertAsync(Set<ID> newPurchaseOrderIDs){
    //Example usage
    //List<Purchase_Order__c> newPurchase_Order__cs = [select Id, Name from Purchase_Order__c where Id IN :newPurchase_Order__cIDs];
  }

  public void OnBeforeUpdate( Map<ID, Purchase_Order__c> oldMap, Map<ID, Purchase_Order__c> newMap){
    //Example Map usage
    //Map<ID, Contact> contacts = new Map<ID, Contact>( [select Id, FirstName, LastName, Email from Contact where Purchase_Order__cId IN :Purchase_Order__cMap.keySet()] );
  }
  */
  public void OnAfterUpdate( Map<ID, Purchase_Order__c> oldMap, Map<ID, Purchase_Order__c> newMap){

    updateOrderStatusToOrderReleased(oldMap, newMap);
    updateOrderStatusToInstallNeeded(oldMap, newMap);

  }

  /*
  @future public static void OnAfterUpdateAsync(Set<ID> updatedPurchaseOrderIDs){
    //List<Purchase_Order__c> updatedPurchase_Order__cs = [select Id, Name from Purchase_Order__c where Id IN :updatedPurchase_Order__cIDs];
  }

  public void OnBeforeDelete(Purchase_Order__c[] PurchaseOrdersToDelete, Map<ID, Purchase_Order__c> PurchaseOrderMap){

  }

  public void OnAfterDelete(Purchase_Order__c[] deletedPurchaseOrders, Map<ID, Purchase_Order__c> PurchaseOrderMap){

  }

  @future public static void OnAfterDeleteAsync(Set<ID> deletedPurchaseOrderIDs){

  }

  public void OnUndelete(Purchase_Order__c[] restoredPurchaseOrders){

  }*/

  public void updateOrderStatusToOrderReleased(Map<Id, Purchase_Order__c> oldMap, Map<Id,Purchase_Order__c> newMap){
    Map<Id, Order> parentOrders = new Map<Id,Order>();
    Set<Id> orderIds = new Set<Id>();
    Map<Id, Boolean> mapOrderIDtoValidForUpdate = new Map<Id, Boolean>();
    List<Order> ordersToUpdate = new List<Order>();
    for(Purchase_Order__c po : newMap.values()){
      if(po.Status__c == 'Released' && oldMap.get(po.Id).Status__c != po.Status__c){
        orderIds.add(po.Order__c);
      }
    }

    parentOrders = new Map<Id,Order>([SELECT Id, Status FROM Order WHERE Id in: orderIds AND Status = 'Ready to Order']);
    List<Purchase_Order__c> allRelatedPOs = [Select Id, Order__c, Status__c from Purchase_Order__c where Order__c in: parentOrders.keySet() and Id not in: newMap.keySet()];

    for(Id orderId: parentOrders.keySet()){
      mapOrderIDtoValidForUpdate.put(orderId, true);
    }
    for(Purchase_Order__c po: allRelatedPOs){
      if(po.Status__c != 'Released' && po.Status__c != 'Cancelled'){
        mapOrderIDtoValidForUpdate.put(po.Order__c,false);
      }
    }


    for(Id orderId: mapOrderIDtoValidForUpdate.keySet()){
      if(mapOrderIDtoValidForUpdate.get(orderId)){
        ordersToUpdate.add(parentOrders.get(orderId));
      }
    }

    for(Order o : ordersToUpdate){
      o.Status = 'Order Released';
    }
    update ordersToUpdate;
  }

  public void updateOrderStatusToInstallNeeded(Map<Id, Purchase_Order__c> oldMap, Map<Id,Purchase_Order__c> newMap){
    Map<Id, Order> parentOrders = new Map<Id,Order>();
    Set<Id> orderIds = new Set<Id>();
    Map<Id, Boolean> mapOrderIDtoValidForUpdate = new Map<Id, Boolean>();
    List<Order> ordersToUpdate = new List<Order>();
    for(Purchase_Order__c po : newMap.values()){
      if(po.Status__c == 'Confirmed' && oldMap.get(po.Id).Status__c != po.Status__c){
        orderIds.add(po.Order__c);
      }
    }

    parentOrders = new Map<Id,Order>([SELECT Id, Status FROM Order WHERE Id in: orderIds AND Status = 'Order Released']);
    List<Purchase_Order__c> allRelatedPOs = [Select Id, Order__c, Status__c from Purchase_Order__c where Order__c in: parentOrders.keySet() and Id not in: newMap.keySet()];
    for(Id orderId: parentOrders.keySet()){
      mapOrderIDtoValidForUpdate.put(orderId, true);
    }
    for(Purchase_Order__c po: allRelatedPOs){
      if(po.Status__c != 'Confirmed' && po.Status__c != 'Cancelled'){
        mapOrderIDtoValidForUpdate.put(po.Order__c,false);
      }
    }

    for(Id orderId: mapOrderIDtoValidForUpdate.keySet()){
      if(mapOrderIDtoValidForUpdate.get(orderId)){
        ordersToUpdate.add(parentOrders.get(orderId));
      }
    }

    for(Order o : ordersToUpdate){
      o.Status = 'Install Needed';
    }
    update ordersToUpdate;
  }
}
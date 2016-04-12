public with sharing class RMS_OrderTriggerHandler {
  // This should be used in conjunction with the ApexTriggerComprehensive.trigger template
  // The origin of this pattern is http://www.embracingthecloud.com/2010/07/08/ASimpleTriggerTemplateForSalesforce.aspx
  private boolean m_isExecuting = false;
  private integer BatchSize = 0;

  public RMS_OrderTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }


 /* public void OnBeforeInsert(Order[] newOrders){

  }

  public void OnAfterInsert(Order[] newOrders){

  }

  @future public static void OnAfterInsertAsync(Set<ID> newOrderIDs){
    //Example usage
    //List<Order> newOrders = [select Id, Name from Order where Id IN :newOrderIDs];
  }*/

  public void OnBeforeUpdate(Map<ID, Order>  oldMap, Map<ID, Order> newMap){

    updateOrderStatus(oldMap,newMap);
  }

  /*public void OnAfterUpdate(Order[] oldOrders, Order[] updatedOrders, Map<ID, Order> OrderMap){

  }

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
      }else if(o.Status == 'Install Scheduled' && o.Install_Order_Status__c == 'Complete' && oldMap.get(o.Id).Install_Order_Status__c != o.Install_Order_Status__c){
        //o.Apex_Context__c = true;
        o.status = 'Install Complete';
      }
    }
  }

  
}
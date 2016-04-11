trigger PurchaseOrderTrigger on Purchase_Order__c (  after update) {

	// This should be used in conjunction with the TriggerHandlerComprehensive.cls template
  // The origin of this pattern is http://www.embracingthecloud.com/2010/07/08/ASimpleTriggerTemplateForSalesforce.aspx

  PurchaseOrderTriggerHandler handler = new PurchaseOrderTriggerHandler(Trigger.isExecuting, Trigger.size);

  if(Trigger.isUpdate && Trigger.isAfter){
    handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
  }
  
}
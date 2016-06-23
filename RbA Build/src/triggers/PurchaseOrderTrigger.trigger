trigger PurchaseOrderTrigger on Purchase_Order__c ( after insert, after update) {

	// This should be used in conjunction with the TriggerHandlerComprehensive.cls template
  // The origin of this pattern is http://www.embracingthecloud.com/2010/07/08/ASimpleTriggerTemplateForSalesforce.aspx

  PurchaseOrderTriggerHandler handler = new PurchaseOrderTriggerHandler(Trigger.isExecuting, Trigger.size);
    List<SObject> orders = new List<SObject>();
    
  if(Trigger.isUpdate && Trigger.isAfter){
    handler.OnAfterUpdate(Trigger.oldMap, Trigger.newMap);
      orders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
  }
  
  if(Trigger.isInsert && Trigger.isAfter){
    handler.OnAfterInsert(Trigger.new);
      orders = (List<SObject>) dlrs.RollupService.rollup(trigger.new);
  }
  
   update orders;
}
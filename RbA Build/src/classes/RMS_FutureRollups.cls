global with sharing class RMS_FutureRollups {

	@future
	public static void rollupWorkOrdersToOrders(Set<Id> workOrders)
	{  
		List<Order> orderRecords = new List<Order>(); 
		List<RbA_Work_Order__c> workOrderRecords = new List<RbA_Work_Order__c>(); 
		workOrderRecords = [SELECT Id, Work_Order_Type__c, Sold_Order__c from RbA_Work_Order__c where Id IN: workOrders];
		//dlrs.RollupService.rollup(orderRecords);
        orderRecords =  dlrs.RollupService.rollup(workOrderRecords);
        update orderRecords;
    }
}
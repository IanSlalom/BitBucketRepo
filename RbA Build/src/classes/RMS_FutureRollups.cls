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
    @future
    public static void rollupOrderItemsToOrders(Set<Id> orderItems)
    {  
        List<sObject> orderRecords = new List<Order>(); 
        List<OrderItem> orderItemRecords = new List<OrderItem>(); 
        orderItemRecords = [SELECT Id, OrderId, Status__c, Product_Family__c, Product_Type__c, Quantity, Total_Retail_Price__c, Total_Wholesale_Cost__c, Purchase_Order__c from OrderItem where Id IN: orderItems];
        orderRecords =  dlrs.RollupService.rollup(orderItemRecords);
        update orderRecords;
    }
    
    @future
    public static void rollupChangeHistoriesToOrders(set<Id> changeHistories)
    {
        List<Order> orderRecords = new List<Order>();
        List<Change_History__c> changeHistoryRecords = new List<Change_History__c>();
        changeHistoryRecords = [SELECT Id, Order__c, Retail_Price_Change__c, Report_Type__c, Order_Discount__c FROM Change_History__c where Id IN: changeHistories];
        orderRecords = dlrs.RollupService.rollup(changeHistoryRecords);
        update orderRecords;
    }
}
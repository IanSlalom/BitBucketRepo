public class RMS_ServiceProductPickup {
    
    public void customerPickup(List<Order> listOld, List<Order> listNew, Map<Id, Order> mapOld, Map<Id, Order> mapNew){
        
        List<OrderItem> childRecords = [Select Id, OrderId, Quote_Accepted__c, Customer_Pickup__c 
                                                FROM OrderItem WHERE Quote_Accepted__c = TRUE AND OrderId IN: Trigger.newMap.keySet()];
        
        Map<Id,OrderItem> orderMap = new Map<Id,OrderItem>([select Id,Order.Customer_Pickup_All__c from OrderItem where id in:childRecords]);
        
        for(OrderItem child :childRecords){
            if(!orderMap.IsEmpty()){   
                if(mapNew.get(child.OrderId).Customer_Pickup_All__c == TRUE && mapNew.get(child.OrderId).Customer_Pickup_All__c != mapOld.get(child.OrderId).Customer_Pickup_All__c){
                    child.Customer_Pickup__c = 'Yes';                    
                }
            }
        }
        
        if(childRecords.size() > 0){
            update childRecords;
        }                    
    }

}
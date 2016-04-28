public with sharing class RMS_setBilltoContact {
    
    public void setBilltoContact(List<Order> listOld, List<Order> listNew, Map<Id, Order> mapOld, Map<Id, Order> mapNew){
        
        List<Id> soldOrders = new List<Id>();
        Id serviceRT = UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order');
        
        
        for(Order o : listNew){
            If(o.RecordTypeId == serviceRT){
                soldOrders.add(o.Sold_Order__c); 
            }   
        }
        
        Map<Id,Order> orderMap = new Map<Id,Order>([select BilltoContactId from Order where id in:soldOrders]);
        
        for(Order ord: listNew){
            if(!orderMap.IsEmpty()){   
                If(ord.Sold_Order__c != null && mapOld.get(ord.Id).Sold_Order__c != ord.Sold_Order__c){
                    ord.BilltoContactId = orderMap.get(ord.Sold_Order__c).BilltoContactId;
                }    
                
                
            }
        }
        
    }
}
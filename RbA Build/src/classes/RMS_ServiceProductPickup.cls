/*******************************************************//**

@class  RMS_ServiceProductPickup

@brief  Service Requests have Service Products (Orders and OrderItems)
A checkbox exists on the Service Request, Customer Pickup - All, which indicates
that the Customer will pick up all Service Products. On the Service Product there is
a Yes/No Picklist for Customer Pickup. Should the Service Request be marked
as Customer Pickup - All as true, all Service Products with the quote accepted will have
Customer Pickup picklist set to Yes.

@author  Brianne Wilson (Slalom.BLW)

@version    2016-5-10  Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/

public class RMS_ServiceProductPickup {
    
    public void customerPickup(List<Order> listOld, List<Order> listNew, Map<Id, Order> mapOld, Map<Id, Order> mapNew){
        
		// First check if any order's customer pickup all has turned on
		Set<Id> orderIdsChangedPickup = new Set<Id>();
		for(Order o: listNew){
			if(mapNew.get(o.Id).Customer_Pickup_All__c == TRUE && mapNew.get(o.Id).Customer_Pickup_All__c != mapOld.get(o.Id).Customer_Pickup_All__c){
				orderIdsChangedPickup.add(o.Id);
			}
		}
		
		// If no order's customer pickup has turned on, just return
		if (orderIdsChangedPickup.size() == 0) return;

        List<OrderItem> childRecords = [Select Id, OrderId, Quote_Accepted__c, Customer_Pickup__c,Order.Customer_Pickup_All__c 
                                                FROM OrderItem WHERE Quote_Accepted__c = TRUE AND OrderId IN: orderIdsChangedPickup];
        
        Map<Id,OrderItem> orderMap = new Map<Id,OrderItem>([select Id from OrderItem where id in:childRecords]);
        
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
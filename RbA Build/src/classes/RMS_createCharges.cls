public with sharing class RMS_createCharges {
    
    
    public void createCharge(List<OrderItem> listNew, Map<Id, OrderItem> mapNew){
        
        List<Charge__c> newCharge = new list<Charge__c>();        
        
        for(OrderItem oi : listNew){ 
            if(oi.Manufacturer_Replace__c){
                Charge__c ch = new Charge__c(
                    Charge_Cost_To__c = 'Manufacturing',
                    Service_Product__c = oi.Id,
                    Service_Request__c = oi.OrderId,
                    Validate_Service_Order__c = True);
                
                newCharge.add(ch);
            }
            
            if(oi.Local_Remake__c){
                Charge__c ch = new Charge__c(
                    Charge_Cost_To__c = 'Retailer',
                    Service_Product__c = oi.Id,
                    Service_Request__c = oi.OrderId,
                    Validate_Service_Order__c = True);
                
                newCharge.add(ch);
            }
            
            if(oi.Customer_Replace__c){
                Charge__c ch = new Charge__c(
                    Charge_Cost_To__c = 'Customer',
                    Service_Product__c = oi.Id,
                    Service_Request__c = oi.OrderId,
                    Validate_Service_Order__c = True);
                
                newCharge.add(ch);
            }
        }
        insert newCharge;
        
    }
    
}
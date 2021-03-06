/*******************************************************//**

@class  RMS_viewOrderProductsController

@brief  Controller for RMS_ViewOrderProduct visualforce page

@author  Kai Ruan (Slalom.CDK)

@version    2016-2-18  Slalom.CDK
    Created.

@copyright  (c)2016 Slalom.  All Rights Reserved. 
            Unauthorized use is prohibited.

***********************************************************/
public with sharing class RMS_viewOrderProductsController {

    public final Order ord;
    public Map<Id,OrderItem> orderItems {get;set;}
    public List<OrderItemWrapper> orderItemWrappers{get;set;}
    public Id masterProductId {get;set;}
    public Id miscJobId {get;set;}
    public Id constrMatId {get;set;}
    public Id servProd {get;set;}
    public Id serviceOrderId {get;set;} 
    public Id changeOrderId {get;set;}
    public Id coroOrderId {get;set;}
    public boolean changeOrder {get;set;}
    public String baseURL{get;set;}
    public String addProductURL{get;set;}
    public String editOrderItem{get;set;}
    public Id orderItemToToggle{get;set;}
    public Id orderItemToCancel{get;set;}
  

    public RMS_viewOrderProductsController(ApexPages.StandardController stdController) {
        if(!test.isRunningTest()){
            stdController.addFields(new List<String>{'PriceBook2Id','RecordTypeId'});
        }
        this.ord = (Order)stdController.getRecord();
		changeOrder = (this.ord.RecordTypeId == UtilityMethods.RecordTypeFor('Order', 'Change_Order')) ? true : false;
        masterProductId = UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Master_Product');
        miscJobId =UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Misc_Job_and_Unit_Charges');
		constrMatId = UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Construction_Materials');
        servProd =UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Service_Product');    
        serviceOrderId = UtilityMethods.GetRecordTypeIdsMapForSObject(Order.sObjectType).get('CORO_Service');
        changeOrderId = UtilityMethods.GetRecordTypeIdsMapForSObject(Order.sObjectType).get('Change_Order');
        coroOrderId = UtilityMethods.GetRecordTypeIdsMapForSObject(Order.sObjectType).get('CORO_Record_Type');

        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

        loadOrderItems();

        if(ord.RecordTypeId == serviceOrderId){
            addProductURL = '/apex/RMS_addServiceProduct?id=' + ord.Id;
        }else{
            addProductURL = '/apex/rms_ProdConfigEdit?oid='+ord.Id+'&pid='+ord.Pricebook2Id +'&mode=e';
        }
                
        

    }

    public void loadOrderItems(){
        orderItems =  new Map<Id,OrderItem>([select Id, PricebookEntry.Product2Id, PricebookEntry.Product2.Name, Purchase_Order__c, Quantity, Total_Retail_Price__c, 
                         Unit_Wholesale_Cost__c, Total_Wholesale_Cost__c, Variant_Number__c, UnitPrice, Unit_Id__c,PricebookEntry.Product2.RecordTypeId, Status__c,
                         Purchase_Order__r.Status__c, Color_Match_Hinges__c, Corrosion_Resistant_Hinges__c, Corrosion_Resistant_Lock__c, Hardware_Finish_Color__c, Window_Opening_Control_Device__c,
                         Is_Height_L_or_R_Leg_Height__c, Is_Leg_Height_L_or_R_Leg_Height__c, Leg_Height_Exterior_Fraction__c, Leg_Height_Exterior_Whole_Inch__c,Leg_Height_Interior_Fraction__c, 
                         Leg_Height_Interior_Whole_Inch__c, Meet_Rail_Dimension__c, EJ_Kerf__c, Cancellation_Reason__c
                         from OrderItem 
                         where OrderId =: ord.Id 
                            and (Parent_Order_Item__c = null) 
                            and (PricebookEntry.Product2.RecordTypeId != : constrMatId)
                            order by PricebookEntry.Product2.RecordType.DeveloperName]);

        Map<Id,List<OrderItem>> relatedOrderItems = new Map<Id,List<OrderItem>>();
        for(OrderItem oi: [select Id, PricebookEntry.Product2Id,  PricebookEntry.Product2.Name, Purchase_Order__c, Quantity, Total_Retail_Price__c, 
                         Unit_Wholesale_Cost__c, Total_Wholesale_Cost__c, Variant_Number__c, UnitPrice, Parent_Order_Item__c, Service__c, Unit_Id__c, Status__c,
                         Purchase_Order__r.Status__c, Color_Match_Hinges__c, Corrosion_Resistant_Hinges__c, Corrosion_Resistant_Lock__c, Hardware_Finish_Color__c, Window_Opening_Control_Device__c,
                         Is_Height_L_or_R_Leg_Height__c, Is_Leg_Height_L_or_R_Leg_Height__c, Leg_Height_Exterior_Fraction__c, Leg_Height_Exterior_Whole_Inch__c,Leg_Height_Interior_Fraction__c, 
                         Leg_Height_Interior_Whole_Inch__c, Meet_Rail_Dimension__c, EJ_Kerf__c, Cancellation_Reason__c
                         from OrderItem 
                         where OrderId =: ord.Id
                         and Parent_Order_Item__c in: orderItems.keySet() 
                         and (PricebookEntry.Product2.RecordTypeId != : constrMatId)
                         and Parent_Order_Item__c != null
                         order by PriceBookEntry.Product2.Name]){
            system.debug(oi);
            if(relatedOrderItems.containsKey(oi.Parent_Order_Item__c)){
                relatedOrderItems.get(oi.Parent_Order_Item__c).add(oi);
            }else{
                relatedOrderItems.put(oi.Parent_Order_Item__c,new List<OrderItem>{oi});
            }
        }
        system.debug(relatedOrderItems);
        orderItemWrappers = new List<OrderItemWrapper>();
        for(OrderItem oi: orderItems.values()){
            orderItemWrappers.add(new OrderItemWrapper(oi,relatedOrderItems.get(oi.Id)));
            
            if(oi.Service__c = true){
                editOrderItem = '/apex/RMS_editServiceProduct?id=' + oi.Id;
            }else{
                editOrderItem = '/apex/rms_ProdConfigEdit?oid='+ord.Id+'&pid='+ord.Pricebook2Id +'&mode=e';
            }
        }
        
        system.debug(orderItemWrappers);
    }

    public void toggleShowRelatedItems(){
        for(OrderItemWrapper wrapper: orderItemWrappers){
            if(wrapper.orderItem.Id == orderItemToToggle){
                wrapper.showRelatedItems = !wrapper.showRelatedItems;
                break;
            }
        }
    }
    public class OrderItemWrapper{
        public OrderItem orderItem{get;set;}
        public List<OrderItem> relatedItems{get;set;}
        public Boolean showRelatedItems{get;set;}

        public OrderItemWrapper(OrderItem oi, List<OrderItem> relatedOI){
            orderItem = oi;
            relatedItems = relatedOI;
            showRelatedItems = false;
        }
    }

    public pageReference cancelOrderItem(){
        /*System.debug('OI to CANCEL' + orderItemToCancel);
        OrderItem o = [Select Id, Status__c from OrderItem where Id =: orderItemToCancel];
        o.Status__c = 'Cancelled';
        update o;
        loadOrderItems();*/
        return new PageReference('/apex/RMS_CancelOrderLine?id='+orderItemToCancel);
    }
    
}
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

    public final Order order;
    public Map<Id,OrderItem> orderItems {get;set;}
    public Map<Id,List<OrderItem>> relatedOrderItems{get;set;} 
    public List<OrderItemWrapper> orderItemWrappers{get;set;}
    public Id masterProductId = UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Master_Product');
    public Id miscJobId = UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Misc_Job_and_Unit_Charges');
    public String baseURL{get;set;}
    public String reportURL{get;set;}
    public String addProductURL{get;set;}
    public Id orderItemToToggle{get;set;}

    public RMS_viewOrderProductsController(ApexPages.StandardController stdController) {
        if(!test.isRunningTest()){
            stdController.addFields(new List<String>{'PriceBook2Id'});
        }
        this.order = (Order)stdController.getRecord();

        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        orderItems =  new Map<Id,OrderItem>([select Id, PricebookEntry.Product2Id, PricebookEntry.Product2.Name, Purchase_Order__c, Quantity, Total_Retail_Price__c, 
                         Unit_Wholesale_Cost__c, Total_Wholesale_Cost__c, Variant_Number__c, UnitPrice 
                         from OrderItem 
                         where OrderId =: order.Id 
                         and PricebookEntry.Product2.RecordTypeId =: masterProductId]);

        relatedOrderItems = new Map<Id,List<OrderItem>>();
        for(OrderItem oi: [select Id, PricebookEntry.Product2Id,  PricebookEntry.Product2.Name, Purchase_Order__c, Quantity, Total_Retail_Price__c, 
                         Unit_Wholesale_Cost__c, Total_Wholesale_Cost__c, Variant_Number__c, UnitPrice, Parent_Order_Item__c 
                         from OrderItem 
                         where Parent_Order_Item__c in: orderItems.keySet() 
                         and PricebookEntry.Product2.RecordTypeId =: miscJobId
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
        }
        system.debug(orderItemWrappers);
        List<Report> installMatReport = [select Id from Report where DeveloperName = 'Install_Materials_Summary2' limit 1];
        String reportId = '';
        if(installMatReport.size()>0){
            reportId = installMatReport[0].Id;
        }
        reportURL = '/'+reportId+'?pv0='+String.ValueOf(order.Id).substring(0,15)+'&pv1=Construction_Materials';
        addProductURL = '/apex/rms_ProdConfigEdit2?oid='+order.Id+'&pid='+order.Pricebook2Id;

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

    
}
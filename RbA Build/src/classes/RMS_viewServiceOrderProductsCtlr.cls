/*******************************************************//**

@class  RMS_viewServiceOrderProductsCtlr

@brief  Controller for RMS_viewServiceOrderProducts visualforce page
which is embedded in the View Service Request page.

@author  Brianne Wilson (Slalom.CDK)

@version    2016-2-18  Slalom.CDK
Created.

@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
public with sharing class RMS_viewServiceOrderProductsCtlr {
    
    public final Order ord;
    public Map<Id,OrderItem> orderItems {get;set;}
    public List<OrderItemWrapper> orderItemWrappers{get;set;}
    public Id masterProductId = UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Master_Product');    
    public Id servProd = UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Service_Product');    
    public Id serviceOrderId = UtilityMethods.GetRecordTypeIdsMapForSObject(Order.sObjectType).get('CORO_Service');
    public String baseURL{get;set;}
    public String addProductURL{get;set;}
    public String editOIURL{get;set;}
    public Id orderItemToToggle{get;set;}
    public integer num_assets;
    public String orderURL{get;set;}
    public String accountURL{get;set;}
    
    public RMS_viewServiceOrderProductsCtlr(ApexPages.StandardController stdController) {
        /*if(!test.isRunningTest()){
stdController.addFields(new List<String>{'PriceBook2Id','RecordTypeId'});
}*/
        this.ord = (Order)stdController.getRecord();
        
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        orderURL = '/'+'{!ord.Id}';
            accountURL = '/'+'{!ord.AccountId}';
        
                orderItems =  new Map<Id,OrderItem>([select Id, PricebookEntry.Product2Id, PricebookEntry.Product2.Name, Purchase_Order__c, 
                                             Variant_Number__c,
                    //                         Quanity_Ordered__c, MTO_Source_Code__c, Sold_Order_Product_Asset__r.Name, Defect_Code__c, Installed_Product_Asset__c, Installed_Product_Asset__r.Name 
                                             Quanity_Ordered__c, Sold_Order_Product_Asset__r.Name, Installed_Product_Asset__c, Installed_Product_Asset__r.Name 
                                             from OrderItem 
                                             where OrderId =: ord.Id 
                                             and PricebookEntry.Product2.RecordTypeId =: servProd
                                             ORDER BY Sold_Order_Product_Asset__r.Name , PricebookEntry.Product2.Name]);
        
        orderItemWrappers = new List<OrderItemWrapper>();
        for(OrderItem oi: orderItems.values()){
            orderItemWrappers.add(new OrderItemWrapper(oi));
        }
        system.debug(orderItemWrappers);
        
        List<AggregateResult> results2=[select COUNT (Id) 
                                        FROM Asset 
                                        WHERE AccountId = :ord.AccountId];
        num_assets = (Integer) results2[0].get('expr0');
        
        system.debug(orderItemWrappers);  
        
        
        if(ord.RecordTypeId == serviceOrderId){
            if(num_assets > 0){
                addProductURL = '/apex/RMS_addServiceProduct?id=' + ord.Id;                
            } else {
                addProductURL = '/apex/RMS_addServiceProductLegacy?id=' + ord.Id;                  
            }
            
        }else{
            addProductURL = '/apex/rms_ProdConfigEdit?oid='+ord.Id+'&pid='+ord.Pricebook2Id +'&mode=e';
        }
        
        
    }
    
    
    public class OrderItemWrapper{
        public OrderItem orderItem{get;set;}
        
        
        public OrderItemWrapper(OrderItem oi){
            orderItem = oi;
            
        }
    }
    
    public PageReference addProductPage(){
        PageReference newPage;
        
        if(ord.RecordTypeId == serviceOrderId){
            if(num_assets > 0){
                newPage = new PageReference('/apex/RMS_addServiceProduct?id=' + ord.Id);                
            } else {
                newPage = new PageReference('/apex/RMS_addServiceProductLegacy?id=' + ord.Id);                  
            }
            
        }else{
            newPage = new PageReference('/apex/rms_ProdConfigEdit?oid='+ord.Id+'&pid='+ord.Pricebook2Id +'&mode=e');
        }
        newPage.setRedirect(true); 
        return newPage;
    }
    
    
}
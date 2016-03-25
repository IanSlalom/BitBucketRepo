/*******************************************************//**

@class  RMS_viewOrdersController

@brief  Controller for RMS_viewCOROOrders and RMS_viewServiceOrders visualforce page

@author  Kai Ruan (Slalom)

@version    2016-3-11  Slalom
Created.

@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
public with sharing class RMS_viewOrdersController {
    
    
    public String strurl;
    public String baseUrl{get;set;}
    public String createServiceRequestURL{get;set;}
    
    public Id serviceRecordTypeId{get;set;}
    public Id CORORecordTypeId{get;set;}
    public List<Order> orders{get;set;}
    
    /******* Set up Standard Controller for Purchase_Order__c  *****************/
    private Apexpages.StandardController standardController;
    private final Account acc;
    
    
    //Constructor
    public RMS_viewOrdersController(ApexPages.StandardController stdController) {
        if(!test.isRunningTest()){
            stdController.addFields(new List<String>{'Store_Location__c'});
        }
        this.acc = (Account)stdController.getRecord();
        
        strurl = ApexPages.currentPage().getUrl();
        strurl = strurl.split('apex/')[1];
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        
        
        serviceRecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order');
        CORORecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Record_Type', 'Order');
        
        Id recordTypeId = null;
        System.debug(strurl);
        System.debug(serviceRecordTypeId);
        if(strurl.Contains('viewService')){
            recordTypeId = serviceRecordTypeId;
        }else {
            recordTypeId = CORORecordTypeId;			
        }
        
        orders = [SELECT 	Name,
                  OrderNumber,
                  Status,
                  EffectiveDate,
                  Contract.Name,
                  ContractId,
                  TotalAmount,
                  RecordType.Name,
                  Sold_Order__c,
                  Description,
                  Service_Type__c,
                  Sold_Order__r.OrderNumber
                  FROM 	Order
                  WHERE 	RecordTypeId =: recordTypeId
                  AND 	AccountId =: acc.Id];	 
        
        system.debug(orders);
        createServiceRequestURL = '/apex/RMS_createServiceRequestRedirect?isdtp=vw&aid='+acc.Id+'&slid='+acc.Store_Location__c; 
        
    }
    
}
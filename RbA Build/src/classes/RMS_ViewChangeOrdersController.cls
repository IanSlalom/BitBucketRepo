/*******************************************************//**

@class  RMS_ViewChangeOrdersController

@brief  Controller for RMS_viewChangeOrders visualforce page

@author  Kai Ruan (Slalom)

@version    2016-8-16  Slalom
Created.

@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
public with sharing class RMS_ViewChangeOrdersController {
    
    public String strurl;
    public String baseUrl{get;set;}
    public Id ChangeOrderRecordTypeId{get;set;}
    public List<Order> orders{get;set;}
    public Order ord{get;set;}
    
    /******* Set up Standard Controller for Order  *****************/
    private Apexpages.StandardController standardController;
    
    
    //Constructor
    public RMS_ViewChangeOrdersController(ApexPages.StandardController stdController) {
        this.ord = (Order)stdController.getRecord();
       
        strurl = ApexPages.currentPage().getUrl();
        strurl = strurl.split('apex/')[1];
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        ChangeOrderRecordTypeId = UtilityMethods.retrieveRecordTypeId('Change_Order', 'Order');
        orders = [SELECT 	Name,
                  OrderNumber,
                  Retail_Total__c,
                  CreatedDate
                  FROM 	Order
                  WHERE 	RecordTypeId =: ChangeOrderRecordTypeId
                  AND 	Sold_Order__c =: ord.Id];	 
        
        
    }
    
}
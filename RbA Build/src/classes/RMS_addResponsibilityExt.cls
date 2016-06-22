/*******************************************************//**

@class  RMS_addResponsibilityExt


@author  Brianne Wilson (Slalom.BLW)

@brief 1 of 2 classes used to add Warranties

@version    2016-06-06 Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/

public with sharing class RMS_addResponsibilityExt extends RMS_addCharges
{
    
    
    public OrderItem myWO {get; private set;}
    
    public RMS_addResponsibilityExt(ApexPages.StandardController stdController) 
    {
        super(stdController);
        
        
        this.myWO = [SELECT Id,OrderId, PricebookEntryId, PricebookEntry.Product2Id                    
                     FROM OrderItem
                     WHERE Id =: stdController.getRecord().Id];
        
        this.childList = [SELECT Id,
                          Service_Product__c,
                          Service_Product__r.Product_Name__c,
                          Service_Request__c,                          
                          Charge_Cost_To__c,
                          Primary_Reason__c,
                          Secondary_Reason__c,
                          Installed_Product__c
                          FROM Charge__c
                          WHERE Service_Product__c =: mysObject.Id];
    }

    
    
    /*
* This method is necessary for reference on the Visualforce page, 
* in order to reference non-standard fields.
*/
    public List<Charge__c> getChildren()
    {
        return (List<Charge__c>)childList;
    }
    
    public override sObject initChildRecord()
    {
        Charge__c child = new Charge__c();
        child.Service_Product__c = myWO.Id; 
        child.Service_Request__c = myWo.OrderId;                           
        
        return child;
    }
    
}
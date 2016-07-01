/*******************************************************//**

@class  RMS_addWarrantiesExt


@author  Brianne Wilson (Slalom.BLW)

@brief 1 of 2 classes used to add Warranties

@version    2016-06-06 Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/

public with sharing class RMS_addWarrantiesExt extends RMS_addWarranties
{
    
    
    public OrderItem myWO {get; private set;}
    
    public RMS_addWarrantiesExt(ApexPages.StandardController stdController) 
    {
        super(stdController);
        
        
        this.myWO = [SELECT Id, OrderId, PricebookEntryId, PricebookEntry.Product2Id                      
                     FROM OrderItem
                     WHERE Id =: stdController.getRecord().Id];
        
        this.childList = [SELECT Id,
                          Service_Product__c,
                          Service_Request__c,
                          Procedure_Code__c,
                          Charge_Cost_To__c,
                          Quantity__c                                                
                          FROM Warranty__c
                          WHERE Service_Product__c =: mysObject.Id];
    }
    
    public List<selectOption> getProcs() {
        List<selectOption> options = new List<selectOption>(); //new list for holding all of the picklist options        
        
        List<Id> ssIds = new List<Id>();
        for(Service_Symptom__c symptoms : [SELECT Id, Service_Symptom__c, Service_Product__c
                                          FROM Service_Symptom__c
                                           WHERE Service_Product__c = :myWO.Id]){
                                               ssIds.add(symptoms.Service_Symptom__c);
                                           }
        
        List<Id> ssAssign = new List<Id>();
        for (Service_Symptom_Assignment__c assignments : [Select Id, Service_Symptom__c, Procedure_Code__c
                                                         FROM Service_Symptom_Assignment__c
                                                          WHERE Service_Symptom__c =: ssIds]){
                                                              ssAssign.add(assignments.Procedure_Code__c);
                                                          }
        
        for (Procedure_Code_Assignment__c procedures : [SELECT Id, Name, Service_Product__c, Procedure_Code__c
                                                        FROM Procedure_Code_Assignment__c 
                                                        WHERE Service_Product__c = :myWo.PricebookEntry.Product2Id 
                                                        AND Procedure_Code__c = : ssAssign
                                                        ORDER BY Procedure_Code_Assignment__c.Name ASC]) { 
                                                            options.add(new selectOption(procedures.Id, procedures.Name)); //for all records found - add them to the picklist options
                                                        }
        options.add(new selectOption('', '-- None --')); //add the first option of '- None -' in case the user doesn't want to select a value or in case no values are returned from query below
        return options; //return the picklist options        
    } 
    
        public List<selectOption> getCharges() {
        List<selectOption> options = new List<selectOption>(); //new list for holding all of the picklist options        
        for (Charge__c charges : [SELECT Id, Name, Charge_Cost_To__c,Category__c
                                                        FROM Charge__c 
                                                        WHERE Service_Product__c = :myWo.Id
                                  						AND What_Where__c = 'Renewal by Andersen'
                                                        ORDER BY Charge__c.Charge_Cost_To__c ASC]) { 
                                                            options.add(new selectOption(charges.Id, charges.Charge_Cost_To__c + ' - '+ charges.Category__c)); //for all records found - add them to the picklist options
                                                        }
        options.add(new selectOption('', '-- None --')); //add the first option of '- None -' in case the user doesn't want to select a value or in case no values are returned from query below
        return options; //return the picklist options        
    } 
    
    
    /*
* This method is necessary for reference on the Visualforce page, 
* in order to reference non-standard fields.
*/
    public List<Warranty__c> getChildren()
    {
        return (List<Warranty__c>)childList;
    }
    
    public override sObject initChildRecord()
    {
        Warranty__c child = new Warranty__c();
        child.Service_Product__c = myWO.Id; 
        child.Service_Request__c = myWo.OrderId;                          
        
        return child;
    }
    
}
/*******************************************************//**

@class  RMS_editableTaskListExt


@author  Brianne Wilson (Slalom.BLW)

@brief 1 of 2 classes used on the RMS_addMultipleTaskstoWO page
for creating a dynamic page where user may add multiple records
on a single page. Class used to create records and add/delete
rows on the single page, each representing a new record.

@version    2016-05-11 Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/

public with sharing class RMS_editableTaskListExt extends RMS_editableTaskList
{
    
    
    public RbA_Work_Order__c myWO {get; private set;}
    
    public RMS_editableTaskListExt(ApexPages.StandardController stdController) 
    {
        super(stdController);
        
        
        this.myWO = [SELECT Id, Service_Material_Owner_Id__c                             
                     FROM RbA_Work_Order__c
                     WHERE Id =: stdController.getRecord().Id];
        
        this.childList = [SELECT Id,
                          WhatId,
                          Assigned_To__c,
                          Service_Type__c,
                          Subject,
                          Status,
                          OwnerId                          
                          FROM Task
                          WHERE WhatId =: mysObject.Id
                          AND Status = 'Open'];
    }
    
    /*
* This method is necessary for reference on the Visualforce page, 
* in order to reference non-standard fields.
*/
    public List<Task> getChildren()
    {
        return (List<Task>)childList;
    }
    
    public override sObject initChildRecord()
    {
        Task child = new Task();
        child.WhatId = myWO.Id; 
        child.Status = 'Open';                  
        child.Service_Material_Owner_Id__c = myWo.Service_Material_Owner_Id__c;
        
        return child;
    }
    
}
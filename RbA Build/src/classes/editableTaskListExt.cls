public with sharing class editableTaskListExt extends editableTaskList
{


 public RbA_Work_Order__c myWO {get; private set;}

  public editableTaskListExt(ApexPages.StandardController stdController) 
  {
    super(stdController);


    this.myWO = [SELECT Id                            
                            FROM RbA_Work_Order__c
                            WHERE Id =: stdController.getRecord().Id];
    
    this.childList = [SELECT Id,
                          WhatId,
                          Service_Type__c,
                          Subject,
                          Status,
                          OwnerId,
                          Non_Stock_Material__c                          
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
    // Can either use mysObject or acct here
    child.WhatId = mysObject.Id; 
    child.Status = 'Open';        
    
    return child;
  }
    
}
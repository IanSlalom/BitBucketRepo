public with sharing class RMS_addProblemComponentsExt extends RMS_addProblemComponents{
    
    
    public Service_Symptom__c myWO {get; private set;}
    
    public RMS_addProblemComponentsExt (ApexPages.StandardController stdController) {        
        super(stdController);        
        
        this.myWO = [SELECT Id, Service_Product__c,Service_Symptom__c               
                     FROM Service_Symptom__c
                     WHERE Id =: stdController.getRecord().Id];
        
        this.childList = [SELECT Id,
                          Problem_Component_asgn__c,
                          Service_Symptom__c,
                          Service_Product_lkup__c ,
                          Service_Symptom_Validation__c                                 
                          FROM Problem_Component__c
                          WHERE Service_Symptom__c =: mysObject.Id];
                
        
    }
    
    public List<selectOption> getSers() {
        List<selectOption> options = new List<selectOption>(); //new list for holding all of the picklist options        
        options.add(new selectOption('', '-- SELECT --'));
        for (Service_Symptom_List__c servs : [SELECT Id,Name 
                                              FROM Service_Symptom_List__c 
                                              WHERE Name != null
                                              ORDER BY Service_Symptom_List__c.Name ASC]) { 
                                                  options.add(new selectOption(servs.Id, servs.Name)); //for all records found - add them to the picklist options
                                              } //add the first option of '- None -' in case the user doesn't want to select a value or in case no values are returned from query below        
        return options; //return the picklist options        
    }
    
    
    
    public List<Problem_Component__c> getChildren()
    {
        return (List<Problem_Component__c>)childList;
    }
    
    public override sObject initChildRecord()
    {     
        Problem_Component__c child = new Problem_Component__c();
        child.Service_Product_lkup__c  = myWO.Service_Product__c; 
        child.Service_Symptom_Validation__c = myWo.Service_Symptom__c;
        child.Service_Symptom__c = myWo.Id;
        
        return child;
    }
    
    //view problem components as picklist
    public List<selectOption> getProbs() {
        List<selectOption> options = new List<selectOption>(); //new list for holding all of the picklist options        
        options.add(new selectOption('', '-- None --')); //add the first option of '- None -' in case the user doesn't want to select a value or in case no values are returned from query below
        for (Problem_Component_Config__c  probs : [SELECT Id, Name, Problem_Component__c, Service_Symptom__c  
                                                   FROM Problem_Component_Config__c
                                                   WHERE Service_Symptom__c = :myWO.Service_Symptom__c  
                                                   ORDER BY Name ASC]) { 
                                                       options.add(new selectOption(probs.Id, probs.Name));
                                                   }        
        return options; //return the picklist options        
    } 
    
}
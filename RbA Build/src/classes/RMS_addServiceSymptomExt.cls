public with sharing class RMS_addServiceSymptomExt {
    
    public final Service_Symptom__c s;
    
    public RMS_addServiceSymptomExt (ApexPages.StandardController stdController) {
        this.s = (Service_Symptom__c)stdController.getRecord();            
        
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
    
    public String ssSP { get; set; }{
        ssSP = apexpages.currentpage().getparameters().get('ssSP');
        if ( ssSP == null ) ssSP = '';
    }
    public PageReference saveRerender(){
        //deletes the order and redirects to delete confirmation page        
        s.Service_Product__c = ssSp;
        insert s;
        
        PageReference reRender = new PageReference('/apex/RMS_addServiceSymptomP2?id='+ s.Id + '&retUrl=' + s.Service_Product__c);
        reRender.setRedirect(true);
        return reRender;
        
    }
    
    
    
    
}
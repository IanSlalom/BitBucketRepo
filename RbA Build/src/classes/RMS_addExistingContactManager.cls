public with sharing class RMS_addExistingContactManager {
    
    public final Contact_History__c c;
    Id customerContactRecordType = UtilityMethods.retrieveRecordTypeId('Customer_Contacts', 'Contact');
    
    public RMS_addExistingContactManager(ApexPages.StandardController stdController) {
        this.c = (Contact_History__c)stdController.getRecord();                      
    }
    
    public String aid { get; set; }{
        
        aid = apexpages.currentpage().getparameters().get('aid');       
        
        if ( aid == null ) aid = '';
    }
    
    
    public String pc { get; set; }{
        
        aid = apexpages.currentpage().getparameters().get('aid');
        List <Contact_History__c> ch = [SELECT Full_Name__c FROM Contact_History__c WHERE Dwelling__c=: aid AND Primary_Contact__c = TRUE LIMIT 1];
        
        if(ch.isEmpty()){
            pc = '';
            
        } else {
            Contact_History__c cpc = ch[0];
            pc = cpc.Full_Name__c;
        }
        
    }
    
    public String aname { get; set; }{
        aname = apexpages.currentpage().getparameters().get('aname');
        if ( aname == null ) aname = '';
    }
    
    public PageReference saveCH(){
        try{
            c.Dwelling__c = aid;
            upsert c;
                           
            PageReference newPage;
            
            If (c.Type__c == 'Current Resident'){
                newPage = new PageReference('/apex/RMS_addExistingContactUpdateDwelling?id='+ c.Id);
            } else {
                newPage = new PageReference('/'+aid);
            }
            
            newPage.setRedirect(true);
            return newPage;
        } catch(DMLException saveEx){
            ApexPages.addMessages(saveEx);
            PageReference newPage = new PageReference('/apex/RMS_addExistingContactUpdateDwelling?id='+ c.Id);
            newPage.setRedirect(false);
            return newPage;
        }
        
    }
    
    public PageReference saveCH2(){
        try{
            upsert c;
            PageReference newPage;
            newPage = new PageReference('/'+c.Dwelling__c);
            newPage.setRedirect(true);
            return newPage;
        } catch(DMLException saveEx){
            ApexPages.addMessages(saveEx);
            PageReference newPage = new PageReference('/'+c.Dwelling__c);
            newPage.setRedirect(false);
            return newPage;
        }
        
    }
                  

    
}
/*******************************************************//**


@author  Brianne Wilson (Slalom.BLW)

@version    2016-6-2  Slalom.BLW
    Created.

@copyright  (c)2016 Slalom.  All Rights Reserved. 
            Unauthorized use is prohibited.

***********************************************************/
public with sharing class RMS_viewPCCtrlr {
	    
    public final Procedure_Code__c p;
    public String baseURL{get;set;}
    map<String, Service_Field_Ids__c> Service_Field_Ids_map = Service_Field_Ids__c.getAll();
    public String ssPC = Service_Field_Ids_map.get('Service Symptom - Procedure Code').Value__c;
    public String ssSP = Service_Field_Ids_map.get('Procedure Code - Procedure Code').Value__c;

    public RMS_viewPCCtrlr(ApexPages.StandardController stdController) {
        if(!test.isRunningTest()){
            stdController.addFields(new List<String>{'Name'});
        }
        this.p = (Procedure_Code__c)stdController.getRecord();                

        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        
    }
    
    public PageReference addServiceProduct(){
        Schema.DescribeSObjectResult pc = Procedure_Code_Assignment__c.sObjectType.getDescribe();
        String procCodePrefix = pc.getKeyPrefix();  
        
        PageReference newPage;
        newPage = new PageReference('/'+procCodePrefix+'/e?'+ssSP+'='+p.Name+'&'+ssSP+'_lkid='+p.id+'&Name='+p.name);
        newPage.setRedirect(true); 
        return newPage;
    } 

    public PageReference addServiceSymptom(){
        Schema.DescribeSObjectResult ss = Service_Symptom_Assignment__c.sObjectType.getDescribe();
        String servSympPrefix = ss.getKeyPrefix();
        
        PageReference newPage;
        newPage = new PageReference('/'+servSympPrefix+'/e?'+ssPC+'='+p.Name+'&'+ssPC+'_lkid='+p.id+'&Name=Enter Symptom Here');
        newPage.setRedirect(true); 
        return newPage;
    }     


    
}
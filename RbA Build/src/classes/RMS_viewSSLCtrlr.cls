/*******************************************************//**


@author  Brianne Wilson (Slalom.BLW)

@version    2016-6-2  Slalom.BLW
Created.

@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
public with sharing class RMS_viewSSLCtrlr {
    
    public final Service_Symptom_List__c p;
    public String baseURL{get;set;}
    public String addProcedureCodeURL{get;set;}
    public String addProblemComponentURL{get;set;}
    map<String, Service_Field_Ids__c> Service_Field_Ids_map = Service_Field_Ids__c.getAll();
    public String ssPC = Service_Field_Ids_map.get('Service Symptom - Procedure Code').Value__c;
    public String pcSS = Service_Field_Ids_map.get('Problem Component - Service Symptom').Value__c;
    
    
    
    public RMS_viewSSLCtrlr(ApexPages.StandardController stdController) {
        if(!test.isRunningTest()){
            stdController.addFields(new List<String>{'Name'});
        }
        this.p = (Service_Symptom_List__c)stdController.getRecord();
        
        Schema.DescribeSObjectResult prc = Problem_Component_Config__c.sObjectType.getDescribe();
        String probCompPrefix = prc.getKeyPrefix(); 
        
        Schema.DescribeSObjectResult ss = Service_Symptom_Assignment__c.sObjectType.getDescribe();
        String servSympPrefix = ss.getKeyPrefix();  
        
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        addProcedureCodeURL = '/'+servSympPrefix+'/e?'+ssPC+'='+p.Name+'&'+ssPC+'_lkid='+p.id+'&Name='+p.Name;        
        addProblemComponentURL = '/'+probCompPrefix+'/e?'+pcSS+'='+p.Name+'&'+pcSS+'_lkid='+p.id+'&Name=Enter Component';        
        
    
    
    
    }    
    
}
/*******************************************************//**


@author  Brianne Wilson (Slalom.BLW)

@version    2016-6-2  Slalom.BLW
    Created.

@copyright  (c)2016 Slalom.  All Rights Reserved. 
            Unauthorized use is prohibited.

***********************************************************/
public with sharing class RMS_viewPCLCtrlr {
	    
    public final Problem_Component_List__c p;
    public String baseURL{get;set;}
    public String addServiceSymptomURL{get;set;}
    map<String, Service_Field_Ids__c> Service_Field_Ids_map = Service_Field_Ids__c.getAll();
    public String ssPC = Service_Field_Ids_map.get('Problem Component - Problem Component').Value__c;


    public RMS_viewPCLCtrlr(ApexPages.StandardController stdController) {
        if(!test.isRunningTest()){
            stdController.addFields(new List<String>{'Name'});
        }
        this.p = (Problem_Component_List__c)stdController.getRecord();

        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        addServiceSymptomURL = '/a1C/e?'+ssPC+'='+p.Name+'&'+ssPC+'_lkid='+p.id+'&Name='+p.Name;        
        
    }



    
}
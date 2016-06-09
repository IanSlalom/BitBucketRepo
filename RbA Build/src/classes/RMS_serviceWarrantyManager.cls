/*******************************************************//**


@author  Brianne Wilson (Slalom.BLW)

@version    2016-6-2  Slalom.BLW
    Created.

@copyright  (c)2016 Slalom.  All Rights Reserved. 
            Unauthorized use is prohibited.

***********************************************************/
public with sharing class RMS_serviceWarrantyManager {
	    
    public final Product2 p;
    public String baseURL{get;set;}
    public String addServiceProductURL{get;set;}
    public String addMasterProductURL{get;set;}
    public String addProcedureCodeURL{get;set;}
    map<String, Service_Field_Ids__c> Service_Field_Ids_map = Service_Field_Ids__c.getAll();
    public String spMP = Service_Field_Ids_map.get('Service Product - Master Product').Value__c;
    public String spSP = Service_Field_Ids_map.get('Service Product - Service Product').Value__c;
    public String pcSP = Service_Field_Ids_map.get('Procedure Code - Service Product').Value__c;
    
    public RMS_serviceWarrantyManager(ApexPages.StandardController stdController) {
        if(!test.isRunningTest()){
            stdController.addFields(new List<String>{'Name','RecordTypeId'});
        }
        this.p = (Product2)stdController.getRecord();
        

        Schema.DescribeSObjectResult sp = Service_Product__c.sObjectType.getDescribe();
        String servProdKeyPrefix = sp.getKeyPrefix();
        
        Schema.DescribeSObjectResult pc = Procedure_Code_Assignment__c.sObjectType.getDescribe();
        String procCodePrefix = pc.getKeyPrefix();                        

        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        addServiceProductURL = '/'+servProdKeyPrefix+'/e?'+spMP+'='+p.Name+'&'+spMP+'_lkid='+p.id+'&Name=Enter Product Name Here';
        addMasterProductURL = '/'+servProdKeyPrefix+'/e?'+spSP+'='+p.Name+'&'+spSP+'_lkid='+p.id+'&Name='+p.Name;
        addProcedureCodeURL = '/'+procCodePrefix+'/e?'+pcSP+'='+p.Name+'&'+pcSP+'_lkid='+p.id+'&Name=Enter Code Here';
        
        
    }



    
}
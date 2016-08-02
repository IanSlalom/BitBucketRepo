public with sharing class RMS_MunicipalityManager {
    
    
    public void createMunicipalityMatch(List<Municipality__c> listNew, Map<Id, Municipality__c> mapNew){
        
        Id buildingPermitMunicipalitiesRecordType = UtilityMethods.retrieveRecordTypeId(Constants.PERMIT_MUNICIPALITY_RECORD_TYPE_NAME , 'Municipality__c');
        
        List<Municipality_Match__c> newMatch = new list<Municipality_Match__c>();        
        
        for(Municipality__c m : listNew){ 
            if(m.RecordTypeId == buildingPermitMunicipalitiesRecordType){
                Municipality_Match__c mm = new Municipality_Match__c(
                    Agency_Name__c = m.Id,
                    City_Township__c = m.City_Township__c,
                    Zip_Code__c = m.Zip_Code__c,
                    State__c = m.State__c,
                    County__c = m.County__c);
                
                newMatch.add(mm);
            }
            
            
        }
        insert newMatch;
        
    }
    
}
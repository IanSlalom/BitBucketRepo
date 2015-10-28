/*******************************************************//**

@class	RMS_MunicipalityMatchManager

@brief	Controller to hold logic about matching Municipalities to Dwellings(Accounts).

@author  Anthony Strafaccia (Slalom.ADS)

@version	2015-10/27  Slalom.ADS
	Created.

@see		RMS_MunicipalityMatchManagerTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/

public with sharing class RMS_MunicipalityMatchManager {

    public void matchBuildingPermitMunicipality(List<Account> listNew){ 
        system.debug('******INSIDE RMS_MunicipalityMatchManager/matchBuildingPermitMunicipality'); 
		
		//CREATE LIST TO ALLOW EDITING
 		list<Account> dwellingList = new list<Account>();
 		
        //SETTING UP RECORD TYPES VAR 
        Id dwellingAccountRecordType = UtilityMethods.retrieveRecordTypeId(Constants.DWELLING_ACCOUNT_RECORD_TYPE_NAME , 'Account');
        Id buildingPermitMunicipalitiesRecordType = UtilityMethods.retrieveRecordTypeId(Constants.PERMIT_MUNICIPALITY_RECORD_TYPE_NAME , 'Municipality__c');
        
        //BUILDING LIST OF STORE LOCATION IDs TO BE USED LATER
        list<id> storeLocationIds = new list<id>();
        
        //FOR LOOP TO REMOVE NON-DWELLING RECORD TYPE AND NULL ZIP CODE OR CITY BY ADDING TO NEW LIST
        for(Account acct : listNew){
        	if(acct.RecordTypeId == dwellingAccountRecordType && acct.BillingPostalCode != null && acct.BillingCity != null){
        		storeLocationIds.add(acct.Store_Location__c);
        		dwellingList.add(acct);
        	}
        }
	
		//GETTING ALL BUILDING PERMIT RECORD TYPE MUNICIPALITYS RELATED TO STORES
        list<Municipality__c> permitMunicipalities = [SELECT Id  FROM Municipality__c WHERE For_Retail_Location__c IN :storeLocationIds AND RecordTypeId = :buildingPermitMunicipalitiesRecordType];
        list<id> permitMunicipalityIds = new list<id>();
        
        //IF NO MUNICIPALITIES THEN SKIP REST OF LOGIC
        if(permitMunicipalities.size() > 0){
        	
        	//CREATING LIST OF MUNICIPALITY IDs TO BE USED LATER
	        for(Municipality__c muni : permitMunicipalities){
	        	permitMunicipalityIds.add(muni.Id);
	        }
        
	        list<Municipality_Match__c> permitMunicipalityMatchs = [SELECT 	id, 
	        																Agency_Name__c, 
	        																Zip_Code__c, 
	        																City_Township__c, 
	        																Agency_Name__r.For_Retail_Location__c 
    																FROM Municipality_Match__c 
    																WHERE Agency_Name__c IN :permitMunicipalityIds];
			
			//IF NO MUNICIPALITY MATCHES THEN SKIP REST OF LOGIC
			if(permitMunicipalityMatchs.size() > 0){
		        
		        //CREATE MAP OF STORE ID TO LIST OF MUNICIPALITY MATCHES
		        map<id, list<Municipality_Match__c>> storeIDtoListOfMatchMap = new  map<id, list<Municipality_Match__c>>();
				for(Municipality_Match__c muniMatch : permitMunicipalityMatchs){
					if(storeIDtoListOfMatchMap.containsKey(muniMatch.Agency_Name__r.For_Retail_Location__c)){
						storeIDtoListOfMatchMap.get(muniMatch.Agency_Name__r.For_Retail_Location__c).add(muniMatch);
					}else{
						storeIDtoListOfMatchMap.put(muniMatch.Agency_Name__r.For_Retail_Location__c, new list<Municipality_Match__c>{muniMatch});
					}	
				}   
		
		        //LOOP THROUGH DWELLINGS TO PREFORM LOGIC OF ASSINGING MUNICIPALITY
		        for(Account dwelling : dwellingList){
		        	
		        	//GET LIST OF MUNICIPALITY MATCHES AND LOOP THROUGH THEM TO CHECK FOR A ZIP&CITY MATCH
	        		list<Municipality_Match__c> relatedMatches = storeIDtoListOfMatchMap.get(dwelling.Store_Location__c);
	        		
	        		for(Municipality_Match__c mm : relatedMatches){
	        			if(	mm.Zip_Code__c == dwelling.BillingPostalCode && mm.City_Township__c.toUpperCase() == dwelling.BillingCity.toUpperCase()){
	        				
	        				//IF MATCHED ZIP&CITY THEN ASSIGN BUILDING PERMIT MUNICIPALITY TO DWELLING AND BREAK LOOP
	        				dwelling.Building_Permit__c = mm.Agency_Name__c;
	        				break;
	    				}
	        		}
		        }
	        
			} // END OF IF permitMunicipalityMatchs.size() > 0
       
        } // END OF IF permitMunicipalities.size() > 0
   
    } // END OF matchBuildingPermitMunicipality
    
    
    
} // EOF
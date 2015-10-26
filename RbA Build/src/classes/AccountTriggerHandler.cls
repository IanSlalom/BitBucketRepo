/*******************************************************//**

@class	AccountTriggerHandler

@brief	Controller to hold logic for AccountTrigger trigger

@author  Anthony Strafaccia (Slalom.ADS)

@version	2015-10/15  Slalom.ADS
	Created.

@see		AccountTriggerHandlerTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/


public without sharing class AccountTriggerHandler{

   
    public void OnBeforeInsert(List<Account> listNew){ 
        system.debug('ads INSIDE BEFORE INSERT');  
        
        Id dwellingAccountRecordType = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
        list<id> storeLocationIds = new list<id>();
        for(Account acct : listNew){
        	storeLocationIds.add(acct.Store_Location__c);
        }
        /*
        list<Account> storeLocations = [SELECT id, Building_Permit__c FROM Account WHERE id IN :storeLocationIds];
        list<id> permitMunicipalityIds = new list<id>();
        for(Account acct : storeLocations){
        	permitMunicipalityIds.add(acct.Building_Permit__c);
        }
        */
        list<Municipality__c> permitMunicipalities = [SELECT Id  FROM Municipality__c WHERE For_Retail_Location__c IN :storeLocationIds];
        list<id> permitMunicipalityIds = new list<id>();
        for(Municipality__c muni : permitMunicipalities){
        	permitMunicipalityIds.add(muni.Id);
        }
        list<Municipality_Match__c> permitMunicipalityMatchs = [SELECT id, Agency_Name__c, Zip_Code__c, City_Township__c, Agency_Name__r.For_Retail_Location__c FROM Municipality_Match__c WHERE Agency_Name__c IN :permitMunicipalityIds];
        map<id, list<Municipality_Match__c>> storeIDtoListOfMatchMap = new  map<id, list<Municipality_Match__c>>();
		
		
		
		//map<id, list<Municipality_Match__c>> storeIDtoListOfMatchMap = new  map<id, list<Municipality_Match__c>>();
		
		for(Municipality_Match__c muniMatch : permitMunicipalityMatchs){
			if(storeIDtoListOfMatchMap.containsKey(muniMatch.Agency_Name__r.For_Retail_Location__c)){
				storeIDtoListOfMatchMap.get(muniMatch.Agency_Name__r.For_Retail_Location__c).add(muniMatch);
			}else{
				storeIDtoListOfMatchMap.put(muniMatch.Agency_Name__r.For_Retail_Location__c, new list<Municipality_Match__c>{muniMatch});
			}	
		}   

        
        for(Account dwelling : listNew){
        	if(dwelling.RecordTypeId == dwellingAccountRecordType && dwelling.BillingPostalCode != null && dwelling.BillingCity != null){
        		system.debug('ads permitMunicipalityMatchs.size(): ' +permitMunicipalityMatchs.size());
        		list<Municipality_Match__c> relatedMatches = storeIDtoListOfMatchMap.get(dwelling.Store_Location__c);
        		
        		for(Municipality_Match__c mm : relatedMatches){
        			system.debug('ads mm.Zip_Code__c = dwelling.BillingPostalCode: '+mm.Zip_Code__c+' = '+dwelling.BillingPostalCode);
        			system.debug('ads mm.City_Township__c.toUpperCase() = dwelling.BillingCity.toUpperCase(): '+mm.City_Township__c.toUpperCase()+' = '+dwelling.BillingCity.toUpperCase());
        			
        			if(	mm.Zip_Code__c == dwelling.BillingPostalCode && mm.City_Township__c.toUpperCase() == dwelling.BillingCity.toUpperCase()){
        				system.debug('ads setting Building_Permit__c: ' +mm.Agency_Name__c);
        				dwelling.Building_Permit__c = mm.Agency_Name__c;
        				break;
    				}
        		}
        		
        		/*
        		Store_Location__c on account 
        		that account has Building_Permit__c a lookup to Municipality__c object with record type Permit 
        		find all the children of that object of type Municipality_Match__c
        		Billing Zip/Postal Code + Billing City = Zip Code + City/Township
        		*/
        	}
        }
    } 
    

    /*
    public void OnBeforeUpdate(List<Account> listOld, List<Account> listNew, Map<Id, Account> mapOld, Map<Id, Account> mapNew){
        system.debug('ads INSIDE BEFORE UPDATE');
    }
    */

    /*
    public void OnBeforeDelete(List<Account> listToDelete, Map<Id, Account> mapToDelete){
        system.debug('ads INSIDE BEFORE DELETE');
    }
    */

    /*
    public void OnAfterInsert(List<Account> listNew, Map<Id, Account> mapNew){
         system.debug('ads INSIDE AFTER INSERT');       
    }
    */

    /*
    public void OnAfterUpdate(List<Account> listOld, List<Account> listNew, Map<Id, Account> mapOld, Map<Id, Account> mapNew){
          system.debug('ads INSIDE AFTER UPDATE');        
    }
    /*

    /*
    public void OnAfterDelete(List<Account> listDeleted, Map<Id, Account> listNew){
         system.debug('ads INSIDE AFTER DELETE'); 
    }
    */
 
    /*
    public void OnUndelete(List<Account> listRestored){
         system.debug('ads INSIDE ON UNDELETE'); 
    }
    */
}
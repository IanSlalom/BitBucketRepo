public with sharing class RMS_backOfficeChecklistManager {

	/***********************************************
			createWorkOrderOnOrderCreation
	*******************************************/
	
	public void createBackOfficeChecksOnOrderCreation(List<Order> listNew, Map<Id, Order> mapNew){
		system.debug('******INSIDE RMS_backOfficeChecklistManager/createBackOfficeChecksOnOrderCreation');
		
		
		
		list<Id> relatedAccountIds = new list<Id>();
    	for(Order o : listNew){
    		relatedAccountIds.add(o.AccountId);
    	} 
    	list<Account> relatedAccounts = [SELECT BillingStreet,
								    			BillingCity,
								    			BillingState,
								    			BillingStateCode,
								    			BillingPostalCode, 
								    			BillingCountry,
								    			BillingCountryCode,
								    			Store_Location__c
								    			
								    			FROM Account WHERE Id IN :relatedAccountIds];
		map<id, Account> accountIdToAccountMap = new map<id, Account>();		
    	list<id> dwellingStoreLocationIds = new list<id>();
    	for(Account a : relatedAccounts){
    		accountIdToAccountMap.put(a.id, a);
    		dwellingStoreLocationIds.add(a.Store_Location__c);
    	}


	
    	//GETTING ALL STORE CONFIGS FOR RELATED DWELLINGS
	    map<Id, Store_Configuration__c> accountIdtoStoreConfigMap = UtilityMethods.mapStoreConfigs(dwellingStoreLocationIds);

		list<Id> storeConfigIdList = new list<id>();
    	for(Store_Configuration__c sc : accountIdtoStoreConfigMap.values()){
    		storeConfigIdList.add(sc.id);
    	}

    	
    	SObjectType xBOC = Schema.getGlobalDescribe().get('Back_Office_Checklist_Configuration__c');
		map<String,Schema.SObjectField> bocFieldsMap = xBOC.getDescribe().fields.getMap();
	    
	    String bocQuery = 'SELECT ';
	    
		for(String bocField : bocFieldsMap.KeySet()){
			bocQuery = bocQuery + bocField + ', ';
	    }
	    
	    bocQuery = bocQuery.substring(0,bocQuery.length()-2);
	    bocQuery = bocQuery + ' FROM Back_Office_Checklist_Configuration__c WHERE Store_Configuration__c IN :storeConfigIdList';
	    
	    list<Back_Office_Checklist_Configuration__c> backOfficeCheckList = Database.query(bocQuery);
    
    
    
    	map<id, Back_Office_Checklist_Configuration__c> storeConfigIdToBackOfficeChecklistMap = new map<id, Back_Office_Checklist_Configuration__c>();
    	for(Back_Office_Checklist_Configuration__c boc : backOfficeCheckList){
    		storeConfigIdToBackOfficeChecklistMap.put(boc.Store_Configuration__c, boc);
    	}
    	
    	
		list<Back_Office_Check__c> checksToAdd = new list<Back_Office_Check__c>();
		for(Order ord : listNew){
			
			//GETTING BACK OFFICE CONFIG FOR CURRENT ORDER
			Account orderDwelling = accountIdToAccountMap.get(ord.AccountId);
			
			//IF THE DWELLING DOESN'T HAVE A STORE SKIP REST OF LOGIC
			if(orderDwelling.Store_Location__c != null){
				Store_Configuration__c storeConfig = accountIdtoStoreConfigMap.get(orderDwelling.Store_Location__c);
		    	
		    	//IF THE STORE CONFIG IS NOT SET SKIP REST OF LOGIC
		    	if(storeConfig.id != null){
			    	Back_Office_Checklist_Configuration__c boChecklist = storeConfigIdToBackOfficeChecklistMap.get(storeConfig.id);
			    	
			    	system.debug('ADS boChecklist :'+boChecklist);
			    	
			    	//FOR EACH FIELD ON BACK OFFICE CHECKLIST CONFIG CREATES A CHECK ON THE ORDER.
			    	for(String bocField :bocFieldsMap.KeySet()){
			    		if(boChecklist.get(bocField) != null && boChecklist.get(bocField) == true){
			    			String checkName = bocFieldsMap.get(bocField).getDescribe().getLabel();
			    			Back_Office_Check__c boc = new Back_Office_Check__c(Name= checkName, Order__c = ord.Id);
				    		checksToAdd.add(boc);
			    		}	
			    	}
			
					insert checksToAdd;
		    	}
			}
		}
	}//END OF createBackOfficeChecksOnOrderCreation METHOD
	
	
}// EOF
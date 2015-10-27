/*******************************************************//**

@class	OrderTriggerHandler

@brief	Controller to hold logic for OrderTrigger trigger

@author  Anthony Strafaccia (Slalom.ADS)

@version	2015-10/26  Slalom.ADS
	Created.

@see		OrderTriggerHandlerTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/

public without sharing class OrderTriggerHandler{

    /*
    public void OnBeforeInsert(List<Order> listNew){
    	system.debug('ads INSIDE BEFORE INSERT');    
    } 
    */

    public void OnBeforeUpdate(List<Order> listOld, List<Order> listNew, Map<Id, Order> mapOld, Map<Id, Order> mapNew){
        system.debug('ads INSIDE BEFORE UPDATE');
    	
    	map<Id, Store_Configuration__c> accountIdtoStoreConfigMap = getAllStoreConfigs();
 
    	list<id> relatedDwellingIds = new list<id>();
    	
    	for(Order ord : listNew){
    		system.debug('ads ord: '+ ord);
    		system.debug('ads ord.AccountId: '+ ord.AccountId);
    		relatedDwellingIds.add(ord.AccountId);
    	}
    	
    	list<Account> relatedDwelling = [SELECT Id, 
    											Store_Location__c, 
    											HOA__c, Historical__c, 
    											Building_Permit__c,
    											BillingStreet,
								    			BillingCity,
								    			BillingState,
								    			BillingStateCode,
								    			BillingPostalCode, 
								    			BillingCountry,
								    			BillingCountryCode 
    									
    										FROM Account Where Id IN : relatedDwellingIds];
    	
    	map<id, Account> dwellingIdtoDwellingMap = new map<id, Account>();
    	for(Account dwel : relatedDwelling){
    		dwellingIdtoDwellingMap.put(dwel.id, dwel);
    	}
    	
    	list<SVMXC__Service_Order__c> workOrdersToAdd = new list<SVMXC__Service_Order__c>();
    	
    	for(Order ord : listNew){
    		system.debug('ads ord.Status: '+ord.Status);
    		system.debug('ads mapOld.get(ord.Id).Status: '+ mapOld.get(ord.Id).Status);
    		if(ord.Status == 'Activated' && mapOld.get(ord.Id).Status == 'Draft'){
    			
    			Account dwelling = dwellingIdtoDwellingMap.get(ord.AccountId);
    			
    			
    			Id permitWORecordType = UtilityMethods.retrieveRecordTypeId('Permit', 'SVMXC__Service_Order__c');
    			Id actionWORecordType = UtilityMethods.retrieveRecordTypeId('Actions', 'SVMXC__Service_Order__c');
    			
    			Store_Configuration__c storeConfig;
    			
    			if(dwelling.Store_Location__c == null){ 
    				ord.addError('Store has not been set on dwelling.');
    			}else if(accountIdtoStoreConfigMap.get(dwelling.Store_Location__c) == null){
    				ord.addError('Store Configuation has not been created.');
    			}else{
    				
    				storeConfig = accountIdtoStoreConfigMap.get(dwelling.Store_Location__c);
    			
	    			if(dwelling.HOA__c != null){
	    				system.debug('ads inside HOA');
	    				SVMXC__Service_Order__c hoaWorkOrder = buildWorkOrder(dwelling, ord, actionWORecordType, storeConfig.Permit_Work_Order_Queue_Id__c, 'HOA',  dwelling.HOA__c);
	    				workOrdersToAdd.add(hoaWorkOrder);
	    			}
	    			
	    			if(dwelling.Historical__c != null){
	    				system.debug('ads inside historical');
	    				SVMXC__Service_Order__c historicalWorkOrder = buildWorkOrder(dwelling, ord, actionWORecordType, storeConfig.Permit_Work_Order_Queue_Id__c, 'Historical', dwelling.Historical__c );
	    				workOrdersToAdd.add(historicalWorkOrder);
	    			}
	    			
	    			if(dwelling.Building_Permit__c != null){
	    				system.debug('ads inside building');
	    				SVMXC__Service_Order__c buildingPermitWorkOrder = buildWorkOrder(dwelling, ord, permitWORecordType, storeConfig.Permit_Work_Order_Queue_Id__c, 'Building Permit', dwelling.Building_Permit__c );
	    				workOrdersToAdd.add(buildingPermitWorkOrder);
	    			}
	    			system.debug('ads workOrdersToAdd: '+workOrdersToAdd);
	    			insert workOrdersToAdd;
	    		}
			}
   	
    	}
    
    } 
    

    /*
    public void OnBeforeDelete(List<Order> listToDelete, Map<Id, Order> mapToDelete){
        system.debug('ads INSIDE BEFORE DELETE');
    }
    */

   
    public void OnAfterInsert(List<Order> listNew, Map<Id, Order> mapNew){
        system.debug('ads INSIDE AFTER INSERT');
    	
    	list<SVMXC__Service_Order__c> workOrdersToAdd = new list<SVMXC__Service_Order__c>();
    	list<Back_Office_Check__c> checksToAdd = new list<Back_Office_Check__c>();
    	
    	//TODO: use utility methods
		RecordType serviceOrderVisitRecordType = [SELECT id FROM RecordType WHERE SobjectType = 'SVMXC__Service_Order__c' AND Name = 'Visit'];
    	RecordType accountStoreRecordType = [SELECT id FROM RecordType WHERE SobjectType = 'Account' AND Name = 'Store'];
    	
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
								    			BillingCountryCode
								    			FROM Account WHERE Id IN :relatedAccountIds];
		map<id, Account> accountIdToAccountMap = new map<id, Account>();		
    	for(Account a : relatedAccounts){
    		accountIdToAccountMap.put(a.id, a);
    	}
    	
    	
    	//TODO: Clean this up
    	////////THIS IS BEING USED FOR DEMO UNTIL ACCOUNT IS POPULATED INSIDE THE ORDER///////////
    	Account testAccount = [SELECT id FROM Account Where Name = '77 - Twin Cities, MN'];
    	//////////////////////////////////////////////////////////////////////////////////////////
    	
    	list<Store_Configuration__c> storeConfigs = [SELECT 	Id, 
    															Store__c, 
    															Install_Work_Order_Queue_Id__c, 
    															Tech_Measure_Work_Order_Queue_Id__c, 
    															Order_Queue_Id__c
    															FROM Store_Configuration__c
    															];
    	
    	map<id, Store_Configuration__c> accountIdtoStoreConfigMap = new map<id, Store_Configuration__c>();
		
		list<Id> storeConfigIdList = new list<id>();
    	for(Store_Configuration__c sc : storeConfigs){
    		accountIdtoStoreConfigMap.put(sc.Store__c, sc);
    		storeConfigIdList.add(sc.id);
    	}
    	
    	
    	//TODO: move to method
    	map<id, Back_Office_Checklist_Configuration__c> storeConfigIdToBackOfficeChecklistMap = new map<id, Back_Office_Checklist_Configuration__c>();
    	
    	SObjectType xBOC = Schema.getGlobalDescribe().get('Back_Office_Checklist_Configuration__c');
		map<String,Schema.SObjectField> bocFieldsMap = xBOC.getDescribe().fields.getMap();
	    
	    String bocQuery = 'SELECT ';
	    for(String bocField : bocFieldsMap.KeySet()){
			bocQuery = bocQuery + bocField + ', ';
	    }
	    bocQuery = bocQuery.substring(0,bocQuery.length()-2);
	    bocQuery = bocQuery + ' FROM Back_Office_Checklist_Configuration__c WHERE Store_Configuration__c IN :storeConfigIdList';
	    
	    list<Back_Office_Checklist_Configuration__c> backOfficeCheckList = Database.query(bocQuery);
    	//TODO: Class Method Names
    	system.debug('ads backOfficeCheckList: '+backOfficeCheckList);
    	for(Back_Office_Checklist_Configuration__c boc : backOfficeCheckList){
    		storeConfigIdToBackOfficeChecklistMap.put(boc.Store_Configuration__c, boc);
    	}
    	
    	
    	for(Order ord : listNew){
    		//TODO: Clean up
    		////////THIS IS BEING USED FOR DEMO UNTIL ACCOUNT IS POPULATED INSIDE THE ORDER///////////
	    	id storeLocation = testAccount.id;
	    	//////////////////////////////////////////////////////////////////////////////////////////
    		if(accountIdtoStoreConfigMap.get(storeLocation) == null){
    			ord.addError('Store Configuation has not been created.');
    		}
    		
    		Id installQueueId = accountIdtoStoreConfigMap.get(storeLocation).Install_Work_Order_Queue_Id__c;
    		Id techMeasureQueueId = accountIdtoStoreConfigMap.get(storeLocation).Tech_Measure_Work_Order_Queue_Id__c;
			
			//TODO:relatedDwelling
    		Account relatedAccount = accountIdToAccountMap.get(ord.AccountId);
    		
    		//CREATE WORK ORDER (TECH MEASURE)
    		SVMXC__Service_Order__c techWO = new SVMXC__Service_Order__c(
    			Sold_Order__c = ord.id,
    			RecordTypeId = serviceOrderVisitRecordType.id,
    			SVMXC__Order_Type__c = 'Tech Measure',
    			SVMXC__Company__c = ord.AccountId,
    				
    			SVMXC__Street__c = relatedAccount.BillingStreet,
    			SVMXC__City__c = relatedAccount.BillingCity,
    			SVMXC__State__c = relatedAccount.BillingStateCode,
    			SVMXC__Zip__c = relatedAccount.BillingPostalCode, 
    			SVMXC__Country__c = relatedAccount.BillingCountryCode,

    			OwnerId = techMeasureQueueId
    		);
    		workOrdersToAdd.add(techWO);
    		
    		
    		//CREATE WORK ORDER (INSTALL)
    		
    		/* Currently not making this type.
    		SVMXC__Service_Order__c installWO = new SVMXC__Service_Order__c(
    			Sold_Order__c = ord.id, 
    			RecordTypeId =  serviceOrderVisitRecordType.id,
    			SVMXC__Order_Type__c = 'Install',
    			SVMXC__Company__c = ord.AccountId,
    			
    			SVMXC__Street__c = relatedAccount.BillingStreet,
    			SVMXC__City__c = relatedAccount.BillingCity,
    			SVMXC__State__c = relatedAccount.BillingStateCode,
    			SVMXC__Zip__c = relatedAccount.BillingPostalCode, 
    			SVMXC__Country__c = relatedAccount.BillingCountryCode,
    			
    			
    			OwnerId = installQueueId
    		);
    		system.debug('ads adding install WO: '+installWO);
    		workOrdersToAdd.add(installWO);	
	    	*/
	    	
	    	
	    	
	    	
	    	Store_Configuration__c storeConfig = accountIdtoStoreConfigMap.get(storeLocation);
	    	system.debug('ADS storeConfig :'+storeConfig);
	    	
	    	//TODO:rename to checklist configuration
	    	Back_Office_Checklist_Configuration__c boChecklist = storeConfigIdToBackOfficeChecklistMap.get(storeConfig.id);
	    	
	    	system.debug('ADS boChecklist :'+boChecklist);
	    	
	    	for(String bocField :bocFieldsMap.KeySet()){
	    		if(boChecklist.get(bocField) != null && boChecklist.get(bocField) == true){
	    			String checkName = bocFieldsMap.get(bocField).getDescribe().getLabel();
	    			Back_Office_Check__c boc = new Back_Office_Check__c(Name= checkName, Order__c = ord.Id);
		    		checksToAdd.add(boc);
	    		}	
	    	}
    	}

    	insert workOrdersToAdd;
        insert checksToAdd;
                 
    }
   

    /*
    public void OnAfterUpdate(List<Order> listOld, List<Order> listNew, Map<Id, Order> mapOld, Map<Id, Order> mapNew){
          system.debug('ads INSIDE AFTER UPDATE');        
    }
    /*

    /*
    public void OnAfterDelete(List<Order> listDeleted, Map<Id, Order> listNew){
         system.debug('ads INSIDE AFTER DELETE'); 
    }
    */

    /*
    public void OnUndelete(List<Order> listRestored){
         system.debug('ads INSIDE ON UNDELETE'); 
    }
    */
    
    
    
    public SVMXC__Service_Order__c buildWorkOrder(Account dwelling, Order ord, Id rtID, Id ownerId, String ordType, Id munici ){
		SVMXC__Service_Order__c wo = new SVMXC__Service_Order__c(
			Sold_Order__c = ord.id,
			RecordTypeId = rtID,
			SVMXC__Order_Type__c = ordType,
			SVMXC__Company__c = ord.AccountId,
					
			SVMXC__Street__c = dwelling.BillingStreet,
			SVMXC__City__c = dwelling.BillingCity,
			SVMXC__State__c = dwelling.BillingStateCode,
			SVMXC__Zip__c = dwelling.BillingPostalCode, 
			SVMXC__Country__c = dwelling.BillingCountryCode,
			
			Municipality__c = munici,
			
			OwnerId = ownerId
			
		);
    	
    	return wo;
    	
    }
    
    public map<Id, Store_Configuration__c> getAllStoreConfigs(){
    	map<id, Store_Configuration__c> accountIdtoStoreConfigMap = new map<id, Store_Configuration__c>();

    	list<Store_Configuration__c> storeConfigs = [SELECT 	Id, 
    															Store__c, 
    															Install_Work_Order_Queue_Id__c, 
    															Tech_Measure_Work_Order_Queue_Id__c, 
    															Order_Queue_Id__c,
    															Permit_Work_Order_Queue_Id__c
    															FROM Store_Configuration__c
    															];
    	
    	for(Store_Configuration__c sc : storeConfigs){
    		accountIdtoStoreConfigMap.put(sc.Store__c, sc);
    	}
    	
    	return accountIdtoStoreConfigMap;
    }
    
    
}
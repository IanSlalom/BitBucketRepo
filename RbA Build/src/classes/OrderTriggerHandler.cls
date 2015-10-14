/*
Trigger Handler Anthony Strafaccia 2015

This is the class for the OrderTrigger that handles all the logic. It is designed so that only one trigger needs to be created for the object and allows for the customization of the order of execution. 

Test Code will be handled inside OrderTriggerHandlerTest
*/


public without sharing class OrderTriggerHandler{

    /*
    public void OnBeforeInsert(List<Order> listNew){
    	system.debug('ads INSIDE BEFORE INSERT');    
    } 
    */

    /*
    public void OnBeforeUpdate(List<Order> listOld, List<Order> listNew, Map<Id, Order> mapOld, Map<Id, Order> mapNew){
        system.debug('ads INSIDE BEFORE UPDATE');
    }
    */

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
    	
    	system.debug('Ads workOrdersToAdd[0]: ' + workOrdersToAdd[0].RecordType);
    	system.debug('Ads serviceOrderVisitRecordType: ' + serviceOrderVisitRecordType);
    	system.debug('Ads workOrdersToAdd[1]: ' + workOrdersToAdd[1].RecordType);
    	
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
}
public with sharing class UtilityMethods {

	public UtilityMethods() {}
	
	//CHANGE UTILITY METHOD TO SEND SOBJECT AS WELL
	public static Id retrieveRecordTypeId(String developerName, String sobjectType){
		RecordType recordType = [SELECT Id FROM RecordType WHERE IsActive = true AND DeveloperName = :developerName AND SobjectType = :sobjectType];
		return recordType.Id;
	}
	
	// Retrieves Id for recordtype using object name and dev name
	public static Id RecordTypeFor(String sObjectName, String devName) {

		String devString = sObjectName + devName;
		if (masterRTList == null || masterRTList.isEmpty()) {
			for (RecordType rt : [SELECT Id, developerName, sObjectType FROM RecordType]) {
				masterRTList.put(rt.sObjectType + rt.DeveloperName, rt.Id);
			}
		}
				
		return masterRTList.get(sObjectName + devName);
	}
	
	// Persistant variable used by RecordTypeFor()
	public static Map<String,Id> masterRTList = new Map<String,Id>();

	
	public static SVMXC__Service_Order__c buildWorkOrder(Account dwelling, Order ord, Id rtID, Id ownerId, String ordType, Id munici ){
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
    
	public static map<Id, Store_Configuration__c> mapStoreConfigs(list<id> storeIds){
    	map<id, Store_Configuration__c> accountIdtoStoreConfigMap = new map<id, Store_Configuration__c>();

    	list<Store_Configuration__c> storeConfigs = [SELECT 	Id, 
    															Store__c, 
    															Install_Work_Order_Queue_Id__c, 
    															Tech_Measure_Work_Order_Queue_Id__c, 
    															Order_Queue_Id__c,
    															HOA_Work_Order_Queue_Id__c,
    															Historical_Work_Order_Queue_Id__c,
    															Building_Permit_Work_Order_Queue_Id__c,
    															LSWP_WO_Owner_ID__c
    															
    															FROM Store_Configuration__c 
    															WHERE Store__c IN :storeIds
    															];
    	
    	for(Store_Configuration__c sc : storeConfigs){
    		accountIdtoStoreConfigMap.put(sc.Store__c, sc);
    	}
    	
    	return accountIdtoStoreConfigMap;
	}
	
	public static decimal calculateFraction(String fraction){
		if(fraction == 'Even'){
			fraction = null;
		}
		if(fraction != null){
			list<String>liststr = fraction.split('/');
			return (decimal.valueOf(liststr[0]) / decimal.valueOf(listStr[1])).setScale(3);
		}else{
			return 0;
		}
	}
    
}
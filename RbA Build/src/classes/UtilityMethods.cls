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



	//Cache used by GetRecordTypeIdsMapForSObject method
	private static Map<Schema.SObjectType,Map<String,Id>> rtypesCache = new Map<Schema.SObjectType,Map<String,Id>>();

	// Returns a map of active, user-available RecordType IDs for a given SObjectType,
	// keyed by each RecordType's unique, unchanging DeveloperName 
	public static Map<String, Id> GetRecordTypeIdsMapForSObject(Schema.SObjectType token) {
	    Map<String, Id> mapRecordTypes = rtypesCache.get(token);
	    //check if cache contains recordtypes for the object requested
	    if (mapRecordTypes == null) {
	        mapRecordTypes = new Map<String, Id>();
	        rtypesCache.put(token,mapRecordTypes);
	    } else {
	       return mapRecordTypes;
	    }

	    // Get the Describe Result
	    Schema.DescribeSObjectResult obj = token.getDescribe();
	    // Obtain ALL Active Record Types for the given SObjectType token
	    // (We will filter out the Record Types that are unavailable
	    // to the Running User using Schema information)
	    String soql = 
	        'SELECT Id, Name, DeveloperName '
	        + 'FROM RecordType '
	        + 'WHERE SObjectType = \'' + String.escapeSingleQuotes(obj.getName()) + '\' '
	        + 'AND IsActive = TRUE';
	    List<SObject> results;
	    try {
	        results = Database.query(soql);
	    } catch (Exception ex) {
	        results = new List<SObject>();
	    }

	    // Obtain the RecordTypeInfos for this SObjectType token
	    Map<Id,Schema.RecordTypeInfo> recordTypeInfos = obj.getRecordTypeInfosByID();

	    // Loop through all of the Record Types we found,
	    //      and weed out those that are unavailable to the Running User
	    for (SObject rt : results) {  
	        if (recordTypeInfos.get(rt.Id).isAvailable()) {
	            // This RecordType IS available to the running user,
	            //      so add it to our map of RecordTypeIds by DeveloperName
	            mapRecordTypes.put(String.valueOf(rt.get('DeveloperName')),rt.Id);
	        }
	    }

	    return mapRecordTypes;
	}
		
	public static RbA_Work_Order__c buildWorkOrder(Account dwelling, Order ord, Id rtID, Id ownerId, String ordType, Id munici ){
		RbA_Work_Order__c wo = new RbA_Work_Order__c(
			Sold_Order__c = ord.id,
			RecordTypeId = rtID,
			Work_Order_Type__c = ordType,
			Account__c = ord.AccountId,
					
			Street__c = dwelling.ShippingStreet,
			City__c = dwelling.ShippingCity,
			State__c = dwelling.ShippingStateCode,
			Zip__c = dwelling.ShippingPostalCode, 
			Country__c = dwelling.ShippingCountryCode,
			Contact__c = ord.BillToContactId,
			
			Municipality__c = munici,
			
			OwnerId = ownerId
			
		);
    	
		if(ord.OpportunityId != null){
    		wo.Opportunity__c = ord.OpportunityId;
		} 
		
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
    															LSWP_WO_Owner_ID__c,
    															Location_Number__c,
    															Paint_Stain_Vendor_Account__c,
    															Paint_Stain_Vendor_Contact__c,
    															Service_Work_Order_Queue_ID__c
    															
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

	// Method used to retrieve a store's financial account numbers in the form of a map of strings (AccountType, Number)
	public static Map<String,String> retrieveAccountNumbers(Id AccountId){
		if(AccountId == null){
			return null;
		}
		Map<String,String> accountNumberMap = new Map<String,String>();
		for (Financial_Account_Number__c fan : [SELECT Account_Type__c, Name FROM Financial_Account_Number__c WHERE Store_Configuration__r.Store__c =: AccountId]) {
			accountNumberMap.put(fan.Account_Type__c, fan.Name);	
		}
		return accountNumberMap;
	}

	// Method used to lock a list of sObjects
	public static String lockRecords(List<sObject> recordsToLock){
		String result;
		if(recordsToLock == null){
			result = 'No records received';
			return result;
		}
		// Lock the sObjects
		Approval.LockResult[] lrList = Approval.lock(recordsToLock, false);
	
		result = 'Records successfully locked';
	
		// Iterate through each returned result
		for(Approval.LockResult lr : lrList) {
    		if (lr.isSuccess()) {
        		// Operation was successful, so get the ID of the record that was processed
        		System.debug('Successfully locked account with ID: ' + lr.getId());

	    	}
    		else {
        		// Operation failed, so get all errors                
        		for(Database.Error err : lr.getErrors()) {
            		System.debug('The following error has occurred.');                    
            		System.debug(err.getStatusCode() + ': ' + err.getMessage());
           	 		System.debug('Account fields that affected this error: ' + err.getFields());
        		}
				result = 'One or more records could not be locked';
   			}
		}
		return result;
	}
	
	// Method used to check if a record is locked
	public static String checkLocked(List<sObject> listNew, List<sObject> listOld, map<id, sObject> mapNew, map<id, sObject> mapOld, String triggerType){
		String result = 'No records locked';

		List<sObject> recordsToCheck = (triggerType == 'Delete') ? listOld : listNew;

		if(recordsToCheck == null){
			result = 'No records received';
			System.Debug(result);
			return result;
		}
		for(SObject recordToCheck : recordsToCheck){
						
			// if it's a delete trigger, just check the old trigger, otherwise check old and new			
			boolean locked = (triggerType == 'Delete') ? (boolean)(mapOld.get(recordToCheck.id)).get('Locked__c') :
							((boolean)(mapNew.get(recordToCheck.id)).get('Locked__c') && (boolean)(mapOld.get(recordToCheck.id)).get('Locked__c'));
			if (locked) {
				recordToCheck.addError(RMS_errorMessages.RECORD_IS_LOCKED, FALSE);
				result = 'At least one record was locked';
			}
		}
		return result;
	}

	// Method used to check if a record is locked
	public static String checkLockedByStatus(List<sObject> listNew, List<sObject> listOld, map<id, sObject> mapNew, map<id, sObject> mapOld, String objectType){
		String result = 'No records locked';
		
		Map<String, List<String>> lockedFieldMap;

		if(listNew == null){
			result = 'No records received';
			return result;
		}

		if (objectType == 'Order') {
			// pulls the map of fields that should be locked by status from the Constants class
			lockedFieldMap = Constants.lockedOrderFieldMap;
		}
		List<sObject> recordsToCheck = listNew;
	
		for(SObject recordToCheck : recordsToCheck){
			String dynamicErrorMessage;
			String	errorMessage;
			System.Debug('********************object=' +(mapOld.get(recordToCheck.id)).get('Status'));
			// Retrieve	the old Status from the record, not the new (in case it changed)		
//			String status = (string)(mapOld.get(recordToCheck.id)).get('Status');
			String status = 'TestClass';
			List<String> lockedFields = lockedFieldMap.get(status);
			if (lockedFields == null) continue;
			// Pull the locked fields from the map and loop through them
			for (String lockedField : lockedFields) {

				// Check if the locked field has changed
				if ((mapOld.get(recordToCheck.id)).get(lockedField) != (mapNew.get(recordToCheck.id)).get(lockedField))
				{
					dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.FIELD_IS_LOCKED, '[field]', lockedField);
					errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
					recordToCheck.addError(errorMessage, FALSE);
					result = 'At least one record containted a field that was locked';
				}
			}
		}
		return result;
	}	

	/***************************************************
	 Method to dynamically change error messages
	****************************************************/
  	public static string fillInErrorRuleValues(String errorMessage, String targetValue, String replacementValue){
		errorMessage = errorMessage.replace(targetValue, '<b>('+replacementValue+')</b>');
		errorMessage = errorMessage.replace('null', '');
		
		return errorMessage;
	} 

	/*******************************************************
          calculateTaxes method - calculates the tax for po line items
	*******************************************************/
	public static List<OrderItem> calculateTaxes(List<OrderItem> allOrderItems, decimal poSubtotal, decimal poTax) {
		System.Debug('*************in method UtilityMethods->calculateTaxes=');

		// If any of the values are null or less than zero, return
		if (allOrderItems == null || poSubtotal == null || poTax == null) return null;
		if (allOrderItems.size() <= 0 || poSubtotal <= 0 || poTax <= 0) return null;

		List<OrderItem> itemsToTax = new List<OrderItem>();
		List<OrderItem> itemsToReturn = new List<OrderItem>();

		// Find only those order items that have a wholesale amount
		for (orderItem orderItem : allOrderItems) {
			if (orderItem.Unit_Wholesale_Cost__c != null && orderItem.Unit_Wholesale_Cost__c > 0) {
				itemsToTax.add(orderItem);
			}
		}

		// If the number of items with wholesale cost is null or zero, return
		if (itemsToTax == null) return null;
		integer numberOfItems = itemsToTax.size();
		if (numberOfItems == 0) return null;
		integer count = 1;
		decimal taxRemaining = poTax;
		
		for (orderItem itemToTax : itemsToTax) {

			// If we have reached the last item, just set it to the tax remaining
			if (count == numberOfItems) {
				itemToTax.Tax__c = taxRemaining;
			} 
			else {
				// multiple the total tax times the percentage of this item's 
				// wholesale cost to the po's subtotal
				itemToTax.Tax__c = poTax * ((itemToTax.Unit_Wholesale_Cost__c*itemToTax.Quantity) / poSubtotal);
			}
			itemsToReturn.add(itemToTax);

			// Increase the loop count and update the tax remaining to be applied
			count++;
			taxRemaining = taxRemaining - itemToTax.Tax__c;
		}

		// If we didn't apply all of the tax, add an error
		if (taxRemaining != 0)
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was a problem calculating the tax per line item. Please contact your administrator.'));
		return itemsToReturn;

	}
	
	/*******************************************************
          check for recursive triggers
	*******************************************************/

	/*******************************************************
			TriggerRan functionality

	Static variables and methods used from several triggers/classes
	to track whether a trigger has already ran
	*******************************************************/

	private static boolean alreadyRanOrderTrigger = false;

	public static boolean hasOrderTriggerRan()
	{
		return alreadyRanOrderTrigger;
	}

	public static void setOrderTriggerRan()
	{
		alreadyRanOrderTrigger = true;
	}

	public static void unsetOrderTriggerRan()
	{
		alreadyRanOrderTrigger = false;
	}

	
}
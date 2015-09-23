public with sharing class UtilityMethods {

	public UtilityMethods() {}
	
	//CHANGE UTILITY METHOD TO SEND SOBJECT AS WELL
	public RecordType retriveRecordType(String developerName, String sobjectType){
		RecordType recordType = [SELECT Id FROM RecordType WHERE IsActive = true AND DeveloperName = :developerName AND SobjectType = :sobjectType];
		return recordType;
	}
	
	
	
}
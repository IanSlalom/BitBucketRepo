@isTest
public with sharing class RMS_eventManagerTest {


	static testmethod void positiveDelete(){
		TestUtilityMethods testMethods = new TestUtilityMethods();
		testMethods.setUpConfigs();
		
		Id workOrderEventRecordTypeId = UtilityMethods.retrieveRecordTypeId('Work_Order_Event', 'Event');
		RbA_Work_Order__c rbaWO1 = new RbA_Work_Order__c(Cancel_Reason__c = 'Bad Reviews', Cancel_Date__c = Date.Today() );
		insert rbaWO1;
		
		Event e1 = new Event(	WhatId = rbaWO1.id, 
								StartDateTime = System.now(), 
								EndDateTime = System.now(), 
								RecordTypeId = workOrderEventRecordTypeId 
							);
		insert e1;
		delete e1;
		
		List<Change_History__c> chResults = [SELECT Id, RecordTypeId, RbA_Work_Order__c, Subtype__c, Changes__c FROM Change_History__c ];
		System.AssertEquals(1, chResults.size());
		System.AssertEquals(UtilityMethods.RecordTypeFor('Change_History__c', 'RbA_Work_Order'), chResults[0].RecordTypeId);
		System.AssertEquals('Change', chResults[0].Subtype__c);
		System.AssertEquals(rbaWO1.Id, chResults[0].RbA_Work_Order__c);
		System.Assert(chResults[0].Changes__c != null);
	}

}
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
	}

}
@isTest
public with sharing class RMS_priceCalcSlimAPILogicTest {
	
	
	static testmethod void testFindAppointments(){
		
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
		TestUtilityMethods utilities = new TestUtilityMethods();
			 
       /*
        User u = new User(Alias = 'standt', Email='rbaTest@test.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='rbaTest@test.com');
		*/
		
		User u = utilities.createUser(p.id);
		
		
        System.runAs(u) {
            // The following code runs as user 'u' 
            System.debug('Current User: ' + UserInfo.getUserName());
            System.debug('Current Profile: ' + UserInfo.getProfileId()); 
        	

			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			
			req.requestURI = '/services/apexrest/pcs/';  //Request URL
			req.httpMethod = 'GET';//HTTP Request Type
			RestContext.request = req;
			RestContext.response= res;
			
			RMS_priceCalcSlimAPILogic logic = new RMS_priceCalcSlimAPILogic ();
        	
        	String response1 =  logic.findAppointments(UserInfo.getUserId());
			system.debug('ADS Response1: '+ response1);
        	
        	
    	/////// START CREATE OF DATA //////
        	
        	RMS_Settings__c customSetting1 = new RMS_Settings__c(Value__c = '1234567890', Name='Data Loading Profile ID');
			insert customSetting1;
			
			
			
			Account account1 = utilities.createAccount('1');
		 	insert account1;
		 	
		 	Account account2 = utilities.createAccount('2');
		 	insert account2;
		 	
		 	Opportunity openOpp1 = utilities.createOpportunity(account1.id, 'Open');
		 	insert openOpp1;
		 	
		 	Opportunity openOpp2 = utilities.createOpportunity(account2.id, 'Open');
		 	insert openOpp2;
		 	
		 	Opportunity closedOpp1 = utilities.createOpportunity(account1.id, 'Closed');
		 	insert closedOpp1;
		 	
		 	Opportunity closedOpp2 = utilities.createOpportunity(account2.id, 'Closed');
		 	insert closedOpp2;
		 	
		 	
		 	Contact contact1 = utilities.createContact(account1.id, '1');
		 	insert contact1;
		 	Contact contact2 = utilities.createContact(account1.id, '2');
		 	insert contact2;
		 	
		 	Contact contact3 = utilities.createContact(account2.id, '3');
		 	insert contact3;
		 	Contact contact4 = utilities.createContact(account2.id, '4');
		 	insert contact4;
		 	
		 	Event event1 = new Event(WhatId = openOpp1.id, DurationInMinutes = 60, ActivityDateTime = Date.today().adddays(1));
		 	insert event1;
			
			Event event2 = new Event(WhatId = openOpp2.id, DurationInMinutes = 60, ActivityDateTime = Date.today().adddays(1));
		 	insert event2;

		//////// END CREATE OF DATA /////////


			String response2 =  logic.findAppointments(UserInfo.getUserId());
			system.debug('ADS Response2: '+ response2);
			
        }
	}
	
	
	
	static testmethod void testUpdateOpportunity(){
		
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
		TestUtilityMethods utilities = new TestUtilityMethods();
		RMS_priceCalcSlimAPILogic logic = new RMS_priceCalcSlimAPILogic ();
		
		User u = utilities.createUser(p.id);

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		
		req.requestURI = '/services/apexrest/pcs/updateOpps';  //Request URL
		req.httpMethod = 'POST';//HTTP Request Type
		RestContext.request = req;
		RestContext.response= res;
		
		//Creating Account (Needed for RMS_Queue_Settings__c)
		Account account1 = utilities.createAccount('1');
	 	insert account1;
		
		//Creating RMS_Settings__c
    	RMS_Settings__c customSetting1 = new RMS_Settings__c(Value__c = '1234567890', Name='Data Loading Profile ID');
		insert customSetting1;
		
		//Creating RMS_Queue_Settings__c
		Group Order_Queue = utilities.createQueue('Order_Queue');
		insert Order_Queue;
		QueueSobject Order_Queue_Link = utilities.createQueueSobject(Order_Queue.id ,'Order');
		insert Order_Queue_Link;
		
		
    	Group Install_Work_Order_Queue = utilities.createQueue('Install_Work_Order_Queue');
		insert Install_Work_Order_Queue;
		QueueSobject Install_Work_Order_Link = utilities.createQueueSobject(Install_Work_Order_Queue.id ,'SVMXC__Service_Order__c');
		insert Install_Work_Order_Link;
		
		Group Tech_Measure_Work_Order_Queue = utilities.createQueue('Tech_Measure_Work_Order');
		insert Tech_Measure_Work_Order_Queue;
		QueueSobject Tech_Measure_Work_Order_Link = utilities.createQueueSobject(Tech_Measure_Work_Order_Queue.id ,'SVMXC__Service_Order__c');
		insert Tech_Measure_Work_Order_Link;
		
    	Store_Configuration__c storeConfig = new Store_Configuration__c(
    		Store__c = account1.id,
        	Order_Queue_Id__c = Order_Queue.id,
    		Install_Work_Order_Queue_Id__c = Install_Work_Order_Queue.id,
        	Tech_Measure_Work_Order_Queue_Id__c = Tech_Measure_Work_Order_Queue.id
        	);
    	insert storeConfig;
		
		String response1 =  logic.updateOpportunity(null, 'Closed - Won');
		system.debug('ADS testUpdateOpportunity: '+ response1); 
		
    	Opportunity openOpp1 = utilities.createOpportunity(account1.id, 'Open');
	 	insert openOpp1;
    	
    	String response2 =  logic.updateOpportunity(openOpp1.id, 'Closed - Won');
    	system.debug('ADS testUpdateOpportunity: '+ response2); 

	}


}
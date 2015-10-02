@isTest
public with sharing class OrderTriggerHandlerTest {


	static testmethod void test1(){
		
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
		TestUtilityMethods utilities = new TestUtilityMethods();

		//Creating Account (Needed for RMS_Queue_Settings__c)
		Account account1 = utilities.createAccount('1');
	 	insert account1;
		
		Account store1 = utilities.createStoreAccount('77 - Twin Cities, MN');
		insert store1;
			
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
    		Store__c = store1.id,
        	Order_Queue_Id__c = Order_Queue.id,
    		Install_Work_Order_Queue_Id__c = Install_Work_Order_Queue.id,
        	Tech_Measure_Work_Order_Queue_Id__c = Tech_Measure_Work_Order_Queue.id
        	);
    	insert storeConfig;
		
		Order ord1 = new Order( AccountId = account1.id ,
								Status = 'Draft', 
								EffectiveDate = Date.Today()
								);
		insert ord1;
		
		
		
	}
}
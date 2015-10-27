@isTest
public with sharing class OrderTriggerHandlerTest {


	static testmethod void test1(){ 
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
		TestUtilityMethods utilities = new TestUtilityMethods();
		utilities.setUpConfigs();
		Account store = [SELECT Id FROM account WHERE Name ='77 - Twin Cities, MN'];
		
		
		
		Municipality__c muniHOA = new Municipality__c(Name ='HOAMuni', RecordTypeId = UtilityMethods.retrieveRecordTypeId('HOA', 'Municipality__c'), For_Retail_Location__c = store.id );
		insert muniHOA;
		Municipality__c muniHistorical = new Municipality__c(Name ='HistoricalMuni', RecordTypeId = UtilityMethods.retrieveRecordTypeId('Historical', 'Municipality__c'), For_Retail_Location__c = store.id );
		insert muniHistorical;
		Municipality__c muniPermit = new Municipality__c(Name ='PermitMuni', RecordTypeId = UtilityMethods.retrieveRecordTypeId('Permit', 'Municipality__c'), For_Retail_Location__c = store.id );
		insert muniPermit;
		
		Municipality_Match__c muniMatchHOA = new Municipality_Match__c(City_Township__c= 'Sunshine1', State__c = 'Minnesota', Zip_Code__c = '55449', Agency_Name__c = muniHOA.id );
		insert muniMatchHOA;
		Municipality_Match__c muniMatchHistorical = new Municipality_Match__c(City_Township__c= 'Sunshine1', State__c = 'Minnesota', Zip_Code__c = '55449', Agency_Name__c = muniHistorical.id );
		insert muniMatchHistorical;
		Municipality_Match__c muniMatchPermit = new Municipality_Match__c(City_Township__c= 'Sunshine', State__c = 'Minnesota', Zip_Code__c = '55449', Agency_Name__c = muniPermit.id );
		insert muniMatchPermit;
		
		
		
		
		//Creating Account (Needed for RMS_Queue_Settings__c)
		Account account1 =  new Account(Name = 'Test Account1',
	        AccountNumber = '1234567890',
	        Phone = '(763) 555-2000',
		 	Store_Location__c = store.id, 
			HOA__c = muniHOA.id, 
			Historical__c = muniHistorical.id, 
			Building_Permit__c = muniPermit.id,
			BillingStreet = '123 happy Ln',
			BillingCity = 'Sunshine',
			BillingState = 'Minnesota',
			BillingStateCode = 'MN',
			BillingPostalCode = '55449', 
			BillingCountry = 'United States',
			RecordTypeId = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account') ); 
	 	insert account1;

		Order ord1 = new Order( AccountId = account1.id ,
								Status = 'Draft', 
								EffectiveDate = Date.Today(),
								Pricebook2Id = Test.getStandardPricebookId()
								);
		insert ord1;
		
		
		
		Account vend1 = utilities.createVendorAccount('Vendor Account 1');
		insert vend1;

		Pricebook2 pricebook1 =  utilities.createPricebook2Name('Standard Price Book');
		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Test Product',
			Vendor__c = vend1.id
		);

		insert product1;
		
		PricebookEntry pricebookEntry1 = utilities.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;
		
		OrderItem orderItem1 = new OrderItem(OrderId = ord1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100 );
		insert orderItem1;	

		
		ord1.Status = 'Activated';
		update ord1;
		
		list<SVMXC__Service_Order__c> relatedWorkOrders = [SELECT id FROM SVMXC__Service_Order__c WHERE Sold_Order__c = :ord1.id];
		
		System.assertEquals(relatedWorkOrders.size(),4);
		
		ord1.Status = 'Draft';
		update ord1;
		
		delete ord1;
		
		//TODO:Assertions
	}
	

	
}
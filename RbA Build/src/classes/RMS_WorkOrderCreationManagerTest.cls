@isTest
public with sharing class RMS_WorkOrderCreationManagerTest {
		
	static testMethod void testWorkOrderMovingFromOppOnCreationOfWorkOrder(){
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();

		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
		id muniPermitRT = UtilityMethods.retrieveRecordTypeId('Permit', 'Municipality__c');
		
		Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];
		
		Municipality__c muni1 = utility.createMunicipality(store.id, muniPermitRT);
		insert muni1;
		
		Municipality__c muni2 = utility.createMunicipality(store.id, muniPermitRT);
		insert muni2;
		
		Municipality_Match__c mm1 = utility.createMunicipalityMatch(muni1.id, '55429', 'Blaine');
		insert mm1;
		
		Municipality_Match__c mm2 = utility.createMunicipalityMatch(muni1.id, '55444', 'Blaine');
		insert mm2;

		Account newDwelling = new Account(Name='test1', Store_Location__c = store.id, RecordTypeId = dwellingRT, BillingPostalCode = '55429' , BillingCity = 'Blaine' );
		insert newDwelling;
		
		//CREATE OPPORTUNITY
		Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=newDwelling.id, StageName = 'New', CloseDate = Date.today().addYears(1) );
		
		//CREATE A WORKORDER ON OPP
		Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
		RbA_Work_Order__c workOrderOnOpp = new RbA_Work_Order__c(  	RecordTypeId = serviceOrderVisitRecordTypeId,  
																				Order_Type__c = 'Tech Measure',
															                    Opportunity__c = opp1.id
															                    );
		
		//CREATE AN ORDER RELATED TO OPPORTUNITY
		Order ord1 = new Order( AccountId = newDwelling.id ,
								Status = 'Draft', 
								OpportunityId = opp1.id,
								EffectiveDate = Date.Today(),
								Pricebook2Id = Test.getStandardPricebookId()
								);
		insert ord1;
		
		
		//CHECK NO WORK ORDERS CREATED AND MOVED WORK ORDER THAT IS ON OPP TO ORDER
		list<RbA_Work_Order__c> workOrdersOnOrder = [SELECT Id, Opportunity__c FROM RbA_Work_Order__c WHERE Sold_Order__c = :ord1.id];
		
		System.assertEquals(workOrdersOnOrder.size() , 1);
		System.assertEquals(workOrdersOnOrder[0].Opportunity__c, opp1.id);
	}
	
	
	
	
	
	static testMethod void testWorkOrderCreationOnCreationOfWorkOrder(){
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();

		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
		id muniPermitRT = UtilityMethods.retrieveRecordTypeId('Permit', 'Municipality__c');
		
		Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];
		
		Municipality__c muni1 = utility.createMunicipality(store.id, muniPermitRT);
		insert muni1;
		
		Municipality__c muni2 = utility.createMunicipality(store.id, muniPermitRT);
		insert muni2;
		
		Municipality_Match__c mm1 = utility.createMunicipalityMatch(muni1.id, '55429', 'Blaine');
		insert mm1;
		
		Municipality_Match__c mm2 = utility.createMunicipalityMatch(muni1.id, '55444', 'Blaine');
		insert mm2;

		Account newDwelling = new Account(Name='test1', Store_Location__c = store.id, RecordTypeId = dwellingRT, BillingPostalCode = '55429' , BillingCity = 'Blaine' );
		insert newDwelling;

		//CREATE AN ORDER RELATED TO OPPORTUNITY
		Order ord1 = new Order( AccountId = newDwelling.id ,
								Status = 'Draft', 
								EffectiveDate = Date.Today(),
								Pricebook2Id = Test.getStandardPricebookId()
								);
		insert ord1;

		//CHECK NO WORK ORDERS CREATED AND MOVED WORK ORDER THAT IS ON OPP TO ORDER
		list<RbA_Work_Order__c> workOrdersOnOrder = [SELECT Id, Sold_Order__c FROM RbA_Work_Order__c WHERE Sold_Order__c = :ord1.id];
		
		System.assertEquals(workOrdersOnOrder.size() , 1);
		System.assertEquals(workOrdersOnOrder[0].Sold_Order__c, ord1.id);
	}
		
		
	
	
	
	static testmethod void testCreationOfWorkOrdersOnOrderActivation(){ 
		TestUtilityMethods utilities = new TestUtilityMethods();
		utilities.setUpConfigs();
		
		Account store = [SELECT Id FROM account WHERE Name ='77 - Twin Cities, MN'];
		
		//TODO TestutilityMethods
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

		Order ord2 = new Order( AccountId = account1.id ,
								Status = 'Draft', 
								EffectiveDate = Date.Today(),
								Pricebook2Id = Test.getStandardPricebookId()
								);
		insert ord2;
		
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
		
		OrderItem orderItem1 = new OrderItem(OrderId = ord2.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100 );
		insert orderItem1;	

		list<RbA_Work_Order__c> relatedWorkOrders = [SELECT id, Order_Type__c FROM RbA_Work_Order__c WHERE Sold_Order__c = :ord2.id];
		system.debug('ads remove relatedWorkOrders1: '+relatedWorkOrders);
		ord2.Status = 'Activated';
		update ord2;
		
		relatedWorkOrders = [SELECT id, Order_Type__c FROM RbA_Work_Order__c WHERE Sold_Order__c = :ord2.id];
		System.assertEquals(5, relatedWorkOrders.size());
		
		ord2.Status = 'Draft';
		update ord2;
		
		delete ord2;
	}



}
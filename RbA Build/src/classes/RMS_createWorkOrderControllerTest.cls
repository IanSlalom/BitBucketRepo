@isTest
public with sharing class RMS_createWorkOrderControllerTest {


	static testMethod void testingConstructor(){
		
		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();
		
		id dwellingRT = UtilityMethods.retrieveRecordTypeId('Dwelling', 'Account');
		Account store = [SELECT id FROM Account WHERE Name ='77 - Twin Cities, MN'];
		Account newDwelling = new Account(Name='test1', Store_Location__c = store.id, RecordTypeId = dwellingRT, BillingPostalCode = '55429' , BillingCity = 'Blaine' );
		insert newDwelling;
		
		//CREATE AN ORDER RELATED TO OPPORTUNITY
		Order ord1 = new Order( AccountId = newDwelling.id ,
								Status = 'Draft', 
								EffectiveDate = Date.Today(),
								Pricebook2Id = Test.getStandardPricebookId()
								);
		insert ord1;
		
		//CREATE OPPORTUNITY
		Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=newDwelling.id, StageName = 'New', CloseDate = Date.today().addYears(1) );
		insert opp1;
		
		Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
		RbA_Work_Order__c workOrder = new RbA_Work_Order__c(  	RecordTypeId = serviceOrderVisitRecordTypeId  
															                    );
		
		String actionUrl = '/apex/RMS_createActionsWorkOrder?'+
		'type=actions'+
		'&orderId='+ord1.id+
		'&accountId='+newDwelling.id+
		'&billingStreet=300 Stanley Ave'+
		'&billingCity=Long Beach'+
		'&billingPostalCode=California'+
		'&billingCountry=United States'+
		'&relatedOpp='+opp1.id+
		'&permit='+
		'&hoa='+
		'&historical=';
		
		PageReference pageRef = new PageReference(actionUrl); 
		Test.setCurrentPage(pageRef);
			
		ApexPages.StandardController stdController = new ApexPages.StandardController(workOrder);
		RMS_createWorkOrderController customController  = new RMS_createWorkOrderController(stdController);
		

		
		String visitUrl = '/apex/RMS_createActionsWorkOrder?'+
		'type=visit'+
		'&orderId='+ord1.id+
		'&accountId='+newDwelling.id+
		'&billingStreet=300 Stanley Ave'+
		'&billingCity=Long Beach'+
		'&billingPostalCode=California'+
		'&billingCountry=United States'+
		'&relatedOpp='+opp1.id+
		'&permit='+
		'&hoa='+
		'&historical=';
		PageReference pageRefVisit = new PageReference(visitUrl); 
		Test.setCurrentPage(pageRefVisit);
			
		ApexPages.StandardController stdControllerVisit = new ApexPages.StandardController(workOrder);
		RMS_createWorkOrderController customControllerVisit  = new RMS_createWorkOrderController(stdControllerVisit);
		
		
		
		String lswpUrl = '/apex/RMS_createActionsWorkOrder?'+
		'type=lswp'+
		'&orderId='+ord1.id+
		'&accountId='+newDwelling.id+
		'&billingStreet=300 Stanley Ave'+
		'&billingCity=Long Beach'+
		'&billingPostalCode=California'+
		'&billingCountry=United States'+
		'&relatedOpp='+opp1.id+
		'&permit='+
		'&hoa='+
		'&historical=';
		PageReference pageReflswp = new PageReference(lswpUrl); 
		Test.setCurrentPage(pageReflswp);
			
		ApexPages.StandardController stdControllerlswp = new ApexPages.StandardController(workOrder);
		RMS_createWorkOrderController customControllerlswp = new RMS_createWorkOrderController(stdControllerlswp);
		
		
		
		String paintStainUrl = '/apex/RMS_createActionsWorkOrder?'+
		'type=paintStain'+
		'&orderId='+ord1.id+
		'&accountId='+newDwelling.id+
		'&billingStreet=300 Stanley Ave'+
		'&billingCity=Long Beach'+
		'&billingPostalCode=California'+
		'&billingCountry=United States'+
		'&relatedOpp='+opp1.id+
		'&permit='+
		'&hoa='+
		'&historical=';
		PageReference pageRefpaintStain = new PageReference(paintStainUrl); 
		Test.setCurrentPage(pageRefpaintStain);
			
		ApexPages.StandardController stdControllerpaintStain = new ApexPages.StandardController(workOrder);
		RMS_createWorkOrderController customControllerpaintStain  = new RMS_createWorkOrderController(stdControllerpaintStain);
		
		
		String permitUrl = '/apex/RMS_createActionsWorkOrder?'+
		'type=permit'+
		'&orderId='+ord1.id+
		'&accountId='+newDwelling.id+
		'&billingStreet=300 Stanley Ave'+
		'&billingCity=Long Beach'+
		'&billingPostalCode=California'+
		'&billingCountry=United States'+
		'&relatedOpp='+opp1.id+
		'&permit='+
		'&hoa='+
		'&historical=';
		PageReference pageRefpermit = new PageReference(permitUrl); 
		Test.setCurrentPage(pageRefpermit);
			
		ApexPages.StandardController stdControllerpermit = new ApexPages.StandardController(workOrder);
		RMS_createWorkOrderController customControllerpermit  = new RMS_createWorkOrderController(stdControllerpermit);
		
		customControllerpermit.save();
	
	}

}
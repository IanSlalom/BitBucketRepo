@isTest
public with sharing class RMS_vendorPurchaseOrderControllerTest {
	
	
	static testmethod void test(){
		TestUtilityMethods utility = new TestUtilityMethods();
		
		RMS_Settings__c customSetting1 = new RMS_Settings__c(Value__c = '1234567890', Name='Data Loading Profile ID');
		insert customSetting1;
	
		Account account1 = utility.createVendorAccount('test1');
		insert account1;
		
		Opportunity opp1 = utility.createOpportunity(account1.id, 'Closed - Won');
		insert opp1;
		
		Pricebook2 pricebook1 =  utility.createPricebook2();
		insert pricebook1;

		Product2 product1 = new Product2(
    		Name='Test Product',
    		Vendor__c = account1.id
		);
		
		
		insert product1;
		
		PricebookEntry pricebookEntry1 = utility.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
		insert pricebookEntry1;
		
		Order order1 = new Order(	Name='testOrder', 
									AccountId = account1.id, 
									EffectiveDate= Date.Today(), 
									Opportunity = opp1, 
									Status ='Draft', 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		
		OrderItem orderItem1 = new OrderItem(OrderId = Order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100 );
		insert orderItem1;
		
		
		Purchase_Order__c po = new Purchase_Order__c();
		
		ApexPages.currentPage().getParameters().put('orderId',order1.id);
		ApexPages.StandardController stdController = new ApexPages.StandardController(po);
	    RMS_vendorPurchaseOrderController customController  = new RMS_vendorPurchaseOrderController(stdController);
		
		customController.Save();
		customController.Cancel();
		customController.selectedVendor = account1.id;
		list<SelectOption> avaliableVendors = customController.getAvaliableVendors();
		list<RMS_vendorPurchaseOrderController.OrderItemWrapper> orderItemWrappersByVendor = customController.getOrderItemWrappersByVendor();
		customController.updateSubTotal();
		
		
		
		ApexPages.StandardController stdController2 = new ApexPages.StandardController(po);
		RMS_vendorPurchaseOrderController customController2  = new RMS_vendorPurchaseOrderController(stdController2);
		
		
		
	}	
}
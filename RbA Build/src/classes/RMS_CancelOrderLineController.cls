public with sharing class RMS_CancelOrderLineController {
	
	public OrderItem oi;
	ApexPAges.StandardController controller;
	public RMS_CancelOrderLineController(ApexPages.StandardController stdController) {
		controller = stdController;
		oi = (OrderItem)stdController.getRecord();
		oi.Status__c = 'Cancelled';
	}

	public PageReference save(){
		controller.save();
		return new PageReference('/'+oi.OrderId);
	}

	public PageReference cancel(){
		controller.cancel();
		return new PageReference('/'+oi.OrderId);
	
	}
}
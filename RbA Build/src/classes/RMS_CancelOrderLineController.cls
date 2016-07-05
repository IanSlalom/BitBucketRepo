public with sharing class RMS_CancelOrderLineController {
	
	public OrderItem oi;
	ApexPages.StandardController controller;
	public RMS_CancelOrderLineController(ApexPages.StandardController stdController) {
		controller = stdController;
		oi = (OrderItem)stdController.getRecord();
		oi.Status__c = 'Cancelled';
	}

	public void save(){
		controller.save();
		//return new PageReference('/'+oi.OrderId);
	}

	public void cancel(){
		controller.cancel();
		//return new PageReference('/'+oi.OrderId);
	
	}
}
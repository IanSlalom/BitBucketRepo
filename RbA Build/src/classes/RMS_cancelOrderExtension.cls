/*******************************************************//**

@class	RMS_cancelOrderExtension

@brief	Controller extension for VF page RMS_cancelOrder.page

	Cancels the order and other related records

@author  Creston Kuenzi (Slalom.CDK)

@version	2015-10-25  Slalom.CDK
	Created.

@see		RMS_cancelOrderExtensionTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited. 

***********************************************************/
public with sharing class RMS_cancelOrderExtension {


	/******* Set up Standard Controller for Order  *****************/
	private Apexpages.StandardController standardController;
	private final Order theOrder;
	
	/******* Constructor  *****************/
	public RMS_cancelOrderExtension(ApexPages.StandardController stdController) {
		this.theOrder = (Order)stdController.getRecord();
	}
	
	/*******************************************************
					cancelOrder method
	*******************************************************/
	public PageReference cancelOrder() {
		system.debug('*****Cancelling an order');

		String theId = ApexPages.currentPage().getParameters().get('id');

		if (theId == null) {
			// Display the Visualforce page's content if no Id is found
			return null;
		}

		// Find the order and cancel it
		Order theOrder = [Select Id, Name, Status from Order where id =:theId];
		theOrder.Status = 'Cancelled';
		theOrder.Date_Cancelled__c = System.Today();


		List<RbA_Work_Order__c> workOrdersWithOpenEvents = [Select Id from RbA_Work_Order__c WHERE Sold_Order__c =:theOrder.Id 
                                                            AND Number_Open_Events_Formula__c > 0];
		if(!workOrdersWithOpenEvents.isEmpty()){
			System.debug('Error encountered in RMS_CancelOrderExtensions: ' + RMS_errorMessages.WORK_ORDERS_WITH_OPEN_EVENTS);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.WORK_ORDERS_WITH_OPEN_EVENTS)); 
			return null;
		}	
		List<Purchase_Order__c> purchaseOrdersToCancel = new List<Purchase_Order__c>();
		List<OrderItem> orderItemsToCancel = new List<OrderItem>();
		List<Order_Discount__c> discountsToCancel = new List<Order_Discount__c>();
		List<RbA_Work_Order__c> workOrdersToCancel = new List<RbA_Work_Order__c>();

		// Find any purchase orders linked to the order that haven't been cancelled and cancel them
		for (Purchase_Order__c poToCancel : [SELECT Id, Status__c FROM Purchase_Order__c 
											WHERE Order__c =: theOrder.Id AND Status__c != 'Cancelled']) 
		{
			poToCancel.Status__c = 'Cancelled';
			purchaseOrdersToCancel.add(poToCancel);
		}

		// Find any order items linked to the order that haven't been cancelled and cancel them
		for (OrderItem orderItemToCancel : [SELECT Id, Status__c FROM OrderItem 
											WHERE OrderId =: theOrder.Id AND Status__c != 'Cancelled']) 
		{
			orderItemToCancel.Status__c = 'Cancelled';
			orderItemsToCancel.add(orderItemToCancel);
		}

		// Find any discounts linked to the order that haven't been cancelled and cancel them
		for (Order_Discount__c discToCancel : [SELECT Id, Status__c FROM Order_Discount__c 
											WHERE Order__c =: theOrder.Id AND Status__c != 'Cancelled']) 
		{
			discToCancel.Status__c = 'Cancelled';
			discountsToCancel.add(discToCancel);
		}

		for(RbA_Work_Order__c woTocancel : [Select Id, Work_Order_Status__c, Work_Order_Type__c, Cancel_Reason__c FROM RbA_Work_Order__c
											WHERE Work_Order_Type__c in ('LSWP','Bulding Permit','HOA','Historical','Tech Measure','Install','Paint/Stain')
											AND Sold_Order__c =:theOrder.Id]){
			woToCancel.Work_Order_Status__c = 'Cancelled';
			if (woToCancel.Cancel_Reason__c == null) woToCancel.Cancel_Reason__c = 'Order Cancelled';
			workOrdersToCancel.add(woTocancel);
		}

		try{
			// upsert all of the cancelled order items, pos, and the order
			upsert purchaseOrdersToCancel;  
			upsert discountsToCancel; 
			upsert orderItemsToCancel; 
			update workOrdersToCancel;
			upsert theOrder;
		} catch (Exception e){
			// TODO: Add comment here
			System.debug('************The following exception occurred in the RMS_cancelOrderExtension in the cancelOrder method:' + e);
			return null;
		}

		// Redirect the user back to the order page
		PageReference pageRef = new PageReference('/' + theId);
		pageRef.setRedirect(true);
		return pageRef;

	}
}
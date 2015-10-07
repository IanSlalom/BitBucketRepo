/*******************************************************//**

@class      RMS_vendorPurchaseOrderController

@brief      Controller for VF page RMS_vendorPurchaseOrder.page

    Manages all of the purchase order creation and editing logic

@author     Anthony Strafaccia (Slalom.CDK)

@version    2015-09/16  Slalom.ADS
    Created.

@see        RMS_vendorPurchaseOrderControllerTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/

public with sharing class RMS_vendorPurchaseOrderController { 
	 
	/******* public variables  *****************/
	
	 
	//public variables used on VF page
	public String selectedVendor {get;set;}
	public String selectedVendorName {get;set;}
 	public String status {get;set;}
	
	//public variables used in both new and edit PO
 //	public Id orderId;
 	public Order relatedOrder;
	public List<OrderItem> relatedOrderItems = new List<OrderItem>();
 	public list<Id> relatedProduct2IDList = new list<Id>();
	public List<Product2> relatedProducts = new List<Product2>();
 	public list<Id> vendorIdList = new list<Id>();
	public list<Account> vendorsOnOrder = new list<Account>();

    public String orderId             { get; set; }
    {
        orderId = apexpages.currentpage().getparameters().get('orderId');
        if ( orderId == null ) orderId = '';
    }
 	
	public Boolean newPurchaseOrder {get;set;}
	
 	//public variables to be used in new PO
 	public list<SelectOption> avaliableVendors = new list<SelectOption>();
 	
 	
 	//public variables to create wrapper
	public list<OrderItemWrapper> orderItemWrapperList = new list<OrderItemWrapper>();
	
	public map<Id, OrderItem> orderItemIdToOrderItemMap = new Map<Id, OrderItem>();
	public map<Id, Account> accountIdToAccountMap = new Map<Id, Account>();
	public map<Id, Product2> productIdToProductMap = new Map<Id, Product2>();
	
	public list<OrderItemWrapper> orderItemWrapperByVendor = new list<OrderItemWrapper>();
 	/******* Set up Standard Controller for Purchase_Order__c  *****************/
 	private Apexpages.StandardController standardController;
 	private final Purchase_Order__c po;
	
	
	
	//Constructor
	public RMS_vendorPurchaseOrderController(ApexPages.StandardController stdController) {
		this.po = (Purchase_Order__c)stdController.getRecord();
	    
		//NEW PURCHASE ORDER
        if(stdController.getId() == null){
        	newPurchaseOrder = true;
//	        orderId = apexpages.currentpage().getparameters().get('orderId');
	        status = 'new';
	        this.po.Status__c = 'New';
	        
        }//END OF NEW PURCHASE ORDER 
        
		//EXISTING PURCHASE ORDER	       	
        else {
			newPurchaseOrder = false;
	        
	        Purchase_Order__c po1 = [SELECT Id, Order__c, Vendor__c, Vendor__r.Name From Purchase_Order__c Where ID =:po.id];
	        orderId = po1.Order__c;
	        selectedVendor = po1.Vendor__c;
	        selectedVendorName = po1.Vendor__r.Name;
	        status = 	(this.po.Status__c == 'Released' && selectedVendorName != 'RbA') 	? 	'rel' 	:
	        			(this.po.Status__c == 'Released' && selectedVendorName == 'RbA')	?	'rbarel'	:
	        			(this.po.Status__c == 'Confirmed' && selectedVendorName != 'RbA')	?	'con'	:
	        			(this.po.Status__c == 'Confirmed' && selectedVendorName == 'RbA')	?	'rbacon'	:							
	        			(this.po.Status__c == 'Rejected')	?									'rej'	:
	        			(this.po.Status__c == 'Received')	?									'rec'	:
	        			(this.po.Status__c == 'Cancelled')	?									'can'	:
	        																					'new';
	        		

        }
       
        //GET THE ORDER
        relatedOrder = [SELECT Id, Name  FROM Order WHERE Id = :orderId];
        
        //GET THE ORDER ITEMS
        relatedOrderItems =[Select Id, OrderItemNumber, Pricebookentry.Product2Id, Pricebookentry.UnitPrice, Quantity, Variant_Number__c, Unit_Wholesale_Cost__c FROM OrderItem Where OrderId =: orderId];
		
       
       //USING ORDER ITEMS GET ALL PRODUCTS
        for(OrderItem oi: relatedOrderItems){
        	System.debug('***************oi=' +oi);
        	relatedProduct2IDList.add(oi.Pricebookentry.Product2Id);
        	orderItemIdToOrderItemMap.put(oi.id, oi);
        }
        relatedProducts = [SELECT Id, Name, Vendor__c, Vendor__r.Id, Vendor__r.Name FROM Product2 Where Id IN :relatedProduct2IDList];
		
		//USING PRODUCTS GET LIST OF ALL VENDORS
		for(Product2 p : relatedProducts){
			vendorIdList.add(p.Vendor__c);
			productIdToProductMap.put(p.id, p);
		}
		list<Account> vendorsOnOrder = [SELECT Id, Name FROM Account WHERE Id IN :vendorIdList];
        for(Account a : vendorsOnOrder){
        	accountIdToAccountMap.put(a.id, a);
        }
        
        //USING MAPS TO CREATE WRAPPERS
        
        for(OrderItem oi : relatedOrderItems){
        	Product2 product2 = productIdToProductMap.get(oi.Pricebookentry.Product2Id);
        	Account account = accountIdToAccountMap.get(product2.Vendor__c);
        	OrderItemWrapper OIW = new OrderItemWrapper(oi, account, product2);
        	
        	orderItemWrapperList.add(OIW);
        }
    	//BUILD SELECT LIST FOR CHOOSING VENDOR
		avaliableVendors.add(new SelectOption('','Please Select'));
		for(Account vend : vendorsOnOrder){
			avaliableVendors.add(new SelectOption(vend.Id,vend.Name));
		}	
	}//end of constructor
	
	public List<SelectOption> getAvaliableVendors() {
		return avaliableVendors;
    }
    
    
	public List<OrderItemWrapper> getOrderItemWrappersByVendor(){
		orderItemWrapperByVendor.clear();
		
		for(OrderItemWrapper oiw : orderItemWrapperList){
			system.debug('ADS oiw: '+oiw);
			if(oiw.account != null && oiw.account.id == selectedVendor){
				orderItemWrapperByVendor.add(oiw);
			}
		}
		system.debug('ADS orderItemsByVendor: '+orderItemWrapperByVendor);
		return orderItemWrapperByVendor;
	}
	
	
	public void updateSubTotal(){
		List<OrderItemWrapper> venderOrderItems = getOrderItemWrappersByVendor();
		Decimal subtotal = 0;
		for(OrderItemWrapper oiw :venderOrderItems){
			system.debug('ads oiw.OrderItem.Pricebookentry.UnitPrice: ' +oiw.orderItem.Pricebookentry.UnitPrice);
			subtotal = subtotal + (oiw.orderItem.Pricebookentry.UnitPrice*oiw.orderItem.Quantity);
		}
		po.Subtotal__c = subtotal;
	}
	
	
	
	//OVERRIDE SAVE METHOD
	public PageReference save() {
		system.debug('ads selectedVendor save: '+selectedVendor);
		if(newPurchaseOrder == true){
			if(selectedVendor == '' || selectedVendor == null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please select a Vendor'));
				return null;
			}
			else{
				po.Name = 'PlaceHolderPOName';
				po.Vendor__c = selectedVendor; 
			 	po.Order__c = orderId;
			 	//po.RecordType =  
			}	
		}
		// check for received status errors
		if (checkReceived())
			return null;
			 	
		upsert po;
		
		list<OrderItem> orderItemsToUpdateList = new list<OrderItem>();
			 	
		for(OrderItemWrapper oiw : orderItemWrapperByVendor){
			OrderItem oi = oiw.orderItem;
			oi.Purchase_Order__c = po.id;
			orderItemsToUpdateList.add(oi);
		}
		update orderItemsToUpdateList;

		return null;
        
	}
	
    //OVERRIDE CANCEL METHOD
	public virtual PageReference cancel() {
		return null;
	}
	
	public PageReference saveAndNew() {
		if(newPurchaseOrder == true){
			if(selectedVendor == '' || selectedVendor == null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please select a Vendor'));
				return null;
			}else{
				if(selectedVendor == '' || selectedVendor == null){
					po.addError('Please select a Vendor');
				}
				po.Name = 'PlaceHolderPOName';
				po.Vendor__c = selectedVendor;
			 	po.Order__c = orderId;
			 	//po.RecordType =  
			 	upsert po;
		
			 	list<OrderItem> orderItemsToUpdateList = new list<OrderItem>();
			 	
			 	for(OrderItemWrapper oiw : orderItemWrapperByVendor){
			 		OrderItem oi = oiw.orderItem;
			 		oi.Purchase_Order__c = po.id;
			 		orderItemsToUpdateList.add(oi);
			 	}
				update orderItemsToUpdateList;
			}
		}else{
			upsert po;
		}
		return null;
	}

	// Method to ensure that it's ok to change the status to received
	public boolean checkReceived() {
		
		// If the status is not received just return false
	 	if (po.Status__c != 'Received')
	 		return false;

		// If the status is received and the ship date is null, return true
	 	if (po.Estimated_Ship_Date__c == null) {
	 		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.SHIP_DATE_REQUIRED));
	 		return true;
	 	}
	 		
		// If the status is received and one of the unit costs is null, return true
		for(OrderItemWrapper oiw : orderItemWrapperByVendor){
			if (oiw.orderItem.Unit_Wholesale_Cost__c == null) {
 				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.UNIT_COST_REQUIRED));
 				return true;					
			}
		}
		// It's ok to change the status to Received so return false
		return false; 			 				
	}
	public class OrderItemWrapper{
		public OrderItem orderItem {get; set;}
   		public Account account {get; set;}
   		public Product2 product {get; set;}
   		
        public OrderItemWrapper(OrderItem oi, Account a, Product2 p) {
            orderItem = oi;
            account = a;
            product = p;
        }                            
    } 


}
/*******************************************************//**

@class	RMS_vendorPurchaseOrderController

@brief	Controller for VF page RMS_vendorPurchaseOrder.page

	Manages all of the purchase order creation and editing logic

@author  Anthony Strafaccia (Slalom.ADS)
@author  Creston Kuenzi (Slalom.CDK)

@version	2015-09/16  Slalom.ADS
	Created.
@version	2015-10/12  Slalom.CDK
	Added ability to add products manually and Cost PO Functionality.

@see		RMS_vendorPurchaseOrderControllerTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/

public with sharing class RMS_vendorPurchaseOrderController { 
	 
	/******* public variables  *****************/

	//public variables used on VF page
	public String selectedVendor {get;set;}
	public String selectedPricebook {get;set;}
	public String status {get;set;}
	public String poId {get;set;}
	
	//public variables used in both new and edit PO
	public Order relatedOrder;
	public List<OrderItem> relatedOrderItems = new List<OrderItem>();
	public list<Id> relatedProduct2IDList = new list<Id>();
	public List<Product2> relatedProducts = new List<Product2>();
	public list<Id> vendorIdList = new list<Id>();
	public list<Account> vendorsOnOrder = new list<Account>();
	public String newProduct { get; set; }

	// The selected vendor name string
	public String selectedVendorName
	{
		get
		{
			if ( String.isNotBlank(selectedVendorName) ) return selectedVendorName;
			if ( selectedVendor == null) {
				selectedVendorName = '';
			}
			else {
				selectedVendorName = [SELECT Name from Account Where Id =: selectedVendor].Name;
			}

			return selectedVendorName;
		}
		set;
	}

	public List<OrderItem> newOrderItems 
	{
		get
		{
			if ( newOrderItems == null ) {
				newOrderItems = new List<OrderItem>();
				OrderItem o = new OrderItem();
				newOrderItems.add(o);
			}
			return newOrderItems;
		}
		private set;
	}

	// SOQL Filters for the vendor autocomplete checklist
	public String vendorFilter
	{
		get
		{
			if ( vendorFilter != null ) return vendorFilter;
			vendorFilter = ' AND RecordTypeId = ';
			return vendorFilter;
		}
		private set;
	}
	public String vendorFilter2
	{
		get
		{
			if ( vendorFilter2 != null ) return vendorFilter2;
			vendorFilter2 = UtilityMethods.retrieveRecordTypeId('Vendor', 'Account');
			return vendorFilter2;
		}
		private set;
	}

	// SOQL Filters for the product autocomplete checklist
	public String productFilter
	{
		get
		{
			if ( productFilter != null ) return productFilter;
			if (selectedVendor == null) return null;

			// If this is a cost PO, only return non-inventoried items, otherwise return inventoried items
			productFilter = (costPurchaseOrder) ? 	' AND Inventoried_Item__c = false ' :
													' AND Inventoried_Item__c = true ';

			// Only return active products with a particular vendor (see productFilter2)
			productFilter += ' AND IsActive = true AND Vendor__c = ';
			return productFilter;
		}
		private set;
	}
	public String productFilter2
	{
		get
		{
			if ( productFilter2 != null ) return productFilter2;
			if (selectedVendor == null) return null;
			productFilter2 = selectedVendor;
			return productFilter2;
		}
		private set;
	}

	// Dynamic string used in the page title
	public String pageTitle
	{
		get
		{
			if ( pageTitle != null ) return pageTitle;
			pageTitle = (newPurchaseOrder) ? 'Create ' : '';
			pageTitle += (costPurchaseOrder) ? 'Cost' : 'Product';
			return pageTitle;
		}
		private set;
	}
	// Dynamic string used to change product text to item
	public String productText
	{
		get
		{
			if ( productText != null ) return productText;
			productText = (costPurchaseOrder) ? 'Item' : 'Product';
			return productText;
		}
		private set;
	}

	public String orderId { get; set; }
	{
		orderId = apexpages.currentpage().getparameters().get('orderId');
		if ( orderId == null ) orderId = '';
	}
	
	public Boolean newPurchaseOrder {get;set;}
	public Boolean costPurchaseOrder {get;set;}
	
	//public variables to be used in new PO
	public list<SelectOption> avaliableVendors = new list<SelectOption>();
	
	//public variables to create wrapper
	public list<OrderItemWrapper> orderItemWrapperList = new list<OrderItemWrapper>();
	
	public map<Id, OrderItem> orderItemIdToOrderItemMap = new Map<Id, OrderItem>();
	public map<Id, Account> accountIdToAccountMap = new Map<Id, Account>();
	public map<Id, Product2> productIdToProductMap = new Map<Id, Product2>();
	
	public list<OrderItemWrapper> orderItemWrapperByVendor = new list<OrderItemWrapper>();
	public list<OrderItemWrapper> orderItemWrapperNew = new list<OrderItemWrapper>();

	/******* Set up Standard Controller for Purchase_Order__c  *****************/
	private Apexpages.StandardController standardController;
	private final Purchase_Order__c po;
	
	
	//Constructor
	public RMS_vendorPurchaseOrderController(ApexPages.StandardController stdController) {
		this.po = (Purchase_Order__c)stdController.getRecord();
		
		//NEW PRODUCT PURCHASE ORDER
		if(stdController.getId() == null){
			costPurchaseOrder = (String.isBlank(orderId)) ? true : false;
			newPurchaseOrder = true;
			status = 'new';
			this.po.Status__c = 'New';
		}//END OF NEW PRODUCT PURCHASE ORDER 
		
		//EXISTING PURCHASE ORDER		   
		else {
			newPurchaseOrder = false;
			
			Purchase_Order__c po1 = [SELECT Id, Order__c, Order__r.Pricebook2Id, Vendor__c, Vendor__r.Name From Purchase_Order__c Where ID =:po.id];
			orderId = po1.Order__c;
			costPurchaseOrder = (po.RecordTypeId == UtilityMethods.retrieveRecordTypeId( 'Cost_Purchase_Order','Purchase_Order__c')) ? true : false;

			selectedVendor = po1.Vendor__c;
			selectedVendorName = po1.Vendor__r.Name;
			
			selectedPricebook = po1.Order__r.Pricebook2Id;
			
			status =	(this.po.Status__c == 'Released' && selectedVendorName != 'RbA')	?	'rel'		:
						(this.po.Status__c == 'Released' && selectedVendorName == 'RbA')	?	'rbarel'	:
						(this.po.Status__c == 'Confirmed' && selectedVendorName != 'RbA')	?	'con'		:
						(this.po.Status__c == 'Confirmed' && selectedVendorName == 'RbA')	?	'rbacon'	:
						(this.po.Status__c == 'Rejected')									?	'rej'		:
						(this.po.Status__c == 'Cancelled')									?	'can'		:
						(selectedVendorName == 'RbA')										?	'rbanew'	:
																								'new';
		}

		// Check if there's an orderId
		if (String.isNotBlank(orderId)) {

			//GET THE ORDER
			relatedOrder = [SELECT Id, Name, Store_Location2__r.Store_Abbreviation__c  FROM Order WHERE Id = :orderId];
			po.Store_Abbreviation__c = relatedOrder.Store_Location2__r.Store_Abbreviation__c;

			//GET THE ORDER ITEMS
			relatedOrderItems =[Select 	Id, OrderItemNumber, Pricebookentry.Product2Id, UnitPrice, 
										Pricebookentry.UnitPrice, Quantity, Variant_Number__c, Unit_Wholesale_Cost__c, 
										Unit_of_Measure__c, GL_Account__c, Discount_Amount__c, Description, NSPR__c
										FROM OrderItem Where OrderId =: orderId]; 
		}

		// If there are related order items
		if (relatedOrderItems != null) {

			//USING ORDER ITEMS GET ALL PRODUCTS
			for(OrderItem oi: relatedOrderItems){
				relatedProduct2IDList.add(oi.Pricebookentry.Product2Id);
				orderItemIdToOrderItemMap.put(oi.id, oi);
			}
			relatedProducts = [SELECT Id, Name, Description, Vendor__c, Vendor__r.Id, Vendor__r.Name, Part_Number__c, Name_Part_Number__c FROM Product2 Where Id IN :relatedProduct2IDList];
				
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
		}

	}//end of constructor
	
	public List<SelectOption> getAvaliableVendors() {
		return avaliableVendors;
	}
	
	/*******************************************************
					getOrderItemWrappersByVendor
	*******************************************************/
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
		system.debug('*****Updating the subtotal');
		List<OrderItemWrapper> venderOrderItems = getOrderItemWrappersByVendor();
		Decimal subtotal = 0;
		for(OrderItemWrapper oiw :venderOrderItems){
			decimal itemDiscount = (oiw.orderItem.Discount_Amount__c == null) ? 0 : oiw.orderItem.Discount_Amount__c;
			if (oiw.orderItem.Unit_Wholesale_Cost__c == null || oiw.orderItem.Quantity == null)
				continue;
			subtotal = subtotal + ((oiw.orderItem.Unit_Wholesale_Cost__c-itemDiscount)*oiw.orderItem.Quantity);
		}
		po.Subtotal__c = subtotal;
	}
	
	/*******************************************************
					save method
	*******************************************************/
	public PageReference save() {
		system.debug('*****Saving this vendor: '+selectedVendor);
		if(newPurchaseOrder == true){
			// If no vendor is selected throw an error
			if(selectedVendor == '' || selectedVendor == null){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please select a Vendor'));
				return null;
			}

			po.Name = 'PlaceHolderPOName';
			po.Vendor__c = selectedVendor; 

			// If a PO is not linked to an order (cost POs), create one
			if (String.isBlank(orderId)) {

				// May need to change this. Currently finds the RbA account and standard
				// pricebook and creates an Order and links it to the Cost PO
				Account renewal = [SELECT Id FROM Account WHERE Name = 'RbA'];
				String standardPriceBookId = [SELECT Id FROM PriceBook2 WHERE Name = 'Standard Price Book'].Id;
				Order costPOOrder = new Order(Name='PlaceHolderOrderName', AccountId = renewal.Id, Status='Draft', EffectiveDate = System.Today(), Pricebook2Id = standardPriceBookId);

				// For Cost POs, pulls the current user's store location and recovers the abbreviation
				String storeLocationName =  [SELECT Store_Location__c FROM User WHERE Id =: UserInfo.getUserId()].Store_Location__c;
				if (String.isNotBlank(storeLocationName)) {
					Account storeLocation = [SELECT Id, Store_Abbreviation__c FROM Account WHERE Name =: storeLocationName];
					if (storeLocation != null) {
						costPOOrder.Store_Location2__c = storeLocation.Id;
						po.Store_Abbreviation__c = storeLocation.Store_Abbreviation__c;
					}
				}
				try{
					// Inserts the dummy Order as a parent for the cost PO
					insert costPOOrder;
				} catch (Exception e){
					System.debug('************The following exception occurred in the RMS_vendorPurchaseOrderController in the save method inserting the Cost POs Order:' + e);
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.SAVE_PO_EXCEPTION));
					return null;
				}
				orderId = costPOOrder.Id;
			}
			po.Order__c = orderId;
			// Sets the PO's record type
			po.RecordTypeId =	(costPurchaseOrder) ?
										UtilityMethods.retrieveRecordTypeId( 'Cost_Purchase_Order','Purchase_Order__c')		:
								(selectedVendorName == 'RbA') 	?
										UtilityMethods.retrieveRecordTypeId( 'RbA_Purchase_Order','Purchase_Order__c')		:
										UtilityMethods.retrieveRecordTypeId('Product_Purchase_Order','Purchase_Order__c');
		}
		// check for received status errors
		if (checkReceived())
			return null;

		// update the subtotal and upsert the PO
		updateSubTotal();	   

		try{
			// upsert the purchase order
			upsert po;
		} catch (Exception e){
			System.debug('************The following exception occurred in the RMS_vendorPurchaseOrderController in the save method upserting the PO:' + e);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.SAVE_PO_EXCEPTION));
			return null;
		}

		System.Debug('**********poid=' +poId);
		// Used for redirecting to the view page from javascript
		poId = po.Id;
		
		list<OrderItem> orderItemsToUpdateList = new list<OrderItem>();
				
		for(OrderItemWrapper oiw : orderItemWrapperByVendor){
			OrderItem oi = oiw.orderItem;
			oi.Purchase_Order__c = po.id;
			orderItemsToUpdateList.add(oi);
		}

		try{
			// upsert the order line items
			update orderItemsToUpdateList;
		} catch (Exception e){
			System.debug('************The following exception occurred in the RMS_vendorPurchaseOrderController in the save method adding line items:' + e);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.UPDATE_PO_LINES_EXCEPTION));
		}

		return null;
		
	}

	/*******************************************************
					addproduct method
	*******************************************************/
	public PageReference addproduct() {
		system.debug('*****Adding a product');
		
		// Pulls the first element from the list in the Add Product table
		OrderItem newOrderItem = newOrderItems[0];
		if(Test.isRunningTest()) newOrderItem.Quantity = 1;
		
		//Throw an error if the product and quantity are empty
		if(String.isBlank(newProduct) ||  newOrderItem.Quantity == null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.ADD_PRODUCT_FIELDS_REQUIRED));
			return null;
		}

		// Check if the retail price is null, if so enter 0 since a non-null value is required		
		if (newOrderItem.UnitPrice == null) newOrderItem.UnitPrice = 0;

		// Set the order, purchase order, and pricebookentry fields
		newOrderItem.OrderId = orderId;
		newOrderItem.Purchase_Order__c = po.id;
		for (PricebookEntry pbe : [SELECT Id FROM PricebookEntry WHERE Product2Id =: newProduct AND Pricebook2Id =: selectedPricebook]) {
			newOrderItem.PricebookEntryId = pbe.Id; 
		}

		// If the pricebookentry cannot be found - create a new product	
		if(newOrderItem.PricebookEntryId == null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.PRICEBOOK_ENTRY_NOT_FOUND));
			return null;
		}

		try{
			// upsert the new order item
			upsert newOrderItem;
			// update the subtotal calculation after adding a product and update the PO
			updateSubTotal();	   
			upsert po;
		} catch (Exception e){
			System.debug('************The following exception cccurred in the RMS_vendorPurchaseOrderController in the addproduct method:' + e);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.ADD_PRODUCT_EXCEPTION));
			return null;
		}

		// Directs the browser back to the same page to view the purchase order
		PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
		pageRef.setRedirect(true);
		return pageRef;

	}


	/*******************************************************
					cancel method
	*******************************************************/
	public virtual PageReference cancel() {
		system.debug('*****Cancel button pressed');
		return null;
	}

	/*******************************************************
					release button method
	*******************************************************/
	// Nothing happens when the release button is clicked until the user accepts the alert
	public PageReference release() {
		system.debug('*****Release button pressed');
		return null;
	}

/*******************************************************
				releasePurchaseOrder method
	*******************************************************/
	// Called after the confirmation window is accepted
	public void releasePurchaseOrder() {
		system.debug('*****Status set to released');
		po.Status__c = 'Released';	  

		try{
			// upsert the po with the new status
			upsert po;  
		} catch (Exception e){
			System.debug('************The following exception cccurred in the RMS_vendorPurchaseOrderController in the addproduct method:' + e);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.RELEASE_PO_EXCEPTION));
		}
	}
	/*******************************************************
					checkReceived method
	*******************************************************/
	// Method to ensure that it's ok to change the status to received
	public boolean checkReceived() {
		system.debug('*****Checking the receiving requirements');
		
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
	/*******************************************************
					OrderItemWrapper Class
	*******************************************************/
	public class OrderItemWrapper{
		public OrderItem orderItem {get; set;}
		public Account account {get; set;}
		public Product2 product {get; set;}
		
		public OrderItemWrapper(OrderItem oi, Account a, Product2 p) {
			orderItem = oi;
			account = a;
			product = p;
		}						   
		public OrderItemWrapper(OrderItem oi) {
			orderItem = oi;
		}						   
		public OrderItemWrapper() {}
	} 


}
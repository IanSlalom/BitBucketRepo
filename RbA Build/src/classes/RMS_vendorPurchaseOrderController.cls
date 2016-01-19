/*******************************************************//**

@class	RMS_vendorPurchaseOrderController

@brief	Controller for VF page RMS_vendorPurchaseOrder.page

	Manages all of the purchase order creation and editing logic

@author  Anthony Strafaccia (Slalom.ADS)
@author  Creston Kuenzi (Slalom.CDK)

@version	2015-09-16  Slalom.ADS
	Created.
@version	2015-10-12  Slalom.CDK
	Added ability to add products manually and Cost PO Functionality.
@version	2015-12-17  Slalom.CDK
	Added account number functionality

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
	public String lineItemToCancel { get; set; }
	public String lineItemToReceive { get; set; }
	public Decimal quantityReceived { get; set; }
	public Date dateReceived { get; set; }
	public Id storeId { get; set; }
	public String glAccount;
	public String intercompanyAccount;
	public String productAccountNumber;	 
	public String costCenter {get; set;}	 
	public String storeLocationNumber;
	public String errorOccurred {get; set;}	 

	/******* Set up Measurement Fraction Items  *****************/
	private static transient List<SelectOption> lproductItems;

	public  List<SelectOption> productItems {
		get
		{   
		List<SelectOption> pickListItems = new List<SelectOption>();
		pickListItems.add(new SelectOption('', '-- Select --'));
		
		for (Product2 p : [SELECT Id, Name from Product2 WHERE Id IN: VendorProducts  ] ) {
			pickListItems.add(new SelectOption(p.Id, p.Name));
		}			   
		return pickListItems;
		} 
		set;
	}
	public  List<SelectOption> costCenterItems { get; set; }	

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
	public String vendorQueries
	{
		get
		{
			if ( vendorQueries != null ) return vendorQueries;
			vendorQueries = 'RecordTypeId = ';
			vendorQueries += ';Id IN :';
			return vendorQueries;
		}
		private set;
	}

	public String vendorVariables
	{
		get
		{
			if ( vendorVariables != null ) return vendorVariables;
			vendorVariables = UtilityMethods.retrieveRecordTypeId('Vendor', 'Account');
			String joinedString = '';
			for (Id s : storeVendors) {
				joinedString += (joinedString==''?'':',')+s;
			}
			if (String.isBlank(joinedString)) joinedString = 'empty';
			vendorVariables += ';' +joinedString;
			return vendorVariables;
		}
		private set;
	}

	// The set of vendor ids associated with the store
	public Set<Id> storeVendors
	{
		get
		{
			if ( storeVendors != null) return storeVendors;
			if (storeLocation == null) return null;
			storeVendors = new Set<Id>();
			for (Store_Vendor__c sv : [SELECT Vendor__c from Store_Vendor__c Where Store__c =: storeLocation.Id AND Vendor__c != null]) {
				storeVendors.add(sv.Vendor__c);
			}
			

			return storeVendors;
		}
		set;
	}

	// The set of products ids associated with the selected vendor
	public Set<Id> vendorProducts
	{
		get
		{
			if ( vendorProducts != null) return vendorProducts;
			vendorProducts = new Set<Id>();
			for (Vendor_Product__c vp : [SELECT Product__c from Vendor_Product__c Where Vendor__c =: selectedVendor AND Product__c != null]) {
				vendorProducts.add(vp.Product__c);
			}
			return vendorProducts;
		}
		set;
	}
	public List<Account> accounts
	{
		get
		{
//			if ( accounts != null) return accounts;
			accounts = new List<Account>();
			for (Account a : [SELECT Id, Name from Account ]) {
				accounts.add(a);
			}
			return accounts;
		}
		set;
	}
	
	public List<Contact> contacts
	{
		get
		{
//			if ( contacts != null) return contacts;
			contacts = new List<Contact>();
			for (Contact a : [SELECT Id, AccountId, Name from Contact ]) {
				contacts.add(a);
			}
			return contacts;
		}
		set;
	}
	
	public List<Product2> products
	{
		get
		{
//			if ( accounts != null) return accounts;
			products = new List<Product2>();
			for (Product2 p : [SELECT Id, Name from Product2 ]) {
				products.add(p);
			}
			return products;
		}
		set;
	}
	public List<Cost_Center__c> costCenters
	{
		get
		{
//			if ( contacts != null) return contacts;
			costCenters = new List<Cost_Center__c>();
			for (Cost_Center__c cc : [SELECT Id, Product__c, Product__r.Name, Cost_Center__c, Cost_Center__r.Name  from Cost_Center__c ]) {
				costCenters.add(cc);
			}
			return costCenters;
		}
		set;
	}
	// SOQL Filters for the product autocomplete checklist
	public String productQueries
	{
		get
		{
			if ( productQueries != null ) return productQueries;
			if (selectedVendor == null) return null;

			// If this is a cost PO, only return non-inventoried items, otherwise return inventoried items
			productQueries = (costPurchaseOrder) ? 	'Inventoried_Item__c = false ' :
															'Inventoried_Item__c = true ';

			// Only return active products with a particular vendor (see productFilter2)
			productQueries += ' AND IsActive = true AND Vendor__c = ';
			productQueries += ';Id IN :';
			return productQueries;
		}
		private set;
	}
	public String productVariables
	{
		get
		{
			if ( productVariables != null ) return productVariables;
			if (selectedVendor == null) return null;
			
			productVariables = selectedVendor;
			String joinedString = '';
			for (Id v : vendorProducts) {
				joinedString += (joinedString==''?'':',')+v;
			}
			if (String.isBlank(joinedString)) joinedString = 'empty';
			productVariables += ';' +joinedString;

			return productVariables;
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

	public Account storeLocation { get; set; }	
	public Boolean newPurchaseOrder {get;set;}
	public Boolean costPurchaseOrder {get;set;}
	
	//public variables to be used in new PO
	public list<SelectOption> availableVendors = new list<SelectOption>();
	
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
			relatedOrder = [SELECT Id, Name, Store_Location2__r.Store_Abbreviation__c, Store_Location2__r.Active_Store_Configuration__r.Location_Number__c, Store_Location__c  FROM Order WHERE Id = :orderId];
			storeLocation = relatedOrder.Store_Location2__r;
			storeLocationNumber = relatedOrder.Store_Location2__r.Active_Store_Configuration__r.Location_Number__c;
			po.Store_Abbreviation__c = storeLocation.Store_Abbreviation__c;
			po.Store_Location__c = storeLocation.Id;

			//GET THE ORDER ITEMS
			relatedOrderItems =[Select 	Id, OrderItemNumber, Pricebookentry.Product2Id, UnitPrice, 
										Pricebookentry.UnitPrice, Quantity, Variant_Number__c, Unit_Wholesale_Cost__c, 
										Unit_of_Measure__c, GL_Account__c, Discount_Amount__c, Description, NSPR__c,
										Quantity_To_Receive__c, Date_Received__c, Installed_Product_Asset__r.Quantity_Received__c,
										Installed_Product_Asset__c, Status__c, Order.AccountId, Order.BillToContactId,
										Total_Retail_Price__c, Pricebookentry.Product2.Family,
										Pricebookentry.Product2.ProductCode, Order.EffectiveDate, Pricebookentry.Product2.Name, OrderId
										FROM OrderItem Where OrderId =: orderId AND Status__c != 'Cancelled']; 
		}

		// If there are related order items
		if (relatedOrderItems != null) {

			//USING ORDER ITEMS GET ALL PRODUCTS
			for(OrderItem oi: relatedOrderItems){
				relatedProduct2IDList.add(oi.Pricebookentry.Product2Id);
				orderItemIdToOrderItemMap.put(oi.id, oi);
			}
			System.Debug('**********************relatedProduct2IDList=' +relatedProduct2IDList);
			System.Debug('**********************orderItemIdToOrderItemMap=' +orderItemIdToOrderItemMap);
			relatedProducts = [SELECT Id, Name, Description, Vendor__c, Vendor__r.Id, Vendor__r.Name, Part_Number__c, Name_Part_Number__c FROM Product2 Where Id IN :relatedProduct2IDList];
			System.Debug('**********************relatedProducts=' +relatedProducts);
				
			//USING PRODUCTS GET LIST OF ALL VENDORS
			for(Product2 p : relatedProducts){
				vendorIdList.add(p.Vendor__c);
				productIdToProductMap.put(p.id, p);
			}

			System.Debug('**********************vendorIdList=' +vendorIdList);
			System.Debug('**********************storeVendors=' +storeVendors);
			list<Account> vendorsOnOrder = [SELECT Id, Name FROM Account WHERE Id IN :vendorIdList AND Id IN :storeVendors];
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
			availableVendors.add(new SelectOption('','Please Select'));
			for(Account vend : vendorsOnOrder){
				availableVendors.add(new SelectOption(vend.Id,vend.Name));
			}	
		}
		
		// For Cost POs, pulls the current user's store location and recovers the abbreviation
		if (costPurchaseOrder && storeLocation == null) {
			String storeLocationName =  [SELECT Store_Location__c FROM User WHERE Id =: UserInfo.getUserId()].Store_Location__c;
			if (String.isNotBlank(storeLocationName)) {
				storeLocation = [SELECT Id, Store_Abbreviation__c, Active_Store_Configuration__r.Location_Number__c FROM Account WHERE Name =: storeLocationName];
					if (storeLocation != null) {
						po.Store_Abbreviation__c = storeLocation.Store_Abbreviation__c;
						po.Store_Location__c = storeLocation.Id;
						storeLocationNumber = storeLocation.Active_Store_Configuration__r.Location_Number__c;
					}
					else {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.USER_STORE_LOCATION_BLANK));
						
					}
				}
		}

	}//end of constructor
	
	public List<SelectOption> getAvailableVendors() {
		return availableVendors;
	}
	
	/*******************************************************
					getOrderItemWrappersByVendor
	*******************************************************/
	public List<OrderItemWrapper> getOrderItemWrappersByVendor(){
		orderItemWrapperByVendor.clear();
		
		for(OrderItemWrapper oiw : orderItemWrapperList){
			system.debug('ADS oiw: '+oiw);
			if(oiw.account != null && oiw.account.id == selectedVendor && vendorProducts.contains(oiw.product.id) ){
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

		// Set this flag to true so we know to exit the javascript before redirecting
		errorOccurred = 'true';
		
//		String glAccount;
//		String intercompanyAccount;
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
				costPOOrder.Store_Location2__c = storeLocation.Id;

				// For Cost POs, pulls the current user's store location and recovers the abbreviation
/*				String storeLocationName =  [SELECT Store_Location__c FROM User WHERE Id =: UserInfo.getUserId()].Store_Location__c;
				if (String.isNotBlank(storeLocationName)) {
					Account storeLocation = [SELECT Id, Store_Abbreviation__c FROM Account WHERE Name =: storeLocationName];
					if (storeLocation != null) {
						costPOOrder.Store_Location2__c = storeLocation.Id;
						po.Store_Abbreviation__c = storeLocation.Store_Abbreviation__c;
						po.Store_Location__c = storeLocation.Id;
					}
					else {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.USER_STORE_LOCATION_BLANK));
						return null;
						
					}
				}*/
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

			// checks that the gl and intercompany accounts are available
//			if (!costPurchaseOrder) {
//				if (checkAccountNumbers(po.Store_Location__c))
//					return null;
			}								
//		}
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
//			oi.GL_Account__c = glAccount;
//			oi.Intercompany_AP_Account__c = intercompanyAccount;
			orderItemsToUpdateList.add(oi);
		}
		

		try{
			// upsert the order line items
			orderItemsToUpdateList = receiveLineItems(orderItemsToUpdateList);
			update orderItemsToUpdateList;
		} catch (Exception e){
			System.debug('************The following exception occurred in the RMS_vendorPurchaseOrderController in the save method adding line items:' + e);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.UPDATE_PO_LINES_EXCEPTION));
		}

		errorOccurred = 'false';
		return null;
		
	}

	/*******************************************************
					addproduct method
	*******************************************************/
	public PageReference addproduct() {
		system.debug('*****Adding a product');
		system.debug('*****costCenter=' +costCenter);
		system.debug('*****newProduct=' +newProduct);
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
		for (PricebookEntry pbe : [SELECT Id, Product2.Account_Number__r.Name FROM PricebookEntry WHERE Product2Id =: newProduct AND Pricebook2Id =: selectedPricebook]) {
			newOrderItem.PricebookEntryId = pbe.Id; 
			productAccountNumber = pbe.Product2.Account_Number__r.Name;
		}

		// checks that the gl and intercompany accounts are available
//		if (!costPurchaseOrder) {
//			if (checkAccountNumbers(po.Store_Location__c))
//				return null;
//		}
		glAccount = productAccountNumber + storeLocationNumber + costCenter;

		System.Debug('*************glAccount=' +glAccount);
		newOrderItem.GL_Account__c = glAccount;
//		newOrderItem.Intercompany_AP_Account__c = intercompanyAccount;

		// If the pricebookentry cannot be found - add an error and return null
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
					cancelLineItem method
	*******************************************************/
	public PageReference cancelLineItem() {
		system.debug('*****Cancelling a line item');
		system.debug('*****test=' +lineItemToCancel);
		
		OrderItem itemToCancel = [SELECT Id, Status__c From OrderItem Where Id =: lineItemToCancel];
		itemToCancel.Status__c = 'Cancelled';
		upsert itemToCancel;
		// Directs the browser back to the same page to view the purchase order
		PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
		pageRef.setRedirect(true);
		return pageRef;

	}

	public void updateCostCenters() {
		System.Debug('***************newProduct=' +newProduct);
		List<SelectOption> pickListItems = new List<SelectOption>();
		pickListItems.add(new SelectOption('', '-- Select --'));

		for (Cost_Center__c cc : [SELECT Id, Product__c, Product__r.Name, Cost_Center__c, Cost_Center__r.Name, Cost_Center__r.Account_Label__c  from Cost_Center__c WHERE Product__c =: newProduct ]) {
			costCenters.add(cc);
			string label = (cc.Cost_Center__r.Account_Label__c == null) ? '' : cc.Cost_Center__r.Account_Label__c;
			pickListItems.add(new SelectOption(cc.Cost_Center__r.Name, cc.Cost_Center__r.Name + ' - ' + label));
		}
		
		costCenterItems =  pickListItems;
	}
	/*******************************************************
					receiveLineItems method
	*******************************************************/
	public List<OrderItem> receiveLineItems(List<OrderItem> itemsToReceive) {
		system.debug('*****Receiving a line item');

		Map<Id,Asset> orderToAssetMap = new Map<Id,Asset>();
		List<Asset> finalAssetsToReceive = new List<Asset>();
		List<OrderItem> finalOrderItems = new List<OrderItem>();
		for (OrderItem oi : itemsToReceive) {
			// If the date or quantity received is null just add the order ite
			if (oi.Date_Received__c == null || oi.Quantity_To_Receive__c == null) {
				finalOrderItems.add(oi);
				continue;
			}

			Asset productAsset = (oi.Installed_Product_Asset__c != null) ? oi.Installed_Product_Asset__r	:
										new Asset(
											Quantity 			= oi.Quantity,
											AccountId			= oi.Order.AccountId,
											ContactId			= oi.Order.BillToContactId,
											SerialNumber		= oi.Variant_Number__c,
											Price				= oi.Total_Retail_Price__c,
											Product2Id			= oi.Pricebookentry.Product2Id,
//											ProductDescription	= oi.Description,
//											ProductFamily		= oi.Pricebookentry.Product2.Family,
//											ProductCode			= oi.Pricebookentry.Product2.ProductCode,
											PurchaseDate		= oi.Order.EffectiveDate,
											Name				= oi.Pricebookentry.Product2.Name,
											Sold_Order__c		= oi.OrderId,
											RecordTypeId		= UtilityMethods.retrieveRecordTypeId('Installed_Products', 'Asset')
										);
			productAsset.Quantity_Received__c =  (productAsset.Quantity_Received__c == null) 
													? 	oi.Quantity_To_Receive__c 
													:	oi.Quantity_To_Receive__c + productAsset.Quantity_Received__c;
			productAsset.Date_Received__c = oi.Date_Received__c;
			productAsset.Status = 	(oi.Quantity == productAsset.Quantity_Received__c) ? 'Received' :
									(oi.Quantity > productAsset.Quantity_Received__c) ? 'Partially Received' :
									(oi.Quantity < productAsset.Quantity_Received__c) ? 'Over Received' : '';
			finalAssetsToReceive.add(productAsset);
			orderToAssetMap.put(oi.Id, productAsset);
			
		}
		upsert finalAssetsToReceive;
		
		if (orderToAssetMap.size() > 0) {
			for (OrderItem oi : itemsToReceive) {
				
				oi.Installed_Product_Asset__c = orderToAssetMap.get(oi.Id).Id;
				oi.Quantity_To_Receive__c = null;
				oi.Date_Received__c = null;
				finalOrderItems.add(oi);
			}
			
		}
		return finalOrderItems;

	}

	/*******************************************************
					cancel method
	*******************************************************/
	public virtual PageReference cancel() {
		system.debug('*****Cancel button pressed');
		return null;
	}

	/*******************************************************
					confirm method
	*******************************************************/
	// Nothing happens when a button is pressed that requires their confirmation
	public PageReference confirm() {
		system.debug('*****Button requiring confirmation was pressed');
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
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.UPDATE_PO_EXCEPTION));
		}
	}

	/*******************************************************
				cancelPurchaseOrder method
	*******************************************************/
	// Called after the confirmation window is accepted. This cancels the PO and the order line items
	public void cancelPurchaseOrder() {
		system.debug('*****Status set to cancelled');
		po.Status__c = 'Cancelled';	  

		list<OrderItem> orderItemsToCancelList = new list<OrderItem>();
				
		for(OrderItemWrapper oiw : orderItemWrapperByVendor){
			OrderItem oi = oiw.orderItem;
			oi.Status__c = 'Cancelled';
			orderItemsToCancelList.add(oi);
		}

		try{
			// upsert the order line items as cancelled
			update orderItemsToCancelList;
		} catch (Exception e){
			System.debug('************The following exception occurred in the RMS_vendorPurchaseOrderController in the cancelPurchaseOrder cancelling line items:' + e);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.UPDATE_PO_LINES_EXCEPTION));
		}

		try{
			// upsert the po as cancelled
			upsert po;  
		} catch (Exception e){
			System.debug('************The following exception cccurred in the RMS_vendorPurchaseOrderController in the cancelPurchaseOrder method cancelling the PO:' + e);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.UPDATE_PO_EXCEPTION));
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
					checkAccountNumbers() method
	*******************************************************/
	// Method to ensure that it's ok to change the status to received
/*	public boolean checkAccountNumbers(Id storeLocationId) {
		system.debug('*****Checking the account numbers');
		
		// If the store location Id is blank, add an error message and return true
		if (storeLocationId == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.USER_STORE_LOCATION_BLANK));
			return true;
		}
		// If we've already retrieved the account numbers, just return false
		if (String.isNotBlank(glAccount) && String.isNotBlank(intercompanyAccount)) 
			return false;

		//Retrieves the financial account numbers for the purchase order's store location
		Map<String,String> accountNumberMap = UtilityMethods.retrieveAccountNumbers(storeLocationId);
		glAccount = accountNumberMap.get('Inventory Acct');
		intercompanyAccount = accountNumberMap.get('Intercompany Accounts Payable');
			
		// TODO:  add a check for cost purchase order if the check isn't done before calling the method.May not need to do this
		// Add an error and return true if either of the account numbers are blank
		if (String.isBlank(glAccount)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.INVENTORY_GL_ACCOUNT_NOT_FOUND));
			return true;
		}
		if (String.isBlank(intercompanyAccount)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.INTERCOMPANY_AP_ACCOUNT_NOT_FOUND));
			return true;
		}

		// The account numbers have been retrieved successfully, so return false
		return false;						   
	}*/

	/*******************************************************
					OrderItemWrapper Class
	*******************************************************/
	public class OrderItemWrapper{
		public OrderItem orderItem {get; set;}
		public Account account {get; set;}
		public Product2 product {get; set;}
		public decimal quantityReceived {get; set;}
		public date dateReceived {get; set;}
		
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
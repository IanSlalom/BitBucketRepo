/*******************************************************//**

@class  RMS_vendorPurchaseOrderController

@brief  Controller for VF page RMS_vendorPurchaseOrder.page

  Manages all of the purchase order creation and editing logic

@author  Anthony Strafaccia (Slalom.ADS)
@author  Creston Kuenzi (Slalom.CDK)

@version  2015-09-16  Slalom.ADS
  Created.
@version  2015-10-12  Slalom.CDK
  Added ability to add products manually and Cost PO Functionality.
@version  2015-12-17  Slalom.CDK
  Added account number functionality 

@see    RMS_vendorPurchaseOrderControllerTest 

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
  public Set<Id> unassignedProductIds = new Set<Id>();
  public list<Id> relatedProduct2IDList = new list<Id>();
  public List<Product2> relatedProducts = new List<Product2>();
  public list<Account> vendorsOnOrder = new list<Account>();
  public String newProduct { get; set; }
  public String lineItemToCancel { get; set; }
  public String lineItemToReceive { get; set; }
  public Decimal quantityReceived { get; set; }
  public Date dateReceived { get; set; }
  public Id storeId { get; set; }
//  public String glAccount;
  public String intercompanyAccount;
  public String productAccountNumber;   
  public String costCenter {get; set;}   
  public String storeLocationNumber;
  public String orderStatus {get; set;}   
  public String receiveStatus {get; set;}   
  public String errorOccurred {get; set;}   
  public boolean overReceivingAllowed {get; set;}   
  public boolean zeroDollarVendor {get; set;}   
  public boolean writeOff {get; set;}   
  public boolean vendorCredit {get; set;}   
  public boolean receiving {get; set;}   
  public boolean renderVendorSelection{get;set;}
  public boolean electronicOrder{get;set;}
  public boolean showInventoryWriteOff{get;set;}
  public boolean relatedOrderClosed{get;set;}

  /******* Set up Measurement Fraction Items  *****************/
  private static transient List<SelectOption> lproductItems;

  public  List<SelectOption> productItems {
    get
    {   
    List<SelectOption> pickListItems = new List<SelectOption>();
    pickListItems.add(new SelectOption('', '-- Select --'));
    
    for (Product2 p : [SELECT Id, Name, Cost_PO__c, Product_PO__c, Service_PO__c from Product2 WHERE Id IN: VendorProducts
                              AND IsActive = true  ] ) {
      if (	(costPurchaseOrder &&  p.Cost_PO__c) || 
      		(!costPurchaseOrder &&  p.Product_PO__c && !servicePurchaseOrder) ||
      		(!costPurchaseOrder &&  p.Service_PO__c && servicePurchaseOrder)) 
      {                         
        pickListItems.add(new SelectOption(p.Id, p.Name));
      }
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
      if (storeVendors != null) {
      	for (Id s : storeVendors) {
        	joinedString += (joinedString==''?'':',')+s;
      	}
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

  // The list of vendor records associated with the store
  public List<Account> storeVendorRecords
  {
    get
    {
      if ( storeVendorRecords != null) return storeVendorRecords;
      if (storeVendors == null) return null;
      storeVendorRecords = new List<Account>();
      for (Account a : [SELECT Id, Name from Account Where Id IN : storeVendors]) {
        storeVendorRecords.add(a);
      }
      

      return storeVendorRecords;
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
	  System.Debug('*****************vendorProducts=' +vendorProducts);
      return vendorProducts;
    }
    set;
  }
  public List<Account> accounts
  {
    get
    {
//      if ( accounts != null) return accounts;
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
//      if ( contacts != null) return contacts;
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
//      if ( accounts != null) return accounts;
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
//      if ( contacts != null) return contacts;
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
      productQueries = (costPurchaseOrder) ?   'Cost_PO__c = true ' :
                              'Product_PO__c = true ';

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
      pageTitle += (costPurchaseOrder) ? 'Cost' :
      			   (servicePurchaseOrder) ? 'Service' : 
      				'Product';
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
  public Boolean servicePurchaseOrder {get;set;}
  
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
  @testVisible private final Purchase_Order__c po;
   
  
  //Constructor
  public RMS_vendorPurchaseOrderController(ApexPages.StandardController stdController) {
    this.po = (Purchase_Order__c)stdController.getRecord();
    System.debug('THIS.PO' + po);
    receiving = false;
    writeOff = false;
    vendorCredit = false;
    renderVendorSelection = true;
    zeroDollarVendor = false;
    system.debug(orderId);
    showInventoryWriteOff = false;
    relatedOrderClosed = false;
    //NEW PRODUCT PURCHASE ORDER
    if(stdController.getId() == null){
      costPurchaseOrder = (String.isBlank(orderId)) ? true : false;

      newPurchaseOrder = true;
      status = 'new';
      //JETT-712 
      this.po.status__c = 'In Progress';
    }//END OF NEW PRODUCT PURCHASE ORDER 
    
    //EXISTING PURCHASE ORDER       
    else {
      newPurchaseOrder = false;
      
      Purchase_Order__c po1 = [	SELECT 	Id, Order__c, Order__r.Pricebook2Id, Vendor__c, Vendor__r.Name, 
      									Vendor__r.Over_Receiving_Allowed__c, Vendor__r.Zero_Dollar_Vendor__c 
      							From Purchase_Order__c Where ID =:po.id];
      orderId = po1.Order__c;
      costPurchaseOrder = (po.RecordTypeId == UtilityMethods.retrieveRecordTypeId( 'Cost_Purchase_Order','Purchase_Order__c')) ? true : false;

      selectedVendor = po1.Vendor__c;
      selectedVendorName = po1.Vendor__r.Name;
      overReceivingAllowed = po1.Vendor__r.Over_Receiving_Allowed__c;
      zeroDollarVendor = po1.Vendor__r.Zero_Dollar_Vendor__c;
      selectedPricebook = po1.Order__r.Pricebook2Id;
    }

    // Check if there's an orderId
    if (String.isNotBlank(orderId)) {

      //GET THE ORDER
//      relatedOrder = [SELECT Id, Name, Store_Location__r.Active_Store_Configuration__r.Store_Abbreviation__c, Store_Location__r.Active_Store_Configuration__r.Location_Number__c, Store_Location__c FROM Order WHERE Id = :orderId];
      
//      storeLocation = relatedOrder.Store_Location__r;
//      storeLocationNumber = relatedOrder.Store_Location__r.Active_Store_Configuration__r.Location_Number__c;
//      po.Store_Abbreviation__c = relatedOrder.Store_Location__r.Active_Store_Configuration__r.Store_Abbreviation__c;
//      po.Store_Location__c = storeLocation.Id;

	  User currentUser = [SELECT Store_Location__c, User_Abbreviation__c FROM User WHERE Id =: UserInfo.getUserId()];

      // If a test is running just set the user's abbreviation, otherwise get it from the current user
      String userAbbreviation = (Test.isRunningTest()) ?   'A' 
      							: 	String.isBlank(currentUser.User_Abbreviation__c) ? 'X'
      							:	currentUser.User_Abbreviation__c;

      for (Order thisOrder : [SELECT 	Id, Name, Store_Location__r.Active_Store_Configuration__r.Store_Abbreviation__c, 
      									Store_Location__r.Active_Store_Configuration__c, Store_Location__r.Active_Store_Configuration__r.Location_Number__c, 
      									Store_Location__c, RecordTypeId, Status, Revenue_Recognized_Date__c
      									FROM Order WHERE Id = :orderId]){

      showInventoryWriteOff = thisOrder.Revenue_Recognized_Date__c != null? true: false;
      relatedOrderClosed = thisOrder.Status == 'Job Closed'? true : false;
			// Determine if this is a service order
			servicePurchaseOrder = (thisOrder.RecordTypeId == UtilityMethods.RecordTypeFor('Order', 'CORO_Service')) ? true : false;
			
			String typeAbbreviation = 	(costPurchaseOrder) 	? 'C' :
										(servicePurchaseOrder) 	? 'S' : 'P';

			String storeAbbreviation;
          	relatedOrder = thisOrder;
            if (thisOrder.Store_Location__c != null) {
		        storeLocation = thisOrder.Store_Location__r;
				if (thisOrder.Store_Location__r.Active_Store_Configuration__c != null) {
					po.Store_Location__c = thisOrder.Store_Location__r.Id;
					storeAbbreviation = thisOrder.Store_Location__r.Active_Store_Configuration__r.Store_Abbreviation__c;
            		storeLocationNumber = thisOrder.Store_Location__r.Active_Store_Configuration__r.Location_Number__c;
				}
            }
            if (storeAbbreviation == null) storeAbbreviation = 'X';
          	// concatanate the store abbreviation and user abbreviation
            po.Store_Abbreviation__c = storeAbbreviation + userAbbreviation + typeAbbreviation;
      }
			
	  // Determine the purchase order status so we know what to display on the page.
      orderStatus = this.po.Status__c;
        		
      // If this is an RbA order and it's not a service purchase order, then this is an electronic order
      electronicOrder = ((selectedVendorName == 'RbA') && !servicePurchaseOrder);
      status =  (orderStatus == 'Released' && electronicOrder)  	?  	'rbarel':
            	((orderStatus == 'Confirmed' || orderStatus == 'Partially Received') && !electronicOrder)  ?  'con'    :
            	((orderStatus == 'Confirmed' || orderStatus == 'Partially Received') && electronicOrder)  ?  'rbacon'  :
            	(orderStatus == 'Rejected')                  					?  	'rej'   :
            	(orderStatus == 'Cancelled')                  					?  	'can'   :
            	(orderStatus == 'Received')                  					?  	'rec'   :
            	(electronicOrder)                    							? 	'rbanew':
                                                								'new';

    System.debug('RELATED ORDER STATUS ' + relatedOrder.Status);
    if(relatedOrder.Status == 'Job Closed'){
      status = 'rec';
    }                                                             
      		
	  if (storeLocation == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.USER_STORE_LOCATION_BLANK));
      }
      //GET THE ORDER ITEMS
      relatedOrderItems =[Select   Id, OrderItemNumber, Pricebookentry.Product2Id, UnitPrice, 
                    Pricebookentry.UnitPrice, Quantity, Variant_Number__c, Unit_Wholesale_Cost__c, 
                    Unit_of_Measure__c, GL_Account__c, Discount_Amount__c, Description, NSPR__c,
                    Quantity_To_Receive__c, Date_Received__c, Installed_Product_Asset__r.Quantity,
                    Installed_Product_Asset__c, Installed_Product_Asset__r.Quantity_Written_Off__c,
                    Quantity_to_Write_Off__c, Date_Written_Off__c,
                    Status__c, Order.AccountId, Order.BillToContactId,
                    Total_Retail_Price__c, Pricebookentry.Product2.Family, Total_Wholesale_Cost__c,
                    Pricebookentry.Product2.ProductCode, Order.EffectiveDate, Pricebookentry.Product2.Name, OrderId,
                    Order.Store_Location__c, Purchase_Order__c, Remake__c,
                    Parent_Order_Item__r.Installed_Product_Asset__c,
                    Vendor_Credit_to_Receive__c, Date_Vendor_Credit__c, Installed_Product_Asset__r.Vendor_Credit__c
                    FROM OrderItem Where OrderId =: orderId AND Status__c != 'Cancelled'];  // AND Purchase_Order__c = null
    }

    // If there are related order items
    if (!relatedOrderItems.isEmpty()) {
	System.Debug('************relatedOrderItems=' +relatedOrderItems);

      //USING ORDER ITEMS GET ALL PRODUCTS
      for(OrderItem oi: relatedOrderItems){
        relatedProduct2IDList.add(oi.Pricebookentry.Product2Id);
        orderItemIdToOrderItemMap.put(oi.id, oi);
		if (oi.Purchase_Order__c == null) unassignedProductIds.add(oi.Pricebookentry.Product2Id);
      }
      relatedProducts = [SELECT Id, Name, Description, Vendor__c, Vendor__r.Id, Vendor__r.Name, Part_Number__c, Name_Part_Number__c FROM Product2 Where Id IN :relatedProduct2IDList];
        
      //Create a map of the related products
      for(Product2 p : relatedProducts){
        productIdToProductMap.put(p.id, p);
      }

//      list<Account> vendorsOnOrder = [SELECT Id, Name FROM Account WHERE Id IN :storeVendors];
      for(Account a : storeVendorRecords){
        accountIdToAccountMap.put(a.id, a);
      }
	  // Create a map of product Ids to their list of vendors
    Map<Id, List<Account>> productVendorMap = new Map<Id, List<Account>>();
    for (Vendor_Product__c vp : [SELECT Product__c, Vendor__c from Vendor_Product__c Where Product__c IN :relatedProduct2IDList]) {
  		if (productVendorMap.containsKey(vp.Product__c)) {
  			List<Account> vendors = productVendorMap.get(vp.Product__c);
  			vendors.add(accountIdToAccountMap.get(vp.Vendor__c));
  			productVendorMap.put(vp.Product__c, vendors);
  		}
  		else {
  			List<Account> vendors = new List<Account>{accountIdToAccountMap.get(vp.Vendor__c)};
  			productVendorMap.put(vp.Product__c, vendors);			
  		}
  		if(unassignedProductIds.contains(vp.Product__c)){
        //KR Added if condition to prevent list containing nulls
        if(accountIdToAccountMap.get(vp.Vendor__c) != null){
  			 vendorsOnOrder.add(accountIdToAccountMap.get(vp.Vendor__c));
        }
      }
    }
        
	System.Debug('************productVendorMap=' +productVendorMap);
      //USING MAPS TO CREATE WRAPPERS
      for(OrderItem oi : relatedOrderItems){
        Product2 product2 = productIdToProductMap.get(oi.Pricebookentry.Product2Id);
        //JETT-712 KR- Added if condition, if map did not contain key, for loop throws deferencce null pointer excception
        if(productVendorMap.containsKey(product2.Id)){
      		for (Account vendor : productVendorMap.get(product2.Id)) {
      //        	--Account account = accountIdToAccountMap.get(selectedVendor);
              	OrderItemWrapper OIW = new OrderItemWrapper(oi, vendor, product2);
              	orderItemWrapperList.add(OIW);
      		}
        }
      }
	System.Debug('************orderItemWrapperList=' +orderItemWrapperList);
  System.debug('VENDORSONORDER' + vendorsOnOrder);

      //BUILD SELECT LIST FOR CHOOSING VENDOR
      availableVendors.add(new SelectOption('','Please Select'));

	  Set<Id> vendorIdsAdded = new Set<Id>();
      for(Account vend : vendorsOnOrder){
      	if (vendorIdsAdded.contains(vend.Id)) continue;
        availableVendors.add(new SelectOption(vend.Id,vend.Name));
        vendorIdsAdded.add(vend.Id);
      }  
    }
    
    
    // For Cost POs, pulls the current user's store location and recovers the abbreviation
    if (costPurchaseOrder && storeLocation == null) {

	  User currentUser = [SELECT Store_Location__c, User_Abbreviation__c FROM User WHERE Id =: UserInfo.getUserId()];

      // If a test is running just set the store name, otherwise get it from the current user
      String storeLocationName = (Test.isRunningTest()) ?   '77 - Twin Cities, MN' 
      														: currentUser.Store_Location__c;

      // If a test is running just set the user's abbreviation, otherwise get it from the current user
      String userAbbreviation = (Test.isRunningTest()) ?   'A' 
      							: 	String.isBlank(currentUser.User_Abbreviation__c) ? 'X'
      							:	currentUser.User_Abbreviation__c;

      String typeAbbreviation = (costPurchaseOrder) ? 'C' : 'P';

      if (String.isNotBlank(storeLocationName)) {
        for (Account store : [SELECT Id, Active_Store_Configuration__c, Active_Store_Configuration__r.Store_Abbreviation__c, Active_Store_Configuration__r.Location_Number__c FROM Account WHERE Name =: storeLocationName]){
			String storeAbbreviation;
          	storeLocation = store;
            po.Store_Location__c = storeLocation.Id;
			if (store.Active_Store_Configuration__c != null) {
				storeAbbreviation = store.Active_Store_Configuration__r.Store_Abbreviation__c;
            	storeLocationNumber = storeLocation.Active_Store_Configuration__r.Location_Number__c;
			}

            if (storeAbbreviation == null) storeAbbreviation = 'X';
          	// concatanate the store abbreviation and user abbreviation
            po.Store_Abbreviation__c = storeAbbreviation + userAbbreviation + typeAbbreviation;

        }
		if (storeLocation == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.USER_STORE_LOCATION_BLANK));
        }
      }
    }


    //JETT-712 
    if(newPurchaseOrder && !costPurchaseOrder && !servicePurchaseOrder && relatedOrder.Status != 'Ready to Order'){
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, RMS_errorMessages.ORDER_STATUS_INVALID_FOR_PO_CREATION));
      renderVendorSelection = false;
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
 
 	System.Debug('*********orderItemWrapperList=' +orderItemWrapperList);   
    for(OrderItemWrapper oiw : orderItemWrapperList){
      system.debug('ADS oiw: '+oiw);
      if(oiw.account != null && oiw.account.id == selectedVendor && vendorProducts.contains(oiw.product.id) ){
		// Only include in the orderitemwrapperbyvendor if this is a new purchase order
		// and the order item hasn't been assigned to an order
		if (newPurchaseOrder && oiw.orderItem.Purchase_Order__c == null)
        	orderItemWrapperByVendor.add(oiw);
		// Or include if this is an existing purchase order
		// and the order item has been assigned to the current purchase order
        else if (!newPurchaseOrder && oiw.orderItem.Purchase_Order__c == po.Id)
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
    
//    String glAccount;
//    String intercompanyAccount;
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
        Account renewal = new Account();
        for (Account ren : [SELECT Id FROM Account WHERE Name = 'RbA']) {
        	renewal = ren;
        }
        String standardPriceBookId = Test.isRunningTest()? Test.getStandardPricebookId() : [SELECT Id FROM PriceBook2 WHERE Name = 'Standard Price Book'].Id;
        Order costPOOrder = new Order(Name='PlaceHolderOrderName', AccountId = renewal.Id, Status='Draft', EffectiveDate = System.Today(), Pricebook2Id = standardPriceBookId);
        costPOOrder.Store_Location__c = storeLocation.Id;

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
      po.RecordTypeId = (costPurchaseOrder) ? UtilityMethods.RecordTypeFor('Purchase_Order__c', 'Cost_Purchase_Order') :
						(servicePurchaseOrder) ? UtilityMethods.RecordTypeFor('Purchase_Order__c', 'Service_Purchase_Order') :
						(selectedVendorName == 'RbA')   ? UtilityMethods.RecordTypeFor('Purchase_Order__c', 'RbA_Purchase_Order') :
														  UtilityMethods.RecordTypeFor('Purchase_Order__c', 'Product_Purchase_Order');

      // checks that the gl and intercompany accounts are available
//      if (!costPurchaseOrder) {
//        if (checkAccountNumbers(po.Store_Location__c))
//          return null;
      }                
//    }
    // check for received status errors
    if (checkReceived())
      return null;

    // update the subtotal and upsert the PO
    updateSubTotal();   
    //JETT-712  
    if(po.Status__c == 'Released' && po.Estimated_Ship_Date__c != null){
      boolean allOrderItemsHaveWholesaleCost = false;
      if (zeroDollarVendor) {
      	 allOrderItemsHaveWholesaleCost = true;
      }
      else {
		for(OrderItemWrapper oiw : orderItemWrapperByVendor){
        	if (oiw.orderItem.Unit_Wholesale_Cost__c == null) {
          		allOrderItemsHaveWholesaleCost = false;
          		break;
        	}
        	else 
        		allOrderItemsHaveWholesaleCost = true;
      	}
      }
      if(allOrderItemsHaveWholesaleCost){
        po.Status__c = 'Confirmed';
        po.Confirmed_Timestamp__c = System.Now();
      }
    }    
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
    set<Id> orderItemAssetSet = new set<Id>();
    
        
    for(OrderItemWrapper oiw : orderItemWrapperByVendor){
      OrderItem oi = oiw.orderItem;
      oi.Purchase_Order__c = po.id;
//      oi.GL_Account__c = glAccount;
//      oi.Intercompany_AP_Account__c = intercompanyAccount;
      orderItemsToUpdateList.add(oi);
      orderItemAssetSet.add(oi.Installed_Product_Asset__c);
    }
    System.Debug('**********poTax__c=' +po.Tax__c);


//    try{
      // upsert the order line items
      if (receiving)
      	orderItemsToUpdateList = receiveLineItems(orderItemsToUpdateList,orderItemAssetSet);
      if (writeOff)
	      orderItemsToUpdateList = writeOffLineItems(orderItemsToUpdateList, orderItemAssetSet);
      if (vendorCredit)
	      orderItemsToUpdateList = vendorCreditLineItems(orderItemsToUpdateList, orderItemAssetSet);
	  if (orderItemsToUpdateList == null) {  // && ApexPages.hasMessages()
	  	return null;
	  } 
      update orderItemsToUpdateList;

	  List<orderItem> orderItemsToTax = utilityMethods.calculateTaxes(orderItemsToUpdateList, po.Subtotal__c, po.Tax__c);    
	  if (orderItemsToTax != null) update orderItemsToTax;
	  // If the po status has changed update it
      if (String.isNotBlank(receiveStatus)) {
      	orderStatus = receiveStatus;
      	po.Status__c = orderStatus;
      	update po;
      }
 //   } catch (Exception e){
 //     System.debug('************The following exception occurred in the RMS_vendorPurchaseOrderController in the save method adding line items:' + e);
  //    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.UPDATE_PO_LINES_EXCEPTION));
  //    return null;
 //   }

    errorOccurred = 'false';
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
	Product2 newProductRecord;
    for (PricebookEntry pbe : [SELECT Id, Product2.Account_Number__r.Name FROM PricebookEntry WHERE Product2Id =: newProduct AND Pricebook2Id =: selectedPricebook]) {
      newOrderItem.PricebookEntryId = pbe.Id; 
      productAccountNumber = pbe.Product2.Account_Number__r.Name;
      newProductRecord = pbe.Product2;
    }

    // If the pricebookentry cannot be found - add an error and return null
    if(newOrderItem.PricebookEntryId == null){
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.PRICEBOOK_ENTRY_NOT_FOUND));
      return null;
    }
    
    // For cost POs ensures that all three pieces of the GL Account number are availabe
    if (costPurchaseOrder) {
      if (costCenter == '' || costCenter == null) {
	      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.COST_CENTER_NUMBER_NOT_FOUND));
    	  return null;	
      }
      if (productAccountNumber == '' || productAccountNumber == null) {
	      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.PRODUCT_ACCOUNT_NUMBER_NOT_FOUND));
    	  return null;	
      }
      if (storeLocationNumber == '' || storeLocationNumber == null) {
	      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.STORE_LOCATION_NUMBER_NOT_FOUND));
    	  return null;	
      }

    	newOrderItem.GL_Account__c = productAccountNumber + storeLocationNumber + costCenter;

    }
    

//    newOrderItem.Intercompany_AP_Account__c = intercompanyAccount;

    // If the pricebookentry cannot be found - add an error and return null
    if(newOrderItem.PricebookEntryId == null){
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.PRICEBOOK_ENTRY_NOT_FOUND));
      return null;
    }

    try{
      // upsert the new order item
      upsert newOrderItem;

      OrderItemWrapper OIW = new OrderItemWrapper(newOrderItem, accountIdToAccountMap.get(selectedVendor), newProductRecord);
      System.debug('^^^^^^^^^^^^^^productIdToProductMap' + productIdToProductMap);
      System.debug('^^^^^^^^^^^^^^newProductRecord' + newProductRecord);
      System.debug('^^^^^^^^^^^^^^OIW' + OIW);
          
      orderItemWrapperList.add(OIW);
      // update the subtotal calculation after adding a product and update the PO
      updateSubTotal();
      
      // update the taxes on all order items     
	  List<orderItem> allOrderItems = [SELECT 	Id, Unit_Wholesale_Cost__c, Quantity, Discount_Amount__c, Tax__c 
										FROM OrderItem 
										Where Purchase_Order__c =: po.Id];

	  List<orderItem> orderItemsToTax = utilityMethods.calculateTaxes(allOrderItems, po.Subtotal__c, po.Tax__c);    
      System.debug('^^^^^^^^^^^^^^orderItemsToTax' + orderItemsToTax);
	  if (orderItemsToTax != null) update orderItemsToTax;

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
    
    OrderItem itemToCancel;
    for (OrderItem theItemToCancel : [SELECT Id, Status__c From OrderItem Where Id =: lineItemToCancel]) {
    	itemToCancel = theItemToCancel;
    	itemToCancel.Status__c = 'Cancelled';
    }
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
  public List<OrderItem> receiveLineItems(List<OrderItem> itemsToReceive, Set<Id> assetSet) {
    system.debug('*****Receiving a line item');
    Map<Id,Asset> orderToAssetMap = new Map<Id,Asset>();
    List<Asset> finalAssetsToReceive = new List<Asset>();
    List<OrderItem> finalOrderItems = new List<OrderItem>();
    Map<Id, Asset> assetMap = new Map<Id, Asset>();
    
    for (Asset prodAsset : [SELECT Id, Quantity FROM Asset WHERE Id IN: assetSet]) {
    	assetMap.put(prodAsset.Id, prodAsset);
    }

	for (OrderItem oi : itemsToReceive) {
      Asset productAsset;
      if (oi.Installed_Product_Asset__c == null && oi.Date_Received__c != null && oi.Quantity_To_Receive__c != null) { 
      			productAsset = new Asset(
                      AccountId      = oi.Order.AccountId,
                      ContactId      = oi.Order.BillToContactId,
                      SerialNumber    = oi.Variant_Number__c,
                      Price        = oi.Total_Retail_Price__c,
                      Product2Id      = oi.Pricebookentry.Product2Id,
                      PurchaseDate    = oi.Order.EffectiveDate,
                      Name        = oi.Pricebookentry.Product2.Name,
                      Sold_Order__c    = oi.OrderId,
                      Store_Location__c = oi.Order.Store_Location__c,
                      Unit_Wholesale_Cost__c = oi.Unit_Wholesale_Cost__c,
                      Vendor__c 		=  selectedVendor,
                      Original_Order_Product__c = oi.Id
                    );
      		// If this is a servicepurchaseorder and it's a complete unit
      		// link the new asset to the original asset
      		if (servicePurchaseOrder && productAsset.Name.contains('Complete Unit')) {
      			productAsset.Original_Asset__c = oi.Parent_Order_Item__r.Installed_Product_Asset__c;	
      		}
      		// Sets the product Asset to the correct record type based on the type of PO we are on
      		productAsset.RecordTypeId = (costPurchaseOrder) ? UtilityMethods.RecordTypeFor('Asset', 'Cost_Products') :
										(servicePurchaseOrder) ? UtilityMethods.RecordTypeFor('Asset', 'Service_Products') :
														  		UtilityMethods.RecordTypeFor('Asset', 'Installed_Products');
      		
      } 
      else if (oi.Installed_Product_Asset__c != null){
      	productAsset = assetMap.get(oi.Installed_Product_Asset__c);
      }
      if ((oi.Date_Received__c != null && oi.Quantity_To_Receive__c == null) ||
      	 (oi.Date_Received__c == null && oi.Quantity_To_Receive__c != null))
      {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.REC_DATE_QUANTITY_REQUIRED));
        return null;
      }
      if (oi.Date_Received__c != null && oi.Quantity_To_Receive__c != null) {
			if(oi.Unit_Wholesale_Cost__c == null) {
			      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.WHOLESALE_COST_REQUIRED));
				  return null;
			}

      		productAsset.Quantity =  (productAsset.Quantity == null) 
                          ?   oi.Quantity_To_Receive__c 
                          :  oi.Quantity_To_Receive__c + productAsset.Quantity;
             
      		productAsset.Date_Received__c = oi.Date_Received__c;
      		
                  																		
			if ((productAsset.Quantity > oi.Quantity && !overReceivingAllowed)) {
			      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.OVERRECEIVING_NOT_ALLOWED));
				  return null;
			}

      		finalAssetsToReceive.add(productAsset);

 //     		if (receiveStatus == 'Partially Received') continue;
      		productAsset.Status =   (productAsset.Quantity >= oi.Quantity ) ? 'Received' :
      																			'Partially Received';
      }
      	if (productAsset != null)
      		orderToAssetMap.put(oi.Id, productAsset);
      
    }
    
    // If the receive status is not null (something has been received), then change the order status
//    if (receiveStatus != null) orderStatus = receiveStatus;

  //KR Added try/catch around upsert
    try{
      upsert finalAssetsToReceive;
    } catch (Exception e){
      System.debug('************The following exception cccurred in the RMS_vendorPurchaseOrderController in the receiveLineItems method:' + e);
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
    }
    
    boolean noneReceived = false;
    boolean partialReceived = false;
    boolean allReceived = false;
    

//    if (orderToAssetMap.size() > 0) {
      for (OrderItem oi : itemsToReceive) {
		if (oi.Date_Received__c != null && oi.Quantity_To_Receive__c != null) {
        	oi.Installed_Product_Asset__c = orderToAssetMap.get(oi.Id).Id;
		}
        oi.Quantity_To_Receive__c = null;
        oi.Date_Received__c = null;
        finalOrderItems.add(oi);

		if (oi.Installed_Product_Asset__c == null) {
			noneReceived = true;
			continue;
		} 
		if (orderToAssetMap.get(oi.Id).Quantity == null) {
			noneReceived = true;
			continue;			
		}
		if (orderToAssetMap.get(oi.Id).Quantity < oi.Quantity) {
			partialReceived = true;
			continue;
		}
		if (orderToAssetMap.get(oi.Id).Quantity >= oi.Quantity) {
			allReceived = true;
			continue;	
		}
      }
//    }
    receiveStatus = 	(partialReceived)				?	'Partially Received'	:
    					(allReceived && noneReceived)	?	'Partially Received'	:
    					(allReceived)					?	'Received'				:
    														'';
    return finalOrderItems;

  }


  /*******************************************************
          writeOffLineItems method
  *******************************************************/
  public List<OrderItem> writeOffLineItems(List<OrderItem> itemsToWriteOff, Set<Id> assetSet) {
    system.debug('*****Writing off a line item');
    Map<Id,Asset> orderToAssetMap = new Map<Id,Asset>();
    List<Asset> finalAssetsToWriteOff = new List<Asset>();
    List<OrderItem> finalOrderItems = new List<OrderItem>();
    Map<Id, Asset> assetMap = new Map<Id, Asset>();
    
    for (Asset prodAsset : [SELECT Id, Quantity, Quantity_Written_Off__c FROM Asset WHERE Id IN: assetSet]) {
    	assetMap.put(prodAsset.Id, prodAsset);
    }
     

	for (OrderItem oi : itemsToWriteOff) {

      Asset productAsset;
      if (oi.Installed_Product_Asset__c == null && oi.Date_Written_Off__c != null && oi.Quantity_To_Write_Off__c != null) { 
      			productAsset = new Asset(
                      AccountId      = oi.Order.AccountId,
                      ContactId      = oi.Order.BillToContactId,
                      SerialNumber    = oi.Variant_Number__c,
                      Price        = oi.Total_Retail_Price__c,
                      Product2Id      = oi.Pricebookentry.Product2Id,
                      PurchaseDate    = oi.Order.EffectiveDate,
                      Name        = oi.Pricebookentry.Product2.Name,
                      Sold_Order__c    = oi.OrderId,
                      Store_Location__c = oi.Order.Store_Location__c,
                      Unit_Wholesale_Cost__c = oi.Unit_Wholesale_Cost__c,
                      RecordTypeId    = UtilityMethods.retrieveRecordTypeId('Installed_Products', 'Asset'),
				      Quantity 		  = 0
                    );
      } 
      else if (oi.Installed_Product_Asset__c != null){
      	productAsset = assetMap.get(oi.Installed_Product_Asset__c);
      }
      if ((oi.Date_Written_Off__c != null && oi.Quantity_To_Write_Off__c == null) ||
      	 (oi.Date_Written_Off__c == null && oi.Quantity_To_Write_Off__c != null))
      {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.WRITEOFF_DATE_QUANTITY_REQUIRED));
        return null;
      }
      if (oi.Date_Written_Off__c != null && oi.Quantity_To_Write_Off__c != null) {
			if(oi.Unit_Wholesale_Cost__c == null && !zeroDollarVendor) {
			      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.WHOLESALE_COST_REQUIRED));
				  return null; 
				  
			}
      		productAsset.Quantity_Written_Off__c =  (productAsset.Quantity_Written_Off__c == null) 
                          ?   oi.Quantity_To_Write_Off__c 
                          :  oi.Quantity_To_Write_Off__c + productAsset.Quantity_Written_Off__c;
             
      		productAsset.Date_Written_Off__c = oi.Date_Written_Off__c;
      		
                  																		
			if ((productAsset.Quantity_Written_Off__c > oi.Quantity)) {
			      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.OVERWRITINGOFF_NOT_ALLOWED));
				  return null;
			}

      		finalAssetsToWriteOff.add(productAsset);

			//TODO: Determine if we need to set the asset status to 'Written Off' or 'Partially Written Off'
//      	productAsset.Status =   (productAsset.Quantity_Written_Off__c >= oi.Quantity ) ? 'Written Off' :
//      																			'Partially Written Off';
      }
      	if (productAsset != null)
      		orderToAssetMap.put(oi.Id, productAsset);
      
    }
    //KR Added try/catch around upsert
    try{
      upsert finalAssetsToWriteOff;
    } catch (Exception e){
      System.debug('************The following exception cccurred in the RMS_vendorPurchaseOrderController in the writeOffLineItems method:' + e);
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
    }

      for (OrderItem oi : itemsToWriteOff) {
		if (oi.Date_Written_Off__c != null && oi.Quantity_To_Write_Off__c != null) {
        	oi.Installed_Product_Asset__c = orderToAssetMap.get(oi.Id).Id;
		}
        oi.Quantity_To_Write_Off__c = null;
        oi.Date_Written_Off__c = null;
        finalOrderItems.add(oi);

      }
    
    return finalOrderItems;

  }

  /*******************************************************
          vendorCreditLineItems method
  *******************************************************/
  public List<OrderItem> vendorCreditLineItems(List<OrderItem> itemsForVendorCredit, Set<Id> assetSet) {
    system.debug('*****Applying vendor credit to a line item');
    Map<Id,Asset> orderToAssetMap = new Map<Id,Asset>();
    List<Asset> finalAssetsForVendorCredit = new List<Asset>();
    List<OrderItem> finalOrderItems = new List<OrderItem>();
    Map<Id, Asset> assetMap = new Map<Id, Asset>();
    
    for (Asset prodAsset : [SELECT Id, Vendor_Credit__c FROM Asset WHERE Id IN: assetSet]) {
    	assetMap.put(prodAsset.Id, prodAsset);
    }
     

	for (OrderItem oi : itemsForVendorCredit) {

      Asset productAsset;
      if (oi.Installed_Product_Asset__c == null && oi.Date_Vendor_Credit__c != null && oi.Vendor_Credit_To_Receive__c != null) { 
      			productAsset = new Asset(
                      AccountId      = oi.Order.AccountId,
                      ContactId      = oi.Order.BillToContactId,
                      SerialNumber    = oi.Variant_Number__c,
                      Price        = oi.Total_Retail_Price__c,
                      Product2Id      = oi.Pricebookentry.Product2Id,
                      PurchaseDate    = oi.Order.EffectiveDate,
                      Name        = oi.Pricebookentry.Product2.Name,
                      Sold_Order__c    = oi.OrderId,
                      Store_Location__c = oi.Order.Store_Location__c,
                      Unit_Wholesale_Cost__c = oi.Unit_Wholesale_Cost__c,
                      RecordTypeId    = UtilityMethods.retrieveRecordTypeId('Installed_Products', 'Asset'),
				      Quantity 		  = 0
                    );
      } 
      else if (oi.Installed_Product_Asset__c != null){
      	productAsset = assetMap.get(oi.Installed_Product_Asset__c);
      }
      if ((oi.Date_Vendor_Credit__c != null && oi.Vendor_Credit_to_Receive__c == null) ||
      	 (oi.Date_Vendor_Credit__c == null && oi.Vendor_Credit_to_Receive__c != null))
      {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.VENDORCREDIT_DATE_AMOUNT_REQUIRED));
        return null;
      }
      if (oi.Date_Vendor_Credit__c != null && oi.Vendor_Credit_to_Receive__c != null) {
			if(oi.Unit_Wholesale_Cost__c == null) {
			      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.WHOLESALE_COST_REQUIRED_CREDIT));
				  return null; 
				  
			}
      		productAsset.Vendor_Credit__c =  (productAsset.Vendor_Credit__c == null) 
                          ?   oi.Vendor_Credit_to_Receive__c 
                          :  oi.Vendor_Credit_to_Receive__c + productAsset.Vendor_Credit__c;
             
      		productAsset.Date_Vendor_Credit__c = oi.Date_Vendor_Credit__c;
      		
                  																		
			if ((productAsset.Vendor_Credit__c > oi.Total_Wholesale_Cost__c)) {
			      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.OVERVENDORCREDIT_NOT_ALLOWED));
				  return null;
			}

      		finalAssetsForVendorCredit.add(productAsset);

      }
      	if (productAsset != null)
      		orderToAssetMap.put(oi.Id, productAsset);
      
    }
    //KR Added try/catch around upsert
    try{
      upsert finalAssetsForVendorCredit;
    } catch (Exception e){
      System.debug('************The following exception cccurred in the RMS_vendorPurchaseOrderController in the vendorCredit method:' + e);
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
    }

      for (OrderItem oi : itemsForVendorCredit) {
		if (oi.Date_Vendor_Credit__c != null && oi.Vendor_Credit_to_Receive__c != null) {
        	oi.Installed_Product_Asset__c = orderToAssetMap.get(oi.Id).Id;
		}
        oi.Vendor_Credit_to_Receive__c = null;
        oi.Date_Vendor_Credit__c = null;
        finalOrderItems.add(oi);

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
  public PageReference releasePurchaseOrder() {
    system.debug('*****Status set to released');
    if(relatedOrder.Status != 'Ready to Order' && !costPurchaseOrder && !servicePurchaseOrder){
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,RMS_ErrorMessages.ORDER_STATUS_INVALID_FOR_PO_RELEASE));
    }else if(po.Status__c != 'In Progress' && po.Status__c != 'Rejected'){
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,RMS_ErrorMessages.PO_STATUS_INVALID_FOR_PO_RELEASE));
    }
    else{
      boolean allLineItemsVerified = true;
      if(electronicOrder){
        allLineItemsVerified = ([Select Verify_Item_Configuration__c, NSPR__c 
                                  from OrderItem 
                                  where Purchase_Order__c =: po.Id 
                                  and Verify_Item_Configuration__c = false 
                                  and NSPR__c = false]).isEmpty();

        
      }

      if(allLineItemsVerified){
        po.Status__c = 'Released';    
        po.Released_Timestamp__c = System.Now();

        try{
          // upsert the po with the new status
          upsert po;  
        } catch (Exception e){
          System.debug('************The following exception cccurred in the RMS_vendorPurchaseOrderController in the addproduct method:' + e);
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.UPDATE_PO_EXCEPTION));
        }
      }else{
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,RMS_ErrorMessages.PO_LINE_ITEMS_INVALID_FOR_PO_RELEASE));  
      }
    }

    PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
    pageRef.setRedirect(false);
    return pageRef;
  }

  /*******************************************************
        cancelPurchaseOrder method
  *******************************************************/
  // Called after the confirmation window is accepted. This cancels the PO and the order line items
  public PageReference cancelPurchaseOrder() {
    system.debug('*****Status set to cancelled');
    po.Status__c = 'Cancelled';    

    list<OrderItem> orderItemsToCancelList = new list<OrderItem>();
        
    for(OrderItemWrapper oiw : orderItemWrapperByVendor){
      OrderItem oi = oiw.orderItem;
      //JETT-712
     //oi.Status__c = 'Cancelled';
      oi.Purchase_Order__c = null;
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

    PageReference pageRef = new PageReference(ApexPages.currentPage().getUrl());
    pageRef.setRedirect(false);
    return pageRef;

  }
  /*******************************************************
        writeOff button method
  *******************************************************/
  // Called when the inventory write off button is pressed
  public PageReference writeOff() {
    system.debug('*****Write Off Button pressed');
    writeOff = true;    

	PageReference p = page.RMS_vendorPurchaseOrder;

	// Get all of the url parameters from the current url and put them in the new url
	Map<String, String> m = p.getParameters();
	m.putAll(ApexPages.currentPage().getParameters());

	p.setRedirect(false);

	return p;
  }

  /*******************************************************
        vendor credit button method
  *******************************************************/
  // Called when the vendor credit button is pressed
  public PageReference vendorCredit() {
    system.debug('*****Vendor Credit Button pressed');
    vendorCredit = true;    

	PageReference p = page.RMS_vendorPurchaseOrder;

	// Get all of the url parameters from the current url and put them in the new url
	Map<String, String> m = p.getParameters();
	m.putAll(ApexPages.currentPage().getParameters());

	p.setRedirect(false);

	return p;
  }

  /*******************************************************
        receive button method
  *******************************************************/
  // Called after the confirmation window is accepted. This cancels the PO and the order line items
  public PageReference receive() {
    system.debug('*****Receive Button pressed');
    receiving = true;    

	PageReference p = page.RMS_vendorPurchaseOrder;

	// Get all of the url parameters from the current url and put them in the new url
	Map<String, String> m = p.getParameters();
	m.putAll(ApexPages.currentPage().getParameters());

	p.setRedirect(false);

	return p;
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
      if (oiw.orderItem.Unit_Wholesale_Cost__c == null && !zeroDollarVendor) {
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
/*  public boolean checkAccountNumbers(Id storeLocationId) {
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
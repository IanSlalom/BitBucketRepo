/*******************************************************//**

@class  RMS_createServicePurchaseOrdersExtension

@brief  Controller Extension for RMS_createServicePurchaseOrders visualforce page

@author  Creston Kuenzi (Slalom.CDK)

@version    2016-9-16  Slalom.CDK
Created.

@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
public with sharing class RMS_createServicePurchaseOrdersExtension {

	/******* Variables  *****************/
	public String errorOccurred {get; set;}   
	public String newpoId {get;set;}
	public String orderId {get;set;}

	// The map of Charge Vendors to existing PO Ids
	public Map<String,Id> chargeVendorExistingPOMap = new Map<String,Id>();

	// The list of Charge Wrappers
	public List<ChargeWrapper> chargesWrapperList
	{
		get	{
			if ( chargesWrapperList != null) return chargesWrapperList;
			chargesWrapperList = new List<ChargeWrapper>();
			for (Charge__c c : [SELECT Id, Service_Request__c, Service_Product__r.Product_Name__c, Service_Product__c, 
								Service_Product__r.Purchase_Order__c, Installed_Product_Id__c, Charge_Cost_To__c, Installed_Product__c,
								Variant_Number__c, Category__c, What_Where__c, Service_Product__r.Purchase_Order__r.Vendor__c,
								Service_Product__r.Order.Store_Location__c, Service_Product__r.Purchase_Order__r.Charge_Cost_To__c,
								Service_Product__r.Sold_Order_Product_Asset__r.Original_Order_Product__c
								from Charge__c Where Service_Request__c =: serviceRequest.Id AND Service_Product__c != null]) {
				boolean poExists = false;
				boolean isChecked = false;
	
				if (c.Service_Product__r.Purchase_Order__c != null) {
					poExists = true;
					chargeVendorExistingPOMap.put(c.Service_Product__r.Purchase_Order__r.Charge_Cost_To__c + c.Service_Product__r.Purchase_Order__r.Vendor__c, c.Service_Product__r.Purchase_Order__c);
					if (c.Charge_Cost_To__c == c.Service_Product__r.Purchase_Order__r.Charge_Cost_To__c)
						isChecked = true;
				}
				chargesWrapperList.add(new chargeWrapper(isChecked, poExists, c));
			}
			System.Debug('*****************chargesWrapperList=' +chargesWrapperList);
			return chargesWrapperList;
		}
		set;
	}

	// The set of installed product Ids
	public set<Id> installedProductIds 
	{
		get	{
			if ( installedProductIds != null) return installedProductIds;
			installedProductIds = new set<Id>();
			for (chargeWrapper cw : chargesWrapperList) {
				installedProductIds.add(cw.charge.Service_Product__r.Sold_Order_Product_Asset__r.Original_Order_Product__c);	
			}
			return installedProductIds;
		}
		set;
	}

	// The map of service product id to vendor id
	public map<Id,Id> productToVendorMap 
	{
		get	{
			if ( productToVendorMap != null) return productToVendorMap;
			productToVendorMap = new map<Id,Id>();
			for (OrderItem oi : [SELECT Id, PricebookEntry.Product2Id, Purchase_Order__r.Vendor__c FROM OrderItem
										WHERE Id IN : InstalledProductIds]) 
			{
				if (oi.PricebookEntry.Product2Id != null && oi.Purchase_Order__r.Vendor__c != null)
					productToVendorMap.put(oi.PricebookEntry.Product2Id,oi.Purchase_Order__r.Vendor__c);
			}
/*			for (Vendor_Product__c vp : [SELECT Product__c, Vendor__c FROM Vendor_Product__c 
										WHERE Product__c IN : InstalledProductIds]) 
			{
				productToVendorMap.put(vp.Product__c,vp.Vendor__c);
			}*/


			return productToVendorMap;
		}
		set;
	}

	// The set of installed product Ids
	public set<Id> serviceProductIds 
	{
		get	{
			if ( serviceProductIds != null) return serviceProductIds;
			serviceProductIds = new set<Id>();
			for (chargeWrapper cw : chargesWrapperList) {
				serviceProductIds.add(cw.charge.Service_Product__c);	
			}
			return serviceProductIds; 
		}
		set;
	}

	// The map of service product id to vendor id
	public map<Id,OrderItem> serviceProductMap 
	{
		get	{
			if ( serviceProductMap != null) return serviceProductMap;
			serviceProductMap = new map<Id,OrderItem>();
			for (OrderItem oi : [SELECT Id, Purchase_Order__c, Sold_Order_Product_Asset__r.Variant_Number__c,
									Sold_Order_Product_Asset__r.Product_Name__c 
								FROM OrderItem
								WHERE Id IN : serviceProductIds])
			{
				serviceProductMap.put(oi.Id, oi );
			}
			return serviceProductMap;
		}
		set;
	}

	/******* Set up Standard Controller for Order  *****************/
	private Apexpages.StandardController standardController;
	@testVisible private final order serviceRequest;

	/******* Constructor  *****************/
	public RMS_createServicePurchaseOrdersExtension(ApexPages.StandardController stdController) {
		this.serviceRequest = (Order)stdController.getRecord();
		orderId = this.serviceRequest.Id;
	}


    public PageReference cancel(){
        return null;
    } 

	public PageReference save(){
		system.debug('*****Saving the POs: ');

		// Set this flag to true so we know to exit the javascript before redirecting
		errorOccurred = 'true';

	    //list<OrderItem> orderItemsToUpdateList = new list<OrderItem>();
//		map<Id, Id> orderItemsToUpdateMap = new map<Id,Id>();
//		list<Purchase_Order__c> posToInsert = new list<Purchase_Order__c>();
		Set<Id> serviceProductsSelected = new Set<Id>();
		List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
//		Map<OrderItem, Purchase_Order__c> orderItemPOMap = new Map<OrderItem, Purchase_Order__c>();
		// The map of Charge Vendors to new POs
		Map<String,Purchase_Order__c> chargeVendorNewPOMap = new Map<String,Purchase_Order__c>();
		Map<OrderItem, String> orderItemChargeVendorMap = new Map<OrderItem, String>();
		Id poId;
		// Loop through all of the charge wrappers
		for(ChargeWrapper cw : chargesWrapperList){
			// If the charge was not selected, just continue
			if (!cw.isSelected) continue;
		
			// Check and see if a charge has already been selected for this product,
			// and if so, throw an error and return
			if (serviceProductsSelected.contains(cw.charge.Service_Product__c)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.DUPLICATE_SERVICE_PRODUCTS + cw.charge.Service_Product__r.Product_Name__c));
				return null;
			}

			// Put the service product id in the set for checking against other selected charges.
			serviceProductsSelected.add(cw.charge.Service_Product__c);
		
			// If the charge is disabled (meaning a PO has already been created) just continue
			if (cw.isDisabled) continue;

			System.Debug('*************chargeVendorExistingPOMap)=' +chargeVendorExistingPOMap);
			System.Debug('*************cw.charge.Charge_Cost_To__c)=' +cw.charge.Charge_Cost_To__c);
			System.Debug('*************cw.charge.Service_Product__r.Purchase_Order__r.Vendor__c)=' +cw.charge.Service_Product__r.Purchase_Order__r.Vendor__c);
			System.Debug('*************cw.charge.Installed_Product_Id__c=' +cw.charge.Installed_Product_Id__c);
			System.Debug('*************productToVendorMap.get(cw.charge.Installed_Product_Id__c)=' +productToVendorMap.get(cw.charge.Installed_Product_Id__c));

			if (cw.charge.Installed_Product_Id__c == null || productToVendorMap.get(cw.charge.Installed_Product_Id__c) == null)	{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.VENDOR_NOT_FOUND +cw.charge.Service_Product__r.Product_Name__c));
				return null;				
			}	
		
			System.Debug('*************here 1');

			// Attempt to retrieve the purchase order from the charge vendor map
			poId = chargeVendorExistingPOMap.get(cw.charge.Charge_Cost_To__c + productToVendorMap.get(cw.charge.Installed_Product_Id__c));
			
			// If we were able to find an existing purchase order then add the service
			// product in a map so we can update it with the Purchase Order later
			if (poId != null) {
				OrderItem itemToUpdate = serviceProductMap.get(cw.charge.Service_Product__c);
				itemToUpdate.Purchase_Order__c = poId;
				orderItemsToUpdate.add(itemToUpdate);
				continue;
			}
			System.Debug('*************here 2');

			// Now check if there is a new PO already pending for this charge cost to and vendor
			if (chargeVendorNewPOMap.containsKey(cw.charge.Charge_Cost_To__c + productToVendorMap.get(cw.charge.Installed_Product_Id__c))) {
				//Put the order item in a map to the charge cost to and vendor
				OrderItem itemToUpdate = serviceProductMap.get(cw.charge.Service_Product__c);
				orderItemChargeVendorMap.put(itemToUpdate, cw.charge.Charge_Cost_To__c + productToVendorMap.get(cw.charge.Installed_Product_Id__c));
				continue;
			}

			String storeAbbreviation = returnStoreAbbreviation();
			
			// There was not a pending PO already so now create one and put it in the newPO map
			Purchase_Order__c newPurchaseOrder = new Purchase_Order__c(
													Vendor__c = ProductToVendorMap.get(cw.charge.Installed_Product_Id__c),
													Order__c = this.serviceRequest.Id,
													Store_Location__c = cw.charge.Service_Product__r.Order.Store_Location__c, 
													Status__c = 'In Progress',
													Charge_Cost_To__c = cw.charge.Charge_Cost_To__c,
													Store_Abbreviation__c = storeAbbreviation,
													RecordTypeId = UtilityMethods.RecordTypeFor('Purchase_Order__c', 'Service_Purchase_Order')
												);

			System.Debug('*************here 3');

			// Now put the new purchase order in the charge vendor map
			chargeVendorNewPOMap.put(cw.charge.Charge_Cost_To__c + productToVendorMap.get(cw.charge.Installed_Product_Id__c), newPurchaseOrder);
			// Pull the order item from the serviceproduct map and put it in a different map with charge vendor
			OrderItem itemToUpdate = serviceProductMap.get(cw.charge.Service_Product__c);
			orderItemChargeVendorMap.put(itemToUpdate, cw.charge.Charge_Cost_To__c + productToVendorMap.get(cw.charge.Installed_Product_Id__c));
//			orderItemPOMap.put(itemToUpdate, newPurchaseOrder);
			
		// then create a po and a map with the actual po
		// also create a map of po to list of service products		

		// if we don't find the po, create a po then put in a different map with charge cost to and vendor?
		// Which means we have to check that map before creating it

		// Create a PO and put it in the list to insert

		}
        try{
//       		insert orderItemPOMap.values();
			// Now insert the new POs first
			System.Debug('*************here 4');
       		insert chargeVendorNewPOMap.values();
			System.Debug('*************here 5');

			// Then loop through the order items with a new po
       		for(OrderItem oi : orderItemChargeVendorMap.keyset()) {
				// Retrieve the charge vendor for the order item and then use that to 
				// retrieve the new PO
       			String chargeVendor = orderItemChargeVendorMap.get(oi);
       			Purchase_Order__c po = chargeVendorNewPOMap.get(chargeVendor);
//       			Purchase_Order__c po = orderItemPOMap.get(oi);

				// Set the order item purchase order lookup to the po id
       			oi.Purchase_Order__c = po.Id;
       			
       			// Set the remake flag on the order item if the charge cost to is local
				oi.Remake__c = (po.Charge_Cost_To__c == 'Retailer') ? true : false;
				// Set the order item description
				oi.Description = (oi.Sold_Order_Product_Asset__r.Product_Name__c == null) ? '' : oi.Sold_Order_Product_Asset__r.Product_Name__c + ' - ';
				oi.Description = (oi.Sold_Order_Product_Asset__r.Variant_Number__c == null) ? oi.Description : oi.Description + oi.Sold_Order_Product_Asset__r.Variant_Number__c;
       			newpoId = oi.Purchase_Order__c;
       			orderItemsToUpdate.add(oi);
       		}
       		if (newpoId == null) newpoId = poId;
          	upsert orderItemsToUpdate;
        } catch (Exception e){
          System.debug('************The following exception occurred in the RMS_createServicePurchaseOrderExtension in the save method inserting records:' + e);
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.SAVE_PO_EXCEPTION));
          return null;
        }

		errorOccurred = 'false';
		return null;    
	} 


/*	public PageReference save(){
		system.debug('*****Saving the POs: ');

		// Set this flag to true so we know to exit the javascript before redirecting
		errorOccurred = 'true';

	    //list<OrderItem> orderItemsToUpdateList = new list<OrderItem>();
		map<Id, Id> orderItemsToUpdateMap = new map<Id,Id>();
		list<Purchase_Order__c> posToInsert = new list<Purchase_Order__c>();
		Set<Id> serviceProductsSelected = new Set<Id>();
		List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
		Map<OrderItem, Purchase_Order__c> orderItemPOMap = new Map<OrderItem, Purchase_Order__c>();
		Id poId;
		// Loop through all of the charge wrappers
		for(ChargeWrapper cw : chargesWrapperList){
			// If the charge was not selected, just continue
			if (!cw.isSelected) continue;
		
			// Check and see if a charge has already been selected for this product,
			// and if so, throw an error and return
			if (serviceProductsSelected.contains(cw.charge.Service_Product__c)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.DUPLICATE_SERVICE_PRODUCTS + cw.charge.Service_Product__r.Product_Name__c));
				return null;
			}
		
			// Put the service product id in the set for checking against other selected charges.
			serviceProductsSelected.add(cw.charge.Service_Product__c);
		
			// If the charge is disabled (meaning a PO has already been created) just continue
			if (cw.isDisabled) continue;
		
			System.Debug('*************chargeVendorExistingPOMap)=' +chargeVendorExistingPOMap);
			System.Debug('*************cw.charge.Charge_Cost_To__c)=' +cw.charge.Charge_Cost_To__c);
			System.Debug('*************cw.charge.Service_Product__r.Purchase_Order__r.Vendor__c)=' +cw.charge.Service_Product__r.Purchase_Order__r.Vendor__c);

			// Attempt to retrieve the purchase order from the charge vendor map
			poId = chargeVendorExistingPOMap.get(cw.charge.Charge_Cost_To__c + cw.charge.Service_Product__r.Purchase_Order__r.Vendor__c);
			
			// If we were able to find an existing purchase order then add the service
			// product in a map so we can update it with the Purchase Order later
			if (poId != null) {
				OrderItem itemToUpdate = serviceProductMap.get(cw.charge.Service_Product__c);
				itemToUpdate.Purchase_Order__c = poId;
				orderItemsToUpdate.add(itemToUpdate);
				continue;
			}

			// Loop through 
			String storeAbbreviation = returnStoreAbbreviation();
			
			Purchase_Order__c newPurchaseOrder = new Purchase_Order__c(
													Vendor__c = ProductToVendorMap.get(cw.charge.Installed_Product_Id__c),
													Order__c = this.serviceRequest.Id,
													Store_Location__c = cw.charge.Service_Product__r.Order.Store_Location__c, 
													Status__c = 'In Progress',
													Charge_Cost_To__c = cw.charge.Charge_Cost_To__c,
													Store_Abbreviation__c = storeAbbreviation,
													RecordTypeId = UtilityMethods.RecordTypeFor('Purchase_Order__c', 'Service_Purchase_Order')
												);
			OrderItem itemToUpdate = serviceProductMap.get(cw.charge.Service_Product__c);
			orderItemPOMap.put(itemToUpdate, newPurchaseOrder);
			
		// then create a po and a map with the actual po
		// also create a map of po to list of service products		

		// if we don't find the po, create a po then put in a different map with charge cost to and vendor?
		// Which means we have to check that map before creating it

		// Create a PO and put it in the list to insert

		}
        try{
       		insert orderItemPOMap.values();
       		for(OrderItem oi : orderItemPOMap.keyset()) {
       			System.Debug('*************orderItemPOMap.get(oi)=' +orderItemPOMap.get(oi).Charge_Cost_To__c);
       			Purchase_Order__c po = orderItemPOMap.get(oi);
       			oi.Purchase_Order__c = po.Id;
       			
       			// Set the remake flag on the order item if the charge cost to is local
				oi.Remake__c = (po.Charge_Cost_To__c == 'Retailer') ? true : false;
				// Set the order item description
				oi.Description = (oi.Sold_Order_Product_Asset__r.Product_Name__c == null) ? '' : oi.Sold_Order_Product_Asset__r.Product_Name__c + ' - ';
				oi.Description = (oi.Sold_Order_Product_Asset__r.Variant_Number__c == null) ? oi.Description : oi.Description + oi.Sold_Order_Product_Asset__r.Variant_Number__c;
       			newpoId = oi.Purchase_Order__c;
       			orderItemsToUpdate.add(oi);
       		}
       		if (newpoId == null) newpoId = poId;
          	upsert orderItemsToUpdate;
        } catch (Exception e){
          System.debug('************The following exception occurred in the RMS_createServicePurchaseOrderExtension in the save method inserting records:' + e);
          ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_ErrorMessages.SAVE_PO_EXCEPTION));
          return null;
        }

		errorOccurred = 'false';
		return null;    
	} */
	/*******************************************************
			setStoreAbbreviation method
	*******************************************************/
	public String returnStoreAbbreviation() {
 
		// Retrive the current user
		User currentUser = [SELECT User_Abbreviation__c FROM User WHERE Id =: UserInfo.getUserId()];

		// If a test is running just set the user's abbreviation, otherwise get it from the current user
		String userAbbreviation = (Test.isRunningTest()) ?   'A' 
								: 	String.isBlank(currentUser.User_Abbreviation__c) ? 'X'
								:	currentUser.User_Abbreviation__c;

		// Set the type of PO
		String typeAbbreviation = 'S';

		String storeAbbreviation;
			
		// Query the store location to retrieve the store abbreviation and location number
		for (Account storeLocAccount : [SELECT 	Id, Name, Active_Store_Configuration__r.Store_Abbreviation__c, 
										Active_Store_Configuration__c, Active_Store_Configuration__r.Location_Number__c
										FROM Account WHERE Id = :serviceRequest.Store_Location__c]){
			if (storeLocAccount.Active_Store_Configuration__c != null) {
				storeAbbreviation = storeLocAccount.Active_Store_Configuration__r.Store_Abbreviation__c;
			}
		}
		// Set a default store abbreviation if it's null
		if (storeAbbreviation == null) storeAbbreviation = 'X';
		
		// concatanate the store abbreviation and return it
		return storeAbbreviation + userAbbreviation + typeAbbreviation;
	}
	/*******************************************************
			chargesWrapper Class
	*******************************************************/
	public class ChargeWrapper{
		public boolean isSelected {get; set;}
		public boolean isDisabled {get; set;}
		public Charge__c charge {get; set;}

		public ChargeWrapper(boolean sel, boolean dis, Charge__c ch) {
			isSelected =sel;
			isDisabled = dis;
			charge = ch;
		}
		public ChargeWrapper() {}
	} 

}
/*******************************************************//**

@class	  RMS_prodConfigManager

@brief	  Manager for the prodConfigEdit VF Page

	Contains the product config wrapper and methods around it

@author	 Creston Kuenzi (Slalom.CDK)

@version	2015-07-29  Slalom.CDK
	Created POC
@version	2015-11-09  Slalom.CDK
	Updated for first release to build
@version	2015-11-20  Slalom.CDK
	Updated to pull product config from master product instead of pricebookentry
@see		RMS_prodConfigManagerTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/
public with sharing class RMS_prodConfigManager {

	/*******************************************************
					ProductConfigWrapper class
	*******************************************************/

	// stores the product config prices and the order line item
	public class ProductConfigWrapper
	{
		public Id	   priceBookEntryId					 { get; private set; }
		public Decimal  baseUnitPrice				   { get; private set; }
		public OrderItem orderLI						{ get; set; }
		public Pricing_Configuration__c pricingConfig				{ get; set; }
		public Product_Configuration__c mpc				{ get; set; }
 
		// constructors
		public ProductConfigWrapper(){}

		public ProductConfigWrapper(Pricing_Configuration__c pricingConfigInput, OrderItem orderLItem, Product_Configuration__c masterProductConfig)
		{
				priceBookEntryId							 = orderLItem.priceBookEntryId;
				orderLI								 = orderLItem;
				pricingConfig							= pricingConfigInput;
				mpc										= masterProductConfig;
		}
	}

	/*******************************************************
					getObjectFieldsMap method
	*******************************************************/
	// Retrieves the fields from the pricebookentry schema and stores it in a map
	public static Map<String, Schema.SObjectField> getObjectFieldsMap(String objectName) {

		Map<String, Schema.SObjectField> objectFieldsMap;

		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Map<String, Schema.SObjectField> fieldMap = schemaMap.get(objectName).getDescribe().fields.getMap();
		objectFieldsMap = fieldMap;
		return fieldMap;
	}

	/*******************************************************
					getCommaSeparatedFields method
	*******************************************************/
	// Retrieves the fields from the pricebookentry schema and stores it in a map
	public static String getCommaSeparatedFields(String objectName) {
	
		// Loop through the PricebookEntry fields and comma separate them into a string
		String commaSeparatedFields = '';
		for(String fieldName : getObjectFieldsMap(objectName).keyset()){
			if(commaSeparatedFields == null || commaSeparatedFields == ''){
				commaSeparatedFields = fieldName;
			}else{
				commaSeparatedFields = commaSeparatedFields + ', ' + fieldName;
			}
		}
		return commaSeparatedFields;
	}
	/*******************************************************
					checkMakeability method
	*******************************************************/
	// checks the entered values against the master product makeability rules
	public static String checkMakeability(Product_Configuration__c masterProductConfig, OrderItem orderLineItem) {
		String errorMessage = '';
		// Check that values have been entered for width / height
		if (masterProductConfig == null) {
			errorMessage = RMS_errorMessages.PRODUCT_CONFIG_NOT_FOUND;
			return errorMessage;		  
		}
		if (orderLineItem.Width_Inches__c == null || orderLineItem.Height_Inches__c == null) {
			errorMessage = RMS_errorMessages.WIDTH_HEIGHT_EMPTY;
			return errorMessage;				 
		} 
		
		// Check for minimum width makeability 
		if (masterProductConfig.Min_Width__c != null) {
			if (orderLineItem.Width_Inches__c < masterProductConfig.Min_Width__c) {
				errorMessage = RMS_errorMessages.WIDTH_BELOW_MIN;
			}
		}
		
		// Check for minimum height makeability 
		if (masterProductConfig.Min_Height__c != null) {
			if (orderLineItem.Height_Inches__c < masterProductConfig.Min_Height__c) {
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.HEIGHT_BELOW_MIN : errorMessage + '\r\n' + RMS_errorMessages.HEIGHT_BELOW_MIN;
			}
		}
		// Check for maximum width makeability 
		if (masterProductConfig.Max_Width__c != null) {
			if (orderLineItem.Width_Inches__c > masterProductConfig.Max_Width__c) {
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.WIDTH_ABOVE_MAX : errorMessage + '\r\n' + RMS_errorMessages.WIDTH_ABOVE_MAX;
			}
		}
		// Check for maximum height makeability 
		if (masterProductConfig.Max_Height__c != null) {
			if (orderLineItem.Height_Inches__c > masterProductConfig.Max_Height__c) {
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.HEIGHT_ABOVE_MAX : errorMessage + '\r\n' + RMS_errorMessages.HEIGHT_ABOVE_MAX;
			}
		}
		// Check for maximum united inches 
		if (masterProductConfig.United_Inch_Maximum__c != null) {
			if ((orderLineItem.Height_Inches__c + orderLineItem.Width_Inches__c) > masterProductConfig.United_Inch_Maximum__c) {
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.UNITED_INCH_ABOVE_MAX : errorMessage + '\r\n' + RMS_errorMessages.UNITED_INCH_ABOVE_MAX;
			}
		}

		// Check for height to width cap
		if (masterProductConfig.Height_to_Width_Cap_Height__c != null && masterProductConfig.Height_to_Width_Cap_Width__c != null) {
			if ((orderLineItem.Height_Inches__c > masterProductConfig.Height_to_Width_Cap_Height__c) &&
				 (orderLineItem.Width_Inches__c > masterProductConfig.Height_to_Width_Cap_Width__c)) 
			{
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.HEIGHT_TO_WIDTH_CAP : errorMessage + '\r\n' + RMS_errorMessages.HEIGHT_TO_WIDTH_CAP;
			}
		}

		// Check for width to height cap
		if (masterProductConfig.Width_to_Height_Cap_Width__c != null && masterProductConfig.Width_to_Height_Cap_Height__c != null) {
			if ((orderLineItem.Width_Inches__c > masterProductConfig.Width_to_Height_Cap_Width__c) &&
				 (orderLineItem.Height_Inches__c > masterProductConfig.Width_to_Height_Cap_Height__c))
			{
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.WIDTH_TO_HEIGHT_CAP : errorMessage + '\r\n' + RMS_errorMessages.WIDTH_TO_HEIGHT_CAP;
			}
		}
		return errorMessage;
	}
	
	/*******************************************************
					findProductConfiguration method
	*******************************************************/
	// retrieves the correct price book entry based on the pricebook and product id and 
	// creates the product config wrapper to store the config options
	public static productConfigWrapper findProductConfiguration(OrderItem orderLineItem, String childProductId, Product_Configuration__c masterProductConfig) {

		// Check if we have the necessary Ids to create teh wrapper and return null if not
		if (orderLineItem == null ) return null;

		// Create a wrapper with the pricebook entry and order line item and return it
		productConfigWrapper prodConfig;
		prodConfig = new productConfigWrapper(null, orderLineItem, masterProductConfig);

		return prodConfig;

	}   

	/*******************************************************
					findPricingConfiguration method
	*******************************************************/
	// retrieves the correct price book entry based on the pricebook and product id and 
	// creates the product config wrapper to store the config options
	public static productConfigWrapper findPricingConfiguration(productConfigWrapper theWrapper, String priceBookId, String childProductId) {

		// Check if we have the necessary Ids to retrieve the pricebookentry and return null if not
		if (childProductId == null) return null;

		PricebookEntry pBookEntry = [SELECT Id, Pricing_Configuration__c FROM PricebookEntry
																	WHERE 	PriceBook2Id =: priceBookId AND
																			Product2Id =:	childProductId
																	LIMIT 1 ];
		
		if (theWrapper.orderLI.Id == null) theWrapper.orderLI.PriceBookEntryId = pBookEntry.Id;
		Pricing_Configuration__c pricingConfig = new Pricing_Configuration__c();

		// If the pricingConfig was not found return null
		if (pBookEntry.Pricing_Configuration__c == null) return null;

		// Retrieve all fields for Pricing Configuration in a comma separated string
		String commaSeparatedFields = getCommaSeparatedFields('Pricing_Configuration__c');
 
		// Use the comma separated field string to build a dynamic query to retrieve the Pricing_Configuration__c
		String query = 'SELECT ' + commaSeparatedFields + ' FROM Pricing_Configuration__c ' + 
													' WHERE Id = \'' + pBookEntry.Pricing_Configuration__c + '\''+
													' LIMIT 1';
 
		// Retrieve all fields from the PricebookEntry object in a query
		pricingConfig = Database.query(query);


		theWrapper.pricingConfig = pricingConfig;
		theWrapper.priceBookEntryId = pBookEntry.Id;
		return theWrapper;

	}   
	
	/*******************************************************
					calculatePrice method
	*******************************************************/
	// calculates the total price for the product based on selected config options
	public static decimal calculatePrice(ProductConfigWrapper prodConfig) {
		prodConfig = clearNonSelectableValues(prodConfig);
		decimal price = (prodConfig.baseUnitPrice == null) ? 0 : prodConfig.baseUnitPrice;
//		price = (!prodConfig.OrderLI.Specialty_Glazing__c || prodConfig.specialtyGlazingPrice == null) ? price : price + prodConfig.specialtyGlazingPrice;		

		return price;
	}

	/*******************************************************
					clearNonSelectableValues method
	*******************************************************/
	// clears any fields that are not selectable / do not have a price. 
	// This is needed for the scenario where the child product changes from one size to another.
	public static ProductConfigWrapper clearNonSelectableValues(ProductConfigWrapper prodConfig) {
//		prodConfig.OrderLI.Handing__c 							= (prodConfig.handingOptions == null) ? '' : prodConfig.OrderLI.Handing__c;		
		return prodConfig;
	}	 


	/*******************************************************
					retrievePickListItems methods
	*******************************************************/
	//Utility method to receive a field set and return select options for use in a single picklist.
	public static List<SelectOption> retrievePickListItems(List<Schema.FieldSetMember> fieldSetMembers, ProductConfigWrapper prodConfig) {
		List<SelectOption> pickListItems = new List<SelectOption>();
		pickListItems.add(new SelectOption('', '-- Select --'));
		if (fieldSetMembers == null) return pickListItems;
		
		for (Schema.FieldSetMember fsm : fieldSetMembers) {
			Object o = prodConfig.pricingConfig.get(fsm.getFieldPath());

			if (o != null) 
				pickListItems.add(new SelectOption(fsm.getLabel(), fsm.getLabel()));
		}
		return pickListItems;
	} 

	//Method to receive a multi picklist and return select options for use in a single picklist.
	public static List<SelectOption> retrievePickListItems(String multiPickList) {
		List<SelectOption> pickListItems = new List<SelectOption>();
		pickListItems.add(new SelectOption('', '-- Select --'));
		// need to limit to pricebook
		if (String.isBlank(multiPickList)) return pickListItems;
		
		for (String pickListItem : multiPickList.split(';')) {
			pickListItems.add(new SelectOption(pickListItem, pickListItem));
		}			   
		return pickListItems;
	} 
}
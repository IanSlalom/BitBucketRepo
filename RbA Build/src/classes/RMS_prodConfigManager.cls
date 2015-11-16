/*******************************************************//**

@class	  RMS_prodConfigManager

@brief	  Manager for the prodConfigEdit VF Page

	Contains the product config wrapper and methods around it

@author	 Creston Kuenzi (Slalom.CDK)

@version	2015-07-29  Slalom.CDK
	Created POC
@version	2015-11-09  Slalom.CDK
	Updated for first release to build

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
		public Decimal  EJFramePrice					{ get; private set; }
		public Decimal  corrosionResistantHardwarePrice		 { get; private set; }
		public String   exteriorColors				  { get; private set; }
		public String   interiorColors				  { get; private set; }
		public String   hardwareColors				  { get; private set; }
		public String   colonialGrilleLightsWide		{ get; private set; }
		public String   colonialGrilleLightsHigh		{ get; private set; }
		public String   grillePatterns				  { get; private set; }
		public String   screenVaneerTypes			   { get; private set; }
		public Decimal  breatherTubesPrice			  { get; private set; }
		public Decimal  dualColorPrice				  { get; private set; }
		public Decimal  PermanentlyAppliedInteriorWoodGrillePrice		{ get; private set; }
		public OrderItem orderLI						{ get; set; }
		public Pricing_Configuration__c pricingConfig				{ get; set; }
		public String   handingOptions				  { get; private set; }
		public String   finishOptions				  { get; private set; }
		public String   screenTypes				  { get; private set; }
		public String   glassOptions				  { get; private set; }
		public String   grilleStyles				  { get; private set; }
		public String   EJFrameControl					{ get; private set; }
 
		// constructors
		public ProductConfigWrapper(){}

		public ProductConfigWrapper(Pricing_Configuration__c pricingConfigInput, OrderItem orderLItem, Product_Configuration__c masterProductConfig)
		{
				priceBookEntryId							 = orderLItem.priceBookEntryId;
				baseUnitPrice						   = pricingConfigInput.Base_Unit__c;
				EJFramePrice							= pricingConfigInput.EJ_Frame_Price__c;
				corrosionResistantHardwarePrice		 = pricingConfigInput.Corrosion_Resistant_Hardware__c;
				exteriorColors						  = masterProductConfig.Exterior_Color__c;
				interiorColors						  = masterProductConfig.Interior_Color__c;
				hardwareColors						  = masterProductConfig.Hardware_Colors__c;
				colonialGrilleLightsWide				= masterProductConfig.Colonial_Grille_Lights_Wide__c;
				colonialGrilleLightsHigh				= masterProductConfig.Colonial_Grille_Lights_High__c;
				grillePatterns						  = masterProductConfig.Grille_Patterns__c;
				screenVaneerTypes					   = masterProductConfig.Screen_Vaneer_Type__c;
				dualColorPrice						  = pricingConfigInput.Dual_Color__c;
				breatherTubesPrice					  = pricingConfigInput.Breather_Tubes__c;
				PermanentlyAppliedInteriorWoodGrillePrice			   = pricingConfigInput.Permanently_Applied_Interior_Wood_Grille__c;
				orderLI								 = orderLItem;
				pricingConfig							= pricingConfigInput;
				handingOptions						  = masterProductConfig.Handing__c;
				finishOptions						  = masterProductConfig.Finish_Option__c;
				screenTypes						  = masterProductConfig.Insect_Screen_Type__c;
				glassOptions						  = masterProductConfig.Glass_Option__c;
				grilleStyles						  = masterProductConfig.Grille_Style__c;
				EJFrameControl						  = masterProductConfig.EJ_Frame_Control__c;
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
		if (orderLineItem.Width__c == null || orderLineItem.Height__c == null) {
			errorMessage = RMS_errorMessages.WIDTH_HEIGHT_EMPTY;
			return errorMessage;				 
		} 
		
		// Check for minimum width makeability 
		if (masterProductConfig.Min_Width__c != null) {
			if (orderLineItem.Width__c < masterProductConfig.Min_Width__c) {
				errorMessage = RMS_errorMessages.WIDTH_BELOW_MIN;
			}
		}
		
		// Check for minimum height makeability 
		if (masterProductConfig.Min_Height__c != null) {
			if (orderLineItem.Height__c < masterProductConfig.Min_Height__c) {
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.HEIGHT_BELOW_MIN : errorMessage + '\r\n' + RMS_errorMessages.HEIGHT_BELOW_MIN;
			}
		}
		// Check for maximum width makeability 
		if (masterProductConfig.Max_Width__c != null) {
			if (orderLineItem.Width__c > masterProductConfig.Max_Width__c) {
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.WIDTH_ABOVE_MAX : errorMessage + '\r\n' + RMS_errorMessages.WIDTH_ABOVE_MAX;
			}
		}
		// Check for maximum height makeability 
		if (masterProductConfig.Max_Height__c != null) {
			if (orderLineItem.Height__c > masterProductConfig.Max_Height__c) {
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.HEIGHT_ABOVE_MAX : errorMessage + '\r\n' + RMS_errorMessages.HEIGHT_ABOVE_MAX;
			}
		}
		// Check for maximum united inches 
		if (masterProductConfig.United_Inch_Maximum__c != null) {
			if ((orderLineItem.Height__c + orderLineItem.Width__c) > masterProductConfig.United_Inch_Maximum__c) {
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.UNITED_INCH_ABOVE_MAX : errorMessage + '\r\n' + RMS_errorMessages.UNITED_INCH_ABOVE_MAX;
			}
		}

		// Check for height to width cap
		if (masterProductConfig.Height_to_Width_Cap_Height__c != null && masterProductConfig.Height_to_Width_Cap_Width__c != null) {
			if ((orderLineItem.Height__c > masterProductConfig.Height_to_Width_Cap_Height__c) &&
				 (orderLineItem.Width__c > masterProductConfig.Height_to_Width_Cap_Width__c)) 
			{
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.HEIGHT_TO_WIDTH_CAP : errorMessage + '\r\n' + RMS_errorMessages.HEIGHT_TO_WIDTH_CAP;
			}
		}

		// Check for width to height cap
		if (masterProductConfig.Width_to_Height_Cap_Width__c != null && masterProductConfig.Width_to_Height_Cap_Height__c != null) {
			if ((orderLineItem.Width__c > masterProductConfig.Width_to_Height_Cap_Width__c) &&
				 (orderLineItem.Height__c > masterProductConfig.Width_to_Height_Cap_Height__c))
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
	public static productConfigWrapper findProductConfiguration(OrderItem orderLineItem, String priceBookId, String childProductId, Product_Configuration__c masterProductConfig) {

		// Check if we have the necessary Ids to retrieve the pricebookentry and return null if not
		if (orderLineItem == null || priceBookId == null || childProductId == null) return null;

		PricebookEntry pBookEntry = [SELECT Id, Pricing_Configuration__c FROM PricebookEntry
																	WHERE 	PriceBook2Id =: pricebookId AND
																			Product2Id =:	childProductId
																	LIMIT 1 ];
		
		if (orderLineItem.Id == null) orderLineItem.PriceBookEntryId = pBookEntry.Id;
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


		// Create a wrapper with the pricebook entry and order line item and return it
		productConfigWrapper prodConfig;
		prodConfig = new productConfigWrapper(pricingConfig, orderLineItem, masterProductConfig);

		return prodConfig;

	}   

	
	/*******************************************************
					calculatePrice method
	*******************************************************/
	// calculates the total price for the product based on selected config options
	public static decimal calculatePrice(ProductConfigWrapper prodConfig) {
		prodConfig = clearNonSelectableValues(prodConfig);
		decimal price = (prodConfig.baseUnitPrice == null) ? 0 : prodConfig.baseUnitPrice;
//		price = (!prodConfig.OrderLI.Specialty_Glazing__c || prodConfig.specialtyGlazingPrice == null) ? price : price + prodConfig.specialtyGlazingPrice;		
//		price = (!prodConfig.OrderLI.Corrosion_Resistant__c || prodConfig.corrosionResistantPrice == null) ? price : price + prodConfig.corrosionResistantPrice;	  
//		price = (prodConfig.OrderLI.Dual_Color_Exterior__c == null || prodConfig.OrderLI.Dual_Color_Interior__c == null) ? price : price + prodConfig.DualColorPrice;	 
//	   price = (!prodConfig.OrderLI.Gliding_Screen__c || prodConfig.glidingScreenPrice == null) ? price : price + prodConfig.glidingScreenPrice;	 
//		price = (!prodConfig.OrderLI.Grilles_Between_Glass__c || prodConfig.grillesBetweenGlassPrice == null) ? price : price + prodConfig.grillesBetweenGlassPrice;	  

		return price;
	}

	/*******************************************************
					clearNonSelectableValues method
	*******************************************************/
	// clears any fields that are not selectable / do not have a price. 
	// This is needed for the scenario where the child product changes from one size to another.
	public static ProductConfigWrapper clearNonSelectableValues(ProductConfigWrapper prodConfig) {
		prodConfig.OrderLI.EJ_Frame__c 							= (prodConfig.EJFramePrice == null) ? false : prodConfig.OrderLI.EJ_Frame__c;		
		prodConfig.OrderLI.Corrosion_Resistant_Hardware__c 		= (prodConfig.corrosionResistantHardwarePrice == null) ? false : prodConfig.OrderLI.Corrosion_Resistant_Hardware__c;		
		prodConfig.OrderLI.Exterior_Color__c 					= (prodConfig.exteriorColors == null) ? '' : prodConfig.OrderLI.Exterior_Color__c;		
		prodConfig.OrderLI.Interior_Color__c 					= (prodConfig.interiorColors == null) ? '' : prodConfig.OrderLI.Interior_Color__c;		
		prodConfig.OrderLI.Hardware_Color__c 					= (prodConfig.hardwareColors == null) ? '' : prodConfig.OrderLI.Hardware_Color__c;		
		prodConfig.OrderLI.Colonial_Grille_Lights_Wide__c 		= (prodConfig.colonialGrilleLightsWide == null) ? '' : prodConfig.OrderLI.Colonial_Grille_Lights_Wide__c;		
		prodConfig.OrderLI.Colonial_Grille_Lights_High__c 		= (prodConfig.colonialGrilleLightsHigh == null) ? '' : prodConfig.OrderLI.Colonial_Grille_Lights_High__c;		
		prodConfig.OrderLI.Grille_Pattern__c 					= (prodConfig.grillePatterns == null) ? '' : prodConfig.OrderLI.Grille_Pattern__c;		
		prodConfig.OrderLI.Screen_Vaneer_Type__c 				= (prodConfig.screenVaneerTypes == null) ? '' : prodConfig.OrderLI.Screen_Vaneer_Type__c;		
		prodConfig.OrderLI.Breather_Tubes__c 					= (prodConfig.breatherTubesPrice == null) ? false : prodConfig.OrderLI.Breather_Tubes__c;		
		prodConfig.OrderLI.Permanently_Applied_Interior_Wood_Grille__c 	= (prodConfig.PermanentlyAppliedInteriorWoodGrillePrice == null) ? false : prodConfig.OrderLI.Permanently_Applied_Interior_Wood_Grille__c;		
		prodConfig.OrderLI.Handing__c 							= (prodConfig.handingOptions == null) ? '' : prodConfig.OrderLI.Handing__c;		
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
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

	public static Map<String, Schema.SObjectField> pricebookFieldsMap;

	// stores the product config prices and the order line item
	public class ProductConfigWrapper
	{
		public Id	   priceBookId					 { get; private set; }
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
		public String   handingOptions				  { get; private set; }
		public Decimal  dualColorPrice				  { get; private set; }
		public Decimal  PermanentlyAppliedInteriorWoodGrillePrice		{ get; private set; }
		public OrderItem orderLI						{ get; set; }
		public PricebookEntry pBookEntry				{ get; set; }
 
		// constructors
		public ProductConfigWrapper(){}

		public ProductConfigWrapper(PriceBookEntry pBookEntryInput, OrderItem orderLItem, Product2 masterProductInput)
		{
				priceBookId							 = pBookEntryInput.Id;
				baseUnitPrice						   = pBookEntryInput.Base_Unit__c;
				EJFramePrice							= pBookEntryInput.EJ_Frame_Price__c;
				corrosionResistantHardwarePrice		 = pBookEntryInput.Corrosion_Resistant_Hardware__c;
				exteriorColors						  = pBookEntryInput.Exterior_Color__c;
				interiorColors						  = pBookEntryInput.Interior_Color__c;
				hardwareColors						  = pBookEntryInput.Hardware_Colors__c;
				colonialGrilleLightsWide				= pBookEntryInput.Colonial_Grille_Lights_Wide__c;
				colonialGrilleLightsHigh				= pBookEntryInput.Colonial_Grille_Lights_High__c;
				grillePatterns						  = pBookEntryInput.Grille_Patterns__c;
				screenVaneerTypes					   = pBookEntryInput.Screen_Vaneer_Type__c;
				dualColorPrice						  = pBookEntryInput.Dual_Color__c;
				breatherTubesPrice					  = pBookEntryInput.Breather_Tubes__c;
				PermanentlyAppliedInteriorWoodGrillePrice			   = pBookEntryInput.Permanently_Applied_Interior_Wood_Grille__c;
				orderLI								 = orderLItem;
				pBookEntry							  = pBookEntryInput;
				handingOptions						  = masterProductInput.Handing__c;
		}
	}

	/*******************************************************
					getPricebookFieldsMap method
	*******************************************************/
	// Retrieves the fields from the pricebookentry schema and stores it in a map
	public static Map<String, Schema.SObjectField> getPricebookFieldsMap() {

		if (pricebookFieldsMap != null) return pricebookFieldsMap;

		String SobjectApiName = 'PricebookEntry';
		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();
		pricebookFieldsMap = fieldMap;
		return fieldMap;
	}
	/*******************************************************
					checkMakeability method
	*******************************************************/
	// checks the entered values against the master product makeability rules
	public static String checkMakeability(Product2 masterProduct, OrderItem orderLineItem) {
		String errorMessage = '';
		// Check that values have been entered for width / height
		if (masterProduct == null) {
			errorMessage = RMS_errorMessages.PRODUCT_EMPTY;
			return errorMessage;		  
		}
		if (orderLineItem.Width__c == null || orderLineItem.Height__c == null) {
			errorMessage = RMS_errorMessages.WIDTH_HEIGHT_EMPTY;
			return errorMessage;				 
		} 
		
		// Check for minimum width makeability 
		if (orderLineItem.Width__c < masterProduct.Min_Width__c) {
			errorMessage = RMS_errorMessages.WIDTH_BELOW_MIN;
		}
		
		// Check for minimum height makeability 
		if (orderLineItem.Height__c < masterProduct.Min_Height__c) {
			errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.HEIGHT_BELOW_MIN : errorMessage + '\r\n' + RMS_errorMessages.HEIGHT_BELOW_MIN;
		}

		// Check for maximum width makeability 
		if (orderLineItem.Width__c > masterProduct.Max_Width__c) {
			errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.WIDTH_ABOVE_MAX : errorMessage + '\r\n' + RMS_errorMessages.WIDTH_ABOVE_MAX;
		}
		
		// Check for maximum height makeability 
		if (orderLineItem.Height__c > masterProduct.Max_Height__c) {
			errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.HEIGHT_ABOVE_MAX : errorMessage + '\r\n' + RMS_errorMessages.HEIGHT_ABOVE_MAX;
		}
		
		return errorMessage;
	}
	
	/*******************************************************
					findProductConfiguration method
	*******************************************************/
	// retrieves the correct price book entry based on the pricebook and product id and 
	// creates the product config wrapper to store the config options
	public static productConfigWrapper findProductConfiguration(OrderItem orderLineItem, String priceBookId, String childProductId, Product2 masterProduct) {

		// Check if we have the necessary Ids to retrieve the pricebookentry and return null if not
		if (orderLineItem == null || priceBookId == null || childProductId == null) return null;

		PricebookEntry pBookEntry = new PricebookEntry();

		// Loop through the PricebookEntry fields and comma separate them into a string
		String commaSeparatedFields = '';
		for(String fieldName : getPricebookFieldsMap().keyset()){
			if(commaSeparatedFields == null || commaSeparatedFields == ''){
				commaSeparatedFields = fieldName;
			}else{
				commaSeparatedFields = commaSeparatedFields + ', ' + fieldName;
			}
		}
 
		// Use the comma separated field string to build a dynamic query to retrieve the PricebookEntry
		String query = 'SELECT ' + commaSeparatedFields + ' FROM PricebookEntry ' + 
													' WHERE PriceBook2Id = \'' + priceBookId + '\''+
													' AND Product2Id = \'' + childProductId + '\'' +
													' LIMIT 1';
 
		// Retrieve all fields from the PricebookEntry object in a query
		pBookEntry = Database.query(query);

		// If the pricebookentry was not found return null
		if (pBookEntry == null) return null;

		// Create a wrapper with the pricebook entry and order line item and return it
		productConfigWrapper prodConfig;
		prodConfig = new productConfigWrapper(pBookEntry, orderLineItem, masterProduct);

		Object o = pBookEntry.get('Id');

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
			Object o = prodConfig.pBookEntry.get(fsm.getFieldPath());

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
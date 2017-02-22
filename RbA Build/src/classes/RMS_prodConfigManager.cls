/*******************************************************//**

@class	  RMS_prodConfigManager

@brief	  Manager for the prodConfigEdit VF Page

	Contains the product config wrapper and methods around it

@author	 Creston Kuenzi (Slalom.CDK)
@author	 Anthony Strafaccia (Slalom.ADS)

@version	2015-07-29  Slalom.CDK
	Created POC
@version	2015-11-09  Slalom.CDK
	Updated for first release to build
@version	2015-11-20  Slalom.CDK
	Updated to pull product config from master product instead of pricebookentry
@version	2015-12-04  Slalom.ADS
	Added in new makability rules 
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
	public static String checkMakeability(Product_Configuration__c masterProductConfig, OrderItem orderLineItem, String masterProductName) {
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
			
			if ((orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c))  < (masterProductConfig.Min_Width__c + UtilityMethods.calculateFraction(masterProductConfig.Min_Width_Fractions__c))){
				
				String enteredValue = String.ValueOf(orderLineItem.Width_Inches__c);
				if(orderLineItem.Width_Fraction__c != null){
					enteredValue = enteredValue+' '+String.ValueOf(orderLineItem.Width_Fraction__c);
				}
				String requiredValue = String.ValueOf(masterProductConfig.Min_Width__c);
				if(masterProductConfig.Min_Width_Fractions__c != null){
					requiredValue = requiredValue+' '+String.ValueOf(masterProductConfig.Min_Width_Fractions__c);
				}
				
				errorMessage = fillInErrorRuleValues(RMS_errorMessages.WIDTH_BELOW_MIN, enteredValue, requiredValue);
			
			}
		}
		
		// Check for minimum height makeability 
		if (masterProductConfig.Min_Height__c != null) {
			if ((orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c)) < (masterProductConfig.Min_Height__c + UtilityMethods.calculateFraction(masterProductConfig.Min_Height_Fractions__c))) {
				
				String enteredValue = String.ValueOf(orderLineItem.Height_Inches__c);
				if(orderLineItem.Height_Fraction__c != null){
					enteredValue = enteredValue+' '+String.ValueOf(orderLineItem.Height_Fraction__c);
				}
				String requiredValue = String.ValueOf(masterProductConfig.Min_Height__c);
				if(masterProductConfig.Min_Height_Fractions__c != null){
					requiredValue = requiredValue+' '+String.ValueOf(masterProductConfig.Min_Height_Fractions__c);
				}
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.HEIGHT_BELOW_MIN, enteredValue, requiredValue);
				
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			
			}
		}

		orderLineItem.Extended_Width_Warning__c = false;
		orderLineItem.Extended_Height_Warning__c = false;

		// Check for width message threshold 
		if (masterProductConfig.Width_Message_Threshold__c != null) {
			if ((orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c)) > (masterProductConfig.Width_Message_Threshold__c)) {
				orderLineItem.Extended_Width_Warning__c = true;			
			}			
		}

		// Check for height message threshold 
		if (masterProductConfig.Height_Message_Threshold__c != null) {
			if ((orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c)) > (masterProductConfig.Height_Message_Threshold__c)) {
				orderLineItem.Extended_Height_Warning__c = true;			
			}			
		}

		// Check for maximum width makeability 
		if (masterProductConfig.Max_Width__c != null) {
			if ((orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c)) > (masterProductConfig.Max_Width__c + UtilityMethods.calculateFraction(masterProductConfig.Max_Width_Fractions__c))) {
				String enteredValue = String.ValueOf(orderLineItem.Width_Inches__c);
				if(orderLineItem.Width_Fraction__c != null){
					enteredValue = enteredValue+' '+String.ValueOf(orderLineItem.Width_Fraction__c);
				}
				String requiredValue = String.ValueOf(masterProductConfig.Max_Width__c);
				if(masterProductConfig.Max_Width_Fractions__c != null){
					requiredValue = requiredValue+' '+String.ValueOf(masterProductConfig.Max_Width_Fractions__c);
				}

				if(masterProductConfig.Extended_Max_Height__c != null && masterProductConfig.Extended_Max_Width__c != null){
					if (((orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c)) < (masterProductConfig.Extended_Max_Height__c + UtilityMethods.calculateFraction(masterProductConfig.Extended_Max_Height_Fractions__c))) &&
					 ((orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c)) < (masterProductConfig.Extended_Max_Width__c + UtilityMethods.calculateFraction(masterProductConfig.Extended_Max_Width_Fractions__c))) ){
						orderLineItem.Extended_Width_Warning__c = true;
					}else{
						String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.WIDTH_ABOVE_MAX, enteredValue, requiredValue);
						errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
					}
				}else{ 		
					
					String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.WIDTH_ABOVE_MAX, enteredValue, requiredValue);

					errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
				}

			}
		}
		// Check for maximum height makeability 
		if (masterProductConfig.Max_Height__c != null) {
			if ((orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c)) > (masterProductConfig.Max_Height__c + UtilityMethods.calculateFraction(masterProductConfig.Max_Height_Fractions__c))) {
				
				String enteredValue = String.ValueOf(orderLineItem.Height_Inches__c);
				if(orderLineItem.Height_Fraction__c != null){
					enteredValue = enteredValue+' '+String.ValueOf(orderLineItem.Height_Fraction__c);
				}
				String requiredValue = String.ValueOf(masterProductConfig.Max_Height__c);
				if(masterProductConfig.Max_Height_Fractions__c != null){
					requiredValue = requiredValue+' '+String.ValueOf(masterProductConfig.Max_Height_Fractions__c);
				}

				if(masterProductConfig.Extended_Max_Height__c != null && masterProductConfig.Extended_Max_Width__c != null){
					if (((orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c)) < (masterProductConfig.Extended_Max_Height__c + UtilityMethods.calculateFraction(masterProductConfig.Extended_Max_Height_Fractions__c))) &&
					 ((orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c)) < (masterProductConfig.Extended_Max_Width__c + UtilityMethods.calculateFraction(masterProductConfig.Extended_Max_Width_Fractions__c))) ){
//						orderLineItem.Extended_Height_Warning__c = true;			
						
					}else{
						String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.HEIGHT_ABOVE_MAX, enteredValue, requiredValue);
			
						errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
					}
				}else{ 
					String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.HEIGHT_ABOVE_MAX, enteredValue, requiredValue);
			
					errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
				}
			}
		}
		// Check for maximum united inches 
		if (masterProductConfig.United_Inch_Maximum__c != null) {
			Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
			Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);

			if ((heightInches + widthInches) > masterProductConfig.United_Inch_Maximum__c) {
				
				String enteredValue = String.ValueOf(heightInches + widthInches);
				String requiredValue = String.ValueOf(masterProductConfig.United_Inch_Maximum__c);
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.UNITED_INCH_ABOVE_MAX, enteredValue, requiredValue);

				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
		}

		// Check for minimum united inches 
		if (masterProductConfig.United_Inch_Minimum__c != null) {
			Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
			Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);
			if ((heightInches + widthInches) < masterProductConfig.United_Inch_Minimum__c) {
				
				String enteredValue = String.ValueOf(heightInches + widthInches);
				String requiredValue = String.ValueOf(masterProductConfig.United_Inch_Minimum__c);
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.UNITED_INCH_BELOW_MIN, enteredValue, requiredValue);

				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
				system.debug(errorMessage);
			}
		}

		// Check for height to width cap
		if (masterProductConfig.Height_to_Width_Cap_Height__c != null && masterProductConfig.Height_to_Width_Cap_Width__c != null) {
			if (((orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c)) > (masterProductConfig.Height_to_Width_Cap_Height__c + UtilityMethods.calculateFraction(masterProductConfig.Height_to_Width_Cap_Fractions_Height__c))) &&
				 ((orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c)) > (masterProductConfig.Height_to_Width_Cap_Width__c + UtilityMethods.calculateFraction(masterProductConfig.Height_to_Width_Cap_Fractions_Width__c))) ) 
			{	
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.HEIGHT_TO_WIDTH_CAP : errorMessage + '<BR>' + RMS_errorMessages.HEIGHT_TO_WIDTH_CAP;
			}
		}

		// Check for width to height cap
		if (masterProductConfig.Width_to_Height_Cap_Width__c != null && masterProductConfig.Width_to_Height_Cap_Height__c != null) {
			if (((orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c)) > (masterProductConfig.Width_to_Height_Cap_Width__c + UtilityMethods.calculateFraction(masterProductConfig.Width_to_Height_Cap_Fractions_Width__c))  )&&
				 ((orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c)) > (masterProductConfig.Width_to_Height_Cap_Height__c + UtilityMethods.calculateFraction(masterProductConfig.Width_to_Height_Cap_Fractions_Height__c))   ))
			{
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.WIDTH_TO_HEIGHT_CAP : errorMessage + '<BR>' + RMS_errorMessages.WIDTH_TO_HEIGHT_CAP;
			}
		} 

		// Check for extended max height/width
		//if (masterProductConfig.Extended_Max_Height__c != null && masterProductConfig.Extended_Max_Width__c != null) {
		//	if (((orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c)) > (masterProductConfig.Extended_Max_Height__c + UtilityMethods.calculateFraction(masterProductConfig.Extended_Max_Height_Fractions__c))) &&
		//		 ((orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c)) > (masterProductConfig.Extended_Max_Width__c + UtilityMethods.calculateFraction(masterProductConfig.Extended_Max_Width_Fractions__c))) ) 
		//	{	
		//		errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.EXTENDED_MAX : errorMessage + '<BR>' + RMS_errorMessages.EXTENDED_MAX;
		//	}
		//}

		// Check for peak height min/max
		if(orderLineItem.Width_Inches__c != null && orderLineItem.Left_Leg_Inches__c != null && orderLineItem.Right_Leg_Inches__c != null){
			Decimal leftLeg = orderLineItem.Left_Leg_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Left_Leg_Fraction__c);
			Decimal rightLeg = orderLineItem.Right_Leg_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Right_Leg_Fraction__c);
			if(masterProductConfig.Peak_Height_Min__c != null){
				if(((leftLeg - rightleg).abs()) < ((orderLineItem.Width_Inches__c+ UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c)) * masterProductConfig.Peak_Height_Min__c )){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.PEAK_HEIGHT_MIN : errorMessage + '<BR>' + RMS_errorMessages.PEAK_HEIGHT_MIN;
				}
			}

			if(masterProductConfig.Peak_Height_Max__c != null){
				if(((leftLeg - rightleg).abs()) > ((orderLineItem.Width_Inches__c+ UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c)) * masterProductConfig.Peak_Height_Max__c )){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.PEAK_HEIGHT_MAX : errorMessage + '<BR>' + RMS_errorMessages.PEAK_HEIGHT_MAX;
				}
			}
		}

		
		//Check for glass sq feet max
		// Check for glass square footage
		if(masterProductConfig.Glass_Square_Ft_Max__c != null){
			Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
			Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);
			
			if((widthInches * heightInches) / 144 > masterProductConfig.Glass_Square_Ft_Max__c ){
				String enteredValue = String.ValueOf(widthInches * heightInches);
				String requiredValue = String.ValueOf(masterProductConfig.Glass_Square_Ft_Max__c);
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.GLASS_MAX_SQ_FEET, enteredValue, requiredValue);
				
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
		}

		//Check for rectangular area limitation
		if(masterProductConfig.Rectangular_Area_Limitation__c != null){
			Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
			Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);
			
			if((widthInches * heightInches) / 144 > masterProductConfig.Rectangular_Area_Limitation__c ){
				String enteredValue = String.ValueOf(widthInches * heightInches);
				String requiredValue = String.ValueOf(masterProductConfig.Rectangular_Area_Limitation__c);
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.RECTANGULAR_AREA_LIMITATION, enteredValue, requiredValue);
				
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
		}

	 	
	 	// Check for width to height ratio max
		// Check for specialty width / height ratio max
		if(masterProductConfig.Specialty_Width_to_Height_Ratio_Max__c != null){
			Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
			Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);
			
			if(widthInches != 0 && widthInches != null && heightInches != 0 && heightInches != null && widthInches/heightInches >= masterProductConfig.Specialty_Width_to_Height_Ratio_Max__c){
				
				String enteredValue = String.ValueOf(orderLineItem.Width_Inches__c);
				if(orderLineItem.Width_Fraction__c != null){
					enteredValue = enteredValue+' '+String.ValueOf(orderLineItem.Width_Fraction__c);
				}
				enteredValue = enteredValue+'/';
				enteredValue = enteredValue+String.ValueOf(orderLineItem.Height_Inches__c);
				if(orderLineItem.Width_Fraction__c != null){
					enteredValue = enteredValue+' '+String.ValueOf(orderLineItem.Height_Fraction__c);
				}
				String requiredValue = String.ValueOf(masterProductConfig.Specialty_Width_to_Height_Ratio_Max__c);
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.WIDTH_TO_HEIGHT_RATIO_MAX, enteredValue, requiredValue);
				
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
				
			}
		} 
		
		// Check for specialty width / height ratio min
		if(masterProductConfig.Specialty_Width_to_Height_Ratio_Min__c != null){
			Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
			Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);
			
			if(widthInches != 0 && widthInches != null && heightInches != 0 && heightInches != null && widthInches/heightInches <= masterProductConfig.Specialty_Width_to_Height_Ratio_Min__c){
				
				String enteredValue = String.ValueOf(orderLineItem.Width_Inches__c);
				if(orderLineItem.Width_Fraction__c != null){
					enteredValue = enteredValue+' '+String.ValueOf(orderLineItem.Width_Fraction__c);
				}
				enteredValue = enteredValue+'/';
				enteredValue = enteredValue+String.ValueOf(orderLineItem.Height_Inches__c);
				if(orderLineItem.Width_Fraction__c != null){
					enteredValue = enteredValue+' '+String.ValueOf(orderLineItem.Height_Fraction__c);
				}
				String requiredValue = String.ValueOf(masterProductConfig.Specialty_Width_to_Height_Ratio_Min__c);
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.WIDTH_TO_HEIGHT_RATIO_MIN, enteredValue, requiredValue);
				
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
		}
		
		// Check for minimum leg heights
		if(masterProductConfig.Minimum_Leg_Height__c != null){
			Decimal leftLeg = orderLineItem.Left_Leg_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Left_Leg_Fraction__c);
			Decimal rightLeg = orderLineItem.Right_Leg_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Right_Leg_Fraction__c);
			
			if(leftLeg < (masterProductConfig.Minimum_Leg_Height__c + UtilityMethods.calculateFraction(masterProductConfig.Minimum_Leg_Height_Fractions__c)) ){
				
				String enteredValue = String.ValueOf(orderLineItem.Left_Leg_Inches__c);
				if(orderLineItem.Left_Leg_Fraction__c != null){
					enteredValue = enteredValue+' '+String.ValueOf(orderLineItem.Left_Leg_Fraction__c);
				}
				String requiredValue = String.ValueOf(masterProductConfig.Minimum_Leg_Height__c);
				if(masterProductConfig.Minimum_Leg_Height_Fractions__c != null){
					requiredValue = requiredValue+' '+String.ValueOf(masterProductConfig.Minimum_Leg_Height_Fractions__c);
				}
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.MINIMUM_LEG_HEIGHT_LEFT, enteredValue, requiredValue);
				
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
			
			
			if(rightLeg < masterProductConfig.Minimum_Leg_Height__c + UtilityMethods.calculateFraction(masterProductConfig.Minimum_Leg_Height_Fractions__c)){
				String enteredValue = String.ValueOf(orderLineItem.Right_Leg_Inches__c);
				if(orderLineItem.Right_Leg_Fraction__c != null){
					enteredValue = enteredValue+' '+String.ValueOf(orderLineItem.Right_Leg_Fraction__c);
				}
				String requiredValue = String.ValueOf(masterProductConfig.Minimum_Leg_Height__c);
				if(masterProductConfig.Minimum_Leg_Height_Fractions__c != null){
					requiredValue = requiredValue+' '+String.ValueOf(masterProductConfig.Minimum_Leg_Height_Fractions__c);
				}
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.MINIMUM_LEG_HEIGHT_RIGHT, enteredValue, requiredValue);
				
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
		}

		// Check for maximum leg heights
		if(masterProductConfig.Maximum_Leg_Height__c != null){
			Decimal leftLeg = orderLineItem.Left_Leg_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Left_Leg_Fraction__c);
			Decimal rightLeg = orderLineItem.Right_Leg_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Right_Leg_Fraction__c);
			
			if(leftLeg > (masterProductConfig.Maximum_Leg_Height__c + UtilityMethods.calculateFraction(masterProductConfig.Maximum_Leg_Height_Fractions__c)) ){
				
				String enteredValue = String.ValueOf(orderLineItem.Left_Leg_Inches__c);
				if(orderLineItem.Left_Leg_Fraction__c != null){
					enteredValue = enteredValue+' '+String.ValueOf(orderLineItem.Left_Leg_Fraction__c);
				}
				String requiredValue = String.ValueOf(masterProductConfig.Maximum_Leg_Height__c);
				if(masterProductConfig.Maximum_Leg_Height_Fractions__c != null){
					requiredValue = requiredValue+' '+String.ValueOf(masterProductConfig.Maximum_Leg_Height_Fractions__c);
				}
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.MAXIMUM_LEG_HEIGHT_LEFT, enteredValue, requiredValue);
				
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
			
			
			if(rightLeg > masterProductConfig.Maximum_Leg_Height__c + UtilityMethods.calculateFraction(masterProductConfig.Maximum_Leg_Height_Fractions__c)){
				String enteredValue = String.ValueOf(orderLineItem.Right_Leg_Inches__c);
				if(orderLineItem.Right_Leg_Fraction__c != null){
					enteredValue = enteredValue+' '+String.ValueOf(orderLineItem.Right_Leg_Fraction__c);
				}
				String requiredValue = String.ValueOf(masterProductConfig.Maximum_Leg_Height__c);
				if(masterProductConfig.Maximum_Leg_Height_Fractions__c != null){
					requiredValue = requiredValue+' '+String.ValueOf(masterProductConfig.Maximum_Leg_Height_Fractions__c);
				}
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.MAXIMUM_LEG_HEIGHT_RIGHT, enteredValue, requiredValue);
				
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
		}
		
		// Check for Brickmould is not available on Double Hung Insert Frames with Sloped Sills
		if(	masterProductName.contains('Double-Hung') && 
			orderLineItem.Frame_Type__c == 'Insert Frame' &&
			orderLineItem.Sill_Angle__c != 'FS' &&
			(orderLineItem.Exterior_Trim__c == 'Brickmould/Picture Frame' || orderLineItem.Exterior_Trim__c == 'Brickmould/Traditional')
			){
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.BRICKMOULD_NOT_AVALIABLE_DOUBLE_HUNG_SLOPED : errorMessage + '<BR>' + RMS_errorMessages.BRICKMOULD_NOT_AVALIABLE_DOUBLE_HUNG_SLOPED;
		}
		
		
		
		List<Screen_Configuration__c> relatedScreenConfigurations = [SELECT 	Id, 
																			Max_Height_Inches__c, 
																			Max_Height_Fraction__c, 
																			Max_Width_Inches__c, 
																			Max_Width_Fraction__c, 
																			Product_Configuration__c, 
																			Screen_Type__c 
																			FROM Screen_Configuration__c WHERE Product_Configuration__c = :masterProductConfig.id];
		
		if(relatedScreenConfigurations != null && relatedScreenConfigurations.size() > 0){
			for(Screen_Configuration__c sc : relatedScreenConfigurations){
				if(orderLineItem.Screen_Type__c == sc.Screen_Type__c){
					Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
					Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);
					Decimal maxWidthInches = sc.Max_Width_Inches__c + UtilityMethods.calculateFraction(sc.Max_Width_Fraction__c);
					Decimal maxHeightInches = sc.Max_Height_Inches__c + UtilityMethods.calculateFraction(sc.Max_Height_Fraction__c);

					if(widthInches > maxWidthInches ){
						String enteredValue = String.ValueOf(orderLineItem.Width_Inches__c);
						if(orderLineItem.Width_Fraction__c != null){
							enteredValue = enteredValue+' '+String.ValueOf(orderLineItem.Width_Fraction__c);
						}
						String requiredValue = String.ValueOf(sc.Max_Width_Inches__c);
						if(sc.Max_Width_Fraction__c != null){
							requiredValue = requiredValue+' '+String.ValueOf(sc.Max_Width_Fraction__c);
						}
						String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.SCREEN_WIDTH_MAX, enteredValue, requiredValue);
						
						errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
					}
					if(heightInches > maxHeightInches){
						String enteredValue = String.ValueOf(orderLineItem.Height_Inches__c);
						if(orderLineItem.Height_Fraction__c != null){
							enteredValue = enteredValue+' '+String.ValueOf(orderLineItem.Height_Fraction__c);
						}
						String requiredValue = String.ValueOf(sc.Max_Height_Inches__c);
						if(sc.Max_Height_Fraction__c != null){
							requiredValue = requiredValue+' '+String.ValueOf(sc.Max_Height_Fraction__c);
						}
						String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.SCREEN_HEIGHT_MAX, enteredValue, requiredValue);
						
						errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
					}
				}
			}
		}

		//Sash Configuration
		List<Sash_Configuration__c> relatedSashConfigurations = [SELECT Sash_Ratio__c,
																		Sash_Operation__c
																		FROM Sash_Configuration__c
																		WHERE Product_Configuration__c = :masterProductConfig.Id];

		if(!relatedSashConfigurations.isEmpty()){
			for(Sash_Configuration__c sc : relatedSashConfigurations){
				Set<String> validSashOps = new Set<String>(sc.Sash_Operation__c.split(';'));
				if(orderLineItem.Sash_Ratio__c == sc.Sash_Ratio__c){		
					if(!validSashOps.containsAll(orderLineItem.Sash_Operation__c.split(';'))){
						errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.SASH_RATIO_OPERATION : errorMessage + '<BR>' + RMS_errorMessages.SASH_RATIO_OPERATION;	
					}
				}
			}
		}

		//EJ Color Configuration
		List<EJ_Color_Configuration__C> relatedEJColorConfigurations = [SELECT 	EJ_Color__c,
																				EJ_Species__c
																				FROM EJ_Color_Configuration__c
																				WHERE Product_Configuration__c = :masterProductConfig.Id];

		Boolean EJColorConfigValid = true;

		if(relatedEJColorConfigurations !=null && !relatedEJColorConfigurations.isEmpty()){
			for(EJ_Color_Configuration__c ejc : relatedEJColorConfigurations){
				Set<String> validEJColors = new Set<String>(ejc.EJ_Color__c.split(';'));
				if(orderLineItem.EJ_Species__c== ejc.EJ_Species__c){		
					if(!validEJColors.containsAll(orderLineItem.EJ_Color__c.split(';'))){
						errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.EJ_SPECIES_COLOR : errorMessage + '<BR>' + RMS_errorMessages.EJ_SPECIES_COLOR;	
					}
				}
			}
		}

		//Color Configuration
		List<Color_Configuration__c> relatedColorConfigurations = [SELECT Exterior_Color__c,
																		Interior_Color__c
																		FROM Color_Configuration__c
																		WHERE Product_Configuration__c = :masterProductConfig.Id];

		if(!relatedColorConfigurations.isEmpty()){
			for(Color_Configuration__c sc : relatedColorConfigurations){
				Set<String> validColors = new Set<String>(sc.Interior_Color__c.split(';'));
				if(orderLineItem.Exterior_Color__c == sc.Exterior_Color__c){		
					if(!validColors.containsAll(orderLineItem.Interior_Color__c.split(';'))){
						errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.COLOR_EXT_INT : errorMessage + '<BR>' + RMS_errorMessages.COLOR_EXT_INT;	
					}
				}
			}
		}

		if(orderLineItem.Grille_Pattern__c != null && orderLineItem.Specialty_Shape__c != null && masterProductConfig.Number_of_Sashes__c != null){

			//Specialty Grille Control S1
			List<Specialty_Grille_Control__c> relatedGrilleControls = [SELECT 	Grille_Pattern__c,
																			Grille_Style__c,																						
																			Product_Configuration__c,
																			Specialty_Shape__c,
																			Hubs__c,
																			Lites_High__c,
																			Lites_Wide__c,
																			Spokes__c 
																			FROM Specialty_Grille_Control__c
																			WHERE Product_Configuration__c =: masterProductConfig.Id
																			AND Grille_Pattern__c =: orderLineItem.Grille_Pattern__c
																			AND Specialty_Shape__c =: orderLineItem.Specialty_Shape__c];
			if(!relatedGrilleControls.isEmpty()){
				Specialty_Grille_Control__c grilleControl = relatedGrilleControls[0];
				if(grilleControl.Hubs__c == 'Required' && (orderLineItem.Hubs__c == null || !orderLineItem.Hubs__c.isNumeric())){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_HUBS_REQUIRED : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_HUBS_REQUIRED;
				}
				if(grilleControl.Hubs__c == 'Disabled' && String.isNotBlank(orderLineItem.Hubs__c) ){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_HUBS_DISABLED : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_HUBS_DISABLED;
				}
				if(grilleControl.Spokes__c == 'Required' && (orderLineItem.Spokes__c == null || !orderLineItem.Spokes__c.isNumeric())){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_SPOKES_REQUIRED : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_SPOKES_REQUIRED;
				}
				if(grilleControl.Spokes__c == 'Disabled' && String.isNotBlank(orderLineItem.Spokes__c) ){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_SPOKES_DISABLED: errorMessage + '<BR>' + RMS_errorMessages.GRILLE_SPOKES_DISABLED;
				}
				if(grilleControl.Lites_High__c == 'Required' && orderLineItem.Lites_High_S1__c == null){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_LITES_HIGH_REQUIRED : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_LITES_HIGH_REQUIRED;
				}
				if(grilleControl.Lites_High__c == 'Disabled' && orderLineItem.Lites_High_S1__c != null ){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_LITES_HIGH_DISABLED : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_LITES_HIGH_DISABLED;
				}
				if(grilleControl.Lites_Wide__c == 'Required' && orderLineItem.Lites_Wide_S1__c == null){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_LITES_WIDE_REQUIRED : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_LITES_WIDE_REQUIRED;
				}
				if(grilleControl.Lites_Wide__c == 'Disabled' && orderLineItem.Lites_Wide_S1__c != null ){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_LITES_WIDE_DISABLED : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_LITES_WIDE_DISABLED;
				}
				if(grilleControl.Grille_Style__c == 'Required' && orderLineItem.Grille_Style__c == null){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_STYLE_REQUIRED : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_STYLE_REQUIRED;
				}
				if(grilleControl.Grille_Style__c == 'Disabled' && orderLineItem.Grille_Style__c != null){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_STYLE_DISABLED : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_STYLE_DISABLED;
				}
			}
		} 

		//Specialty Grille Control S2
		if(orderLineItem.Grille_Pattern__c != null && orderLineItem.Specialty_Shape__c != null && (masterProductConfig.Number_of_Sashes__c == '2' || masterProductConfig.Number_of_Sashes__c == '3' || masterProductConfig.Number_of_Sashes__c == '4')){
			List<Specialty_Grille_Control__c> relatedGrilleControls = [SELECT 	Grille_Pattern__c,
																			Grille_Style__c,																						
																			Product_Configuration__c,
																			Specialty_Shape__c,
																			Hubs__c,
																			Lites_High__c,
																			Lites_Wide__c,
																			Spokes__c 
																			FROM Specialty_Grille_Control__c
																			WHERE Product_Configuration__c =: masterProductConfig.Id
																			AND Grille_Pattern__c =: orderLineItem.Grille_Pattern__c
																			AND Specialty_Shape__c =: orderLineItem.Specialty_Shape__c];
			if(!relatedGrilleControls.isEmpty()){
				Specialty_Grille_Control__c grilleControl = relatedGrilleControls[0];
				if(grilleControl.Lites_High__c == 'Required' && orderLineItem.Lites_High_S2__c == null){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_LITES_HIGH_REQUIRED : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_LITES_HIGH_REQUIRED;
				}
				if(grilleControl.Lites_High__c == 'Disabled' && orderLineItem.Lites_High_S2__c != null ){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_LITES_HIGH_DISABLED : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_LITES_HIGH_DISABLED;
				}
				if(grilleControl.Lites_Wide__c == 'Required' && orderLineItem.Lites_Wide_S2__c == null){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_LITES_WIDE_REQUIRED : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_LITES_WIDE_REQUIRED;
				}
				if(grilleControl.Lites_Wide__c == 'Disabled' && orderLineItem.Lites_Wide_S2__c != null ){
					errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_LITES_WIDE_DISABLED : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_LITES_WIDE_DISABLED;
				}
			}
		} 

		//Specialty Grille Configuration S1
		if(orderLineItem.Grille_Pattern__c != null && orderLineItem.Grille_Style__c != null && orderLineItem.Specialty_Shape__c != null && masterProductConfig.Number_of_Sashes__c != null){

			List<Specialty_Grille_Configuration__c> relatedGrilleConfigurations = [SELECT 	Grille_Pattern__c,
																						Grille_Style__c,
																						Hubs__c,
																						Lites_High__c,
																						Lites_Wide__c,
																						Product_Configuration__c,
																						Specialty_Shape__c,
																						Spokes__c 
																						FROM Specialty_Grille_Configuration__c
																						WHERE Product_Configuration__c =: masterProductConfig.Id
																						AND Grille_Pattern__c =: orderLineItem.Grille_Pattern__c
																						AND Grille_Style__c =: orderLineItem.Grille_Style__c
																						AND Specialty_Shape__c =: orderLineItem.Specialty_Shape__c];
			if(relatedGrilleConfigurations.isEmpty()){
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_STYLE_SHAPE_PATTERN : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_STYLE_SHAPE_PATTERN;	
			}else{
				if(orderLineItem.Lites_High_S1__c != null && orderLineItem.Lites_Wide_S1__c != null){
					Boolean validLites = false;
					for(Specialty_Grille_Configuration__c grilleConfig : relatedGrilleConfigurations){
						if(orderLineItem.Lites_High_S1__c == grilleConfig.Lites_High__c && orderLineItem.Lites_Wide_S1__c == grilleConfig.Lites_Wide__c){
							validLites = true;
						}
					}
					if(!validLites){
						errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_LITES : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_LITES;	

					}
				}
				if(orderLineItem.Hubs__c != null && orderLineItem.Spokes__c != null){
					Boolean validHubs = false;
					Integer hubs = 0;
					Integer spokes = 0;
					if(orderLineItem.Hubs__c != null && orderLineItem.Hubs__c.isNumeric()){
						hubs = Integer.valueOf(orderLineItem.Hubs__c);
					}
					if(orderLineItem.Spokes__c != null && orderLineItem.Spokes__c.isNumeric()){
						spokes = Integer.valueOf(orderLineItem.Spokes__c);
					}
					for(Specialty_Grille_Configuration__c grilleConfig : relatedGrilleConfigurations){
						if(hubs == grilleConfig.Hubs__c && spokes == grilleConfig.Spokes__c){
							validHubs = true;
						}
					}
					if(!validHubs){
						errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_HUBS_SPOKES : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_HUBS_SPOKES;	

					}
				}
			}
		} 

		//Specialty Grille Configuration S2
		if(orderLineItem.Grille_Pattern__c != null && orderLineItem.Grille_Style__c != null && orderLineItem.Specialty_Shape__c != null && (masterProductConfig.Number_of_Sashes__c == '2' || masterProductConfig.Number_of_Sashes__c == '3' || masterProductConfig.Number_of_Sashes__c == '4')){

			List<Specialty_Grille_Configuration__c> relatedGrilleConfigurations = [SELECT 	Grille_Pattern__c,
																						Grille_Style__c,
																						Hubs__c,
																						Lites_High__c,
																						Lites_Wide__c,
																						Product_Configuration__c,
																						Specialty_Shape__c,
																						Spokes__c 
																						FROM Specialty_Grille_Configuration__c
																						WHERE Product_Configuration__c =: masterProductConfig.Id
																						AND Grille_Pattern__c =: orderLineItem.Grille_Pattern__c
																						AND Grille_Style__c =: orderLineItem.Grille_Style__c
																						AND Specialty_Shape__c =: orderLineItem.Specialty_Shape__c];
			if(relatedGrilleConfigurations.isEmpty()){
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_STYLE_SHAPE_PATTERN : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_STYLE_SHAPE_PATTERN;	
			}else{
				if(orderLineItem.Lites_High_S2__c != null && orderLineItem.Lites_Wide_S2__c != null){
					Boolean validLites = false;
					for(Specialty_Grille_Configuration__c grilleConfig : relatedGrilleConfigurations){
						if(orderLineItem.Lites_High_S2__c == grilleConfig.Lites_High__c && orderLineItem.Lites_Wide_S2__c == grilleConfig.Lites_Wide__c){
							validLites = true;
						}
					}
					if(!validLites){
						errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_LITES : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_LITES;	

					}
				}
				if(orderLineItem.Hubs__c != null && orderLineItem.Spokes__c != null){
					Boolean validHubs = false;
					Integer hubs = 0;
					Integer spokes = 0;
					if(orderLineItem.Hubs__c != null && orderLineItem.Hubs__c.isNumeric()){
						hubs = Integer.valueOf(orderLineItem.Hubs__c);
					}
					if(orderLineItem.Spokes__c != null && orderLineItem.Spokes__c.isNumeric()){
						spokes = Integer.valueOf(orderLineItem.Spokes__c);
					}
					for(Specialty_Grille_Configuration__c grilleConfig : relatedGrilleConfigurations){
						if(hubs == grilleConfig.Hubs__c && spokes == grilleConfig.Spokes__c){
							validHubs = true;
						}
					}
					if(!validHubs){
						errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_HUBS_SPOKES : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_HUBS_SPOKES;	

					}
				}
			}
		} 

		//Grille Pattern Configuration S1
		if(orderLineItem.Grille_Pattern__c != null ){
			List<Grille_Pattern_Configuration__c> relatedGrillePatternConfigurations = [SELECT 	Sash_Ratio__c,
																							Grille_Pattern__c,
																							Grille_Style__c,
																							Min_Width_Inches__c,
																							Min_Width_Fraction__c,
																							Min_Height_Inches__c,
																							Min_Height_Fraction__c													
																							FROM Grille_Pattern_Configuration__c
																							WHERE Product_Configuration__c =: masterProductConfig.Id
																							AND Grille_Pattern__c =: orderLineItem.Grille_Pattern__c
																							AND Grille_Style__c =: orderLineItem.Grille_Style__c
																							];
			Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
			Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);

			if(!relatedGrillePatternConfigurations.isEmpty()){
				for(Grille_Pattern_Configuration__c grillePatternConfig : relatedGrillePatternConfigurations){
					if(grillePatternConfig.Min_Width_Inches__c != null){
						Decimal requiredWidth = grillePatternConfig.Min_Width_Inches__c + UtilityMethods.calculateFraction(grillePatternConfig.Min_Width_Fraction__c);
						if(widthInches < requiredWidth){
							String requiredWidthString =  String.ValueOf(grillePatternConfig.Min_Width_Inches__c) + ' ' + (grillePatternConfig.Min_Width_Fraction__c == null? '' : String.valueOf(grillePatternConfig.Min_Width_Fraction__c));
							String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.GRILLE_MIN_WIDTH, '', requiredWidthString);
							errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;	
						}
					}
					if(grillePatternConfig.Min_Height_Inches__c != null){
						Decimal requiredHeight = grillePatternConfig.Min_Height_Inches__c + UtilityMethods.calculateFraction(grillePatternConfig.Min_Height_Fraction__c);
						if(heightInches < requiredHeight){
							String requiredHeightString =  String.ValueOf(grillePatternConfig.Min_Height_Inches__c) + ' '+ (grillePatternConfig.Min_Height_Fraction__c == null? '' : String.valueOf(grillePatternConfig.Min_Height_Fraction__c));
							String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.GRILLE_MIN_HEIGHT, '', requiredHeightString);
							errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;	
						}
					}
				}
			}
		} 

		//Glazing Configuration S1
		if(orderLineItem.Glazing_S1__c != null){
			List<Glazing_Configuration__c> relatedGlazingConfigurations = [SELECT 	Sash_Ratio__c,
																							Glazing__c,
																							Glass_Pattern__c,
																							Max_Width_Inches__c,
																							Max_Width_Fraction__c,
																							Max_Height_Inches__c,
																							Max_Height_Fraction__c													
																							FROM Glazing_Configuration__c
																							WHERE Product_Configuration__c =: masterProductConfig.Id
																							AND Glazing__c =: orderLineItem.Glazing_S1__c
																							AND Glass_Pattern__c =: orderLineItem.Glass_Pattern_S1__c
																							];
			Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
			Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);

			if(!relatedGlazingConfigurations.isEmpty()){
				for(Glazing_Configuration__c glazingConfig : relatedGlazingConfigurations){
					if(glazingConfig.Max_Width_Inches__c != null){
						Decimal requiredWidth = glazingConfig.Max_Width_Inches__c + UtilityMethods.calculateFraction(glazingConfig.Max_Width_Fraction__c);
						if(widthInches > requiredWidth){
							String requiredWidthString =  String.ValueOf(glazingConfig.Max_Width_Inches__c) + ' ' +(glazingConfig.Max_Width_Fraction__c == null? '' : String.valueOf(glazingConfig.Max_Width_Fraction__c));
							String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.GLAZING_MAX_WIDTH, '', requiredWidthString);
							errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;	
						}
					}
					if(glazingConfig.Max_Height_Inches__c != null){
						Decimal requiredHeight = glazingConfig.Max_Height_Inches__c + UtilityMethods.calculateFraction(glazingConfig.Max_Height_Fraction__c);
						if(heightInches > requiredHeight){
							String requiredHeightString =  String.ValueOf(glazingConfig.Max_Height_Inches__c) + ' '+ (glazingConfig.Max_Height_Fraction__c == null? '' : String.valueOf(glazingConfig.Max_Height_Fraction__c));
							String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.GLAZING_MAX_HEIGHT, '', requiredHeightString);
							errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;	
						}
					}
				}
			}
		} 

		//Glazing Configuration S2
		if(orderLineItem.Glazing_S2__c != null ){
			List<Glazing_Configuration__c> relatedGlazingConfigurations = [SELECT 	Sash_Ratio__c,
																							Glazing__c,
																							Glass_Pattern__c,
																							Max_Width_Inches__c,
																							Max_Width_Fraction__c,
																							Max_Height_Inches__c,
																							Max_Height_Fraction__c													
																							FROM Glazing_Configuration__c
																							WHERE Product_Configuration__c =: masterProductConfig.Id
																							AND Glazing__c =: orderLineItem.Glazing_S2__c
																							AND Glass_Pattern__c =: orderLineItem.Glass_Pattern_S2__c

																							];
			Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
			Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);

			if(!relatedGlazingConfigurations.isEmpty()){
				for(Glazing_Configuration__c glazingConfig : relatedGlazingConfigurations){
					if(glazingConfig.Max_Width_Inches__c != null){
						Decimal requiredWidth = glazingConfig.Max_Width_Inches__c + UtilityMethods.calculateFraction(glazingConfig.Max_Width_Fraction__c);
						if(widthInches > requiredWidth){
							String requiredWidthString =  String.ValueOf(glazingConfig.Max_Width_Inches__c) + ' ' +(glazingConfig.Max_Width_Fraction__c == null? '' : String.valueOf(glazingConfig.Max_Width_Fraction__c));
							String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.GLAZING_MAX_WIDTH, '', requiredWidthString);
							errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;	
						}
					}
					if(glazingConfig.Max_Height_Inches__c != null){
						Decimal requiredHeight = glazingConfig.Max_Height_Inches__c + UtilityMethods.calculateFraction(glazingConfig.Max_Height_Fraction__c);
						if(heightInches > requiredHeight){
							String requiredHeightString =  String.ValueOf(glazingConfig.Max_Height_Inches__c) + ' '+ (glazingConfig.Max_Height_Fraction__c == null? '' : String.valueOf(glazingConfig.Max_Height_Fraction__c));
							String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.GLAZING_MAX_HEIGHT, '', requiredHeightString);
							errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;	
						}
					}
				}
			}
		} 
 
		//Glazing Configuration S3
		if(orderLineItem.Glazing_S3__c != null){
			List<Glazing_Configuration__c> relatedGlazingConfigurations = [SELECT 	Sash_Ratio__c,
																							Glazing__c,
																							Glass_Pattern__c,
																							Max_Width_Inches__c,
																							Max_Width_Fraction__c,
																							Max_Height_Inches__c,
																							Max_Height_Fraction__c													
																							FROM Glazing_Configuration__c
																							WHERE Product_Configuration__c =: masterProductConfig.Id
																							AND Glazing__c =: orderLineItem.Glazing_S3__c
																							AND Glass_Pattern__c =: orderLineItem.Glass_Pattern_S3__c
																							];
			Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
			Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);

			if(!relatedGlazingConfigurations.isEmpty()){
				for(Glazing_Configuration__c glazingConfig : relatedGlazingConfigurations){
					if(glazingConfig.Max_Width_Inches__c != null){
						Decimal requiredWidth = glazingConfig.Max_Width_Inches__c + UtilityMethods.calculateFraction(glazingConfig.Max_Width_Fraction__c);
						if(widthInches > requiredWidth){
							String requiredWidthString =  String.ValueOf(glazingConfig.Max_Width_Inches__c) + ' ' +(glazingConfig.Max_Width_Fraction__c == null? '' : String.valueOf(glazingConfig.Max_Width_Fraction__c));
							String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.GLAZING_MAX_WIDTH, '', requiredWidthString);
							errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;	
						}
					}
					if(glazingConfig.Max_Height_Inches__c != null){
						Decimal requiredHeight = glazingConfig.Max_Height_Inches__c + UtilityMethods.calculateFraction(glazingConfig.Max_Height_Fraction__c);
						if(heightInches > requiredHeight){
							String requiredHeightString =  String.ValueOf(glazingConfig.Max_Height_Inches__c) + ' '+ (glazingConfig.Max_Height_Fraction__c == null? '' : String.valueOf(glazingConfig.Max_Height_Fraction__c));
							String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.GLAZING_MAX_HEIGHT, '', requiredHeightString);
							errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;	
						}
					}
				}
			}
		} 

		//Glazing Configuration S4
		if(orderLineItem.Glazing_S4__c != null){
			List<Glazing_Configuration__c> relatedGlazingConfigurations = [SELECT 	Sash_Ratio__c,
																							Glazing__c,
																							Glass_Pattern__c,
																							Max_Width_Inches__c,
																							Max_Width_Fraction__c,
																							Max_Height_Inches__c,
																							Max_Height_Fraction__c													
																							FROM Glazing_Configuration__c
																							WHERE Product_Configuration__c =: masterProductConfig.Id
																							AND Glazing__c =: orderLineItem.Glazing_S4__c
																							AND Glass_Pattern__c =: orderLineItem.Glass_Pattern_S4__c
																							];
			Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
			Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);

			if(!relatedGlazingConfigurations.isEmpty()){
				for(Glazing_Configuration__c glazingConfig : relatedGlazingConfigurations){
					if(glazingConfig.Max_Width_Inches__c != null){
						Decimal requiredWidth = glazingConfig.Max_Width_Inches__c + UtilityMethods.calculateFraction(glazingConfig.Max_Width_Fraction__c);
						if(widthInches > requiredWidth){
							String requiredWidthString =  String.ValueOf(glazingConfig.Max_Width_Inches__c) + ' ' +(glazingConfig.Max_Width_Fraction__c == null? '' : String.valueOf(glazingConfig.Max_Width_Fraction__c));
							String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.GLAZING_MAX_WIDTH, '', requiredWidthString);
							errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;	
						}
					}
					if(glazingConfig.Max_Height_Inches__c != null){
						Decimal requiredHeight = glazingConfig.Max_Height_Inches__c + UtilityMethods.calculateFraction(glazingConfig.Max_Height_Fraction__c);
						if(heightInches > requiredHeight){
							String requiredHeightString =  String.ValueOf(glazingConfig.Max_Height_Inches__c) + ' '+ (glazingConfig.Max_Height_Fraction__c == null? '' : String.valueOf(glazingConfig.Max_Height_Fraction__c));
							String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.GLAZING_MAX_HEIGHT, '', requiredHeightString);
							errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;	
						}
					}
				}
			}
		} 

		//LOCK_MAX_WIDTH
		if(masterProductConfig.Lock_Max_Width_Inches__c != null ){
			Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
			Decimal lockMaxWidthInches = masterProductConfig.Lock_Max_Width_Inches__c + UtilityMethods.calculateFraction(masterProductConfig.Lock_Max_Width_Fractions__c);
			Decimal lockSash;
			if(orderLineItem.Locks_Sash__c != null){
				lockSash = decimal.valueOf(orderLineItem.Locks_Sash__c);
			}else{
				lockSash = 0;
			}
			if(widthInches < lockMaxWidthInches && lockSash > decimal.valueOf(masterProductConfig.Lock_Max_Width_Locks__c)){
				String enteredValue = String.ValueOf(masterProductConfig.Lock_Max_Width_Locks__c);
				String requiredValue = String.ValueOf(masterProductConfig.Lock_Max_Width_Inches__c);
				if(masterProductConfig.Lock_Max_Width_Fractions__c != null){
					requiredValue = requiredValue+' '+String.ValueOf(masterProductConfig.Lock_Max_Width_Fractions__c);
				}
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.LOCK_MAX_WIDTH, enteredValue, requiredValue);
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
		}
		
		//LOCK_MAX_HEIGHT
		if(masterProductConfig.Lock_Max_Height_Inches__c != null ){
			Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);
			Decimal lockMaxHeightInches = masterProductConfig.Lock_Max_Height_Inches__c + UtilityMethods.calculateFraction(masterProductConfig.Lock_Max_Height_Fractions__c);
			Decimal lockSash;
			if(orderLineItem.Locks_Sash__c != null){
				lockSash = decimal.valueOf(orderLineItem.Locks_Sash__c);
			}else{
				lockSash = 0;
			}
			if(heightInches < lockMaxHeightInches && lockSash > decimal.valueOf(masterProductConfig.Lock_Max_Height_Locks__c)){
				String enteredValue = String.ValueOf(masterProductConfig.Lock_Max_Height_Locks__c);
				String requiredValue = String.ValueOf(masterProductConfig.Lock_Max_Height_Inches__c);
				if(masterProductConfig.Lock_Max_Height_Fractions__c != null){
					requiredValue = requiredValue+' '+String.ValueOf(masterProductConfig.Lock_Max_Height_Fractions__c);
				}
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.LOCK_MAX_HEIGHT, enteredValue, requiredValue);
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
		}
		
		
		//LOCK_MIN_WIDTH
		if(masterProductConfig.Lock_Min_Width_Inches__c != null ){
			Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
			Decimal lockMinWidthInches = masterProductConfig.Lock_Min_Width_Inches__c + UtilityMethods.calculateFraction(masterProductConfig.Lock_Min_Width_Fractions__c);
			Decimal lockSash;
			if(orderLineItem.Locks_Sash__c != null){
				lockSash = decimal.valueOf(orderLineItem.Locks_Sash__c);
			}else{
				lockSash = 0;
			}
			if(widthInches > lockMinWidthInches && lockSash < decimal.valueOf(masterProductConfig.Lock_Min_Width_Locks__c)){
				String enteredValue = String.ValueOf(masterProductConfig.Lock_Min_Width_Locks__c);
				String requiredValue = String.ValueOf(masterProductConfig.Lock_Min_Width_Inches__c);
				if(masterProductConfig.Lock_Min_Width_Fractions__c != null){
					requiredValue = requiredValue+' '+String.ValueOf(masterProductConfig.Lock_Min_Width_Fractions__c);
				}
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.LOCK_Min_WIDTH, enteredValue, requiredValue);
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
		}
		
		//LOCK_MIN_HEIGHT
		if(masterProductConfig.Lock_Min_Height_Inches__c != null ){
			Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);
			Decimal lockMinHeightInches = masterProductConfig.Lock_Min_Height_Inches__c + UtilityMethods.calculateFraction(masterProductConfig.Lock_Min_Height_Fractions__c);
			Decimal lockSash;
			if(orderLineItem.Locks_Sash__c != null){
				lockSash = decimal.valueOf(orderLineItem.Locks_Sash__c);
			}else{
				lockSash = 0;
			}
			if(heightInches > lockMinHeightInches && lockSash < decimal.valueOf(masterProductConfig.Lock_Min_Height_Locks__c)){
				String enteredValue = String.ValueOf(masterProductConfig.Lock_Min_Height_Locks__c);
				String requiredValue = String.ValueOf(masterProductConfig.Lock_Min_Height_Inches__c);
				if(masterProductConfig.Lock_Min_Height_Fractions__c != null){
					requiredValue = requiredValue+' '+String.ValueOf(masterProductConfig.Lock_Min_Height_Fractions__c);
				}
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.LOCK_MIN_HEIGHT, enteredValue, requiredValue);
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
		}
		//Interior Color Max Width
		if(masterProductConfig.Int_Color_Max_Width_Inches__c != null ){
			Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
			Decimal intColorMaxWidthInches = masterProductConfig.Int_Color_Max_Width_Inches__c + UtilityMethods.calculateFraction(masterProductConfig.Int_Color_Max_Width_Fractions__c);
			
			if(widthInches > intColorMaxWidthInches){
				List<String> intColors = masterProductConfig.Int_Color_Max__c.split(';');
				
				for(String c : intColors){
					if(c == orderLineItem.Interior_Color__c){
						String enteredValue = String.ValueOf(masterProductConfig.Int_Color_Max_Width_Inches__c);
						if(masterProductConfig.Lock_Min_Height_Fractions__c != null){
							enteredValue = enteredValue+' '+String.ValueOf(masterProductConfig.Int_Color_Max_Width_Fractions__c);
						}
						String requiredValue = String.ValueOf(c);
						String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.INTERIOR_COLOR_MAX_WIDTH, enteredValue, requiredValue);
						errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;	
						break;
					}
					
				}
			}	
		}
		
		//Interior Color Max height
		if(masterProductConfig.Int_Color_Max_Height_Inches__c != null ){
			Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);
			Decimal intColorMaxHeightInches = masterProductConfig.Int_Color_Max_Height_Inches__c + UtilityMethods.calculateFraction(masterProductConfig.Int_Color_Max_Height_Fractions__c);
			
			if(heightInches > intColorMaxHeightInches){
				List<String> intColors = masterProductConfig.Int_Color_Max__c.split(';');
				
				for(String c : intColors){
					if(c == orderLineItem.Interior_Color__c){
						String enteredValue = String.ValueOf(masterProductConfig.Int_Color_Max_Height_Inches__c);
						if(masterProductConfig.Lock_Min_Height_Fractions__c != null){
							enteredValue = enteredValue+' '+String.ValueOf(masterProductConfig.Int_Color_Max_Height_Fractions__c);
						}
						String requiredValue = String.ValueOf(c);
						String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.INTERIOR_COLOR_MAX_HEIGHT, enteredValue, requiredValue);
						errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;	
						break;
					}
					
				}
			}	
		}
		
		//HW Finish Required
		if(masterProductConfig.HW_Finish_Required__c == true){
			if(orderLineItem.Hardware_Style__c != null && orderLineItem.Hardware_Style__c != '' && (orderLineItem.Hardware_Finish__c == null || orderLineItem.Hardware_Finish__c == '')){
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.HARDWARE_FINISH_BLANK, null, null);
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
		}
		
		//Tempered Glass Test
		if(orderLineItem.Tempered_S1__c == false && masterProductConfig.Tempered_Square_Ft_Max__c != null && masterProductConfig.Height_Backdown_Inches__c != null && masterProductConfig.Width_Backdown_Inches__c != null){
			Decimal heightInches = orderLineItem.Height_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Height_Fraction__c);
			Decimal widthInches = orderLineItem.Width_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c);
			
			Decimal heightBackdownInches = masterProductConfig.Height_Backdown_Inches__c + UtilityMethods.calculateFraction(masterProductConfig.Height_Backdown_Fractions__c);
			Decimal widthBackdownInches = masterProductConfig.Width_Backdown_Inches__c + UtilityMethods.calculateFraction(masterProductConfig.Width_Backdown_Fractions__c);
 
			if(((heightInches-heightBackdownInches)*(widthInches-widthBackdownInches)/144) > masterProductConfig.Tempered_Square_Ft_Max__c){
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.TEMPERED_GLASS_REQUIRED : errorMessage + '<BR>' + RMS_errorMessages.TEMPERED_GLASS_REQUIRED;	
			}	
		} 
		
		if(orderLineItem.Special_Options__c == true){
			
		    if(orderLineItem.Screen_Type__c == 'TruScene with Wood Veneer)' && (orderLineItem.Screen_Color__c != null && orderLineItem.Screen_Color__c != '')){
		    	errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.SCREEN_COLOR_SELECTED_WITH_WOOD_VENEER : errorMessage + '<BR>' + RMS_errorMessages.SCREEN_COLOR_SELECTED_WITH_WOOD_VENEER;	
		    }
		    if((orderLineItem.Grille_Style__c == 'No Grilles' || orderLineItem.Grille_Style__c == null) && (orderLineItem.Exterior_Grille_Color__c != null || orderLineItem.Interior_Grille_Color__c != null)){
		    	errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.GRILLE_COLOR_WITHOUT_STYPE : errorMessage + '<BR>' + RMS_errorMessages.GRILLE_COLOR_WITHOUT_STYPE;	
		    }
		    //Disabling this check per JETT-4213
			//if(orderLineItem.Install_Holes_Location__c == null || orderLineItem.Install_Holes_Location__c == '' || orderLineItem.Install_Track_Location__c == null || orderLineItem.Install_Track_Location__c == ''){
			//	errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.TRACK_HOLE_LOCATION_NULL : errorMessage + '<BR>' + RMS_errorMessages.TRACK_HOLE_LOCATION_NULL;	
			//}
			
			
		}
		
		return errorMessage;
	
	}
	
	
	/*******************************************************
					findProductConfiguration method
	*******************************************************/
	// retrieves the correct price book entry based on the pricebook and product id and 
	// creates the product config wrapper to store the config options
	public static productConfigWrapper findProductConfiguration(OrderItem orderLineItem, String childProductId, Product_Configuration__c masterProductConfig) {

		// Check if we have the necessary Ids to create the wrapper and return null if not
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

		// Check if we have the necessary Ids to retrieve the pricebookentry and return the wrapper unchanged if so
		if (childProductId == null) return theWrapper;
		PricebookEntry pBookEntry;
		
		for (PricebookEntry pBookE : [SELECT Id, Pricing_Configuration__c FROM PricebookEntry
																	WHERE 	PriceBook2Id =: priceBookId AND
																			Product2Id =:	childProductId
																	LIMIT 1 ]) {
																		
			pBookEntry = pBookE;
		}
		
		// If the child product's pricebook entry cannot be found, return the wrapper unchanged
		if (pBookEntry == null) return theWrapper;

		Pricing_Configuration__c pricingConfig = new Pricing_Configuration__c();

		// If the pricingConfig was not found return the wrapper unchanged
		if (pBookEntry.Pricing_Configuration__c == null) return theWrapper;

		// Retrieve all fields for Pricing Configuration in a comma separated string
		String commaSeparatedFields = getCommaSeparatedFields('Pricing_Configuration__c');
 
		// Use the comma separated field string to build a dynamic query to retrieve the Pricing_Configuration__c
		String query = 'SELECT ' + commaSeparatedFields + ' FROM Pricing_Configuration__c ' + 
													' WHERE Id = \'' + pBookEntry.Pricing_Configuration__c + '\''+
													' LIMIT 1';
 
		// Retrieve all fields from the PricebookEntry object in a query
		pricingConfig = Database.query(query);


		theWrapper.pricingConfig = pricingConfig;
		return theWrapper;

	}   
	
	/*******************************************************
					calculatePrice method
	*******************************************************/
	// TODO: This is where the price could be rolled up using the pricing configuration object
	public static decimal calculatePrice(ProductConfigWrapper prodConfig) {
		prodConfig = clearNonSelectableValues(prodConfig);
		decimal price = 0;
//		decimal price = (prodConfig.baseUnitPrice == null) ? 0 : prodConfig.baseUnitPrice;
//		price = (!prodConfig.OrderLI.Specialty_Glazing__c || prodConfig.specialtyGlazingPrice == null) ? price : price + prodConfig.specialtyGlazingPrice;		

		return price;
	}

	/*******************************************************
					clearNonSelectableValues method
	*******************************************************/
	// TODO: This is where we need to clear all non selectable values when a product is edited and changes from one product to another
	public static ProductConfigWrapper clearNonSelectableValues(ProductConfigWrapper prodConfig) {
//		prodConfig.OrderLI.Handing__c 							= (prodConfig.handingOptions == null) ? '' : prodConfig.OrderLI.Handing__c;		
		return prodConfig;
	}	 


	/*******************************************************
					retrievePickListItems method
	*******************************************************/
	//Method to receive a multi picklist and return select options for use in a single picklist.
	public static List<SelectOption> retrievePickListItems(String multiPickList) {
		System.Debug('**************multiPickList=' +multiPickList);
		List<SelectOption> pickListItems = new List<SelectOption>();
		pickListItems.add(new SelectOption('', '-- Select --'));
		// need to limit to pricebook
		if (String.isBlank(multiPickList)) return pickListItems;
		
		for (String pickListItem : multiPickList.split(';')) {
			pickListItems.add(new SelectOption(pickListItem, pickListItem));
		}			   
		return pickListItems;
	} 

	/*******************************************************
					retrievePickListItems method
	*******************************************************/
	//Method to receive a multi picklist and return select options for use in a single picklist.
	public static List<SelectOption> retrievePickListItems(String multiPickList, Set<String> currentValues) {
		System.Debug('**************multiPickList=' +multiPickList);
		List<SelectOption> pickListItems = new List<SelectOption>();
		pickListItems.add(new SelectOption('', '-- Select --'));
		Set<String> pickListItemsToAdd = new Set<String>();

		// If both the multipicklist and the set of current values is null just return nothing
		if (String.isBlank(multiPickList) && (currentValues == null)) return pickListItems;
		
		// If the multipicklist is not blank, split it into individual strings and add to the set
		if (!String.isBlank(multiPickList)) {
			for (String pickListItem : multiPickList.split(';')) {
				pickListItemsToAdd.add(pickListItem);
			}
		}	
		// If the currentValues list is not blank, split it into individual strings and add to the set
		if (currentValues != null) {
			currentValues.remove(null);
			for (String pickListItem : currentValues) {
				pickListItemsToAdd.add(pickListItem);
			}
		}	
		// Loop through the set and create select options for each string
		for (String pickListItem : pickListItemsToAdd) {
			pickListItems.add(new SelectOption(pickListItem, pickListItem));
		}
			
		return pickListItems;
	} 
	
	/*******************************************************
					error message methods
	*******************************************************/	
	//Method for error messages to make them dynamic
	public static string fillInErrorRuleValues(String errorMessage, String enteredValue, String requiredValue){
		errorMessage = errorMessage.replace('[enteredValue]', '<b>('+enteredValue+')</b>');
		errorMessage = errorMessage.replace('[requiredValue]', '<b>('+requiredValue+')</b>');
		errorMessage = errorMessage.replace('null', '');
		
		return errorMessage;
	}

	/*******************************************************
					getOrderStatus methods
	*******************************************************/	
	//Method for error messages to make them dynamic
	public static string getOrderStatus(String orderStatus){

		return 
		(	orderStatus == 'Draft') 					?	'drf'	:
		(	orderStatus == 'Tech Measure Needed') 		?	'act'	:
		(	orderStatus == 'Tech Measure Scheduled') 	?	'act'	:
		(	orderStatus == 'Ready to Order') 			?	'act'	:
		(	orderStatus == 'Order Released') 			?	'rel'	:
		(	orderStatus == 'Install Needed') 			?	'rel'	:
		(	orderStatus == 'Install Scheduled') 		?	'rel'	:
		(	orderStatus == 'Job in Progress') 			?	'rel'	:
		(	orderStatus == 'Job Closed')		 		?	'clo'	:
		(	orderStatus == 'On Hold')		 			?	'clo'	:
		(	orderStatus == 'Pending Cancellation')		?	'clo'	:
		(	orderStatus == 'Cancelled')					?	'clo'	: 
															'drf';
	}

	/*******************************************************
					updateTaxes methods
	*******************************************************/	
	//Method for updating the taxes on product line items
	public static string updateTaxes(Id poId) {
		String errorMessage = RMS_errorMessages.PO_TAX_ISSUE;	
		if (poId == null) return errorMessage;
		List<OrderItem> allOrderItems = new List<OrderItem>();
		
		Purchase_Order__c po = [SELECT Id, Subtotal__c, Tax__c FROM Purchase_Order__c WHERE Id =: poId];

		decimal subtotal = 0;
		for (OrderItem oi : [SELECT 	Id, Unit_Wholesale_Cost__c, Quantity, Discount_Amount__c 
										FROM OrderItem 
										Where Purchase_Order__c =: poId])
		{
			decimal itemDiscount = (oi.Discount_Amount__c == null) ? 0 : oi.Discount_Amount__c;
			if (oi.Unit_Wholesale_Cost__c == null || oi.Quantity == null)
				continue;
			subtotal = subtotal + ((oi.Unit_Wholesale_Cost__c-itemDiscount)*oi.Quantity);
			allOrderItems.add(oi);
		}
		po.Subtotal__c = subtotal;
		upsert po;

		List<OrderItem> itemsToUpdate = new List<OrderItem>();
		itemsToUpdate = UtilityMethods.calculateTaxes(allOrderItems, po.Subtotal__c, po.Tax__c);
		if(itemsToUpdate != null){
			update itemsToUpdate;
		}
		return null;
	}

}
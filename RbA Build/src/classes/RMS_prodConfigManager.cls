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
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.WIDTH_ABOVE_MAX, enteredValue, requiredValue);

				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;

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
				String dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.HEIGHT_ABOVE_MAX, enteredValue, requiredValue);
		
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
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

		// Check for peak height
		if(masterProductConfig.Peak_Height__c != null && orderLineItem.Width_Inches__c != null){
			
			Decimal leftLeg = orderLineItem.Left_Leg_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Left_Leg_Fraction__c);
			Decimal rightLeg = orderLineItem.Right_Leg_Inches__c + UtilityMethods.calculateFraction(orderLineItem.Right_Leg_Fraction__c);
			
			if(((leftLeg - rightleg).abs()) < ((orderLineItem.Width_Inches__c+ UtilityMethods.calculateFraction(orderLineItem.Width_Fraction__c)) * masterProductConfig.Peak_Height__c )){
				errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.PEAK_HEIGHT : errorMessage + '<BR>' + RMS_errorMessages.PEAK_HEIGHT;
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
	 	
	 	// Check for width to heither ratio max
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
		
		// Check for Brickmould is not available on Double Hung Insert Frames with Sloped Sills
		if(	masterProductName == 'Double-Hung' && 
			orderLineItem.Frame_Type__c == 'Insert Frame' &&
			orderLineItem.Sill_Angle__c != 'FS' &&
			(orderLineItem.Exterior_Trim__c == 'Brickmould - Picture Frame' || orderLineItem.Exterior_Trim__c == 'Brickmould - Traditional')
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
		(	orderStatus == 'Job Close')		 			?	'clo'	:
		(	orderStatus == 'On Hold')		 			?	'clo'	:
		(	orderStatus == 'Cancellation in Progress')	?	'clo'	:
		(	orderStatus == 'Cancelled')					?	'clo'	: 
															'drf';
	}
}
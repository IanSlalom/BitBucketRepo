/*******************************************************//**

@class	  RMS_prodConfigExtension class

@brief	  Extension for the prodConfig VF Page

	Manages all of the product config / pricing functionality

@author	 Creston Kuenzi (Slalom.CDK)

@version	2015-07-22  Slalom.CDK
	Created.
@version	2015-11-09  Slalom.CDK
	Updated for first release to build
@version	2015-11-20  Slalom.CDK
	Updated to pull product config from master product instead of pricebookentry

@see		RMS_prodConfigExtensionTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/
public class RMS_prodConfigExtension {

	/******* public variables  *****************/
	public boolean newOrderItem {get; set;}	 
	public boolean jobClosed {get; set;}	 
	public String priceBookId {get; set;}   
	public String orderId {get; set;}   
	public String oiId {get;set;} // used for redirecting of tabs
	public Decimal inputUI;	
	public String exteriorColor {get; set;}	 
	public String interiorColor {get; set;}	 
	public String defaultInstallTrackLocation {get; set;}
	public String errorOccurred {get; set;}	 
	public String ordStat {get; set;}	// order status 
	public String mode {get; set;}	// viewing mode
	public Id poId {get; set;}	// purchase order linked to the order product
	public List<Change_History__c> changeHistoryRecords{get;set;}
	public Boolean isMiscJob {get;set;}
	public Boolean relatedChangeOrder{get;set;}


	/******* Set up Standard Controller for OrderItem  *****************/
	private final OrderItem orderLineItem;	

	public RMS_prodConfigExtension(ApexPages.StandardController stdController) {
		verifyProducts = true;
		this.orderLineItem = (OrderItem)stdController.getRecord();
		isMiscJob = false;
		newOrderItem = stdController.getId() == null;
		ordStat = 'dft';
		jobClosed = false;	
		relatedChangeOrder = false;		
		mode = ApexPages.currentPage().getParameters().get('mode');
		if (mode == null) mode = 'v';
		if(mode == 'e' && !newOrderItem && orderLineItem.Purchase_Order__c != null){
			Purchase_Order__c relatedPO = [Select Status__c from Purchase_Order__c where Id =: orderLineItem.Purchase_Order__c];
			if(relatedPO.Status__c != 'In Process' && relatedPO.Status__c != 'Rejected'){
				mode = 'v';
			}
			if(relatedPO.Status__c == 'Released' || relatedPO.Status__c == 'Confirmed'){
				mode = 'r';
			}
		}
//		if (mode == 'v') productSelected = true;
		
		// If this is a new order item, retrieve the order and pricebook id from the url params
		//changeHistoryRecords = new List<Change_History__c>();
		if (newOrderItem) {
			newOrderItem = true;
			this.orderLineItem.OrderId = ApexPages.currentPage().getParameters().get('oid');
			orderId = orderLineItem.OrderId;
			if (orderId != null)
				relatedChangeOrder = [Select RecordType.DeveloperName from Order where Id =: orderId].RecordType.DeveloperName == 'Change_Order';
			priceBookId = ApexPages.currentPage().getParameters().get('pid');		 
			this.orderLineItem.Responsible_Party__c = 'Homeowner';
		// If we are editing an order item, retrieve the master product and price book id from the order item
		} else {
			system.debug('ads: on construction: orderLineItem: '+orderLineItem);
				for (OrderItem orderItem : [SELECT Id, PricebookEntryId, PricebookEntry.Pricebook2Id, 
											PricebookEntry.Product2Id, Order.Status, Specialty_Shape__c, 
											Purchase_Order__c, Verify_Item_Configuration__c, PricebookEntry.Product2.RecordType.DeveloperName,
											Responsible_Party__c, Order.RecordType.DeveloperName 
											From OrderItem WHERE Id =: orderLineItem.Id]) {
					masterProductId = orderItem.PricebookEntry.Product2Id;
					priceBookId = String.ValueOf(orderItem.PricebookEntry.Pricebook2Id);
					orderId = orderItem.OrderId;
					poId = orderItem.Purchase_Order__c;
					oiId = orderItem.Id;
					relatedChangeOrder = (orderItem.Order.RecordType.DeveloperName == 'Change_Order');
					// retrieves an abbreviated status name for use in the vf page
					ordStat = RMS_prodConfigManager.getOrderStatus(orderItem.Order.Status);
					//JETT-2213 Do not allow editing of Misc Job and Unit Charges orderitems after creation
					if(orderItem.PricebookEntry.Product2.RecordType.DeveloperName == 'Misc_Job_and_Unit_Charges'){
						isMiscJob = true;
						mode ='v';
					}
					enterProduct();

				}
			changeHistoryRecords = [SELECT Id, Name, CreatedById, LastModifiedBy.Name, LastModifiedDate, Changes__c, Retail_Price__c, Retail_Price_Change__c, Responsible_Party__c, Order_Product__c 
									FROM Change_History__C 
									WHERE Order_Product__c =: oiId];
		}

		if(orderId != null){
			Order o = [Select Status from Order where Id =: orderId];
			if(o.Status == 'Job Closed'){
				jobClosed = true;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.ORDER_CLOSED)); 
				mode = 'v';
			}
		}

		if(ApexPages.currentPage().getParameters().get('extWidthWarning') !=null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ApexPages.currentPage().getParameters().get('extWidthWarning'))); 
		}
		if(ApexPages.currentPage().getParameters().get('extHeightWarning') !=null){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ApexPages.currentPage().getParameters().get('extHeightWarning'))); 
		}

	}

	/******* public properties  *****************/
	public String inputWidth {get;set;}
	public String inputHeight {get;set;}
	public boolean productSelected {get;set;}	

    public  boolean verifyProducts  {get;set;}

    public PageReference toggleVerify() {
            verifyProducts = (verifyProducts == true) ? false : true;
            return null;
    }
                     
    public boolean getVerifyProducts() {
        return verifyProducts;
    }

	/******* property for the product configuration wrapper  *****************/
	public  RMS_prodConfigManager.productConfigWrapper prodConfig  {
		get
		{   
			if (prodConfig != null) return prodConfig;
			prodConfig = new RMS_prodConfigManager.productConfigWrapper();
			return prodConfig;
		}	
		private set;		  
	}

	/******* property for the store location acount  *****************/
	public Id storeLocationId {
		get
		{   
			if (storeLocationId != null) return storeLocationId;
			
			Order relatedOrder = [SELECT Id, Name, Store_Location__c  FROM Order WHERE Id = :orderId];

//			for (Order o : [SELECT Store_Location__c FROM Order WHERE Id =: orderId]) {
				storeLocationId = relatedOrder.Store_Location__c;
//			}
			
			if (storeLocationId == null)
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.STORE_LOCATION_BLANK));

			return storeLocationId;
		}
		private set;		  
	}

	// The set of vendor ids associated with the store
	private static transient Set<Id> lstoreVendors;
	public Set<Id> storeVendors
	{
		get
		{
			if ( lstoreVendors != null) return lstoreVendors;
			if (storeLocationId == null) return null;
			lstoreVendors = new Set<Id>();
			for (Store_Vendor__c sv : [SELECT Vendor__c from Store_Vendor__c Where Store__c =: storeLocationId AND Vendor__c != null]) {
				lstoreVendors.add(sv.Vendor__c);
			}
			

			return lstoreVendors;
		}
		set;
	}

	// The set of products ids associated with the store vendor
	private static transient Set<Id> lvendorProducts;
	public Set<Id> vendorProducts
	{
		get
		{
			if ( lvendorProducts != null) return lvendorProducts;
			lvendorProducts = new Set<Id>();
			for (Vendor_Product__c vp : [SELECT Product__c from Vendor_Product__c Where Vendor__c IN : storeVendors AND Product__c != null]) {
				lvendorProducts.add(vp.Product__c);
			}
			return lvendorProducts;
		}
		set;
	}	

	public String masterProductId {get; set;}

	/******* properties/variables to store the master product id/record and makeability *****************/
	private static transient Product2 lMasterProduct;
	public Product2 masterProduct {
		get
		{   
			
			if (lmasterProduct != null) return lmasterProduct;
			if (masterProductId == '' || masterProductId == null)
				return null;
			
			// retrieves fields from the master product makeability based on the master product id  
			lMasterProduct = [SELECT Id, Name, Family
															FROM Product2
															WHERE Id =: masterProductId
					
															limit 1].get(0);
			return lMasterProduct;
		}
	}

	// SOQL Filters for the product autocomplete checklist
	private static transient String lproductQueries;
	public String productQueries
	{
		get
		{
			if ( lproductQueries != null ) return lproductQueries;

			// return inventoried items
			lproductQueries = 'Inventoried_Item__c = true ';

			// Only return active products without a master product
			lproductQueries += ' AND IsActive = true AND Master_Product__c = null';

			//JETT-184 If Order is Change Order, only search for products of type Misc Job & Unit Charges
			if(relatedChangeOrder){
				//productQueries+=' AND RecordType.DeveloperName = \'Misc_Job_and_Unit_Charges\'';
				lproductQueries+=' AND RecordTypeId = "'+UtilityMethods.retrieveRecordTypeId('Misc_Job_and_Unit_Charges', 'Product2')+'"';
			}

			// The query side of making sure the product id is in the vendor product id set
			lproductQueries += ' AND Id IN :';

			return lproductQueries;
		}
		private set;
	}

	private static transient String lproductVariables;
	public String productVariables
	{
		get
		{
			if ( lproductVariables != null ) return lproductVariables;
			
			String joinedString = '';
			for (Id v : vendorProducts) {
				joinedString += (joinedString==''?'':',')+v;
			}
			if (String.isBlank(joinedString)) joinedString = 'empty';
			lproductVariables = joinedString;

			return lproductVariables;
		}
		private set;
	}
	/******* properties/variables to store the master product configuration *****************/
	private static transient Product_Configuration__c lMasterProductConfig;
	public Product_Configuration__c masterProductConfig {
		get
		{   
			
			if (lMasterProductConfig != null) return lMasterProductConfig;
			if (masterProductId == '' || masterProductId == null)
				return null;
			
			// Loop through the Product_Configuration__c fields and comma separate them into a string
			String commaSeparatedFields = RMS_prodConfigManager.getCommaSeparatedFields('Product_Configuration__c');
 
 			String specialtyShapeString = orderLineItem.Specialty_Shape__c != null ?
 											' AND Specialty_Shape__c = \'' + orderLineItem.Specialty_Shape__c + '\'' : '';
			// Use the comma separated field string to build a dynamic query to retrieve the Product_Configuration__c
			String query = 'SELECT ' + commaSeparatedFields + ' FROM Product_Configuration__c ' + 
													' WHERE Product__c = \'' + masterProductId + '\''+
													specialtyShapeString+
													' LIMIT 1';
 			System.Debug('***************prodconfigquery=' +query);
 
			// Retrieve all fields from the Product_Configuration__c object in a query
			List<Product_Configuration__c> resultConfigs = Database.query(query);
			if(resultConfigs.size() > 0)
				lMasterProductConfig = resultConfigs.get(0);

			return lMasterProductConfig;
		}
	}

	private static transient Id lPriceBookEntryId;
	public Id priceBookEntryId {
		get
		{   
			
			if (lPriceBookEntryId != null) return lPriceBookEntryId;
			if (masterProductId == '' || masterProductId == null)
				return null;
			
				System.debug(priceBookId + '  ' + masterProductId);
			// Retrieve the pricebookentryId for the master product and the current price book
			lPriceBookEntryId = [SELECT Id  FROM PricebookEntry
																	WHERE 	PriceBook2Id =: priceBookId AND
																			Product2Id =:	masterProductId
																			LIMIT 1 ].Id;

			return lPriceBookEntryId;
		}
	}

		

	/******* properties to store the child product record that this order item will be linked to *****************/
	public Product2 childProduct {
		get
		{   
			if (masterProductId == '' || masterProductId == null) {
				return null;
			}
			Product2 childProduct; 
				integer count = 0;

				// Retrieves the correct child product using the master product id and united inch max/min
				for (Product2 cProd : [SELECT Id, Name, UI_Minimum__c, UI_Maximum__c From Product2 WHERE RecordTypeId =: UtilityMethods.RecordTypeFor('Product2', 'Child_Product')
																							AND Master_Product__c =: masterProductId
																							AND UI_Minimum__c <=: InputUI																						   
																							AND UI_Maximum__c >=: InputUI]) {
					childProduct = cProd;
					count++;
				}

			return childProduct;
		}
	}

	/******* property for the sash tab name  *****************/
	public  String sashTabName  {
		get
		{   
			if (sashTabName != null) return sashTabName;
			if (prodConfig.mpc.Number_of_Sashes__c == '3')
				sashTabName = 'Sash 1/3';
			else
				sashTabName = 'Sash 1';
			return sashTabName;
		}	
		private set;		  
	}

	/******* property for the sash field name  *****************/
	public  String sashFieldName  {
		get
		{   
			if (sashFieldName != null) return sashFieldName;
			if (prodConfig.mpc.Number_of_Sashes__c == '3')
				sashFieldName = 'S1/3';
			else
				sashFieldName = 'S1';
			return sashFieldName;
		}	
		private set;		  
	}

	/******* property for the number of Sashes  *****************/
	public  Integer numSashes  {
		get
		{   
//			if (numSashes != null) return numSashes;
			if (prodConfig.mpc.Number_of_Sashes__c != null && prodConfig.mpc.Number_of_Sashes__c.isNumeric()){
				numSashes = Integer.valueOf(prodConfig.mpc.Number_of_Sashes__c);
			}else{
				numSashes = 0;
			}
			return numSashes;
		}	
		private set;		  
	}
	
	/******* Set up ProductMaster PickList Items  *****************/
	private static transient List<SelectOption> lMasterProductItems;
	public List<SelectOption> masterProductItems {
		get
		{   
			if (lMasterProductItems == null) {
				lMasterProductItems = new List<SelectOption>();
				lMasterProductItems.add(new SelectOption('', '-- Select --'));
				for (Product2 masterProd : [SELECT Id, Name From Product2 WHERE RecordTypeId =: UtilityMethods.RecordTypeFor('Product2', 'Master_Product')]) {
					lMasterProductItems.add(new SelectOption(masterProd.Id, masterProd.Name));
				}
			}			   
			return lMasterProductItems;
		}
	}

	/******* Set up Measurement Fraction Items  *****************/
	private static transient List<SelectOption> lMeasurementFractionItems;
	public List<SelectOption> measurementFractionItems{
		get
		{   
			Set<String> currentValues = new Set<String>{orderLineItem.Width_Fraction__c,orderLineItem.Height_Fraction__c,orderLineItem.Right_Leg_Fraction__c,orderLineItem.Left_Leg_Fraction__c};
			if (lMeasurementFractionItems == null) {
				lMeasurementFractionItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Measurement_Fractions__c, currentValues);
			}			   
			return lMeasurementFractionItems;
		}
	}

	/*** Color Configuration Records *********/
	private static transient List<Color_Configuration__c> lColorConfigs;
	public List<Color_Configuration__c> colorConfigs{
		get
		{
			if (masterProductConfig == null) return new List<Color_Configuration__c>();
			
			if(lColorConfigs == null){
				lColorConfigs = [Select Exterior_Color__c, Interior_Color__c, Product_Configuration__c from Color_Configuration__c WHERE Product_Configuration__c =: masterProductConfig.Id];
			}
			return lColorConfigs;
		}
	}

	/******* Set up Exterior Color Items  *****************/
	private static transient List<SelectOption> lExteriorColorItems;
	public List<SelectOption> exteriorColorItems{
		get
		{   
			if (lExteriorColorItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Exterior_Color__c};
				Set<String> extColors = new Set<String>();
				for(Color_Configuration__c cc: ColorConfigs){
					if(cc.Exterior_Color__c != null){
						extColors.add(cc.Exterior_Color__c);
					}
				}
				String extColorsString = '';
				for(String color: extColors){
					extColorsString += color + ';';
				}
				lExteriorColorItems = RMS_ProdConfigManager.retrievePickListItems(extColorsString, currentValues);

			}			   
			return lExteriorColorItems;
		}
	}

	/******* Set up Interior Color Items  *****************/
	private static transient List<SelectOption> lInteriorColorItems;
	public List<SelectOption> interiorColorItems{
		get
		{   
			if (interiorColorItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Interior_Color__c};
				Set<String> intColors = new Set<String>();
				for(Color_Configuration__c cc: ColorConfigs){
					if(cc.Interior_Color__c != null){
						for (String c : cc.Interior_Color__c.split(';')) {
					   		intColors.add(c);
					   	}
					}
				}
				String intColorsString = '';
				for(String color: intColors){
					intColorsString += color + ';';
				}

				lInteriorColorItems = RMS_ProdConfigManager.retrievePickListItems(intColorsString, currentValues);

			}			   
			return lInteriorColorItems;
		}
	}


	/******* Glazing Items  *****************/
	private static transient List<SelectOption> lGlazingItems;
	public List<SelectOption> glazingItems {
		get
		{   
			if (lGlazingItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Glazing_S1__c,orderLineItem.Glazing_S2__c,orderLineItem.Glazing_S3__c,orderLineItem.Glazing_S4__c};
				lGlazingItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Glazing__c, currentValues);
			}			   
			return lGlazingItems;
		}
	} 

	/******* Glass Pattern Items  *****************/
	private static transient List<SelectOption> lGlassPatternItems;
	public List<SelectOption> glassPatternItems {
		get
		{   
			if (lGlassPatternItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Glass_Pattern_S1__c,orderLineItem.Glass_Pattern_S2__c,orderLineItem.Glass_Pattern_S3__c,orderLineItem.Glass_Pattern_S4__c};
				lGlassPatternItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Glass_Pattern__c, currentValues);
			}			   
			return lGlassPatternItems;
		}
	} 

	/******* Grille Style Items  *****************/
	private static transient List<SelectOption> lGrilleStyleItems;
	public List<SelectOption> grilleStyleItems {
		get
		{   
			if (lGrilleStyleItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Grille_Style__c};
				lGrilleStyleItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Grille_Style__c, currentValues);
			}			   
			return lGrilleStyleItems;
		}
	} 

	/******* Grille Pattern Items  *****************/
	private static transient List<SelectOption> lGrillePatternItems;
	public List<SelectOption> grillePatternItems{
		get
		{   
			if (lGrillePatternItems== null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Grille_Pattern__c};
				lGrillePatternItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Grille_Patterns__c, currentValues);
			}
			return lGrillePatternItems;
		}
	}

	/******* Grille Lights Wide Items Items  *****************/
	private static transient List<SelectOption> lLitesWideItems;
	public List<SelectOption> litesWideItems{
		get
		{   
			if (lLitesWideItems== null) {
				Set<String> currentValues = new Set<String>{string.valueof(orderLineItem.Lites_Wide_S1__c),string.valueof(orderLineItem.Lites_Wide_S2__c),string.valueof(orderLineItem.Lites_Wide_S4__c)};
				lLitesWideItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Lites_Wide__c, currentValues);
			}			   
			return lLitesWideItems;
		}
	}

	/******* Grille Lights High Items Items  *****************/
	private static transient List<SelectOption> lLitesHighItems;
	public List<SelectOption> litesHighItems{
		get
		{   
			if (lLitesHighItems== null) {
				Set<String> currentValues = new Set<String>{string.valueof(orderLineItem.Lites_High_S1__c),string.valueof(orderLineItem.Lites_High_S2__c),string.valueof(orderLineItem.Lites_High_S4__c)};
				lLitesHighItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Lites_High__c, currentValues);
			}			   
			return lLitesHighItems;
		}
	}

	/******* Hub Items  *****************/
	private static transient List<SelectOption> lHubItems;
	public List<SelectOption> hubItems{
		get
		{   
			if (lHubItems== null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Hubs__c};
				lHubItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Hubs__c, currentValues);
			}			   
			return lHubItems;
		}
	}

	/******* Spoke Items  *****************/
	private static transient List<SelectOption> lSpokeItems;
	public List<SelectOption> spokeItems{
		get
		{   
			if (lSpokeItems== null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Spokes__c};
				lSpokeItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Spokes__c, currentValues);
			}			   
			return lSpokeItems;
		}
	}

	/******* Exterior Trim Items  *****************/
	private static transient List<SelectOption> lExteriorTrimItems;
	public List<SelectOption> exteriorTrimItems {
		get
		{   
			if (lExteriorTrimItems== null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Exterior_Trim__c};
				lExteriorTrimItems= RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Exterior_Trim__c, currentValues);
			}			   
			return lExteriorTrimItems;
		}
	} 

	/******* Frame Type Items  *****************/
	private static transient List<SelectOption> lFrameTypeItems;
	public List<SelectOption> frameTypeItems {
		get
		{   
			if (lFrameTypeItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Frame_Type__c};
				lFrameTypeItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Frame_Type__c, currentValues);
			}			   
			return lFrameTypeItems;
		}
	} 

	/******* Checkrail Style Items  *****************/
	private static transient List<SelectOption> lCheckrailStyleItems;
	public List<SelectOption> checkrailStyleItems {
		get
		{   
			if (lCheckrailStyleItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Checkrail_Style__c};
				lCheckrailStyleItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Checkrail_Style__c, currentValues);
			}			   
			return lCheckrailStyleItems;
		}
	} 

	/******* Interior Trim Items  *****************/
	private static transient List<SelectOption> lInteriorTrimItems;
	public List<SelectOption> interiorTrimItems {
		get
		{   
			if (lInteriorTrimItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Interior_Trim__c};
				lInteriorTrimItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Interior_Trim__c, currentValues);
			}			   
			return lInteriorTrimItems;
		}
	} 

	/******* Set up Hardware Finish Items  *****************/
	private static transient List<SelectOption> lHardwareFinishItems;
	public List<SelectOption> hardwareFinishItems{
		get
		{   
			if (lHardwareFinishItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Hardware_Finish__c};
				lHardwareFinishItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Hardware_Finish__c, currentValues);
			}			   
			return lHardwareFinishItems;
		}
	}

	/******* Set up Hardware Color Items  *****************/
	private static transient List<SelectOption> lHardwareColorItems;
	public List<SelectOption> hardwareColorItems{
		get
		{   
			if (lHardwareColorItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Hardware_Color__c};
				lHardwareColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Hardware_Color__c, currentValues);
			}			   
			return lHardwareColorItems;
		}
	}

	/******* Set up Hardware Finish Color Items  *****************/
	private static transient List<SelectOption> lHardwareFinishColorItems;
	public List<SelectOption> hardwareFinishColorItems{
		get
		{   
			if (lHardwareFinishColorItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Hardware_Finish_Color__c};
				lHardwareFinishColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Hardware_Finish_Color__c, currentValues);
			}			   
			return lHardwareFinishColorItems;
		}
	}

	/******* Set up Height Left or Right Items *****************/
	private static transient List<SelectOption> lLeftOrRightItems;
	public List<SelectOption> isHeightlOrR{
		get
		{   
			if (lLeftOrRightItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Is_Height_L_or_R_Leg_Height__c};
				lLeftOrRightItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Is_Height_L_or_R_Leg_Height__c, currentValues);
			}			   
			return lLeftOrRightItems;
		}
	}

	/******* Set up Leg Height Left or Right Items *****************/
	private static transient List<SelectOption> lLegLeftOrRightItems;
	public List<SelectOption> isLegHeightlOrR{
		get
		{   
			if (lLegLeftOrRightItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Is_Leg_Height_L_or_R_Leg_Height__c};
				lLegLeftOrRightItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Is_Leg_Height_L_or_R_Leg_Height__c, currentValues);
			}			   
			return lLegLeftOrRightItems;
		}
	}

	/******* Set up Leg Height Exterior Fraction Items *****************/
	private static transient List<SelectOption> llegExteriorFractionItems;
	public List<SelectOption> legExteriorFractionItems{
		get
		{   
			if (llegExteriorFractionItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Leg_Height_Exterior_Fraction__c};
				llegExteriorFractionItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Leg_Height_Exterior_Fraction__c, currentValues);
			}			   
			return llegExteriorFractionItems;
		}
	}

	/******* Set up Leg Height Interior Fraction Items *****************/
	private static transient List<SelectOption> llegInteriorFractionItems;
	public List<SelectOption> legInteriorFractionItems{
		get
		{   
			if (llegInteriorFractionItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Leg_Height_Interior_Fraction__c};
				llegInteriorFractionItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Leg_Height_Interior_Fraction__c, currentValues);
			}			   
			return llegInteriorFractionItems;
		}
	}

	/******* Set up Meet Rail Dimension Items *****************/
	private static transient List<SelectOption> lMeetRailDimensionItems;
	public List<SelectOption> meetRailDimension{
		get
		{   
			if (lMeetRailDimensionItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Meet_Rail_Dimension__c};
				lMeetRailDimensionItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Meet_Rail_Dimension__c, currentValues);
			}			   
			return lMeetRailDimensionItems;
		}
	}


	/******* Set up Hardware Style Items  *****************/
	private static transient List<SelectOption> lHardwareStyleItems;
	public List<SelectOption> hardwareStyleItems{
		get
		{   
			if (lHardwareStyleItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Hardware_Style__c};
				lHardwareStyleItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Hardware_Style__c, currentValues);
			}			   
			return lHardwareStyleItems;
		}
	}

	/******* Set up Hardware Option Items  *****************/
	private static transient List<SelectOption> lHardwareOptionItems;
	public List<SelectOption> hardwareOptionItems{
		get
		{   
			if (lHardwareOptionItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Hardware_Option__c};
				lHardwareOptionItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Hardware_Option__c, currentValues);
			}			   
			return lHardwareOptionItems;
		}
	}

	/******* Lifts Pulls Items  *****************/
	private static transient List<SelectOption> lLiftsPullsItems;
	public List<SelectOption> liftsPullsItems {
		get
		{   
			if (lLiftsPullsItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Lifts_Pulls__c};
				lLiftsPullsItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Lifts_Pulls__c, currentValues);
			}			   
			return lLiftsPullsItems;
		}
	} 

	/******* Locks Sash Items  *****************/
	private static transient List<SelectOption> lLocksSashItems;
	public List<SelectOption> locksSashItems {
		get
		{   
			if (lLocksSashItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Locks_Sash__c};
				lLocksSashItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Locks_Sash__c, currentValues);
			}			   
			return lLocksSashItems;
		}
	} 

	/******* Finger Lifts Items  *****************/
	private static transient List<SelectOption> lfingerLiftItems;
	public List<SelectOption> fingerLiftItems {
		get
		{   
			if (lfingerLiftItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Finger_Lifts__c};
				lfingerLiftItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Finger_Lifts__c, currentValues);
			}			   
			return lfingerLiftItems;
		}
	} 

	/******* Screen Type Items  *****************/
	private static transient List<SelectOption> lScreenTypeItems;
	public List<SelectOption> screenTypeItems {
		get
		{   
			if (lScreenTypeItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Screen_Type__c};
				lScreenTypeItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Screen_Type__c, currentValues);
			}
			return lScreenTypeItems;
		}
	} 

	/******* Screen Veneer Type Items  *****************/
/*	private static transient List<SelectOption> lScreenVeneerTypeItems;
	public List<SelectOption> screenVeneerTypeItems{
		get
		{   
			if (lScreenVeneerTypeItems== null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Screen_Veneer_Type__c};
				lScreenVeneerTypeItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Screen_Veneer_Type__c, currentValues);
			}
			return lScreenVeneerTypeItems;
		}
	}*/

	/******* Sill Angle Items  *****************/
	private static transient List<SelectOption> lSillAngleItems;
	public List<SelectOption> sillAngleItems{
		get
		{   
			if (lSillAngleItems== null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Sill_Angle__c};
				lSillAngleItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Sill_Angle__c, currentValues);
			}
			return lSillAngleItems;
		}
	}

	/******* Mull Sequence Mullion Items  *****************/
	private static transient List<SelectOption> lMullSequenceMullionItems;
	public List<SelectOption> mullSequenceMullionItems{
		get
		{   
			if (lMullSequenceMullionItems== null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Mull_Sequence_Mullion__c};
				lMullSequenceMullionItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Mull_Sequence_Mullion__c, currentValues);
			}
			return lMullSequenceMullionItems;
		}
	}

	/******* Sash Ratio Items  *****************/
	private static transient List<SelectOption> lSashRatioItems;
	public List<SelectOption> sashRatioItems{
		get
		{   
			if (lSashRatioItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Sash_Ratio__c};
				lSashRatioItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Sash_Ratio__c, currentValues);
			}
			return lSashRatioItems;
		}
	}

	/******* Sash Operation Items  *****************/
	private static transient List<SelectOption> lSashOperationItems;
	public List<SelectOption> sashOperationItems{
		get
		{   
			if (lSashOperationItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Sash_Operation__c};
				lSashOperationItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Sash_Operation__c, currentValues);
			}
			return lSashOperationItems;
		}
	}

	/******* EJ Thickness Items  *****************/
	private static transient List<SelectOption> lEJThicknessItems;
	public List<SelectOption> EJThicknessItems{
		get
		{   
			if (lEJThicknessItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.EJ_Thickness__c};
				lEJThicknessItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.EJ_Thickness__c, currentValues);
			}
			return lEJThicknessItems;
		}
	}

	/******* EJ Wall Depth Items  *****************/
	private static transient List<SelectOption> lEJWallDepthItems;
	public List<SelectOption> EJWallDepthItems{
		get
		{   
			if (lEJWallDepthItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.EJ_Wall_Depth__c};
				lEJWallDepthItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.EJ_Wall_Depth__c, currentValues);
			}
			return lEJWallDepthItems;
		}
	}

	/******* EJ Species Items  *****************/
	private static transient List<SelectOption> lEJSpeciesItems;
	public List<SelectOption> EJSpeciesItems{
		get
		{   
			if (lEJSpeciesItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.EJ_Species__c};
				lEJSpeciesItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.EJ_Species__c, currentValues);
			}
			return lEJSpeciesItems;
		}
	}

	/******* EJ Color Items  *****************/
	private static transient List<SelectOption> lEJColorItems;
	public List<SelectOption> EJColorItems{
		get
		{   
			if (lEJColorItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.EJ_Color__c};
				lEJColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.EJ_Color__c, currentValues);
			}
			return lEJColorItems;
		}
	}

	/******* Casing Profile Items  *****************/
	private static transient List<SelectOption> lCasingProfileItems;
	public List<SelectOption> casingProfileItems{
		get
		{   
			if (lCasingProfileItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Casing_Profile__c};
				lCasingProfileItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Casing_Profile__c, currentValues);
			}
			return lCasingProfileItems;
		}
	}

	/******* Casing Species Items  *****************/
	private static transient List<SelectOption> lCasingSpeciesItems;
	public List<SelectOption> casingSpeciesItems{
		get
		{   
			if (lCasingSpeciesItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Casing_Species__c};
				lCasingSpeciesItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Casing_Species__c, currentValues);
			}
			return lCasingSpeciesItems;
		}
	}

	/******* Casing Location Items  *****************/
	private static transient List<SelectOption> lCasingLocationItems;
	public List<SelectOption> casingLocationItems{
		get
		{   
			if (lCasingLocationItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Casing_Location__c};
				lCasingLocationItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Casing_Location__c, currentValues);
			}
			return lCasingLocationItems;
		}
	}

	/******* Brickmould Location Items  *****************/
	private static transient List<SelectOption> lBrickmouldLocationItems;
	public List<SelectOption> brickmouldLocationItems{
		get
		{   
			if (lBrickmouldLocationItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Brickmould_Location__c};
				lBrickmouldLocationItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Brickmould_Location__c, currentValues);
			}
			return lBrickmouldLocationItems;
		}
	}

	/******* Drip Cap Pieces Items  *****************/
	private static transient List<SelectOption> lDripCapPiecesItems;
	public List<SelectOption> dripCapPiecesItems{
		get
		{   
			if (lDripCapPiecesItems == null) {
				Set<String> currentValues = new Set<String>{string.valueof(orderLineItem.Drip_Cap_Pieces__c)};
				lDripCapPiecesItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Drip_Cap_Pieces__c, currentValues);
			}
			return lDripCapPiecesItems;
		}
	}

	/******* Screen Color Items  *****************/
	private static transient List<SelectOption> lScreenColorItems;
	public List<SelectOption> screenColorItems{
		get
		{   
			if (lScreenColorItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Screen_Color__c};
				lScreenColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Screen_Color__c, currentValues);
			}
			return lScreenColorItems;
		}
	}

	/******* Exterior Grille Color Items  *****************/
	private static transient List<SelectOption> lExteriorGrilleColorItems;
	public List<SelectOption> exteriorGrilleColorItems{
		get
		{   
			if (lExteriorGrilleColorItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Exterior_Grille_Color__c};
				lExteriorGrilleColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Exterior_Grille_Color__c, currentValues);
			}
			return lExteriorGrilleColorItems;
		}
	}

	/******* Interior Grille Color Items  *****************/
	private static transient List<SelectOption> lInteriorGrilleColorItems;
	public List<SelectOption> interiorGrilleColorItems{
		get
		{   
			if (lInteriorGrilleColorItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Interior_Grille_Color__c};
				lInteriorGrilleColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Interior_Grille_Color__c, currentValues);
			}
			return lInteriorGrilleColorItems;
		}
	}

	/******* Storm Window Color Items  *****************/
	private static transient List<SelectOption> lStormWindowColorItems;
	public List<SelectOption> StormWindowColorItems{
		get
		{   
			if (lStormWindowColorItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Storm_Window_Color__c};
				lStormWindowColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Storm_Window_Color__c, currentValues);
			}
			return lStormWindowColorItems;
		}
	}

	/******* Exterior Trim Color Items  *****************/
	private static transient List<SelectOption> lExteriorTrimColorItems;
	public List<SelectOption> ExteriorTrimColorItems{
		get
		{   
			if (lExteriorTrimColorItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Exterior_Trim_Color__c};
				lExteriorTrimColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Exterior_Trim_Color__c, currentValues);
			}
			return lExteriorTrimColorItems;
		}
	}

	/******* Jamb Liner Color Items  *****************/
	private static transient List<SelectOption> lJambLinerColorItems;
	public List<SelectOption> JambLinerColorItems{
		get
		{   
			if (lJambLinerColorItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Jamb_Liner_Color__c};
				lJambLinerColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Jamb_Liner_Color__c, currentValues);
			}
			return lJambLinerColorItems;
		}
	}

	/******* Interior Sash Color Items  *****************/
	private static transient List<SelectOption> lInteriorSashColorItems;
	public List<SelectOption> interiorSashColorItems{
		get
		{   
			if (lInteriorSashColorItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Interior_Sash_Color__c};
				lInteriorSashColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Interior_Sash_Color__c, currentValues);
			}
			return lInteriorSashColorItems;
		}
	}

	/******* Astragal Color Items  *****************/
	private static transient List<SelectOption> lAstragalColorItems;
	public List<SelectOption> astragalColorItems{
		get
		{   
			if (lAstragalColorItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Astragal__c};
				lAstragalColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Astragal__c, currentValues);
			}
			return lAstragalColorItems;
		}
	}

	/******* Storm Window Items  *****************/
	private static transient List<SelectOption> lStormWindowItems;
	public List<SelectOption> stormWindowItems{
		get
		{   
			if (lStormWindowItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Storm_Window__c};
				lStormWindowItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Storm_Window__c, currentValues);
			}
			return lStormWindowItems;
		}
	}

	/******* Storm Window Items  *****************/
	private static transient List<SelectOption> lStormWindowStyleItems;
	public List<SelectOption> stormWindowStyleItems{
		get
		{   
			if (lStormWindowStyleItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Storm_Window_Style__c};
				lStormWindowStyleItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Storm_Window_Style__c, currentValues);
			}
			return lStormWindowStyleItems;
		}
	}

	/******* Install Track Location Items  *****************/
	private static transient List<SelectOption> lInstallTrackLocationItems;
	public List<SelectOption> installTrackLocationItems{
		get
		{   
			if (lInstallTrackLocationItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Install_Track_Location__c};
				lInstallTrackLocationItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Install_Track_Location__c, currentValues);
			}
			return lInstallTrackLocationItems;
		}
	}
	
	
	/******* Interior Pre Finish Items  *****************/
	private static transient List<SelectOption> linteriorPreFinishItems;
	public List<SelectOption> interiorPreFinishItems{
		get
		{   
			if (linteriorPreFinishItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Interior_Pre_Finish__c};
				linteriorPreFinishItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Interior_Pre_Finish__c, currentValues);
			}
			return linteriorPreFinishItems;
		}
	}

	
	/******* Exterior Frame Depth Items  *****************/
	private static transient List<SelectOption> lExteriorFrameDepthItems;
	public List<SelectOption> ExteriorFrameDepthItems{
		get
		{   
			if (lExteriorFrameDepthItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Exterior_Frame_Depth__c};
				lExteriorFrameDepthItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Exterior_Frame_Depth__c, currentValues);
			}
			return lExteriorFrameDepthItems;
		}
	}
 
 	/******* Door Sill Color Items  *****************/
	private static transient List<SelectOption> lDoorSillColorItems;
	public List<SelectOption> DoorSillColorItems{
		get
		{   
			if (lDoorSillColorItems == null) {
				Set<String> currentValues = new Set<String>{orderLineItem.Door_Sill_Color__c};
				lDoorSillColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Door_Sill_Color__c, currentValues);
			}
			return lDoorSillColorItems;
		}
	} 
	
	


	/*******************************************************
					enterProduct method
	*******************************************************/
	// runs whenever the Enter button is clicked at the master product level
	public virtual pageReference enterProduct() {

		if (masterProductId == '' || masterProductId == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.PRODUCT_EMPTY));
			return null;
		}
		prodConfig = RMS_prodConfigManager.findProductConfiguration(orderLineItem, null, masterProductConfig);
		productSelected = true;
		
		// If there is a product config, and we're in edit mode, retrieve the default inside track location
		// for the store 
		if (prodConfig != null && mode == 'e') {
			for (Order ord : [SELECT Id, Store_Location__r.Active_Store_Configuration__r.Default_Install_Track_Location__c FROM Order WHERE Id =: orderId]) {
				defaultInstallTrackLocation = ord.Store_Location__r.Active_Store_Configuration__r.Default_Install_Track_Location__c;
			}
		}
		// Default the verify item config to true if a product configuration record was found
		orderLineItem.Verify_Item_Configuration__c = (mode == 'v') ? orderLineItem.Verify_Item_Configuration__c :
		 											 (prodConfig.mpc != null && !orderLineItem.NSPR__c) ? true : false;
		verifyProducts = orderLineItem.Verify_Item_Configuration__c;
		return null;

	}

	/*******************************************************
					saveProduct method
	*******************************************************/
	// runs whenever the Save button is clicked at the child product level
	public virtual pageReference saveProduct() {

		// Set these flags to true so we know to exit the javascript before redirecting
		errorOccurred = 'true';

		if (orderLineItem.Quantity == null || orderLineItem.Quantity < 1) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.QUANTITY_EMPTY));
			return null;			
		}
		inputUI = (orderLineItem.Width_Inches__c != null && orderLineItem.Height_Inches__c != null) ?
					orderLineItem.Width_Inches__c + orderLineItem.Height_Inches__c : 0;

		// Only verify the makeability rules when Verify Item Config is checked
		if (orderLineItem.Verify_Item_Configuration__c) {
			
			String errorMessage = RMS_prodConfigManager.checkMakeability(masterProductConfig, orderLineItem, masterProduct.Name);
			if(!String.isBlank(errorMessage)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
				return null;			
			} 
		} 
		if (childProduct != null)
			prodConfig = RMS_prodConfigManager.findPricingConfiguration(prodConfig, priceBookId, childProduct.Id);
		
//		orderLineItem.unitPrice = RMS_prodConfigManager.calculatePrice(prodConfig);
		if(orderLineItem.unitPrice == null) orderLineItem.unitPrice = 0;
		if (newOrderItem) {
			System.debug('PRICE BOOK ' + priceBookEntryId);
			orderLineItem.PriceBookEntryId = priceBookEntryId;
			System.Debug('**********************orderLineItemFinal=' +orderLineItem);
			insert orderLineItem;
			oiId = orderLineItem.Id;  // used to redirect to correct tab 
		}
		else {
			if (orderLineItem.PriceBookEntryId != priceBookEntryId) {
				OrderItem newOrderLineItem = orderLineItem.clone(false,true);
				newOrderLineItem.PriceBookEntryId = priceBookEntryId;
				// for this scenario we will need to make sure we clear out selected options that are not available
				// on the new order line item  
				if (masterProductConfig != null)
					newOrderLineItem = clearNonSelectableValues(newOrderLineItem, masterProductConfig);
				insert newOrderLineItem;
				delete orderLineItem;				
				oiId = newOrderLineItem.Id;  // used to redirect to correct tab 
				
			}
			else {
				upsert orderLineItem;
				oiId = orderLineItem.Id;  // used to redirect to correct tab 
			}
		}	

		// Check to see if the purchase order has changed and calculate
		// taxes if so
		if (poId != orderLineItem.Purchase_Order__c) {
			String errorMessage = RMS_prodConfigManager.updateTaxes(orderLineItem.Purchase_Order__c);
			if(!String.isBlank(errorMessage)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
				return null;			
			} 
		}
		// Set this flag back to false so we know it's ok to redirect from javascript
		errorOccurred = 'false';

	PageReference p = page.RMS_prodConfigEdit;

	// Get all of the url parameters from the current url and put them in the new url
	Map<String, String> m = p.getParameters();
    m.put('mode', 'v');
    m.put('id', orderLineItem.Id);
    if(orderLineItem.Extended_Width_Warning__c){
		m.put('extWidthWarning',masterProductConfig.Width_Message__c);
	}
    if(orderLineItem.Extended_Height_Warning__c){
    	m.put('extHeightWarning',masterProductConfig.Height_Message__c);
    }
	p.setRedirect(true);

	return p;	}

	/*******************************************************
					close method
	*******************************************************/
	public virtual PageReference close() {
		system.debug('*****Close button pressed');
		errorOccurred = 'false';
		return null;
	}

	/*******************************************************
					edit method
	*******************************************************/
	public virtual PageReference edit() {
		system.debug('*****Edit button pressed');
//		errorOccurred = 'false';

	PageReference p = page.RMS_prodConfigEdit;

	// Get all of the url parameters from the current url and put them in the new url
	Map<String, String> m = p.getParameters();
    m.put('mode', 'e');
    m.put('id', orderLineItem.Id);
	p.setRedirect(true);

	return p;


 
	}

	/**********************************************************
	clearNonSelectableValues(newOrderLineItem, masterProductConfig)
	**********************************************************/
	public static OrderItem clearNonSelectableValues(OrderItem oI, Product_Configuration__c newProdConfig){
		//DYNAMICLY GET ALL FIELDS ON THE PRODUCT CONFIG
    	SObjectType xPC = Schema.getGlobalDescribe().get('Product_Configuration__c');
      	map<String,Schema.SObjectField> pcFieldsMap = xPC.getDescribe().fields.getMap();
		list<String> activatedControlFieldNames = new list<String>();
		  
		for(String pcField : pcFieldsMap.KeySet()){
			if(pcField.contains('control') && (newProdConfig.get(pcField) == 'Disabled' || newProdConfig.get(pcField) == null) ){
				activatedControlFieldNames.add(pcField);
}		}
		for(String pcField : activatedControlFieldNames){
			String controlledField = pcField.replace('_control', '');

			Map<String, Schema.SObjectField> OrderItemFieldsMap = Schema.SObjectType.OrderItem.fields.getMap();
			Set<String> OrderItemFields = OrderItemFieldsMap.keySet();

			if(OrderItemFields.contains(controlledField)) {
				Schema.SObjectField field = OrderItemFieldsMap.get(controlledField);
				Schema.DisplayType fldType = field.getDescribe().getType();
			
				if(String.ValueOf(fldType) == 'BOOLEAN'){
					oI.put(controlledField, false);
				}else{
					oI.put(controlledField, null);
				}
			}
			
			/*
			list<String> selectedOptions = String.valueOf(newProdConfig.get(pcField)).split(';');
			boolean foundMatch = false;
			for(String option : selectedOptions){
				if(oI.get(pcField) == option ){
					foundMatch = true;
					break;
				}
			}
			if(foundMatch == false){
				oI.put(pcField, null);
			}
			*/
		}
		
		//If Prod Config -> Special Options Control is disabled clear the following Order Line Item fields:
		if(newProdConfig.Special_Options_Control__c == 'Disabled' || newProdConfig.Special_Options_Control__c == null) {
			oI.Screen_Color__c = null;
			oI.Hardware_Color__c = null;	
			oI.Exterior_Grille_Color__c = null;	
			oI.Interior_Grille_Color__c = null;	
			oI.Storm_Window_Color__c = null;	
			oI.Exterior_Trim_Color__c = null;	
			oI.Jamb_Liner_Color__c = null;	
			oI.Interior_Sash_Color__c = null;
			oI.Astragal__c = null;	
			oI.Install_Track_Location__c = null;	
			oI.Install_Holes_Location__c = null;	
			oI.Glazing_S3__c = null;	
			oI.Glass_Pattern_S3__c = null;	
			oI.Tempered_S3__c = false;
		}

		//If any of the glass/grille controls are disabled, clear the corresponding Sash 1 fields:
		if(newProdConfig.Grille_Pattern_Control__c == 'Disabled' || newProdConfig.Grille_Pattern_Control__c == null) {
			oI.Grille_Pattern__c    = null;
			oI.Grille_Pattern_S1__c = null;
			oI.Grille_Pattern_S2__c = null;
			oI.Grille_Pattern_S3__c = null;
			oI.Grille_Pattern_S4__c = null;
		}
		if(newProdConfig.Grille_Lites_Control__c == 'Disabled' || newProdConfig.Grille_Lites_Control__c == null) {
			oI.Lites_Wide_S1__c = null;	
			oI.Lites_High_S1__c = null;	
			oI.Lites_Wide_S2__c = null;	
			oI.Lites_High_S2__c = null;	
			oI.Lites_Wide_S3__c = null;	
			oI.Lites_High_S3__c = null;	
			oI.Lites_Wide_S4__c = null;	
			oI.Lites_High_S4__c = null;	
		}
		if(newProdConfig.Custom_Grille_Details_Control__c == 'Disabled' || newProdConfig.Custom_Grille_Details_Control__c == null) {
			oI.Custom_Grille_Details_S1__c	= null;
			oI.Custom_Grille_Details_S2__c	= null;
			oI.Custom_Grille_Details_S3__c	= null;
			oI.Custom_Grille_Details_S4__c	= null;
		}
		
		//If Prod Config -> Number of Sashes = null, clear the following Order Line Item fields:
		if(newProdConfig.Number_of_Sashes__c == null){
			oI.Grille_Pattern__c = null;
			oI.Grille_Pattern_S1__c = null;
			oI.Lites_Wide_S1__c = null;	
			oI.Lites_High_S1__c = null;	
			oI.Custom_Grille_Details_S1__c	= null;
			oI.Glazing_S1__c = null;	
			oI.Glass_Pattern_S1__c = null; 
			oI.Tempered_S1__c = false;
		}
		//If Prod Config -> Number of Sashes = 1, clear the following Order Line Item fields:
		if(newProdConfig.Number_of_Sashes__c == '1'){
			oI.Grille_Pattern_S2__c = null;
			oI.Lites_Wide_S2__c = null;	
			oI.Lites_High_S2__c = null;	
			oI.Custom_Grille_Details_S2__c	= null;
			oI.Glazing_S2__c = null;	
			oI.Glass_Pattern_S2__c = null; 
			oI.Tempered_S2__c = false;
		}
		//If Prod Config -> Number of Sashes = 1 or 2, clear the following Order Line Item fields:
		if(newProdConfig.Number_of_Sashes__c == '1' || newProdConfig.Number_of_Sashes__c == '2'){
			oI.Grille_Pattern_S3__c = null;
			oI.Lites_Wide_S3__c = null;	
			oI.Lites_High_S3__c = null;	
			oI.Custom_Grille_Details_S3__c	= null;
			oI.Glazing_S3__c = null;	
			oI.Glass_Pattern_S3__c = null; 
			oI.Tempered_S3__c = false;
		}
		//JETT-2171 If Prod Config -> Number of Sashes = 1 or 2 or 3 , clear the following Order Line Item fields:
		if(newProdConfig.Number_of_Sashes__c == '1' || newProdConfig.Number_of_Sashes__c == '2' || newProdConfig.Number_of_Sashes__c == '3'){
			oI.Grille_Pattern_S4__c = null;
			oI.Lites_Wide_S4__c = null;	
			oI.Lites_High_S4__c = null;	
			oI.Custom_Grille_Details_S4__c	= null;
			oI.Glazing_S4__c = null;	
			oI.Glass_Pattern_S4__c = null; 
			oI.Tempered_S4__c = false;
		}

		return oI;
	}//END OF clearNonSelectableValues Method
	

}//EOF
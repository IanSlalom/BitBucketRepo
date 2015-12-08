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
	public boolean orderActivated {get; set;}	 
	public String priceBookId {get; set;}   
	public String orderId {get; set;}   
	public String oiId {get;set;} // used for redirecting of tabs
	public Decimal inputUI;	
	public String exteriorColor {get; set;}	 
	public String interiorColor {get; set;}	 
	public String errorOccurred {get; set;}	 


	/******* Set up Standard Controller for OrderItem  *****************/
	private final OrderItem orderLineItem;

	public RMS_prodConfigExtension(ApexPages.StandardController stdController) {
		this.orderLineItem = (OrderItem)stdController.getRecord();
		newOrderItem = stdController.getId() == null;
			
		// If this is a new order item, retrieve the order and pricebook id from the url params
		if (newOrderItem) {
			newOrderItem = true;
			this.orderLineItem.OrderId = ApexPages.currentPage().getParameters().get('oid');
			orderId = orderLineItem.OrderId;
			priceBookId = ApexPages.currentPage().getParameters().get('pid');		 
		// If we are editing an order item, retrieve the master product and price book id from the order item
		} else {
				for (OrderItem orderItem : [SELECT Id, PricebookEntryId, PricebookEntry.Pricebook2Id, PricebookEntry.Product2Id, PricebookEntry.Product2.Master_Product__c, Order.Status From OrderItem WHERE Id =: orderLineItem.Id]) {
					masterProductId = orderItem.PricebookEntry.Product2.Master_Product__c;
					priceBookId = String.ValueOf(orderItem.PricebookEntry.Pricebook2Id);
					orderId = orderItem.OrderId;
					if (orderItem.Order.Status == 'Activated') {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.ORDER_ACTIVATED_EDIT));
						orderActivated = true;
					}
				}
		}
	}

	/******* public properties  *****************/
	public String inputWidth {get;set;}
	public String inputHeight {get;set;}
	public boolean productSelected {get;set;}	
	
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
			lMasterProduct = [SELECT Name, Product_Configuration__c
															FROM Product2
															WHERE Id =: masterProductId
															limit 1].get(0);
			return lMasterProduct;
		}
	}

	/******* properties/variables to store the master product configuration *****************/
	private static transient Product_Configuration__c lMasterProductConfig;
	public Product_Configuration__c masterProductConfig {
		get
		{   
			
			if (lMasterProductConfig != null) return lMasterProductConfig;
			if (masterProductId == '' || masterProductId == null)
				return null;
			if (masterProduct.Product_Configuration__c == null)
				return null;
			
			// Loop through the Product_Configuration__c fields and comma separate them into a string
			String commaSeparatedFields = RMS_prodConfigManager.getCommaSeparatedFields('Product_Configuration__c');
 
			// Use the comma separated field string to build a dynamic query to retrieve the Product_Configuration__c
			String query = 'SELECT ' + commaSeparatedFields + ' FROM Product_Configuration__c ' + 
													' WHERE Id = \'' + masterProduct.Product_Configuration__c + '\''+
													' LIMIT 1';
 
			// Retrieve all fields from the Product_Configuration__c object in a query
			lMasterProductConfig = Database.query(query);

			return lMasterProductConfig;
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

			// returns an error message if either 0 child products are found matching the criteria or multiple are found.
			if (count == 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.CHILD_PRODUCT_NOT_FOUND));
				return null;
			}
			if (count > 1) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.MULTIPLE_CHILD_PRODUCTS));
				return null;
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
			if (lMeasurementFractionItems == null) {
				lMeasurementFractionItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Measurement_Fractions__c);
			}			   
			return lMeasurementFractionItems;
		}
	}

	/******* Set up Exterior Color Items  *****************/
	private static transient List<SelectOption> lExteriorColorItems;
	public List<SelectOption> exteriorColorItems{
		get
		{   
			if (lExteriorColorItems == null) {
				lExteriorColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Exterior_Color__c);
			}			   
			return lExteriorColorItems;
		}
	}

	/******* Set up Interior Color Items  *****************/
	private static transient List<SelectOption> lInteriorColorItems;
	public List<SelectOption> interiorColorItems{
		get
		{   
			if (lInteriorColorItems == null) {
				lInteriorColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Interior_Color__c);
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
				lGlazingItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Glazing__c);
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
				lGlassPatternItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Glass_Pattern__c);
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
				lGrilleStyleItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Grille_Style__c);
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
				lGrillePatternItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Grille_Patterns__c);
			}
			return lGrillePatternItems;
		}
	}

	/******* Colonial Grille Lights Wide Items Items  *****************/
	private static transient List<SelectOption> lColonialGrilleLitesWideItems;
	public List<SelectOption> colonialGrilleLitesWideItems{
		get
		{   
			if (lColonialGrilleLitesWideItems== null) {
				lColonialGrilleLitesWideItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Colonial_Grille_Lites_Wide__c);
			}			   
			return lColonialGrilleLitesWideItems;
		}
	}

	/******* Colonial Grille Lights High Items Items  *****************/
	private static transient List<SelectOption> lColonialGrilleLitesHighItems;
	public List<SelectOption> colonialGrilleLitesHighItems{
		get
		{   
			if (lColonialGrilleLitesHighItems== null) {
				lColonialGrilleLitesHighItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Colonial_Grille_Lites_High__c);
			}			   
			return lColonialGrilleLitesHighItems;
		}
	}

	/******* Exterior Trim Items  *****************/
	private static transient List<SelectOption> lExteriorTrimItems;
	public List<SelectOption> exteriorTrimItems {
		get
		{   
			if (lExteriorTrimItems== null) {
				lExteriorTrimItems= RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Exterior_Trim__c);
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
				lFrameTypeItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Frame_Type__c);
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
				lCheckrailStyleItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Checkrail_Style__c);
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
				lInteriorTrimItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Interior_Trim__c);
			}			   
			return lInteriorTrimItems;
		}
	} 

	/******* Handing Option Items  *****************/
	private static transient List<SelectOption> lHandingOptionItems;
	public List<SelectOption> handingOptionItems {
		get
		{   
			if (lHandingOptionItems == null) {
				lHandingOptionItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Handing__c);
			}			   
			return lHandingOptionItems;
		}
	} 

	/******* Set up Hardware Finish Items  *****************/
	private static transient List<SelectOption> lHardwareFinishItems;
	public List<SelectOption> hardwareFinishItems{
		get
		{   
			if (lHardwareFinishItems == null) {
				lHardwareFinishItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Hardware_Finish__c);
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
				lHardwareColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Hardware_Color__c);
			}			   
			return lHardwareColorItems;
		}
	}

	/******* Set up Hardware Style Items  *****************/
	private static transient List<SelectOption> lHardwareStyleItems;
	public List<SelectOption> hardwareStyleItems{
		get
		{   
			if (lHardwareStyleItems == null) {
				lHardwareStyleItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Hardware_Style__c);
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
				lHardwareOptionItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Hardware_Option__c);
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
				lLiftsPullsItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Lifts_Pulls__c);
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
				lLocksSashItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Locks_Sash__c);
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
				lfingerLiftItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Finger_Lifts__c);
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
				lScreenTypeItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Screen_Type__c);
			}
			return lScreenTypeItems;
		}
	} 

	/******* Screen Vaneer Type Items  *****************/
	private static transient List<SelectOption> lScreenVaneerTypeItems;
	public List<SelectOption> screenVaneerTypeItems{
		get
		{   
			if (lScreenVaneerTypeItems== null) {
				lScreenVaneerTypeItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Screen_Vaneer_Type__c);
			}
			return lScreenVaneerTypeItems;
		}
	}

	/******* Sill Angle Items  *****************/
	private static transient List<SelectOption> lSillAngleItems;
	public List<SelectOption> sillAngleItems{
		get
		{   
			if (lSillAngleItems== null) {
				lSillAngleItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Sill_Angle__c);
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
				lMullSequenceMullionItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Mull_Sequence_Mullion__c);
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
				lSashRatioItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Sash_Ratio__c);
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
				lSashOperationItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Sash_Operation__c);
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
				lEJThicknessItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.EJ_Thickness__c);
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
				lEJWallDepthItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.EJ_Wall_Depth__c);
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
				lEJSpeciesItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.EJ_Species__c);
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
				lEJColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.EJ_Color__c);
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
				lCasingProfileItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Casing_Profile__c);
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
				lCasingSpeciesItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Casing_Species__c);
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
				lCasingLocationItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Casing_Location__c);
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
				lBrickmouldLocationItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Brickmould_Location__c);
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
				lDripCapPiecesItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Drip_Cap_Pieces__c);
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
				lScreenColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Screen_Color__c);
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
				lExteriorGrilleColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Exterior_Grille_Color__c);
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
				lInteriorGrilleColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Interior_Grille_Color__c);
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
				lStormWindowColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Storm_Window_Color__c);
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
				lExteriorTrimColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Exterior_Trim_Color__c);
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
				lJambLinerColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Jamb_Liner_Color__c);
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
				lInteriorSashColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Interior_Sash_Color__c);
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
				lAstragalColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Astragal__c);
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
				lStormWindowItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Storm_Window__c);
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
				lStormWindowStyleItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Storm_Window_Style__c);
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
				lInstallTrackLocationItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Install_Track_Location__c);
			}
			return lInstallTrackLocationItems;
		}
	}

	/*******************************************************
					enterProduct method
	*******************************************************/
	// runs whenever the Enter button is clicked at the master product level
	public virtual pageReference enterProduct() {

/*		
		inputUI = orderLineItem.Width_Inches__c + orderLineItem.Height_Inches__c;
		String errorMessage = RMS_prodConfigManager.checkMakeability(masterProductConfig, orderLineItem);
		if(!String.isBlank(errorMessage)) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
			return null;			
		}
		if (childProduct == null) return null;
		prodConfig = RMS_prodConfigManager.findProductConfiguration(orderLineItem, priceBookId, childProduct.Id, masterProductConfig);
		
		if (prodConfig == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.INVALID_CHILD_PRODUCT));
			return null;
		}
		productSelected = true;
		return null;
*/
		if (masterProductId == '' || masterProductId == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.PRODUCT_EMPTY));
			return null;
		}
		prodConfig = RMS_prodConfigManager.findProductConfiguration(orderLineItem, null, masterProductConfig);
		productSelected = true;
		
		// Default the verify item config to true if a product configuration record was found
		if (prodConfig.mpc != null) orderLineItem.Verify_Item_Configuration__c = true;
		return null;


	}

	/*******************************************************
					saveProduct method
	*******************************************************/
	// runs whenever the Save button is clicked at the child product level
	public virtual pageReference saveProduct() {

		// Set this flag to true so we know to exit the javascript before redirecting
		errorOccurred = 'true';

		if (orderLineItem.Quantity == null || orderLineItem.Quantity < 1) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.QUANTITY_EMPTY));
			return null;			
		}
		
		inputUI = orderLineItem.Width_Inches__c + orderLineItem.Height_Inches__c; 
		// Only verify the makeability rules when Verify Item Config is checked
		if (orderLineItem.Verify_Item_Configuration__c) {
			
			String errorMessage = RMS_prodConfigManager.checkMakeability(masterProductConfig, orderLineItem, masterProduct.Name);
			if(!String.isBlank(errorMessage)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
				return null;			
			}
		}
		if (childProduct == null) return null;
		System.Debug('****************prodConfig=' +prodConfig);
		System.Debug('****************priceBookId=' +priceBookId);
		System.Debug('****************childProduct.Id=' +childProduct.Id);
		prodConfig = RMS_prodConfigManager.findPricingConfiguration(prodConfig, priceBookId, childProduct.Id);
		
		if (prodConfig == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.INVALID_CHILD_PRODUCT));
			return null;
		}

		PageReference ref;
		orderLineItem.unitPrice = RMS_prodConfigManager.calculatePrice(prodConfig);
		if (newOrderItem) {
			orderLineItem.PriceBookEntryId = prodConfig.priceBookEntryId;
			System.Debug('**********************orderLineItemFinal=' +orderLineItem);
			insert orderLineItem;
			ref = new PageReference('/' +orderLineItem.OrderId);
		}
		else {
			if (orderLineItem.PriceBookEntryId != prodConfig.priceBookEntryId) {
				OrderItem newOrderLineItem = orderLineItem.clone(false,true);
				newOrderLineItem.PriceBookEntryId = prodConfig.priceBookEntryId;
				// for this scenario we will need to make sure we clear out selected options that are not available
				// on the new order line item  
				insert newOrderLineItem;
				delete orderLineItem;
				ref = new PageReference('/' +newOrderLineItem.OrderId);
				
			}
			else {
				upsert orderLineItem;
				ref = new PageReference('/' +orderLineItem.OrderId);
			}
		}	
		oiId = orderLineItem.Id;  // used to redirect to correct tab   
//		return ref;
		System.Debug('***************oiId=' +oiId);
		// Set this flag back to false so we know it's ok to redirect from javascript
		errorOccurred = 'false';
		return null;
	}

	/*******************************************************
					cancel method
	*******************************************************/
	public virtual PageReference cancel() {
		system.debug('*****Cancel button pressed');
		errorOccurred = 'false';
		return null;
	}

}
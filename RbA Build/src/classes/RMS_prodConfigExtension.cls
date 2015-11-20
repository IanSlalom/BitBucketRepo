/*******************************************************//**

@class    RMS_prodConfigExtension class

@brief    Extension for the prodConfig VF Page

    Manages all of the product config / pricing functionality

@author  Creston Kuenzi (Slalom.CDK)

@version    2015-07-22  Slalom.CDK
    Created.
@version    2015-11-09  Slalom.CDK
    Updated for first release to build

@see        RMS_prodConfigExtensionTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/
public class RMS_prodConfigExtension {

    /******* public variables  *****************/
    public boolean newOrderItem {get; set;}  
    public boolean orderActivated {get; set;}    
    public String priceBookId;   
    public Decimal inputUI; 
    public String exteriorColor {get; set;}  
    public String interiorColor {get; set;}  


    /******* Set up Standard Controller for OrderItem  *****************/
    private final OrderItem orderLineItem;

    public RMS_prodConfigExtension(ApexPages.StandardController stdController) {
        this.orderLineItem = (OrderItem)stdController.getRecord();
        newOrderItem = stdController.getId() == null;
            
        // If this is a new order item, retrieve the order and pricebook id from the url params
        if (newOrderItem) {
            newOrderItem = true;
            this.orderLineItem.OrderId = ApexPages.currentPage().getParameters().get('oid');
            priceBookId = ApexPages.currentPage().getParameters().get('pid');        
        // If we are editing an order item, retrieve the master product and price book id from the order item
        } else {
                for (OrderItem orderItem : [SELECT Id, PricebookEntryId, PricebookEntry.Pricebook2Id, PricebookEntry.Product2Id, PricebookEntry.Product2.Master_Product__c, Order.Status From OrderItem WHERE Id =: orderLineItem.Id]) {
                    masterProductId = orderItem.PricebookEntry.Product2.Master_Product__c;
                    priceBookId = String.ValueOf(orderItem.PricebookEntry.Pricebook2Id);
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
    public Integer inputQuantity {get;set;} 
    
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
                for (Product2 cProd : [SELECT Id, UI_Minimum__c, UI_Maximum__c From Product2 WHERE RecordTypeId =: UtilityMethods.RecordTypeFor('Product2', 'Child_Product')
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

	/******* Set up Width Fraction Items  *****************/
	private static transient List<SelectOption> lWidthFractionItems;
	public List<SelectOption> widthFractionItems{
		get
		{   
			if (lWidthFractionItems == null) {
				lWidthFractionItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Width_Fractions__c);
			}			   
			return lWidthFractionItems;
		}
	}

	/******* Set up Height Fraction Items  *****************/
	private static transient List<SelectOption> lHeightFractionItems;
	public List<SelectOption> heightFractionItems{
		get
		{   
			if (lHeightFractionItems == null) {
				lHeightFractionItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.mpc.Height_Fractions__c);
			}			   
			return lHeightFractionItems;
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
                lGrilleStyleItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.grilleStyles);
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
                lGrillePatternItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.grillePatterns);
            }
            return lGrillePatternItems;
        }
    }

    /******* Colonial Grille Lights Wide Items Items  *****************/
    private static transient List<SelectOption> lColonialGrilleLightsWideItems;
    public List<SelectOption> colonialGrilleLightsWideItems{
        get
        {   
            if (lColonialGrilleLightsWideItems== null) {
                lColonialGrilleLightsWideItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.colonialGrilleLightsWide);
            }              
            return lColonialGrilleLightsWideItems;
        }
    }

    /******* Colonial Grille Lights High Items Items  *****************/
    private static transient List<SelectOption> lColonialGrilleLightsHighItems;
    public List<SelectOption> colonialGrilleLightsHighItems{
        get
        {   
            if (lColonialGrilleLightsHighItems== null) {
                lColonialGrilleLightsHighItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.colonialGrilleLightsHigh);
            }              
            return lColonialGrilleLightsHighItems;
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
                lHandingOptionItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.handingOptions);
            }              
            return lHandingOptionItems;
        }
    } 

    /******* Set up Hardware Color Items  *****************/
    private static transient List<SelectOption> lHardwareColorItems;
    public List<SelectOption> hardwareColorItems{
        get
        {   
            if (lHardwareColorItems == null) {
                lHardwareColorItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.hardwareColors);
            }              
            return lHardwareColorItems;
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

    /******* Screen Vaneer Option Items  *****************/
    private static transient List<SelectOption> lScreenVaneerOptionItems;
    public List<SelectOption> screenVaneerOptionItems{
        get
        {   
            if (lScreenVaneerOptionItems== null) {
                lScreenVaneerOptionItems = RMS_prodConfigManager.retrievePickListItems(prodConfig.screenVaneerTypes);
            }
            return lScreenVaneerOptionItems;
        }
    }


    /*******************************************************
                    enterProduct method
    *******************************************************/
    // runs whenever the Enter button is clicked at the master product level
    public virtual pageReference enterProduct() {
        
//		inputUI = orderLineItem.Width__c + orderLineItem.Height__c;
		inputUI = 0;
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
    }

    /*******************************************************
                    saveProduct method
    *******************************************************/
    // runs whenever the Save button is clicked at the child product level
    public pageReference saveProduct() {
        PageReference ref;
        if (orderLineItem.Quantity == null) orderLineItem.Quantity = 1;
        orderLineItem.unitPrice = RMS_prodConfigManager.calculatePrice(prodConfig);
        if (newOrderItem) {
            orderLineItem.PriceBookEntryId = prodConfig.priceBookEntryId;
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
                update orderLineItem;
                ref = new PageReference('/' +orderLineItem.OrderId);
            }
        }      
        return ref;
    }

}
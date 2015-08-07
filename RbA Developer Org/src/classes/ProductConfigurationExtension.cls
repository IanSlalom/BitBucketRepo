/*******************************************************//**

@class      ProductConfigurationExtension (POC)

@brief      Extension for the Product_Configuration_Edit VF Page

    Manages all of the product config / pricing functionality

@author     Creston Kuenzi (Slalom.CDK)

@version    2015-07-22  Slalom.CDK
    Created.

@see        ProductConfigurationExtensionTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/
public class ProductConfigurationExtension {


    /******* public variables  *****************/
	public boolean newOrderItem {get; set;}     
	public boolean orderActivated {get; set;}     
	public String priceBookId;   
    public Decimal inputUI;    

    /******* Set up Standard Controller for OrderItem  *****************/
    private final OrderItem orderLineItem;

    public ProductConfigurationExtension(ApexPages.StandardController stdController) {
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
             			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.ORDER_ACTIVATED_EDIT));
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
    public  prodConfigManager.productConfigWrapper prodConfig  {
        get
        {   
            if (prodConfig != null) return prodConfig;
            prodConfig = new prodConfigManager.productConfigWrapper();
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
            lMasterProduct = [SELECT Name, Min_Width__c, Min_Height__c, Max_Width__c, Max_Height__c FROM Product2
                                                            WHERE Id =: masterProductId
                                                            limit 1].get(0);
            return lMasterProduct;
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
                for (Product2 cProd : [SELECT Id, UI_Minimum__c, UI_Maximum__c From Product2 WHERE RecordTypeId =: Utilities.RecordTypeFor('Product2', 'Child_Product')
                                                                                            AND Master_Product__c =: masterProductId
                                                                                            AND UI_Minimum__c <=: InputUI                                                                                           
                                                                                            AND UI_Maximum__c >=: InputUI]) {
                    childProduct = cProd;
                    count++;
                }

			// returns an error message if either 0 child products are found matching the criteria or multiple are found.
            if (count == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.CHILD_PRODUCT_NOT_FOUND));
                return null;
            }
            if (count > 1) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.MULTIPLE_CHILD_PRODUCTS));
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
            // need to limit to pricebook?
            if (lMasterProductItems == null) {
                lMasterProductItems = new List<SelectOption>();
                lMasterProductItems.add(new SelectOption('', '-- Select --'));
                for (Product2 masterProd : [SELECT Id, Name From Product2 WHERE RecordTypeId =: Utilities.RecordTypeFor('Product2', 'Master_Product')]) {
                    lMasterProductItems.add(new SelectOption(masterProd.Id, masterProd.Name));
                }
            }               
            return lMasterProductItems;
        }
    }

    /******* Set up Size PickList Items  *****************/
    private static transient List<SelectOption> lSizeItems;
    public List<SelectOption> sizeItems {
        get
        {   
            if (lSizeItems == null && prodConfig.sizes != null) {
                lSizeItems = ProdConfigUtility.retrievePickListItems(prodConfig.sizes);
            }               
            return lSizeItems;
        }
    }
    
    /******* Set up Dual Color Exterior Items  *****************/
    private static transient List<SelectOption> lDualColorExteriorItems;
    public List<SelectOption> dualColorExteriorItems {
        get
        {   
            // need to limit to pricebook
            if (lDualColorExteriorItems == null && prodConfig.dualColorPrice != null) {
                lDualColorExteriorItems = ProdConfigUtility.retrievePickListItems(prodConfig.dualColorExteriors);
            }               
            return lDualColorExteriorItems;
        }
    }

    /******* Set up Dual Color Interior Items  *****************/
    private static transient List<SelectOption> lDualColorInteriorItems;
    public List<SelectOption> dualColorInteriorItems {
        get
        {   
            // need to limit to pricebook
            if (lDualColorInteriorItems == null && prodConfig.dualColorPrice != null) {
                lDualColorInteriorItems = ProdConfigUtility.retrievePickListItems(prodConfig.dualColorInteriors);
            }               
            return lDualColorInteriorItems;
        }
    } 

    /*******************************************************
                    enterProduct method
    *******************************************************/
	// runs whenever the Enter button is clicked at the master product level
    public virtual pageReference enterProduct() {
    	
        inputUI = orderLineItem.Width__c + orderLineItem.Height__c;
    	String errorMessage = ProdConfigManager.checkMakeability(masterProduct, orderLineItem);
        if(!String.isBlank(errorMessage)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
            return null;        	
        }
        prodConfig = ProdConfigManager.findProductConfiguration(orderLineItem, priceBookId, childProduct.Id);
        
        if (prodConfig == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.INVALID_CHILD_PRODUCT));
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
    	orderLineItem.unitPrice = ProdConfigManager.calculatePrice(prodConfig);
    	if (newOrderItem) {
    		orderLineItem.PriceBookEntryId = prodConfig.priceBookId;
    		insert orderLineItem;
			ref = new PageReference('/' +orderLineItem.OrderId);
    	}
    	else {
    		if (orderLineItem.PriceBookEntryId != prodConfig.priceBookId) {
    			OrderItem newOrderLineItem = orderLineItem.clone(false,true);
    			newOrderLineItem.PriceBookEntryId = prodConfig.priceBookId;
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
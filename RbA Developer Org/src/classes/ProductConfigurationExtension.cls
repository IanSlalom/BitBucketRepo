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
                for (OrderItem orderItem : [SELECT Id, PricebookEntryId, PricebookEntry.Pricebook2Id, PricebookEntry.Product2Id, PricebookEntry.Product2.Master_Product__c From OrderItem WHERE Id =: orderLineItem.Id]) {
                    masterProductId = orderItem.PricebookEntry.Product2.Master_Product__c;
                    priceBookId = String.ValueOf(orderItem.PricebookEntry.Pricebook2Id);
                }       	
        }
    }   

    /******* public properties  *****************/
    public String inputWidth {get;set;}
    public String inputHeight {get;set;}
    public boolean productSelected {get;set;}    
    public Integer inputQuantity {get;set;}    
    
    /******* property for the product configuration wrapper  *****************/
    public  productConfigWrapper prodConfig  {
        get
        {   
            if (prodConfig != null) return prodConfig;
            prodConfig = new productConfigWrapper();
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
                lSizeItems = new List<SelectOption>();
                lSizeItems.add(new SelectOption('', '-- Select --'));
                for (String size : prodConfig.sizes.split(';')) {
                    lSizeItems.add(new SelectOption(size, size));
                }
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
            if (lDualColorExteriorItems == null && prodConfig.sizes != null) {
                lDualColorExteriorItems = new List<SelectOption>();
                lDualColorExteriorItems.add(new SelectOption('', '-- Select --'));
                for (String color : prodConfig.dualColorExteriors.split(';')) {
                    lDualColorExteriorItems.add(new SelectOption(color, color));
                }
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
            if (lDualColorInteriorItems == null && prodConfig.sizes != null) {
                lDualColorInteriorItems = new List<SelectOption>();
                lDualColorInteriorItems.add(new SelectOption('', '-- Select --'));
                for (String color : prodConfig.dualColorInteriors.split(';')) {
                    lDualColorInteriorItems.add(new SelectOption(color, color));
                }
            }               
            return lDualColorInteriorItems;
        }
    }
    /*******************************************************
                    ProductConfigWrapper class
    *******************************************************/
	// stores the product config prices and the order line item
    public class ProductConfigWrapper
    {
        public Id  		priceBookId                   	{ get; private set; }
        public Decimal  baseUnitPrice                   { get; private set; }
        public Decimal  corrosionResistantPrice         { get; private set; }
        public String 	dualColorExteriors              { get; private set; }
        public String 	dualColorInteriors        		{ get; private set; }
        public Decimal  dualColorPrice                  { get; private set; }
        public Decimal  glidingScreenPrice              { get; private set; }
        public Decimal  grillesBetweenGlassPrice        { get; private set; }
        public Decimal  specialtyGlazingPrice           { get; private set; }
        public String 	sizes                           { get; private set; }
        public OrderItem orderLI              			{ get; set; }

		// constructors
        public ProductConfigWrapper(){}

        public ProductConfigWrapper(PriceBookEntry pBookEntry, OrderItem orderLItem)
        {
				priceBookId								= pBookEntry.Id;
                baseUnitPrice                           = pBookEntry.Base_Unit__c;
                corrosionResistantPrice         		= pBookEntry.Corrosion_Resistant__c;
                dualColorExteriors                      = pBookEntry.Dual_Color_Exterior__c;
                dualColorInteriors                      = pBookEntry.Dual_Color_Interior__c;
                dualColorPrice                          = pBookEntry.Dual_Color__c;
                glidingScreenPrice                      = pBookEntry.Gliding_Screen__c;
                grillesBetweenGlassPrice        		= pBookEntry.Grilles__c;
                specialtyGlazingPrice           		= pBookEntry.Specialty_Glazing__c;
            	sizes                                   = pBookEntry.Size__c;
            	orderLI = orderLItem;
        }
    }

    

    /*******************************************************
                    enterProduct method
    *******************************************************/
	// runs whenever the Enter button is clicked at the master product level
    public virtual pageReference enterProduct() {
        if(!checkMakeability())
            return null;
        if(!findProductConfiguration())
            return null;
        productSelected = true;
        return null;
    }

    /*******************************************************
                    saveProduct method
    *******************************************************/
	// runs whenever the Save button is clicked at the child product level
    public pageReference saveProduct() {
		PageReference ref;
    	orderLineItem.unitPrice = calculatePrice();
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

    /*******************************************************
                    calculatePrice method
    *******************************************************/
	// calculates the total price for the product based on selected config options
    public decimal calculatePrice() {
    	decimal price = (prodConfig.baseUnitPrice == null) ? 0 : prodConfig.baseUnitPrice;
        price = (!prodConfig.OrderLI.Specialty_Glazing__c || prodConfig.specialtyGlazingPrice == null) ? price : price + prodConfig.specialtyGlazingPrice;    	
        price = (!prodConfig.OrderLI.Corrosion_Resistant__c || prodConfig.corrosionResistantPrice == null) ? price : price + prodConfig.corrosionResistantPrice;    	
        price = (prodConfig.OrderLI.Dual_Color_Exterior__c == null || prodConfig.OrderLI.Dual_Color_Interior__c == null) ? price : price + prodConfig.DualColorPrice;    	
        price = (!prodConfig.OrderLI.Gliding_Screen__c || prodConfig.glidingScreenPrice == null) ? price : price + prodConfig.glidingScreenPrice;    	
        price = (!prodConfig.OrderLI.Grilles_Between_Glass__c || prodConfig.grillesBetweenGlassPrice == null) ? price : price + prodConfig.grillesBetweenGlassPrice;    	

        return price;
    }

    /*******************************************************
                    checkMakeability method
    *******************************************************/
	// checks the entered values against the master product makeability rules
    private boolean checkMakeability() {

        // Check that values have been entered for width / height
        if (MasterProduct == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.PRODUCT_EMPTY));
            System.Debug('got here');
            return false;          
        }
        if (orderLineItem.Width__c == null || orderLineItem.Height__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.WIDTH_HEIGHT_EMPTY));
            System.Debug('got here');
            return false;                 
        } 
        
        // Check for minimum makeability 
        if (orderLineItem.Height__c < masterProduct.Min_Height__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.HEIGHT_BELOW_MIN));
            System.Debug('got here');
            return false;                  
        }
        if (orderLineItem.Width__c < masterProduct.Min_Width__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.WIDTH_BELOW_MIN));
            System.Debug('got here'); 
            return false;                  
        }

        // Check for maximum makeability 
        if (orderLineItem.Height__c > masterProduct.Max_Height__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.HEIGHT_ABOVE_MAX));
            return false;                  
        }
        if (orderLineItem.Width__c > masterProduct.Max_Width__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.WIDTH_ABOVE_MAX));
            return false;                  
        }
        
        inputUI = orderLineItem.Width__c + orderLineItem.Height__c;

        return true;
    }

    /*******************************************************
                    findProductConfiguration method
    *******************************************************/
	// retrieves the correct price book entry based on the pricebook and product id and 
	// creates the product config wrapper to store the config options
	// add check here to make sure multiple pricebook entries were not found that match the criteria
    private boolean findProductConfiguration() {
    	integer count = 0;
        for (PricebookEntry pBook : [SELECT PriceBook2Id, Product2Id, Base_Unit__c, Corrosion_Resistant__c, 
                                                    Dual_Color_Exterior__c, Dual_Color_Interior__c, Dual_Color__c, 
                                                    Gliding_Screen__c, Grilles__c, Specialty_Glazing__c, Size__c  
                                                    		From PricebookEntry WHERE PriceBook2Id =: priceBookId 
                                                           	//             AND Master_Product__c =: masterProductId
                                                           	//             AND UI_Minimum__c <=: InputUI
                                                           	AND      Product2Id =: childProduct.Id]) {
        	prodConfig = new productConfigWrapper(pBook, orderLineItem);
        	count++;
        }
        return true;
    }
}
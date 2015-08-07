public class ProdConfigManager {

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
                    checkMakeability method
    *******************************************************/
	// checks the entered values against the master product makeability rules
    public static String checkMakeability(Product2 masterProduct, OrderItem orderLineItem) {
		String errorMessage = '';
        // Check that values have been entered for width / height
        if (masterProduct == null) {
            errorMessage = ErrorMessages.PRODUCT_EMPTY;
            return errorMessage;          
        }
        if (orderLineItem.Width__c == null || orderLineItem.Height__c == null) {
            errorMessage = ErrorMessages.WIDTH_HEIGHT_EMPTY;
            return errorMessage;                 
        } 
        
        // Check for minimum width makeability 
        if (orderLineItem.Width__c < masterProduct.Min_Width__c) {
        	errorMessage = ErrorMessages.WIDTH_BELOW_MIN;
        }
        
        // Check for minimum height makeability 
        if (orderLineItem.Height__c < masterProduct.Min_Height__c) {
            errorMessage = (String.isBlank(errorMessage)) ? ErrorMessages.HEIGHT_BELOW_MIN : errorMessage + '\r\n' + ErrorMessages.HEIGHT_BELOW_MIN;
        }

        // Check for maximum width makeability 
        if (orderLineItem.Width__c > masterProduct.Max_Width__c) {
            errorMessage = (String.isBlank(errorMessage)) ? ErrorMessages.WIDTH_ABOVE_MAX : errorMessage + '\r\n' + ErrorMessages.WIDTH_ABOVE_MAX;
        }
        
        // Check for maximum height makeability 
        if (orderLineItem.Height__c > masterProduct.Max_Height__c) {
            errorMessage = (String.isBlank(errorMessage)) ? ErrorMessages.HEIGHT_ABOVE_MAX : errorMessage + '\r\n' + ErrorMessages.HEIGHT_ABOVE_MAX;
        }
        
        return errorMessage;
    }
    
    /*******************************************************
                    findProductConfiguration method
    *******************************************************/
	// retrieves the correct price book entry based on the pricebook and product id and 
	// creates the product config wrapper to store the config options
	// add check here to make sure multiple pricebook entries were not found that match the criteria
    public static productConfigWrapper findProductConfiguration(OrderItem orderLineItem, String priceBookId, String childProductId) {
    	integer count = 0;
    	productConfigWrapper prodConfig;
        if (orderLineItem == null || priceBookId == null || childProductId == null) return null;
    	
        for (PricebookEntry pBook : [SELECT PriceBook2Id, Product2Id, Base_Unit__c, Corrosion_Resistant__c, 
                                                    Dual_Color_Exterior__c, Dual_Color_Interior__c, Dual_Color__c, 
                                                    Gliding_Screen__c, Grilles__c, Specialty_Glazing__c, Size__c  
                                                    		From PricebookEntry WHERE PriceBook2Id =: priceBookId 
                                                           	//             AND Master_Product__c =: masterProductId
                                                           	//             AND UI_Minimum__c <=: InputUI
                                                           	AND      Product2Id =: childProductId]) {
        	prodConfig = new productConfigWrapper(pBook, orderLineItem);
        	count++;
        }
        
        if (count != 1) return null;

        return prodConfig;
    }   
    
    /*******************************************************
                    calculatePrice method
    *******************************************************/
	// calculates the total price for the product based on selected config options
    public static decimal calculatePrice(ProductConfigWrapper prodConfig) {
    	prodConfig = clearNonSelectableValues(prodConfig);
    	decimal price = (prodConfig.baseUnitPrice == null) ? 0 : prodConfig.baseUnitPrice;
        price = (!prodConfig.OrderLI.Specialty_Glazing__c || prodConfig.specialtyGlazingPrice == null) ? price : price + prodConfig.specialtyGlazingPrice;    	
        price = (!prodConfig.OrderLI.Corrosion_Resistant__c || prodConfig.corrosionResistantPrice == null) ? price : price + prodConfig.corrosionResistantPrice;    	
        price = (prodConfig.OrderLI.Dual_Color_Exterior__c == null || prodConfig.OrderLI.Dual_Color_Interior__c == null) ? price : price + prodConfig.DualColorPrice;    	
        price = (!prodConfig.OrderLI.Gliding_Screen__c || prodConfig.glidingScreenPrice == null) ? price : price + prodConfig.glidingScreenPrice;    	
        price = (!prodConfig.OrderLI.Grilles_Between_Glass__c || prodConfig.grillesBetweenGlassPrice == null) ? price : price + prodConfig.grillesBetweenGlassPrice;    	

        return price;
    }

    /*******************************************************
                    clearNonSelectableValues method
    *******************************************************/
	// clears any fields that are not selectable / do not have a price. 
	// This is needed for the scenario where the child product changes from one size to another.
    public static ProductConfigWrapper clearNonSelectableValues(ProductConfigWrapper prodConfig) {
        prodConfig.OrderLI.Specialty_Glazing__c = (prodConfig.specialtyGlazingPrice == null) ? false : prodConfig.OrderLI.Specialty_Glazing__c;    	
        prodConfig.OrderLI.Corrosion_Resistant__c = (prodConfig.corrosionResistantPrice == null) ? false : prodConfig.OrderLI.Corrosion_Resistant__c;    	
        prodConfig.OrderLI.Dual_Color_Exterior__c = (prodConfig.DualColorPrice == null) ? null : prodConfig.OrderLI.Dual_Color_Exterior__c;    	
        prodConfig.OrderLI.Dual_Color_Interior__c = (prodConfig.DualColorPrice == null) ? null : prodConfig.OrderLI.Dual_Color_Interior__c;    	
        prodConfig.OrderLI.Gliding_Screen__c = (prodConfig.glidingScreenPrice == null) ? false : prodConfig.OrderLI.Gliding_Screen__c;    	
        prodConfig.OrderLI.Grilles_Between_Glass__c = (prodConfig.grillesBetweenGlassPrice == null) ? false : prodConfig.OrderLI.Grilles_Between_Glass__c;    	
		return prodConfig;
    }     

}
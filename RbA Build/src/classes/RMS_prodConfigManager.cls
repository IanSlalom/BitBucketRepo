public with sharing class RMS_prodConfigManager {

    /*******************************************************
                    ProductConfigWrapper class
    *******************************************************/

    public static Map<String, Schema.SObjectField> pricebookFieldsMap;
//        get
//        {   
// 			if (pricebookFieldsMap != null) return 
 //           return 'me';
//        }    
//        private set;          
//    }
	
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
        public PricebookEntry pBookEntry              	{ get; set; }

		// constructors
        public ProductConfigWrapper(){}

        public ProductConfigWrapper(PriceBookEntry pBookEntryInput, OrderItem orderLItem)
        {
				priceBookId								= pBookEntryInput.Id;
                baseUnitPrice                           = pBookEntryInput.Base_Unit__c;
                corrosionResistantPrice         		= pBookEntryInput.Corrosion_Resistant__c;
                dualColorExteriors                      = pBookEntryInput.Dual_Color_Exterior__c;
                dualColorInteriors                      = pBookEntryInput.Dual_Color_Interior__c;
                dualColorPrice                          = pBookEntryInput.Dual_Color__c;
                glidingScreenPrice                      = pBookEntryInput.Gliding_Screen__c;
                grillesBetweenGlassPrice        		= pBookEntryInput.Grilles__c;
                specialtyGlazingPrice           		= pBookEntryInput.Specialty_Glazing__c;
            	sizes                                   = pBookEntryInput.Size__c;
            	orderLI = orderLItem;
            	pBookEntry = pBookEntryInput;
        }
    }

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
	public static productConfigWrapper findProductConfiguration(OrderItem orderLineItem, String priceBookId, String childProductId) {

		// Check if we have the necessary Ids to retrieve the pricebookentry and return null if not
		if (orderLineItem == null || priceBookId == null || childProductId == null) return null;

		// Do a global describe to pull back a map with all objects in the system with their tokens and then use
		// that map to retrieve all of the fields on the PricebookEntry object
//		String SobjectApiName = 'PricebookEntry';
//		Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
//		Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();

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
 //       	extraSOQL = extraSOQL1 + '\'' +extraSOQL2 +'\'';
 
		// Retrieve all fields from the PricebookEntry object in a query
        pBookEntry = Database.query(query);
		System.Debug('*****************query=' + query);
		System.Debug('*****************pBookEntry=' + pBookEntry);
		System.Debug('*****************orderLineItem=' + orderLineItem);
		// If the pricebookentry was not found return null
		if (pBookEntry == null) return null;

		// Create a wrapper with the pricebook entry and order line item and return it
		productConfigWrapper prodConfig;
		prodConfig = new productConfigWrapper(pBookEntry, orderLineItem);

		Object o = pBookEntry.get('Id');

		System.Debug('*************o=' +o);
		return prodConfig;

//    	integer count = 0;
//    	productConfigWrapper prodConfig;
//        if (orderLineItem == null || priceBookId == null || childProductId == null) return null;

//        for (PricebookEntry pBook : [SELECT PriceBook2Id, Product2Id, Base_Unit__c, Corrosion_Resistant__c, 
//                                                    Dual_Color_Exterior__c, Dual_Color_Interior__c, Dual_Color__c, 
//                                                    Gliding_Screen__c, Grilles__c, Specialty_Glazing__c, Size__c  
//                                                   		From PricebookEntry WHERE PriceBook2Id =: priceBookId 
//                                                           	//             AND Master_Product__c =: masterProductId
//                                                           	//             AND UI_Minimum__c <=: InputUI
//                                                           	AND      Product2Id =: childProductId]) {
//        	prodConfig = new productConfigWrapper(pBook, orderLineItem);
//        	count++;
//        }
        
//        if (count != 1) return null;

//        return prodConfig;
    }   

 /*   public static void fetch(){

		// Do a global describe to pull back a map with all objects in the system with their tokens and then use
		// that map to retrieve all of the fields on the PricebookEntry object
        String SobjectApiName = 'PricebookEntry';
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap = schemaMap.get(SobjectApiName).getDescribe().fields.getMap();
 
		// Loop through the PricebookEntry fields and comma separate them into a string
        String commaSeparatedFields = '';
        for(String fieldName : fieldMap.keyset()){
            if(commaSeparatedFields == null || commaSeparatedFields == ''){
                commaSeparatedFields = fieldName;
            }else{
                commaSeparatedFields = commaSeparatedFields + ', ' + fieldName;
            }
        }
 
		// Use the comma separated field string to build a dynamic query
        query = 'select ' + commaSepratedFields + ' from ' + SobjectApiName + ' Limit 5';
 
		// Retrieve all fields from the PricebookEntry object in a query
        accList = Database.query(query);
 
        return null;
    }*/

    
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


    /*******************************************************
                    retrievePickListItems method
    *******************************************************/
	//Utility method to receive a multi picklist and return select options for use in a single picklist.
    public static List<SelectOption> retrievePickListItems2(List<Schema.FieldSetMember> fieldSetMembers, ProductConfigWrapper prodConfig) {
        List<SelectOption> pickListItems = new List<SelectOption>();
        pickListItems.add(new SelectOption('', '-- Select --'));
    	// need to limit to pricebook
        if (fieldSetMembers == null) return pickListItems;
        
        for (Schema.FieldSetMember fsm : fieldSetMembers) {
			Object o = prodConfig.pBookEntry.get(fsm.getFieldPath());

			System.Debug('*************o=' +o);
			if (o != null) 
				pickListItems.add(new SelectOption(fsm.getLabel(), fsm.getLabel()));
        }               
        return pickListItems;
    } 

    /*******************************************************
                    createPicklistFromFieldSet method
    *******************************************************/
	// clears any fields that are not selectable / do not have a price. 
	// This is needed for the scenario where the child product changes from one size to another.
/*    public static List<SelectOption> createPicklistFromFieldSet(ProductConfigWrapper prodConfig) {
        prodConfig.OrderLI.Specialty_Glazing__c = (prodConfig.specialtyGlazingPrice == null) ? false : prodConfig.OrderLI.Specialty_Glazing__c;    	
        prodConfig.OrderLI.Corrosion_Resistant__c = (prodConfig.corrosionResistantPrice == null) ? false : prodConfig.OrderLI.Corrosion_Resistant__c;    	
        prodConfig.OrderLI.Dual_Color_Exterior__c = (prodConfig.DualColorPrice == null) ? null : prodConfig.OrderLI.Dual_Color_Exterior__c;    	
        prodConfig.OrderLI.Dual_Color_Interior__c = (prodConfig.DualColorPrice == null) ? null : prodConfig.OrderLI.Dual_Color_Interior__c;    	
        prodConfig.OrderLI.Gliding_Screen__c = (prodConfig.glidingScreenPrice == null) ? false : prodConfig.OrderLI.Gliding_Screen__c;    	
        prodConfig.OrderLI.Grilles_Between_Glass__c = (prodConfig.grillesBetweenGlassPrice == null) ? false : prodConfig.OrderLI.Grilles_Between_Glass__c;    	
		return prodConfig;
    }

    public dualColorInteriorItems {
        get
        {   
            // need to limit to pricebook
            if (lDualColorInteriorItems == null && prodConfig.dualColorPrice != null) {
                lDualColorInteriorItems = ProdConfigUtility.retrievePickListItems(prodConfig.dualColorInteriors);
            }               
            return lDualColorInteriorItems;
        }
    } 

    }     */

}
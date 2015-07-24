public class ProductConfigurationExtension {

    /******* Set up Standard Controller  *****************/
    private final OrderItem orderLineItem;
	public boolean newOrderItem {get; set;}     
	public String priceBookId;   
    public ProductConfigurationExtension(ApexPages.StandardController stdController) {
        this.orderLineItem = (OrderItem)stdController.getRecord();
        newOrderItem = stdController.getId() == null;
    
        
        System.Debug('****************this.orderLineItem=' +this.orderLineItem);
        if (newOrderItem) {
        	newOrderItem = true;
//            this.orderLineItem = new OrderItem(); 
            this.orderLineItem.OrderId = ApexPages.currentPage().getParameters().get('oid');
 //           this.orderLineItem.PriceBook2Id = ApexPages.currentPage().getParameters().get('pid');         
            priceBookId = ApexPages.currentPage().getParameters().get('pid');         
        } else {
                for (OrderItem orderItem : [SELECT Id, PricebookEntryId, PricebookEntry.Pricebook2Id, PricebookEntry.Product2Id, PricebookEntry.Product2.Master_Product__c From OrderItem WHERE Id =: orderLineItem.Id]) {
                    masterProductId = orderItem.PricebookEntry.Product2.Master_Product__c;
                    priceBookId = String.ValueOf(orderItem.PricebookEntry.Pricebook2Id);
                }

        	
        }
//        System.Debu
    }   

    public String inputWidth {get;set;}
    public String inputHeight {get;set;}
    public boolean productSelected {get;set;}    
    public Integer inputQuantity {get;set;}    
    public Decimal inputUI;    
    
    public  productConfigWrapper prodConfig  {
        get
        {   
            if (prodConfig != null) return prodConfig;
            prodConfig = new productConfigWrapper();
            return prodConfig;
        }    
        private set;          
    }
    /******* Set up ProductMaster PickList  *****************/

//    private static transient String lMasterProductId;
	public String masterProductId {get; set;}
/*    public String masterProductId {
        get
        {   
 //           if (masterProductId != null) return lmasterProductId;
        	String masterProductId;
            System.Debug('*************newOrderItem=' +newOrderItem);
        	if (!newOrderItem) {
                for (OrderItem orderItem : [SELECT Id, PricebookEntryId, PricebookEntry.Product2Id, PricebookEntry.Product2.Master_Product__c From OrderItem WHERE Id =: orderLineItem.Id]) {
                    masterProductId = orderItem.PricebookEntry.Product2.Master_Product__c;
                }
        	} else {
//        		lmasterProductId = masterProductId;
        	}
        	newOrderItem = true;
        	return masterProductId;	
 //       } set{ lmasterProductId = masterProductId;}
        } set;
    }*/
    private static transient Product2 lMasterProduct;
    public Product2 masterProduct {
        get
        {   
        	
            if (lmasterProduct != null) return lmasterProduct;
            if (masterProductId == '' || masterProductId == null) {
            System.Debug('*************here');
            return null;
            }
            lMasterProduct = [SELECT Name, Min_Width__c, Min_Height__c, Max_Width__c, Max_Height__c FROM Product2
                                                            WHERE Id =: masterProductId
                                                            limit 1].get(0);
            System.Debug('************lMasterProduct=' +lMasterProduct);
            return lMasterProduct;
        }
    }

    public Product2 childProduct {
        get
        {   
            if (masterProductId == '' || masterProductId == null) {
                return null;
            }
            Product2 childProduct; 
                integer count = 0;
                System.Debug('*************masterProductId=' +masterProductId);
                for (Product2 cProd : [SELECT Id, UI_Minimum__c, UI_Maximum__c From Product2 WHERE RecordTypeId =: Utilities.RecordTypeFor('Product2', 'Child_Product')
                                                                                            AND Master_Product__c =: masterProductId
                                                                                            AND UI_Minimum__c <=: InputUI
                                                                                            AND UI_Maximum__c >=: InputUI]) {
                    childProduct = cProd;
                    System.Debug('************cprod=' +cProd);
                    count++;
                }

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

    
    private static transient List<SelectOption> lMasterProductItems;
    public List<SelectOption> masterProductItems {
        get
        {   
            // need to limit to pricebook
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

    private static transient List<SelectOption> lSizeItems;
    public List<SelectOption> sizeItems {
        get
        {   
            // need to limit to pricebook
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
                    ProductConfig class
    *******************************************************/

    public class ProductConfigWrapper
    {
        public Id  priceBookId                   { get; private set; }
        public Decimal  baseUnitPrice                   { get; private set; }
        public Decimal  corrosionResistantPrice         { get; private set; }
//        public boolean        corrosionResistantSelected  { get; private set; }
        public String dualColorExteriors                        { get; private set; }
//        public String         dualColorExteriorSelected       { get; private set; }
        public String dualColorInteriors        { get; private set; }
//        public String         dualColorInteriorSelected       { get; private set; }
        public Decimal  dualColorPrice                          { get; private set; }
//        public boolean        dualColorSelected               { get; private set; }
        public Decimal  glidingScreenPrice                      { get; private set; }
//        public boolean        glidingScreenSelected       { get; private set; }
        public Decimal  grillesBetweenGlassPrice        { get; private set; }
//        public boolean        grillesBetweenGlassSelected { get; private set; }
        public Decimal  specialtyGlazingPrice           { get; private set; }
//        public boolean        specialtyGlazingSelected        { get; private set; }
        public String sizes                                     { get; private set; }
//        public String         sizeSelected                            { get; private set; }
        public OrderItem orderLI              { get; set; }

        public ProductConfigWrapper()
        {
        }

        public ProductConfigWrapper(PriceBookEntry pBookEntry, OrderItem orderLItem)
        {
				priceBookId										= pBookEntry.Id;
                baseUnitPrice                           = pBookEntry.Base_Unit__c;
                corrosionResistantPrice         = pBookEntry.Corrosion_Resistant__c;
                dualColorExteriors                      = pBookEntry.Dual_Color_Exterior__c;
                dualColorInteriors                      = pBookEntry.Dual_Color_Interior__c;
                dualColorPrice                          = pBookEntry.Dual_Color__c;
                glidingScreenPrice                      = pBookEntry.Gliding_Screen__c;
                grillesBetweenGlassPrice        = pBookEntry.Grilles__c;
                specialtyGlazingPrice           = pBookEntry.Specialty_Glazing__c;
            	sizes                                       = pBookEntry.Size__c;
            	orderLI = orderLItem;
        }
    }

    
    public virtual pageReference enterProduct() {
        if(!checkMakeability())
            return null;
        if(!findProductConfiguration())
            return null;
                productSelected = true;
        return null;
    }

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
 //   			newOrderLineItem = orderLineItem;
    			insert newOrderLineItem;
    			delete orderLineItem;
				ref = new PageReference('/' +newOrderLineItem.OrderId);
    			
    		}
    		else {
    			update orderLineItem;
				ref = new PageReference('/' +orderLineItem.OrderId);
    		}
    	}
//    	orderLineItem.OrderId = '8011a0000000I5H';
//    	upsert orderLineItem;
//        ref.setRedirect(true);
//        return ref;

//		PageReference ref = new PageReference('/' +orderLineItem.OrderId);
//        ref.setRedirect(true);
//        return ref;
    	
        return ref;
    }

    public decimal calculatePrice() {
    	decimal price = (prodConfig.baseUnitPrice == null) ? 0 : prodConfig.baseUnitPrice;
        price = (!prodConfig.OrderLI.Specialty_Glazing__c) ? price : price + prodConfig.specialtyGlazingPrice;    	
        price = (!prodConfig.OrderLI.Corrosion_Resistant__c) ? price : price + prodConfig.corrosionResistantPrice;    	
        price = (prodConfig.OrderLI.Dual_Color_Exterior__c == null || prodConfig.OrderLI.Dual_Color_Interior__c == null) ? price : price + prodConfig.DualColorPrice;    	
        price = (!prodConfig.OrderLI.Gliding_Screen__c ) ? price : price + prodConfig.glidingScreenPrice;    	
        price = (!prodConfig.OrderLI.Grilles_Between_Glass__c ) ? price : price + prodConfig.grillesBetweenGlassPrice;    	

        return price;
    }
    private boolean checkMakeability() {
        // clear master product
//        lMasterProduct = null;
//        if (MasterProductId == '' || masterProductId == null) {
		System.Debug('********************MasterProduct=' +MasterProduct);
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
        
/*        Pattern p = Pattern.compile('\\d+(\\.\\d+)?');
        Matcher mHeight =p.matcher(orderLineItem.Height__c);
        Matcher mWidth =p.matcher(orderLineItem.Width__c);


        if (!mHeight.find()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.INVALID_HEIGHT_FORMAT));
            return false;             
        } 
        if (!mWidth.find()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.INVALID_WIDTH_FORMAT));
            return false;             
        } */
        
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

		System.Debug('*****************orderLineItem.Width__c=' +orderLineItem.Width__c);
		System.Debug('*****************orderLineItem.Height__c=' +orderLineItem.Height__c);
		System.Debug('*****************inputUI=' +inputUI);
        return true;
    }

    private boolean findProductConfiguration() {
        System.Debug('************childProduct=' +childProduct);
        // query pricebook entries where product = childproduct and pricebook = order price book.   How to get order price book? Query pricebooks where order is a child of pricebook
//            Product2 childProduct; 
                integer count = 0;
                System.Debug('*************masterProductId=' +masterProductId);
                System.Debug('*************priceBookId=' +priceBookId);
                System.Debug('*************childProduct=' +childProduct.Id);
                for (PricebookEntry pBook : [SELECT PriceBook2Id, Product2Id, Base_Unit__c, Corrosion_Resistant__c, 
                                                    Dual_Color_Exterior__c, Dual_Color_Interior__c, Dual_Color__c, 
                                                    Gliding_Screen__c, Grilles__c, Specialty_Glazing__c, Size__c  From PricebookEntry WHERE PriceBook2Id =: priceBookId 
                                                                               //             AND Master_Product__c =: masterProductId
                                                                               //             AND UI_Minimum__c <=: InputUI
                                                                                   AND      Product2Id =: childProduct.Id]) {
             //       childProduct = cProd;
                    System.Debug('************pBook =' +pBook );
//                    orderLineItem.
                    prodConfig = new productConfigWrapper(pBook, orderLineItem);
                    count++;
                }


        return true;
    }
}
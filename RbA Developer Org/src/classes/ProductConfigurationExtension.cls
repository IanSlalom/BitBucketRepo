public class ProductConfigurationExtension {

    /******* Set up Standard Controller  *****************/
    private final OrderItem orderLineItem;
    
    public ProductConfigurationExtension(ApexPages.StandardController stdController) {
        this.orderLineItem = (OrderItem)stdController.getRecord();
        if (this.orderLineItem == null)
            this.orderLineItem = new OrderItem();
    }   


    public String inputWidth {get;set;}
    public String inputHeight {get;set;}
    public Decimal inputUI;    
    /******* Set up ProductMaster PickList  *****************/

//    public Id masterProductId {get;set;} 
    public String masterProductId {get;set;} 

    private static transient Product2 lMasterProduct;
    public Product2 masterProduct {
        get
        {   
            if (lmasterProduct != null) return lmasterProduct;
            if (masterProductId == '' || masterProductId == null) {
            System.Debug('*************here');
            return null;
            }
            lMasterProduct = [SELECT Min_Width__c, Min_Height__c, Max_Width__c, Max_Height__c FROM Product2
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
                for (Product2 cProd : [SELECT UI_Minimum__c, UI_Maximum__c From Product2 WHERE RecordTypeId =: Utilities.RecordTypeFor('Product2', 'Child_Product')
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
/*      List<SelectOption> options = new List<SelectOption>();
        // need to limit to pricebook
        for (Product2 masterProd : [SELECT Id, Name From Product2 WHERE RecordTypeId =: Utilities.RecordTypeFor('Product2', 'Master_Product')]) {
            options.add(new SelectOption(masterProd.Name, masterProd.Id));
        }               
        return options;*/
    }

    /*******************************************************
                    ProductConfig class
    *******************************************************/

    public class ProductConfigWrapper
    {
        public Decimal 	baseUnitPrice        		{ get; private set; }
        public Decimal	corrosionResistantPrice		{ get; private set; }
        public boolean	corrosionResistantSelected  { get; private set; }
        public String dualColorExteriors			{ get; private set; }
        public String 	dualColorExteriorSelected	{ get; private set; }
        public String dualColorInteriors       	{ get; private set; }
        public String 	dualColorInteriorSelected	{ get; private set; }
        public Decimal 	dualColorPrice				{ get; private set; }
        public boolean	dualColorSelected       	{ get; private set; }
        public Decimal 	glidingScreenPrice			{ get; private set; }
        public boolean	glidingScreenSelected       { get; private set; }
        public Decimal 	grillesBetweenGlassPrice	{ get; private set; }
        public boolean	grillesBetweenGlassSelected { get; private set; }
        public Decimal 	specialtyGlazingPrice		{ get; private set; }
        public boolean	specialtyGlazingSelected	{ get; private set; }
        public String sizes				       	{ get; private set; }
        public String 	sizeSelected				{ get; private set; }

        public ProductConfigWrapper()
        {
        }

        public ProductConfigWrapper(PriceBookEntry pBookEntry)
        {

        	baseUnitPrice 				= pBookEntry.Base_Unit__c;
        	corrosionResistantPrice		= pBookEntry.Corrosion_Resistant__c;
        	dualColorExteriors 			= pBookEntry.Dual_Color_Exterior__c;
        	dualColorInteriors 			= pBookEntry.Dual_Color_Interior__c;
        	dualColorPrice 				= pBookEntry.Dual_Color__c;
        	glidingScreenPrice 			= pBookEntry.Gliding_Screen__c;
        	grillesBetweenGlassPrice 	= pBookEntry.Grilles__c;
        	specialtyGlazingPrice 		= pBookEntry.Specialty_Glazing__c;
            sizes        				= pBookEntry.Size__c;
        }
    }


    
    public virtual pageReference enterProduct() {
        if(!checkMakeability())
            return null;
        if(!findProductConfiguration())
            return null;

        return null;
    }

    public void saveProduct() {
        return;
    }

    private boolean checkMakeability() {
        // clear master product
        lMasterProduct = null;
//        if (MasterProductId == '' || masterProductId == null) {
        if (MasterProduct == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.PRODUCT_EMPTY));
            System.Debug('got here');
            return false;          
        }
        if (String.isBlank(inputWidth) || String.isBlank(inputHeight)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.WIDTH_HEIGHT_EMPTY));
            System.Debug('got here');
            return false;          
        
        } 
        
        Pattern p = Pattern.compile('\\d+(\\.\\d+)?');
        Matcher mHeight =p.matcher(inputHeight);
        Matcher mWidth =p.matcher(inputWidth);


        if (!mHeight.find()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.INVALID_HEIGHT_FORMAT));
            return false;             
        } 
        if (!mWidth.find()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.INVALID_WIDTH_FORMAT));
            return false;             
        } 
        
        // Check for minimum makeability 
        if (Decimal.valueOf(inputHeight) < masterProduct.Min_Height__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.HEIGHT_BELOW_MIN));
            System.Debug('got here');
            return false;                  
        }
        if (Decimal.valueOf(inputWidth) < masterProduct.Min_Width__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.WIDTH_BELOW_MIN));
            System.Debug('got here'); 
            return false;                  
        }

        // Check for maximum makeability 
        if (Decimal.valueOf(inputHeight) > masterProduct.Max_Height__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.HEIGHT_ABOVE_MAX));
            return false;                  
        }
        if (Decimal.valueOf(inputWidth) > masterProduct.Max_Width__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.WIDTH_ABOVE_MAX));
            return false;                  
        }
        
        inputUI = Decimal.valueOf(inputWidth) + Decimal.valueOf(inputHeight);

        return true;
    }

    private boolean findProductConfiguration() {
        System.Debug('************childProduct=' +childProduct);
        // query pricebook entries where product = childproduct and pricebook = order price book.   How to get order price book? Query pricebooks where order is a child of pricebook
            Product2 childProduct; 
                integer count = 0;
                System.Debug('*************masterProductId=' +masterProductId);
                for (PricebookEntry pBook : [SELECT PriceBook2Id, Product2Id From PricebookEntry WHERE PriceBook2Id = '01s1a000002Ino2AAC' 
                                                                               //             AND Master_Product__c =: masterProductId
                                                                               //             AND UI_Minimum__c <=: InputUI
                                                                                   AND      Product2Id = '01t1a000000BfyI']) {
             //       childProduct = cProd;
                    System.Debug('************pBook =' +pBook );
                    count++;
                }


        return true;
    }
}
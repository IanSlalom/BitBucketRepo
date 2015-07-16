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
    
    /******* Set up ProductMaster PickList  *****************/

//    public Id masterProductId {get;set;} 
    public String masterProductId {get;set;} 

    public Product2 masterProduct {
        get
        {   
            if (masterProductId == '' || masterProductId == null) {
            System.Debug('*************here');
            return null;
            }
            Product2 masterProduct = [SELECT Min_Width__c, Min_Height__c, Max_Width__c, Max_Height__c FROM Product2
                                                            WHERE Id =: masterProductId
                                                            limit 1].get(0);
            System.Debug('************masterProduct=' +masterProduct);
            return masterProduct;
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
    
    public virtual pageReference enterProduct() {
//        if (MasterProductId == '' || masterProductId == null) {
        if (MasterProduct == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.PRODUCT_EMPTY));
            System.Debug('got here');
            return null;          
        }
        if (String.isBlank(inputWidth) || String.isBlank(inputHeight)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.WIDTH_HEIGHT_EMPTY));
            System.Debug('got here');
            return null;          
        
        } 
        
        Pattern p = Pattern.compile('\\d+(\\.\\d+)?');
    Matcher m =p.matcher(inputHeight);


        if (!m.find()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.INVALID_HEIGHT_FORMAT));
            System.Debug('got here');
            return null;             
        } 
        
        if (Decimal.valueOf(inputHeight) < masterProduct.Min_Height__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ErrorMessages.HEIGHT_BELOW_MIN));
            System.Debug('got here');
            return null;             
        
        
        }

        return null;
    }

    public void saveProduct() {
        return;
    }

}
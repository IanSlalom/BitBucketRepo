/*******************************************************//**

@class      OrderExtension

@brief      Extension for the Product_Configuration VF Page

    Simply redirects from the Product_Configuration page to the Product_Configuration_Edit page. 
    This is necessary to override the "Add Product" button on Order Products because there is 
    an issue where that button can only be overridden by an Order standard controller instead
    of Order Products which it should be

@author     Creston Kuenzi (Slalom.CDK)

@version    2015-07-29  Slalom.CDK
    Created.

@see        OrderExtensionTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited.

***********************************************************/

public with sharing class OrderExtension {

    /******* Set up Standard Controller for Order  *****************/
    private final Order theOrder;
    
    public OrderExtension(ApexPages.StandardController stdController) {
        this.theOrder = (Order)stdController.getRecord();
        if (this.theOrder == null)
            this.theOrder = new Order(); 
    }   

    /******* redirect method  *****************/
	public PageReference redirect() {
		if (theOrder.Id == null) return null;
    	PageReference p = new PageReference('/apex/Product_Configuration_Edit?oid=' +theOrder.Id +'&pid=' +theOrder.Pricebook2Id);
    	return p;
	}
	
}
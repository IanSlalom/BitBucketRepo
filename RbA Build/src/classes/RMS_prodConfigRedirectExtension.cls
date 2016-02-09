/*******************************************************//**

@class	  RMS_prodConfigRedirectExtension

@brief	  Extension for the prodConfigEdit VF Page

	Simply redirects from the prodConfigEdit page to the Product_Configuration_Edit page. 
	This is necessary to override the "Add Product" button on Order Products because there is 
	an issue where that button can only be overridden by an Order standard controller instead
	of Order Products which it should be

@author	 Creston Kuenzi (Slalom.CDK)

@version	2015-07-29  Slalom.CDK
	Created POC
@version	2015-11-09  Slalom.CDK
	Updated for first release to build

@see		RMS_prodConfigRedirectExtensionTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/

public with sharing class RMS_prodConfigRedirectExtension {

	/******* Set up Standard Controller for Order  *****************/
	private final Order theOrder;
	public boolean orderActivated;
	
	public RMS_prodConfigRedirectExtension(ApexPages.StandardController stdController) {
		this.theOrder = (Order)stdController.getRecord();
		if (this.theOrder == null)  this.theOrder = new Order(); 
	}

	/******* redirect method  *****************/
	public PageReference redirect() {
		if (theOrder.Id == null) {
			 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, RMS_errorMessages.ORDER_NOT_FOUND));
			 return null;
		}
		PageReference p = new PageReference('/apex/rms_ProdConfigEdit?oid=' +theOrder.Id +'&pid=' +theOrder.Pricebook2Id);
		return p;
	}
	
}
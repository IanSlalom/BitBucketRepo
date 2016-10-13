/*******************************************************//**

@class	  RMS_editBackOfficeCheckRedirectExtension

@brief	  Extension for redirecting the user when clicking the Edit Back Office Check links

	Redirects the user to the Back Office Checklist visualforce page

@author	 Creston Kuenzi (Slalom.CDK)

@version	2016-10-13  Slalom.CDK
	Created

@see		RMS_editBackOfficeCheckRedirectExtension

@copyright  (c)2016 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/

public with sharing class RMS_editBackOfficeCheckRedirectExtension {

	/******* Set up Standard Controller for Back_Office_Check__c  *****************/
	private final Back_Office_Check__c theCheck;
	
	public RMS_editBackOfficeCheckRedirectExtension(ApexPages.StandardController stdController) {
		this.theCheck = (Back_Office_Check__c)stdController.getRecord();
		if (this.theCheck == null)
			this.theCheck = new Back_Office_Check__c(); 
	}

	/******* redirect method  *****************/
	public PageReference redirect() {

		String newPageUrl = '/apex/RMS_completeOrderChecks?Id=' +theCheck.Order__c;
		PageReference newPage = new PageReference(newPageUrl);
		newPage.setRedirect(true);
		return newPage;
	}
	
}
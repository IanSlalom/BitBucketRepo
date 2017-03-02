/**
 *@class	RMS_mobileAppAPIControllerTest
 *@brief	test class for RMS_mobileAppAPIController
 *@author  Mark Wochnick (Slalom.MAW)
 *@version	2016-02-09  Slalom.ADS	Created.
 *@copyright  (c)2016 Slalom.  All Rights Reserved.	Unauthorized use is prohibited.
 */
@isTest
private class RMS_mobileAppAPIControllerTest {

	static testmethod void testdoGet(){
		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setupConfigs();
		RestRequest req = new RestRequest(); 
		RestResponse res = new RestResponse();
		// this is an example of the full URL - it needs to be broken into its parts
	    //req.requestURI = 'https://foo.salesforce.com/services/apexrest/1net/getAppointments?TS=2015-12-03 23:23:53';
		req.addParameter('TS', '2015-12-03 23:23:53');
	    req.requestURI = '/1net/getAppointments';
	    req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;
		RMS_mobileAppAPIController.doGet();
		Blob b = (blob) (RestContext.response.responseBody);
		System.assert(b.toString().startsWith('{"tmAppts":'));
	}

	static testmethod void testdoGetUnsupportedOperation(){
		RestRequest req = new RestRequest(); 
		RestResponse res = new RestResponse();
	    req.requestURI = '/1net/unsupportedOperationExample';
	    req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;
		RMS_mobileAppAPIController.doGet();
		Blob b = (blob) (RestContext.response.responseBody);
		System.assert(b.toString().startsWith('Unsupported operation:'));
	}

	static testmethod void testdoGetNoOperation(){
		RestRequest req = new RestRequest(); 
		RestResponse res = new RestResponse();
	    req.requestURI = '/1net';
	    req.httpMethod = 'GET';
		RestContext.request = req;
		RestContext.response = res;
		RMS_mobileAppAPIController.doGet();
		Blob b = (blob) (RestContext.response.responseBody);
		System.assert(b.toString().startsWith(RMS_mobileAppAPIController.NO_REQUEST_FOUND));
	}

	static testmethod void testdoPost(){
		RestRequest req = new RestRequest(); 
		RestResponse res = new RestResponse();
		// this is an example of the full URL - it needs to be broken into its parts
	    //req.requestURI = 'https://cs50.salesforce.com/services/apexrest/1net/resultSalesAppointments';
		//req.addParameter('TS', '2015-12-03 23:23:53');
	    req.requestURI = '/1net/resultSalesAppointments';
	    req.httpMethod = 'POST';
		//TODO: Create a JSON string that will work
		req.requestBody = Blob.valueOf('{"salesAppts": [{"opptyContainer": {"quoteContainerList": [{"quoteLineItems": [{}],"quoteDiscountList": [{}],"aQuote": {}}],"oppty": {}},"event": {},"account": {}}]}');
		RestContext.request = req;
		RestContext.response = res;
		RMS_mobileAppAPIController.doPost();
		Blob b = (blob) (RestContext.response.responseBody);
		System.debug('###### ' + b.toString());
		System.assert(b.toString().startsWith('An Error has occurred.'));
		
		//Cover various helper class method invocations
		RestContext.request.requestURI = '/1net/'+RMS_mobileAppAPIController.SAVE_TECH_MEASURE;
		RMS_mobileAppAPIController.doPost();

		RestContext.request.requestURI = '/1net/'+RMS_mobileAppAPIController.RESULT_APPOINTMENTS;
		RMS_mobileAppAPIController.doPost();

		RestContext.request.requestURI = '/1net/'+RMS_mobileAppAPIController.CREATE_CONTACT;
		RMS_mobileAppAPIController.doPost();

		RestContext.request.requestURI = '/1net/'+RMS_mobileAppAPIController.CUSTOMER_JOB_SEARCH;
		RMS_mobileAppAPIController.doPost();

		RestContext.request.requestURI = '/1net/'+RMS_mobileAppAPIController.GET_SELECTED_SEARCH_RESULTS;
		RMS_mobileAppAPIController.doPost();

		RestContext.request.requestURI = '/1net/'+RMS_mobileAppAPIController.CANCEL_ORDER;
		RMS_mobileAppAPIController.doPost();
	}

	static testmethod void testdoPostException(){
		RestRequest req = new RestRequest(); 
		RestResponse res = new RestResponse();
	    req.requestURI = '/1net/resultSalesAppointments';
	    req.httpMethod = 'POST';
		RestContext.request = req;
		RestContext.response = res;
		RMS_mobileAppAPIController.doPost();
		Blob b = (blob) (RestContext.response.responseBody);
		System.debug('######  ' + b.toString());
		System.assert(b.toString().startsWith('An Error has occurred'));
	}

	static testmethod void testdoPostUnsupportedOperation(){
		RestRequest req = new RestRequest(); 
		RestResponse res = new RestResponse();
	    req.requestURI = '/1net/unsupportedOperationExample';
	    req.httpMethod = 'POST';
		RestContext.request = req;
		RestContext.response = res;
		RMS_mobileAppAPIController.doPost();
		Blob b = (blob) (RestContext.response.responseBody);
		System.assert(b.toString().startsWith('Unsupported operation:'));
	}

	static testmethod void testdoPostNoOperation(){
		RestRequest req = new RestRequest(); 
		RestResponse res = new RestResponse();
	    req.requestURI = '/1net';
	    req.httpMethod = 'POST';
		RestContext.request = req;
		RestContext.response = res;
		RMS_mobileAppAPIController.doPost();
		Blob b = (blob) (RestContext.response.responseBody);
		System.assert(b.toString().startsWith(RMS_mobileAppAPIController.NO_REQUEST_FOUND));
	}

	static testmethod void testdoPatch(){
		RestRequest req = new RestRequest(); 
		RestResponse res = new RestResponse();
	    req.requestURI = 'https://test';  
	    req.httpMethod = 'PATCH';
		RestContext.request = req;
		RestContext.response = res;
		RMS_mobileAppAPIController.doPatch();
		Blob b = (blob) (RestContext.response.responseBody);
		System.assert(b.toString().equals('patch'));
	}

	static testmethod void testdoDelete(){
		RestRequest req = new RestRequest(); 
		RestResponse res = new RestResponse();
	    req.requestURI = 'https://test';  
	    req.httpMethod = 'DELETE';
		RestContext.request = req;
		RestContext.response = res;
		RMS_mobileAppAPIController.doDelete();
		Blob b = (blob) (RestContext.response.responseBody);
		System.assert(b.toString().equals('delete'));
	}
}
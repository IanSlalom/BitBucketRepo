/*
 *@class	RMS_mobileAppAPIController
 *@brief	Controller for the mobile application custom apis
 *@author 	Anthony Strafaccia (Slalom.ADS)
 *@author 	Mark Wochnick (Slalom.MAW)
 *@version	2015-09/16  Slalom.ADS	Created.
 *@version	2015-10/12  Slalom.MAW
 *@copyright  (c)2015 Slalom.  All Rights Reserved.	Unauthorized use is prohibited.
 */
@RestResource(urlMapping='/1net/*')
global with sharing class RMS_mobileAppAPIController {
	// REST API Constants
	public static final String GET_APPOINTMENTS = 'getAppointments';
	public static final String RESULT_APPOINTMENTS = 'resultSalesAppointments';
	public static final String TIME_STAMP_KEY = 'TS';
	public static final String CREATE_CONTACT = 'createContact';
	public static final String CUSTOMER_JOB_SEARCH = 'customerJobSearch';
	public static final String GET_SELECTED_SEARCH_RESULTS = 'getSelectedSearchResults';
	public static final String SAVE_TECH_MEASURE = 'saveTechMeasure';
	
	// REST API Error Messages
	public static final String NO_REQUEST_FOUND = 'No request found: ';
	public static final String INVALID_DATETIMESTAMP = 'Invalid Date/Time Parameter';

	/* Reads only */	
	@HttpGet
    global static void doGet() {
		try {
//TODO: add api versioning
			RestRequest req = RestContext.request;
			String temp = req.requestURI.substringAfter('/');
			temp = temp.substringAfter('/');
			String operation = temp.substringBefore('/');
			if (operation == null || operation== ''){
				RestContext.response.addHeader('Content-Type', 'application/json');
				RestContext.response.responseBody = Blob.valueOf(NO_REQUEST_FOUND + req.requestURI);
			} else if (operation.equals(GET_APPOINTMENTS)) {
				Id userId = UserInfo.getUserId();
				String afterDateParam = req.params.get(TIME_STAMP_KEY);
				Datetime afterDTStamp = null;
				try {
					afterDTStamp = Datetime.valueOf(afterDateParam);
				} catch (Exception e) {
					// if the parameter is not set or the parameter format is incorrect set the query to now
					System.debug('RMS_mobileAppAPIController.doGet ' + INVALID_DATETIMESTAMP + ': ' + afterDateParam);
					afterDTStamp = Datetime.now();
				}
				RMS_mobileAppRequestHelper handler = new RMS_mobileAppRequestHelper();
				RestContext.response.addHeader('Content-Type', 'application/json');
				RestContext.response.responseBody = Blob.valueOf(handler.findAppointments(userId, afterDTStamp));
			} else {
				RestContext.response.addHeader('Content-Type', 'application/json');
				RestContext.response.responseBody = Blob.valueOf('Unsupported operation: ' + req.requestURI + ' - temp ' + temp + ' - operation: ' + operation + ' params: ' + req.params);
			}
		} catch (Exception e) {
			RestContext.response.addHeader('Content-Type', 'application/json');
			RestContext.response.responseBody = Blob.valueOf('Unhandled Exception: ' + e.getMessage() + ' Stack trace: ' + e.getStackTraceString());
			System.debug(LoggingLevel.ERROR, 'RMS_mobileAppAPIController.doGet: Unhandled exception: ' + e);
		}
    }
    
	/* creates and multi operation requests */
	@HttpPut
    @HttpPost
    global static void doPost(){
		try {
			RestRequest req = RestContext.request;
			RestContext.response.addHeader('Content-Type', 'application/json');
			String temp = req.requestURI.substringAfter('/');
			temp = temp.substringAfter('/');
			String operation = temp.substringBefore('/');
			if (operation == null || operation== ''){			
				RestContext.response.responseBody = Blob.valueOf(NO_REQUEST_FOUND + req.requestURI);
			} else if (operation.equals(RESULT_APPOINTMENTS)) {
				Id userId = UserInfo.getUserId();
				RMS_mobileAppRequestHelper handler = new RMS_mobileAppRequestHelper();
				String result = handler.resultSalesAppointments(userId, req.requestBody.toString());
				// lets handle the processed result
				RestContext.response.responseBody = Blob.valueOf(result);
			} else if (operation.equals(CREATE_CONTACT)){
				String result = RMS_mobileAppContactHelper.saveNewContact(req.requestBody.toString());
				RestContext.response.responseBody = Blob.valueOf(result);
			} else if (operation.equals(CUSTOMER_JOB_SEARCH)){
				RMS_mobileAppRequestHelper handler = new RMS_mobileAppRequestHelper();
				String result = handler.customerSearch(req.requestBody.toString());
				RestContext.response.responseBody = Blob.valueOf(result);
			} else if (operation.equals(GET_SELECTED_SEARCH_RESULTS)){
				RMS_mobileAppRequestHelper handler = new RMS_mobileAppRequestHelper();
				String result = handler.getSelectedSearchResults(req.requestBody.toString());
				RestContext.response.responseBody = Blob.valueOf(result);
			} else if (operation.equals(SAVE_TECH_MEASURE)){
				RMS_mobileAppRequestHelper handler = new RMS_mobileAppRequestHelper();
				String result = handler.saveTechMeasure(req.requestBody.toString());
				RestContext.response.responseBody = Blob.valueOf(result);
			} else {
				RestContext.response.responseBody = Blob.valueOf('Unsupported operation: ' + req.requestURI + ' - temp ' + temp + ' - operation: ' + operation + ' params: ' + req.params);
			}
		} catch (Exception e) {
			RestContext.response.addHeader('Content-Type', 'application/json');
			RestContext.response.responseBody = Blob.valueOf('Unhandled Exception: ' + e.getMessage() + ' Stack trace: ' + e.getStackTraceString());
			System.debug(LoggingLevel.ERROR, 'RMS_mobileAppAPIController.doPost: Unhandled exception: ' + e);
		}
    }

	/* Updates only */
    @HttpPatch
    global static void doPatch(){
		try {
			RestContext.response.addHeader('Content-Type', 'application/json');
			RestContext.response.responseBody = Blob.valueOf('patch');
		} catch (Exception e) {
			RestContext.response.addHeader('Content-Type', 'application/json');
			RestContext.response.responseBody = Blob.valueOf('Unhandled Exception: ' + e.getMessage() + ' Stack trace: ' + e.getStackTraceString());
			System.debug(LoggingLevel.ERROR, 'RMS_mobileAppAPIController.doPatch: Unhandled exception: ' + e);
		}
    }

	/* Deletes only */
    @HttpDelete
    global static void doDelete(){
		try {
			RestContext.response.addHeader('Content-Type', 'application/json');
			RestContext.response.responseBody = Blob.valueOf('delete');
		} catch (Exception e) {
			RestContext.response.addHeader('Content-Type', 'application/json');
			RestContext.response.responseBody = Blob.valueOf('Unhandled Exception: ' + e.getMessage() + ' Stack trace: ' + e.getStackTraceString());
			System.debug(LoggingLevel.ERROR, 'RMS_mobileAppAPIController.doDelete: Unhandled exception: ' + e);
		}
    }

}
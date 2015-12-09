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
	public static final String TIME_STAMP_KEY = 'after';
	
	// REST API Error Messages
	public static final String NO_REQUEST_FOUND = 'No request found: ';
	public static final String INVALID_DATETIMESTAMP = 'Invalid Date/Time Parameter';

	/* Reads only */	
	@HttpGet
    global static void doGet() {
    	
		RestRequest req = RestContext.request;
		String temp = req.requestURI.substringAfter('/');
		temp = temp.substringAfter('/');
		String operation = temp.substringBefore('/');
		if (operation == null || operation== ''){
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
			RestContext.response.responseBody = Blob.valueOf('Unsupported operation: ' + req.requestURI + ' - temp ' + temp + ' - operation: ' + operation + ' params: ' + req.params);
		}
    }
    
	/* creates and multi operation requests */
	@HttpPut
    @HttpPost
    global static String doPost(){
		RestRequest req = RestContext.request;
		String finalURLpart = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
    	if(finalURLpart == 'updateOpps'){
			RMS_mobileAppRequestHelper handler = new RMS_mobileAppRequestHelper();
			Map<String, String> parameters = req.params;
    		return handler.updateOpportunity(parameters.get('OppId'),parameters.get('Status'));
			return 'true';
    	} 
    	else if(finalURLpart == '' || finalURLpart == null){
			//call handler.method to get stuff
			return 'post';
		}else{
			return 'error';
		}
    }

	/* Updates only */
    @HttpPatch
    global static String doPatch(){
		return 'patch';
    }

	/* Deletes only */
    @HttpDelete
    global static String doDelete(){
		return 'delete';
    }

//    @HttpHead
//    global static String httpHead(){
//		return 'HEAD - Not Sujpported';
//    }
}
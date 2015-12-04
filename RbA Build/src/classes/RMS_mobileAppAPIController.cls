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
	
	// REST API Error Messages
	public static final String NO_REQUEST_FOUND = 'No request found: ';

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
			RMS_mobileAppRequestHelper handler = new RMS_mobileAppRequestHelper();
			RestContext.response.addHeader('Content-Type', 'application/json');
			RestContext.response.responseBody = Blob.valueOf(handler.findAppointments(userId));
		}else{
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
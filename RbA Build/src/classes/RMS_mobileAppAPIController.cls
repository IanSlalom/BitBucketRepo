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

	@HttpGet
    global static void httpGet() {
		RestRequest req = RestContext.request;
		String finalURLpart = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
		if(finalURLpart == '' || finalURLpart == null){
			Id userId = UserInfo.getUserId();
			RMS_priceCalcSlimAPILogic handler = new RMS_priceCalcSlimAPILogic();
			RestContext.response.addHeader('Content-Type', 'application/json');
			RestContext.response.responseBody = Blob.valueOf(handler.findAppointments(userId));
		}else{
			RestContext.response.responseBody = Blob.valueOf('error');
		}
    }
    
    
    @HttpPost
    global static String httpPost(){
		RestRequest req = RestContext.request;
		String finalURLpart = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
    	if(finalURLpart == 'updateOpps'){
			RMS_priceCalcSlimAPILogic handler = new RMS_priceCalcSlimAPILogic();
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
}
@RestResource(urlMapping='/pcs/*')
global with sharing class RMS_priceCalcSlimAPIController {

	static RestRequest req = RestContext.request;
	static String finalURLpart = RMS_priceCalcSlimAPIController.req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
	static RMS_priceCalcSlimAPILogic handler = new RMS_priceCalcSlimAPILogic();
	
	static Map<String, String> parameters = req.params;
	
	@HttpGet
    global static String httpGet() {
		if(RMS_priceCalcSlimAPIController.finalURLpart == '' || RMS_priceCalcSlimAPIController.finalURLpart == null){
			return handler.findAppointments(parameters.get('UserId'));
				//use the User Info CLASS
		}else{
			return 'error';
		}
    }
    
    
    @HttpPost
    global static String httpPost(){
    	if(finalURLpart == 'updateOpps'){
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
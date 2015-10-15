public with sharing class RMS_completeOrderChecksController {

    public list<Back_Office_Check__c> selectedChecks {get;set;}
    public Id ordId;
    //selected
    public RMS_completeOrderChecksController(ApexPages.StandardSetController controller) {
        //controller.setPageSize(20);
        
        ordId = ApexPages.currentPage().getParameters().get('Id');
        List<Back_Office_Check__c> relatedBOC = [SELECT Id, Name, Completed__c, Signed_Date__c, Order__c FROM Back_Office_Check__c WHERE Order__c = :ordId ];
        selectedChecks = relatedBOC;

    }
    
    public pageReference save(){
    	update selectedChecks;
    	
    	PageReference newPage = New PageReference('/'+ordId);
		newPage.setRedirect(true);
		return newPage;
    }
}
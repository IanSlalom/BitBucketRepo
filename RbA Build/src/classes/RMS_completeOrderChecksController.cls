/*******************************************************//**
@class  RMS_completeOrderChecksController

@brief  Controller for RMS_completeOrderChecks visualforce page

@author  Slalom

@version    2016-2-18  Slalom.CDK
    Created.

@copyright  (c)2016 Slalom.  All Rights Reserved. 
            Unauthorized use is prohibited.

***********************************************************/
public with sharing class RMS_completeOrderChecksController {

    public list<Back_Office_Check__c> selectedChecks {get;set;}
    public Id ordId{get;set;}
    //selected
    public RMS_completeOrderChecksController(ApexPages.StandardSetController controller) {
        //controller.setPageSize(20);
        
        ordId = ApexPages.currentPage().getParameters().get('Id');
        List<Back_Office_Check__c> relatedBOC = [SELECT Id, Name, Completed__c, Signed_Date__c, Order__c FROM Back_Office_Check__c WHERE Order__c = :ordId ];
        selectedChecks = relatedBOC;

    }
    
    public pageReference save(){
        try{
    	update selectedChecks;
    	Boolean allChecksCompleted = true;
        for(Back_Office_Check__c check : selectedChecks){
            if(!check.Completed__c){
                allChecksCompleted = false;
                break;
            }
        }

        if(allChecksCompleted){
            Order order = [SELECT Id, Status, Tech_Measure_Status__c, Order_Processed_Date__c FROM Order WHERE Id =: ordId];
            if(order.Status == 'Draft'){
                if(order.Order_Processed_Date__c == null){
                 order.Order_Processed_Date__c = System.Today();   
                }                
                order.Status = 'Tech Measure Needed';
                if(order.Tech_Measure_Status__c == 'Scheduled'){
                    order.Status = 'Tech Measure Scheduled';
                }
                update order;
            }
        }
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Some Back Office Checks could not be saved. Please check Error Messages above.'));
        }
        //JETT-2143 Removed page redirect from controller, tab closing/page redirection is handled by vf page instead.
        return null;
    }
}
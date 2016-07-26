/*******************************************************//**

@class  RMS_populateResourceonEventManager


@author  Brianne Wilson (Slalom.BLW)

@brief When an event is created for a work order, user selects
who should be the assignee. If user selects, "Primary Resource" checkbox,
this class will search for the Resource record where the Event Assignee =
Resource RbA User and populates the Resource record onto the Event. 

@version    2016-05-11 Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/

public with sharing class RMS_populateResourceonEventManager {
    
    public void populateResourceonUpdate(List<Event> listOld, List<Event> listNew, Map<Id, Event> mapOld, Map<Id, Event> mapNew){
        
        List<Id> resource = new List<Id>(); 
        
        
        for(Event e : listNew){
            If(e.Primary_Resource__c == true){
                If((e.MA_Scheduler_Event__c == null) || (e.MA_Scheduler_Event__c != null && e.Type != 'Install')){
                    resource.add(e.OwnerId);   
                }
            }   
        }
        List <Resource__c> resourceList = [Select ID, RbA_User__c from Resource__c where RbA_User__c in :resource];
        
        for (Integer i = 0; i <listNew.size(); i++){
            if (resourceList.size() > 0 && listNew[i].OwnerId !=null){
                for (Resource__c z:resourceList){
                    if (listNew[i].OwnerId == z.RbA_User__c){
                        listNew[i].Resource__c = z.ID;
                    }
                }
            }
            else{
                listNew[i].Resource__c = listNew[i].Resource__c;
                
            }
            
        }
        
    }
    
    public void populateInstallCrew(List<Event> listOld, List<Event> listNew, Map<Id, Event> mapOld, Map<Id, Event> mapNew){
        List<Id> maEvent = new List<Id>();
        
        for(Event e :listNew){
            if(e.Primary_Resource__c == true){
                if(e.MA_Scheduler_Event__c != null && e.Type == 'Install'){
                    maEvent.add(e.MA_Scheduler_Event__c);
                }
            }	
        }
        
        List <MA_Scheduler_Event__c> eventList = [SELECT Id, Resource__c FROM MA_Scheduler_Event__c WHERE Id in :maEvent];
        
        for(Integer i=0; i<listNew.size(); i++){
            if(eventList.size() > 0){
                for (MA_Scheduler_Event__c z:eventList){
                    listNew[i].Resource__c = z.Resource__c;
                }
            }

        }
    }
    
    
}
public with sharing class RMS_populateResourceonEventManager {
    
    public void populateResourceonUpdate(List<Event> listOld, List<Event> listNew, Map<Id, Event> mapOld, Map<Id, Event> mapNew){
        
       List<Id> resource = new List<Id>(); 
       
        
        for(Event e : listNew){
            If(e.Primary_Resource__c == true){
                resource.add(e.OwnerId);   
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
                listNew[i].Resource__c = null;
            }
            
        }

    }
    }
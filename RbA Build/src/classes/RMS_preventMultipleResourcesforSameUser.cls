public with sharing class RMS_preventMultipleResourcesforSameUser {
    
    public void preventMultipleResourcesforSameUser(List<Resource__c> listOld, List<Resource__c> listNew, Map<Id, Resource__c> mapOld, Map<Id, Resource__c> mapNew){
        String errorMessage = '';
        List<Id> user = new List<Id>();      
        
        
        for(Resource__c e : listNew){
            If(e.Resource_Type__c != null){
                user.add(e.RbA_User__c);   
            }   
        }
        
        List <Resource__c> resourceList = [Select ID, RbA_User__c, Resource_Type__c from Resource__c where RbA_User__c in :user];
        
        for (Integer i = 0; i <listNew.size(); i++){
            if (resourceList.size() > 0 && listNew[i].OwnerId !=null){
                for (Resource__c z:resourceList){
                    if (listNew[i].OwnerId == z.RbA_User__c && listNew[i].Resource_Type__c != z.Resource_Type__c){
                        listNew[i].addError('You already have a resource for this user, you may not have multiple resources for the same user with different resource types. Please add to the secondary resource type(s) field. Note: You may create multiple Resource records for the same resource and type for different stores.'); 
                    }
                }
            }            
            
        }
        
    }
}
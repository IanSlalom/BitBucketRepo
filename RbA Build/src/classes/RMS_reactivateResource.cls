/*************************************************************
@brief  When an insurance exp date is updated on a vendor account,
any inactive resources for that vendor are reactivated

@author  Brianne Wilson (Slalom.BLW)

@version    2016-5-20  Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/

public class RMS_reactivateResource {
    
    public void reactivateResource(List<Account> listOld, List<Account> listNew, Map<Id, Account> mapOld, Map<Id, Account> mapNew){
        
        List<Resource__c> childRecords = [Select Id, RbA_User__c, Vendor_Account_Id__c,RbA_User__r.Contact.AccountId
                                                FROM Resource__c WHERE Active__c = FALSE and RbA_User__r.Contact.AccountId IN: Trigger.newMap.keySet()];
        
        system.debug(childRecords);
        
        Map<Id,Resource__c> resourceMap = new Map<Id,Resource__c>([select Id from Resource__c where id in:childRecords]);
        
        for(Resource__c child :childRecords){
            if(!resourceMap.IsEmpty()){   
                if(mapNew.get(child.RbA_User__r.Contact.AccountId).Inactive_Date__c != null && mapNew.get(child.RbA_User__r.Contact.AccountId).Inactive_Date__c != mapOld.get(child.RbA_User__r.Contact.AccountId).Inactive_Date__c){
                   if(mapNew.get(child.RbA_User__r.Contact.AccountId).Inactive_Date__c >= system.TODAY()){
                    child.Active__c = TRUE;                    
                    }
                }                              
            }
        }
        
        if(childRecords.size() > 0){
            update childRecords;
        }                    
    }
}
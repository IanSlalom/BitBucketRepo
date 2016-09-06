/*******************************************************//**

@class  RMS_createContactHistoryManager

@brief  When a Contact is created, a Contact History record is created. 
Primary Contact and Primary Dwelling for Contact are passed from Contact
to Contact History. Should a Contact have their Account change, a Contact
History record is created as well. This means each Contact has at least one
Contact History record. They should have a Contact History record for each
Account they have had populated in the "Account" field over time.

Note: Contact related list on the Account page is actually the list of Contact Histories
in order to view all Contacts who have lived at that Dwelling. The "New Contact" button; h
however brings user to "Create Contact" page.

@author  Brianne Wilson (Slalom.BLW)
@version    2016-4-19  Slalom.BLW

Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
public with sharing class RMS_createContactHistoryManager {
    
    Id customerContactRecordType = UtilityMethods.retrieveRecordTypeId('Customer_Contacts', 'Contact');
    map<String, RMS_Settings__c> RMS_Settings_map = RMS_Settings__c.getAll(); 
    //Id masterAccountId = RMS_Settings_map.get('Unassigned Account Id').Value__c;
    
    
    public void createContactHistoryonInsert(List<Contact> listNew){
        
        List<Contact_History__c> newContactHistories = new list<Contact_History__c>();        
        
        
        Map<Id,Id> mapCurrentPrimary = new Map<Id,Id>();
        List<Contact_History__c> contactHistoriestoUpdate = new List<Contact_History__c>();
        List<Id> relatedAccountIds = new list<Id>();             
        
        for(Contact con : listNew){ 
            if(con.AccountId != null && con.RecordTypeId == customerContactRecordType){
                Contact_History__c ch = new Contact_History__c(
                    Contact__c = con.Id,
                    Dwelling__c = con.AccountId,
                    Primary_Contact__c = con.Primary_Contact__c,
                    Type__c = 'Current Resident');
                
                newContactHistories.add(ch);
                if(con.Primary_Contact__c == True){
                    mapCurrentPrimary.put(con.AccountId, con.Id);
                    relatedAccountIds.add(con.AccountId);
                }
            }
        }
        
        insert newContactHistories;
        
        for(Contact_History__c contactHistoryList: [SELECT Id, Primary_Contact__c, Type__c FROM Contact_History__c WHERE Primary_Contact__c = TRUE AND Type__c = 'Current Resident' AND Dwelling__c in: mapCurrentPrimary.keySet() AND Contact__c !=: mapCurrentPrimary.values()]){            
            contactHistoryList.Primary_Contact__c = False;
            contactHistoriestoUpdate.add(contactHistoryList);            
        }
        
        update contactHistoriestoUpdate;
        
        List<Account> parentAccount = [SELECT Id, Primary_Contact__c FROM Account WHERE Id in :relatedAccountIds];
        for(Contact con : listNew){
            for(Account parent :parentAccount){
                if(con.Primary_Contact__c == TRUE){
                    parent.Primary_Contact__c = con.Full_Name__c;
                }
            }  
        }
        
        update parentAccount;
        
        List<Contact> formerPrimary = [SELECT Id, Primary_Contact__c, AccountId FROM Contact WHERE AccountId In:relatedAccountIds AND Primary_Contact__c = TRUE AND Id NOT IN : Trigger.newMap.keySet()];
        
        Map<Id, Contact> contactMap = new Map<Id,Contact>([SELECT Id from Contact WHERE Id in:formerPrimary]);          
        
        for(Contact con : listNew){
            for(Contact former :formerPrimary){
                if(!contactMap.isEmpty()){                    
                    former.Primary_Contact__c = FALSE;                                   
                }  
            }
            
        }
        if(formerPrimary.size()>0){
            update formerPrimary;
        }
    }
    
    
    //If Contact History is Primary, uncheck any others as primary
    public void primaryContactController(List<Contact_History__c> listOld, List<Contact_History__c> listNew, Map<Id, Contact_History__c> mapOld, Map<Id, Contact_History__c> mapNew){                               
        
        Map<Id,Id> mapCurrentPrimary = new Map<Id,Id>();
        List<Contact_History__c> contactHistoriestoUpdate = new List<Contact_History__c>();
        
        for(Contact_History__c con : listNew){ 
            if(con.Primary_Contact__c == True){
                mapCurrentPrimary.put(con.Dwelling__c, con.Contact__c);
                
            }
        }
        
        
        for(Contact_History__c contactHistoryList: [SELECT Id, Primary_Contact__c, Type__c FROM Contact_History__c WHERE Primary_Contact__c = TRUE AND Type__c = 'Current Resident' AND Dwelling__c in: mapCurrentPrimary.keySet() AND Contact__c !=: mapCurrentPrimary.values()]){            
            
            contactHistoryList.Primary_Contact__c = False;           
            contactHistoriestoUpdate.add(contactHistoryList);            
        }
        
        update contactHistoriestoUpdate;
        
    }
    
    //If new Contact History indicates to update Account on Contact, do so    
    public void updateContactAccount(List<Contact_History__c> listOld, List<Contact_History__c> listNew, Map<Id, Contact_History__c> mapOld, Map<Id, Contact_History__c> mapNew){
        
        List <Id> contact = new List<Id>();
        List<Id> account = new List<Id>();        
        
        for(Contact_History__c ch : listNew){
            If(mapOld.get(ch.Id).Update_Contact_Account__c != mapNew.get(ch.Id).Update_Contact_Account__c){
                contact.add(ch.Contact__c);   
                account.add(ch.Dwelling__c);
            }   
        }
        
        List <Contact> con = [Select ID, AccountId from Contact where Id in :contact];
        List <Account> acc = [Select Id, Primary_Contact__c from Account WHERE Id in :account];
        List <Contact> primary = [Select Id, AccountId, Primary_Contact__c FROM Contact WHERE AccountId IN :account AND Id NOT IN :contact AND Primary_Contact__c = TRUE];
        
        for (Integer i = 0; i <listNew.size(); i++){
            if (con.size() > 0){
                for (Contact z:con){
                    if (listNew[i].Update_Contact_Account__c == true && mapOld.get(listNew[i].Id).Update_Contact_Account__c == false){
                        z.AccountId = listNew[i].Dwelling__c;
                    }
                    if (listNew[i].Primary_Contact__c == true){
                        z.Primary_Contact__c = true;
                    }
                }
            }
            if(acc.size()>0){
                for(Account a:acc){
                    if (listNew[i].Primary_Contact__c == true){
                        a.Primary_Contact__c = listNew[i].Full_Name__c;
                    }
                }
            }
            if(primary.size()>0){
                for(Contact c :primary){
                    if (listNew[i].Primary_Contact__c == true){
                        c.Primary_Contact__c = FALSE;
                    }
                }
            } 
            
            
        }
        update con; 
        update acc;
        update primary;
    }
    
    //if Account changes on Contact, verify that there aren't any Contact Histories already for this Contact and Account. If there aren't create one.
    public void createContactHistoryUpdate(List<Contact> listOld, List<Contact> listNew, Map<Id, Contact> mapOld, Map<Id, Contact> mapNew){
        
        List<Contact_History__c> childCH = [SELECT Id, Contact__c, Dwelling__c, Type__c FROM Contact_History__c WHERE Contact__c IN: Trigger.newMap.keySet()];
        
        List<Id> relatedAccountIds = new list<Id>();        
        
        for(Contact con : listNew){
            if(mapOld.get(con.Id).AccountId != mapNew.get(con.Id).AccountId){ 
                relatedAccountIds.add(con.AccountId);
            }
        }        
        
        Map<Id, Contact_History__c> contactHMap = new Map<Id,Contact_History__c>([SELECT Id from Contact_History__c WHERE Id in:childCH AND Dwelling__c in:relatedAccountIds AND Type__c = 'Current Resident']);
        
        List<Contact_History__c> updatedContact = new list<Contact_History__c>();
        Id customerContactRecordType = UtilityMethods.retrieveRecordTypeId('Customer_Contacts', 'Contact');
        
        for(Contact con : listNew){
            if(contactHMap.isEmpty()){
                if(con.AccountId != null && mapOld.get(con.Id).AccountId != con.AccountId && con.RecordTypeId == customerContactRecordType){
                    updatedContact.add(new Contact_History__c(
                        Contact__c = con.Id,
                        Dwelling__c = con.AccountId,
                        Primary_Contact__c = con.Primary_Contact__c,
                        Type__c = 'Current Resident'));
                }
                
            }          
        }
        insert updatedContact;
    }
    
    //if Make Primary is checked/unchecked on the Contact, uncheck on the Contact History for Contact and Account
    public void uncheckPrimary(List<Contact> listOld, List<Contact> listNew, Map<Id, Contact> mapOld, Map<Id, Contact> mapNew){                
        
        List<Id> relatedAccountIds = new list<Id>();
        
        for(Contact con : listNew){
            if((mapNew.get(con.Id).Primary_Contact__c != mapOld.get(con.Id).Primary_Contact__c)|| mapNew.get(con.Id).Primary_Contact__c == TRUE){
                relatedAccountIds.add(con.AccountId);
            }
        }
        List<Contact_History__c> childCH = [SELECT Id, Primary_Contact__c, Contact__c, Dwelling__c, Type__c FROM Contact_History__c WHERE Contact__c IN: Trigger.newMap.keySet() AND Dwelling__c in: relatedAccountIds];
        Map<Id, Contact_History__c> contactHMap = new Map<Id,Contact_History__c>([SELECT Id from Contact_History__c WHERE Id in:childCH]);          
        
        List<Account> parentAccount = [SELECT Id, Primary_Contact__c FROM Account WHERE Id in :relatedAccountIds];
        
        for(Contact con : listNew){
            for(Contact_History__c child :childCH){
                if(!contactHMap.isEmpty()){
                    if(mapNew.get(child.Contact__c).Primary_Contact__c != mapOld.get(child.Contact__c).Primary_Contact__c){
                        child.Primary_Contact__c = con.Primary_Contact__c;
                    }
                    
                }  
            }
            
            for(Account parent :parentAccount){
                if(con.Primary_Contact__c == TRUE){
                    parent.Primary_Contact__c = con.Full_Name__c;
                }
            }
            
        }
        if(childCH.size()>0){
            update childCH;
        }
        
        if(parentAccount.size()>0){
            update parentAccount;
        }
    }
    

    //formerly moveContacttoUnassigned Method
    public void contactManager(List<Contact_History__c> listOld, List<Contact_History__c> listNew, Map<Id, Contact_History__c> mapOld, Map<Id, Contact_History__c> mapNew){                               
        
        List<Id> relatedContact = new list<Id>();
        
        for(Contact_History__c ch : listNew){
            if(ch.Type__c == 'Past Resident' && mapOld.get(ch.Id).Type__c != mapNew.get(ch.Id).Type__c){
                relatedContact.add(ch.Contact__c);
            }
        }
        
        List<Contact> maptoContact = [SELECT Id,AccountId,Primary_Contact__c FROM Contact WHERE Id in:relatedContact];
        
        
        List<Id> chList = new List<Id>();
        
        for(Contact_History__c hist : [SELECT Id, Type__c, Contact__c
                                       FROM Contact_History__c
                                       WHERE Contact__c = :relatedContact
                                       AND Type__c = 'Current Resident']){
                                           chList.add(hist.Id);
                                       }
        
        List<Contact_History__c> currentResident = [SELECT Id FROM Contact_History__c WHERE Id in:chList];
        
        
        for(Integer i = 0; i <listNew.size(); i++){
            for(Contact z: maptoContact){
                if(currentResident.size() > 0){
                    z.AccountId = z.AccountId;
                } else {
                    
                    //z.AccountId = masterAccountId;
                    z.Primary_Contact__c = FALSE;
                }
            }
        }
        update maptoContact;
        
    }
    
    public void uncheckFormerPrimary(List<Contact> listOld, List<Contact> listNew, Map<Id, Contact> mapOld, Map<Id, Contact> mapNew){                
        
        List<Id> relatedAccountIds = new list<Id>();
        
        for(Contact con : listNew){
            if((mapNew.get(con.Id).Primary_Contact__c != mapOld.get(con.Id).Primary_Contact__c) && mapNew.get(Con.Id).Primary_Contact__c == True){
                relatedAccountIds.add(con.AccountId);
            }
        }
        
        List<Contact> formerPrimary = [SELECT Id, Primary_Contact__c, AccountId FROM Contact WHERE AccountId In:relatedAccountIds AND Primary_Contact__c = TRUE AND Id NOT IN : Trigger.newMap.keySet()];
        
        Map<Id, Contact> contactMap = new Map<Id,Contact>([SELECT Id from Contact WHERE Id in:formerPrimary]);          
        
        for(Contact con : listNew){
            for(Contact former :formerPrimary){
                if(!contactMap.isEmpty()){                    
                    former.Primary_Contact__c = FALSE;                                   
                }  
            }
            
        }
        if(formerPrimary.size()>0){
            update formerPrimary;
        }
    }
    
}
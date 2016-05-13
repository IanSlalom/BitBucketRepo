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
    Id masterAccountId = RMS_Settings_map.get('Unassigned Account Id').Value__c;
    
    //JETT-2100 When a Contact is moved to a new Account, any existing Contact Histories are moved to 'Past Resident'
    //except for Spouse, then update/insert a Contact History for updated contact as 'Current Resident'
    public void createContactHistoryonUpdate( Map<Id, Contact> mapOld, Map<Id, Contact> mapNew){

        List<Contact_History__c> historiesToUpsert = new list<Contact_History__c>();
        Map<Contact,Id> mapContactToNewAccount = new Map<Contact,Id>();
        Map<Id,List<Contact_History__c>> mapAccountToHistories = new Map<Id,List<Contact_History__c>>();
        Set<Id> spouseIds = new Set<Id>();
        Set<Id> contactsToMove = new Set<Id>();
        for(Contact con : mapNew.values()){   
            //Exclude processing for Contacts that are reparented to the Master Account record
            if(con.AccountId != null && con.AccountId != masterAccountId && mapOld.get(con.Id).AccountId != con.AccountId && con.RecordTypeId == customerContactRecordType){
                 mapContactToNewAccount.put(con,con.AccountId);
                 if(con.Spouse__c != null){
                    spouseIds.add(con.Spouse__c);
                 }
            }
        }

        for(Contact_History__c hist: [Select Id, Contact__c, Dwelling__c, Type__c from Contact_History__c where Dwelling__c in: mapContactToNewAccount.values()]){
            if(mapAccountToHistories.containsKey(hist.Dwelling__c)){
                mapAccountToHistories.get(hist.Dwelling__c).add(hist);
            }else{
                 mapAccountToHistories.put(hist.Dwelling__c, new List<Contact_History__c>{hist});
            }
        }

        //TODO: Moving contacts code needs to be corrected, currently not verifying that the contact to be moved is a detail to the correct account
        for(Contact c: mapContactToNewAccount.keySet()){
            boolean insertNewHistory = true;
            for(Contact_History__c hist: mapAccountToHistories.get(mapContactToNewAccount.get(c))){
                if(hist.Contact__c == c.Id){
                    hist.Type__c = 'Current Resident';
                    insertNewHistory = false;
                }else if(hist.Contact__c == c.Spouse__c){
                    hist.Type__c = 'Current Resident';
                }else if(hist.Type__c == 'Current Resident'){
                    hist.Type__c = 'Past Resident';
                    contactsToMove.add(hist.Contact__c);
                }
                historiesToUpsert.add(hist);
            }
            if(insertNewHistory){
                historiesToUpsert.add(new Contact_History__c(
                    Contact__c = c.Id,
                    Dwelling__c = c.AccountId,
                    Primary_Contact__c = c.Primary_Contact__c,
                    Type__c = 'Current Resident',
                    Primary_Dwelling_for_Contact__c = c.Primary_Dwelling_for_Contact__c));
            }
        }
        upsert historiesToUpsert;

        //Finally any existing Contacts that are linked to account who have had their Contact History record changed to Past Resident need to get updated to a new account.
        //After their Contact History records are update to Past Resident, if the Contact has no other Contact History records where they are the Current Resident then
        //change the Account to the Unassigned Account
        //else if the do have Current Resident Contact History records on another account then
        //assign the Contact to the newest (last modified) Current Resident Account
        List<Contact_History__c> contactsToMoveHistories =  [Select Id, Contact__c, Dwelling__c, LastModifiedDate from Contact_History__c 
                                                                            Where Contact__c in: contactsToMove and Type__c = 'Current Resident'];
        Map<Id,Contact_History__c> mapContactIdToLastModifiedCurrentResidentHistory = new Map<Id,Contact_History__c>();
        for(Contact_History__c hist: contactsToMoveHistories){
            if(mapContactIdToLastModifiedCurrentResidentHistory.containsKey(hist.Contact__c)){
                if(hist.LastModifiedDate > mapContactIdToLastModifiedCurrentResidentHistory.get(hist.Contact__c).LastModifiedDate){
                    mapContactIdToLastModifiedCurrentResidentHistory.put(hist.Contact__c,hist);
                }
            }else{
                mapContactIdToLastModifiedCurrentResidentHistory.put(hist.Contact__c,hist);
            }
        }

        //For contacts that are child records of the accounts, reparent them. Exclude the updated contact and the spouse.
        List<Contact> contactsToUpdate = [Select Id, AccountId from Contact where Id in: contactsToMove];
        for(Contact c: contactsToUpdate){
            if(mapContactIdToLastModifiedCurrentResidentHistory.containsKey(c.Id)){
                c.AccountId = mapContactIdToLastModifiedCurrentResidentHistory.get(c.Id).Dwelling__c;
            }else{
            c.AccountId = masterAccountId;
            }
        }
        update contactsToUpdate;
    }
    
    //JETT-2100 When a contact is inserted, create a 'Current Resident' contact history for that contact related to the account
    //If the spouse has a contact history on the account, update type to 'Current Resident'
    public void createContactHistoryonInsert(List<Contact> listNew){
        
        List<Contact_History__c> newContactHistories = new list<Contact_History__c>();        

       
        Map<Id,Id> mapAccountToSpouse = new Map<Id,Id>();
        List<Contact_History__c> spouseHistoriesToUpdate = new List<Contact_History__c>();

        
        for(Contact con : listNew){ 
            if(con.AccountId != null && con.RecordTypeId == customerContactRecordType){
                Contact_History__c ch = new Contact_History__c(
                    Contact__c = con.Id,
                    Dwelling__c = con.AccountId,
                    Primary_Contact__c = con.Primary_Contact__c,
                    Type__c = 'Current Resident',
                    Primary_Dwelling_for_Contact__c = con.Primary_Dwelling_for_Contact__c);
                
                newContactHistories.add(ch);
                if(con.Spouse__c != null){
                    mapAccountToSpouse.put(con.AccountId, con.Spouse__c);
                }
            }
        }

        insert newContactHistories;

        for(Contact_History__c spouseHistory: [Select Id, Type__c, Dwelling__c, Contact__c from Contact_History__c Where Dwelling__c in: mapAccountToSpouse.keySet() AND Contact__c in :mapAccountToSpouse.values()]){
            if(spouseHistory.Type__c != 'Current Resident' && mapAccountToSpouse.get(spouseHistory.Dwelling__c) == spouseHistory.Contact__c){
                spouseHistory.Type__c = 'Current Resident';
                spouseHistoriesToUpdate.add(spouseHistory);
            }
        }

        update spouseHistoriesToUpdate;
        
    }
    
}
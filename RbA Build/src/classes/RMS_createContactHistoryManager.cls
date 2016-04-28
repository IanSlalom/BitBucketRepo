public with sharing class RMS_createContactHistoryManager {
    
    public void createContactHistoryonUpdate(List<Contact> listOld, List<Contact> listNew, Map<Id, Contact> mapOld, Map<Id, Contact> mapNew){
        
        List<Contact_History__c> updatedContact = new list<Contact_History__c>();
                Id customerContactRecordType = UtilityMethods.retrieveRecordTypeId('Customer_Contacts', 'Contact');
        
        for(Contact con : listNew){
            if(con.AccountId != null && mapOld.get(con.Id).AccountId != con.AccountId && con.RecordTypeId == customerContactRecordType){
                updatedContact.add(new Contact_History__c(
                    Contact__c = con.Id,
                    Dwelling__c = con.AccountId,
                    Primary_Contact__c = con.Primary_Contact__c,
                    Type__c = 'Current Resident',
                    Primary_Dwelling_for_Contact__c = con.Primary_Dwelling_for_Contact__c));
            }
        }
        insert updatedContact;
    }
    
    public void createContactHistoryonInsert(List<Contact> listNew, Map<Id, Contact> mapNew){
        
        List<Contact_History__c> newContact = new list<Contact_History__c>();        
        List<Id> relatedAccountIds = new list<Id>();
        Id customerContactRecordType = UtilityMethods.retrieveRecordTypeId('Customer_Contacts', 'Contact');
        
        for(Contact con : listNew){
            relatedAccountIds.add(con.AccountId);
        }
        
        for(Contact con : listNew){ 
            if(con.AccountId != null && con.RecordTypeId == customerContactRecordType){
                Contact_History__c ch = new Contact_History__c(
                    Contact__c = con.Id,
                    Dwelling__c = con.AccountId,
                    Primary_Contact__c = con.Primary_Contact__c,
                    Type__c = 'Current Resident',
                    Primary_Dwelling_for_Contact__c = con.Primary_Dwelling_for_Contact__c);
                
                newContact.add(ch);
            }
        }
        insert newContact;
        
    }
    
}
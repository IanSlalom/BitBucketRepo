public with sharing class RMS_addressManager {
    
    //When Account Address Changes, update Address on all child Contacts
    public void updateContactAddresses(List<Account> listOld, List<Account> listNew, Map<Id, Account> mapOld, Map<Id, Account> mapNew){        
        List<Id> account = new List<Id>();
        
        for(Account acc : listNew){
            if((mapOld.get(acc.Id).ShippingStreet != mapNew.get(acc.Id).ShippingStreet)){
                account.add(acc.Id);
            }
        }
        
        // If no account's address has changed, just return
        if (account.size() == 0) return;
        
        List<Contact> childContacts = [Select Id, AccountId, MailingStreet, MailingCity, MailingState, MailingCountry, MailingPostalCode, OtherStreet, OtherCity, OtherCountry, OtherPostalCode, OtherState FROM Contact WHERE AccountId IN: account];
        
        Map<Id,Contact> contactMap = new Map<Id,Contact>([SELECT Id from Contact WHERE Id in:childContacts]);
        
        for(Account a: listNew){
            for(Contact child :childContacts){
                if(!contactMap.IsEmpty()){
                    if(mapNew.get(child.AccountId).ShippingStreet != mapOld.get(child.AccountId).ShippingStreet){
                        child.MailingStreet = a.ShippingStreet;
                        child.MailingCity = a.ShippingCity;
                        child.MailingState = a.ShippingState;
                        child.MailingPostalCode = a.ShippingPostalCode;
                        child.MailingCountry = a.ShippingCountry;
                        child.OtherStreet = a.ShippingStreet;
                        child.OtherCity = a.ShippingCity;
                        child.OtherState = a.ShippingState;
                        child.OtherPostalCode = a.ShippingPostalCode;
                        child.OtherCountry = a.ShippingCountry;
                        
                    }
                    
                }
            }
        }
        
        if(childContacts.size() > 0){
            update childContacts;
        }        
    }
    
    //Update Address on Contact if the Account has changed on the Contact
    public void populateAccountAddressNewAccount(List<Contact> listOld, List<Contact> listNew, Map<Id, Contact> mapOld, Map<Id, Contact> mapNew){
        
        List<Id> account = new List<Id>(); 
        
        for(Contact c : listNew){
            if(mapNew.get(c.Id).AccountId != mapOld.get(c.Id).AccountId){            
                If(c.AccountId != null){
                    account.add(c.AccountId);   
                }   
            }
        }
        List <Account> accountList = [Select ID, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry from Account where Id in :account];
        
        for (Integer i = 0; i <listNew.size(); i++){
            if (accountList.size() > 0 && listNew[i].AccountId !=null){
                for (Account a:accountList){
                    if (listNew[i].AccountId != listOld[i].AccountId){
                        listNew[i].MailingStreet = a.ShippingStreet;
                        listNew[i].MailingCity = a.ShippingCity;
                        listNew[i].MailingState = a.ShippingState;
                        listNew[i].MailingPostalCode = a.ShippingPostalCode;
                        listNew[i].MailingCountry = a.ShippingCountry;
                        listNew[i].OtherStreet = a.BillingStreet;
                        listNew[i].OtherCity = a.BillingCity;
                        listNew[i].OtherState = a.BillingState;
                        listNew[i].OtherPostalCode = a.BillingPostalCode;
                        listNew[i].OtherCountry = a.BillingCountry;
                    }
                }
            }
            
        }        
    }
    
    //Set the Account address on the newly created Cotact
    public void populateAccountAddressNewContact(List<Contact> listOld, List<Contact> listNew, Map<Id, Contact> mapOld, Map<Id, Contact> mapNew){
        
        List<Id> account = new List<Id>();
        
        for(Contact c : listNew){            
            If(c.AccountId != null){
                account.add(c.AccountId);   
            }            
        }
        
        List <Account> accountList = [SELECT ID, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry from Account where Id in :account];
        
        for(Integer i=0; i<listNew.size(); i++){
            if(accountList.size() > 0){
                for (Account a:accountList){                    
                    listNew[i].MailingStreet = a.ShippingStreet;
                    listNew[i].MailingCity = a.ShippingCity;
                    listNew[i].MailingState = a.ShippingState;
                    listNew[i].MailingPostalCode = a.ShippingPostalCode;
                    listNew[i].MailingCountry = a.ShippingCountry;
                    listNew[i].OtherStreet = a.BillingStreet;
                    listNew[i].OtherCity = a.BillingCity;
                    listNew[i].OtherState = a.BillingState;
                    listNew[i].OtherPostalCode = a.BillingPostalCode;
                    listNew[i].OtherCountry = a.BillingCountry;                    
                }
                
            }
        }
    }    
    
}
public with sharing class RMS_AccountTriggerHandler {
	// This should be used in conjunction with the ApexTriggerComprehensive.trigger template
  // The origin of this pattern is http://www.embracingthecloud.com/2010/07/08/ASimpleTriggerTemplateForSalesforce.aspx
  

  public RMS_AccountTriggerHandler(){

  }

/*
  public void OnBeforeInsert(Account[] newAccounts){
    setPriceBookId(newAccounts);
  }
*/

  public void OnAfterInsert(Account[] newAccounts){
    createSharingRecords(newAccounts);
  }
/*
  @future public static void OnAfterInsertAsync(Set<ID> newAccountIDs){
    //Example usage
    //List<Account> newAccounts = [select Id, Name from Account where Id IN :newAccountIDs];
  }

  public void OnBeforeUpdate(Map<ID, Account>  oldMap, Map<ID, Account> newMap){

  }
*/
  public void OnAfterUpdate(Map<ID, Account>  oldMap, Map<ID, Account> newMap){
    system.debug('AFTER UPDATE');
    createOrDeleteSharingRecordsHelper(oldMap, newMap);
  }

  /*  
  @future public static void OnAfterUpdateAsync(Set<ID> updatedAccountIDs){
    //List<Account> updatedAccounts = [select Id, Name from Account where Id IN :updatedAccountIDs];
  }

  public void OnBeforeDelete(Account[] AccountsToDelete, Map<ID, Account> AccountMap){

  }

  public void OnAfterDelete(Account[] deletedAccounts, Map<ID, Account> AccountMap){

  }

  @future public static void OnAfterDeleteAsync(Set<ID> deletedAccountIDs){

  }

  public void OnUndelete(Account[] restoredAccounts){

  }*/

  public void createOrDeleteSharingRecordsHelper(Map<Id, Account> oldMap, Map<Id, Account> newMap){
    //TODO: account for store location going from nonnull to null; Account for deleting the old share records
    List<Account> accountsToCreateSharingRecordsFor = new List<Account>();
    List<Account> accountsToDeleteSharingRecordsFor = new List<Account>();
  	for(Id aid: oldMap.keyset()){
      if(oldMap.get(aid).OwnerId != newMap.get(aid).OwnerId){
        accountsToCreateSharingRecordsFor.add(newMap.get(aid));
      }else if(oldMap.get(aid).Store_Location__c != newMap.get(aid).Store_Location__c){
        if(newMap.get(aid).Store_Location__c != null){
          accountsToCreateSharingRecordsFor.add(newMap.get(aid));
        }if(oldMap.get(aid).Store_Location__c != null){
          accountsToDeleteSharingRecordsFor.add(newMap.get(aid));
        }
      }
    }
    deleteSharingRecords(accountsToDeleteSharingRecordsFor);
    createSharingRecords(accountsToCreateSharingRecordsFor);

  }
  public void createSharingRecords(List<Account> accounts){
    //Possibly unnecessary
    accounts = [Select Id, Store_Location__c, Store_Location__r.Name from Account where Id in: accounts and Store_Location__c != null];
    if(!accounts.isEmpty() ){
      List<AccountShare> sharesToInsert = new List<AccountShare>();

      String userQuery = 'Select Id, Store_Locations__c from User where Store_Locations__c includes(';
      for(Account a : accounts){ 
          userQuery +='\''+a.Store_Location__r.Name+'\',';
      }
      userQuery = userQuery.removeEnd(',');
      userQuery += ')';

      System.debug(userQuery);
      //List<User> users = [Select Id, Store_Locations__c from User where Store_Locations__c includes(:accountNames)];
      List<User> users = Database.query(userQuery);
      for(Account a: accounts){
        for(User u : users){
          if(u.Store_Locations__c.containsIgnoreCase(a.Store_Location__r.Name)){
            sharesToInsert.add(new AccountShare(AccountId = a.Id, UserOrGroupId = u.Id, AccountAccessLevel = 'read',
                              OpportunityAccessLevel = 'read', CaseAccessLevel = 'read', rowCause = 'Manual'));
          }
        }
      }

      system.debug(sharesToInsert);
      insert sharesToInsert;
    }
  }

  public void deleteSharingRecords(List<Account> accounts){
      List<AccountShare> sharesToDelete = [Select Id, rowCause, AccountId, UserOrGroupId from AccountShare where AccountId in: accounts and rowCause = 'Manual'];
      delete sharesToDelete;
  }
  

}
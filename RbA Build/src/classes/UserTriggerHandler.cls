/*******************************************************//**

@class	  UserTriggerHandler

@brief	 Handler for the user trigger

@author	 Creston Kuenzi (Slalom.CDK)

@version	2016-5-25  Slalom.CDK
	Created

@see		UserTriggerHandlerTest

@copyright  (c)2016 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/

public with sharing class UserTriggerHandler {
  // This should be used in conjunction with the ApexTriggerComprehensive.trigger template
  // The origin of this pattern is http://www.embracingthecloud.com/2010/07/08/ASimpleTriggerTemplateForSalesforce.aspx
  private boolean m_isExecuting = false;
  private integer BatchSize = 0;

  public UserTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }

  
  public void OnBeforeInsert(User[] newUsers){
    updateStoreLocationText(newUsers);

  }

 
  
  public void OnAfterInsert(User[] newUsers){
      createSharingRecords(newUsers);
  }



  public void OnBeforeUpdate( Map<ID, User> oldMap, Map<ID, User> newMap){
    updateStoreLocationText(newMap);
  }
  
  
  public void OnAfterUpdate( Map<ID, User> oldMap, Map<ID, User> newMap){
    createOrDeleteSharingRecordsHelper(oldMap, newMap);
  }


/*
  public void OnBeforeDelete(User[] UsersToDelete, Map<ID, User> UsersMap){

  }

  public void OnAfterDelete(User[] deletedUsers, Map<ID, User> UsersMap){

  }


  public void OnUndelete(User[] restoredUsers){

  }*/

	// This method puts store location multi-picklist values in a text box so we can use them in field filters
	// Note Salesforce multi-picklists are limited and cannot be used in field filters, formula fields or workflow easily
	public void updateStoreLocationText(List<User> usersToUpdate){
		for(User u : usersToUpdate){
			
			// Limit the text to 255 characters to avoid too many chars error. We can't use a long text area
			// because this field is being used in the Labor->Store Location field filter
			// to limit which stores can be selected, and long text areas are not usable in filters.
			if (u.Store_Locations__c != null)
				u.Store_Location_Text__c = (u.Store_Locations__c).abbreviate(255);
			else
				u.Store_Location_Text__c = '';
		}
	}

	// This method receives a map of store locations and simply calls the method above
	public void updateStoreLocationText(Map<Id, User> userMap){
		List<User> usersToUpdate = userMap.values();
		updateStoreLocationText(usersToUpdate);
	}

  public void createOrDeleteSharingRecordsHelper(Map<Id, User> oldMap, Map<Id, User> newMap){

    //TODO: account for store location going from nonnull to null; Account for deleting the old share records
    List<User> usersToCreateSharingFor = new List<User>();
    List<User> usersToDeleteSharingRecordsFor = new List<User>();
    for(Id uid: oldMap.keyset()){
      if(oldMap.get(uid).Store_Locations__c != newMap.get(uid).Store_Locations__c){
        usersToDeleteSharingRecordsFor.add(newMap.get(uid));
        if(newMap.get(uid).Store_Locations__c != null){
          usersToCreateSharingFor.add(newMap.get(uid));       
        }
      }
    }
    deleteSharingRecords(usersToDeleteSharingRecordsFor);
    createSharingRecords(usersToCreateSharingFor);
    
  }

  public void createSharingRecords(List<User> users){
    //Possibly unnecessary
    users = [Select Id, Store_Location_Text__c, Store_Locations__c from User where Id in: users and Store_Locations__c != null];
    if(!users.isEmpty() ){
      Set<UserShare> sharesToInsert = new Set<UserShare>();

      String userQuery = 'Select Id, Store_Locations__c from User where Store_Locations__c includes(';
      Set<String> locations = new Set<String>();
      for(User u : users){ 
          List<String> loc = u.Store_Locations__c.split(';');
          locations.addAll(loc);
      }
      for(String s: locations){
            userQuery +='\''+s+'\',';
      }
      userQuery = userQuery.removeEnd(',');
      userQuery += ')';

      System.debug(userQuery);
      List<User> usersWithMatchingLoc = Database.query(userQuery);
      for(User u1: usersWithMatchingLoc){
        for(User u : users){
          if(u1.Id != u.Id){
            List<String> loc = u.Store_Locations__c.split(';');
            for(String l : loc){
              if(u1.Store_Locations__c.containsIgnoreCase(l)){
                sharesToInsert.add(new UserShare(UserId = u.Id, UserOrGroupId = u1.Id, UserAccessLevel = 'read',
                                rowCause = 'Manual'));
                sharesToInsert.add(new UserShare(UserId = u1.Id, UserOrGroupId = u.Id, UserAccessLevel = 'read',
                                rowCause = 'Manual'));
                break;
              }
            }
          }
        }
      }

      system.debug(sharesToInsert);
      insert new List<UserShare>(sharesToInsert);

    }
  }



  public void deleteSharingRecords(List<User> users){
      List<UserShare> sharesToDelete = [Select Id, rowCause, UserId, UserOrGroupId from UserShare where ( UserId in: users or UserOrGroupId in: users) and rowCause = 'Manual'];
      delete sharesToDelete;
  }
}
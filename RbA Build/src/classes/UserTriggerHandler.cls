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

 
  /*
  public void OnAfterInsert(User[] newUsers){
  }
*/


  public void OnBeforeUpdate( Map<ID, User> oldMap, Map<ID, User> newMap){
    updateStoreLocationText(newMap);
  }
  
  /*
  public void OnAfterUpdate( Map<ID, User> oldMap, Map<ID, User> newMap){

    updateOrderStatusToOrderReleased(oldMap, newMap);
    updateOrderStatusToInstallNeeded(oldMap, newMap);
    updateHasPOCheckbox(oldMap,newMap);

  }
*/

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
			u.Store_Location_Text__c = (u.Store_Locations__c).abbreviate(255);
		}
	}

	// This method receives a map of store locations and simply calls the method above
	public void updateStoreLocationText(Map<Id, User> userMap){
		List<User> usersToUpdate = userMap.values();
		updateStoreLocationText(usersToUpdate);
	}

}
/*******************************************************//**

@class	  LaborTriggerHandler

@brief	 Handler for the labor trigger

@author	 Creston Kuenzi (Slalom.CDK)

@version	2016-6-23  Slalom.CDK
	Created

@see		LaborTriggerHandlerTest

@copyright  (c)2016 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited.

***********************************************************/

public with sharing class LaborTriggerHandler {
  // This should be used in conjunction with the ApexTriggerComprehensive.trigger template
  // The origin of this pattern is http://www.embracingthecloud.com/2010/07/08/ASimpleTriggerTemplateForSalesforce.aspx
  private boolean m_isExecuting = false;
  private integer BatchSize = 0;

  public LaborTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;
  }

  
  public void OnBeforeInsert(Labor__c[] newLabor){
    updateHourlyRate(newLabor);

  }

 
  /*
  public void OnAfterInsert(User[] newUsers){
  }
*/

/*
  public void OnBeforeUpdate( Map<ID, User> oldMap, Map<ID, User> newMap){
  }
/*  
  /*
  public void OnAfterUpdate( Map<ID, User> oldMap, Map<ID, User> newMap){

  }
*/

/*
  public void OnBeforeDelete(User[] UsersToDelete, Map<ID, User> UsersMap){

  }

  public void OnAfterDelete(User[] deletedUsers, Map<ID, User> UsersMap){

  }


  public void OnUndelete(User[] restoredUsers){

  }*/

	// This method pulls the hourly rate from the store configuration and stores it
	// on the labor record. The standard hourly rate is a formula field
	public void updateHourlyRate(List<Labor__c> laborsToUpdate){
		for(Labor__c l : laborsToUpdate){
			System.Debug('**********hourlyrate=' +l.Standard_Hourly_Rate__c);
			l.Hourly_Rate__c = l.Standard_Hourly_Rate__c;
		}
	}


}
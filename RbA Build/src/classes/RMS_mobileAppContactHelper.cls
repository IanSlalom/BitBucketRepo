/*
 *@class  RMS_mobileAppContactHelper
 *@brief  Help class for handling api call business logic
 *@author  Kai Ruan
 *@version  2016-3/11 Class Created
 *@copyright  (c)2016 Slalom.  All Rights Reserved.  Unauthorized use is prohibited.
 */

public with sharing class RMS_mobileAppContactHelper {
	public RMS_mobileAppContactHelper() {
		
	}

	public static String saveNewContact(String inputJSON){
		DTOContact dtoContact = (DTOContact)JSON.deserialize(inputJSON, Type.forName('RMS_mobileAppContactHelper.DTOContact'));
		Contact contactToInsert = dtoContact.contact;
	
		// lets set a database save point
      	System.SavePoint sp = Database.setSavePoint();
      	try {
      		//Insert Contact
	        Database.SaveResult sr = Database.insert(contactToInsert, false);	 
	        if (!sr.isSuccess()) {
	            // add error messages 
	            // Operation failed, so get all errors               
	            for(Database.Error err : sr.getErrors()) {
	              dtoContact.getErrors().add(err.getStatusCode() + ': ' + err.getMessage() + ': Contact fields that affected this error: ' + err.getFields());
	            }
	        }else{
	        	dtoContact.contact.Id = contactToInsert.Id;
	        }
	        

	        //Insert Contact History
	        if(dtoContact.getErrors().isEmpty()){
	        	Contact_History__c contactHistoryToInsert = new Contact_History__c(Contact__c = contactToInsert.Id, Dwelling__c = dtoContact.accountId, Type__c ='Current Resident');
	        	sr = Database.insert(contactHistoryToInsert, false);
          		if (!sr.isSuccess()) {              
	            	for(Database.Error err : sr.getErrors()) {
	              		dtoContact.getErrors().add(err.getStatusCode() + ': ' + err.getMessage() + ': Contact History fields that affected this error: ' + err.getFields());
	            	}
	          	}
		        
	    	}

	        //Insert Opportunity Contact Role
	        if(dtoContact.getErrors().isEmpty()){
	        	OpportunityContactRole contactRoleToInsert = new OpportunityContactRole(ContactId= contactToInsert.Id, OpportunityId = dtoContact.OpportunityId, IsPrimary = false, Role ='Decision Maker');
	        	sr = Database.insert(contactRoleToInsert, false);
          		if (!sr.isSuccess()) {             
	            	for(Database.Error err : sr.getErrors()) {
	              		dtoContact.getErrors().add(err.getStatusCode() + ': ' + err.getMessage() + ': Opportunity Contact Role fields that affected this error: ' + err.getFields());
	            	}
	          	}		    
	    	}


     	} catch (Exception e) {
	        // we've got another error
	        // rollback the inserts if possible
	        Database.rollBack(sp);
	        dtoContact.getErrors().add('Unhandled exception : ' + e.getMessage() + ' : ' + e.getStackTraceString());
	        System.debug(LoggingLevel.ERROR, 'RMS_mobileAppContactHelper.saveNewContact: Unhandled exception : ' + e.getMessage() + ' : ' + e.getStackTraceString());
	    }
	    system.debug(dtoContact);
		return JSON.serialize(dtoContact);

	}

	public class DTOContact{
		public Id OpportunityId{get;set;}
		public Id AccountId{get;set;}
		public Contact contact{get;set;}
		private String[] errors;
    	public String[] getErrors() { 
      		if (errors == null) { 
        		errors = new String[]{};
      		} 
     	 	return errors;
    	}
	}
}
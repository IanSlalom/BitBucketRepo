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
		System.debug('###### RMS_mobileAppContactHelper.saveNewContact: Input: ' + inputJSON);
		DTOContact dtoContact = (DTOContact)JSON.deserialize(inputJSON, Type.forName('RMS_mobileAppContactHelper.DTOContact'));
		Contact contactToInsert = dtoContact.contact;
		// check for an accoutId to link the contact to
		if (dtoContact.DwellingId == null) {
       		dtoContact.getErrors().add('Required field missing: fields that affected this error: DwellingId');
		}
	
		// lets set a database save point
      	System.SavePoint sp = Database.setSavePoint();
      	try {
      		//Insert Contact
			contactToInsert.AccountId = dtoContact.DwellingId;
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
			// do we have errors if yes roll it all back
			if (!dtoContact.getErrors().isEmpty()) {
		        Database.rollBack(sp);
				dtoContact.isSaveSuccessful = false;
				//add the errors to the error facility
				// add logic to put data in the errors object
				dtoContact.Contact.Id = null;
			}

     	} catch (Exception e) {
	        // we've got another error
	        // rollback the inserts if possible
	        Database.rollBack(sp);
	        dtoContact.getErrors().add('Unhandled exception : ' + e.getMessage() + ' : ' + e.getStackTraceString());
			dtoContact.isSaveSuccessful = false;
	        System.debug(LoggingLevel.ERROR, 'RMS_mobileAppContactHelper.saveNewContact: Unhandled exception : ' + e.getMessage() + ' : ' + e.getStackTraceString());
	    }
		String result = JSON.serialize(dtoContact);
	    system.debug('###### RMS_mobileAppContactHelper.saveNewContact: Output: ' + result);
		return result;

	}

	public class DTOContact{
		public Id OpportunityId{get;set;}
		public Id DwellingId{get;set;}
		public Contact contact{get;set;}
		public Boolean isSaveSuccessful = true;
		private String[] errors;
    	public String[] getErrors() { 
      		if (errors == null) { 
        		errors = new String[]{};
      		} 
     	 	return errors;
    	}
	}
}
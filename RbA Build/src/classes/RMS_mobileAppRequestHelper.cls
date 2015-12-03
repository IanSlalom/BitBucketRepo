/*
 *@class	RMS_mobileAppRequestHelper
 *@brief	Help class for handling api call business logic
 *@author  Anthony Strafaccia (Slalom.ADS)
 *@author  Mark Wochnick (Slalom.MAW)
 *@version	2015-09/16  Slalom.ADS	Created.
 *@version	2015-10/12  Slalom.MAW
 *@copyright  (c)2015 Slalom.  All Rights Reserved.	Unauthorized use is prohibited.
 */

public with sharing class RMS_mobileAppRequestHelper {

	public String findAppointments(String UserId){
		List<Event> eventsOwned = [SELECT Id, StartDateTime, EndDateTime, Subject, WhoId, WhatId FROM Event Where OwnerId =: UserId];
		if(eventsOwned.size() > 0){
			List<SalesAppointmentWrapper> appointmentWrapperList = new List<SalesAppointmentWrapper>();
			List<id> accountIdList = new List<id>();
			List<id> opportunityIdList = new List<id>();
			for(Event e : eventsOwned){
				opportunityIdList.add(e.whatId);
			}

			// we need to be able to distinguish types of appointments for users who have multiple roles.
			// the whatId object will changes based on the event type			
			List<Opportunity> relatedOpportunities = [SELECT Id, Name, StageName, AccountId, isClosed FROM Opportunity WHERE Id IN :opportunityIdList];
			for(Opportunity o : relatedOpportunities){
				accountIdList.add(o.AccountId);
			}
			// get the contacts
			List<OpportunityContactRole> relatedOppContacts = [select Id, contactId, isPrimary, opportunityId, Role, 
				Contact.Id, Contact.FirstName, Contact.LastName, Contact.Email, Contact.HomePhone, 
				Contact.MobilePhone, Contact.OtherPhone, Contact.Phone, Contact.Salutation
				from OpportunityContactRole where isDeleted = false and opportunityId in :opportunityIdList order by opportunityId];

			List<Account> relatedAccounts = [SELECT Id, Name, Dwelling_Style__c, Shipping_County__c, ShippingCity, ShippingCountryCode, ShippingLatitude, ShippingLongitude, ShippingPostalCode, ShippingStateCode, ShippingStreet, Year_Built__c FROM Account WHERE Id IN :accountIdList and isDeleted = false];

			Map<id,Opportunity> opportunityIdToOpportunityMap = new Map<id, Opportunity>();
			Map<id,Account> accountIdToAccountMap = new Map<id, Account>();
			Map<id,list<Contact>> opportunityIdtoContactListMap = new Map<id, list<Contact>>();
			
			for(Opportunity o : relatedOpportunities){
				opportunityIdToOpportunityMap.put(o.id, o);
			}
			for(Account a : relatedAccounts){
				accountIdToAccountMap.put(a.id, a);
			}

			for(OpportunityContactRole ocr : relatedOppContacts){
				Contact c = new Contact(Id=ocr.Contact.Id, FirstName = ocr.Contact.FirstName, LastName = ocr.Contact.LastName, Email = ocr.Contact.Email, HomePhone = ocr.Contact.HomePhone, 
				MobilePhone = ocr.Contact.MobilePhone, OtherPhone = ocr.Contact.OtherPhone, Phone = ocr.Contact.Phone, Salutation = ocr.Contact.Salutation);
				if(opportunityIdtoContactListMap.containsKey(ocr.opportunityId)){
					opportunityIdtoContactListMap.get(ocr.opportunityId).add(c);
				}else{
					opportunityIdtoContactListMap.put(ocr.opportunityId, new list<Contact>{c});
				}
			}
					
			
			for(Event e : eventsOwned){
				Opportunity opp = opportunityIdToOpportunityMap.get(e.WhatId);
				Account account = accountIdToAccountMap.get(opp.AccountId);
				List<Contact> activeContacts = opportunityIdtoContactListMap.get(e.WhatId);
				
				SalesAppointmentWrapper aw = new SalesAppointmentWrapper(e, opp, account, activeContacts);
				appointmentWrapperList.add(aw);
			}	
			return JSON.serialize(appointmentWrapperList);
			
		}else{
			return JSON.serialize('No appointments found');
		}
	}
		
    public String updateOpportunity(String OppId, String Status){
    	List<Opportunity> opp = [SELECT Id, Name, AccountId FROM Opportunity WHERE Id = :OppId];
    	if(opp.size() == 0){
    		return 'No Opportunity found with that Id';
    	}else{
    		//map<String, RMS_Queue_Settings__c> RMS_Queue_Settings_map = RMS_Queue_Settings__c.getAll(); 
    		//RMS_Queue_Settings__c queueSetting = RMS_Queue_Settings_map.get(opp[0].AccountId);
			
			////////THIS IS BEING USED FOR DEMO UNTIL ACCOUNT IS POPULATED INSIDE THE ORDER///////////
	    	Account testAccount = [SELECT id FROM Account Where Name = '77 - Twin Cities, MN'];
	    	//////////////////////////////////////////////////////////////////////////////////////////
	    	
    		list<Store_Configuration__c> storeConfig = [SELECT 	Id, 
    															Store__c, 
    															Install_Work_Order_Queue_Id__c, 
    															Tech_Measure_Work_Order_Queue_Id__c, 
    															Order_Queue_Id__c
    															FROM Store_Configuration__c
    															WHERE Store__r.id =: testAccount.id];
    															//WHERE Store__r.id =: opp[0].AccountId];
    		
    		//ORDER related to the Opp
    		Order ord = new Order(
    			AccountId = opp[0].AccountId,
    			OwnerId = storeConfig[0].Order_Queue_Id__c,
    			Status = 'Draft',
    			EffectiveDate = Date.today(),
    			Opportunity = opp 
    		);
    		insert ord;
    		//Unable to create order with Activated status
    		
    		//Create products on order here
    		
    		//ord.Status = 'Activated';
    		//update ord;
    		
    		
    		RecordType serviceOrderScheduleRecordType = [SELECT id FROM RecordType WHERE SobjectType = 'SVMXC__Service_Order__c' AND Name = 'Schedule'];
    		//CREATE WORK ORDER (TECH MEASURE)
    		SVMXC__Service_Order__c techWO = new SVMXC__Service_Order__c(
    			Sold_Order__c = ord.id,
    			RecordType = serviceOrderScheduleRecordType,
    			SVMXC__Order_Type__c = 'Tech Measure',
    			OwnerId = storeConfig[0].Tech_Measure_Work_Order_Queue_Id__c
    		);
    		 	
    		 	system.debug('ads storeConfig[0].Tech_Measure_Work_Order_Queue_Id__c: '+storeConfig[0].Tech_Measure_Work_Order_Queue_Id__c);
    		 	list<QueueSobject> x = [SELECT id, sobjectType, QueueId  FROM QueueSobject WHERE QueueId =: storeConfig[0].Tech_Measure_Work_Order_Queue_Id__c];
				system.debug('ads checking queue type');
				system.debug('ads: '+ x[0].sobjectType);
    		
    		
    		insert techWO;
    		
    		
    		//CREATE WORK ORDER (INSTALL)
    		SVMXC__Service_Order__c installWO = new SVMXC__Service_Order__c(
    			Sold_Order__c = ord.id, 
    			RecordType =  serviceOrderScheduleRecordType,
    			SVMXC__Order_Type__c = 'Install',
    			OwnerId = storeConfig[0].Install_Work_Order_Queue_Id__c
    		);
    		insert installWO;
			
			return 'Created Order, Install Work Order and Tech Measure Work Order';
    	}
    }

	public class SalesAppointmentWrapper{
		public Event event {get; set;}
   		public Opportunity opportunity {get; set;}
   		public Account account {get; set;}
        public List<Contact> contactList {get; set;}
   		
        public SalesAppointmentWrapper(Event e, Opportunity o, Account a, List<Contact> cl ) {
            event = e;
            opportunity = o;
            account = a;
            contactList = cl;
        }                            
    }
    

}
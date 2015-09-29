public with sharing class RMS_priceCalcSlimAPILogic {

	public String findAppointments(String UserId){
		
		list<Event> eventsOwned = [SELECT Id, WhatId FROM Event Where OwnerId =: UserId];
		if(eventsOwned.size() > 0){
			

			list<appointmentWrapper> appointmentWrapperList = new list<appointmentWrapper>();
			
			List<id> accountIdList = new List<id>();
			List<id> opportunityIdList = new List<id>();
			List<id> contactIdList = New List<id>();
			for(Event e : eventsOwned){
				opportunityIdList.add(e.whatId);
			}
			
			List<Opportunity> relatedOpportunities = [SELECT Id, Name, AccountId FROM Opportunity WHERE Id IN :opportunityIdList];
			
			for(Opportunity o : relatedOpportunities){
				accountIdList.add(o.AccountId);
			}
						
			List<Account> relatedAccounts = [SELECT Id, Name FROM Account WHERE Id IN :accountIdList];
			List<Contact> relatedContacts = [SELECT Id, Name, AccountId FROM Contact WHERE AccountId IN: accountIdList];
			
			Map<id,Opportunity> opportunityIdToOpportunityMap = new Map<id, Opportunity>();
			Map<id,Account> accountIdToAccountMap = new Map<id, Account>();
			Map<id,list<Contact>> accountIdtoContactListMap = new Map<id, list<Contact>>();
			
			for(Opportunity o : relatedOpportunities){
				opportunityIdToOpportunityMap.put(o.id, o);
			}
			for(Account a : relatedAccounts){
				accountIdToAccountMap.put(a.id, a);
			}
			for(Contact c : relatedContacts){
				if(accountIdtoContactListMap.containsKey(c.AccountId)){
					accountIdtoContactListMap.get(c.AccountId).add(c);
				}else{
					accountIdtoContactListMap.put(c.AccountId, new list<Contact>{c});
				}
			}
					
			
			for(Event e : eventsOwned){
				Opportunity opp = opportunityIdToOpportunityMap.get(e.WhatId);
				Account account = accountIdToAccountMap.get(opp.AccountId);
				List<Contact> activeContacts = accountIdtoContactListMap.get(account.id);
				
				AppointmentWrapper aw = new AppointmentWrapper(e, opp, account, activeContacts);
				appointmentWrapperList.add(aw);
			}	
			
			
			return JSON.serializePretty(appointmentWrapperList);
			
		}else{
			return 'No appointments found';
		}

	}
		
	public class AppointmentWrapper{
		public Event event {get; set;}
   		public Opportunity opportunity {get; set;}
   		public Account account {get; set;}
        public List<Contact> contactList {get; set;}
   		
   		
        public AppointmentWrapper(Event e, Opportunity o, Account a, List<Contact> cl ) {
            event = e;
            opportunity = o;
            account = a;
            contactList = cl;
        }                            
    }
    
    
    
    public String updateOpportunity(String OppId, String Status){
    	List<Opportunity> opp = [SELECT Id, Name, AccountId FROM Opportunity WHERE Id = :OppId];
    	if(opp.size() == 0){
    		return 'No Opportunity found with that Id';
    	}else{
    		map<String, RMS_Queue_Settings__c> RMS_Queue_Settings_map = RMS_Queue_Settings__c.getAll(); 
    		RMS_Queue_Settings__c queueSetting = RMS_Queue_Settings_map.get(opp[0].AccountId);
    		
    		//ORDER related to the Opp
    		Order ord = new Order(
    			AccountId = opp[0].AccountId,
    			OwnerId = queueSetting.Order_Queue_Id__c,
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
    			OwnerId = queueSetting.Tech_Measure_Work_Order_Queue_Id__c
    		);
    		 	
    		 	system.debug('ads queueSetting.Tech_Measure_Work_Order_Queue_Id__c: '+queueSetting.Tech_Measure_Work_Order_Queue_Id__c);
    		 	list<QueueSobject> x = [SELECT id, sobjectType, QueueId  FROM QueueSobject WHERE QueueId =: queueSetting.Tech_Measure_Work_Order_Queue_Id__c];
				system.debug('ads checking queue type');
				system.debug('ads: '+ x[0].sobjectType);
    		
    		
    		insert techWO;
    		
    		
    		//CREATE WORK ORDER (INSTALL)
    		SVMXC__Service_Order__c installWO = new SVMXC__Service_Order__c(
    			Sold_Order__c = ord.id, 
    			RecordType =  serviceOrderScheduleRecordType,
    			SVMXC__Order_Type__c = 'Install',
    			OwnerId = queueSetting.Install_Work_Order_Queue_Id__c
    		);
    		insert installWO;
			
			return 'Created Order, Install Work Order and Tech Measure Work Order';
    	}
    }
	
	
}
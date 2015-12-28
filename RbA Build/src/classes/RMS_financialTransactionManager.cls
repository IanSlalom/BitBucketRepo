/*******************************************************//**

@class	RMS_financialTransactionManager

@brief	Controller to handle finacial transation recording

@author  Anthony Strafaccia (Slalom.ADS)

@version	2015-12/24  Slalom.ADS
	Created.

@see		RMS_financialTransactionManagerTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
			Unauthorized use is prohibited. 

***********************************************************/

public with sharing class RMS_financialTransactionManager {


	public void onBeforeInsert(list<Payment__c> listNew){
		map<Id, list<Journal_Entry__c>> paymentIdToJournalEntryMap = linkJournalEntries(listNew);
		
		for(Payment__c p : listNew){
			//if(p.Deposit);
		}
		
	}
	
	public void onBeforeInsert(list<Payment__c> listOld, list<Payment__c> listNew, map<Id, Payment__c> mapOld, map<Id, Payment__c> mapNew){
	
	}
	
	
	
	
	public map<id, list<Journal_Entry__c>> linkJournalEntries(list<Payment__c> paymentList){
		list<id> paymentIdList = new list<id>();
		for(Payment__c p : paymentList){
			paymentIdList.add(p.id);
		}
		list<Journal_Entry__c> relatedJournalEntries = [SELECT id, Payment__c FROM Journal_Entry__c WHERE Payment__c IN :paymentIdList];
		map<Id, list<Journal_Entry__c>> paymentIdToJournalEntryMap = new map<Id, list<Journal_Entry__c>>();
		for(Journal_Entry__c je : relatedJournalEntries){
			if(paymentIdToJournalEntryMap.containsKey(je.Payment__r.id) ){
				paymentIdToJournalEntryMap.get(je.Payment__c).add(je);
			}
			else{
				paymentIdToJournalEntryMap.put(je.Payment__c, new list<Journal_Entry__c>{je});
			}
		}
		return paymentIdToJournalEntryMap;
	}
	
	
	
	
	
	
	
	
	
	
	
	
}
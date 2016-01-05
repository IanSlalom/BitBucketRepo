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

 
	public void onAfterInsert(list<Payment__c> listNew, map<id,Payment__c> mapNew){
		//CHECK FOR DEPOSIT TYPE
		createOrUpdateJournalEntry(listNew, mapNew);
	}

	public void onAfterUpdate(list<Payment__c> listOld, list<Payment__c> listNew, map<Id, Payment__c> mapOld, map<Id, Payment__c> mapNew){
		//CHECK FOR DEPOSIT TYPE
		createOrUpdateJournalEntry(listNew, mapNew);
	}
	
	public void onBeforeDelete(list<Payment__c> listOld, map<Id, Payment__c> mapOld){
		allowDeleteOrNot(listOld, mapOld);
	}

	public void allowDeleteOrNot(list<Payment__c> listOld, map<id,Payment__c> mapOld ){
		list<Journal_Entry__c> journalEntriesToDelete= new list<Journal_Entry__c>();
		map<Id, list<Journal_Entry__c>> paymentIdToJournalEntryMap = linkJournalEntries(listOld);
		map<Id, list<Financial_Transaction__c>>  paymentIdToDepositFinacialTransactionList = linkFinacialTransactions(listOld, 'Deposit');
		String errorMessage;
		
		for(Payment__c p : listOld){
			if(paymentIdToJournalEntryMap.get(p.id) == null || paymentIdToJournalEntryMap.get(p.id).size() == 0){
				continue;
			}else if(paymentIdToJournalEntryMap.get(p.id).size() > 1){
				errorMessage = RMS_errorMessages.MULTIPLE_JOURNAL_ENTRIES;
				p.addError(errorMessage, FALSE);
			}else if(paymentIdToJournalEntryMap.get(p.id).size() == 1){
				if(paymentIdToJournalEntryMap.get(p.id)[0].Sent_to_BaanERP__c == false){
					journalEntriesToDelete.add(paymentIdToJournalEntryMap.get(p.id)[0]);
				}else{
					errorMessage = RMS_errorMessages.PAYMENT_ALREADY_SUBMITTED_DELETE;
					p.addError(errorMessage, FALSE);
				}
			}
		}
		system.debug('ads journalEntriesToDelete: '+journalEntriesToDelete);
		delete journalEntriesToDelete;
	}
	
	public void createOrUpdateJournalEntry(list<Payment__c> listNew, map<id,Payment__c> mapNew ){	
		list<Journal_Entry__c> journalEntriesToUpsert = new list<Journal_Entry__c>();
		list<Payment__c> extraFieldsList = [SELECT 	id,
													Order__c,
													Order__r.BillToContactId,
													Payment_Amount__c,
													Payment_Type__c,
													Order__r.Store_Location2__c,
													RecordTypeId,
													Store_Location__c
													FROM Payment__c WHERE Id IN :mapNew.keyset()];		
		
		map<Id, list<Journal_Entry__c>> paymentIdToJournalEntryMap = linkJournalEntries(extraFieldsList);
		map<Id, list<Financial_Transaction__c>>  paymentIdToDepositFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Deposit');
		
		Id paymentDespositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		
		for(Payment__c p : extraFieldsList){
			if(p.RecordTypeId == paymentDespositRecordTypeId && p.Payment_Type__c == 'Deposit'){
				string errorMessage;
				if(p.Store_Location__c == null ){ 
					errorMessage = RMS_errorMessages.STORE_LOCATION_IS_BLANK;
				}
				if(paymentIdToJournalEntryMap.get(p.id) == null || paymentIdToJournalEntryMap.get(p.id).size() == 0 ){
					
					errorMessage = checkFinacialTransationForErrors(paymentIdToDepositFinacialTransactionList.get(p.id) , errorMessage, p.Payment_Type__c);
					errorMessage = checkPaymentForErrors(p, errorMessage);
					 system.debug('ads p: '+p);
					 system.debug('ads p.Order__r.BillToContactId,: '+p.Order__r.BillToContactId);
					 
					if(errorMessage == null || errorMessage == ''){
						Journal_Entry__c newJE = new Journal_Entry__c(
						Date__c = Datetime.Now(),
						Type__c = 'Deposit',
						Payment__c = p.id,
						Order__c = p.Order__c,
						Amount__c = p.Payment_Amount__c,
						Customer__c = p.Order__r.BillToContactId, 
						
						Credit_General_Ledger_Account__c = paymentIdToDepositFinacialTransactionList.get(p.id)[0].Credit_Account_Number__r.Name,
						Debit_General_Ledger_Account__c = paymentIdToDepositFinacialTransactionList.get(p.id)[0].Debit_Account_Number__r.Name
						);
						journalEntriesToUpsert.add(newJE);
					}else{
						//there is an error message
						mapNew.get(p.id).addError(errorMessage, FALSE);
					}
				}else{
					//there is a related journal entry
					if(paymentIdToJournalEntryMap.get(p.id).size() == 1){
						Journal_Entry__c je = paymentIdToJournalEntryMap.get(p.id)[0];
						if(je.Sent_to_BaanERP__c == true){
							//Journal Entry already sent to BaanERP, throw error
							//String 
							errorMessage = RMS_errorMessages.PAYMENT_ALREADY_SUBMITTED;
							mapNew.get(p.id).addError(errorMessage, FALSE);
						}else{
							//Journal Entry NOT sent to BaanERP, update Journal Entry
							system.debug('ads inside not sent to Baan: '+ je);
							je.Date__c = Datetime.Now();
							je.Type__c = 'Deposit';
							je.Payment__c = p.id;
							je.Order__c = p.Order__c;
							je.Amount__c = p.Payment_Amount__c;
							je.Customer__c = p.Order__r.BillToContactId;
							je.Credit_General_Ledger_Account__c = paymentIdToDepositFinacialTransactionList.get(p.id)[0].Credit_Account_Number__c;
							je.Debit_General_Ledger_Account__c = paymentIdToDepositFinacialTransactionList.get(p.id)[0].Debit_Account_Number__c;
							journalEntriesToUpsert.add(je);
						}
						
					}//end if only one journal entery
				}//end of if there is related journal entery
					
			}//END IF DEPOSIT
		}//END OF PAYMENT FOR LOOP
		system.debug('ads journalEntriesToUpsert: '+journalEntriesToUpsert);
		upsert journalEntriesToUpsert;
	}//END onAfterInsert Method
	
	
	/***************************************************
	 Method to link paymentId to a list of Journal_Entry__c
	****************************************************/
	public map<id, list<Journal_Entry__c>> linkJournalEntries(list<Payment__c> paymentList){
		list<id> paymentIdList = new list<id>();
		for(Payment__c p : paymentList){
			paymentIdList.add(p.id);
		}
		list<Journal_Entry__c> relatedJournalEntries = [SELECT 	id, 
																Payment__c,
																Sent_to_BaanERP__c
																FROM Journal_Entry__c WHERE Payment__c IN :paymentIdList];
		map<Id, list<Journal_Entry__c>> paymentIdToJournalEntryMap = new map<Id, list<Journal_Entry__c>>();
		for(Journal_Entry__c je : relatedJournalEntries){
			if(paymentIdToJournalEntryMap.containsKey(je.Payment__c) ){
				paymentIdToJournalEntryMap.get(je.Payment__c).add(je);
			}
			else{
				paymentIdToJournalEntryMap.put(je.Payment__c, new list<Journal_Entry__c>{je});
			}
		}
		return paymentIdToJournalEntryMap;
	}
	
	
	
	
	/***************************************************
	 Method to link paymentId to a list of Financial_Transaction__c
	 of a specific type.
	****************************************************/
	public map<id, list<Financial_Transaction__c>>  linkFinacialTransactions(List<Payment__c> paymentList, String typeToGet){
		list<id> paymentIdList = new list<id>();
		list<id> storeListId = new list<id>();
		for(Payment__c p : paymentList){
			paymentIdList.add(p.id);
			//TODOO pull store from payment if isn't throw error
			storeListId.add(p.Store_Location__c);
		}
		
		list<Financial_Transaction__c> relatedFinancialTransactions = [SELECT 	id, 
																				Store_Configuration__c, 
																				Store_Configuration__r.Store__c,
																				Credit_Account_Number__c,
																				Credit_Account_Number__r.Name,
																				Debit_Account_Number__c,
																				Debit_Account_Number__r.Name
																			FROM Financial_Transaction__c 
											 								WHERE Store_Configuration__r.Store__c IN :storeListId
																			AND Transaction_Type__c = :typeToGet
																			];
		
		map<id, list<Financial_Transaction__c>> storeIdToListFinancialTransaction = new map<id, list<Financial_Transaction__c>>();
		for(Financial_Transaction__c ft : relatedFinancialTransactions){
			if(storeIdToListFinancialTransaction.containsKey(ft.Store_Configuration__r.Store__c) ){
				storeIdToListFinancialTransaction.get(ft.Store_Configuration__r.Store__c).add(ft);
			}else{
				storeIdToListFinancialTransaction.put(ft.Store_Configuration__r.Store__c, new list<Financial_Transaction__c>{ft});
			}
		}
		
		map<id, list<Financial_Transaction__c>> paymentIdToListFinancialTransaction = new map<id, list<Financial_Transaction__c>>();
		for(Payment__c p : paymentList){
			paymentIdToListFinancialTransaction.put(p.id, storeIdToListFinancialTransaction.get(p.Store_Location__c));
		}
		system.debug('ads paymentIdToListFinancialTransaction: '+paymentIdToListFinancialTransaction);
		return paymentIdToListFinancialTransaction;
	}
	
	
	/***************************************************
	 Method to run error checks against the Finacial Transaction Object
	****************************************************/
	public String checkFinacialTransationForErrors(list<Financial_Transaction__c> ftList, string errorMessage, string paymentType){

		String dynamicErrorMessage;
		
		//CHECK IF MORE THEN ONE FINACIAL TRANSACTION RECORDS
		if(ftList != null && ftList.size() > 1 ){
			dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.EXTRA_FINACIAL_TRANSACTION_RECORDS, '[Transaction Type]', paymentType);
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		//CHECK IF NO FINACIAL TRANSACTION RECORDS
		}else if(ftList == null || ftList.size() == 0 ){
			dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.NO_FINACIAL_TRANSACTION_RECORDS, '[Transaction Type]', paymentType);
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}else{
			//CHECK IF CREDIT ACCOUNT NUMBER IS NULL
			if(ftList[0].Credit_Account_Number__c == null){
				dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.FINACIAL_TRANSACTION_RECORDS_NO_CREDIT_ACCOUNT_NUMBER, '[Transaction Type]', paymentType);
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
			//CHECK IF DEBIT ACCOUNT NUMBER IS NULL
			if(ftList[0].Debit_Account_Number__c == null){
				dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.FINACIAL_TRANSACTION_RECORDS_NO_DEBIT_ACCOUNT_NUMBER, '[Transaction Type]', paymentType);
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
		}
		return errorMessage;		 
	}
	

	/***************************************************
	 Method to run error checks against the Payment Object
	****************************************************/
	public String checkPaymentForErrors(Payment__c payment, string errorMessage){
		String dynamicErrorMessage;
		if(payment.id == null){
			dynamicErrorMessage = RMS_errorMessages.PAYMENT_ID_IS_NULL;
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}
		if(payment.Order__c == null){
			dynamicErrorMessage = RMS_errorMessages.ORDER_IS_NULL;
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}
		if(payment.Payment_Amount__c == null){
			dynamicErrorMessage = RMS_errorMessages.PAYMENT_AMOUNT_IS_NULL;
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}
		if(payment.Order__r.BillToContactId == null){
			dynamicErrorMessage = RMS_errorMessages.CONTACT_IS_NULL;
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}
		return errorMessage;		
	}
	
	/***************************************************
	 Method to dynamicly change error messages
	****************************************************/
  	public static string fillInErrorRuleValues(String errorMessage, String targetValue, String replacementValue){
		errorMessage = errorMessage.replace(targetValue, '<b>('+replacementValue+')</b>');
		errorMessage = errorMessage.replace('null', '');
		
		return errorMessage;
	} 
	
}
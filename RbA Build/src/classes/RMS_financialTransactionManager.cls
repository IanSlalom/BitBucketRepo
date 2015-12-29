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
		map<Id, list<Journal_Entry__c>> paymentIdToJournalEntryMap = linkJournalEntries(listNew);
		map<id, list<Financial_Transaction__c>>  paymentIdToDepositFinacialTransactionList = linkFinacialTransactions(listNew, 'Deposit');
		
		for(Payment__c p : listNew){
			if(p.Payment_Type__c == 'Deposit'){
				if(paymentIdToJournalEntryMap.get(p.id) == null || paymentIdToJournalEntryMap.get(p.id).size() == 0 ){
					string errorMessage;
					
					errorMessage = checkFinacialTransationForErrors(paymentIdToDepositFinacialTransactionList.get(p.id) , errorMessage);
					errorMessage = checkPaymentForErrors(p, errorMessage);
					 
					if(errorMessage == null || errorMessage == ''){
						Journal_Entry__c newJE = new Journal_Entry__c(
						Date__c = Datetime.Now(),
						Type__c = 'Deposit',
						Payment__c = p.id,
						Order__c = p.Order__c,
						Amount__c = p.Payment_Amount__c,
						Customer__c = p.Order__r.BillToContactId,
						
						Credit_General_Ledger_Account__c = paymentIdToDepositFinacialTransactionList.get(p.id)[0].Credit_Account_Number__c,
						Debit_General_Ledger_Account__c = paymentIdToDepositFinacialTransactionList.get(p.id)[0].Debit_Account_Number__c
						);
						
					}else{
						p.addError(errorMessage);
					}
				}
				
				
				/*
				If the Payment Id, 
				Order, 
				Amount, 
				Customer Id, 
				Credit Ledger Account Number, or 
				Debit Ledger Account Number 
				
				cannot be found or is blank throw an error and do not allow the Payment record to be created. 
				*/
				
				
			}
		}
		
	}
	
	public void onBeforeInsert(list<Payment__c> listOld, list<Payment__c> listNew, map<Id, Payment__c> mapOld, map<Id, Payment__c> mapNew){
	
	}
	
	
	
	/***************************************************
	 Method to link paymentId to a list of Journal_Entry__c
	****************************************************/
	public map<id, list<Journal_Entry__c>> linkJournalEntries(list<Payment__c> paymentList){
		list<id> paymentIdList = new list<id>();
		for(Payment__c p : paymentList){
			paymentIdList.add(p.id);
		}
		list<Journal_Entry__c> relatedJournalEntries = [SELECT id, Payment__c FROM Journal_Entry__c WHERE Payment__c IN :paymentIdList];
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
			storeListId.add(p.Order__r.Store_Location2__c);
		}
		
		list<Financial_Transaction__c> relatedFinancialTransactions = [SELECT 	id, 
																				Store_Configuration__c, 
																				Store_Configuration__r.Store__c 
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
			paymentIdToListFinancialTransaction.put(p.id, storeIdToListFinancialTransaction.get(p.Order__r.Store_Location2__c));
		}
		return paymentIdToListFinancialTransaction;
	}
	
	
	/***************************************************
	 Method to run error checks against the Finacial Transaction Object
	****************************************************/
	public String checkFinacialTransationForErrors(list<Financial_Transaction__c> ftList, string errorMessage){

		String dynamicErrorMessage;
		
		//CHECK IF MORE THEN ONE FINACIAL TRANSACTION RECORDS
		if(ftList != null && ftList.size() > 1 ){
			dynamicErrorMessage = RMS_errorMessages.EXTRA_FINACIAL_TRANSACTION_RECORDS;
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		//CHECK IF NO FINACIAL TRANSACTION RECORDS
		}else if(ftList == null || ftList.size() == 0 ){
			dynamicErrorMessage = RMS_errorMessages.NO_FINACIAL_TRANSACTION_RECORDS;
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}else{
			//CHECK IF CREDIT ACCOUNT NUMBER IS NULL
			if(ftList[0].Credit_Account_Number__c == null){
				dynamicErrorMessage = RMS_errorMessages.FINACIAL_TRANSACTION_RECORDS_NO_CREDIT_ACCOUNT_NUMBER;
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
			//CHECK IF DEBIT ACCOUNT NUMBER IS NULL
			if(ftList[0].Debit_Account_Number__c == null){
				dynamicErrorMessage = RMS_errorMessages.FINACIAL_TRANSACTION_RECORDS_NO_DEBIT_ACCOUNT_NUMBER;
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
	
	
	
	
	
	
	
}
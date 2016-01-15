/**********************************************************

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

 	//PAYMENT
	public void onAfterInsert(list<Payment__c> listNew, map<id,Payment__c> mapNew){
		createOrUpdateJournalEntry(listNew, mapNew);
		//TODO:This locking functionality will eventually get moved to a batch process
		lockPaymentRecords(listNew);
	}

	public void onAfterUpdate(list<Payment__c> listOld, list<Payment__c> listNew, map<Id, Payment__c> mapOld, map<Id, Payment__c> mapNew){
		createOrUpdateJournalEntry(listNew, mapNew);
		lockPaymentRecords(listOld, mapNew);
	}
	
	public void onBeforeDelete(list<Payment__c> listOld, map<Id, Payment__c> mapOld){
		allowDeleteOrNot(listOld, mapOld);
	}
	
	
	//LABOR
	public void onAfterInsertLabor(list<Labor__c> listNew, map<id,Labor__c> mapNew){
		createOrUpdateJournalEntryLabor(listNew, mapNew);
	}

	public void onAfterUpdateLabor(list<Labor__c> listOld, list<Labor__c> listNew, map<Id, Labor__c> mapOld, map<Id, Labor__c> mapNew){
		createOrUpdateJournalEntryLabor(listNew, mapNew);
	}
	
	public void onBeforeDeleteLabor(list<Labor__c> listOld, map<Id, Labor__c> mapOld){
		allowDeleteOrNot(listOld, mapOld);
	}
	
	/***************************************************
	 Method to check if payment records can be deleted
	****************************************************/
	public void allowDeleteOrNot(list<SObject> listOld, map<id,SObject> mapOld ){
		list<Journal_Entry__c> journalEntriesToDelete= new list<Journal_Entry__c>();
		map<Id, list<Journal_Entry__c>> paymentIdToJournalEntryMap = linkJournalEntries(listOld);

		String errorMessage;
		
		for(SObject o : listOld){
			if(paymentIdToJournalEntryMap.get(o.id) == null || paymentIdToJournalEntryMap.get(o.id).size() == 0){
				continue;
			}else if(paymentIdToJournalEntryMap.get(o.id).size() > 1){
				errorMessage = RMS_errorMessages.MULTIPLE_JOURNAL_ENTRIES;
				o.addError(errorMessage, FALSE);
			}else if(paymentIdToJournalEntryMap.get(o.id).size() == 1){
				if(paymentIdToJournalEntryMap.get(o.id)[0].Sent_to_BaanERP__c == false){
					journalEntriesToDelete.add(paymentIdToJournalEntryMap.get(o.id)[0]);
				}else{
					
					errorMessage = RMS_errorMessages.ALREADY_SUBMITTED_DELETE;
					o.addError(errorMessage, FALSE);
				}
			}
		}
		system.debug('ads journalEntriesToDelete: '+journalEntriesToDelete);
		delete journalEntriesToDelete;
	}
	
	
	/***************************************************
	 Method to create or update Journal Entry
	****************************************************/
	public void createOrUpdateJournalEntry(list<Payment__c> listNew, map<id,Payment__c> mapNew ){	
		list<Journal_Entry__c> journalEntriesToUpsert = new list<Journal_Entry__c>();
		list<Payment__c> extraFieldsList = [SELECT 	id,
													Order__c,
													Order__r.BillToContactId,
													Payment_Amount__c,
													Payment_Type__c,
													Order__r.Store_Location2__c,
													RecordTypeId,
													Store_Location__c,
													Account_Number__c
													
													FROM Payment__c WHERE Id IN :mapNew.keyset()];		
		
		map<Id, list<Journal_Entry__c>> paymentIdToJournalEntryMap = linkJournalEntries(extraFieldsList);
		map<Id, list<Financial_Transaction__c>>  paymentIdToDepositFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Deposit');
		map<Id, list<Financial_Transaction__c>>  paymentIdToFinalPaymentFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Final Payment');
		map<Id, list<Financial_Transaction__c>>  paymentIdToMiscCashReceiptFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Misc Cash Receipt');
		
		system.debug('ads paymentIdToMiscCashReceiptFinacialTransactionList: '+paymentIdToMiscCashReceiptFinacialTransactionList);
		Id paymentDespositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
		Id paymentMiscCashReceiptRecordTypeId = UtilityMethods.retrieveRecordTypeId('Misc_Cash_Receipt', 'Payment__c');
		
		for(Payment__c p : extraFieldsList){
			String typeOfPayment;
			if(p.RecordTypeId == paymentDespositRecordTypeId && p.Payment_Type__c == 'Deposit'){
				typeOfPayment = 'DepositDeposit';
			}else if(p.RecordTypeId == paymentDespositRecordTypeId && p.Payment_Type__c == 'Final Payment'){
				typeOfPayment = 'DepositFinalPayment';
			}else if( p.RecordTypeId == paymentMiscCashReceiptRecordTypeId){
				typeOfPayment = 'MiscCashReceipt';
			} 
			
			
			if(typeOfPayment != null){
				string errorMessage;
				
				if(paymentIdToJournalEntryMap.get(p.id) == null || paymentIdToJournalEntryMap.get(p.id).size() == 0 ){
					
					if(typeOfPayment == 'DepositDeposit'){
						errorMessage = checkFinacialTransationForErrors(paymentIdToDepositFinacialTransactionList.get(p.id) , errorMessage, p.Payment_Type__c);
					}else if(typeOfPayment == 'DepositFinalPayment'){
						errorMessage = checkFinacialTransationForErrors(paymentIdToFinalPaymentFinacialTransactionList.get(p.id) , errorMessage, p.Payment_Type__c);
					}else if(typeOfPayment == 'MiscCashReceipt'){
						errorMessage = checkFinacialTransationForErrors(paymentIdToMiscCashReceiptFinacialTransactionList.get(p.id) , errorMessage, 'Misc Cash Receipt');
					}
					
					errorMessage = checkPaymentForErrors(p, errorMessage, typeOfPayment);
					 
					 
					 system.debug('ads p: '+p);
					 system.debug('ads p.Order__r.BillToContactId,: '+p.Order__r.BillToContactId);
					 
					if(errorMessage == null || errorMessage == ''){
						Journal_Entry__c newJE = new Journal_Entry__c(
							Date__c = Datetime.Now(),
							Payment__c = p.id,
							Order__c = p.Order__c,
							Amount__c = p.Payment_Amount__c,
							Customer__c = p.Order__r.BillToContactId, 
							Debit_General_Ledger_Account__c = paymentIdToDepositFinacialTransactionList.get(p.id)[0].Debit_Account_Number__r.Name
							);
						
						if(typeOfPayment == 'DepositDeposit'){
							newJE.Type__c = 'Deposit';
							newJE.Debit_General_Ledger_Account__c = paymentIdToDepositFinacialTransactionList.get(p.id)[0].Debit_Account_Number__r.Name;
							newJE.Credit_General_Ledger_Account__c = paymentIdToDepositFinacialTransactionList.get(p.id)[0].Credit_Account_Number__r.Name;
							
						}else if(typeOfPayment == 'DepositFinalPayment'){
							newJE.Type__c = 'Final Payment';
							newJE.Debit_General_Ledger_Account__c = paymentIdToFinalPaymentFinacialTransactionList.get(p.id)[0].Debit_Account_Number__r.Name;
							newJE.Credit_General_Ledger_Account__c = paymentIdToFinalPaymentFinacialTransactionList.get(p.id)[0].Credit_Account_Number__r.Name;
						
						}else if(typeOfPayment == 'MiscCashReceipt'){
							newJE.Type__c = 'Misc Cash Receipt';
							newJE.Debit_General_Ledger_Account__c = paymentIdToMiscCashReceiptFinacialTransactionList.get(p.id)[0].Debit_Account_Number__r.Name;
							newJE.Credit_General_Ledger_Account__c = p.Account_Number__c;			
						}
						
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
							je.Payment__c = p.id;
							je.Order__c = p.Order__c;
							je.Amount__c = p.Payment_Amount__c;
							je.Customer__c = p.Order__r.BillToContactId;
							
							if(typeOfPayment == 'DepositDeposit'){
								je.Type__c = 'Deposit';
								je.Debit_General_Ledger_Account__c = paymentIdToDepositFinacialTransactionList.get(p.id)[0].Debit_Account_Number__r.Name;
								je.Credit_General_Ledger_Account__c = paymentIdToDepositFinacialTransactionList.get(p.id)[0].Credit_Account_Number__r.Name;
							
							}else if(typeOfPayment == 'DepositFinalPayment'){
								je.Type__c = 'Final Payment';
								je.Debit_General_Ledger_Account__c = paymentIdToFinalPaymentFinacialTransactionList.get(p.id)[0].Debit_Account_Number__r.Name;
								je.Credit_General_Ledger_Account__c = paymentIdToFinalPaymentFinacialTransactionList.get(p.id)[0].Credit_Account_Number__r.Name;
							
							}else if(typeOfPayment == 'MiscCashReceipt'){
								je.Type__c = 'Misc Cash Receipt';
								je.Debit_General_Ledger_Account__c = paymentIdToMiscCashReceiptFinacialTransactionList.get(p.id)[0].Debit_Account_Number__r.Name;
								je.Credit_General_Ledger_Account__c = p.Account_Number__c;			
							}

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
	 Method to link object Id to a list of Journal_Entry__c
	****************************************************/
	public map<id, list<Journal_Entry__c>> linkJournalEntries(list<SObject> objectList){
		list<id> idList = new list<id>();
		for(SObject o : objectList){
			idList.add(o.id);
		}
		list<Journal_Entry__c> relatedJournalEntries = [SELECT 	id, 
																Payment__c,
																Labor__c,
																Sent_to_BaanERP__c
																FROM Journal_Entry__c WHERE Payment__c IN :idList OR Labor__c IN :idList];
																
		map<Id, list<Journal_Entry__c>> idToJournalEntryMap = new map<Id, list<Journal_Entry__c>>();
		if(String.ValueOf(objectList[0].getSObjectType()) == 'Payment__c'){
			for(Journal_Entry__c je : relatedJournalEntries){
				if(idToJournalEntryMap.containsKey(je.Payment__c) ){
					idToJournalEntryMap.get(je.Payment__c).add(je);
				}
				else{
					idToJournalEntryMap.put(je.Payment__c, new list<Journal_Entry__c>{je});
				}
			}
		}else if(String.ValueOf(objectList[0].getSObjectType()) == 'Labor__c'){
			for(Journal_Entry__c je : relatedJournalEntries){
				if(idToJournalEntryMap.containsKey(je.Labor__c) ){
					idToJournalEntryMap.get(je.Labor__c).add(je);
				}
				else{
					idToJournalEntryMap.put(je.Labor__c, new list<Journal_Entry__c>{je});
				}
			}
		}
		
		return idToJournalEntryMap;
	}
	
	/***************************************************
	 Method to link object ID to a list of Financial_Transaction__c
	 of a specific type.
	****************************************************/
	public map<id, list<SObject>>  linkFinacialTransactions(List<SObject> objectList, String typeToGet){
		list<id> paymentIdList = new list<id>();
		list<Id> storeListId = new list<Id>();
		
		for(SObject o : objectList){
			paymentIdList.add(o.id);
			storeListId.add((Id)o.get('Store_Location__c'));
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
//			if(String.ValueOf(objectList[0].getSObjectType()) == 'Payment__c'){
		for(SObject o : objectList){
			paymentIdToListFinancialTransaction.put(o.id, storeIdToListFinancialTransaction.get((Id)o.get('Store_Location__c')));
		}
		system.debug('ads paymentIdToListFinancialTransaction: '+paymentIdToListFinancialTransaction);
		return paymentIdToListFinancialTransaction;
	}
		
	/***************************************************
	 Method to run error checks against the Finacial Transaction Object
	****************************************************/
	public String checkFinacialTransationForErrors(list<Financial_Transaction__c> ftList, string errorMessage, string objectType){

		String dynamicErrorMessage;
		
		//CHECK IF MORE THEN ONE FINACIAL TRANSACTION RECORDS
		if(ftList != null && ftList.size() > 1 ){
			dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.EXTRA_FINACIAL_TRANSACTION_RECORDS, '[Transaction Type]', objectType);
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		//CHECK IF NO FINACIAL TRANSACTION RECORDS
		}else if(ftList == null || ftList.size() == 0 ){
			dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.NO_FINACIAL_TRANSACTION_RECORDS, '[Transaction Type]', objectType);
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}else{
			//CHECK IF CREDIT ACCOUNT NUMBER IS NULL
			if(ftList[0].Credit_Account_Number__c == null && objectType != 'Misc Cash Receipt' && objectType != 'Misc Reimbursement'){
				dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.FINACIAL_TRANSACTION_RECORDS_NO_CREDIT_ACCOUNT_NUMBER, '[Transaction Type]', objectType);
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
			//CHECK IF DEBIT ACCOUNT NUMBER IS NULL
			if(ftList[0].Debit_Account_Number__c == null ){
				dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.FINACIAL_TRANSACTION_RECORDS_NO_DEBIT_ACCOUNT_NUMBER, '[Transaction Type]', objectType);
				errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
			}
		}
		return errorMessage;		 
	}
	

	/***************************************************
	 Method to run error checks against the Payment Object
	****************************************************/
	public String checkPaymentForErrors(Payment__c payment, string errorMessage, string typeOfPayment){
		String dynamicErrorMessage;
		if(payment.id == null){
			dynamicErrorMessage = RMS_errorMessages.PAYMENT_ID_IS_NULL;
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}
		if(payment.Store_Location__c == null ){ 
			errorMessage = RMS_errorMessages.STORE_LOCATION_IS_BLANK;
		}
		if(payment.Payment_Amount__c == null){
			dynamicErrorMessage = RMS_errorMessages.PAYMENT_AMOUNT_IS_NULL;
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}
		if(payment.Order__c == null && typeOfPayment != 'MiscCashReceipt'){
			dynamicErrorMessage = RMS_errorMessages.ORDER_IS_NULL;
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}
		if(payment.Account_Number__c == null && typeOfPayment == 'MiscCashReceipt'){
			errorMessage = RMS_errorMessages.ACCOUNT_NUMBER_NULL;
		}
		if(payment.Order__r.BillToContactId == null && typeOfPayment != 'MiscCashReceipt'){
			dynamicErrorMessage = RMS_errorMessages.CONTACT_IS_NULL;
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}
		
		return errorMessage;		
	}
	
	/***************************************************
	 Method to run error checks against the Labor Object
	****************************************************/
	public String checkLaborForErrors(Labor__c labor, string errorMessage, string typeOfLabor){
		String dynamicErrorMessage;
		if(labor.id == null){
			dynamicErrorMessage = RMS_errorMessages.LABOR_ID_IS_NULL;
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}
		if(labor.Related_Work_Order__r.Sold_Order__c == null && typeOfLabor != 'LaborMiscReimbursement'){
			dynamicErrorMessage = RMS_errorMessages.ORDER_ON_WORK_ORDER_NULL;
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}
		if((labor.External_Labor_Amount__c == null || labor.External_Labor_Amount__c == 0) && typeOfLabor == 'LaborMiscReimbursement'){
			dynamicErrorMessage = RMS_errorMessages.EXTERNAL_AMOUNT_NULL;
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}
		if((labor.External_Labor_Amount__c == null || labor.External_Labor_Amount__c == 0) && 
			(labor.Internal_Cost__c == null || labor.Internal_Cost__c == 0)){
			dynamicErrorMessage = RMS_errorMessages.LABOR_AMOUNTS_NULL;
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}
		if( (labor.External_Labor_Amount__c != null && labor.External_Labor_Amount__c != 0) && 
			(labor.Installer__r.Account.Baan_Business_Partner_Number__c == null || labor.Installer__r.Account.Baan_Business_Partner_Number__c == '')){
			dynamicErrorMessage = RMS_errorMessages.INSTALLER_HAS_NO_BAAN_NUMBER;
			errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
		}
		return errorMessage;		
	}
	

	/***************************************************
	 Method to create or update Journal Entry for LABOR
	****************************************************/
	public void createOrUpdateJournalEntryLabor(list<Labor__c> listNew, map<id, Labor__c> mapNew ){	
		list<Journal_Entry__c> journalEntriesToUpsert = new list<Journal_Entry__c>();
		list<Labor__c> extraFieldsList = [SELECT 	id,
													Check_Date__c,
													Check_Number__c,
													Date_Applied__c,
													Description__c,
													External_Labor_Amount__c,
													Hours_Applied__c,
													Installer__c,
													Installer__r.Account.Baan_Business_Partner_Number__c,
													Installer_Account_Number__c,
													Internal_Cost__c,
													Labor_Complete__c,
													Related_Work_Order__c,
													Related_Work_Order__r.Sold_Order__c,
													Standard_Hourly_Rate__c,
													Store_Location__c,
													Related_Work_Order__r.Sold_Order__r.Store_Location2__c,
													Work_Order_Type__c,
													CreatedById,
													Name,
													RecordTypeId
													
													FROM Labor__c WHERE Id IN :mapNew.keyset()];		
		
		map<Id, list<Journal_Entry__c>> laborIdToJournalEntryMap = linkJournalEntries(extraFieldsList);

		map<Id, list<Financial_Transaction__c>>  laborIdToLaborFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Internal Labor');
		map<Id, list<Financial_Transaction__c>>  laborIdToMiscReimbursementFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Misc Reimbursement');
		
		Id laborLaborRecordTypeId = UtilityMethods.retrieveRecordTypeId('Labor', 'Labor__c');
		Id laborMiscReimbursementRecordTypeId = UtilityMethods.retrieveRecordTypeId('Misc_Reimbursement', 'Labor__c');
		
		for(Labor__c l : extraFieldsList){
			String typeOfLabor;
			if(l.RecordTypeId == laborLaborRecordTypeId ){
				typeOfLabor = 'LaborLabor';
			}else if(l.RecordTypeId == laborMiscReimbursementRecordTypeId ){
				typeOfLabor = 'LaborMiscReimbursement';
			}
			
			
			if(typeOfLabor != null){
				string errorMessage;
				if(l.Store_Location__c == null ){ 
					errorMessage = RMS_errorMessages.STORE_LOCATION_IS_BLANK;
				}
				
				errorMessage = checkLaborForErrors(l, errorMessage, typeOfLabor);
				
				if(typeOfLabor == 'LaborLabor'){
					if(l.External_Labor_Amount__c != null && l.External_Labor_Amount__c != 0){
						errorMessage = checkFinacialTransationForErrors(laborIdToLaborFinacialTransactionList.get(l.id) , errorMessage, 'External Labor');
					}else if(l.External_Labor_Amount__c == null || l.External_Labor_Amount__c == 0){
						errorMessage = checkFinacialTransationForErrors(laborIdToLaborFinacialTransactionList.get(l.id) , errorMessage, 'Internal Labor');
					}
				}else if( typeOfLabor == 'LaborMiscReimbursement'){
					errorMessage = checkFinacialTransationForErrors(laborIdToMiscReimbursementFinacialTransactionList.get(l.id) , errorMessage, 'Misc Reimbursement');
					
				}
				
				if(laborIdToJournalEntryMap.get(l.id) == null || laborIdToJournalEntryMap.get(l.id).size() == 0 ){
					if(errorMessage == null || errorMessage == ''){
						Journal_Entry__c newJE = new Journal_Entry__c(
							Date__c = Datetime.Now(),
							Labor__c = l.id,
							Order__c = l.Related_Work_Order__r.Sold_Order__c
		
							);
							
							if(typeOfLabor == 'LaborLabor'){
								newJE.Debit_General_Ledger_Account__c = laborIdToLaborFinacialTransactionList.get(l.id)[0].Debit_Account_Number__r.Name;
								newJE.Credit_General_Ledger_Account__c = laborIdToLaborFinacialTransactionList.get(l.id)[0].Credit_Account_Number__r.Name;
							
								if(l.External_Labor_Amount__c != null && l.External_Labor_Amount__c != 0){
									newJE.Type__c = 'External Labor';
									newJE.Amount__c = l.External_Labor_Amount__c;
									newJE.Baan_Business_Partner_Number__c = l.Installer__r.Account.Baan_Business_Partner_Number__c;
								}else if(l.External_Labor_Amount__c == null || l.External_Labor_Amount__c == 0){
									newJE.Type__c = 'Internal Labor';
									newJe.Amount__c = l.Internal_Cost__c;
								}
							}else if(typeOfLabor == 'LaborMiscReimbursement'){
								newJE.Type__c = 'Misc Reimbursement';
								newJE.Amount__c = l.External_Labor_Amount__c;
								newJE.Baan_Business_Partner_Number__c = l.Installer__r.Account.Baan_Business_Partner_Number__c;
								
								newJE.Debit_General_Ledger_Account__c = l.Installer_Account_Number__c;
								newJE.Credit_General_Ledger_Account__c = laborIdToMiscReimbursementFinacialTransactionList.get(l.id)[0].Credit_Account_Number__r.Name;
							}
						
						journalEntriesToUpsert.add(newJE);
					}else{
						//there is an error message
						mapNew.get(l.id).addError(errorMessage, FALSE);
					}
				}else
					//there is a related journal entry
					if(errorMessage == null || errorMessage == ''){
						if(laborIdToJournalEntryMap.get(l.id).size() == 1){
							Journal_Entry__c je = laborIdToJournalEntryMap.get(l.id)[0];
							if(je.Sent_to_BaanERP__c == true){
								//Journal Entry already sent to BaanERP, throw error
								errorMessage = RMS_errorMessages.PAYMENT_ALREADY_SUBMITTED;
								mapNew.get(l.id).addError(errorMessage, FALSE);
							}else{
								//Journal Entry NOT sent to BaanERP, update Journal Entry
								system.debug('ads inside not sent to Baan: '+ je);
								je.Date__c = Datetime.Now();
								je.Labor__c = l.id;
								je.Order__c = l.Related_Work_Order__r.Sold_Order__c;
			
								if(typeOfLabor == 'LaborLabor'){
									je.Debit_General_Ledger_Account__c = laborIdToLaborFinacialTransactionList.get(l.id)[0].Debit_Account_Number__r.Name;
									je.Credit_General_Ledger_Account__c = laborIdToLaborFinacialTransactionList.get(l.id)[0].Credit_Account_Number__r.Name;
								
									if(l.External_Labor_Amount__c != null && l.External_Labor_Amount__c != 0){
										je.Type__c = 'External Labor';
										je.Amount__c = l.External_Labor_Amount__c;
										je.Baan_Business_Partner_Number__c = l.Installer__r.Account.Baan_Business_Partner_Number__c;
									}else if(l.External_Labor_Amount__c == null || l.External_Labor_Amount__c == 0){
										je.Type__c = 'Internal Labor';
										je.Amount__c = l.Internal_Cost__c;
									}
								}else if(typeOfLabor == 'LaborMiscReimbursement'){
									je.Type__c = 'Misc Reimbursement';
									je.Amount__c = l.External_Labor_Amount__c;
									je.Baan_Business_Partner_Number__c = l.Installer__r.Account.Baan_Business_Partner_Number__c;
									
									je.Debit_General_Ledger_Account__c = l.Installer_Account_Number__c;
									je.Credit_General_Ledger_Account__c = laborIdToMiscReimbursementFinacialTransactionList.get(l.id)[0].Credit_Account_Number__r.Name;
								}
	
								journalEntriesToUpsert.add(je);
							}
							
						}//end if only one journal entery
						
					}else{
						//there is an error message
						mapNew.get(l.id).addError(errorMessage, FALSE);
					}
					
				}//end of if there is related journal entery
					
		
		}//END OF PAYMENT FOR LOOP
		system.debug('ads journalEntriesToUpsert: '+journalEntriesToUpsert);
		upsert journalEntriesToUpsert;
	}//END onAfterInsert Method
	
	
	/***************************************************
	 Methods to lock records
	****************************************************/
	// TODO: Make these completely generic for sObjects?
	public void lockPaymentRecords(list<Payment__c> listNew){	

	 	List<Payment__c> recordsToLock = new List<Payment__c>();

		// Loop through the list of payments and if it's been set to processed, lock it
	 	for(Payment__c p : listNew){
	 		if(p.Processed_Date__c != null){
		 		recordsToLock.add(p);
	 		}
	 	} 
	 	
	 	if (recordsToLock.size() > 0) {
	 		String result = UtilityMethods.lockRecords(recordsToLock);
	 	}
	 	
	}

	public void lockPaymentRecords(list<Payment__c> listOld, map<id,Payment__c> mapNew ){	

	 	List<Payment__c> recordsWithNullProcessedDate = new List<Payment__c>();

		// loop through the old list and if the processed date was null, send it to the lock records to test the new list
	 	for(Payment__c pOld : listOld){
	 		if(	pOld.Processed_Date__c == null){
				recordsWithNullProcessedDate.add(mapNew.get(pOld.id));
	 		}
	 	}	
	 	lockPaymentRecords(recordsWithNullProcessedDate);	
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
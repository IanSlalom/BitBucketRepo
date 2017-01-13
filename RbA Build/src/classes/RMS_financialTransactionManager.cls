/**********************************************************

@class  RMS_financialTransactionManager

@brief  Controller to handle finacial transation recording

@author  Anthony Strafaccia (Slalom.ADS)

@version    2015-12/24  Slalom.ADS
    Created. 

@see        RMS_financialTransactionManagerTest

@copyright  (c)2015 Slalom.  All Rights Reserved.
            Unauthorized use is prohibited. 

***********************************************************/

public with sharing class RMS_financialTransactionManager {
	
    public Id orderCORORecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Record_Type', 'Order');
    public Id orderCOROServiceRecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order');
	public Id orderChangeOrderRecordTypeId = UtilityMethods.retrieveRecordTypeId('Change_Order', 'Order');
    public List<Id> orderRecordTypes = new list<id>{orderCORORecordTypeId,orderCOROServiceRecordTypeId,orderChangeOrderRecordTypeId};

	
	//CHECK IF DATA LOADING PROFILE	
	public Boolean turnFinancialTransactionsOff {get{map<String, RMS_Settings__c> RMS_Settings_map = RMS_Settings__c.getAll();
														if(	RMS_Settings_map.get('Turn Financial Transactions Off') != null && 
															RMS_Settings_map.get('Turn Financial Transactions Off').Value__c != null &&
															RMS_Settings_map.get('Turn Financial Transactions Off').Value__c != '' &&
															RMS_Settings_map.get('Turn Financial Transactions Off').Value__c.toLowerCase() == 'yes'){
															return true;
														}else{
															return false;
														} 
													}}

    //PAYMENT
    public void onAfterInsertPayment(list<Payment__c> listNew, map<id,Payment__c> mapNew){
        if(!turnFinancialTransactionsOff){
        	createOrUpdateJournalEntryPayment(listNew, mapNew);
        }
        //TODO:This locking functionality will eventually get moved to a batch process
//      lockPaymentRecords(listNew);
    }

    public void onAfterUpdatePayment(list<Payment__c> listOld, list<Payment__c> listNew, map<Id, Payment__c> mapOld, map<Id, Payment__c> mapNew){
        if(!turnFinancialTransactionsOff){
        	createOrUpdateJournalEntryPayment(listNew, mapNew);
        }
//      lockPaymentRecords(listOld, mapNew);
    }
    
    public void onBeforeDeletePayment(list<Payment__c> listOld, map<Id, Payment__c> mapOld){
        
        allowDeleteOrNot(listOld, mapOld);
    }
    
    
    //LABOR
    public void onAfterInsertLabor(list<Labor__c> listNew, map<id,Labor__c> mapNew){
        if(!turnFinancialTransactionsOff){
        	createOrUpdateJournalEntryLabor(listNew, mapNew);
        }
    }

    public void onAfterUpdateLabor(list<Labor__c> listOld, list<Labor__c> listNew, map<Id, Labor__c> mapOld, map<Id, Labor__c> mapNew){
        if(!turnFinancialTransactionsOff){
        	createOrUpdateJournalEntryLabor(listNew, mapNew);
        }
    }
    
    public void onBeforeDeleteLabor(list<Labor__c> listOld, map<Id, Labor__c> mapOld){
        allowDeleteOrNot(listOld, mapOld);
    }
    
    //ASSET
    public void onAfterInsertAsset(list<Asset> listNew, map<id,Asset> mapNew){
        if(!turnFinancialTransactionsOff){
        	createOrUpdateJournalEntryAsset(listNew, mapNew, null, 'insert');
        }
    }

    public void onAfterUpdateAsset(list<Asset> listOld, list<Asset> listNew, map<Id, Asset> mapOld, map<Id, Asset> mapNew){
        if(!turnFinancialTransactionsOff){
        	createOrUpdateJournalEntryAsset(listNew, mapNew, mapOld, 'update');
        }
    }
    
    public void onBeforeDeleteAsset(list<Asset> listOld, map<Id, Asset> mapOld){
        allowDeleteOrNot(listOld, mapOld);
    }
    
    //ORDER
    public void onAfterUpdateOrder(list<Order> listOld, list<Order> listNew, map<Id, Order> mapOld, map<Id, Order> mapNew){
        if(!turnFinancialTransactionsOff){
        	createJournalEntryOrder(listNew, mapNew, mapOld);
        }
    }
    
    public void onBeforeDeleteOrder(list<Order> listOld, map<Id, Order> mapOld){
        allowDeleteOrNot(listOld, mapOld);
    }
    
    //REFUND
    public void onAfterInsertAsset(list<Refund__c> listNew, map<id,Refund__c> mapNew){
        if(!turnFinancialTransactionsOff){
        	createOrUpdateJournalEntryRefund(listNew, mapNew, null, 'insert');
        }
    }
    
    public void onAfterUpdateOrder(list<Refund__c> listOld, list<Refund__c> listNew, map<Id, Refund__c> mapOld, map<Id, Refund__c> mapNew){
        if(!turnFinancialTransactionsOff){
        	createOrUpdateJournalEntryRefund(listNew, mapNew, mapOld, 'update');
        }
    }
    
    public void onBeforeDeleteOrder(list<Refund__c> listOld, map<Id, Refund__c> mapOld){
        allowDeleteOrNot(listOld, mapOld);
    }
    
    //BUSINESS ADJUSTMENT
    public void onAfterInsertAsset(list<Business_Adjustment__c> listNew, map<id,Business_Adjustment__c> mapNew){
        if(!turnFinancialTransactionsOff){
        	createOrUpdateJournalEntryBusinessAdjustment(listNew, mapNew, null, 'insert');
        }
    }
    
    public void onAfterUpdateOrder(list<Business_Adjustment__c> listOld, list<Business_Adjustment__c> listNew, map<Id, Business_Adjustment__c> mapOld, map<Id, Business_Adjustment__c> mapNew){
        if(!turnFinancialTransactionsOff){
        	createOrUpdateJournalEntryBusinessAdjustment(listNew, mapNew, mapOld, 'update');
        }
    }
    
    public void onBeforeDeleteOrder(list<Business_Adjustment__c> listOld, map<Id, Business_Adjustment__c> mapOld){
        allowDeleteOrNot(listOld, mapOld);
    }


    /***************************************************
     Method to check if payment records can be deleted
    ****************************************************/
    public void allowDeleteOrNot(list<SObject> listOld, map<id,SObject> mapOld ){
        String soType = String.valueOf(listOld.getSObjectType());

        list<Journal_Entry__c> journalEntriesToDelete= new list<Journal_Entry__c>();
        map<Id, list<Journal_Entry__c>> objectIdToJournalEntryMap = linkJournalEntries(listOld);

        String errorMessage;
        
        for(SObject o : listOld){
            if(objectIdToJournalEntryMap.get(o.id) == null || objectIdToJournalEntryMap.get(o.id).size() == 0){
                continue;
            }else if(objectIdToJournalEntryMap.get(o.id).size() > 1 && (soType == 'Payment__c' || soType == 'Labor__c' || soType == 'Refund__c')){
                errorMessage = RMS_errorMessages.MULTIPLE_JOURNAL_ENTRIES;
                o.addError(errorMessage, FALSE);
            }else if(objectIdToJournalEntryMap.get(o.id).size() == 1 && (soType == 'Payment__c' || soType == 'Labor__c' || soType == 'Refund__c')){
                if(objectIdToJournalEntryMap.get(o.id)[0].Sent_to_BaanERP__c == false){
                    journalEntriesToDelete.add(objectIdToJournalEntryMap.get(o.id)[0]);
                }else{
                    errorMessage = RMS_errorMessages.ALREADY_SUBMITTED_DELETE;
                    o.addError(errorMessage, FALSE);
                }
            }else if(objectIdToJournalEntryMap.get(o.id).size() > 0 && (soType == 'Asset' || soType == 'Business_Adjustment__c')  ){
                Boolean submitedToBaan = false;
                for(Journal_Entry__c je : objectIdToJournalEntryMap.get(o.id)){
                    if(je.Sent_to_BaanERP__c == true){
                        submitedToBaan = true;
                        break;
                    } 
                }
                if(submitedToBaan == true){
                    errorMessage = RMS_errorMessages.ALREADY_SUBMITTED_DELETE;
                    o.addError(errorMessage, FALSE);
                }else if(submitedToBaan == false){
                    journalEntriesToDelete.addAll(objectIdToJournalEntryMap.get(o.id));
                }
            }
        }
        system.debug('ads journalEntriesToDelete: '+journalEntriesToDelete);
        delete journalEntriesToDelete;
    }
    
    
    /***************************************************
     Method to create or update Journal Entry for PAYMENT
    ****************************************************/
    public void createOrUpdateJournalEntryPayment(list<Payment__c> listNew, map<id,Payment__c> mapNew ){    
        list<Journal_Entry__c> journalEntriesToUpsert = new list<Journal_Entry__c>();
       	
        list<Payment__c> extraFieldsList = [SELECT  id,
                                                    Order__c,
                                                    Order__r.BillToContactId,
                                                    Order__r.Retail_Total__c,
                                                    Order__r.Retail_Subtotal__c,
                                                    Payment_Amount__c,
                                                    Payment_Type__c,
                                                    Order__r.Store_Location__c,
                                                    Order__r.Revenue_Recognized_Date__c,
                                                    RecordTypeId,
                                                    Store_Location__c,
                                                    Store_Location__r.Active_Store_Configuration__c,
                                                    GL_Account__r.Name
                                                    
                                                    FROM Payment__c WHERE Id IN :mapNew.keyset() ];      
        
        map<Id, list<Journal_Entry__c>> paymentIdToJournalEntryMap = linkJournalEntries(extraFieldsList);
        /*
        map<Id, list<Financial_Transaction__c>>  paymentIdToDepositFTL = linkFinacialTransactions(extraFieldsList, 'Deposit');
        map<Id, list<Financial_Transaction__c>>  paymentIdToFinalPaymentFTL = linkFinacialTransactions(extraFieldsList, 'Final Payment');
        map<Id, list<Financial_Transaction__c>>  paymentIdToMiscCashReceiptFTL = linkFinacialTransactions(extraFieldsList, 'Misc Cash Receipt');
        */
        
        list<string> financialTransactionTypesToGet = new list<string>();
        financialTransactionTypesToGet.add('Deposit');
        financialTransactionTypesToGet.add('Final Payment');
        financialTransactionTypesToGet.add('Misc Cash Receipt'); 
       	map<string, map<Id, list<Financial_Transaction__c>>> typeToMapOfPaymentIdtoListFT = linkFinancialTransactions(extraFieldsList, financialTransactionTypesToGet);
        map<Id, list<Financial_Transaction__c>>  paymentIdToDepositFTL = typeToMapOfPaymentIdtoListFT.get('Deposit');
        map<Id, list<Financial_Transaction__c>>  paymentIdToFinalPaymentFTL = typeToMapOfPaymentIdtoListFT.get('Final Payment');
        map<Id, list<Financial_Transaction__c>>  paymentIdToMiscCashReceiptFTL = typeToMapOfPaymentIdtoListFT.get('Misc Cash Receipt');
        
        map<Id, String> paymentIdToMiscCashReceiptCreditGLAmap = linkMiscPaymentAccountNumbers(extraFieldsList, mapNew);
       
        system.debug('ads paymentIdToMiscCashReceiptFTL: '+paymentIdToMiscCashReceiptFTL);
        Id paymentDespositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
        Id paymentMiscCashReceiptRecordTypeId = UtilityMethods.retrieveRecordTypeId('Misc_Cash_Receipt', 'Payment__c');
        
        
        
        //LINKING ALL PAYMENTS THAT ARE EITHER DEPOSIT OR FINAL PAYMENT TO ORDER AND HAVE ORDER RECORD TYPES OF CORO OR CORO SERVICE
        list<Id> relatedOrderIds = new list<Id>();
        for(Payment__c p : extraFieldsList){
        	relatedOrderIds.add(p.Order__c);
        } 
        list<Payment__c> allRelatedPayments = [SELECT  	id,
	                                                    Order__c,
	                                                    Order__r.BillToContactId,
	                                                    Order__r.Retail_Total__c,
	                                                    Order__r.Retail_Subtotal__c,
	                                                    Payment_Amount__c,
	                                                    Payment_Type__c,
	                                                    Order__r.Store_Location__c,
	                                                    Order__r.Revenue_Recognized_Date__c,
	                                                    Order__r.RecordTypeId,
	                                                    RecordTypeId,
	                                                    Store_Location__c,
	                                                    GL_Account__r.Name
                                                    
                                                    FROM Payment__c WHERE Order__c IN :relatedOrderIds AND Order__r.RecordTypeId IN :orderRecordTypes];
                                                    
        map<Id, list<Payment__c>> orderIdToListOfDFPPayments = new map<Id, list<Payment__c>>();
        for(Payment__c p : allRelatedPayments){
            if(orderIdToListOfDFPPayments.containsKey(p.Order__c) ){
                orderIdToListOfDFPPayments.get(p.Order__c).add(p); 
            }
            else{
                orderIdToListOfDFPPayments.put(p.Order__c, new list<Payment__c>{p});
            }
        } 
        
        
        for(Payment__c p : extraFieldsList){
            String typeOfPayment;
            if(p.RecordTypeId == paymentDespositRecordTypeId && p.Order__r.Revenue_Recognized_Date__c == null){
                typeOfPayment = 'DepositDeposit';
            }else if(p.RecordTypeId == paymentDespositRecordTypeId && p.Order__r.Revenue_Recognized_Date__c != null){
                typeOfPayment = 'DepositFinalPayment';
            }else if( p.RecordTypeId == paymentMiscCashReceiptRecordTypeId){
                typeOfPayment = 'MiscCashReceipt';
            }
            
            
            if(typeOfPayment != null){
                string errorMessage;
                if(typeOfPayment == 'DepositDeposit'){
                    errorMessage = checkFinacialTransationForErrors(paymentIdToDepositFTL.get(p.id) , errorMessage, 'Deposit');
                }else if(typeOfPayment == 'DepositFinalPayment'){
                    errorMessage = checkFinacialTransationForErrors(paymentIdToFinalPaymentFTL.get(p.id) , errorMessage, 'Final Payment');
                }else if(typeOfPayment == 'MiscCashReceipt'){
                    errorMessage = checkFinacialTransationForErrors(paymentIdToMiscCashReceiptFTL.get(p.id) , errorMessage, 'Misc Cash Receipt');
                }
                
                errorMessage = checkPaymentForErrors(p, errorMessage, typeOfPayment);
                
                if(errorMessage == null || errorMessage == ''){
                    
                    if(paymentIdToJournalEntryMap.get(p.id) == null || paymentIdToJournalEntryMap.get(p.id).size() == 0 ){
 
                        system.debug('ads p: '+p);
                        
                        Journal_Entry__c newJE = new Journal_Entry__c();
						if(typeOfPayment != 'MiscCashReceipt') {
                        	//CHECK THAT SUM OF PAYMENT TYPES IS NOT GREATER THAN ORDER TOTAL
	                        system.debug('ads p.Order__r.BillToContactId,: '+p.Order__r.BillToContactId);
                        	Decimal paymentTotal = 0;
                        	for(Payment__c payment :orderIdToListOfDFPPayments.get(p.Order__c)){
                        		if(payment.Payment_Type__c == 'Deposit' || payment.Payment_Type__c == 'Final Payment'){
                        			paymentTotal = paymentTotal + payment.Payment_Amount__c;
                        		}
                        	}
                        	system.debug('ads temporary paymentTotal 1: '+paymentTotal);
                        	system.debug('ads temporary p.Order__r.Retail_Total__c 1: '+p.Order__r.Retail_Total__c);
                        	system.debug('ads temporary p.Payment_Amount__c 1: '+p.Payment_Amount__c);
							//  commented out per JETT-3638
/*                        	if(paymentTotal > p.Order__r.Retail_Total__c){
                        	 	errorMessage = RMS_errorMessages.AMOUNT_OF_PAYMENT_EXCEEDS_PRICE;
                             	mapNew.get(p.id).addError(errorMessage, FALSE);
                        	} */
                            newJE.Date__c = Datetime.Now();
                            newJE.Payment__c = p.id;
                            newJE.Order__c = p.Order__c;
                           	newJE.Amount__c = p.Payment_Amount__c;
                            newJE.Customer__c = p.Order__r.BillToContactId;
						// It's a misc cash receipt
						} else {
                            newJE.Date__c = Datetime.Now();
                            newJE.Payment__c = p.id;
                            newJE.Amount__c = p.Payment_Amount__c;
						}
                        
                        if(typeOfPayment == 'DepositDeposit'){
                            newJE.Type__c = 'Deposit';
                            newJE.Debit_General_Ledger_Account__c = paymentIdToDepositFTL.get(p.id)[0].Debit_Account_Number__r.Name;
                            newJE.Credit_General_Ledger_Account__c = paymentIdToDepositFTL.get(p.id)[0].Credit_Account_Number__r.Name;
                            
                        }else if(typeOfPayment == 'DepositFinalPayment'){
                            newJE.Type__c = 'Final Payment';
                            newJE.Debit_General_Ledger_Account__c = paymentIdToFinalPaymentFTL.get(p.id)[0].Debit_Account_Number__r.Name;
                            newJE.Credit_General_Ledger_Account__c = paymentIdToFinalPaymentFTL.get(p.id)[0].Credit_Account_Number__r.Name;
                        
                        }else if(typeOfPayment == 'MiscCashReceipt'){
                            newJE.Type__c = 'Misc Cash Receipt';
                            newJE.Debit_General_Ledger_Account__c = paymentIdToMiscCashReceiptFTL.get(p.id)[0].Debit_Account_Number__r.Name;
                            newJE.Credit_General_Ledger_Account__c = paymentIdToMiscCashReceiptCreditGLAmap.get(p.id);          
                        }
                        
                        journalEntriesToUpsert.add(newJE);
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
                                
								if(typeOfPayment != 'MiscCashReceipt') {
                                	//CHECK THAT SUM OF PAYMENT TYPES IS NOT GREATER THAN ORDER TOTAL
                                	Decimal paymentTotal = 0;
		                        	for(Payment__c payment :orderIdToListOfDFPPayments.get(p.Order__c)){
		                        		if(payment.Payment_Type__c == 'Deposit' || payment.Payment_Type__c == 'Final Payment'){
		                        			if(payment.Id == p.Id){
		                        				paymentTotal = paymentTotal + p.Payment_Amount__c;
		                        			}else{
			                        			paymentTotal = paymentTotal + payment.Payment_Amount__c;
		                        			}
		                        		}
		                        	}
		                        	system.debug('ads temporary paymentTotal: '+paymentTotal);
		                        	system.debug('ads temporary p.Order__r.Retail_Total__c: '+p.Order__r.Retail_Total__c);
									//  commented out per JETT-3638
		    /*                    	if(paymentTotal > p.Order__r.Retail_Total__c){
		                        		 errorMessage = RMS_errorMessages.AMOUNT_OF_PAYMENT_EXCEEDS_PRICE;
		                            	 mapNew.get(p.id).addError(errorMessage, FALSE);
		                        	}*/
		                        
                                	//Journal Entry NOT sent to BaanERP, update Journal Entry
                                	system.debug('ads inside not sent to Baan: '+ je);
                                	je.Date__c = Datetime.Now();
                                	je.Payment__c = p.id;
                                	je.Order__c = p.Order__c;
                                	je.Amount__c = p.Payment_Amount__c;
                                	je.Customer__c = p.Order__r.BillToContactId;
								// It's a misc cash receipt
								} else {
                        			//Journal_Entry__c newJE = new Journal_Entry__c(
                            		//Date__c = Datetime.Now(),
                            		//Payment__c = p.id,
                            		//Amount__c = p.Payment_Amount__c);
		                            je.Date__c = Datetime.Now();
        		                    je.Payment__c = p.id;
                		            je.Amount__c = p.Payment_Amount__c;
								}
								
                                if(typeOfPayment == 'DepositDeposit'){
                                    je.Type__c = 'Deposit';
                                    je.Debit_General_Ledger_Account__c = paymentIdToDepositFTL.get(p.id)[0].Debit_Account_Number__r.Name;
                                    je.Credit_General_Ledger_Account__c = paymentIdToDepositFTL.get(p.id)[0].Credit_Account_Number__r.Name;
                                
                                }else if(typeOfPayment == 'DepositFinalPayment'){
                                    je.Type__c = 'Final Payment';
                                    je.Debit_General_Ledger_Account__c = paymentIdToFinalPaymentFTL.get(p.id)[0].Debit_Account_Number__r.Name;
                                    je.Credit_General_Ledger_Account__c = paymentIdToFinalPaymentFTL.get(p.id)[0].Credit_Account_Number__r.Name;
                                
                                }else if(typeOfPayment == 'MiscCashReceipt'){
                                    je.Type__c = 'Misc Cash Receipt';
                                    je.Debit_General_Ledger_Account__c = paymentIdToMiscCashReceiptFTL.get(p.id)[0].Debit_Account_Number__r.Name;
                                    je.Credit_General_Ledger_Account__c = paymentIdToMiscCashReceiptCreditGLAmap.get(p.id);         
                                }
     
                                journalEntriesToUpsert.add(je);
                            }
                            
                        }//end if only one journal entery
                    }//end of if there is related journal entry
                }else{
                        //there is an error message
                        mapNew.get(p.id).addError(errorMessage, FALSE); 
                }
            }//END IF typeOfPayment == null
        }//END OF PAYMENT FOR LOOP
        system.debug('ads journalEntriesToUpsert: '+journalEntriesToUpsert);  
        upsert journalEntriesToUpsert;
    }//END createOrUpdateJournalEntryPayment Method
    
     
    /***************************************************
     Method to create or update Journal Entry for LABOR
    ****************************************************/
    public void createOrUpdateJournalEntryLabor(list<Labor__c> listNew, map<id, Labor__c> mapNew ){

        list<Journal_Entry__c> journalEntriesToUpsert = new list<Journal_Entry__c>();
        list<Labor__c> extraFieldsList = [SELECT    id,
                                                    Check_Date__c,
                                                    Check_Number__c,
                                                    Date_Applied__c,
                                                    Description__c,
                                                    External_Labor_Amount__c,
                                                    Hours_Applied__c,
                                                    Installer__c,
                                                    Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c,
                                                    Installer_Account_Number__c,
                                                    GL_Account__c,
                                                    GL_Account__r.Name,
                                                    Internal_Cost__c,
                                                    JIP__c,
                                                    Related_Work_Order__c,
                                                    Related_Work_Order__r.Sold_Order__c,
                                                    Hourly_Rate__c,
                                                    Store_Location__c,
                                                    Store_Location__r.Active_Store_Configuration__c,
                                                    Related_Work_Order__r.Sold_Order__r.Store_Location__c,
                                                    Related_Work_Order__r.Sold_Order__r.Revenue_Recognized_Date__c,
                                                    Related_Work_Order__r.Sold_Order__r.RecordTypeId,
                                                    Work_Order_Type__c,
                                                    CreatedById,
                                                    Name,
                                                    RecordTypeId  
                                                    
                                                    FROM Labor__c WHERE Id IN :mapNew.keyset()];        
        
        map<Id, list<Journal_Entry__c>> laborIdToJournalEntryMap = linkJournalEntries(extraFieldsList);
/*
        map<Id, list<Financial_Transaction__c>>  laborIdToLaborFTL = linkFinacialTransactions(extraFieldsList, 'Internal Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToLaborExternalFTL = linkFinacialTransactions(extraFieldsList, 'External Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToServiceLaborFTL = linkFinacialTransactions(extraFieldsList, 'Service Internal Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToServiceLaborExternalFTL = linkFinacialTransactions(extraFieldsList, 'Service External Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToLaborPostRecInternalFTL = linkFinacialTransactions(extraFieldsList, 'Post Recognized Internal Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToLaborPostRecExternalFTL = linkFinacialTransactions(extraFieldsList, 'Post Recognized External Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToLaborPostRecServiceExternalFTL = linkFinacialTransactions(extraFieldsList, 'Post Recognized Service External Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToMiscReimbursementFTL = linkFinacialTransactions(extraFieldsList, 'Misc Reimbursement');
*/       
        
        list<string> financialTransactionTypesToGet = new list<string>{	'Internal Labor', 
        																'External Labor', 
        																'Service External Labor',
        																'Service External Labor - JIP',
        																'Post Recognized Internal Labor',
        																'Post Recognized External Labor',
        																'Post Recognized Service External Labor',
        																'Post Recognized Service External Labor - JIP',
        																'Misc Reimbursement'
        																};
       	map<string, map<Id, list<Financial_Transaction__c>>> typeToMapOfLaborIdtoListFT = linkFinancialTransactions(extraFieldsList, financialTransactionTypesToGet);
        
        map<Id, list<Financial_Transaction__c>>  laborIdToLaborFTL = typeToMapOfLaborIdtoListFT.get('Internal Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToLaborExternalFTL = typeToMapOfLaborIdtoListFT.get('External Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToServiceLaborExternalFTL = typeToMapOfLaborIdtoListFT.get('Service External Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToServiceLaborExternalJIPFTL = typeToMapOfLaborIdtoListFT.get('Service External Labor - JIP');
       	map<Id, list<Financial_Transaction__c>>  laborIdToLaborPostRecInternalFTL = typeToMapOfLaborIdtoListFT.get('Post Recognized Internal Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToLaborPostRecExternalFTL = typeToMapOfLaborIdtoListFT.get('Post Recognized External Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToLaborPostRecServiceExternalFTL = typeToMapOfLaborIdtoListFT.get('Post Recognized Service External Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToLaborPostRecServiceExternalJIPFTL = typeToMapOfLaborIdtoListFT.get('Post Recognized Service External Labor - JIP');
        map<Id, list<Financial_Transaction__c>>  laborIdToMiscReimbursementFTL = typeToMapOfLaborIdtoListFT.get('Misc Reimbursement');

        map<Id, String> laborIdToMiscReimbursementGLAmap = linkMiscPaymentAccountNumbers(extraFieldsList, mapNew);
        
        Id laborLaborRecordTypeId = UtilityMethods.retrieveRecordTypeId('Labor', 'Labor__c');
        Id laborMiscReimbursementRecordTypeId = UtilityMethods.retrieveRecordTypeId('Misc_Reimbursement', 'Labor__c');
      	
        for(Labor__c l : extraFieldsList){
            String typeOfLabor;
            String subTypeOfLabor;
            String JIPLabor;
            String typeOfOrder;
            
            if(l.RecordTypeId == laborLaborRecordTypeId && l.Related_Work_Order__r.Sold_Order__r.Revenue_Recognized_Date__c == null){
                typeOfLabor = 'LaborLabor';
                if(l.External_Labor_Amount__c == null || l.External_Labor_Amount__c == 0){
                	subTypeOfLabor = 'internal';
                }else if(l.External_Labor_Amount__c != null && l.External_Labor_Amount__c != 0){
                	subTypeOfLabor = 'external';
                }
      			// If the labor JIP flag is set, this is JIP labor, otherwise it is not
                JIPLabor = (l.JIP__c == true) ? 'true' : 'false';
				if(l.Related_Work_Order__r.Sold_Order__r.RecordTypeId == orderCORORecordTypeId){
					typeOfOrder = 'coroRecordType';
				}else if(l.Related_Work_Order__r.Sold_Order__r.RecordTypeId == orderCOROServiceRecordTypeId){
					typeOfOrder = 'coroService';
				}else if(l.Related_Work_Order__r.Sold_Order__r.RecordTypeId == orderChangeOrderRecordTypeId){
					typeOfOrder = 'changeOrder';
				}
            }
            else if(l.RecordTypeId == laborLaborRecordTypeId && l.Related_Work_Order__r.Sold_Order__r.Revenue_Recognized_Date__c != null){
				typeOfLabor = 'PostRecLabor';
               	if(l.External_Labor_Amount__c == null || l.External_Labor_Amount__c == 0){
//                	continue;
                	subTypeOfLabor = 'internal';
                }else if(l.External_Labor_Amount__c != null && l.External_Labor_Amount__c != 0){
                	subTypeOfLabor = 'external';
                }
                // If the labor JIP flag is set, this is JIP labor, otherwise it is not
                JIPLabor = (l.JIP__c == true) ? 'true' : 'false';
                
                if(l.Related_Work_Order__r.Sold_Order__r.RecordTypeId == orderCORORecordTypeId){
					typeOfOrder = 'coroRecordType';
				}else if(l.Related_Work_Order__r.Sold_Order__r.RecordTypeId == orderCOROServiceRecordTypeId){
					typeOfOrder = 'coroService';
				}else if(l.Related_Work_Order__r.Sold_Order__r.RecordTypeId == orderChangeOrderRecordTypeId){
					typeOfOrder = 'changeOrder';
				} 
            }	
            else if(l.RecordTypeId == laborMiscReimbursementRecordTypeId ){
                typeOfLabor = 'LaborMiscReimbursement';
            } 
            
             
            if(typeOfLabor != null){
                string errorMessage;
                if(l.Store_Location__c == null ){ 
                    errorMessage = RMS_errorMessages.STORE_LOCATION_IS_BLANK;
                }
                  
                errorMessage = checkLaborForErrors(l, errorMessage, typeOfLabor);
                
                if(typeOfLabor == 'LaborLabor'){
                    if(subTypeOfLabor == 'external'){
	                	if(typeOfOrder == 'coroService'){
	                		if(JIPLabor == 'true')
	                			errorMessage = checkFinacialTransationForErrors(laborIdToServiceLaborExternalJIPFTL.get(l.id) , errorMessage, 'Service External Labor - JIP');
							else { 		  
	                			errorMessage = checkFinacialTransationForErrors(laborIdToServiceLaborExternalFTL.get(l.id) , errorMessage, 'Service External Labor');
							}
		                }else if(typeOfOrder == 'coroRecordType' || typeOfOrder == 'changeOrder'){
	                        errorMessage = checkFinacialTransationForErrors(laborIdToLaborExternalFTL.get(l.id) , errorMessage, 'External Labor');
	                	}
                    }else if(subTypeOfLabor == 'internal'){
						                       
		                if(typeOfOrder == 'coroRecordType' || typeOfOrder == 'changeOrder' || typeOfOrder == 'coroService'){
	                        errorMessage = checkFinacialTransationForErrors(laborIdToLaborFTL.get(l.id) , errorMessage, 'Internal Labor');
	                    }
                	}
                }
                
                //POST RECOGNIZED LABOR
                else if(typeOfLabor == 'PostRecLabor'){
                    if(subTypeOfLabor == 'external'){
                        if(typeOfOrder == 'coroService'){
	                		if(JIPLabor == 'true')
	    	                	errorMessage = checkFinacialTransationForErrors(laborIdToLaborPostRecServiceExternalJIPFTL.get(l.id) , errorMessage, 'Post Recognized Service External Labor - JIP');
							else
	    	                	errorMessage = checkFinacialTransationForErrors(laborIdToLaborPostRecServiceExternalFTL.get(l.id) , errorMessage, 'Post Recognized Service External Labor');
                        }else if(typeOfOrder == 'coroRecordType' || typeOfOrder == 'changeOrder'){
	                    	errorMessage = checkFinacialTransationForErrors(laborIdToLaborPostRecExternalFTL.get(l.id) , errorMessage, 'Post Recognized External Labor');
                        }
                    }else if(subTypeOfLabor == 'internal'){
                        if(typeOfOrder == 'coroRecordType' || typeOfOrder == 'changeOrder' || typeOfOrder == 'coroService'){
	                        errorMessage = checkFinacialTransationForErrors(laborIdToLaborPostRecInternalFTL.get(l.id) , errorMessage, 'Post Recognized Internal Labor');
	                    } 
                    }
                }else if( typeOfLabor == 'LaborMiscReimbursement'){
                    errorMessage = checkFinacialTransationForErrors(laborIdToMiscReimbursementFTL.get(l.id) , errorMessage, 'Misc Reimbursement');
                }
                
                if(laborIdToJournalEntryMap.get(l.id) == null || laborIdToJournalEntryMap.get(l.id).size() == 0 ){
                    if(errorMessage == null || errorMessage == ''){
                        Journal_Entry__c newJE = new Journal_Entry__c(
                            Date__c = Datetime.Now(),
                            Labor__c = l.id,
                            Order__c = l.Related_Work_Order__r.Sold_Order__c
                            );
                            
                            if(typeOfLabor == 'LaborLabor'){
                                if(subTypeOfLabor == 'external'){
                                    newJE.Amount__c = l.External_Labor_Amount__c;
                                    newJE.Baan_Business_Partner_Number__c = l.Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c;
                                    if(typeOfOrder == 'coroRecordType' || typeOfOrder == 'changeOrder'){
	                                    newJE.Type__c = 'External Labor';
	                                    newJE.Debit_General_Ledger_Account__c = laborIdToLaborExternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
	                                    newJE.Credit_General_Ledger_Account__c = laborIdToLaborExternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                                    }else if(typeOfOrder == 'coroService'){
                                    	if (JIPLabor == 'true') {
                                    		newJE.Type__c = 'Service External Labor - JIP'; 
	                                    	newJE.Debit_General_Ledger_Account__c = laborIdToServiceLaborExternalJIPFTL.get(l.id)[0].Debit_Account_Number__r.Name;
	                                    	newJE.Credit_General_Ledger_Account__c = laborIdToServiceLaborExternalJIPFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                                    	}
                                    	else {
                                    		newJE.Type__c = 'Service External Labor'; 
	                                    	newJE.Debit_General_Ledger_Account__c = laborIdToServiceLaborExternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
	                                    	newJE.Credit_General_Ledger_Account__c = laborIdToServiceLaborExternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;                                    	
                                    	}	
                                    }
                                }else if(subTypeOfLabor == 'internal'){
                                    newJe.Amount__c = l.Internal_Cost__c;
                                    if(typeOfOrder == 'coroRecordType' || typeOfOrder == 'changeOrder' || typeOfOrder == 'coroService'){
	                                    newJE.Type__c = 'Internal Labor';
	                                    newJE.Debit_General_Ledger_Account__c = laborIdToLaborFTL.get(l.id)[0].Debit_Account_Number__r.Name;
	                                    newJE.Credit_General_Ledger_Account__c = laborIdToLaborFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                                    }
                                    /*
                                    else if(typeOfOrder == 'coroService'){
                                    	newJE.Type__c = 'Service Internal Labor';
	                                    newJE.Debit_General_Ledger_Account__c = laborIdToServiceLaborFTL.get(l.id)[0].Debit_Account_Number__r.Name;
	                                    newJE.Credit_General_Ledger_Account__c = laborIdToServiceLaborFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                                    }
                                    */
                                }
                            }else if(typeOfLabor == 'PostRecLabor'){
                                if(subTypeOfLabor == 'external'){
                                	if(typeOfOrder == 'coroService'){
	                                    newJE.Amount__c = l.External_Labor_Amount__c;
	                                    newJE.Baan_Business_Partner_Number__c = l.Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c;
                                    	if (JIPLabor == 'true') {
	                                		newJE.Type__c = 'Post Recognized Service External Labor - JIP';
		                                    newJE.Debit_General_Ledger_Account__c = laborIdToLaborPostRecServiceExternalJIPFTL.get(l.id)[0].Debit_Account_Number__r.Name;
		                                    newJE.Credit_General_Ledger_Account__c = laborIdToLaborPostRecServiceExternalJIPFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                                    	}
										else {
	                                		newJE.Type__c = 'Post Recognized Service External Labor';
		                                    newJE.Debit_General_Ledger_Account__c = laborIdToLaborPostRecServiceExternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
		                                    newJE.Credit_General_Ledger_Account__c = laborIdToLaborPostRecServiceExternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;											
										}
                                	}else if(typeOfOrder == 'coroRecordType' || typeOfOrder == 'changeOrder'){
					                    newJE.Type__c = 'Post Recognized External Labor';
	                                    newJE.Amount__c = l.External_Labor_Amount__c;
	                                    newJE.Baan_Business_Partner_Number__c = l.Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c;
	                                    newJE.Debit_General_Ledger_Account__c = laborIdToLaborPostRecExternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
	                                    newJE.Credit_General_Ledger_Account__c = laborIdToLaborPostRecExternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                                	}
                                    
                                    
                                }
                 				
                                else if(subTypeOfLabor == 'internal'){  
                                    newJe.Amount__c = l.Internal_Cost__c;
                                    if(typeOfOrder == 'coroRecordType' || typeOfOrder == 'changeOrder' || typeOfOrder == 'coroService'){
	                                    newJE.Type__c = 'Post Recognized Internal Labor';
	                                    newJE.Debit_General_Ledger_Account__c = laborIdToLaborPostRecInternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
	                                    newJE.Credit_General_Ledger_Account__c = laborIdToLaborPostRecInternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                                    }
                                    /*
                                    else if(typeOfOrder == 'coroService'){
                                    	newJE.Type__c = 'Post Recognized Service Internal Labor';
	                                    newJE.Debit_General_Ledger_Account__c = laborIdToPostRecServiceInternalLaborFTL.get(l.id)[0].Debit_Account_Number__r.Name;
	                                    newJE.Credit_General_Ledger_Account__c = laborIdToPostRecServiceInternalLaborFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                                    }
                                    */
                                }
                            }else if(typeOfLabor == 'LaborMiscReimbursement'){
                                newJE.Type__c = 'Misc Reimbursement';
                                newJE.Amount__c = l.External_Labor_Amount__c;
                                newJE.Baan_Business_Partner_Number__c = l.Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c;
                                
                                newJE.Debit_General_Ledger_Account__c = laborIdToMiscReimbursementGLAmap.get(l.id);
                                newJE.Credit_General_Ledger_Account__c = laborIdToMiscReimbursementFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                            }
                        
                        journalEntriesToUpsert.add(newJE);
                    }else{
                        //there is an error message
                        mapNew.get(l.id).addError(errorMessage, FALSE);
                    }
                }else{ 
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
									if(subTypeOfLabor == 'external'){
	                                    je.Amount__c = l.External_Labor_Amount__c;
	                                    je.Baan_Business_Partner_Number__c = l.Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c;
	                                    if(typeOfOrder == 'coroRecordType' || typeOfOrder == 'changeOrder'){
		                                    je.Type__c = 'External Labor';
		                                    je.Debit_General_Ledger_Account__c = laborIdToLaborExternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
		                                    je.Credit_General_Ledger_Account__c = laborIdToLaborExternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;
	                                    }else if(typeOfOrder == 'coroService'){
	                                    	if(JIPLabor == 'true') {
	                                    		je.Type__c = 'Service External Labor - JIP';
		                                    	je.Debit_General_Ledger_Account__c = laborIdToServiceLaborExternalJIPFTL.get(l.id)[0].Debit_Account_Number__r.Name;
		                                    	je.Credit_General_Ledger_Account__c = laborIdToServiceLaborExternalJIPFTL.get(l.id)[0].Credit_Account_Number__r.Name;
	                                    	} 
	                                    	else {
	                                    		je.Type__c = 'Service External Labor';
		                                    	je.Debit_General_Ledger_Account__c = laborIdToServiceLaborExternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
		                                    	je.Credit_General_Ledger_Account__c = laborIdToServiceLaborExternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;	                                    		
	                                    	}
	                                    }
	                                }else if(subTypeOfLabor == 'internal'){
	                                    je.Amount__c = l.Internal_Cost__c;
	                                    if(typeOfOrder == 'coroRecordType' || typeOfOrder == 'changeOrder' || typeOfOrder == 'coroService'){
		                                    je.Type__c = 'Internal Labor';
		                                    je.Debit_General_Ledger_Account__c = laborIdToLaborFTL.get(l.id)[0].Debit_Account_Number__r.Name;
		                                    je.Credit_General_Ledger_Account__c = laborIdToLaborFTL.get(l.id)[0].Credit_Account_Number__r.Name;
	                           			}
	                                    /*
	                                    else if(typeOfOrder == 'coroService'){
	                                    	je.Type__c = 'Service Internal Labor';
		                                    je.Debit_General_Ledger_Account__c = laborIdToServiceLaborFTL.get(l.id)[0].Debit_Account_Number__r.Name;
		                                    je.Credit_General_Ledger_Account__c = laborIdToServiceLaborFTL.get(l.id)[0].Credit_Account_Number__r.Name;
	                                    } 
	                                    */
									}
                                }else if(typeOfLabor == 'PostRecLabor'){
                                	 if(subTypeOfLabor == 'external'){
                                	 	if(typeOfOrder == 'coroService'){
		                                    je.Amount__c = l.External_Labor_Amount__c;
	                                    	je.Baan_Business_Partner_Number__c = l.Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c;
	                                		if(JIPLabor == 'true') {
		                                		je.Type__c = 'Post Recognized Service External Labor - JIP';
		                                    	je.Debit_General_Ledger_Account__c = laborIdToLaborPostRecServiceExternalJIPFTL.get(l.id)[0].Debit_Account_Number__r.Name;
		                                    	je.Credit_General_Ledger_Account__c = laborIdToLaborPostRecServiceExternalJIPFTL.get(l.id)[0].Credit_Account_Number__r.Name;	                                			
	                                		}
	                                		else {
		                                		je.Type__c = 'Post Recognized Service External Labor';
		                                    	je.Debit_General_Ledger_Account__c = laborIdToLaborPostRecServiceExternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
		                                    	je.Credit_General_Ledger_Account__c = laborIdToLaborPostRecServiceExternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;	                                			
	                                		}
	                                	}else if(typeOfOrder == 'coroRecordType' || typeOfOrder == 'changeOrder'){
						                    je.Type__c = 'Post Recognized External Labor';
		                                    je.Amount__c = l.External_Labor_Amount__c;
		                                    je.Baan_Business_Partner_Number__c = l.Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c;
		                                    je.Debit_General_Ledger_Account__c = laborIdToLaborPostRecExternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
		                                    je.Credit_General_Ledger_Account__c = laborIdToLaborPostRecExternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;
	                                	}
                                    }
                                    
                                    else if(subTypeOfLabor == 'internal'){
	                                    je.Amount__c = l.Internal_Cost__c;
	                                    if(typeOfOrder == 'coroRecordType' || typeOfOrder == 'changeOrder' || typeOfOrder == 'coroService'){
		                                    je.Type__c = 'Post Recognized Internal Labor';
		                                    je.Debit_General_Ledger_Account__c = laborIdToLaborPostRecInternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
		                                    je.Credit_General_Ledger_Account__c = laborIdToLaborPostRecInternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;
	                                    }
	                                    /*
	                                    else if(typeOfOrder == 'coroService'){
	                                    	je.Type__c = 'Post Recognized Service Internal Labor';
		                                    je.Debit_General_Ledger_Account__c = laborIdToPostRecServiceInternalLaborFTL.get(l.id)[0].Debit_Account_Number__r.Name;
		                                    je.Credit_General_Ledger_Account__c = laborIdToPostRecServicePostRecInternalLaborFTL.get(l.id)[0].Credit_Account_Number__r.Name;
	                                    }
	                                    */
            						}


                                }else if(typeOfLabor == 'LaborMiscReimbursement'){
                                    je.Type__c = 'Misc Reimbursement';
                                    je.Amount__c = l.External_Labor_Amount__c;
                                    je.Baan_Business_Partner_Number__c = l.Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c;
                                    
                                	je.Debit_General_Ledger_Account__c = laborIdToMiscReimbursementGLAmap.get(l.id);
                                    je.Credit_General_Ledger_Account__c = laborIdToMiscReimbursementFTL.get(l.id)[0].Credit_Account_Number__r.Name;

                                }
    
                                journalEntriesToUpsert.add(je);
                            }
                            
                        }//end if only one journal entery
                        
                    }else{
                        //there is an error message
                        mapNew.get(l.id).addError(errorMessage, FALSE);
                    }
                    
                }//end of if there is related journal entery 
                    
            }//END IF typeOfLabor == NULL
        }//END OF LABOR FOR LOOP
        system.debug('ads journalEntriesToUpsert: '+journalEntriesToUpsert);
        upsert journalEntriesToUpsert;
    }//END createOrUpdateJournalEntryLabor Method

    
    /***************************************************
     Method to create or update Journal Entry for ASSET
    ****************************************************/
    public void createOrUpdateJournalEntryAsset(list<Asset> listNew, map<id, Asset> mapNew, map<id, Asset> mapOld, String triggerType ){    
        Id assetInstalledProductsRecordTypeId = UtilityMethods.retrieveRecordTypeId('Installed_Products', 'Asset');
        Id assetServiceProductsRecordTypeId = UtilityMethods.retrieveRecordTypeId('Service_Products', 'Asset');
        Id assetCostProductsRecordTypeId = UtilityMethods.retrieveRecordTypeId('Cost_Products', 'Asset');

        list<Id> RecordTypeIds = new list<Id>();
        RecordTypeIds.add(assetInstalledProductsRecordTypeId);
        RecordTypeIds.add(assetServiceProductsRecordTypeId);
        RecordTypeIds.add(assetCostProductsRecordTypeId);
        
        list<Journal_Entry__c> journalEntriesToUpsert = new list<Journal_Entry__c>();
        list<Journal_Entry__c> journalEntriesToDelete = new list<Journal_Entry__c>();
       
        list<Asset> extraFieldsList = [SELECT       id,
                                                    Unit_Wholesale_Cost__c,
                                                    Quantity,
                                                    Sold_Order__c,
                                                    Sold_Order__r.BillToContactId,
                                                    Sold_Order__r.RecordTypeId,
                                                    Sold_Order__r.Store_Location__c,
                                                    Sold_Order__r.Revenue_Recognized_Date__c,
                                                    Vendor__c,
                                                    Vendor__r.Name,
                                                    Vendor__r.Vendor_Account_Type__c,
                                                    Vendor__r.Baan_Business_Partner_Number__c,
                                                    RecordTypeId,
                                                    Store_Location__c,
                                                    Store_Location__r.Active_Store_Configuration__c,
                                                    Quantity_Written_Off__c,
                                                    Original_Order_Product__c,
                                                    Original_Order_Product__r.Remake__c,
                                                    Original_Order_Product__r.GL_Account__c,
                                                    Vendor_Credit__c
                                                    
                                                    FROM Asset WHERE Id IN :mapNew.keyset() AND RecordTypeId IN :RecordTypeIds AND Sold_Order__r.RecordTypeId IN :orderRecordTypes];        
        
        
        map<Id, list<Journal_Entry__c>> assetIdToJournalEntryMap = linkJournalEntries(extraFieldsList);

        //INVENTORY Received JOURNAL ENTERY
        map<Id, list<Journal_Entry__c>> assetIdToIRIntercompanyJEM = new map<Id, list<Journal_Entry__c>>();
        map<Id, list<Journal_Entry__c>> assetIdToIRExternalVendorJEM = new map<Id, list<Journal_Entry__c>>();
       	//POST RECOGNITION INVENTORY Received JOURNAL ENTERY
        map<Id, list<Journal_Entry__c>> assetIdToPRIRIntercompanyJEM = new map<Id, list<Journal_Entry__c>>();
        map<Id, list<Journal_Entry__c>> assetIdToPRIRExternalVendorJEM = new map<Id, list<Journal_Entry__c>>();
        
        map<Id, list<Journal_Entry__c>> assetIdToInventoryWriteOffJournalEntryMap = new map<Id, list<Journal_Entry__c>>();

		//MAKING MAPS OF ASSET ID TO DIFFERENT TYPES OF FINANCIAL TRANSACION LISTS
        
        /*
        map<Id, list<Financial_Transaction__c>>  assetIdToInventoryWriteOffFTL = linkFinacialTransactions(extraFieldsList, 'Inventory Write-Off');
        
        //INVENTORY Received FINANCIAL TRANSATION
        map<Id, list<Financial_Transaction__c>>  assetIdToIRIntercompanyFTL = linkFinacialTransactions(extraFieldsList, 'Inventory Received - Intercompany');
        map<Id, list<Financial_Transaction__c>>  assetIdToIRIntercompanyCCFTL = linkFinacialTransactions(extraFieldsList, 'Inventory Received - Intercompany Consolidation Center');
        map<Id, list<Financial_Transaction__c>>  assetIdToIRExternalVendorFTL = linkFinacialTransactions(extraFieldsList, 'Inventory Received - External Vendor');
        
        //Service Material Returned
        map<Id, list<Financial_Transaction__c>>  assetIdToSMRIntercompanyFTL = linkFinacialTransactions(extraFieldsList, 'Service Material Returned - Intercompany');
        map<Id, list<Financial_Transaction__c>>  assetIdToSMRIntercompanyCCFTL = linkFinacialTransactions(extraFieldsList, 'Service Material Returned - Intercompany Consolidation Center');
        map<Id, list<Financial_Transaction__c>>  assetIdToSMRExternalVendorFTL = linkFinacialTransactions(extraFieldsList, 'Service Material Returned - External Vendor');
 		
 		//Service Inventory Received
        map<Id, list<Financial_Transaction__c>>  assetIdToSIRIntercompanyFTL = linkFinacialTransactions(extraFieldsList, 'Service Inventory Received - Intercompany');
        map<Id, list<Financial_Transaction__c>>  assetIdToSIRIntercompanyCCFTL = linkFinacialTransactions(extraFieldsList, 'Service Inventory Received - Intercompany Consolidation Center');
        map<Id, list<Financial_Transaction__c>>  assetIdToSIRExternalVendorFTL = linkFinacialTransactions(extraFieldsList, 'Service Inventory Received - External Vendor');
 		
 		//Cost Product Received 
 		map<Id, list<Financial_Transaction__c>>  assetIdToCPRFTL = linkFinacialTransactions(extraFieldsList, 'Cost Product Received');
       */
       
       list<string> financialTransactionTypesToGet = new list<string>{	'Inventory Write-Off', 
        																'Inventory Received - Intercompany', 
        																'Inventory Received - Intercompany Consolidation Center',
        																'Inventory Received - External Vendor',
        																'Service Inventory Received - Intercompany',
        																'Service Inventory Received - Intercompany Consolidation Center',
        																'Service Inventory Received - External Vendor',
        																'Service Inventory Received - Remake Intercompany',
        																'Service Inventory Received - Remake Intercompany Consolidation Center',
        																'Service Inventory Received - Remake External Vendor',
        																'Cost Product Received'
        																};
       	map<string, map<Id, list<Financial_Transaction__c>>> typeToMapOfAssetIdtoListFT = linkFinancialTransactions(extraFieldsList, financialTransactionTypesToGet);
        
        //Inventory Write-Off
       	map<Id, list<Financial_Transaction__c>>  assetIdToInventoryWriteOffFTL = typeToMapOfAssetIdtoListFT.get('Inventory Write-Off');
        
        //INVENTORY Received FINANCIAL TRANSATION
        map<Id, list<Financial_Transaction__c>>  assetIdToIRIntercompanyFTL = typeToMapOfAssetIdtoListFT.get('Inventory Received - Intercompany');
        map<Id, list<Financial_Transaction__c>>  assetIdToIRIntercompanyCCFTL = typeToMapOfAssetIdtoListFT.get('Inventory Received - Intercompany Consolidation Center');
        map<Id, list<Financial_Transaction__c>>  assetIdToIRExternalVendorFTL = typeToMapOfAssetIdtoListFT.get('Inventory Received - External Vendor');
        
        /*
        //Service Material Returned
        map<Id, list<Financial_Transaction__c>>  assetIdToSMRIntercompanyFTL = typeToMapOfAssetIdtoListFT.get('Service Material Returned - Intercompany');
        map<Id, list<Financial_Transaction__c>>  assetIdToSMRIntercompanyCCFTL = typeToMapOfAssetIdtoListFT.get('Service Material Returned - Intercompany Consolidation Center');
        map<Id, list<Financial_Transaction__c>>  assetIdToSMRExternalVendorFTL = typeToMapOfAssetIdtoListFT.get('Service Material Returned - External Vendor');
 		*/
 		
 		//Service Inventory Received
        map<Id, list<Financial_Transaction__c>>  assetIdToSIRIntercompanyFTL = typeToMapOfAssetIdtoListFT.get('Service Inventory Received - Intercompany');
        map<Id, list<Financial_Transaction__c>>  assetIdToSIRIntercompanyCCFTL = typeToMapOfAssetIdtoListFT.get('Service Inventory Received - Intercompany Consolidation Center');
        map<Id, list<Financial_Transaction__c>>  assetIdToSIRExternalVendorFTL = typeToMapOfAssetIdtoListFT.get('Service Inventory Received - External Vendor');
 		//Service Inventory Received REMAKE
        map<Id, list<Financial_Transaction__c>>  assetIdToSIRRemakeIntercompanyFTL = typeToMapOfAssetIdtoListFT.get('Service Inventory Received - Remake Intercompany');
        map<Id, list<Financial_Transaction__c>>  assetIdToSIRRemakeIntercompanyCCFTL = typeToMapOfAssetIdtoListFT.get('Service Inventory Received - Remake Intercompany Consolidation Center');
        map<Id, list<Financial_Transaction__c>>  assetIdToSIRRemakeExternalVendorFTL = typeToMapOfAssetIdtoListFT.get('Service Inventory Received - Remake External Vendor');
        
 		//Cost Product Received 
 		map<Id, list<Financial_Transaction__c>>  assetIdToCPRFTL = typeToMapOfAssetIdtoListFT.get('Cost Product Received');
       	
       	list<string> jeTypesToGet = new list<string>{	'Inventory Received - External Vendor', 
       													'Cost Product Received',
       													'Service Inventory Received - Intercompany',
       													'Service Inventory Received - Intercompany Consolidation Center',
       													'Service Inventory Received - External Vendor',
       													'Service Inventory Received - Remake Intercompany',
       													'Service Inventory Received - Remake Intercompany Consolidation Center',
       													'Service Inventory Received - Remake External Vendor',
       													'Inventory Returned - External Vendor',
       													'Inventory Returned - Cost Product Received',
       													'Service Inventory Returned - External Vendor',
       													'Service Inventory Returned - Intercompany',
       													'Service Inventory Returned - Intercompany Consolidation Center'};
       	
       	list<Journal_Entry__c> relatedJEForVendorCredit = [SELECT 	Id, 
       																Amount__c,
       																Asset__c,
       																Sent_to_BaanERP__c,
       																Type__c,
       																Store_Location__c,
       																Debit_General_Ledger_Account__c,
       																Credit_General_Ledger_Account__c 
       																FROM Journal_Entry__c WHERE Asset__c IN :mapNew.keySet() AND Type__c IN :jeTypesToGet ORDER BY LastModifiedDate desc];
       																
		map<id, Journal_Entry__c> assetIdToLatestJEforVendorCredit = new map<id, Journal_Entry__c>();

		for(Journal_Entry__c je : relatedJEForVendorCredit){
			if(assetIdToLatestJEforVendorCredit.keySet().contains(je.Asset__c)){
				continue;
			}
			else{
				assetIdToLatestJEforVendorCredit.put(je.Asset__c, je);
			}
		}
       	
       
       
        for(Asset a : extraFieldsList){
        		system.debug('ads assetIdToLatestJEforVendorCredit: ' + assetIdToLatestJEforVendorCredit.get(a.id));
          		string errorMessage;
                string assetSubType;
                if(a.Store_Location__c == null ){ 
                    errorMessage = RMS_errorMessages.STORE_LOCATION_IS_BLANK;
                }
                
                boolean inventoryWriteOffAT = false;
                boolean vendorCreditAT = false;
                boolean inventoryReceivedAT = false;
                boolean serviceInventoryReceivedAT = false;
                boolean costProductRecivedAT = false;
                boolean unitWholeSaleCostChangeAT = false;
				
				boolean serviceInventoryRecivedRemake = a.Original_Order_Product__r.Remake__c; 
				
				System.debug('ads serviceInventoryRecivedRemake: '+serviceInventoryRecivedRemake);
				 
                //CAN'T CHANGE WRITE OFF AND VENDOR CREDIT AT THE SAME TIME
                if((mapOld != null && mapOld.get(a.id).Quantity_Written_Off__c != mapNew.get(a.id).Quantity_Written_Off__c && mapOld.get(a.id).Vendor_Credit__c != mapNew.get(a.id).Vendor_Credit__c)
                	|| (mapOld == null && mapNew.get(a.id).Quantity_Written_Off__c != null && mapNew.get(a.id).Vendor_Credit__c != null)){
                		errorMessage = RMS_errorMessages.CHANGED_WRITE_OFF_AND_VENDOR_CREDIT;
        		}
        		
				if((mapOld != null && mapOld.get(a.id).Quantity_Written_Off__c != mapNew.get(a.id).Quantity_Written_Off__c)
					||(mapOld == null && mapNew.get(a.id).Quantity_Written_Off__c != null)){
						//ONLY IF QUANTITY IS 0 look into
//					if(a.Sold_Order__r.RecordTypeId == assetInstalledProductsRecordTypeId){
					if(a.RecordTypeId == assetInstalledProductsRecordTypeId){
						inventoryWriteOffAT = true;
					}
				}
				
				else if( (mapOld != null && mapOld.get(a.id).Vendor_Credit__c != mapNew.get(a.id).Vendor_Credit__c)
						||(mapOld == null && mapNew.get(a.id).Vendor_Credit__c != null)
						&& (mapNew.get(a.id).Vendor_Credit__c != null)){
					
//					if(a.Sold_Order__r.RecordTypeId != assetInstalledProductsRecordTypeId){
					if(a.RecordTypeId != assetInstalledProductsRecordTypeId){
						if(assetIdToLatestJEforVendorCredit.get(a.id) == null){
							errorMessage = 'A vendor credit cannot be issued on an item that has not been received or is not for an external vendor.';
						}else{
							system.debug('ads fixingVendor vendorCreditAT setting to true: '+vendorCreditAT);
							vendorCreditAT = true;
							
							if(assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Inventory Received - External Vendor' || assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Cost Product Received' ||
								assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Service Inventory Received - External Vendor' ||	assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Service Inventory Received - Intercompany' ||
								assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Service Inventory Received - Intercompany Consolidation Center'){
								assetSubType = 'vendorCreateNew';
							}else if(assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Inventory Returned - External Vendor' || assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Inventory Returned - Cost Product Received' ||
										assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Service Inventory Returned - External Vendor' || assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Service Inventory Returned - Intercompany' ||
										assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Service Inventory Returned - Intercompany Consolidation Center'){
								assetSubType = 'vendorEdit';
							}
						}
					}
				
				}else if((mapOld != null && mapOld.get(a.id).Quantity != mapNew.get(a.id).Quantity)
						||(mapOld == null && mapNew.get(a.id).Quantity != 0 && mapNew.get(a.id).Unit_Wholesale_Cost__c != 0)){
					//quantity has to change.
					if(mapNew.get(a.id).RecordTypeId == assetInstalledProductsRecordTypeId){
                		inventoryReceivedAT = true;
					}
					if(mapNew.get(a.id).RecordTypeId == assetServiceProductsRecordTypeId){
                		serviceInventoryReceivedAT = true;
					}
					if(mapNew.get(a.id).RecordTypeId == assetCostProductsRecordTypeId){
                		costProductRecivedAT = true;
					}
                }
                
                else if(mapOld != null && mapOld.get(a.id).Unit_Wholesale_Cost__c != mapNew.get(a.id).Unit_Wholesale_Cost__c){
                	
                	if(mapNew.get(a.id).RecordTypeId == assetInstalledProductsRecordTypeId){
                		inventoryReceivedAT = true;
					}
					if(mapNew.get(a.id).RecordTypeId == assetServiceProductsRecordTypeId){
                		serviceInventoryReceivedAT = true;
					}
					if(mapNew.get(a.id).RecordTypeId == assetCostProductsRecordTypeId){
//                		if(a.Sold_Order__r.RecordTypeId == assetCostProductsRecordTypeId){
                		if(a.RecordTypeId == assetCostProductsRecordTypeId){
                			costProductRecivedAT = true;
                		}
					}
                	if(a.Quantity_Written_Off__c != null){
//	                	if(a.Sold_Order__r.RecordTypeId == assetInstalledProductsRecordTypeId){
	                	if(a.RecordTypeId == assetInstalledProductsRecordTypeId){
	                		inventoryWriteOffAT = true;
	                	}
                	}
                	
                }
                system.debug('ads serviceInventoryReceivedAT: '+serviceInventoryReceivedAT);
                system.debug('ads a.Sold_Order__r.Revenue_Recognized_Date__c: ' +a.Sold_Order__r.Revenue_Recognized_Date__c);
                system.debug('ads a.Vendor__r.Vendor_Account_Type__c: ' +a.Vendor__r.Vendor_Account_Type__c);
                if(vendorCreditAT == false){
	                if(a.Sold_Order__r.Revenue_Recognized_Date__c == null && a.Vendor__r.Vendor_Account_Type__c == 'Intercompany'){
	            		assetSubType = 'Intercompany';
	            	}else if(a.Sold_Order__r.Revenue_Recognized_Date__c == null && a.Vendor__r.Vendor_Account_Type__c == 'Intercompany Consolidation Center'){
	            		assetSubType = 'IntercompanyCC';
	            	}else if(a.Sold_Order__r.Revenue_Recognized_Date__c == null && a.Vendor__r.Vendor_Account_Type__c == 'External'){
	            		assetSubType = 'ExternalVendor';
	            	}
                }
                errorMessage = checkAssetForErrors(a, errorMessage, assetSubType, vendorCreditAT);
                
                //INVENTORY RECEIVED
                if(inventoryReceivedAT == true){
                	if(assetSubType == 'Intercompany'){
	                	errorMessage = checkFinacialTransationForErrors(assetIdToIRIntercompanyFTL.get(a.id) , errorMessage, 'Inventory Received - Intercompany');
                	}
                	if(assetSubType == 'IntercompanyCC'){
	                	errorMessage = checkFinacialTransationForErrors(assetIdToIRIntercompanyCCFTL.get(a.id) , errorMessage, 'Inventory Received - Intercompany Consolidation Center');
                	}
                	if(assetSubType == 'ExternalVendor'){
	                	errorMessage = checkFinacialTransationForErrors(assetIdToIRExternalVendorFTL.get(a.id) , errorMessage, 'Inventory Received - External Vendor');
                	}
                }
                if(serviceInventoryReceivedAT == true){
                	system.debug('ads serviceInventoryReceivedAT assetSubType: '+assetSubType);
                	if(assetSubType == 'Intercompany'){
                		if(serviceInventoryRecivedRemake == true){
                			errorMessage = checkFinacialTransationForErrors(assetIdToSIRRemakeIntercompanyFTL.get(a.id) , errorMessage, 'Service Inventory Received - Remake Intercompany');
                		}else{
	                		errorMessage = checkFinacialTransationForErrors(assetIdToSIRIntercompanyFTL.get(a.id) , errorMessage, 'Service Inventory Received - Intercompany');
                		}
                	}
                	if(assetSubType == 'IntercompanyCC'){
                		if(serviceInventoryRecivedRemake == true){
                			errorMessage = checkFinacialTransationForErrors(assetIdToSIRRemakeIntercompanyCCFTL.get(a.id) , errorMessage, 'Service Inventory Received - Remake Intercompany Consolidation Center');
                		}else{
	                		errorMessage = checkFinacialTransationForErrors(assetIdToSIRIntercompanyCCFTL.get(a.id) , errorMessage, 'Service Inventory Received - Intercompany Consolidation Center');
                		}
                	}
                	if(assetSubType == 'ExternalVendor'){
                		if(serviceInventoryRecivedRemake == true){
                			errorMessage = checkFinacialTransationForErrors(assetIdToSIRRemakeExternalVendorFTL.get(a.id) , errorMessage, 'Service Inventory Received - Remake External Vendor');
                		}else{
	                		errorMessage = checkFinacialTransationForErrors(assetIdToSIRExternalVendorFTL.get(a.id) , errorMessage, 'Service Inventory Received - External Vendor');
                		}
                	}
                }
                //COST PRODUCT RECIVED
                if(costProductRecivedAT == true){
                	errorMessage = checkFinacialTransationForErrors(assetIdToCPRFTL.get(a.id) , errorMessage, 'Cost Product Received');
                }
                
            	/*
                //SERVICE MATERIAL RETURNED		
                if(vendorCreditAT == true){
                	if(assetSubType == 'Intercompany'){
	                	errorMessage = checkFinacialTransationForErrors(assetIdToSMRIntercompanyFTL.get(a.id) , errorMessage, 'Service Material Returned - Intercompany');
                	}
                	if(assetSubType == 'IntercompanyCC'){
	                	errorMessage = checkFinacialTransationForErrors(assetIdToSMRIntercompanyCCFTL.get(a.id) , errorMessage, 'Service Material Returned - Intercompany Consolidation Center');
                	}
                	if(assetSubType == 'ExternalVendor'){
	                	errorMessage = checkFinacialTransationForErrors(assetIdToSMRExternalVendorFTL.get(a.id) , errorMessage, 'Service Material Returned - External Vendor');
                	}
                }
            	*/
                //INVENTORY WRITE OFF	
                if(inventoryWriteOffAT == true){
                	errorMessage = checkFinacialTransationForErrors(assetIdToInventoryWriteOffFTL.get(a.id) , errorMessage, 'Inventory Write-Off');
                }

                //SETTING UP MAPS TO CHECK IF CREDIT/DEBIT ACCOUNTS HAVE BEEN SWITCHED FOR CALCULATIONS
	    		map<string, string> jeTypeToFTCreditNumber = new map<string,string>();
				map<string, string> jeTypeToFTDebitNumber = new map<string,string>();	
   				
   				//INVENTROY RECIVED
   				if(assetIdToIRIntercompanyFTL.get(a.id) != null && assetIdToIRIntercompanyFTL.get(a.id).size() == 1){
   					jeTypeToFTCreditNumber.put('Inventory Received - Intercompany', assetIdToIRIntercompanyFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   					jeTypeToFTDebitNumber.put('Inventory Received - Intercompany', assetIdToIRIntercompanyFTL.get(a.id)[0].Debit_Account_Number__r.Name);
   				}
   				if(assetIdToIRIntercompanyCCFTL.get(a.id) != null && assetIdToIRIntercompanyCCFTL.get(a.id).size() == 1){
   					jeTypeToFTCreditNumber.put('Inventory Received - Intercompany Consolidation Center', assetIdToIRIntercompanyCCFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   					jeTypeToFTDebitNumber.put('Inventory Received - Intercompany Consolidation Center', assetIdToIRIntercompanyCCFTL.get(a.id)[0].Debit_Account_Number__r.Name);
   				}
				if(assetIdToIRIntercompanyFTL.get(a.id) != null && assetIdToIRIntercompanyFTL.get(a.id).size() == 1){
					jeTypeToFTCreditNumber.put('Inventory Received - External Vendor', assetIdToIRIntercompanyFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   					jeTypeToFTDebitNumber.put('Inventory Received - External Vendor', assetIdToIRIntercompanyFTL.get(a.id)[0].Debit_Account_Number__r.Name);
   					
   					//FOR VENDOR CREDIT
   					jeTypeToFTCreditNumber.put('Inventory Returned - External Vendor', assetIdToIRIntercompanyFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   					jeTypeToFTDebitNumber.put('Inventory Returned - External Vendor', assetIdToIRIntercompanyFTL.get(a.id)[0].Debit_Account_Number__r.Name);
				}
				
				//SERVICE INVENTORY Received
				if(assetIdToSIRIntercompanyFTL.get(a.id) != null && assetIdToSIRIntercompanyFTL.get(a.id).size() == 1){
					if(serviceInventoryRecivedRemake == true){	
						jeTypeToFTCreditNumber.put('Service Inventory Received - Remake Intercompany', assetIdToSIRRemakeIntercompanyFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   						jeTypeToFTDebitNumber.put('Service Inventory Received - Remake Intercompany', assetIdToSIRRemakeIntercompanyFTL.get(a.id)[0].Debit_Account_Number__r.Name);
					}else{
						jeTypeToFTCreditNumber.put('Service Inventory Received - Intercompany', assetIdToSIRIntercompanyFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   						jeTypeToFTDebitNumber.put('Service Inventory Received - Intercompany', assetIdToSIRIntercompanyFTL.get(a.id)[0].Debit_Account_Number__r.Name);
					}
				}
				if(assetIdToSIRIntercompanyCCFTL.get(a.id) != null && assetIdToSIRIntercompanyCCFTL.get(a.id).size() == 1){
   					if(serviceInventoryRecivedRemake == true){	
						jeTypeToFTCreditNumber.put('Service Inventory Received - Remake Intercompany Consolidation Center', assetIdToSIRRemakeIntercompanyCCFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   						jeTypeToFTDebitNumber.put('Service Inventory Received - Remake Intercompany Consolidation Center', assetIdToSIRRemakeIntercompanyCCFTL.get(a.id)[0].Debit_Account_Number__r.Name);
				}else{
   						jeTypeToFTCreditNumber.put('Service Inventory Received - Intercompany Consolidation Center', assetIdToSIRIntercompanyCCFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   						jeTypeToFTDebitNumber.put('Service Inventory Received - Intercompany Consolidation Center', assetIdToSIRIntercompanyCCFTL.get(a.id)[0].Debit_Account_Number__r.Name);
   					}
   				}
				if(assetIdToSIRExternalVendorFTL.get(a.id) != null && assetIdToSIRExternalVendorFTL.get(a.id).size() == 1){
					if(serviceInventoryRecivedRemake == true){	
						jeTypeToFTCreditNumber.put('Service Inventory Received - Remake External Vendor', assetIdToSIRRemakeExternalVendorFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   						jeTypeToFTDebitNumber.put('Service Inventory Received - Remake External Vendor', assetIdToSIRRemakeExternalVendorFTL.get(a.id)[0].Debit_Account_Number__r.Name);
					}else{
						jeTypeToFTCreditNumber.put('Service Inventory Received - External Vendor', assetIdToSIRExternalVendorFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   						jeTypeToFTDebitNumber.put('Service Inventory Received - External Vendor', assetIdToSIRExternalVendorFTL.get(a.id)[0].Debit_Account_Number__r.Name);
					}
				}
				
				//COST PRODUCT RECIVED
				if(assetIdToCPRFTL.get(a.id) != null && assetIdToCPRFTL.get(a.id).size() == 1){
					//jeTypeToFTCreditNumber.put('Cost Product Received', assetIdToCPRFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   					jeTypeToFTDebitNumber.put('Cost Product Received', assetIdToCPRFTL.get(a.id)[0].Debit_Account_Number__r.Name);

					//FOR VENDOR CREDIT
					//jeTypeToFTCreditNumber.put('Inventory Returned - Cost Product Received', assetIdToCPRFTL.get(a.id)[0].Credit_Account_Number__r.Name);
					jeTypeToFTDebitNumber.put('Inventory Returned - Cost Product Received', assetIdToCPRFTL.get(a.id)[0].Credit_Account_Number__r.Name);
				}

				/*
				//SERVICE MATERIAL RETURNED
				if(assetIdToSMRIntercompanyFTL.get(a.id) != null && assetIdToSMRIntercompanyFTL.get(a.id).size() == 1){
					jeTypeToFTCreditNumber.put('Service Material Returned - Intercompany', assetIdToSMRIntercompanyFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   					jeTypeToFTDebitNumber.put('Service Material Returned - Intercompany', assetIdToSMRIntercompanyFTL.get(a.id)[0].Debit_Account_Number__r.Name);
				}
				if(assetIdToSMRIntercompanyCCFTL.get(a.id) != null && assetIdToSMRIntercompanyCCFTL.get(a.id).size() == 1){
   					jeTypeToFTCreditNumber.put('Service Material Returned - Intercompany Consolidation Center', assetIdToIRIntercompanyCCFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   					jeTypeToFTDebitNumber.put('Service Material Returned - Intercompany Consolidation Center', assetIdToIRIntercompanyCCFTL.get(a.id)[0].Debit_Account_Number__r.Name);
   				}
				if(assetIdToSMRExternalVendorFTL.get(a.id) != null && assetIdToSMRExternalVendorFTL.get(a.id).size() == 1){
					jeTypeToFTCreditNumber.put('Service Material Returned - External Vendor', assetIdToIRExternalVendorFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   					jeTypeToFTDebitNumber.put('Service Material Returned - External Vendor', assetIdToIRExternalVendorFTL.get(a.id)[0].Debit_Account_Number__r.Name);
				}
				*/
				
                //IF VALUES ARE NULL THEN SET THEM TO 0
          		decimal oldQuantity = 0;
          		if(mapOld != null && mapOld.get(a.id).Quantity != null){
          			oldQuantity = mapOld.get(a.id).Quantity;
          		}
                decimal newQuantity = 0;
                if(mapNew != null && mapNew.get(a.id).Quantity != null){
                	newQuantity = mapNew.get(a.id).Quantity;
                }
                decimal oldQuantityWrittenOff = 0;
                if(mapOld != null && mapOld.get(a.id).Quantity_Written_Off__c != null){
                	oldQuantityWrittenOff = mapOld.get(a.id).Quantity_Written_Off__c;
                } 
                decimal newQuantityWrittenOff = 0;
                if(mapNew != null && mapNew.get(a.id).Quantity_Written_Off__c != null){
                	newQuantityWrittenOff = mapNew.get(a.id).Quantity_Written_Off__c;
                }
                decimal oldVendorCredit = 0;
                if(mapOld != null && mapOld.get(a.id).Vendor_Credit__c != null){
                	oldVendorCredit = mapOld.get(a.id).Vendor_Credit__c;
                }
                decimal newVendorCredit = 0;
                if(mapNew != null && mapNew.get(a.id).Vendor_Credit__c != null){
                	newVendorCredit = mapNew.get(a.id).Vendor_Credit__c;
                }
               
                
                if(errorMessage == null || errorMessage == ''){
		           
		           list<wrapAssetVariable> wrapAssetVariableList = new list<wrapAssetVariable>();
		           String aType;
		           String jType; 
		           String debitAccountN;
		           String creditAccountN;
		           String baanBPN;
		           if(inventoryReceivedAT == true){
						aType = 'InventoryReceived';
						if(assetSubType == 'Intercompany'){
	                        jType = 'Inventory Received - Intercompany';
	                        debitAccountN = assetIdToIRIntercompanyFTL.get(a.id)[0].Debit_Account_Number__r.Name;
	                        creditAccountN = assetIdToIRIntercompanyFTL.get(a.id)[0].Credit_Account_Number__r.Name;
						}else if(assetSubType == 'IntercompanyCC'){
	                        jType = 'Inventory Received - Intercompany Consolidation Center';
	                        debitAccountN = assetIdToIRIntercompanyCCFTL.get(a.id)[0].Debit_Account_Number__r.Name;
	                        creditAccountN = assetIdToIRIntercompanyCCFTL.get(a.id)[0].Credit_Account_Number__r.Name;
						}else if(assetSubType == 'ExternalVendor'){
							jType = 'Inventory Received - External Vendor';
	                        baanBPN = a.vendor__r.Baan_Business_Partner_Number__c;
	                        debitAccountN = assetIdToIRExternalVendorFTL.get(a.id)[0].Debit_Account_Number__r.Name;
	                        creditAccountN = assetIdToIRExternalVendorFTL.get(a.id)[0].Credit_Account_Number__r.Name;
						}
						wrapAssetVariable wAR = new wrapAssetVariable(aType, jType, creditAccountN, debitAccountN);
               			wrapAssetVariableList.add(wAR);
					}
					
					if(serviceInventoryReceivedAT == true){
						aType = 'ServiceInventoryReceived';
						if(assetSubType == 'Intercompany'){
	                        jType = 'Service Inventory Received - Intercompany';
	                        if(serviceInventoryRecivedRemake == true){
	                        	debitAccountN = assetIdToSIRRemakeIntercompanyFTL.get(a.id)[0].Debit_Account_Number__r.Name;
		                        creditAccountN = assetIdToSIRRemakeIntercompanyFTL.get(a.id)[0].Credit_Account_Number__r.Name;
	                        }else{
		                        debitAccountN = assetIdToSIRIntercompanyFTL.get(a.id)[0].Debit_Account_Number__r.Name;
		                        creditAccountN = assetIdToSIRIntercompanyFTL.get(a.id)[0].Credit_Account_Number__r.Name;
	                        }
						}else if(assetSubType == 'IntercompanyCC'){
	                        jType = 'Service Inventory Received - Intercompany Consolidation Center';
	                         if(serviceInventoryRecivedRemake == true){
	                        	debitAccountN = assetIdToSIRRemakeIntercompanyCCFTL.get(a.id)[0].Debit_Account_Number__r.Name;
		                        creditAccountN = assetIdToSIRRemakeIntercompanyCCFTL.get(a.id)[0].Credit_Account_Number__r.Name;
	                        }else{
		                        debitAccountN = assetIdToSIRIntercompanyCCFTL.get(a.id)[0].Debit_Account_Number__r.Name;
		                        creditAccountN = assetIdToSIRIntercompanyCCFTL.get(a.id)[0].Credit_Account_Number__r.Name;
							}
	                 	}else if(assetSubType == 'ExternalVendor'){
							jType = 'Service Inventory Received - External Vendor';
	                        baanBPN = a.vendor__r.Baan_Business_Partner_Number__c;
	                        
	                        if(serviceInventoryRecivedRemake == true){
	                        	debitAccountN = assetIdToSIRRemakeExternalVendorFTL.get(a.id)[0].Debit_Account_Number__r.Name;
	                        	creditAccountN = assetIdToSIRRemakeExternalVendorFTL.get(a.id)[0].Credit_Account_Number__r.Name;
	                        }else{
	                        	debitAccountN = assetIdToSIRExternalVendorFTL.get(a.id)[0].Debit_Account_Number__r.Name;
	                        	creditAccountN = assetIdToSIRExternalVendorFTL.get(a.id)[0].Credit_Account_Number__r.Name;
	                        }
						}
						wrapAssetVariable wAR = new wrapAssetVariable(aType, jType, creditAccountN, debitAccountN);
               			wrapAssetVariableList.add(wAR);
					}
					
					if(costProductRecivedAT == true){
						aType = 'CostProductReceived';
                        jType = 'Cost Product Received';
                        debitAccountN = a.Original_Order_Product__r.GL_Account__c;
                        creditAccountN = assetIdToCPRFTL.get(a.id)[0].Credit_Account_Number__r.Name;
						
						wrapAssetVariable wAR = new wrapAssetVariable(aType, jType, creditAccountN, debitAccountN);
               			wrapAssetVariableList.add(wAR);
					}
					
					if(inventoryWriteOffAT == true){
						aType = 'InventoryWriteOff';
						jType = 'Inventory Write-Off';
                        debitAccountN = assetIdToInventoryWriteOffFTL.get(a.id)[0].Debit_Account_Number__r.Name;
                        creditAccountN = assetIdToInventoryWriteOffFTL.get(a.id)[0].Credit_Account_Number__r.Name;
						wrapAssetVariable wAR = new wrapAssetVariable(aType, jType, creditAccountN, debitAccountN);
                		wrapAssetVariableList.add(wAR);
					}
					
					if(vendorCreditAT == true){
						aType = 'VendorCredit';
						if(assetSubType == 'vendorCreateNew'){
							if(assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Inventory Received - External Vendor'){
								jType = 'Inventory Returned - External Vendor';
							}else if(assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Cost Product Received'){
								jType = 'Inventory Returned - Cost Product Received';
							}else if(assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Service Inventory Received - External Vendor' ||
										assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Service Inventory Received - Remake External Vendor'){
								jType = 'Service Inventory Returned - External Vendor';
							}else if(assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Service Inventory Received - Intercompany' ||
										assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Service Inventory Received - Remake Intercompany'){
								jType = 'Service Inventory Returned - Intercompany';
							}else if(assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Service Inventory Received - Intercompany Consolidation Center' ||
										assetIdToLatestJEforVendorCredit.get(a.id).Type__c == 'Service Inventory Received - Remake Intercompany Consolidation Center'){
								jType = 'Service Inventory Returned - Intercompany Consolidation Center';
							}
							creditAccountN = assetIdToLatestJEforVendorCredit.get(a.id).Debit_General_Ledger_Account__c;
			   				debitAccountN = assetIdToLatestJEforVendorCredit.get(a.id).Credit_General_Ledger_Account__c;
						}else if(assetSubType == 'vendorEdit'){
							creditAccountN = assetIdToLatestJEforVendorCredit.get(a.id).Debit_General_Ledger_Account__c;
				   			debitAccountN = assetIdToLatestJEforVendorCredit.get(a.id).Credit_General_Ledger_Account__c;
						}
					
						/*
						if(assetSubType == 'Intercompany'){
							 jType = 'Service Material Returned - Intercompany';
		                     debitAccountN = assetIdToSMRIntercompanyFTL.get(a.id)[0].Debit_Account_Number__r.Name;
		                     creditAccountN = assetIdToSMRIntercompanyFTL.get(a.id)[0].Credit_Account_Number__r.Name;
						 }else if(assetSubType == 'IntercompanyCC'){
	                        jType = 'Service Material Returned - Intercompany Consolidation Center';
	                        debitAccountN = assetIdToSMRIntercompanyCCFTL.get(a.id)[0].Debit_Account_Number__r.Name;
	                        creditAccountN = assetIdToSMRIntercompanyCCFTL.get(a.id)[0].Credit_Account_Number__r.Name;
						}else if(assetSubType == 'ExternalVendor'){
							jType = 'Service Material Returned - External Vendor';
							baanBPN = a.vendor__r.Baan_Business_Partner_Number__c;
	                        debitAccountN = assetIdToSMRExternalVendorFTL.get(a.id)[0].Debit_Account_Number__r.Name;
	                        creditAccountN = assetIdToSMRExternalVendorFTL.get(a.id)[0].Credit_Account_Number__r.Name;
						}
						*/
						
						
						wrapAssetVariable wAR = new wrapAssetVariable(aType, jType, creditAccountN, debitAccountN);
               			wrapAssetVariableList.add(wAR);
					}  
					
		           for(wrapAssetVariable wAR : wrapAssetVariableList){ 
		   				String assetType = wAR.assetType;
		                String jeType = wAR.jeType;
						String debitAccountNumber = wAR.debitAccountNumber;
						String creditAccountNumber = wAR.creditAccountNumber;

		                //NO RELATED JOURNAL ENTRIES CREATE JOURNAL
		                if(assetIdToJournalEntryMap.get(a.id) == null || assetIdToJournalEntryMap.get(a.id).size() == 0 || assetSubType == 'vendorCreateNew'){
	                        Journal_Entry__c newJE = new Journal_Entry__c();
                            newJE.Date__c = Datetime.Now();
                            newJE.Asset__c = a.id;
                            newJE.Order__c = a.Sold_Order__c;
                            newJE.Customer__c = a.Sold_Order__r.BillToContactId;

                            newJE.Type__c = jeType;
                            newJE.Debit_General_Ledger_Account__c = debitAccountNumber;
                            newJE.Credit_General_Ledger_Account__c = creditAccountNumber;
							newJE.Baan_Business_Partner_Number__c = baanBPN;
							
							if(assetType == 'InventoryReceived' || assetType == 'ServiceInventoryReceived' || assetType == 'CostProductReceived'){
	                            if (a.Quantity == null || a.Unit_Wholesale_Cost__c == null){
	                            	newJE.Amount__c = 0;
	                            }else{
	                            	newJE.Amount__c = a.Quantity * a.Unit_Wholesale_Cost__c;
	                            }

								if (a.Quantity == null || a.Unit_Wholesale_Cost__c == null)
								   newJE.Amount__c = 0;
								else 
	                            	newJE.Amount__c = a.Quantity * a.Unit_Wholesale_Cost__c;

							}else if(assetType == 'InventoryWriteOff'){
								newJE.Amount__c = (newQuantityWrittenOff - oldQuantityWrittenOff) * a.Unit_Wholesale_Cost__c;
							}else if(assetType == 'VendorCredit'){
								newJE.Amount__c = a.Vendor_Credit__c;
							}
							
							if(newJE.Amount__c < 0){
                            	mapNew.get(a.id).addError(RMS_errorMessages.NEGATIVE_FINACIAL_TRANSACTION, FALSE);
                          	}
	        				if(newJE.Amount__c > 0){ 
	                        	journalEntriesToUpsert.add(newJE);
	        				}
	                	}else{
		
	                        list<Journal_Entry__c> jeListSentToBaan = new list<Journal_Entry__c>();
	                        list<Journal_Entry__c> jeListNotSentToBaan = new list<Journal_Entry__c>();
	                        
	                        list<Journal_Entry__c> jeInventoryWriteOffList = new list<Journal_Entry__c>();
	                        list<Journal_Entry__c> jeInventoryReceivedList = new list<Journal_Entry__c>();
	                        list<Journal_Entry__c> jeCostProductReceivedList = new list<Journal_Entry__c>();
	                        list<Journal_Entry__c> jeServiceInventoryReceivedList = new list<Journal_Entry__c>();
	                        //list<Journal_Entry__c> jeServiceMaterialReturnedList = new list<Journal_Entry__c>();
		                    list<Journal_Entry__c> jeInventoryReturnedList = new list<Journal_Entry__c>();
		                    
		                    list<Journal_Entry__c> jeInventoryWriteOffListSentToBaan = new list<Journal_Entry__c>();
	                        list<Journal_Entry__c> jeInventoryReceivedListSentToBaan = new list<Journal_Entry__c>();
	                        list<Journal_Entry__c> jeCostProductReceivedListSentToBaan = new list<Journal_Entry__c>();
	                        list<Journal_Entry__c> jeServiceInventoryReceivedListSentToBaan = new list<Journal_Entry__c>();
	                       // list<Journal_Entry__c> jeServiceMaterialReturnedListSentToBaan = new list<Journal_Entry__c>();
	                        list<Journal_Entry__c> jeInventoryReturnedListSentToBaan = new list<Journal_Entry__c>();
	                        
	                        for(Journal_Entry__c je : assetIdToJournalEntryMap.get(a.id)){
	                            if(je.Sent_to_BaanERP__c == true){
	                                jeListSentToBaan.add(je);
	                                if(je.Type__c == 'Inventory Write-Off'){
	                                	jeInventoryWriteOffListSentToBaan.add(je);
	                                }
	                                
	                                if(je.Type__c != null && je.Type__c.contains('Inventory Received')){
	                                	if(je.Type__c.contains('Service')){
	                                		jeServiceInventoryReceivedListSentToBaan.add(je);
	                                	}else{
	                                		jeInventoryReceivedListSentToBaan.add(je);
	                                	}
	                                }
	                                
	                                if(je.Type__c != null && je.Type__c == 'Cost Product Received'){
	                                	jeCostProductReceivedListSentToBaan.add(je);
	                                }
	                                
	                                /*
	                                if(je.Type__c != null && je.Type__c.contains('Service Material Returned')){
	                                	jeServiceMaterialReturnedListSentToBaan.add(je);
	                                }
	                                */
	                                if(je.Type__c != null && je.Type__c.contains('Inventory Returned')){
	                                	jeInventoryReturnedListSentToBaan.add(je);
	                                }
	                                
	                            }else if(je.Sent_to_BaanERP__c == false){
	                                jeListNotSentToBaan.add(je);
	                                if(je.Type__c == 'Inventory Write-Off'){
	                                	jeInventoryWriteOffList.add(je);
	                                }
	                                if(je.Type__c != null && je.Type__c.contains('Inventory Received')){
	                                	if(je.Type__c.contains('Service')){
	                                		jeServiceInventoryReceivedList.add(je);
	                                	}else{
	                                		jeInventoryReceivedList.add(je);
	                                	}
	                                }
	                                 if(je.Type__c != null && je.Type__c == 'Cost Product Received'){
	                                	jeCostProductReceivedList.add(je);
	                                }
	                                /*
	                                if(je.Type__c != null && je.Type__c.contains('Service Material Returned')){
	                                	jeServiceMaterialReturnedList.add(je);
	                                }
	                                */
	                                if(je.Type__c != null && je.Type__c.contains('Inventory Returned')){
	                                	jeInventoryReturnedList.add(je);
	                                }
	                            }   
                        	}
	              
	                        system.debug('ads jeListSentToBaan: ' + jeListSentToBaan);
	                        system.debug('ads jeListNotSentToBaan: ' + jeListNotSentToBaan);
	                        system.debug('ads jeCostProductReceivedList: ' + jeCostProductReceivedList);
	                        
	                        // More than 1 JE not sent to BAAN ERROR OUT
	                        if(jeInventoryWriteOffList.size() > 1 || jeInventoryReceivedList.size() > 1 /*|| jeServiceMaterialReturnedList.size() > 1*/ || jeServiceInventoryReceivedList.size() > 1 || jeCostProductReceivedList.size() > 1){
	                            mapNew.get(a.id).addError(RMS_errorMessages.MORE_THAN_ONE_JOURNAL_ENTERY_NOT_SUBMITTED, FALSE);
	                        } 
	                        
	                        // All but 1 JE sent to BAAN then update that existing journal entry. The amount should be equal to --- 'Old Journal Entry->Amount + ( (Asset(new)->Quantity - Asset(old)->Quantity) * Unit WholesaleCost) 
	                        else if((jeInventoryWriteOffList.size() == 1 && assetType == 'InventoryWriteOff') || 
			                        (jeInventoryReceivedList.size() == 1 && assetType == 'InventoryReceived') ||
			                        (jeServiceInventoryReceivedList.size() == 1 && assetType == 'ServiceInventoryReceived') ||
			                        (jeCostProductReceivedList.size() == 1 && assetType == 'CostProductReceived') ||
			                        (jeServiceInventoryReceivedList.size() == 1 && assetType == 'InventoryReceived') ||  
			                        (jeInventoryReturnedList.size() == 1 && assetType == 'VendorCredit')){
	                            
	                            Journal_Entry__c je = new Journal_Entry__c();
	                            if(assetType == 'InventoryReceived'){
	                            	je = jeInventoryReceivedList[0];
	                            }else if(assetType == 'ServiceInventoryReceived'){
	                            	je = jeServiceInventoryReceivedList[0];
	                            }else if(assetType == 'CostProductReceived'){
	                            	je = jeCostProductReceivedList[0]; 
	                            }else if(assetType == 'VendorCredit'){
	                            	je = jeInventoryReturnedList[0];
	                            }else if(assetType == 'InventoryWriteOff'){
	                           		je = jeInventoryWriteOffList[0];
	                            }
	                            
	                                                  	
	                           	String oldTypeCreditAccountNumber = jeTypeToFTCreditNumber.get(je.Type__c);
								String oldTypeDebitAccountNumber = jeTypeToFTDebitNumber.get(je.Type__c);
	                           
	                            je.Date__c = Datetime.Now();
	                            je.Asset__c = a.id;
	                            je.Order__c = a.Sold_Order__c;
	                            je.Customer__c = a.Sold_Order__r.BillToContactId; 
								je.Baan_Business_Partner_Number__c = baanBPN;
								if(assetType == 'InventoryReceived' || assetType == 'ServiceInventoryReceived' || assetType == 'CostProductReceived'){
		
		                            je.Type__c = jeType;
		                         
		                            if(	(assetType == 'InventoryReceived' && jeInventoryReceivedListSentToBaan.size() == 0) ||
		                            	(assetType == 'ServiceInventoryReceived' && jeServiceInventoryReceivedListSentToBaan.size() == 0) ||
		                            	(assetType == 'CostProductReceived' && jeCostProductReceivedListSentToBaan.size() == 0)){
		                 
		                            	if((mapNew.get(a.id).Unit_Wholesale_Cost__c == null || mapNew.get(a.id).Unit_Wholesale_Cost__c == 0) || (newQuantity == null || newQuantity == 0)){
		                            		journalEntriesToDelete.add(je);
		                            	}else{
				                            je.Amount__c = a.Quantity * a.Unit_Wholesale_Cost__c;
				                            je.Debit_General_Ledger_Account__c = debitAccountNumber;
				                            je.Credit_General_Ledger_Account__c = creditAccountNumber;
		                            	}
		                            }else{
		                            	
		                            	//CHECKING IF JE.AMOUNT SHOULD BE CALCULATED AS A NEGITIVE AMOUNT 
		                            	system.debug('ads je.Debit_General_Ledger_Account__c: '+je.Debit_General_Ledger_Account__c);
		                            	system.debug('ads je.Credit_General_Ledger_Account__c: '+je.Credit_General_Ledger_Account__c);
		                        
		                            	if(	je.Debit_General_Ledger_Account__c == oldTypeCreditAccountNumber && 
		                            		je.Credit_General_Ledger_Account__c == oldTypeDebitAccountNumber){
		                            			system.debug('ads changing to negative amount: '+je.Amount__c);
		                            			je.Amount__c = je.Amount__c*-1;
		                            	} 
		                            	
		                                system.debug('ads mapNew.get(a.id).Unit_Wholesale_Cost__c: ' +mapNew.get(a.id).Unit_Wholesale_Cost__c);
		                                
		                                system.debug('ads je.Amount__c: ' +je.Amount__c);
		                            	system.debug('ads newQuantity: ' + newQuantity);
		                            	system.debug('ads oldQuantity: ' + oldQuantity);
		                            	
		                            	if((mapNew.get(a.id).Unit_Wholesale_Cost__c == null ||mapNew.get(a.id).Unit_Wholesale_Cost__c == 0) || (newQuantity == null || newQuantity == 0)){
		                            		journalEntriesToDelete.add(je);
		                            	}else if(je.Amount__c + ((newQuantity-oldQuantity) * a.Unit_Wholesale_Cost__c) > 0){
		                                    je.Amount__c = je.Amount__c + ((newQuantity-oldQuantity) * a.Unit_Wholesale_Cost__c);
		                                    je.Debit_General_Ledger_Account__c = debitAccountNumber;
		                           			je.Credit_General_Ledger_Account__c = creditAccountNumber;
		                                }else if(je.Amount__c + ((newQuantity-oldQuantity) * a.Unit_Wholesale_Cost__c) == 0){
		                                	journalEntriesToDelete.add(je);
		                                }else{
		                                	je.Amount__c = Math.abs(je.Amount__c + ((newQuantity-oldQuantity) * a.Unit_Wholesale_Cost__c));
		                                    je.Debit_General_Ledger_Account__c = creditAccountNumber;
		                           			je.Credit_General_Ledger_Account__c = debitAccountNumber;
		                            
		                                }   
		                            }
								}
								
								else if(assetType == 'VendorCredit'){
									je.Type__c = assetIdToLatestJEforVendorCredit.get(a.id).Type__c;
									if(assetIdToLatestJEforVendorCredit.get(a.id) != null && assetIdToLatestJEforVendorCredit.get(a.id).Sent_to_BaanERP__c == false){
										je.Amount__c = je.Amount__c + (newVendorCredit - oldVendorCredit);
			                            je.Debit_General_Ledger_Account__c = creditAccountNumber;
			                            je.Credit_General_Ledger_Account__c = debitAccountNumber;
		                            }else{
		                            	
		                            	//CHECKING IF JE.AMOUNT SHOULD BE CALCULATED AS A NEGITIVE AMOUNT 
		                            	system.debug('ads je.Debit_General_Ledger_Account__c: '+je.Debit_General_Ledger_Account__c);
		                            	system.debug('ads je.Credit_General_Ledger_Account__c: '+je.Credit_General_Ledger_Account__c);
		                        
		                            	if(	je.Debit_General_Ledger_Account__c ==  oldTypeDebitAccountNumber&& 
		                            		je.Credit_General_Ledger_Account__c == oldTypeCreditAccountNumber){
		                            			system.debug('ads changing to negative amount: '+je.Amount__c);
		                            			je.Amount__c = je.Amount__c*-1;
		                            	}
		   
		                                if(je.Amount__c + (newVendorCredit-oldVendorCredit)  > 0){
		                                    je.Amount__c = je.Amount__c + (newVendorCredit-oldVendorCredit);
		                                    je.Debit_General_Ledger_Account__c = debitAccountNumber;
		                           			je.Credit_General_Ledger_Account__c = creditAccountNumber;
		                            
		                                }else if(je.Amount__c + (newVendorCredit-oldVendorCredit) == 0){
		                                	journalEntriesToDelete.add(je);
		                                }else{
		                                	je.Amount__c = Math.abs(je.Amount__c + (newVendorCredit-oldVendorCredit));
		                                    je.Debit_General_Ledger_Account__c = debitAccountNumber;
		                           			je.Credit_General_Ledger_Account__c = creditAccountNumber;
		                            
		                                }
								
									}
								}
								
	
								else if(assetType == 'InventoryWriteOff'){
									je.Type__c = jeType;
		                            je.Debit_General_Ledger_Account__c = debitAccountNumber;
		                            je.Credit_General_Ledger_Account__c = creditAccountNumber;
		                            if(newQuantityWrittenOff - oldQuantityWrittenOff == 0){
			                            	je.Amount__c = a.Quantity_Written_Off__c * a.Unit_Wholesale_Cost__c;
			                            }else{
											je.Amount__c = (jeInventoryWriteOffList[0].Amount__c + (newQuantityWrittenOff - oldQuantityWrittenOff) * a.Unit_Wholesale_Cost__c);
		                            	}
									if(je.Amount__c < 0){
		                            	mapNew.get(a.id).addError(RMS_errorMessages.NEGATIVE_FINACIAL_TRANSACTION, FALSE);
		                          	}   
									
									if(je.Amount__c == 0){
										journalEntriesToDelete.add(je);
									}
								} 
	
	                            journalEntriesToUpsert.add(je);
	                        }
	                        
	                        // All related JE sent to BAAN
	                        //then create a new journal entry IF the quantity has changed. The amount should be equal to --- '( (Asset(new)->Quantity - Asset(old)->Quantity) * Unit WholesaleCost) 
	                        else{
	                        	system.debug('ads old Quantity: '+oldQuantity);
	                        	system.debug('ads newQuantity: '+newQuantity);
	                        	
	                        	system.debug('ads oldQuantityWrittenOff: '+oldQuantityWrittenOff);
	                        	system.debug('ads newQuantityWrittenOff: '+newQuantityWrittenOff);
	                        	
	                        	system.debug('ads oldVendorCredit: '+oldVendorCredit);
	                        	system.debug('ads newVendorCredit: '+newVendorCredit);
	                            if(oldQuantity != newQuantity || oldQuantityWrittenOff != newQuantityWrittenOff || oldVendorCredit != newVendorCredit){
	                                Journal_Entry__c newJE = new Journal_Entry__c( );
	        						newJE.Date__c = Datetime.Now();
		                            newJE.Asset__c = a.id;
		                            newJE.Order__c = a.Sold_Order__c;
		                            newJE.Customer__c = a.Sold_Order__r.BillToContactId;
		                            newJE.Type__c = jeType;
		        					
									if(assetType == 'InventoryReceived' || assetType == 'ServiceInventoryReceived' || assetType == 'CostProductReceived'){
			                            newJE.Debit_General_Ledger_Account__c = debitAccountNumber;
			                            newJE.Credit_General_Ledger_Account__c = creditAccountNumber;
			                            
			                       		if(newQuantity > oldQuantity){
	                                    	newJE.Amount__c = (newQuantity-oldQuantity) * a.Unit_Wholesale_Cost__c;
	                                    	newJE.Debit_General_Ledger_Account__c = debitAccountNumber;
			                            	newJE.Credit_General_Ledger_Account__c = creditAccountNumber;
			                            
		                                }else if (newQuantity < oldQuantity){
		                                    newJE.Amount__c = Math.abs((newQuantity-oldQuantity) * a.Unit_Wholesale_Cost__c);
	                                    	newJE.Debit_General_Ledger_Account__c = creditAccountNumber; 
			                            	newJE.Credit_General_Ledger_Account__c = debitAccountNumber;  
		                                }
			                     
									}
									else if(assetType == 'VendorCredit'){ 
										newJE.Type__c = assetIdToLatestJEforVendorCredit.get(a.id).Type__c;
										newJE.Baan_Business_Partner_Number__c = a.Vendor__r.Baan_Business_Partner_Number__c;
										if(newVendorCredit > oldVendorCredit){
	                                    	newJE.Amount__c = newVendorCredit-oldVendorCredit;
	                                    	newJE.Debit_General_Ledger_Account__c = creditAccountNumber;
			                            	newJE.Credit_General_Ledger_Account__c = debitAccountNumber;
			                            
		                                }else if (newVendorCredit < oldVendorCredit){
		                                    newJE.Amount__c = Math.abs(newVendorCredit-oldVendorCredit);
	                                    	newJE.Debit_General_Ledger_Account__c = debitAccountNumber; 
			                            	newJE.Credit_General_Ledger_Account__c = creditAccountNumber;  
		                                }
									}
								else if(assetType == 'InventoryWriteOff'){
			                            newJE.Debit_General_Ledger_Account__c = debitAccountNumber;
			                            newJE.Credit_General_Ledger_Account__c = creditAccountNumber;
										newJE.Amount__c = (newQuantityWrittenOff - oldQuantityWrittenOff) * a.Unit_Wholesale_Cost__c;
		                                //CHECK THAT WOULD NOT RESULT IN NEGATIVE FINACNCIAL TRANSACTION
										if(newJE.Amount__c < 0){
			                            	mapNew.get(a.id).addError(RMS_errorMessages.NEGATIVE_FINACIAL_TRANSACTION, FALSE);
			                          	}
									}
	        				 
	                                
	                               
	                                journalEntriesToUpsert.add(newJE);  
	                            }
	                        }//end of for loop
	  					
	                }//end of if there is atleast one related journal entery
                }
            }else{
                //there is an error message
                mapNew.get(a.id).addError(errorMessage, FALSE);
            }
            
            
            
        	
        }//END OF ASSET FOR LOOP
        system.debug('ads journalEntriesToUpsert: '+journalEntriesToUpsert);
        upsert journalEntriesToUpsert;
        if(journalEntriesToDelete != null){
        	delete journalEntriesToDelete;
        }
    }//END createOrUpdateJournalEntryAsset Method
	
	
	public class wrapAssetVariable{
				    	String assetType{get;set;}
				    	String jeType{get;set;} 
				    	String creditAccountNumber{get;set;} 
				    	String debitAccountNumber{get;set;}
	
	public wrapAssetVariable(	String assetTypeX, 
   								String jeTypeX, 
						   		String creditAccountNumberX, 
						   		String debitAccountNumberX){
			
			assetType = assetTypeX; 
			jeType = jeTypeX;
			creditAccountNumber = creditAccountNumberX; 
			debitAccountNumber  = debitAccountNumberX;
		}
	}


    /***************************************************
     Method to create Journal Entry for ORDER
    ****************************************************/
    public void createJournalEntryOrder(list<Order> listNew, map<id, Order> mapNew, map<id, Order> mapOld){ 
    	        
		// First check if any order's revenue recognition date has changed
		Set<Id> orderIdsChangedRR = new Set<Id>();
		for(Order o: listNew){
			if (mapOld.get(o.id).Revenue_Recognized_Date__c != mapNew.get(o.id).Revenue_Recognized_Date__c) {
				orderIdsChangedRR.add(o.Id);
			}
		}
		
		// If no order's rev recognition has changed, just return
		if (orderIdsChangedRR.size() == 0) return;

        boolean hasServiceType = false;
        boolean hasCoroType = false;
        list<Journal_Entry__c> journalEntriesToUpsert = new list<Journal_Entry__c>();
        
        list<Order> extraFieldsList = [SELECT       id,
                                                    RecordTypeId,
                                                    Revenue_Recognized_Date__c,
                                                    Store_Location__c,
                                                    Store_Location__r.Active_Store_Configuration__c,
                                                    Retail_Subtotal__c,
                                                    Retail_Total__c,
                                                    Discount_Amount__c,
                                                    Finance_Program_Fees__c,
                                                    Sales_Tax__c,
                                                    Invoice_Subtotal__c,
                                                    Install_Complete_Date__c 
                                                    
                                                    FROM Order WHERE Id IN : orderIdsChangedRR AND RecordTypeId IN :orderRecordTypes];       
        system.debug('ads extraFieldsList; '+extraFieldsList);
		
        list<Order> installDateFilledInOrders = new list<Order>();
        list<Id> installDateFilledInOrderIdList = new list<id>();
        
        for(Order o :extraFieldsList){
        	if(o.RecordTypeId == orderCOROServiceRecordTypeId){
        		hasServiceType=true;
        	}
        	if(o.RecordTypeId == orderCORORecordTypeId){
        		hasCoroType=true;
        	}
        	//Added to fill in Asset installed date and status
        	if(o.Install_Complete_Date__c != null){
        		installDateFilledInOrders.add(o);
        		installDateFilledInOrderIdList.add(o.id);
        	}
        }
        list<Asset> relatedAssestsToSetInstallDate = [SELECT id, InstallDate, Sold_Order__c FROM Asset WHERE Sold_Order__c IN :installDateFilledInOrderIdList];
        map<id, list<Asset>> orderIdToRelatedAssetsMap = new map<id, list<Asset>>();
       	
       	for(Asset a : relatedAssestsToSetInstallDate){
            if(orderIdToRelatedAssetsMap.containsKey(a.Sold_Order__c) ){
                orderIdToRelatedAssetsMap.get(a.Sold_Order__c).add(a); 
            }
            else{
                orderIdToRelatedAssetsMap.put(a.Sold_Order__c, new list<Asset>{a});
            }
       	}

		/*
        map<Id, list<Journal_Entry__c>> orderIdToJournalEntryMap = new map<Id, list<Journal_Entry__c>>(); 
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedDepositFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedExternalLaborFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedServiceExternalLaborFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedRefundDepositFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedInternalLaborFTL = new map<Id, list<Financial_Transaction__c>>();
        
       // map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedServiceInternalLaborFTL = new map<Id, list<Financial_Transaction__c>>();
        
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedDiscountFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedARFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedFinanceFeesFTL = new map<Id, list<Financial_Transaction__c>>();
        
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedServiceARFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdtoRevRecognizedCOGSFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdtoRevRecognizedServiceCOGSFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdtoRevRecognizedServiceTaxFTL = new map<Id, list<Financial_Transaction__c>>();
        
        
        if(extraFieldsList.size() > 0){
            orderIdToJournalEntryMap = linkJournalEntries(extraFieldsList);
            
            orderIdToRevRecognizedDepositFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Deposit');
            orderIdToRevRecognizedExternalLaborFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - External Labor');
            orderIdToRevRecognizedServiceExternalLaborFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Service External Labor');
            
            orderIdToRevRecognizedRefundDepositFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Refund Deposit');
            orderIdToRevRecognizedInternalLaborFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Internal Labor');
           
            //orderIdToRevRecognizedServiceInternalLaborFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Service Internal Labor');
         
            orderIdToRevRecognizedDiscountFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Discount');
            orderIdToRevRecognizedARFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - AR');
            orderIdToRevRecognizedFinanceFeesFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Finance Fees');
            
	        orderIdtoRevRecognizedCOGSFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - COGS');
            
            if(hasServiceType){
            	orderIdtoRevRecognizedServiceCOGSFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Service COGS');
            	orderIdtoRevRecognizedServiceTaxFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Service Tax');
				orderIdToRevRecognizedServiceARFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Service AR');            	
            }
        }
        */
        map<Id, list<Journal_Entry__c>> orderIdToJournalEntryMap = linkJournalEntries(extraFieldsList);
        list<string> financialTransactionTypesToGet = new list<string>{	'Rev Recognized - Deposit',
    																	'Rev Recognized - External Labor',
    																	'Rev Recognized - Service External Labor',
    																	'Rev Recognized - Service External Labor - JIP',
    																	'Rev Recognized - Refund Deposit',
    																	//'Rev Recognized - Internal Labor',
    																	//'Rev Recognized - Service Internal Labor',
    																	'Rev Recognized - Discount',
    																	'Rev Recognized - AR', 
        																'Rev Recognized - Finance Fees',
        																'Rev Recognized - COGS',
        																//'Rev Recognized - Service COGS',
        																'Rev Recognized - Service Tax',
        																'Rev Recognized - Service AR'
        																};
       	map<string, map<Id, list<Financial_Transaction__c>>> typeToMapOfOrderIdtoListFT = linkFinancialTransactions(extraFieldsList, financialTransactionTypesToGet);

        
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedDepositFTL = typeToMapOfOrderIdtoListFT.get('Rev Recognized - Deposit');
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedExternalLaborFTL = typeToMapOfOrderIdtoListFT.get('Rev Recognized - External Labor');
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedServiceExternalLaborFTL = typeToMapOfOrderIdtoListFT.get('Rev Recognized - Service External Labor');
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedServiceExternalLaborJIPFTL = typeToMapOfOrderIdtoListFT.get('Rev Recognized - Service External Labor - JIP');
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedRefundDepositFTL = typeToMapOfOrderIdtoListFT.get('Rev Recognized - Refund Deposit');
        //map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedInternalLaborFTL = typeToMapOfOrderIdtoListFT.get('Rev Recognized - Internal Labor');
        // map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedServiceInternalLaborFTL = typeToMapOfOrderIdtoListFT.get('Rev Recognized - Service Internal Labor');
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedDiscountFTL = typeToMapOfOrderIdtoListFT.get('Rev Recognized - Discount');
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedARFTL = typeToMapOfOrderIdtoListFT.get('Rev Recognized - AR');
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedFinanceFeesFTL = typeToMapOfOrderIdtoListFT.get('Rev Recognized - Finance Fees');
        map<Id, list<Financial_Transaction__c>> orderIdtoRevRecognizedCOGSFTL = typeToMapOfOrderIdtoListFT.get('Rev Recognized - COGS');
        
        //map<Id, list<Financial_Transaction__c>> orderIdtoRevRecognizedServiceCOGSFTL = typeToMapOfOrderIdtoListFT.get('Rev Recognized - Service COGS');
        map<Id, list<Financial_Transaction__c>> orderIdtoRevRecognizedServiceTaxFTL = typeToMapOfOrderIdtoListFT.get('Rev Recognized - Service Tax');
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedServiceARFTL = typeToMapOfOrderIdtoListFT.get('Rev Recognized - Service AR');

      
      
        for(Order o : extraFieldsList){
               
                //IF REVENUE RECOGNIZED DATE HAS CHANGED FROM BLANK/NULL TO A VALUE
                string errorMessage;
                if(mapOld.get(o.id).Revenue_Recognized_Date__c == null && mapNew.get(o.id).Revenue_Recognized_Date__c != null){
	                if(o.Install_Complete_Date__c != null){
	                	list<Asset> relatedA = orderIdToRelatedAssetsMap.get(o.id);
                        if (relatedA != null) {
	                		for(Asset a : relatedA){
	                			a.InstallDate = o.Install_Complete_Date__c;
	                			a.Status = 'Installed';
	                		}
	                		upsert relatedA;
                        }
	                }
                    
                    if(o.Store_Location__c == null ){ 
                        errorMessage = RMS_errorMessages.STORE_LOCATION_IS_BLANK;
                    }
                    if(orderIdToJournalEntryMap.get(o.id) == null ){ 
    //                    errorMessage = RMS_errorMessages.NO_RELATED_DEPOSIT_JOURNAL_ENTRY;
                    }
                    
                    
                    //errorMessage = checkOrderForErrors(o, errorMessage);
                    system.debug('Method:createJournalEntryOrder orderIdToRevRecognizedDepositFTL: '+orderIdToRevRecognizedDepositFTL);
                	
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedDepositFTL.get(o.id) , errorMessage, 'Rev Recognized - Deposit');
                	errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedDiscountFTL.get(o.id) , errorMessage, 'Rev Recognized - Discount');
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedARFTL.get(o.id) , errorMessage, 'Rev Recognized - AR');
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedFinanceFeesFTL.get(o.id) , errorMessage, 'Rev Recognized - Finance Fees');
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedRefundDepositFTL.get(o.id) , errorMessage, 'Rev Recognized - Refund Deposit');
                    

                    if(o.RecordTypeId != orderCOROServiceRecordTypeId){
	                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedExternalLaborFTL.get(o.id) , errorMessage, 'Rev Recognized - External Labor');
	                    //errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedInternalLaborFTL.get(o.id) , errorMessage, 'Rev Recognized - Internal Labor');
	                    errorMessage = checkFinacialTransationForErrors(orderIdtoRevRecognizedCOGSFTL.get(o.id) , errorMessage, 'Rev Recognized - COGS');
                    }else{
                    	errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedServiceExternalLaborFTL.get(o.id) , errorMessage, 'Rev Recognized - Service External Labor');
                    	errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedServiceExternalLaborJIPFTL.get(o.id) , errorMessage, 'Rev Recognized - Service External Labor - JIP');
	                    //errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedServiceInternalLaborFTL.get(o.id) , errorMessage, 'Rev Recognized - Service Internal Labor');
	                   	//errorMessage = checkFinacialTransationForErrors(orderIdtoRevRecognizedServiceCOGSFTL.get(o.id) , errorMessage, 'Rev Recognized - Service COGS');
                    	errorMessage = checkFinacialTransationForErrors(orderIdtoRevRecognizedServiceTaxFTL.get(o.id) , errorMessage, 'Rev Recognized - Service Tax');
                    	errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedServiceARFTL.get(o.id) , errorMessage, 'Rev Recognized - Service AR');

                    }
                   
                    
//                    if(orderIdToJournalEntryMap.get(o.id) != null && orderIdToJournalEntryMap.get(o.id).size() != 0 ){      
                    if(true){      
                        if(errorMessage == null || errorMessage == ''){
                            list<Journal_Entry__c> relatedDepositJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedRevRecognizedDepositJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedExternalLaborJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedServiceExternalLaborJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedServiceExternalLaborJIPJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedRevRecognizedExternalLaborJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedRevRecognizedServiceExternalLaborJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedRevRecognizedServiceExternalLaborJIPJE = new list<Journal_Entry__c>();
                            
                            list<Journal_Entry__c> relatedInternalLaborJE = new list<Journal_Entry__c>();
                            /*
                            list<Journal_Entry__c> relatedServiceInternalLaborJE = new list<Journal_Entry__c>();
 							list<Journal_Entry__c> relatedRevRecognizedServiceInternalLaborJE = new list<Journal_Entry__c>();
 							list<Journal_Entry__c> relatedRevRecognizedInternalLaborJE = new list<Journal_Entry__c>();
 							*/
                            
                            list<Journal_Entry__c> relatedRefundDepositJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedRevRecognizedRefundDepositJE = new list<Journal_Entry__c>();
                            
                            list<Journal_Entry__c> relatedRevRecognizedDiscountJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedRevRecognizedARJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedRevRecognizedFinanceFeesJE = new list<Journal_Entry__c>();
                            
                            list<Journal_Entry__c> relatedInventoryRecivedJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedRevRecognizedCOGSJE = new list<Journal_Entry__c>();
                            //list<Journal_Entry__c> relatedRevRecognizedServiceCOGSJE = new list<Journal_Entry__c>();
                             
                            list<Journal_Entry__c> relatedRevRecognizedServiceTaxJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedRevRecognizedServiceARJE = new list<Journal_Entry__c>();

//                            list<Journal_Entry__c> relatedInstallAdjustmentJE = new list<Journal_Entry__c>();
//                            list<Journal_Entry__c> relatedRevRecognizedInstallAdjustmentJE = new list<Journal_Entry__c>();
                            
                            //CHECK JOURNAL ENTRY OF TYPE Rev Recognized - Deposit DOESN'T EXIST
                            Boolean alreadyHasJEofTypeRevRecDeposit = false;
                            Boolean alreadyHasJEofTypeRevRecExternalLabor = false;
                            Boolean alreadyHasJEofTypeRevRecServiceExternalLabor = false;
                            Boolean alreadyHasJEofTypeRevRecServiceExternalLaborJIP = false;
                            Boolean alreadyHasJEofTypeRevRecRefundDeposit = false;
                            /*
                            Boolean alreadyHasJEofTypeRevRecInternalLabor = false;
                            Boolean alreadyHasJEofTypeRevRecServiceInternalLabor = false;
                            */
                            Boolean alreadyHasJEofTypeRevRecDiscount = false;
                            Boolean alreadyHasJEofTypeRevRecAR = false;
                            Boolean alreadyHasJEofTypeRevRecFinanceFees = false; 
                            
                            Boolean alreadyHasJEofTypeRevRecCOGS = false; 
                            //Boolean alreadyHasJEofTypeRevRecServiceCOGS = false;
                            Boolean alreadyHasJEofTypeRevRecServiceTax = false; 
                            Boolean alreadyHasJEofTypeRevRecServiceAR = false; 

//                            Boolean alreadyHasJEofTypeRevRecInstallAdjustment = false; 
                            
                    		if(orderIdToJournalEntryMap.get(o.id) != null && orderIdToJournalEntryMap.get(o.id).size() != 0 ){      
	                            for(Journal_Entry__c je : orderIdToJournalEntryMap.get(o.id)){
	                                if(je.Type__c == 'Deposit' || je.Type__c == 'Install Adjustment'){
	                                    relatedDepositJE.add(je);
	                                }
	                                if(je.Type__c == 'Internal Labor'){
	                                    relatedInternalLaborJE.add(je);
	                                } 
	                                /*
	                                if(je.Type__c == 'Service Internal Labor'){
	                                    relatedServiceInternalLaborJE.add(je);
	                                }
	                                if(je.Type__c == 'Rev Recognized - ServiceInternal Labor'){
	                                    alreadyHasJEofTypeRevRecServiceInternalLabor = true;   
	                                    relatedRevRecognizedServiceInternalLaborJE.add(je);
	                                }
	                                */
	                                if(je.Type__c == 'External Labor'){
	                                    relatedExternalLaborJE.add(je);
	                                }
	                                if(je.Type__c == 'Service External Labor'){
	                                    relatedServiceExternalLaborJE.add(je);
	                                }
	                                if(je.Type__c == 'Service External Labor - JIP'){
	                                    relatedServiceExternalLaborJIPJE.add(je);
	                                }
	                                if(je.Type__c == 'Refund - Deposit'){
	                                    relatedRefundDepositJE.add(je);
	                                }
	                                if(je.Type__c != null && je.Type__c.contains('Inventory Received')){
	                                    relatedInventoryRecivedJE.add(je);
	                                }
	                                
	
	                                if(je.Type__c == 'Rev Recognized - Deposit'){
	                                    alreadyHasJEofTypeRevRecDeposit = true; 
	                                    relatedRevRecognizedDepositJE.add(je);
	                                }
	                                /*
	                                if(je.Type__c == 'Rev Recognized - Internal Labor'){
	                                    alreadyHasJEofTypeRevRecInternalLabor = true;   
	                                    relatedRevRecognizedInternalLaborJE.add(je);
	                                }
	                               */
	                                if(je.Type__c == 'Rev Recognized - External Labor'){
	                                    alreadyHasJEofTypeRevRecExternalLabor = true;   
	                                    relatedRevRecognizedExternalLaborJE.add(je);
	                                }
	                                if(je.Type__c == 'Rev Recognized - Service External Labor'){
	                                    alreadyHasJEofTypeRevRecServiceExternalLabor = true;   
	                                    relatedRevRecognizedServiceExternalLaborJE.add(je);
	                                }
	                                if(je.Type__c == 'Rev Recognized - Service External Labor - JIP'){
	                                    alreadyHasJEofTypeRevRecServiceExternalLaborJIP = true;   
	                                    relatedRevRecognizedServiceExternalLaborJIPJE.add(je);
	                                }
	                                if(je.Type__c == 'Rev Recognized - Refund Deposit'){ 
	                                    alreadyHasJEofTypeRevRecRefundDeposit = true;   
	                                    relatedRevRecognizedRefundDepositJE.add(je);
	                                }
	                                if(je.Type__c == 'Rev Recognized - COGS'){
	                                    alreadyHasJEofTypeRevRecCOGS = true; 
	                                    relatedRevRecognizedCOGSJE.add(je);
	                                }
	                             	/*	
	                             	if(je.Type__c == 'Rev Recognized - Service COGS'){
	                                    alreadyHasJEofTypeRevRecServiceCOGS = true; 
	                                    relatedRevRecognizedServiceCOGSJE.add(je);
	                                }
	                             	*/
	                                if(je.Type__c == 'Rev Recognized - Discount'){
	                                    alreadyHasJEofTypeRevRecDiscount = true;    
	                                    relatedRevRecognizedDiscountJE.add(je);
	                                }
	                                if(je.Type__c == 'Rev Recognized - AR'){
	                                    alreadyHasJEofTypeRevRecAR = true;  
	                                    relatedRevRecognizedARJE.add(je);
	                                } 
	                                if(je.Type__c == 'Rev Recognized - Finance Fees'){
	                                    alreadyHasJEofTypeRevRecFinanceFees = true;  
	                                    relatedRevRecognizedFinanceFeesJE.add(je);
	                                }
									
	                                if(je.Type__c == 'Rev Recognized - Service Tax'){
	                                    alreadyHasJEofTypeRevRecServiceTax= true;  
	                                    relatedRevRecognizedServiceTaxJE.add(je);
	                                }
	                             	
	                                if(je.Type__c == 'Rev Recognized - Service AR'){
	                                	alreadyHasJEofTypeRevRecServiceAR= true;  
	                                	relatedRevRecognizedServiceARJE.add(je);
	                                }
		                        }
                    		}
                           
                            system.debug('Method:createJournalEntryOrder relatedDepositJE: '+relatedDepositJE);
                            system.debug('Method:createJournalEntryOrder alreadyHasJEofTypeRevRecDeposit: '+alreadyHasJEofTypeRevRecDeposit);
     
                            //NO JE OF TYPE REV REC DEPOSIT BUT HAS DEPOSIT JE, SO CREATE A REV RECC DEPOSIT
                            if(alreadyHasJEofTypeRevRecDeposit == false && relatedDepositJE.size() > 0){ 
                                for(Journal_Entry__c je : relatedDepositJE){ 
                                	if (je.Type__c == 'Deposit')
                                    	errorMessage = checkOrderJEForErrors(je, errorMessage, 'deposit');
                                    else if (je.Type__c == 'Install Adjustment')
                                    	errorMessage = checkOrderJEForErrors(je, errorMessage, 'installadjustment');

                                    if(errorMessage == null){
                                        Journal_Entry__c newJE = new Journal_Entry__c(
                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - Deposit',
                                            Payment__c = je.Payment__c,
                                            Order__c = je.Order__c,
                                            Amount__c = je.Amount__c,
                                            Customer__c = je.Customer__c,
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedDepositFTL.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedDepositFTL.get(o.id)[0].Credit_Account_Number__r.Name
                                        );
                                        //If the original journal entry is an install adjustment rather than a deposit, swap the debit and credit numbers
                                        //and link to the business adjustment record
                                        if (je.Type__c == 'Install Adjustment') {
                                            newJE.Debit_General_Ledger_Account__c = orderIdToRevRecognizedDepositFTL.get(o.id)[0].Credit_Account_Number__r.Name;
                                            newJE.Credit_General_Ledger_Account__c = orderIdToRevRecognizedDepositFTL.get(o.id)[0].Debit_Account_Number__r.Name;                                       	
                                            newJE.Business_Adjustment__c = je.Business_Adjustment__c;
                                        }
                                        journalEntriesToUpsert.add(newJE);
                                    }else{
                                        mapNew.get(o.id).addError(errorMessage, FALSE);
                                        break;
                                    }
                                }//END relatedDepositJE LOOP
                            }//END alreadyHasJEofTypeRevRecDeposit == false
                            
                            //IF THERE IS A RELATED REV RECEIVED - DEPOSIT JOURNAL ENTERY
                            else if(alreadyHasJEofTypeRevRecDeposit == true && relatedRevRecognizedDepositJE.size() > 0 ){
                                for(Journal_Entry__c je: relatedRevRecognizedDepositJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }
                            
                            
                            
                            //does not have related JE records of type Revenue Received External labor BUT HAS EXTERNAL LABOR JE
                            if(alreadyHasJEofTypeRevRecExternalLabor == false && relatedExternalLaborJE.size() > 0  && o.RecordTypeId != orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je : relatedExternalLaborJE){
                                    errorMessage = checkOrderJEForErrors(je, errorMessage, 'labor');
                                    if(errorMessage == null){
                                        Journal_Entry__c newJE = new Journal_Entry__c(
                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - External Labor',
                                            Labor__c = je.Labor__c,
                                            Order__c = je.Order__c,
                                            Amount__c = je.Amount__c,
                                            Baan_Business_Partner_Number__c = je.Baan_Business_Partner_Number__c,
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedExternalLaborFTL.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedExternalLaborFTL.get(o.id)[0].Credit_Account_Number__r.Name
                                        );
                                        journalEntriesToUpsert.add(newJE);
                                    }else{
                                        mapNew.get(o.id).addError(errorMessage, FALSE);
                                        break;
                                    }
                                }//END relatedExternalLaborJE LOOP
                            }else if(alreadyHasJEofTypeRevRecExternalLabor == true && relatedRevRecognizedExternalLaborJE.size() > 0  && o.RecordTypeId != orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je: relatedRevRecognizedRefundDepositJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }
                            
                            //does not have related JE records of type Revenue Received External labor BUT HAS SERVICE EXTERNAL LABOR JE AND IS CORO SERVICE RECORD TYPE
                            system.debug('ads Service External Labor:  alreadyHasJEofTypeRevRecServiceExternalLabor :'+alreadyHasJEofTypeRevRecServiceExternalLabor);
                            system.debug('ads Service External Labor:  relatedServiceExternalLaborJE :'+relatedServiceExternalLaborJE);
                            system.debug('ads Service External Labor:  o.RecordTypeId :'+o.RecordTypeId);
                            system.debug('ads Service External Labor:  orderCOROServiceRecordTypeId :'+orderCOROServiceRecordTypeId);
                            
                            if(alreadyHasJEofTypeRevRecServiceExternalLabor == false && relatedServiceExternalLaborJE.size() > 0  && o.RecordTypeId == orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je : relatedServiceExternalLaborJE){
                                    errorMessage = checkOrderJEForErrors(je, errorMessage, 'labor');
                                    if(errorMessage == null){
                                        Journal_Entry__c newJE = new Journal_Entry__c(
                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - Service External Labor',
                                            Labor__c = je.Labor__c,
                                            Order__c = je.Order__c,
                                            Amount__c = je.Amount__c,
                                            Baan_Business_Partner_Number__c = je.Baan_Business_Partner_Number__c,
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedServiceExternalLaborFTL.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedSErviceExternalLaborFTL.get(o.id)[0].Credit_Account_Number__r.Name
                                        );
                                        journalEntriesToUpsert.add(newJE);
                                    }else{
                                        mapNew.get(o.id).addError(errorMessage, FALSE);
                                        break;
                                    }
                                }//END relatedServiceExternalLaborJE LOOP
                            }else if(alreadyHasJEofTypeRevRecServiceExternalLabor == true && relatedRevRecognizedServiceExternalLaborJE.size() > 0  && o.RecordTypeId == orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je: relatedRevRecognizedRefundDepositJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }

                            //does not have related JE records of type Revenue Received External labor BUT HAS SERVICE EXTERNAL LABOR JIP JE AND IS CORO SERVICE RECORD TYPE
                            system.debug('ads Service External Labor:  alreadyHasJEofTypeRevRecServiceExternalLaborJIP :'+alreadyHasJEofTypeRevRecServiceExternalLaborJIP);
                            system.debug('ads Service External Labor:  relatedServiceExternalLaborJIPJE :'+relatedServiceExternalLaborJIPJE);
                            system.debug('ads Service External Labor:  o.RecordTypeId :'+o.RecordTypeId);
                            system.debug('ads Service External Labor:  orderCOROServiceRecordTypeId :'+orderCOROServiceRecordTypeId);
                            
                            if(alreadyHasJEofTypeRevRecServiceExternalLaborJIP == false && relatedServiceExternalLaborJIPJE.size() > 0  && o.RecordTypeId == orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je : relatedServiceExternalLaborJIPJE){
                                    errorMessage = checkOrderJEForErrors(je, errorMessage, 'labor');
                                    if(errorMessage == null){
                                        Journal_Entry__c newJE = new Journal_Entry__c(
                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - Service External Labor - JIP',
                                            Labor__c = je.Labor__c,
                                            Order__c = je.Order__c,
                                            Amount__c = je.Amount__c,
                                            Baan_Business_Partner_Number__c = je.Baan_Business_Partner_Number__c,
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedServiceExternalLaborJIPFTL.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedSErviceExternalLaborJIPFTL.get(o.id)[0].Credit_Account_Number__r.Name
                                        );
                                        journalEntriesToUpsert.add(newJE);
                                    }else{
                                        mapNew.get(o.id).addError(errorMessage, FALSE);
                                        break;
                                    }
                                }//END relatedDepositJIPJE LOOP
                            }else if(alreadyHasJEofTypeRevRecServiceExternalLaborJIP == true && relatedRevRecognizedServiceExternalLaborJIPJE.size() > 0  && o.RecordTypeId == orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je: relatedRevRecognizedRefundDepositJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }
                            
                            /*
                            //does not have related JE records of type Rev Rec internal labor BUT HAS INTERNAL LABOR JE - CREATE REV REC INTERNAL LABOR JE
                            if(alreadyHasJEofTypeRevRecInternalLabor == false && relatedInternalLaborJE.size() > 0  && o.RecordTypeId != orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je : relatedInternalLaborJE){
                                    errorMessage = checkOrderJEForErrors(je, errorMessage, 'internallabor');
                                    if(errorMessage == null){
                                    	system.debug('ads creating new internal labor JE');
                                        Journal_Entry__c newJE = new Journal_Entry__c(
                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - Internal Labor',
                                            Labor__c = je.Labor__c,
                                            Order__c = je.Order__c,
                                            Amount__c = je.Amount__c,
                                            Customer__c = je.Customer__c,
                                            Baan_Business_Partner_Number__c = je.Baan_Business_Partner_Number__c,
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedInternalLaborFTL.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedInternalLaborFTL.get(o.id)[0].Credit_Account_Number__r.Name
                                        );
                                        journalEntriesToUpsert.add(newJE);
                                    }else{
                                    	system.debug('ads error internal errorMessage: '+errorMessage);
                                    	mapNew.get(o.id).addError(errorMessage, FALSE);
                                        break;
                                    }
                                }//END relatedInternalLaborJE LOOP
                            }else if(alreadyHasJEofTypeRevRecInternalLabor == true && relatedRevRecognizedInternalLaborJE.size() > 0  && o.RecordTypeId != orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je: relatedRevRecognizedInternalLaborJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    } 
                                }
                            }
                            */
                            
                            /*
                             //does not have related JE records of type Rev Rec internal labor BUT HAS INTERNAL LABOR JE AND IS COROR SERVICE RECORD TYPE- CREATE REV REC INTERNAL LABOR JE
                            if(alreadyHasJEofTypeRevRecServiceInternalLabor == false && relatedServiceInternalLaborJE.size() > 0  && o.RecordTypeId == orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je : relatedInternalLaborJE){
                                    errorMessage = checkOrderJEForErrors(je, errorMessage, 'internallabor');
                                    if(errorMessage == null){
                                    	system.debug('ads creating new internal labor JE');
                                        Journal_Entry__c newJE = new Journal_Entry__c( 
                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - Service Internal Labor',
                                            Labor__c = je.Labor__c,
                                            Order__c = je.Order__c,
                                            Amount__c = je.Amount__c,
                                            Customer__c = je.Customer__c,
                                            Baan_Business_Partner_Number__c = je.Baan_Business_Partner_Number__c,
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedServiceInternalLaborFTL.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedServiceInternalLaborFTL.get(o.id)[0].Credit_Account_Number__r.Name
                                        );
                                        journalEntriesToUpsert.add(newJE);
                                    }else{
                                    	system.debug('ads error internal errorMessage: '+errorMessage);
                                    	mapNew.get(o.id).addError(errorMessage, FALSE);
                                        break;
                                    }
                                }//END relatedInternalLaborJE LOOP
                            }else if(alreadyHasJEofTypeRevRecServiceInternalLabor == true && relatedRevRecognizedServiceInternalLaborJE.size() > 0  && o.RecordTypeId == orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je: relatedRevRecognizedInternalLaborJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }      
                     		*/
                            //does not have related JE records of type Rev Recognized - Refund Deposit
                            if(alreadyHasJEofTypeRevRecRefundDeposit == false && relatedRefundDepositJE.size() > 0){
                                for(Journal_Entry__c je : relatedRefundDepositJE){
                                    errorMessage = checkOrderJEForErrors(je, errorMessage, 'refundDeposit');
                                    if(errorMessage == null){
                                        Journal_Entry__c newJE = new Journal_Entry__c(
                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - Refund Deposit',
                                            Refund__c = je.Refund__c,
                                            Order__c = je.Order__c,
                                            Amount__c = je.Amount__c,
                                            Customer__c = je.Customer__c,
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedRefundDepositFTL.get(o.id)[0].Credit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedRefundDepositFTL.get(o.id)[0].Debit_Account_Number__r.Name
                                        );
                                        journalEntriesToUpsert.add(newJE);
                                    }else{
                                        mapNew.get(o.id).addError(errorMessage, FALSE);
                                        break;
                                    }
                                }//END relatedRefundDespoitJE LOOP
                            }else if(alreadyHasJEofTypeRevRecRefundDeposit == true && relatedRevRecognizedExternalLaborJE.size() > 0){
                                for(Journal_Entry__c je: relatedRevRecognizedExternalLaborJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }
                            
                            //does not have related JE records of type Rev Recognized - COGS BUT HAS INVENTORY RECIVED JE - CREATE REV REC COGS JE
                            if(alreadyHasJEofTypeRevRecCOGS == false && relatedInventoryRecivedJE.size() > 0  && o.RecordTypeId != orderCOROServiceRecordTypeId){
                                Decimal totalAmount = 0;
                                Boolean hasNonService = false;
                                for(Journal_Entry__c je : relatedInventoryRecivedJE){
                                	if(!je.Type__c.contains('Service')){
                                		hasNonService = true;
                                   		totalAmount = totalAmount + je.Amount__c;
                                   	}
                                }
                                if(hasNonService == true){
	                                if(errorMessage == null){
	                                    Journal_Entry__c newJE = new Journal_Entry__c(
	                                        Date__c = Datetime.Now(),
	                                        Type__c = 'Rev Recognized - COGS',
	                                        Order__c = o.id,
	                                        Amount__c = totalAmount,
	                                        Debit_General_Ledger_Account__c = orderIdtoRevRecognizedCOGSFTL.get(o.id)[0].Debit_Account_Number__r.Name,
	                                        Credit_General_Ledger_Account__c = orderIdtoRevRecognizedCOGSFTL.get(o.id)[0].Credit_Account_Number__r.Name
	                                    );
	                                    journalEntriesToUpsert.add(newJE);
	                                }else{
	                                    mapNew.get(o.id).addError(errorMessage, FALSE);
	                                    break;
	                                }
                                }
                            }else if(alreadyHasJEofTypeRevRecCOGS == true && relatedRevRecognizedCOGSJE.size() > 0  && o.RecordTypeId != orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je: relatedRevRecognizedCOGSJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }
                            
                            
                             //does not have related JE records of type Rev Recognized - COGS BUT HAS INVENTORY RECIVED JE AND IS CORO SERVICE RECORD TYPE - CREATE REV REC COGS JE
                            /*
                            if(alreadyHasJEofTypeRevRecServiceCOGS == false && relatedInventoryRecivedJE.size() > 0  && o.RecordTypeId == orderCOROServiceRecordTypeId){
                                Decimal totalAmount = 0;
                                Boolean hasService = false;
                                for(Journal_Entry__c je : relatedInventoryRecivedJE){
                               		totalAmount = totalAmount + je.Amount__c;
                                }
                                if(errorMessage == null && totalAmount != 0){ 
                                    Journal_Entry__c newJE = new Journal_Entry__c(
                                        Date__c = Datetime.Now(),
                                        Type__c = 'Rev Recognized - Service COGS',
                                        Order__c = o.id,
                                        Amount__c = totalAmount,
                                        Debit_General_Ledger_Account__c = orderIdtoRevRecognizedCOGSFTL.get(o.id)[0].Debit_Account_Number__r.Name,
                                        Credit_General_Ledger_Account__c = orderIdtoRevRecognizedCOGSFTL.get(o.id)[0].Credit_Account_Number__r.Name
                                    );
                                    journalEntriesToUpsert.add(newJE);
                                }else{
                                    mapNew.get(o.id).addError(errorMessage, FALSE);
                                    break;
                                }
                            }else if(alreadyHasJEofTypeRevRecServiceCOGS == true && relatedRevRecognizedServiceCOGSJE.size() > 0  && o.RecordTypeId == orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je: relatedRevRecognizedCOGSJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }
                            */
                            //does not have related JE records of type Rev Recognized - Discount
                            if(alreadyHasJEofTypeRevRecDiscount == false && o.RecordTypeId != orderCOROServiceRecordTypeId){
                                if(errorMessage == null){
                                    
                                        Journal_Entry__c newJE = new Journal_Entry__c(
                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - Discount',
                                            Order__c = o.id,
                                            Amount__c = o.Discount_Amount__c
                                        
                                        );
                                        if(o.Discount_Amount__c > 0){
                                            newJE.Debit_General_Ledger_Account__c = orderIdToRevRecognizedDiscountFTL.get(o.id)[0].Debit_Account_Number__r.Name;
                                            newJE.Credit_General_Ledger_Account__c = orderIdToRevRecognizedDiscountFTL.get(o.id)[0].Credit_Account_Number__r.Name;
                                        }else if (o.Discount_Amount__c < 0){
                                            newJE.Credit_General_Ledger_Account__c = orderIdToRevRecognizedDiscountFTL.get(o.id)[0].Debit_Account_Number__r.Name;
                                            newJE.Debit_General_Ledger_Account__c = orderIdToRevRecognizedDiscountFTL.get(o.id)[0].Credit_Account_Number__r.Name;
											newJE.Amount__c = newJE.Amount__c * -1;
                                        }
   										if (newJE.Amount__c != 0)
                                        	journalEntriesToUpsert.add(newJE);
                                   
                                }else{
                                    mapNew.get(o.id).addError(errorMessage, FALSE);
                                    break;
                                } 
                            }else if(alreadyHasJEofTypeRevRecRefundDeposit == true && relatedRevRecognizedDiscountJE.size() > 0 && o.RecordTypeId != orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je: relatedRevRecognizedDiscountJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            } 


                            //does not have related JE records of type Rev Recognized - AR
                            if(alreadyHasJEofTypeRevRecAR == false && o.RecordTypeId != orderCOROServiceRecordTypeId){
                                if(errorMessage == null){
                                  
                                        Journal_Entry__c newJE = new Journal_Entry__c(
                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - AR',
                                            Order__c = o.id,
                                            Amount__c = o.Retail_Subtotal__c
                                           
                                        );

                                          if(o.Retail_Subtotal__c > 0){
                                             newJE.Debit_General_Ledger_Account__c = orderIdToRevRecognizedARFTL.get(o.id)[0].Debit_Account_Number__r.Name;
                                             newJE.Credit_General_Ledger_Account__c = orderIdToRevRecognizedARFTL.get(o.id)[0].Credit_Account_Number__r.Name;
                                          }
                                          else if (o.Retail_Subtotal__c < 0){
                                             newJE.Credit_General_Ledger_Account__c = orderIdToRevRecognizedARFTL.get(o.id)[0].Debit_Account_Number__r.Name;
                                             newJE.Debit_General_Ledger_Account__c = orderIdToRevRecognizedARFTL.get(o.id)[0].Credit_Account_Number__r.Name;
											newJE.Amount__c = newJE.Amount__c * -1;
                                          }
										if (newJE.Amount__c != 0)
                                        	journalEntriesToUpsert.add(newJE);
                                    
                                }else{
                                    mapNew.get(o.id).addError(errorMessage, FALSE);
                                    break;
                                } 
                            }else if(alreadyHasJEofTypeRevRecAR == true && relatedRevRecognizedARJE.size() > 0 && o.RecordTypeId != orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je: relatedRevRecognizedARJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }
                            
                            //does not have related JE records of type Rev Recognized - Service AR
                            if(alreadyHasJEofTypeRevRecServiceAR == false && o.RecordTypeId == orderCOROServiceRecordTypeId){
                                if(errorMessage == null){
                                	decimal salesTax = (o.Sales_Tax__c == null) ? 0 : o.Sales_Tax__c;
                                	decimal invoiceSubTotal = (o.Invoice_Subtotal__c == null) ? 0 : o.Invoice_Subtotal__c;
									decimal serviceAR = salesTax + invoiceSubTotal;
                                    if(serviceAR > 0){
                                        Journal_Entry__c newJE = new Journal_Entry__c(
                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - Service AR',
                                            Order__c = o.id,
                                            Amount__c = serviceAR,
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedServiceARFTL.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedServiceARFTL.get(o.id)[0].Credit_Account_Number__r.Name
                                        );
                                        journalEntriesToUpsert.add(newJE);
                                    }
                                }else{
                                    mapNew.get(o.id).addError(errorMessage, FALSE);
                                    break;
                                } 
                            }else if(alreadyHasJEofTypeRevRecServiceAR == true && relatedRevRecognizedServiceARJE.size() > 0 && o.RecordTypeId == orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je: relatedRevRecognizedARJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            } 
                            
                            
                            //does not have related JE records of type Rev Recognized - Finance Fees
                            if(alreadyHasJEofTypeRevRecFinanceFees == false && o.RecordTypeId != orderCOROServiceRecordTypeId){
                                if(errorMessage == null){
                                    if(o.Finance_Program_Fees__c > 0){
                                        Journal_Entry__c newJE = new Journal_Entry__c(
                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - Finance Fees',
                                            Order__c = o.id,
                                            Amount__c = o.Finance_Program_Fees__c,
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedFinanceFeesFTL.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedFinanceFeesFTL.get(o.id)[0].Credit_Account_Number__r.Name
                                        );
                                        journalEntriesToUpsert.add(newJE);
                                    }
                                }else{
                                    mapNew.get(o.id).addError(errorMessage, FALSE);
                                    break;
                                } 
                            }else if(alreadyHasJEofTypeRevRecFinanceFees == true && relatedRevRecognizedFinanceFeesJE.size() > 0 && o.RecordTypeId != orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je: relatedRevRecognizedFinanceFeesJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }


                            
                            //does not have related JE records of type Rev Recognized - Service Tax
                            
                            if(alreadyHasJEofTypeRevRecServiceTax == false  && o.RecordTypeId == orderCOROServiceRecordTypeId){
                                if(errorMessage == null){
                                    if(o.Sales_Tax__c > 0){                                    
                                    Journal_Entry__c newJE = new Journal_Entry__c(
                                        Date__c = Datetime.Now(),
                                        Type__c = 'Rev Recognized - Service Tax',
                                        Order__c = o.id,
                                        Amount__c = o.Sales_Tax__c,
                                        Debit_General_Ledger_Account__c = orderIdToRevRecognizedServiceTaxFTL.get(o.id)[0].Debit_Account_Number__r.Name,
                                        Credit_General_Ledger_Account__c = orderIdToRevRecognizedServiceTaxFTL.get(o.id)[0].Credit_Account_Number__r.Name
                                    );
                                    journalEntriesToUpsert.add(newJE);
                                 }  
                                }else{ 
                                    mapNew.get(o.id).addError(errorMessage, FALSE);
                                    break;
                                } 
                            }else if(alreadyHasJEofTypeRevRecServiceTax == true && relatedRevRecognizedServiceTaxJE.size() > 0 && o.RecordTypeId == orderCOROServiceRecordTypeId){
                                for(Journal_Entry__c je: relatedRevRecognizedServiceTaxJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }
							
							
                            System.debug('ads journalEntriesToUpsert: '+journalEntriesToUpsert);
                            if(errorMessage == null || errorMessage == ''){
                                upsert journalEntriesToUpsert;
                            }else{
                                //there is an error message
                                mapNew.get(o.id).addError(errorMessage, FALSE);
                            }           
                        }else{
                            //there is an error message
                            mapNew.get(o.id).addError(errorMessage, FALSE);
                        }
                    }
                    
                } // END OF IF REVENUE RECOGNIZED DATE HAS CHANGED FROM BLANK/NULL TO A VALUE
                //IF REVENUE RECOGNIZED DATE HAS CHANGED FROM A VALUE TO BLANK/NULL
                else if((orderIdToJournalEntryMap != null && orderIdToJournalEntryMap.get(o.id) != null && orderIdToJournalEntryMap.get(o.id).size() > 0) && mapOld.get(o.id).Revenue_Recognized_Date__c != null && mapNew.get(o.id).Revenue_Recognized_Date__c == null){
                    list<Journal_Entry__c> relatedJEToDelete = new list<Journal_Entry__c>();
                    Boolean sentToBaanERP = false;
                    
                    for(Journal_Entry__c je : orderIdToJournalEntryMap.get(o.id)){
                        if(je.Type__c != null && je.Type__c.contains('Rev Recognized -') && je.Sent_to_BaanERP__c == true){
                                sentToBaanERP = true; break;
                        }else if(je.Type__c != null && je.Type__c.contains('Rev Recognized -')&& je.Sent_to_BaanERP__c == false){
                            relatedJEToDelete.add(je);
                        }
                    }
                    if(sentToBaanERP == true){
                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                    }else{
                        if(relatedJEToDelete.size() > 0){
                            delete relatedJEToDelete; 
                        }  
                    }

                }
                //IF REVENUE RECOGNIZED DATE HAS CHANGED FROM A VALUE TO A VALUE
                else if((mapOld.get(o.id).Revenue_Recognized_Date__c != null && mapNew.get(o.id).Revenue_Recognized_Date__c != null) && (mapOld.get(o.id).Revenue_Recognized_Date__c != mapNew.get(o.id).Revenue_Recognized_Date__c)){
                    mapNew.get(o.id).addError(RMS_errorMessages.CHANGE_REVENUE_RECOGNIZED_DATE_NOT_CLEAR, FALSE);
                }
                
               	//if error
                if(errorMessage != null && errorMessage != ''){
                	mapNew.get(o.id).addError(errorMessage, FALSE);
                }
        }//END OF ORDER LOOP
    }//END createJournalEntryOrder Method


 
    
    /***************************************************
     Method to create Journal Entry for REFUND
    ****************************************************/
    
    public void createOrUpdateJournalEntryRefund(list<Refund__c> listNew, map<id, Refund__c> mapNew, map<id, Refund__c> mapOld, String typeOfCall){
        list<Journal_Entry__c> journalEntriesToUpsert = new list<Journal_Entry__c>();

        
        list<Refund__c> extraFieldsList = [SELECT   id,
                                                    Amount__c,
                                                    Refund_Method__c,
                                                    Date__c,
                                                    Description__c,
                                                    Order__c,
                                                    Order__r.Revenue_Recognized_Date__c,
                                                    Order__r.BillToContactId,
                                                    Order__r.RecordTypeId,
                                                    CreatedById,
                                                    Name,
                                                    Store_Location__c,
                                                    Store_Location__r.Active_Store_Configuration__c
                                                    
                                                    FROM Refund__c WHERE Id IN :mapNew.keyset() AND Order__r.RecordTypeId IN :orderRecordTypes];       
    
        map<Id, list<Journal_Entry__c>> refundIdToJournalEntryMap = linkJournalEntries(extraFieldsList);
       	
       	/*
        map<Id, list<Financial_Transaction__c>>  refundIdToDepositFTL = linkFinacialTransactions(extraFieldsList, 'Deposit');
        map<Id, list<Financial_Transaction__c>>  refundIdToFinalPaymentFTL = linkFinacialTransactions(extraFieldsList, 'Final Payment');
        */
        
        list<string> financialTransactionTypesToGet = new list<string>{	'Deposit',
        																'Deposit - Check Refund',
        																'Final Payment',
        																'Final Payment - Check Refund'
        																};
       	map<string, map<Id, list<Financial_Transaction__c>>> typeToMapOfRefundIdtoListFT = linkFinancialTransactions(extraFieldsList, financialTransactionTypesToGet);
        
        map<Id, list<Financial_Transaction__c>>  refundIdToDepositFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>>  refundIdToDepositCheckFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>>  refundIdToFinalPaymentFTL = new map<Id, list<Financial_Transaction__c>>();
		map<Id, list<Financial_Transaction__c>>  refundIdToFinalPaymentCheckFTL = new map<Id, list<Financial_Transaction__c>>();
		
		refundIdToDepositFTL = typeToMapOfRefundIdtoListFT.get('Deposit');
		refundIdToDepositCheckFTL = typeToMapOfRefundIdtoListFT.get('Deposit - Check Refund');
		refundIdToFinalPaymentFTL = typeToMapOfRefundIdtoListFT.get('Final Payment');
		refundIdToFinalPaymentCheckFTL = typeToMapOfRefundIdtoListFT.get('Final Payment - Check Refund');
		
        for(Refund__c ref : extraFieldsList){
            String refundType;
            if(ref.Order__r.Revenue_Recognized_Date__c == null){ 
                if(ref.Refund_Method__c  == 'Check' || ref.Refund_Method__c == 'Cash'){
                	refundType = 'depositCheck';
                }else{
                	refundType = 'deposit';
                }
            }else if(ref.Order__r.Revenue_Recognized_Date__c != null){
                if(ref.Refund_Method__c  == 'Check' || ref.Refund_Method__c == 'Cash'){
                	refundType = 'finalPaymentCheck';
                }else{
	                refundType = 'finalPayment';
                	
                }
            }
            
            string errorMessage;
            system.debug('ads refundIdToDepositCheckFTL.get(ref.id): '+refundIdToDepositCheckFTL.get(ref.id));
            if(refundType == 'deposit'){
                errorMessage = checkFinacialTransationForErrors(refundIdToDepositFTL.get(ref.id) , errorMessage, 'Deposit');
            }else if(refundType == 'depositCheck'){
                errorMessage = checkFinacialTransationForErrors(refundIdToDepositCheckFTL.get(ref.id) , errorMessage, 'Deposit - Check Refund');
            }else if(refundType == 'finalPayment'){
                errorMessage = checkFinacialTransationForErrors(refundIdToFinalPaymentFTL.get(ref.id) , errorMessage, 'Final Payment');
            }else if(refundType == 'finalPaymentCheck'){
                errorMessage = checkFinacialTransationForErrors(refundIdToFinalPaymentCheckFTL.get(ref.id) , errorMessage, 'Final Payment - Check Refund');
            }
            
            errorMessage = checkRefundForErrors(ref, errorMessage, refundType);

            if(errorMessage == null || errorMessage == ''){
                //IF THERE ARE NO RELATED JOURNAL ENTRY
                if(refundIdToJournalEntryMap.get(ref.id) == null || refundIdToJournalEntryMap.get(ref.id).size() == 0 ){
                     
                    Journal_Entry__c newJE = new Journal_Entry__c(
                    Date__c = Datetime.Now(),
                    Refund__c = ref.id,
                    Order__c = ref.Order__c,
                    Amount__c = ref.Amount__c,
                    Customer__c = ref.Order__r.BillToContactId);
                     
     
                    if(refundType == 'deposit'){
                      newJE.Type__c = 'Refund - Deposit';
                      newJE.Debit_General_Ledger_Account__c = refundIdToDepositFTL.get(ref.id)[0].Credit_Account_Number__r.Name;
                      newJE.Credit_General_Ledger_Account__c = refundIdToDepositFTL.get(ref.id)[0].Debit_Account_Number__r.Name;
                    }else if(refundType == 'depositCheck'){
                      newJE.Type__c = 'Refund - Deposit';
                      newJE.Debit_General_Ledger_Account__c = refundIdToDepositCheckFTL.get(ref.id)[0].Debit_Account_Number__r.Name;
                      newJE.Credit_General_Ledger_Account__c = refundIdToDepositCheckFTL.get(ref.id)[0].Credit_Account_Number__r.Name;
                    }else if(refundType == 'finalPayment'){
                      newJE.Type__c = 'Refund - Final Payment';
                      newJE.Debit_General_Ledger_Account__c = refundIdToFinalPaymentFTL.get(ref.id)[0].Credit_Account_Number__r.Name;
                      newJE.Credit_General_Ledger_Account__c = refundIdToFinalPaymentFTL.get(ref.id)[0].Debit_Account_Number__r.Name;
                    }else if(refundType == 'finalPaymentCheck'){
                      newJE.Type__c = 'Refund - Final Payment';
                      newJE.Debit_General_Ledger_Account__c = refundIdToFinalPaymentCheckFTL.get(ref.id)[0].Debit_Account_Number__r.Name;
                      newJE.Credit_General_Ledger_Account__c = refundIdToFinalPaymentCheckFTL.get(ref.id)[0].Credit_Account_Number__r.Name;
                    }
                    
                    journalEntriesToUpsert.add(newJE);
                }else
                    //there is a related journal entry
                    if(refundIdToJournalEntryMap.get(ref.id).size() == 1){
                        Journal_Entry__c je = refundIdToJournalEntryMap.get(ref.id)[0];
                            if(je.Sent_to_BaanERP__c == true){
                            //Journal Entry already sent to BaanERP, throw error
                            errorMessage = RMS_errorMessages.PAYMENT_ALREADY_SUBMITTED;
                            mapNew.get(ref.id).addError(errorMessage, FALSE);
                        }else{
                            //Journal Entry NOT sent to BaanERP, update Journal Entry
                            je.Date__c = Datetime.Now();
                            je.Refund__c = ref.id;
                            je.Order__c = ref.Order__c;
                            je.Amount__c = ref.Amount__c;
                            je.Customer__c = ref.Order__r.BillToContactId;
                            
                            if(refundType == 'deposit'){
                                je.Type__c = 'Refund - Deposit';
                                je.Debit_General_Ledger_Account__c = refundIdToDepositFTL.get(ref.id)[0].Credit_Account_Number__r.Name;
                                je.Credit_General_Ledger_Account__c = refundIdToDepositFTL.get(ref.id)[0].Debit_Account_Number__r.Name;
                            }else if(refundType == 'deposit'){
                                je.Type__c = 'Refund - Deposit';
                                je.Debit_General_Ledger_Account__c = refundIdToDepositCheckFTL.get(ref.id)[0].Debit_Account_Number__r.Name;
                                je.Credit_General_Ledger_Account__c = refundIdToDepositCheckFTL.get(ref.id)[0].Credit_Account_Number__r.Name;
                            }else if(refundType == 'finalPayment'){
                                je.Type__c = 'Refund - Final Payment';
                                je.Debit_General_Ledger_Account__c = refundIdToFinalPaymentFTL.get(ref.id)[0].Credit_Account_Number__r.Name;
                                je.Credit_General_Ledger_Account__c = refundIdToFinalPaymentFTL.get(ref.id)[0].Debit_Account_Number__r.Name;
                            }else if(refundType == 'finalPaymentCheck'){
                                je.Type__c = 'Refund - Final Payment';
                                je.Debit_General_Ledger_Account__c = refundIdToFinalPaymentCheckFTL.get(ref.id)[0].Debit_Account_Number__r.Name;
                                je.Credit_General_Ledger_Account__c = refundIdToFinalPaymentCheckFTL.get(ref.id)[0].Credit_Account_Number__r.Name;
                            }
                            journalEntriesToUpsert.add(je);
                        }//END ELSE NOT SENT TO BaanERP
                    }//END IF THERE 1 RELATED JOURNAL ENTRY
                //IF MORE THAN ONE JOURNAL ENTRY
                else if(refundIdToJournalEntryMap.get(ref.id).size() != null && refundIdToJournalEntryMap.get(ref.id).size() > 1){
                    errorMessage = RMS_errorMessages.MULTIPLE_JOURNAL_ENTRIES;
                    mapNew.get(ref.id).addError(errorMessage, FALSE);
                }
            }//END IF ERROR MESSAGES NULL
            else{
            //there is an error message
            mapNew.get(ref.id).addError(errorMessage, FALSE); 
            }
            upsert journalEntriesToUpsert;
            
        }//END OF REFUND LOOP
    }   
    
	
 /***************************************************
     Method to create Journal Entry for BUSINESS ADJUSTMENT
    ****************************************************/
    
    public void createOrUpdateJournalEntryBusinessAdjustment(list<Business_Adjustment__c> listNew, map<id, Business_Adjustment__c> mapNew, map<id, Business_Adjustment__c> mapOld, String typeOfCall){
        list<Journal_Entry__c> journalEntriesToUpsert = new list<Journal_Entry__c>();
        
       	
        list<Business_Adjustment__c> extraFieldsList = [SELECT 	id,
			                                                    Name,
			                                                    Amount__c,
			                                                    Date__c,
			                                                    Description__c,
			                                                    Order__c,
			                                                    Store_Location__c,
			                                                    Store_Location__r.Active_Store_Configuration__c,
																Type__c,                                                
			                                                    Order__r.Revenue_Recognized_Date__c,
			                                                    Order__r.BillToContactId,
			                                                    Order__r.RecordTypeId
                                                    
                                                    
                                                    FROM Business_Adjustment__c WHERE Id IN :mapNew.keyset() AND Order__r.RecordTypeId IN :orderRecordTypes];       
    
        map<Id, list<Journal_Entry__c>> businessAdjustmentIdToJournalEntryMap = linkJournalEntries(extraFieldsList);
       /*
        map<Id, list<Financial_Transaction__c>>  businessAdjustmentIdToARWriteOffFTL = linkFinacialTransactions(extraFieldsList, 'AR write-off');
        map<Id, list<Financial_Transaction__c>>  businessAdjustmentIdToInstallAdjustmentFTL = linkFinacialTransactions(extraFieldsList, 'Install Adjustment');
        map<Id, list<Financial_Transaction__c>>  businessAdjustmentIdToNonSufficientFundsTransactionList = linkFinacialTransactions(extraFieldsList, 'Non-sufficient Funds');
        */
        
        list<string> financialTransactionTypesToGet = new list<string>{	'AR write-off', 
        																'Install Adjustment',
        																'Post Recognized Install Adjustment', 
        																'Non-sufficient Funds - Deposit',
        																'Non-sufficient Funds - Final Payment'
        																};
       	map<string, map<Id, list<Financial_Transaction__c>>> typeToMapOfBAIdtoListFT = linkFinancialTransactions(extraFieldsList, financialTransactionTypesToGet);
        
        map<Id, list<Financial_Transaction__c>>  BAIdToARWriteOffFTL = typeToMapOfBAIdtoListFT.get('AR write-off');
        map<Id, list<Financial_Transaction__c>>  BAIdToInstallAdjustmentFTL = typeToMapOfBAIdtoListFT.get('Install Adjustment');
        map<Id, list<Financial_Transaction__c>>  BAIdToPostRecognizedInstallAdjustmentFTL = typeToMapOfBAIdtoListFT.get('Post Recognized Install Adjustment');
        map<Id, list<Financial_Transaction__c>>  BAIdToNSFDepositFTL = typeToMapOfBAIdtoListFT.get('Non-sufficient Funds - Deposit');
        map<Id, list<Financial_Transaction__c>>  BAIdToNSFFinalPaymentFTL = typeToMapOfBAIdtoListFT.get('Non-sufficient Funds - Final Payment');
        
        for(Business_Adjustment__c ba : extraFieldsList){
            String businessAdjustmentType = ba.Type__c;
            String subBusinessAdjustmentType;
            
            string errorMessage;
            if(businessAdjustmentType == 'AR write-off'){
                errorMessage = checkFinacialTransationForErrors(BAIdToARWriteOffFTL.get(ba.id) , errorMessage, 'AR write-off');
            }else if(businessAdjustmentType == 'Install Adjustment'){
                if(ba.Order__r.Revenue_Recognized_Date__c == null){
                	subBusinessAdjustmentType = 'InstallAdjustment'; 
                	errorMessage = checkFinacialTransationForErrors(BAIdToInstallAdjustmentFTL.get(ba.id) , errorMessage, 'Install Adjustment');
                }else if(ba.Order__r.Revenue_Recognized_Date__c != null){
                	subBusinessAdjustmentType = 'PostRecognizedInstallAdjustment';
                	errorMessage = checkFinacialTransationForErrors(BAIdToPostRecognizedInstallAdjustmentFTL.get(ba.id) , errorMessage, 'Post Recognized Install Adjustment');
                }
            }else if(businessAdjustmentType == 'Non-sufficient Funds'){
                if(ba.Order__r.Revenue_Recognized_Date__c == null){
                	subBusinessAdjustmentType = 'NSFdeposit'; 
	                errorMessage = checkFinacialTransationForErrors(BAIdToNSFDepositFTL.get(ba.id) , errorMessage, 'Non-sufficient Funds - Deposit');
                }else if(ba.Order__r.Revenue_Recognized_Date__c != null){
                	subBusinessAdjustmentType = 'NSFfinalPayment';
                	errorMessage = checkFinacialTransationForErrors(BAIdToNSFFinalPaymentFTL.get(ba.id) , errorMessage, 'Non-sufficient Funds - Final Payment');
                }
                 
            }
            errorMessage = checkBussinessAdjustmentForErrors(ba, errorMessage, businessAdjustmentType);

            if(errorMessage == null || errorMessage == ''){
                //IF THERE ARE NO RELATED JOURNAL ENTRY
                if(businessAdjustmentIdToJournalEntryMap.get(ba.id) == null || businessAdjustmentIdToJournalEntryMap.get(ba.id).size() == 0 ){
                     
                    Journal_Entry__c newJE = new Journal_Entry__c(
                    Date__c = Datetime.Now(),
                    Business_Adjustment__c = ba.id,
                    Order__c = ba.Order__c,
                    Amount__c = ba.Amount__c,
                    Customer__c = ba.Order__r.BillToContactId,
                  	Type__c = businessAdjustmentType);
                     
     
                    if(businessAdjustmentType == 'AR write-off'){
                    	newJE.Debit_General_Ledger_Account__c = BAIdToARWriteOffFTL.get(ba.id)[0].Debit_Account_Number__r.Name;
                    	newJE.Credit_General_Ledger_Account__c = BAIdToARWriteOffFTL.get(ba.id)[0].Credit_Account_Number__r.Name;
                      
                    }else if(businessAdjustmentType == 'Install Adjustment'){
                    	if(subBusinessAdjustmentType == 'InstallAdjustment'){
                    		newJe.Type__c = 'Install Adjustment';
	                    	newJE.Debit_General_Ledger_Account__c = BAIdToInstallAdjustmentFTL.get(ba.id)[0].Debit_Account_Number__r.Name; 
	                		newJE.Credit_General_Ledger_Account__c = BAIdToInstallAdjustmentFTL.get(ba.id)[0].Credit_Account_Number__r.Name;
                    	}else if(subBusinessAdjustmentType == 'PostRecognizedInstallAdjustment'){
                    		newJe.Type__c = 'Post Recognized Install Adjustment';
                    		newJE.Debit_General_Ledger_Account__c = BAIdToPostRecognizedInstallAdjustmentFTL.get(ba.id)[0].Debit_Account_Number__r.Name;
	                		newJE.Credit_General_Ledger_Account__c = BAIdToPostRecognizedInstallAdjustmentFTL.get(ba.id)[0].Credit_Account_Number__r.Name;
                    	}
                    
                    }else if(businessAdjustmentType == 'Non-sufficient Funds'){
                    	if(subBusinessAdjustmentType == 'NSFdeposit'){
	                    	newJE.Debit_General_Ledger_Account__c = BAIdToNSFDepositFTL.get(ba.id)[0].Debit_Account_Number__r.Name; 
	                		newJE.Credit_General_Ledger_Account__c = BAIdToNSFDepositFTL.get(ba.id)[0].Credit_Account_Number__r.Name;
                    	}else if(subBusinessAdjustmentType == 'NSFfinalpayment'){
                    		newJE.Debit_General_Ledger_Account__c = BAIdToNSFFinalPaymentFTL.get(ba.id)[0].Debit_Account_Number__r.Name;
	                		newJE.Credit_General_Ledger_Account__c = BAIdToNSFFinalPaymentFTL.get(ba.id)[0].Credit_Account_Number__r.Name;
                    	}
                    }
                    
                    journalEntriesToUpsert.add(newJE);
                }else
                    //there is a related journal entry
                    if(businessAdjustmentIdToJournalEntryMap.get(ba.id).size() == 1){
                        Journal_Entry__c je = businessAdjustmentIdToJournalEntryMap.get(ba.id)[0];
                            if(je.Sent_to_BaanERP__c == true){
                            //Journal Entry already sent to BaanERP, throw error
                            errorMessage = RMS_errorMessages.PAYMENT_ALREADY_SUBMITTED;
                            mapNew.get(ba.id).addError(errorMessage, FALSE);
                        }else{
                            //Journal Entry NOT sent to BaanERP, update Journal Entry
							je.Date__c = Datetime.Now();
		                    je.Business_Adjustment__c = ba.id;
		                    je.Order__c = ba.Order__c;
		                    je.Amount__c = ba.Amount__c;
		                    je.Customer__c = ba.Order__r.BillToContactId;
		                  	je.Type__c = businessAdjustmentType;
                     
     
		                    if(businessAdjustmentType == 'AR write-off'){
		                      je.Debit_General_Ledger_Account__c = BAIdToARWriteOffFTL.get(ba.id)[0].Debit_Account_Number__r.Name;
		                      je.Credit_General_Ledger_Account__c = BAIdToARWriteOffFTL.get(ba.id)[0].Credit_Account_Number__r.Name;
		                      
		                    }else if(businessAdjustmentType == 'Install Adjustment'){
		                     	if(subBusinessAdjustmentType == 'InstallAdjustment'){
		                     		je.Type__c = 'Install Adjustment';
			                    	je.Debit_General_Ledger_Account__c = BAIdToInstallAdjustmentFTL.get(ba.id)[0].Debit_Account_Number__r.Name;
			                		je.Credit_General_Ledger_Account__c = BAIdToInstallAdjustmentFTL.get(ba.id)[0].Credit_Account_Number__r.Name;
		                    	}else if(subBusinessAdjustmentType == 'PostRecognizedInstallAdjustment'){
		                     		je.Type__c = 'Post Recognized Install Adjustment';
		                    		je.Debit_General_Ledger_Account__c = BAIdToPostRecognizedInstallAdjustmentFTL.get(ba.id)[0].Debit_Account_Number__r.Name;
			                		je.Credit_General_Ledger_Account__c = BAIdToPostRecognizedInstallAdjustmentFTL.get(ba.id)[0].Credit_Account_Number__r.Name;
	                    		}
		                    
		                    }else if(businessAdjustmentType == 'Non-sufficient Funds'){
		                     	if(subBusinessAdjustmentType == 'NSFdeposit'){
			                    	je.Debit_General_Ledger_Account__c = BAIdToNSFDepositFTL.get(ba.id)[0].Debit_Account_Number__r.Name;
			                		je.Credit_General_Ledger_Account__c = BAIdToNSFDepositFTL.get(ba.id)[0].Credit_Account_Number__r.Name;
		                    	}else if(subBusinessAdjustmentType == 'NSFfinalpayment'){
		                    		je.Debit_General_Ledger_Account__c = BAIdToNSFFinalPaymentFTL.get(ba.id)[0].Debit_Account_Number__r.Name;
			                		je.Credit_General_Ledger_Account__c = BAIdToNSFFinalPaymentFTL.get(ba.id)[0].Credit_Account_Number__r.Name;
	                    		}
		                    }
                            journalEntriesToUpsert.add(je);
                        }//END ELSE NOT SENT TO BaanERP
                    }//END IF THERE 1 RELATED JOURNAL ENTRY
                //IF MORE THAN ONE JOURNAL ENTRY
                else if(businessAdjustmentIdToJournalEntryMap.get(ba.id).size() != null && businessAdjustmentIdToJournalEntryMap.get(ba.id).size() > 1){
                    errorMessage = RMS_errorMessages.MULTIPLE_JOURNAL_ENTRIES;
                    mapNew.get(ba.id).addError(errorMessage, FALSE);
                }
            }//END IF ERROR MESSAGES NULL
            else{
            //there is an error message
            mapNew.get(ba.id).addError(errorMessage, FALSE); 
            }
            upsert journalEntriesToUpsert;
            
        }//END OF BUISINESS ADJUSTMENT LOOP
    }   
    

    /***************************************************
     Method to link object Id to a list of Journal_Entry__c
    ****************************************************/
    public map<id, list<Journal_Entry__c>> linkJournalEntries(list<SObject> objectList){
        list<id> idList = new list<id>();
        for(SObject o : objectList){
            idList.add(o.id);
        }
        list<Journal_Entry__c> relatedJournalEntries = [SELECT  id, 
                                                                Payment__c,
                                                                Labor__c,
                                                                Asset__c,
                                                                Order__c,
                                                                Refund__c,
                                                                Business_Adjustment__c,
                                                                Sent_to_BaanERP__c, 
                                                                Type__c,
                                                                Customer__c,
                                                                Amount__c,
                                                                Baan_Business_Partner_Number__c,
                                                                Debit_General_Ledger_Account__c,
                                                                Credit_General_Ledger_Account__c
                                                                FROM Journal_Entry__c WHERE Payment__c IN :idList 
                                                                                        OR Labor__c IN :idList 
                                                                                        OR Asset__c IN :idList 
                                                                                        OR Order__c IN :IdList
                                                                                        OR Refund__c IN :IdList
                                                                                        OR Business_Adjustment__c IN :IdList];
        system.debug('Method:linkJournalEntries relatedJournalEntries: '+relatedJournalEntries);                                                        
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
        }else if(String.ValueOf(objectList[0].getSObjectType()) == 'Asset'){
            for(Journal_Entry__c je : relatedJournalEntries){
                if(idToJournalEntryMap.containsKey(je.Asset__c) ){
                    idToJournalEntryMap.get(je.Asset__c).add(je);
                }
                else{
                    idToJournalEntryMap.put(je.Asset__c, new list<Journal_Entry__c>{je});
                }
            }
        }else if(String.ValueOf(objectList[0].getSObjectType()) == 'Order'){
            for(Journal_Entry__c je : relatedJournalEntries){
                if(idToJournalEntryMap.containsKey(je.Order__c) ){
                    idToJournalEntryMap.get(je.Order__c).add(je);
                }
                else{
                    idToJournalEntryMap.put(je.Order__c, new list<Journal_Entry__c>{je});
                }
            }
        }else if(String.ValueOf(objectList[0].getSObjectType()) == 'Refund__c'){
            for(Journal_Entry__c je : relatedJournalEntries){
                if(idToJournalEntryMap.containsKey(je.Refund__c) ){
                    idToJournalEntryMap.get(je.Refund__c).add(je);
                }
                else{
                    idToJournalEntryMap.put(je.Refund__c, new list<Journal_Entry__c>{je});
                }
            }
        }else if(String.ValueOf(objectList[0].getSObjectType()) == 'Business_Adjustment__c'){
            for(Journal_Entry__c je : relatedJournalEntries){
                if(idToJournalEntryMap.containsKey(je.Business_Adjustment__c) ){
                    idToJournalEntryMap.get(je.Business_Adjustment__c).add(je);
                }
                else{
                    idToJournalEntryMap.put(je.Business_Adjustment__c, new list<Journal_Entry__c>{je});
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
        list<Id> storeConfigListId = new list<Id>();
        
        for(SObject o : objectList){
            paymentIdList.add(o.id);
        	storeConfigListId.add((id)String.valueOf(o.getSObject('Store_Location__r').get('Active_Store_Configuration__c')));
        } 
        system.debug('ads storeConfigListId: '+storeConfigListId);
        list<Financial_Transaction__c> relatedFinancialTransactions = [SELECT   id, 
                                                                                Store_Configuration__c, 
                                                                                Store_Configuration__r.Store__c,
                                                                                Credit_Account_Number__c,
                                                                                Credit_Account_Number__r.Name,
                                                                                Debit_Account_Number__c,
                                                                                Debit_Account_Number__r.Name
                                                                            FROM Financial_Transaction__c 
                                                                            WHERE Store_Configuration__c IN :storeConfigListId
                                                                            AND Transaction_Type__c = :typeToGet
                                                                            ];
        system.debug('ads relatedFinancialTransactions: '+relatedFinancialTransactions);
        map<id, list<Financial_Transaction__c>> storeIdToListFinancialTransaction = new map<id, list<Financial_Transaction__c>>();
        for(Financial_Transaction__c ft : relatedFinancialTransactions){
            if(storeIdToListFinancialTransaction.containsKey(ft.Store_Configuration__r.Store__c) ){
                storeIdToListFinancialTransaction.get(ft.Store_Configuration__r.Store__c).add(ft);
            }else{
                storeIdToListFinancialTransaction.put(ft.Store_Configuration__r.Store__c, new list<Financial_Transaction__c>{ft});
            }
        }
         
        map<id, list<Financial_Transaction__c>> paymentIdToListFinancialTransaction = new map<id, list<Financial_Transaction__c>>();
        for(SObject o : objectList){
            paymentIdToListFinancialTransaction.put(o.id, storeIdToListFinancialTransaction.get((Id)o.get('Store_Location__c')));
        }
        system.debug('ads paymentIdToListFinancialTransaction: '+paymentIdToListFinancialTransaction);
        return paymentIdToListFinancialTransaction;
    }
	
	    
	    
	    
    public map<string, map<id, list<SObject>>> linkFinancialTransactions(list<SObject> objectList, list<string> typesToGet){
    	list<id> objectIdList = new list<id>();
        list<Id> storeConfigListId = new list<Id>();
        for(SObject o :objectList){
        	objectIdList.add(o.id);
        	storeConfigListId.add((id)String.valueOf(o.getSObject('Store_Location__r').get('Active_Store_Configuration__c')));
        }
     	list<Financial_Transaction__c> relatedFinancialTransactions = [SELECT   id, 
                                                                                Store_Configuration__c, 
                                                                                Store_Configuration__r.Store__c,
                                                                                Credit_Account_Number__c,
                                                                                Credit_Account_Number__r.Name,
                                                                                Debit_Account_Number__c,
                                                                                Debit_Account_Number__r.Name,
                                                                                Transaction_Type__c
                                                                            FROM Financial_Transaction__c 
                                                                            WHERE Store_Configuration__c IN :storeConfigListId
                                                                            AND Transaction_Type__c IN :typesToGet
                                                                            ];
        system.debug('ads fixing FT method: relatedFinancialTransactions: '+relatedFinancialTransactions);                                                                    
        map<string, map<id, list<SObject>>> transactionTypeToMapOfStoreIdToListofFT = new map<string, map<id, list<SObject>>>();
        map<string, list<Financial_Transaction__c>> typeOfTransactionToListOfFTMap = new map<string, list<Financial_Transaction__c>>();
		for(Financial_Transaction__c rft :relatedFinancialTransactions){
			if(typeOfTransactionToListOfFTMap.containsKey(rft.Transaction_Type__c) ){
				typeOfTransactionToListOfFTMap.get(rft.Transaction_Type__c).add(rft);
			}else{
			typeOfTransactionToListOfFTMap.put(rft.Transaction_Type__c, new list<Financial_Transaction__c>{rft});
			}
		}
		for(string aType :typesToGet){
         		
         		map<id, list<Financial_Transaction__c>> storeIdToListFinancialTransaction = new map<id, list<Financial_Transaction__c>>();
		        if(typeOfTransactionToListOfFTMap.get(atype) != null){
			        for(Financial_Transaction__c ft : typeOfTransactionToListOfFTMap.get(atype)){
			            if(storeIdToListFinancialTransaction.containsKey(ft.Store_Configuration__r.Store__c) ){
			                storeIdToListFinancialTransaction.get(ft.Store_Configuration__r.Store__c).add(ft);
			            }else{
			                storeIdToListFinancialTransaction.put(ft.Store_Configuration__r.Store__c, new list<Financial_Transaction__c>{ft});
			            }
			        }
		        }
				map<id, list<Financial_Transaction__c>> objectIDtoListOfFinancialTransaction = new map<id, list<Financial_Transaction__c>>();
				for(SObject o :objectList){
					
					objectIDtoListOfFinancialTransaction.put(o.id, storeIdToListFinancialTransaction.get((Id)o.get('Store_Location__c')) );
		    	}
	     		transactionTypeToMapOfStoreIdToListofFT.put(aType, objectIDtoListOfFinancialTransaction);
     	}
		return transactionTypeToMapOfStoreIdToListofFT;
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
        }else if((ftList == null || ftList.size() == 0)){
            dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.NO_FINACIAL_TRANSACTION_RECORDS, '[Transaction Type]', objectType);
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }else{
            //CHECK IF CREDIT ACCOUNT NUMBER IS NULL
            if(objectType != 'Misc Cash Receipt' && ftList[0].Credit_Account_Number__c == null ){
                dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.FINACIAL_TRANSACTION_RECORDS_NO_CREDIT_ACCOUNT_NUMBER, '[Transaction Type]', objectType);
                errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
            }
            //CHECK IF DEBIT ACCOUNT NUMBER IS NULL
            if(objectType != 'Misc Reimbursement' && ftList[0].Debit_Account_Number__c == null && ftList[0].Transaction_Type__c != 'Cost Product Received' ){
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
        if(payment.GL_Account__r.Name == null && typeOfPayment == 'MiscCashReceipt'){
            dynamicErrorMessage = RMS_errorMessages.ACCOUNT_NUMBER_NULL;
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }else if(typeOfPayment == 'MiscCashReceipt' && payment.GL_Account__r.Name != null && payment.GL_Account__r.Name.length() <= 3 ){
            dynamicErrorMessage = RMS_errorMessages.GLA_NUMBER_THREE_OR_LESS;
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
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
            (labor.Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c == null || labor.Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c == '')){
            dynamicErrorMessage = RMS_errorMessages.INSTALLER_HAS_NO_BAAN_NUMBER;
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        if(labor.GL_Account__r.Name == null && typeOfLabor == 'LaborMiscReimbursement'){
            dynamicErrorMessage = RMS_errorMessages.ACCOUNT_NUMBER_NULL;
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }else if(typeOfLabor == 'LaborMiscReimbursement' && labor.GL_Account__r.Name != null && labor.GL_Account__r.Name.length() <= 3){
            dynamicErrorMessage = RMS_errorMessages.GLA_NUMBER_THREE_OR_LESS;
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        
        return errorMessage;        
    }
    
    /***************************************************
     Method to run error checks against the Asset Object
    ****************************************************/
    public String checkAssetForErrors(Asset asset, string errorMessage, string assetSubType, boolean vendorCreditAT){
        String dynamicErrorMessage;
        //If the Asset Id, Order, Unit Wholesale Cost, Quantity, Customer Id 

        if(asset.id == null){ 
            dynamicErrorMessage = RMS_errorMessages.ASSET_ID_IS_NULL;
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        if(asset.Sold_Order__c == null){
            dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.REQUIRED_FIELD_IS_NULL, '[field]', 'Order');
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        } 
        /*
        if(asset.Unit_Wholesale_Cost__c == null){
            dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.REQUIRED_FIELD_IS_NULL, '[field]', 'Unit Wholesale Cost');
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        if(asset.Quantity == null){
            dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.REQUIRED_FIELD_IS_NULL, '[field]', 'Quantity');
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        */
        if(asset.Quantity < 0){
            dynamicErrorMessage = RMS_errorMessages.QUANTITY_IS_LESS_THAN_ZERO;
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        // Turned this off temporarily. Not sure if we need to do this check or not
        // Cost POs will not have a contact     
/*      if(asset.Sold_Order__r.BillToContactId == null){
            dynamicErrorMessage = RMS_errorMessages.BILL_TO_CONTACT_ON_ORDER_NULL;
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }*/
        if(asset.Sold_Order__r.Store_Location__c == null){
            dynamicErrorMessage = RMS_errorMessages.STORE_LOCATION_ON_ORDER_NULL;
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        
        if(vendorCreditAT == true && asset.Vendor__r.Baan_Business_Partner_Number__c == null){
        	dynamicErrorMessage = RMS_errorMessages.VENDOR_HAS_NO_BAAN_NUMBER;
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
	 // TODO:  Update all test classes with a vendor where assets are created     
     //   if(asset.Vendor__c == null){
     //       dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.REQUIRED_FIELD_IS_NULL, '[field]', 'Vendor');
     //       errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
     //   } 

        return errorMessage;        
    }
    
    
    /***************************************************
     Method to run error checks against the ORDER Journal Entry
    ****************************************************/
    public String checkOrderJEForErrors(Journal_Entry__c je, string errorMessage, string typeOfJE){
        
        String dynamicErrorMessage;
        if(typeOfJE == 'deposit'){
            if(je.Payment__c == null){
                dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.JOURNAL_ENTRY_FIELD_NULL_ON_ORDER_NULL_DEPOSIT, '[field]', 'Payment');
                errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
            }
            if(je.Customer__c == null){
                dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.JOURNAL_ENTRY_FIELD_NULL_ON_ORDER_NULL_DEPOSIT, '[field]', 'Customer');
                errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
            }
        }
        if(typeOfJE == 'installadjustment'){
            if(je.Business_Adjustment__c == null){
                dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.JOURNAL_ENTRY_FIELD_NULL_ON_ORDER_NULL_INSTALL_ADJ, '[field]', 'Business Adjustment');
                errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
            }
        }
        if(typeOfJE == 'labor' || typeOfJE == 'internallabor'){
            if(je.Amount__c == null){
                dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.JOURNAL_ENTRY_FIELD_NULL_ON_ORDER_NULL_LABOR, '[field]', 'Amount');
                errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
            }
            if(je.Baan_Business_Partner_Number__c == null && typeOfJE == 'labor'){
                dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.JOURNAL_ENTRY_FIELD_NULL_ON_ORDER_NULL_LABOR, '[field]', 'Baan Business Partner Id');
                errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
            }
        }
        
        return errorMessage;        
    }
    
    
    /***************************************************
     Method to run error checks against the REFUND Object
    ****************************************************/
    public String checkRefundForErrors(Refund__c ref, string errorMessage, string typeOfJE){
        
        String dynamicErrorMessage;
        
        if(ref.id == null){ 
            dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.REQUIRED_REFUND_FIELD_NULL, '[field]', 'Id');
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        if(ref.Order__c == null){
            dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.REQUIRED_REFUND_FIELD_NULL, '[field]', 'Order');
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        if(ref.Amount__c == null){
            dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.REQUIRED_REFUND_FIELD_NULL, '[field]', 'Amount');
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        if(ref.Store_Location__c == null){
            dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.REQUIRED_REFUND_FIELD_NULL, '[field]', 'Store Location');
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        if(ref.Order__r.BillToContactId == null){
            dynamicErrorMessage = RMS_errorMessages.CONTACT_IS_NULL;
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }

        return errorMessage;        
    }
    
        
    /***************************************************
     Method to run error checks against the BUSINESS ADJUSTMENT Object
    ****************************************************/
    public String checkBussinessAdjustmentForErrors(Business_Adjustment__c ba, string errorMessage, string typeOfBA){
        
        String dynamicErrorMessage;
        
        if(ba.id == null){ 
            dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.REQUIRED_REFUND_FIELD_NULL, '[field]', 'Id');
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        if(ba.Order__c == null){
            dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.REQUIRED_REFUND_FIELD_NULL, '[field]', 'Order');
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        if(ba.Amount__c == null){
            dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.REQUIRED_REFUND_FIELD_NULL, '[field]', 'Amount');
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        if(ba.Store_Location__c == null){
            dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.REQUIRED_REFUND_FIELD_NULL, '[field]', 'Store Location');
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        if(ba.Order__r.BillToContactId == null){
            dynamicErrorMessage = RMS_errorMessages.CONTACT_IS_NULL;
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }

        return errorMessage;        
    }
    
    
    
    
    /***************************************************
     Methods to lock records (Not used)
    ****************************************************/
    // TODO: Make these completely generic for sObjects?
/*    public void lockPaymentRecords(list<Payment__c> listNew){   

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
        
    }*/

/*    public void lockPaymentRecords(list<Payment__c> listOld, map<id,Payment__c> mapNew ){   

        List<Payment__c> recordsWithNullProcessedDate = new List<Payment__c>();

        // loop through the old list and if the processed date was null, send it to the lock records to test the new list
        for(Payment__c pOld : listOld){
            if( pOld.Processed_Date__c == null){
                recordsWithNullProcessedDate.add(mapNew.get(pOld.id));
            }
        }   
        lockPaymentRecords(recordsWithNullProcessedDate);   
    }*/

    /***************************************************
     Method to dynamicly change error messages
    ****************************************************/
    public static string fillInErrorRuleValues(String errorMessage, String targetValue, String replacementValue){
        errorMessage = errorMessage.replace(targetValue, '<b>('+replacementValue+')</b>');
        errorMessage = errorMessage.replace('null', '');
        
        return errorMessage;
    } 
    /***************************************************
     Method to dynamicly create account number from GL Account number and Location Numkber
    ****************************************************/
    public map<Id, string> linkMiscPaymentAccountNumbers(list<SObject> objectList, map<id, SObject> mapNew){
        map<Id, string> mapToReturn = new map<Id, string>();
        list<id> storeLocationIdList = new list<id>();
		map<id,Id> storeIdToStoreConfigIdMap = new map<id,Id>();       
        for(SObject theObject : objectList){  
            storeLocationIdList.add((id)theObject.get('Store_Location__c'));
        }
		for (Account store : [SELECT Id, Active_Store_Configuration__c FROM Account WHERE Id IN: storeLocationIdList]) {
			if (store.Active_Store_Configuration__c != null)
				storeIdToStoreConfigIdMap.put(store.Id, store.Active_Store_Configuration__c);			
		}

        map<Id, Store_Configuration__c> storeConfigMap = UtilityMethods.mapStoreConfigs(storeIdToStoreConfigIdMap);
        
        for(SObject theObject : objectList){
            String GLAccount;
            if(String.ValueOf(objectList[0].getSObjectType()) == 'Payment__c'){
                Payment__c payment = (Payment__c)theObject;
                GLAccount = payment.GL_Account__r.Name;
            
            }else if(String.ValueOf(objectList[0].getSObjectType()) == 'Labor__c'){
                Labor__c labor = (Labor__c)theObject;
                GLAccount = labor.GL_Account__r.Name;
    
            }
            if(GLAccount == null || GLAccount.length() <= 3){
                break;
            }

			// Commented out this creation of the GL Account number for JETT-3959
/*            string locationNumber;
            if(storeConfigMap == null || storeConfigMap.size() == 0 || storeConfigMap.get((id)theObject.get('Store_Location__c')).Location_Number__c == null ){
                mapNew.get(theObject.id).addError(RMS_errorMessages.LOCATION_ID_IS_NULL, FALSE);
            }else{
                locationNumber = storeConfigMap.get((id)theObject.get('Store_Location__c')).Location_Number__c;
            }
            
            integer glLength = GLAccount.length();
            
            string glFirstSection = GLAccount.substring(0, glLength-3);
            string glSecondSection =GLAccount.substring(glLength-3);
            string newCode = glFirstSection+locationNumber+glSecondSection;
            mapToReturn.put((id)theObject.get('Id'), newCode); */
            mapToReturn.put((id)theObject.get('Id'), GLAccount);
        }
        return mapToReturn;
    }

    /*
    public class miscPaymentAccountNumbers{
        public string debitAccountNumber {get; set;}
        public string creditAccountNumber {get; set;}
        
        public miscPaymentAccountNumbers(string debitNumber, string creditNumber){
            debitAccountNumber = debitNumber;
            creditAccountNumber = creditNumber;
        }
    }
    */
    
}
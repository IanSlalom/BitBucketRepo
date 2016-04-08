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

    //PAYMENT
    public void onAfterInsertPayment(list<Payment__c> listNew, map<id,Payment__c> mapNew){
        createOrUpdateJournalEntryPayment(listNew, mapNew);
        //TODO:This locking functionality will eventually get moved to a batch process
//      lockPaymentRecords(listNew);
    }

    public void onAfterUpdatePayment(list<Payment__c> listOld, list<Payment__c> listNew, map<Id, Payment__c> mapOld, map<Id, Payment__c> mapNew){
        createOrUpdateJournalEntryPayment(listNew, mapNew);
//      lockPaymentRecords(listOld, mapNew);
    }
    
    public void onBeforeDeletePayment(list<Payment__c> listOld, map<Id, Payment__c> mapOld){
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
    
    //ASSET
    public void onAfterInsertAsset(list<Asset> listNew, map<id,Asset> mapNew){
        createOrUpdateJournalEntryAsset(listNew, mapNew, null, 'insert');
    }

    public void onAfterUpdateAsset(list<Asset> listOld, list<Asset> listNew, map<Id, Asset> mapOld, map<Id, Asset> mapNew){
        createOrUpdateJournalEntryAsset(listNew, mapNew, mapOld, 'update');
    }
    
    public void onBeforeDeleteAsset(list<Asset> listOld, map<Id, Asset> mapOld){
        allowDeleteOrNot(listOld, mapOld);
    }
    
    //ORDER
    public void onAfterUpdateOrder(list<Order> listOld, list<Order> listNew, map<Id, Order> mapOld, map<Id, Order> mapNew){
        createJournalEntryOrder(listNew, mapNew, mapOld);
    }
    
    public void onBeforeDeleteOrder(list<Order> listOld, map<Id, Order> mapOld){
        allowDeleteOrNot(listOld, mapOld);
    }
    
    //REFUND
    public void onAfterInsertAsset(list<Refund__c> listNew, map<id,Refund__c> mapNew){
        createOrUpdateJournalEntryRefund(listNew, mapNew, null, 'insert');
    }
    
    public void onAfterUpdateOrder(list<Refund__c> listOld, list<Refund__c> listNew, map<Id, Refund__c> mapOld, map<Id, Refund__c> mapNew){
        createOrUpdateJournalEntryRefund(listNew, mapNew, mapOld, 'update');
    }
    
    public void onBeforeDeleteOrder(list<Refund__c> listOld, map<Id, Refund__c> mapOld){
        allowDeleteOrNot(listOld, mapOld);
    }
    
    //BUSINESS ADJUSTMENT
    public void onAfterInsertAsset(list<Business_Adjustment__c> listNew, map<id,Business_Adjustment__c> mapNew){
        createOrUpdateJournalEntryBusinessAdjustment(listNew, mapNew, null, 'insert');
    }
    
    public void onAfterUpdateOrder(list<Business_Adjustment__c> listOld, list<Business_Adjustment__c> listNew, map<Id, Business_Adjustment__c> mapOld, map<Id, Business_Adjustment__c> mapNew){
        createOrUpdateJournalEntryBusinessAdjustment(listNew, mapNew, mapOld, 'update');
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
                                                    Payment_Amount__c,
                                                    Payment_Type__c,
                                                    Order__r.Store_Location__c,
                                                    RecordTypeId,
                                                    Store_Location__c,
                                                    GL_Account__r.Name
                                                    
                                                    FROM Payment__c WHERE Id IN :mapNew.keyset()];      
        
        map<Id, list<Journal_Entry__c>> paymentIdToJournalEntryMap = linkJournalEntries(extraFieldsList);
        map<Id, list<Financial_Transaction__c>>  paymentIdToDepositFTL = linkFinacialTransactions(extraFieldsList, 'Deposit');
        map<Id, list<Financial_Transaction__c>>  paymentIdToFinalPaymentFTL = linkFinacialTransactions(extraFieldsList, 'Final Payment');
        map<Id, list<Financial_Transaction__c>>  paymentIdToMiscCashReceiptFTL = linkFinacialTransactions(extraFieldsList, 'Misc Cash Receipt');
        map<Id, String> paymentIdToMiscCashReceiptCreditGLAmap = linkMiscPaymentAccountNumbers(extraFieldsList, mapNew);
        
        /*********************************************************
        Building new misc cash receipt finacial transaction list map
        ************************************************************/
        
        system.debug('ads paymentIdToMiscCashReceiptFTL: '+paymentIdToMiscCashReceiptFTL);
        Id paymentDespositRecordTypeId = UtilityMethods.retrieveRecordTypeId('Deposit', 'Payment__c');
        Id paymentMiscCashReceiptRecordTypeId = UtilityMethods.retrieveRecordTypeId('Misc_Cash_Receipt', 'Payment__c');
        
        
        
        //LINKING ALL PAYMENTS THAT ARE EITHER DEPOSIT OR FINAL PAYMENT TO ORDER.
       
        list<Id> relatedOrderIds = new list<Id>();
        for(Payment__c p : extraFieldsList){
        	relatedOrderIds.add(p.Order__c);
        } 
        list<Payment__c> allRelatedPayments = [SELECT  	id,
	                                                    Order__c,
	                                                    Order__r.BillToContactId,
	                                                    Order__r.Retail_Total__c,
	                                                    Payment_Amount__c,
	                                                    Payment_Type__c,
	                                                    Order__r.Store_Location__c,
	                                                    RecordTypeId,
	                                                    Store_Location__c,
	                                                    GL_Account__r.Name
                                                    
                                                    FROM Payment__c WHERE Order__c IN :relatedOrderIds];
                                                    
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
            if(p.RecordTypeId == paymentDespositRecordTypeId && p.Payment_Type__c == 'Deposit'){
                typeOfPayment = 'DepositDeposit';
            }else if(p.RecordTypeId == paymentDespositRecordTypeId && p.Payment_Type__c == 'Final Payment'){
                typeOfPayment = 'DepositFinalPayment';
            }else if( p.RecordTypeId == paymentMiscCashReceiptRecordTypeId){
                typeOfPayment = 'MiscCashReceipt';
            }
            
            
            if(typeOfPayment != null){
                string errorMessage;
                if(typeOfPayment == 'DepositDeposit'){
                    errorMessage = checkFinacialTransationForErrors(paymentIdToDepositFTL.get(p.id) , errorMessage, p.Payment_Type__c);
                }else if(typeOfPayment == 'DepositFinalPayment'){
                    errorMessage = checkFinacialTransationForErrors(paymentIdToFinalPaymentFTL.get(p.id) , errorMessage, p.Payment_Type__c);
                }else if(typeOfPayment == 'MiscCashReceipt'){
                    errorMessage = checkFinacialTransationForErrors(paymentIdToMiscCashReceiptFTL.get(p.id) , errorMessage, 'Misc Cash Receipt');
                }
                
                errorMessage = checkPaymentForErrors(p, errorMessage, typeOfPayment);
                
                if(errorMessage == null || errorMessage == ''){
                    
                    if(paymentIdToJournalEntryMap.get(p.id) == null || paymentIdToJournalEntryMap.get(p.id).size() == 0 ){
 
                        system.debug('ads p: '+p);
                        system.debug('ads p.Order__r.BillToContactId,: '+p.Order__r.BillToContactId);
                        
                        //CHECK THAT SUM OF PAYMENT TYPES IS NOT GREATER THAN ORDER TOTAL
                        Decimal paymentTotal = 0;
                        for(Payment__c payment :orderIdToListOfDFPPayments.get(p.Order__c)){
                        	if(payment.Payment_Type__c == 'Deposit' || payment.Payment_Type__c == 'Final Payment'){
                        		paymentTotal = paymentTotal + payment.Payment_Amount__c;
                        	}
                        }
                        if(paymentTotal+p.Payment_Amount__c > p.Order__r.Retail_Total__c){
                        	 errorMessage = RMS_errorMessages.AMOUNT_OF_PAYMENT_EXCEEDS_PRICE;
                             mapNew.get(p.id).addError(errorMessage, FALSE);
                        } 
                        Journal_Entry__c newJE = new Journal_Entry__c(
                            Date__c = Datetime.Now(),
                            Payment__c = p.id,
                            Order__c = p.Order__c,
                            Amount__c = p.Payment_Amount__c,
                            Customer__c = p.Order__r.BillToContactId);
                        
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
		                        if(paymentTotal > p.Order__r.Retail_Total__c){
		                        	 errorMessage = RMS_errorMessages.AMOUNT_OF_PAYMENT_EXCEEDS_PRICE;
		                             mapNew.get(p.id).addError(errorMessage, FALSE);
		                        }
		                        
		                        
                                //Journal Entry NOT sent to BaanERP, update Journal Entry
                                system.debug('ads inside not sent to Baan: '+ je);
                                je.Date__c = Datetime.Now();
                                je.Payment__c = p.id;
                                je.Order__c = p.Order__c;
                                je.Amount__c = p.Payment_Amount__c;
                                je.Customer__c = p.Order__r.BillToContactId;
                                
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
                                                    Labor_Complete__c,
                                                    Related_Work_Order__c,
                                                    Related_Work_Order__r.Sold_Order__c,
                                                    Standard_Hourly_Rate__c,
                                                    Store_Location__c,
                                                    Related_Work_Order__r.Sold_Order__r.Store_Location__c,
                                                    Related_Work_Order__r.Sold_Order__r.Revenue_Recognized_Date__c,
                                                    Work_Order_Type__c,
                                                    CreatedById,
                                                    Name,
                                                    RecordTypeId 
                                                    
                                                    FROM Labor__c WHERE Id IN :mapNew.keyset()];        
        
        map<Id, list<Journal_Entry__c>> laborIdToJournalEntryMap = linkJournalEntries(extraFieldsList);

        map<Id, list<Financial_Transaction__c>>  laborIdToLaborFTL = linkFinacialTransactions(extraFieldsList, 'Internal Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToLaborExternalFTL = linkFinacialTransactions(extraFieldsList, 'External Labor');
        
        map<Id, list<Financial_Transaction__c>>  laborIdToLaborPostRecInternalFTL = linkFinacialTransactions(extraFieldsList, 'Post Recognized Internal Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToLaborPostRecExternalFTL = linkFinacialTransactions(extraFieldsList, 'Post Recognized External Labor');
        
        map<Id, list<Financial_Transaction__c>>  laborIdToMiscReimbursementFTL = linkFinacialTransactions(extraFieldsList, 'Misc Reimbursement');
        map<Id, String> laborIdToMiscReimbursementGLAmap = linkMiscPaymentAccountNumbers(extraFieldsList, mapNew);
        
        Id laborLaborRecordTypeId = UtilityMethods.retrieveRecordTypeId('Labor', 'Labor__c');
        Id laborMiscReimbursementRecordTypeId = UtilityMethods.retrieveRecordTypeId('Misc_Reimbursement', 'Labor__c');
      
        for(Labor__c l : extraFieldsList){
            String typeOfLabor;
            String subTypeOfLabor;
            if(l.RecordTypeId == laborLaborRecordTypeId && l.Related_Work_Order__r.Sold_Order__r.Revenue_Recognized_Date__c == null){
                typeOfLabor = 'LaborLabor';
                if(l.External_Labor_Amount__c == null || l.External_Labor_Amount__c == 0){
                	subTypeOfLabor = 'internal';
                }else if(l.External_Labor_Amount__c != null && l.External_Labor_Amount__c != 0){
                	subTypeOfLabor = 'external';
                }
            }
            else if(l.RecordTypeId == laborLaborRecordTypeId && l.Related_Work_Order__r.Sold_Order__r.Revenue_Recognized_Date__c != null){
				typeOfLabor = 'PostRecLabor';
               	if(l.External_Labor_Amount__c == null || l.External_Labor_Amount__c == 0){
                	subTypeOfLabor = 'internal';
                }else if(l.External_Labor_Amount__c != null && l.External_Labor_Amount__c != 0){
                	subTypeOfLabor = 'external';
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
                        errorMessage = checkFinacialTransationForErrors(laborIdToLaborExternalFTL.get(l.id) , errorMessage, 'External Labor');
                    }else if(subTypeOfLabor == 'internal'){
                        errorMessage = checkFinacialTransationForErrors(laborIdToLaborFTL.get(l.id) , errorMessage, 'Internal Labor');
                    }
                }else if(typeOfLabor == 'PostRecLabor'){
                    if(subTypeOfLabor == 'external'){
                        errorMessage = checkFinacialTransationForErrors(laborIdToLaborPostRecExternalFTL.get(l.id) , errorMessage, 'Post Recognized External Labor');
                    }else if(subTypeOfLabor == 'internal'){
                        errorMessage = checkFinacialTransationForErrors(laborIdToLaborPostRecInternalFTL.get(l.id) , errorMessage, 'Post Recognized Internal Labor');
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
                                    newJE.Type__c = 'External Labor';
                                    newJE.Amount__c = l.External_Labor_Amount__c;
                                    newJE.Baan_Business_Partner_Number__c = l.Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c;
                                    
                                    newJE.Debit_General_Ledger_Account__c = laborIdToLaborExternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
                                    newJE.Credit_General_Ledger_Account__c = laborIdToLaborExternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                                }else if(subTypeOfLabor == 'internal'){
                                    newJE.Type__c = 'Internal Labor';
                                    newJe.Amount__c = l.Internal_Cost__c;
                                    
                                    newJE.Debit_General_Ledger_Account__c = laborIdToLaborFTL.get(l.id)[0].Debit_Account_Number__r.Name;
                                    newJE.Credit_General_Ledger_Account__c = laborIdToLaborFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                                }
                            }else if(typeOfLabor == 'PostRecLabor'){
                                    newJE.Type__c = 'Post Recognized Labor';
                                if(subTypeOfLabor == 'external'){
                                    newJE.Amount__c = l.External_Labor_Amount__c;
                                    newJE.Baan_Business_Partner_Number__c = l.Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c;
                                    
                                    newJE.Debit_General_Ledger_Account__c = laborIdToLaborPostRecExternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
                                    newJE.Credit_General_Ledger_Account__c = laborIdToLaborPostRecExternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                                }else if(subTypeOfLabor == 'internal'){
                                    newJe.Amount__c = l.Internal_Cost__c;
                                    
                                    newJE.Debit_General_Ledger_Account__c = laborIdToLaborPostRecInternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
                                    newJE.Credit_General_Ledger_Account__c = laborIdToLaborPostRecInternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;
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
                                        je.Type__c = 'External Labor';
                                        je.Amount__c = l.External_Labor_Amount__c;
                                        je.Baan_Business_Partner_Number__c = l.Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c;
                                        
                                        je.Debit_General_Ledger_Account__c = laborIdToLaborExternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
                                        je.Credit_General_Ledger_Account__c = laborIdToLaborExternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                                    }else if(subTypeOfLabor == 'internal'){
                                        je.Type__c = 'Internal Labor';
                                        je.Amount__c = l.Internal_Cost__c;
                                        
                                        je.Debit_General_Ledger_Account__c = laborIdToLaborFTL.get(l.id)[0].Debit_Account_Number__r.Name;
                                        je.Credit_General_Ledger_Account__c = laborIdToLaborFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                                    }
                                    
                                }else if(typeOfLabor == 'PostRecLabor'){
                                    je.Type__c = 'Post Recognized Labor';
                                	 if(subTypeOfLabor == 'external'){
                                        je.Amount__c = l.External_Labor_Amount__c;
                                        je.Baan_Business_Partner_Number__c = l.Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c;
                                        
                                        je.Debit_General_Ledger_Account__c = laborIdToLaborPostRecExternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
                                        je.Credit_General_Ledger_Account__c = laborIdToLaborPostRecExternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                                    }else if(subTypeOfLabor == 'internal'){
                                        je.Amount__c = l.Internal_Cost__c;
                                        
                                        je.Debit_General_Ledger_Account__c = laborIdToLaborPostRecInternalFTL.get(l.id)[0].Debit_Account_Number__r.Name;
                                        je.Credit_General_Ledger_Account__c = laborIdToLaborPostRecInternalFTL.get(l.id)[0].Credit_Account_Number__r.Name;
                                    }
                                }else if(typeOfLabor == 'LaborMiscReimbursement'){
                                    je.Type__c = 'Misc Reimbursement';
                                    je.Amount__c = l.External_Labor_Amount__c;
                                    je.Baan_Business_Partner_Number__c = l.Installer__r.RbA_User__r.Account.Baan_Business_Partner_Number__c;
                                    
                                    je.Debit_General_Ledger_Account__c = l.Installer_Account_Number__c;
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
        list<Journal_Entry__c> journalEntriesToUpsert = new list<Journal_Entry__c>();
        list<Journal_Entry__c> journalEntriesToDelete = new list<Journal_Entry__c>();
        
        list<Asset> extraFieldsList = [SELECT       id,
                                                    Unit_Wholesale_Cost__c,
                                                    Quantity,
                                                    Sold_Order__c,
                                                    Sold_Order__r.BillToContactId,
                                                    Sold_Order__r.Store_Location__c,
                                                    Sold_Order__r.Revenue_Recognized_Date__c,
                                                    Vendor__c,
                                                    Vendor__r.Name,
                                                    Vendor__r.Vendor_Account_Type__c,
                                                    Vendor__r.Baan_Business_Partner_Number__c,
                                                    RecordTypeId,
                                                    Store_Location__c,
                                                    Quantity_Written_Off__c,
                                                    Vendor_Credit__c
                                                    
                                                    FROM Asset WHERE Id IN :mapNew.keyset() AND RecordTypeId = :assetInstalledProductsRecordTypeId];        
        
        
        map<Id, list<Journal_Entry__c>> assetIdToJournalEntryMap = linkJournalEntries(extraFieldsList);

        //INVENTORY Received JOURNAL ENTERY
        map<Id, list<Journal_Entry__c>> assetIdToIRIntercompanyJEM = new map<Id, list<Journal_Entry__c>>();
        map<Id, list<Journal_Entry__c>> assetIdToIRExternalVendorJEM = new map<Id, list<Journal_Entry__c>>();
       	//POST RECOGNITION INVENTORY Received JOURNAL ENTERY
        map<Id, list<Journal_Entry__c>> assetIdToPRIRIntercompanyJEM = new map<Id, list<Journal_Entry__c>>();
        map<Id, list<Journal_Entry__c>> assetIdToPRIRExternalVendorJEM = new map<Id, list<Journal_Entry__c>>();
        
        map<Id, list<Journal_Entry__c>> assetIdToInventoryWriteOffJournalEntryMap = new map<Id, list<Journal_Entry__c>>();
		
		//MAKING MAPS OF ASSET ID TO DIFFERENT TYPES OF FINANCIAL TRANSACION LISTS
        map<Id, list<Financial_Transaction__c>>  assetIdToInventoryWriteOffFTL = linkFinacialTransactions(extraFieldsList, 'Inventory Write-Off');
        
        //INVENTORY Received FINANCIAL TRANSATION
        map<Id, list<Financial_Transaction__c>>  assetIdToIRIntercompanyFTL = linkFinacialTransactions(extraFieldsList, 'Inventory Received - Intercompany');
        map<Id, list<Financial_Transaction__c>>  assetIdToIRIntercompanyCCFTL = linkFinacialTransactions(extraFieldsList, 'Inventory Received - Intercompany Consolidation Center');
        map<Id, list<Financial_Transaction__c>>  assetIdToIRExternalVendorFTL = linkFinacialTransactions(extraFieldsList, 'Inventory Received - External Vendor');
        
        //Service Material Returned
        map<Id, list<Financial_Transaction__c>>  assetIdToSMRIntercompanyFTL = linkFinacialTransactions(extraFieldsList, 'Service Material Returned - Intercompany');
        map<Id, list<Financial_Transaction__c>>  assetIdToSMRIntercompanyCCFTL = linkFinacialTransactions(extraFieldsList, 'Service Material Returned - Intercompany Consolidation Center');
        map<Id, list<Financial_Transaction__c>>  assetIdToSMRExternalVendorFTL = linkFinacialTransactions(extraFieldsList, 'Service Material Returned - External Vendor');
 		
        
        for(Asset a : extraFieldsList){
          		string errorMessage;
                string assetSubType;
                if(a.Store_Location__c == null ){ 
                    errorMessage = RMS_errorMessages.STORE_LOCATION_IS_BLANK;
                }
                
                boolean inventoryWriteOffAT = false;
                boolean vendorCreditAT = false;
                boolean inventoryReceivedAT = false;
                boolean unitWholeSaleCostChangeAT = false;
                
                //CAN'T CHANGE WRITE OFF AND VENDOR CREDIT AT THE SAME TIME
                if((mapOld != null && mapOld.get(a.id).Quantity_Written_Off__c != mapNew.get(a.id).Quantity_Written_Off__c && mapOld.get(a.id).Vendor_Credit__c != mapNew.get(a.id).Vendor_Credit__c)
                	|| (mapOld == null && mapNew.get(a.id).Quantity_Written_Off__c != null && mapNew.get(a.id).Vendor_Credit__c != null)){
                		errorMessage = RMS_errorMessages.CHANGED_WRITE_OFF_AND_VENDOR_CREDIT;
        		}
        		
				if((mapOld != null && mapOld.get(a.id).Quantity_Written_Off__c != mapNew.get(a.id).Quantity_Written_Off__c)
					||(mapOld == null && mapNew.get(a.id).Quantity_Written_Off__c != null)){
						//ONLY IF QUANTITY IS 0 look into
					inventoryWriteOffAT = true;
				}
				
				else if( (mapOld != null && mapOld.get(a.id).Vendor_Credit__c != mapNew.get(a.id).Vendor_Credit__c)
						||(mapOld == null && mapNew.get(a.id).Vendor_Credit__c != null)
						&& (mapNew.get(a.id).Vendor_Credit__c != null)){
					vendorCreditAT = true;
		
				}else if((mapOld != null && mapOld.get(a.id).Quantity != mapNew.get(a.id).Quantity)
						||(mapOld == null && mapNew.get(a.id).Quantity != 0 && mapNew.get(a.id).Unit_Wholesale_Cost__c != 0)){
					//quantity has to change.
                	inventoryReceivedAT = true;
                
                }else if(mapOld != null && mapOld.get(a.id).Unit_Wholesale_Cost__c != mapNew.get(a.id).Unit_Wholesale_Cost__c){
                	if(a.Quantity != 0){
                		inventoryReceivedAT = true;
                	}
                	if(a.Quantity_Written_Off__c != null){
	                	inventoryWriteOffAT = true;
                	}
                	
                }
                
                if(a.Sold_Order__r.Revenue_Recognized_Date__c == null && a.Vendor__r.Vendor_Account_Type__c == 'Intercompany'){
            		assetSubType = 'Intercompany';
            	}else if(a.Sold_Order__r.Revenue_Recognized_Date__c == null && a.Vendor__r.Vendor_Account_Type__c == 'Intercompany Consolidation Center'){
            		assetSubType = 'IntercompanyCC';
            	}else if(a.Sold_Order__r.Revenue_Recognized_Date__c == null && a.Vendor__r.Vendor_Account_Type__c == 'External'){
            		assetSubType = 'ExternalVendor';
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
                
                //SERVICE MATERIAL RETURNED		
                if(vendorCreditAT == true){
                	system.debug('ads vendor credit assetSubType: '+assetSubType);
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
                	
                //INVENTORY WRITE OFF	
                if(inventoryWriteOffAT == true){
                	errorMessage = checkFinacialTransationForErrors(assetIdToInventoryWriteOffFTL.get(a.id) , errorMessage, 'Inventory Write-Off');
                }

                //SETTING UP MAPS TO CHECK IF CREDIT/DEBIT ACCOUNTS HAVE BEEN SWITCHED FOR CALCULATIONS
	    		map<string, string> jeTypeToFTCreditNumber = new map<string,string>();
				map<string, string> jeTypeToFTDebitNumber = new map<string,string>();	
   				
   				//INVENTROY Received
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
				}
				
				//SERVICE MATERIAL RETURNED
				if(assetIdToSMRIntercompanyFTL.get(a.id) != null && assetIdToSMRIntercompanyFTL.get(a.id).size() == 1){
					jeTypeToFTCreditNumber.put('Service Material Returned - Intercompany', assetIdToSMRIntercompanyFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   					jeTypeToFTDebitNumber.put('Service Material Returned - Intercompany', assetIdToSMRIntercompanyFTL.get(a.id)[0].Debit_Account_Number__r.Name);
				}
				if(assetIdToIRIntercompanyCCFTL.get(a.id) != null && assetIdToIRIntercompanyCCFTL.get(a.id).size() == 1){
   					jeTypeToFTCreditNumber.put('Service Material Returned - Intercompany Consolidation Center', assetIdToIRIntercompanyCCFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   					jeTypeToFTDebitNumber.put('Service Material Returned - Intercompany Consolidation Center', assetIdToIRIntercompanyCCFTL.get(a.id)[0].Debit_Account_Number__r.Name);
   				}
				if(assetIdToIRExternalVendorFTL.get(a.id) != null && assetIdToIRExternalVendorFTL.get(a.id).size() == 1){
					jeTypeToFTCreditNumber.put('Service Material Returned - External Vendor', assetIdToIRExternalVendorFTL.get(a.id)[0].Credit_Account_Number__r.Name);
   					jeTypeToFTDebitNumber.put('Service Material Returned - External Vendor', assetIdToIRExternalVendorFTL.get(a.id)[0].Debit_Account_Number__r.Name);
				}
				
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
	                        debitAccountN = assetIdToIRExternalVendorFTL.get(a.id)[0].Debit_Account_Number__r.Name;
	                        creditAccountN = assetIdToIRExternalVendorFTL.get(a.id)[0].Credit_Account_Number__r.Name;
						}
						wrapAssetVariable wAR = new wrapAssetVariable(aType, jType, creditAccountN, debitAccountN);
               			wrapAssetVariableList.add(wAR);
					}
					
					if(inventoryWriteOffAT == true){
						aType = 'InventoryWriteOff';
						jType = 'Inventory Write-Off';
                        debitAccountN = assetIdToInventoryWriteOffFTL.get(a.id)[0].Debit_Account_Number__r.Name;
                        creditAccountN= assetIdToInventoryWriteOffFTL.get(a.id)[0].Credit_Account_Number__r.Name;
						wrapAssetVariable wAR = new wrapAssetVariable(aType, jType, creditAccountN, debitAccountN);
                		wrapAssetVariableList.add(wAR);
					}
					
					if(vendorCreditAT == true){
						system.debug('ads vendorCreditAT = true: what is subtype: '+assetSubType);
						aType = 'VendorCredit';
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
	                        debitAccountN = assetIdToSMRExternalVendorFTL.get(a.id)[0].Debit_Account_Number__r.Name;
	                        creditAccountN = assetIdToSMRExternalVendorFTL.get(a.id)[0].Credit_Account_Number__r.Name;
						}
						wrapAssetVariable wAR = new wrapAssetVariable(aType, jType, creditAccountN, debitAccountN);
               			wrapAssetVariableList.add(wAR);
					}  
					
		           for(wrapAssetVariable wAR : wrapAssetVariableList){ 
		   				String assetType = wAR.assetType;
		                String jeType = wAR.jeType;
						String debitAccountNumber = wAR.debitAccountNumber;
						String creditAccountNumber = wAR.creditAccountNumber;

		                //NO RELATED JOURNAL ENTRIES CREATE JOURNAL
		                if(assetIdToJournalEntryMap.get(a.id) == null || assetIdToJournalEntryMap.get(a.id).size() == 0){
	                        Journal_Entry__c newJE = new Journal_Entry__c();
                            newJE.Date__c = Datetime.Now();
                            newJE.Asset__c = a.id;
                            newJE.Order__c = a.Sold_Order__c;
                            newJE.Customer__c = a.Sold_Order__r.BillToContactId;

                            newJE.Type__c = jeType;
                            newJE.Debit_General_Ledger_Account__c = debitAccountNumber;
                            newJE.Credit_General_Ledger_Account__c = creditAccountNumber;
							
							if(assetType == 'InventoryReceived'){
	                            newJE.Amount__c = a.Quantity * a.Unit_Wholesale_Cost__c;
							}else if(assetType == 'InventoryWriteOff'){
								newJE.Amount__c = (newQuantityWrittenOff - oldQuantityWrittenOff) * a.Unit_Wholesale_Cost__c;
							}else if(assetType == 'VendorCredit'){
								newJE.Baan_Business_Partner_Number__c = a.Vendor__r.Baan_Business_Partner_Number__c;
								newJE.Amount__c = a.Vendor_Credit__c;
							}
							
							if(newJE.Amount__c < 0){
                            	mapNew.get(a.id).addError(RMS_errorMessages.NEGATIVE_FINACIAL_TRANSACTION, FALSE);
                          	}
	        
	                        journalEntriesToUpsert.add(newJE);
	  
	                	}else{
		
	                        list<Journal_Entry__c> jeListSentToBaan = new list<Journal_Entry__c>();
	                        list<Journal_Entry__c> jeListNotSentToBaan = new list<Journal_Entry__c>();
	                        
	                        list<Journal_Entry__c> jeInventoryWriteOffList = new list<Journal_Entry__c>();
	                        list<Journal_Entry__c> jeInventoryReceivedList = new list<Journal_Entry__c>();
	                        list<Journal_Entry__c> jeServiceMaterialReturnedList = new list<Journal_Entry__c>();
		                    
		                    list<Journal_Entry__c> jeInventoryWriteOffListSentToBaan = new list<Journal_Entry__c>();
	                        list<Journal_Entry__c> jeInventoryReceivedListSentToBaan = new list<Journal_Entry__c>();
	                        list<Journal_Entry__c> jeServiceMaterialReturnedListSentToBaan = new list<Journal_Entry__c>();
	                        
	                        for(Journal_Entry__c je : assetIdToJournalEntryMap.get(a.id)){
                            if(je.Sent_to_BaanERP__c == true){
                                jeListSentToBaan.add(je);
                                if(je.Type__c == 'Inventory Write-Off'){
                                	jeInventoryWriteOffListSentToBaan.add(je);
                                }
                                if(je.Type__c.contains('Inventory Received')){
                                	jeInventoryReceivedListSentToBaan.add(je);
                                }
                                if(je.Type__c.contains('Service Material Returned')){
                                	jeServiceMaterialReturnedListSentToBaan.add(je);
                                }
                            }else if(je.Sent_to_BaanERP__c == false){
                                jeListNotSentToBaan.add(je);
                                if(je.Type__c == 'Inventory Write-Off'){
                                	jeInventoryWriteOffList.add(je);
                                }
                                if(je.Type__c.contains('Inventory Received')){
                                	jeInventoryReceivedList.add(je);
                                }
                                if(je.Type__c.contains('Service Material Returned')){
                                	jeServiceMaterialReturnedList.add(je);
                                }
                            }   
                        }
	              
	                        system.debug('ads jeListSentToBaan: ' + jeListSentToBaan);
	                        system.debug('ads jeListNotSentToBaan: ' + jeListNotSentToBaan);
	                        
	                        // More than 1 JE not sent to BAAN ERROR OUT
	                        if(jeInventoryWriteOffList.size() > 1 || jeInventoryReceivedList.size() > 1 || jeServiceMaterialReturnedList.size() > 1){
	                            mapNew.get(a.id).addError(RMS_errorMessages.MORE_THAN_ONE_JOURNAL_ENTERY_NOT_SUBMITTED, FALSE);
	                        } 
	                        
	                        // All but 1 JE sent to BAAN then update that existing journal entry. The amount should be equal to --- 'Old Journal Entry->Amount + ( (Asset(new)->Quantity - Asset(old)->Quantity) * Unit WholesaleCost) 
	                        else if((jeInventoryWriteOffList.size() == 1 && assetType == 'InventoryWriteOff') || 
			                        (jeInventoryReceivedList.size() == 1 && assetType == 'InventoryReceived') || 
			                        (jeServiceMaterialReturnedList.size() == 1 && assetType == 'VendorCredit')){
	                            
	                            Journal_Entry__c je = new Journal_Entry__c();
	                            if(assetType == 'InventoryReceived'){
	                            	je = jeInventoryReceivedList[0];
	                            }else if(assetType == 'VendorCredit'){
	                            	je = jeServiceMaterialReturnedList[0];
	                            }else if(assetType == 'InventoryWriteOff'){
	                           		je = jeInventoryWriteOffList[0];
	                            }
	                            
	                                                  	
	                           	String oldTypeCreditAccountNumber = jeTypeToFTCreditNumber.get(je.Type__c);
								String oldTypeDebitAccountNumber = jeTypeToFTDebitNumber.get(je.Type__c);
	                           
	                            je.Date__c = Datetime.Now();
	                            je.Asset__c = a.id;
	                            je.Order__c = a.Sold_Order__c;
	                            je.Customer__c = a.Sold_Order__r.BillToContactId;
								
								if(assetType == 'InventoryReceived'){
		
		                            je.Type__c = jeType;
		                            if(jeServiceMaterialReturnedListSentToBaan.size() == 0){
		                            	if((mapNew.get(a.id).Unit_Wholesale_Cost__c == null ||mapNew.get(a.id).Unit_Wholesale_Cost__c == 0) || (newQuantity == null || newQuantity == 0)){
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
		                                system.debug('ads newQuantity: ' +newQuantity);
		                            	
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
									je.Baan_Business_Partner_Number__c = a.Vendor__r.Baan_Business_Partner_Number__c;
		
									if(jeListSentToBaan.size() == 0){
										je.Amount__c = je.Amount__c + (newVendorCredit - oldVendorCredit);
			                            je.Debit_General_Ledger_Account__c = debitAccountNumber;
			                            je.Credit_General_Ledger_Account__c = creditAccountNumber;
		                            }else{
		                            	
		                            	//CHECKING IF JE.AMOUNT SHOULD BE CALCULATED AS A NEGITIVE AMOUNT 
		                            	system.debug('ads je.Debit_General_Ledger_Account__c: '+je.Debit_General_Ledger_Account__c);
		                            	system.debug('ads je.Credit_General_Ledger_Account__c: '+je.Credit_General_Ledger_Account__c);
		                        
		                            	if(	je.Debit_General_Ledger_Account__c == oldTypeCreditAccountNumber && 
		                            		je.Credit_General_Ledger_Account__c == oldTypeDebitAccountNumber){
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
		                                    je.Debit_General_Ledger_Account__c = creditAccountNumber;
		                           			je.Credit_General_Ledger_Account__c = debitAccountNumber;
		                            
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
	                            if(oldQuantity != newQuantity || oldQuantityWrittenOff != newQuantityWrittenOff || oldVendorCredit != newVendorCredit){
	                                Journal_Entry__c newJE = new Journal_Entry__c( );
	        						newJE.Date__c = Datetime.Now();
		                            newJE.Asset__c = a.id;
		                            newJE.Order__c = a.Sold_Order__c;
		                            newJE.Customer__c = a.Sold_Order__r.BillToContactId;
		                            newJE.Type__c = jeType;
		        						
									if(assetType == 'InventoryReceived'){
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
										newJE.Baan_Business_Partner_Number__c = a.Vendor__r.Baan_Business_Partner_Number__c;
				
										if(newVendorCredit > oldVendorCredit){
	                                    	newJE.Amount__c = newVendorCredit-oldVendorCredit;
	                                    	newJE.Debit_General_Ledger_Account__c = debitAccountNumber;
			                            	newJE.Credit_General_Ledger_Account__c = creditAccountNumber;
			                            
		                                }else if (newVendorCredit < oldVendorCredit){
		                                    newJE.Amount__c = Math.abs(newVendorCredit-oldVendorCredit);
	                                    	newJE.Debit_General_Ledger_Account__c = creditAccountNumber; 
			                            	newJE.Credit_General_Ledger_Account__c = debitAccountNumber;  
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
        Id orderCORORecordTypeRecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Record_Type', 'Order');
        list<Journal_Entry__c> journalEntriesToUpsert = new list<Journal_Entry__c>();
        
        list<Order> extraFieldsList = [SELECT       id,
                                                    RecordTypeId,
                                                    Revenue_Recognized_Date__c,
                                                    Store_Location__c,
                                                    Retail_Subtotal__c,
                                                    Retail_Total__c,
                                                    Discount_Amount__c,
                                                    Finance_Program_Fees__c
                                                    
                                                    FROM Order WHERE Id IN :mapNew.keyset() AND RecordTypeId = :orderCORORecordTypeRecordTypeId];       
        
        map<Id, list<Journal_Entry__c>> orderIdToJournalEntryMap = new map<Id, list<Journal_Entry__c>>(); 
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedDepositFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedLaborFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedRefundDepositFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedInternalLaborFTL = new map<Id, list<Financial_Transaction__c>>();
        
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedGrossSalesFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedDiscountFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedARFTL = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedFinanceFeesFTL = new map<Id, list<Financial_Transaction__c>>();
        
        if(extraFieldsList.size() > 0){
            orderIdToJournalEntryMap = linkJournalEntries(extraFieldsList);
            orderIdToRevRecognizedDepositFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Deposit');
            orderIdToRevRecognizedLaborFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Labor');
            
            orderIdToRevRecognizedRefundDepositFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Refund Deposit');
            orderIdToRevRecognizedInternalLaborFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Internal Labor');
            
            orderIdToRevRecognizedGrossSalesFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Gross Sales');
            orderIdToRevRecognizedDiscountFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Discount');
            orderIdToRevRecognizedARFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - AR');
            orderIdToRevRecognizedFinanceFeesFTL = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Finance Fees');
            
            
        }
        
        for(Order o : extraFieldsList){
                
                //IF REVENUE RECOGNIZED DATE HAS CHANGED FROM BLANK/NULL TO A VALUE
                if(mapOld.get(o.id).Revenue_Recognized_Date__c == null && mapNew.get(o.id).Revenue_Recognized_Date__c != null){
                    string errorMessage;
                    if(o.Store_Location__c == null ){ 
                        errorMessage = RMS_errorMessages.STORE_LOCATION_IS_BLANK;
                    }
                    if(orderIdToJournalEntryMap.get(o.id) == null ){ 
                        errorMessage = RMS_errorMessages.NO_RELATED_DEPOSIT_JOURNAL_ENTRY;
                    }
                    
                    
                    //errorMessage = checkOrderForErrors(o, errorMessage);
                    system.debug('Method:createJournalEntryOrder orderIdToRevRecognizedDepositFTL: '+orderIdToRevRecognizedDepositFTL);
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedDepositFTL.get(o.id) , errorMessage, 'Rev Recognized - Deposit');
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedLaborFTL.get(o.id) , errorMessage, 'Rev Recognized - Labor');
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedRefundDepositFTL.get(o.id) , errorMessage, 'Rev Recognized - Refund Deposit');
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedInternalLaborFTL.get(o.id) , errorMessage, 'Rev Recognized - Internal Labor');
                    
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedGrossSalesFTL.get(o.id) , errorMessage, 'Rev Recognized - Gross Sales');
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedDiscountFTL.get(o.id) , errorMessage, 'Rev Recognized - Discount');
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedARFTL.get(o.id) , errorMessage, 'Rev Recognized - AR');
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedFinanceFeesFTL.get(o.id) , errorMessage, 'Rev Recognized - Finance Fees');
                    
                    
                    
                    if(orderIdToJournalEntryMap.get(o.id) != null && orderIdToJournalEntryMap.get(o.id).size() != 0 ){      
                        if(errorMessage == null || errorMessage == ''){
                            list<Journal_Entry__c> relatedDespoitJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedExternalLaborJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedRevRecognizedDepositJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedRevRecognizedExternalLaborJE = new list<Journal_Entry__c>();
                            
                            list<Journal_Entry__c> relatedRefundDepositJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedInternalLaborJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedRevRecognizedRefundDepositJE = new list<Journal_Entry__c>();
                            
                            list<Journal_Entry__c> relatedRevRecognizedGrossSalesJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedRevRecognizedDiscountJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedRevRecognizedARJE = new list<Journal_Entry__c>();
                            list<Journal_Entry__c> relatedRevRecognizedFinanceFeesJE = new list<Journal_Entry__c>();
                            
                            
                            //CHECK JOURNAL ENTRY OF TYPE Rev Recognized - Deposit DOESN'T EXIST
                            Boolean alreadyHasJEofTypeRevRecDeposit = false;
                            Boolean alreadyHasJEofTypeRevRecLabor = false;
                            Boolean alreadyHasJEofTypeRevRecRefundDeposit = false;
                            Boolean alreadyHasJEofTypeRevRecInternalLabor = false;
                            
                            Boolean alreadyHasJEofTypeRevRecGrossSales = false;
                            Boolean alreadyHasJEofTypeRevRecDiscount = false;
                            Boolean alreadyHasJEofTypeRevRecAR = false;
                            Boolean alreadyHasJEofTypeRevRecFinanceFees = false; 
                            
                            for(Journal_Entry__c je : orderIdToJournalEntryMap.get(o.id)){
                                if(je.Type__c == 'Rev Recognized - Deposit'){
                                    alreadyHasJEofTypeRevRecDeposit = true; 
                                    relatedRevRecognizedDepositJE.add(je);
                                }
                                if(je.Type__c == 'Deposit'){
                                    relatedDespoitJE.add(je);
                                }

                                if(je.Type__c == 'Rev Recognized - Labor'){
                                    alreadyHasJEofTypeRevRecLabor = true;   
                                    relatedRevRecognizedExternalLaborJE.add(je);
                                }
                                if(je.Type__c == 'External Labor'){
                                    relatedExternalLaborJE.add(je);
                                }
                                
                                if(je.Type__c == 'Rev Recognized - Refund Deposit'){
                                    alreadyHasJEofTypeRevRecRefundDeposit = true;   
                                    relatedRevRecognizedRefundDepositJE.add(je);
                                }
                                if(je.Type__c == 'Refund - Deposit'){
                                    relatedRefundDepositJE.add(je);
                                }
                                if(je.Type__c == 'Rev Recognized - Internal Labor'){
                                    alreadyHasJEofTypeRevRecInternalLabor = true;   
                                    relatedRevRecognizedRefundDepositJE.add(je);
                                }
                                if(je.Type__c == 'Internal Labor'){
                                    relatedRefundDepositJE.add(je);
                                }
                                
                            
                                if(je.Type__c == 'Rev Recognized - Gross Sales'){
                                    alreadyHasJEofTypeRevRecGrossSales = true;  
                                    relatedRevRecognizedGrossSalesJE.add(je);
                                }
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
	                        }
                           
                            system.debug('Method:createJournalEntryOrder relatedDespoitJE: '+relatedDespoitJE);
                            system.debug('Method:createJournalEntryOrder alreadyHasJEofTypeRevRecDeposit: '+alreadyHasJEofTypeRevRecDeposit);
                            if(alreadyHasJEofTypeRevRecDeposit == false && relatedDespoitJE.size() > 0){
                                for(Journal_Entry__c je : relatedDespoitJE){
                                    errorMessage = checkOrderJEForErrors(je, errorMessage, 'deposit');
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
                                        
                                        journalEntriesToUpsert.add(newJE);
                                    
                                    }else{
                                        break;
                                    }
                                }//END relatedDespoitJE LOOP
                            }//END alreadyHasJEofTypeRevRecDeposit == false
                            //IF THERE IS A RELATED REV RECEIVED - DEPOSIT JOURNAL ENTERY
                            else if(alreadyHasJEofTypeRevRecDeposit == true && relatedRevRecognizedDepositJE.size() > 0){
                                for(Journal_Entry__c je: relatedRevRecognizedDepositJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }
                            //does not have related JE records of type Revenue Received labor
                            if(alreadyHasJEofTypeRevRecLabor == false && relatedExternalLaborJE.size() > 0){
                                for(Journal_Entry__c je : relatedExternalLaborJE){
                                    errorMessage = checkOrderJEForErrors(je, errorMessage, 'internalLabor');
                                    if(errorMessage == null){
                                        Journal_Entry__c newJE = new Journal_Entry__c(

                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - Internal Labor',
                                            Labor__c = je.Labor__c,
                                            Order__c = je.Order__c,
                                            Amount__c = je.Amount__c,
                                            Baan_Business_Partner_Number__c = je.Baan_Business_Partner_Number__c,
                                            
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedInternalLaborFTL.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedInternalLaborFTL.get(o.id)[0].Credit_Account_Number__r.Name
                                        );
                                        
                                        journalEntriesToUpsert.add(newJE);
                                    
                                    }else{
                                        break;
                                    }
                                }//END relatedDespoitJE LOOP

                            }
                            //has records Revenue Received labor
                            else if(alreadyHasJEofTypeRevRecLabor == true && relatedRevRecognizedRefundDepositJE.size() > 0){
                                for(Journal_Entry__c je: relatedRevRecognizedRefundDepositJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }
                            
                            //does not have related JE records of type Revenue Received labor
                            if(alreadyHasJEofTypeRevRecInternalLabor == false && relatedInternalLaborJE.size() > 0){
                                for(Journal_Entry__c je : relatedExternalLaborJE){
                                    errorMessage = checkOrderJEForErrors(je, errorMessage, 'labor');
                                    if(errorMessage == null){
                                        Journal_Entry__c newJE = new Journal_Entry__c(

                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - Labor',
                                            Labor__c = je.Labor__c,
                                            Order__c = je.Order__c,
                                            Amount__c = je.Amount__c,
                                            Customer__c = je.Customer__c,
                                            Baan_Business_Partner_Number__c = je.Baan_Business_Partner_Number__c,
                                            
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedLaborFTL.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedLaborFTL.get(o.id)[0].Credit_Account_Number__r.Name
                                        );
                                        
                                        journalEntriesToUpsert.add(newJE);
                                    
                                    }else{
                                        break;
                                    }
                                }//END relatedDespoitJE LOOP

                            }
                            //has records Revenue Received labor
                            else if(alreadyHasJEofTypeRevRecLabor == true && relatedRevRecognizedRefundDepositJE.size() > 0){
                                for(Journal_Entry__c je: relatedRevRecognizedRefundDepositJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }   
                                        
                            
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
                                        break;
                                    }
                                }//END relatedRefundDespoitJE LOOP

                            }// END of if no related Rev Recognized - Refund Deposits
                            //has records Rev Recognized - Refund Deposit
                            else if(alreadyHasJEofTypeRevRecRefundDeposit == true && relatedRevRecognizedExternalLaborJE.size() > 0){
                                for(Journal_Entry__c je: relatedRevRecognizedExternalLaborJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }
                            
                        
                            //does not have related JE records of type Rev Recognized - Gross Sales
                            if(alreadyHasJEofTypeRevRecGrossSales == false){
                                if(o.Retail_Subtotal__c == null){
                                    errorMessage = (String.isBlank(errorMessage)) ? RMS_errorMessages.RETAIL_SUBTOTAL_ON_ORDER_NULL : errorMessage + '<BR>' + RMS_errorMessages.RETAIL_SUBTOTAL_ON_ORDER_NULL;
                                }
                                if(errorMessage == null){
                                    if(o.Retail_Subtotal__c > 0){
                                        Journal_Entry__c newJE = new Journal_Entry__c(
                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - Gross Sales',
                                            Order__c = o.id,
                                            Amount__c = o.Retail_Subtotal__c,
                                                        
                                            Debit_General_Ledger_Account__c = null,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedGrossSalesFTL.get(o.id)[0].Credit_Account_Number__r.Name
                                        );
                                        journalEntriesToUpsert.add(newJE);
                                    }
                                }else{
                                    break;
                                } 
                            }// END of if no related Rev Recognized - Gross Sales
                            //has records Rev Recognized - Gross Sales
                            else if(alreadyHasJEofTypeRevRecRefundDeposit == true && relatedRevRecognizedGrossSalesJE.size() > 0){
                                for(Journal_Entry__c je: relatedRevRecognizedGrossSalesJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }
                            
                            
                            //does not have related JE records of type Rev Recognized - Discount
                            if(alreadyHasJEofTypeRevRecDiscount == false){
                                if(errorMessage == null){
                                    if(o.Discount_Amount__c > 0){
                                        Journal_Entry__c newJE = new Journal_Entry__c(
                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - Discount',
                                            Order__c = o.id,
                                            Amount__c = o.Discount_Amount__c,
                                                        
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedDiscountFTL.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = null
                                        );
                                        journalEntriesToUpsert.add(newJE);
                                    }
                                }else{
                                    break;
                                } 
                            }// END of if no related Rev Recognized - Discount
                            //has records Rev Recognized - Discount
                            else if(alreadyHasJEofTypeRevRecRefundDeposit == true && relatedRevRecognizedDiscountJE.size() > 0){
                                for(Journal_Entry__c je: relatedRevRecognizedDiscountJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }


                            //does not have related JE records of type Rev Recognized - AR
                            if(alreadyHasJEofTypeRevRecAR == false){
                                if(errorMessage == null){
                                    if(o.Retail_Total__c > 0){
                                        Journal_Entry__c newJE = new Journal_Entry__c(
                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - AR',
                                            Order__c = o.id,
                                            Amount__c = o.Retail_Total__c,
                                                        
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedARFTL.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = null
                                        );
                                        journalEntriesToUpsert.add(newJE);
                                    }
                                }else{
                                    break;
                                } 
                            }// END of if no related Rev Recognized - AR
                            //has records Rev Recognized - AR
                            else if(alreadyHasJEofTypeRevRecRefundDeposit == true && relatedRevRecognizedARJE.size() > 0){
                                for(Journal_Entry__c je: relatedRevRecognizedARJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }
                            
                            //does not have related JE records of type Rev Recognized - Finance Fees
                            if(alreadyHasJEofTypeRevRecFinanceFees == false){
                                if(errorMessage == null){
                                    if(o.Finance_Program_Fees__c > 0){
                                        Journal_Entry__c newJE = new Journal_Entry__c(
                                            Date__c = Datetime.Now(),
                                            Type__c = 'Rev Recognized - Finance Fees',
                                            Order__c = o.id,
                                            Amount__c = o.Finance_Program_Fees__c,
                                                        
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedFinanceFeesFTL.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = null
                                        );
                                        journalEntriesToUpsert.add(newJE);
                                    }
                                }else{
                                    break;
                                } 
                            }// END of if no related Rev Recognized - Finance Fees
                            //has records Rev Recognized - Finance Fees
                            else if(alreadyHasJEofTypeRevRecRefundDeposit == true && relatedRevRecognizedFinanceFeesJE.size() > 0){
                                for(Journal_Entry__c je: relatedRevRecognizedFinanceFeesJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }

                            
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
                    list<Journal_Entry__c> relatedRevRecognizedDepositJEToDelete = new list<Journal_Entry__c>();
                    list<Journal_Entry__c> relatedRevRecognizedLaborJEToDelete = new list<Journal_Entry__c>();
                    list<Journal_Entry__c> relatedRevRecognizedRefundDepositJEToDelete = new list<Journal_Entry__c>();
                    list<Journal_Entry__c> relatedRevRecognizedInternalLaborJEToDelete = new list<Journal_Entry__c>();

                    list<Journal_Entry__c> relatedRevRecognizedGrossSalesJEToDelete = new list<Journal_Entry__c>();
                    list<Journal_Entry__c> relatedRevRecognizedDiscountJEToDelete = new list<Journal_Entry__c>();
                    list<Journal_Entry__c> relatedRevRecognizedARToDelete = new list<Journal_Entry__c>();
                    list<Journal_Entry__c> relatedRevRecognizedFinanceFeesJEToDelete = new list<Journal_Entry__c>();
                    
                    Boolean sentToBaanERP = false;
                  
                    for(Journal_Entry__c je : orderIdToJournalEntryMap.get(o.id)){
                        if(je.Type__c == 'Rev Recognized - Deposit' && je.Sent_to_BaanERP__c == true){
                                sentToBaanERP = true; break;
                        }else if(je.Type__c == 'Rev Recognized - Labor' && je.Sent_to_BaanERP__c == true){
                                sentToBaanERP = true; break;
                        }else if(je.Type__c == 'Rev Recognized - Internal Labor' && je.Sent_to_BaanERP__c == true){
                                sentToBaanERP = true; break;
                        }else if(je.Type__c == 'Rev Recognized - Refund Deposit' && je.Sent_to_BaanERP__c == true){
                                sentToBaanERP = true; break;
                        }else if(je.Type__c == 'Rev Recognized - Gross Sales' && je.Sent_to_BaanERP__c == true){
                                sentToBaanERP = true; break;
                        }else if(je.Type__c == 'Rev Recognized - Discount' && je.Sent_to_BaanERP__c == true){
                                sentToBaanERP = true; break;
                        }else if(je.Type__c == 'Rev Recognized - AR' && je.Sent_to_BaanERP__c == true){
                                sentToBaanERP = true; break;
                        }else if(je.Type__c == 'Rev Recognized - Finance Fees' && je.Sent_to_BaanERP__c == true){
                                sentToBaanERP = true; break;
                        }
                        
                        else if(je.Type__c == 'Rev Recognized - Deposit' && je.Sent_to_BaanERP__c == false){
                            relatedRevRecognizedDepositJEToDelete.add(je);
                        }else if(je.Type__c == 'Rev Recognized - Labor' && je.Sent_to_BaanERP__c == false){
                            relatedRevRecognizedLaborJEToDelete.add(je);
                        }else if(je.Type__c == 'Rev Recognized - Internal Labor' && je.Sent_to_BaanERP__c == false){
                            relatedRevRecognizedInternalLaborJEToDelete.add(je);
                        }else if(je.Type__c == 'Rev Recognized - Refund Deposit' && je.Sent_to_BaanERP__c == false){
                            relatedRevRecognizedRefundDepositJEToDelete.add(je);
                        }else if(je.Type__c == 'Rev Recognized - Gross Sales' && je.Sent_to_BaanERP__c == false){
                            relatedRevRecognizedGrossSalesJEToDelete.add(je);
                        }else if(je.Type__c == 'Rev Recognized - Discount' && je.Sent_to_BaanERP__c == false){
                            relatedRevRecognizedDiscountJEToDelete.add(je);
                        }else if(je.Type__c == 'Rev Recognized - AR' && je.Sent_to_BaanERP__c == false){
                            relatedRevRecognizedARToDelete.add(je);
                        }else if(je.Type__c == 'Rev Recognized - Finance Fees' && je.Sent_to_BaanERP__c == false){
                            relatedRevRecognizedFinanceFeesJEToDelete.add(je);
                        }
                    }
                		     
                    if(sentToBaanERP == true){
                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                    }else{
                        if(relatedRevRecognizedDepositJEToDelete.size() > 0){
                            delete relatedRevRecognizedDepositJEToDelete;
                        }
                        if(relatedRevRecognizedLaborJEToDelete.size() > 0){
                            delete relatedRevRecognizedLaborJEToDelete;
                        }
                        if(relatedRevRecognizedInternalLaborJEToDelete.size() > 0){
                            delete relatedRevRecognizedInternalLaborJEToDelete;
                        }
                        if(relatedRevRecognizedRefundDepositJEToDelete.size() > 0){
                            delete relatedRevRecognizedRefundDepositJEToDelete;
                        }
                        
                        if(relatedRevRecognizedGrossSalesJEToDelete.size() > 0){
                            delete relatedRevRecognizedGrossSalesJEToDelete;
                        }
                        if(relatedRevRecognizedDiscountJEToDelete.size() > 0){
                            delete relatedRevRecognizedDiscountJEToDelete;
                        }
                        if(relatedRevRecognizedARToDelete.size() > 0){
                            delete relatedRevRecognizedARToDelete;
                        }
                        if(relatedRevRecognizedFinanceFeesJEToDelete.size() > 0){
                            delete relatedRevRecognizedFinanceFeesJEToDelete;
                        }
                        
                    }

                }
                //IF REVENUE RECOGNIZED DATE HAS CHANGED FROM A VALUE TO A VALUE
                else if((mapOld.get(o.id).Revenue_Recognized_Date__c != null && mapNew.get(o.id).Revenue_Recognized_Date__c != null) && (mapOld.get(o.id).Revenue_Recognized_Date__c != mapNew.get(o.id).Revenue_Recognized_Date__c)){
                    mapNew.get(o.id).addError(RMS_errorMessages.CHANGE_REVENUE_RECOGNIZED_DATE_NOT_CLEAR, FALSE);
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
                                                    Date__c,
                                                    Description__c,
                                                    Order__c,
                                                    Order__r.Revenue_Recognized_Date__c,
                                                    Order__r.BillToContactId,
                                                    CreatedById,
                                                    Name,
                                                    Store_Location__c
                                                    
                                                    FROM Refund__c WHERE Id IN :mapNew.keyset()];       
    
        map<Id, list<Journal_Entry__c>> refundIdToJournalEntryMap = linkJournalEntries(extraFieldsList);
        map<Id, list<Financial_Transaction__c>>  refundIdToDepositFTL = linkFinacialTransactions(extraFieldsList, 'Deposit');
        map<Id, list<Financial_Transaction__c>>  refundIdToFinalPaymentFTL = linkFinacialTransactions(extraFieldsList, 'Final Payment');
        
        for(Refund__c ref : extraFieldsList){
            String refundType;
            if(ref.Order__r.Revenue_Recognized_Date__c == null){
                refundType = 'deposit';
            }else if(ref.Order__r.Revenue_Recognized_Date__c != null){
                refundType = 'finalPayment';
            }
            
            string errorMessage;
            if(refundType == 'deposit'){
                errorMessage = checkFinacialTransationForErrors(refundIdToDepositFTL.get(ref.id) , errorMessage, 'Deposit');
            }else if(refundType == 'finalPayment'){
                errorMessage = checkFinacialTransationForErrors(refundIdToFinalPaymentFTL.get(ref.id) , errorMessage, 'Final Payment');
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
                      
                    }else if(refundType == 'finalPayment'){
                      newJE.Type__c = 'Refund - Final Payment';
                      newJE.Debit_General_Ledger_Account__c = refundIdToFinalPaymentFTL.get(ref.id)[0].Credit_Account_Number__r.Name;
                      newJE.Credit_General_Ledger_Account__c = refundIdToFinalPaymentFTL.get(ref.id)[0].Debit_Account_Number__r.Name;
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
                            }else if(refundType == 'finalPayment'){
                                je.Type__c = 'Refund - Final Payment';
                                je.Debit_General_Ledger_Account__c = refundIdToFinalPaymentFTL.get(ref.id)[0].Credit_Account_Number__r.Name;
                                je.Credit_General_Ledger_Account__c = refundIdToFinalPaymentFTL.get(ref.id)[0].Debit_Account_Number__r.Name;
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
																Type__c,                                                
			                                                    Order__r.Revenue_Recognized_Date__c,
			                                                    Order__r.BillToContactId
                                                    
                                                    
                                                    FROM Business_Adjustment__c WHERE Id IN :mapNew.keyset()];       
    
        map<Id, list<Journal_Entry__c>> businessAdjustmentIdToJournalEntryMap = linkJournalEntries(extraFieldsList);
       
        map<Id, list<Financial_Transaction__c>>  businessAdjustmentIdToARWriteOffFTL = linkFinacialTransactions(extraFieldsList, 'AR write-off');
        map<Id, list<Financial_Transaction__c>>  businessAdjustmentIdToInstallAdjustmentFTL = linkFinacialTransactions(extraFieldsList, 'Install Adjustment');
        map<Id, list<Financial_Transaction__c>>  businessAdjustmentIdToNonSufficientFundsTransactionList = linkFinacialTransactions(extraFieldsList, 'Non-sufficient Funds');
        
        
        for(Business_Adjustment__c ba : extraFieldsList){
            String businessAdjustmentType = ba.Type__c;
            
            
            string errorMessage;
            if(businessAdjustmentType == 'AR write-off'){
                errorMessage = checkFinacialTransationForErrors(businessAdjustmentIdToARWriteOffFTL.get(ba.id) , errorMessage, 'AR write-off');
            }else if(businessAdjustmentType == 'Install Adjustment'){
                errorMessage = checkFinacialTransationForErrors(businessAdjustmentIdToInstallAdjustmentFTL.get(ba.id) , errorMessage, 'Install Adjustment');
            }else if(businessAdjustmentType == 'Non-sufficient Funds'){
                errorMessage = checkFinacialTransationForErrors(businessAdjustmentIdToNonSufficientFundsTransactionList.get(ba.id) , errorMessage, 'Non-sufficient Funds');
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
                      newJE.Debit_General_Ledger_Account__c = businessAdjustmentIdToARWriteOffFTL.get(ba.id)[0].Debit_Account_Number__r.Name;
                      newJE.Credit_General_Ledger_Account__c = businessAdjustmentIdToARWriteOffFTL.get(ba.id)[0].Credit_Account_Number__r.Name;
                      
                    }else if(businessAdjustmentType == 'Install Adjustment'){
                      newJE.Debit_General_Ledger_Account__c = businessAdjustmentIdToInstallAdjustmentFTL.get(ba.id)[0].Debit_Account_Number__r.Name;
                      newJE.Credit_General_Ledger_Account__c = businessAdjustmentIdToInstallAdjustmentFTL.get(ba.id)[0].Credit_Account_Number__r.Name;
                    
                    }else if(businessAdjustmentType == 'Non-sufficient Funds'){
                      newJE.Debit_General_Ledger_Account__c = businessAdjustmentIdToNonSufficientFundsTransactionList.get(ba.id)[0].Debit_Account_Number__r.Name;
                      newJE.Credit_General_Ledger_Account__c = businessAdjustmentIdToNonSufficientFundsTransactionList.get(ba.id)[0].Credit_Account_Number__r.Name;
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
		                      je.Debit_General_Ledger_Account__c = businessAdjustmentIdToARWriteOffFTL.get(ba.id)[0].Debit_Account_Number__r.Name;
		                      je.Credit_General_Ledger_Account__c = businessAdjustmentIdToARWriteOffFTL.get(ba.id)[0].Credit_Account_Number__r.Name;
		                      
		                    }else if(businessAdjustmentType == 'Install Adjustment'){
		                      je.Debit_General_Ledger_Account__c = businessAdjustmentIdToInstallAdjustmentFTL.get(ba.id)[0].Debit_Account_Number__r.Name;
		                      je.Credit_General_Ledger_Account__c = businessAdjustmentIdToInstallAdjustmentFTL.get(ba.id)[0].Credit_Account_Number__r.Name;
		                    
		                    }else if(businessAdjustmentType == 'Non-sufficient Funds'){
		                      je.Debit_General_Ledger_Account__c = businessAdjustmentIdToNonSufficientFundsTransactionList.get(ba.id)[0].Debit_Account_Number__r.Name;
		                      je.Credit_General_Ledger_Account__c = businessAdjustmentIdToNonSufficientFundsTransactionList.get(ba.id)[0].Credit_Account_Number__r.Name;
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
        list<Id> storeListId = new list<Id>();
        
        for(SObject o : objectList){
            paymentIdList.add(o.id);
                storeListId.add((Id)o.get('Store_Location__c'));
        } 
        system.debug('ads storelistId: '+storeListId);
        list<Financial_Transaction__c> relatedFinancialTransactions = [SELECT   id, 
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
            if(objectType != 'Misc Cash Receipt' && objectType != 'Misc Reimbursement' && ftList[0].Credit_Account_Number__c == null ){
                dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.FINACIAL_TRANSACTION_RECORDS_NO_CREDIT_ACCOUNT_NUMBER, '[Transaction Type]', objectType);
                errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
            }
            //CHECK IF DEBIT ACCOUNT NUMBER IS NULL
            if(objectType != 'Misc Cash Receipt' && ftList[0].Debit_Account_Number__c == null ){
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
        if(asset.Unit_Wholesale_Cost__c == null){
            dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.REQUIRED_FIELD_IS_NULL, '[field]', 'Unit Wholesale Cost');
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
        if(asset.Quantity == null){
            dynamicErrorMessage = fillInErrorRuleValues(RMS_errorMessages.REQUIRED_FIELD_IS_NULL, '[field]', 'Quantity');
            errorMessage = (String.isBlank(errorMessage)) ? dynamicErrorMessage : errorMessage + '<BR>' + dynamicErrorMessage;
        }
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
            if( pOld.Processed_Date__c == null){
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
    /***************************************************
     Method to dynamicly create account number from GL Account number and Location Numkber
    ****************************************************/
    public map<Id, string> linkMiscPaymentAccountNumbers(list<SObject> objectList, map<id, SObject> mapNew){
        map<Id, string> mapToReturn = new map<Id, string>();
        list<id> storeLocationIdList = new list<id>();
        for(SObject theObject : objectList){  
            storeLocationIdList.add((id)theObject.get('Store_Location__c'));
        }
        map<Id, Store_Configuration__c> storeConfigMap = UtilityMethods.mapStoreConfigs(storeLocationIdList);
        
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
            string locationNumber;
            if(storeConfigMap.get((id)theObject.get('Store_Location__c')).Location_Number__c == null ){
                mapNew.get(theObject.id).addError(RMS_errorMessages.LOCATION_ID_IS_NULL, FALSE);
            }else{
                locationNumber = storeConfigMap.get((id)theObject.get('Store_Location__c')).Location_Number__c;
            }
            
            integer glLength = GLAccount.length();
            
            string glFirstSection = GLAccount.substring(0, glLength-3);
            string glSecondSection =GLAccount.substring(glLength-3);
            string newCode = glFirstSection+locationNumber+glSecondSection;
            mapToReturn.put((id)theObject.get('Id'), newCode);
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
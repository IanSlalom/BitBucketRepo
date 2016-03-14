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
            }else if(objectIdToJournalEntryMap.get(o.id).size() > 0 && soType == 'Asset' ){
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
                                                    Payment_Amount__c,
                                                    Payment_Type__c,
                                                    Order__r.Store_Location__c,
                                                    RecordTypeId,
                                                    Store_Location__c,
                                                    GL_Account__r.Name
                                                    
                                                    FROM Payment__c WHERE Id IN :mapNew.keyset()];      
        
        map<Id, list<Journal_Entry__c>> paymentIdToJournalEntryMap = linkJournalEntries(extraFieldsList);
        map<Id, list<Financial_Transaction__c>>  paymentIdToDepositFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Deposit');
        map<Id, list<Financial_Transaction__c>>  paymentIdToFinalPaymentFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Final Payment');
        map<Id, list<Financial_Transaction__c>>  paymentIdToMiscCashReceiptFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Misc Cash Receipt');
        map<Id, String> paymentIdToMiscCashReceiptCreditGLAmap = linkMiscPaymentAccountNumbers(extraFieldsList, mapNew);
        
        /*********************************************************
        Building new misc cash receipt finacial transaction list map
        ************************************************************/
        
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
                if(typeOfPayment == 'DepositDeposit'){
                    errorMessage = checkFinacialTransationForErrors(paymentIdToDepositFinacialTransactionList.get(p.id) , errorMessage, p.Payment_Type__c);
                }else if(typeOfPayment == 'DepositFinalPayment'){
                    errorMessage = checkFinacialTransationForErrors(paymentIdToFinalPaymentFinacialTransactionList.get(p.id) , errorMessage, p.Payment_Type__c);
                }else if(typeOfPayment == 'MiscCashReceipt'){
                    errorMessage = checkFinacialTransationForErrors(paymentIdToMiscCashReceiptFinacialTransactionList.get(p.id) , errorMessage, 'Misc Cash Receipt');
                }
                
                errorMessage = checkPaymentForErrors(p, errorMessage, typeOfPayment);
                
                if(errorMessage == null || errorMessage == ''){
                    
                    if(paymentIdToJournalEntryMap.get(p.id) == null || paymentIdToJournalEntryMap.get(p.id).size() == 0 ){
 
                        system.debug('ads p: '+p);
                        system.debug('ads p.Order__r.BillToContactId,: '+p.Order__r.BillToContactId);
                         
                        Journal_Entry__c newJE = new Journal_Entry__c(
                            Date__c = Datetime.Now(),
                            Payment__c = p.id,
                            Order__c = p.Order__c,
                            Amount__c = p.Payment_Amount__c,
                            Customer__c = p.Order__r.BillToContactId);
                        
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
                                                    Installer__r.Account.Baan_Business_Partner_Number__c,
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
                                                    Work_Order_Type__c,
                                                    CreatedById,
                                                    Name,
                                                    RecordTypeId
                                                    
                                                    FROM Labor__c WHERE Id IN :mapNew.keyset()];        
        
        map<Id, list<Journal_Entry__c>> laborIdToJournalEntryMap = linkJournalEntries(extraFieldsList);

        map<Id, list<Financial_Transaction__c>>  laborIdToLaborFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Internal Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToLaborExternalFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'External Labor');
        map<Id, list<Financial_Transaction__c>>  laborIdToMiscReimbursementFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Misc Reimbursement');
        map<Id, String> laborIdToMiscReimbursementGLAmap = linkMiscPaymentAccountNumbers(extraFieldsList, mapNew);
        
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
                        errorMessage = checkFinacialTransationForErrors(laborIdToLaborExternalFinacialTransactionList.get(l.id) , errorMessage, 'External Labor');
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
                            
                                if(l.External_Labor_Amount__c != null && l.External_Labor_Amount__c != 0){
                                    newJE.Type__c = 'External Labor';
                                    newJE.Amount__c = l.External_Labor_Amount__c;
                                    newJE.Baan_Business_Partner_Number__c = l.Installer__r.Account.Baan_Business_Partner_Number__c;
                                    
                                    newJE.Debit_General_Ledger_Account__c = laborIdToLaborExternalFinacialTransactionList.get(l.id)[0].Debit_Account_Number__r.Name;
                                    newJE.Credit_General_Ledger_Account__c = laborIdToLaborExternalFinacialTransactionList.get(l.id)[0].Credit_Account_Number__r.Name;
                                }else if(l.External_Labor_Amount__c == null || l.External_Labor_Amount__c == 0){
                                    newJE.Type__c = 'Internal Labor';
                                    newJe.Amount__c = l.Internal_Cost__c;
                                    
                                    newJE.Debit_General_Ledger_Account__c = laborIdToLaborFinacialTransactionList.get(l.id)[0].Debit_Account_Number__r.Name;
                                    newJE.Credit_General_Ledger_Account__c = laborIdToLaborFinacialTransactionList.get(l.id)[0].Credit_Account_Number__r.Name;
                                }
                            }else if(typeOfLabor == 'LaborMiscReimbursement'){
                                newJE.Type__c = 'Misc Reimbursement';
                                newJE.Amount__c = l.External_Labor_Amount__c;
                                newJE.Baan_Business_Partner_Number__c = l.Installer__r.Account.Baan_Business_Partner_Number__c;
                                
                                newJE.Debit_General_Ledger_Account__c = laborIdToMiscReimbursementGLAmap.get(l.id);
                                newJE.Credit_General_Ledger_Account__c = laborIdToMiscReimbursementFinacialTransactionList.get(l.id)[0].Credit_Account_Number__r.Name;
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
                                
                                    if(l.External_Labor_Amount__c != null && l.External_Labor_Amount__c != 0){
                                        je.Type__c = 'External Labor';
                                        je.Amount__c = l.External_Labor_Amount__c;
                                        je.Baan_Business_Partner_Number__c = l.Installer__r.Account.Baan_Business_Partner_Number__c;
                                        
                                        je.Debit_General_Ledger_Account__c = laborIdToLaborExternalFinacialTransactionList.get(l.id)[0].Debit_Account_Number__r.Name;
                                        je.Credit_General_Ledger_Account__c = laborIdToLaborExternalFinacialTransactionList.get(l.id)[0].Credit_Account_Number__r.Name;
                                    }else if(l.External_Labor_Amount__c == null || l.External_Labor_Amount__c == 0){
                                        je.Type__c = 'Internal Labor';
                                        je.Amount__c = l.Internal_Cost__c;
                                        
                                        je.Debit_General_Ledger_Account__c = laborIdToLaborFinacialTransactionList.get(l.id)[0].Debit_Account_Number__r.Name;
                                        je.Credit_General_Ledger_Account__c = laborIdToLaborFinacialTransactionList.get(l.id)[0].Credit_Account_Number__r.Name;
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
                                                    RecordTypeId,
                                                    Store_Location__c,
                                                    Quantity_Written_Off__c
                                                    
                                                    FROM Asset WHERE Id IN :mapNew.keyset() AND RecordTypeId = :assetInstalledProductsRecordTypeId];        
        
        
        map<Id, list<Journal_Entry__c>> assetIdToJournalEntryMap = linkJournalEntries(extraFieldsList);
        system.debug('ads: assetIdToJournalEntryMap: '+assetIdToJournalEntryMap);
        map<Id, list<Journal_Entry__c>> assetIdToInventoryReceivedJournalEntryMap = new map<Id, list<Journal_Entry__c>>();
        map<Id, list<Journal_Entry__c>> assetIdToInventoryWriteOffJournalEntryMap = new map<Id, list<Journal_Entry__c>>();
        
        for(id assetId : assetIdToJournalEntryMap.keySet()){
        	for(Journal_Entry__c je : assetIdToJournalEntryMap.get(assetId) ){
	        	if(je.Type__c == 'Inventory Received'){
	        		system.debug('ads inside inventory recived loop: '+je);
        		    if(assetIdToInventoryReceivedJournalEntryMap.containsKey(je.Asset__c) ){
	                    assetIdToInventoryReceivedJournalEntryMap.get(je.Asset__c).add(je);
	                }else{
	                	assetIdToInventoryReceivedJournalEntryMap.put(je.Asset__c, new list<Journal_Entry__c>{je});
	                }
	        	}else if(je.Type__c == 'Inventory Write-Off'){
	        		 if(assetIdToInventoryWriteOffJournalEntryMap.containsKey(je.Asset__c) ){
	                    assetIdToInventoryWriteOffJournalEntryMap.get(je.Asset__c).add(je);
	                }else{
	                	assetIdToInventoryWriteOffJournalEntryMap.put(je.Asset__c, new list<Journal_Entry__c>{je});
	                }
	        	}
        	}
        }
        
         system.debug('ads: assetIdToInventoryReceivedJournalEntryMap: '+assetIdToInventoryReceivedJournalEntryMap);
          system.debug('ads: assetIdToInventoryWriteOffJournalEntryMap: '+assetIdToInventoryWriteOffJournalEntryMap);
		
        map<Id, list<Financial_Transaction__c>>  assetIdToInventoryReceivedFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Inventory Received');
        map<Id, list<Financial_Transaction__c>>  assetIdToInventoryWriteOffFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Inventory Write-Off');
        
        for(Asset a : extraFieldsList){
                string errorMessage;
                string assetType;
                if(a.Store_Location__c == null ){ 
                    errorMessage = RMS_errorMessages.STORE_LOCATION_IS_BLANK;
                }
				if(	mapOld != null && 
					mapOld.get(a.id).Quantity_Written_Off__c != mapNew.get(a.id).Quantity_Written_Off__c){
						assetType = 'InventoryWriteOff';
				}else{
                	assetType = 'InventoryRecived';
                }
               
                system.debug('ads assetType: '+ assetType); 
               
                errorMessage = checkAssetForErrors(a, errorMessage);
                
                if(assetType == 'InventoryRecived'){
	                errorMessage = checkFinacialTransationForErrors(assetIdToInventoryReceivedFinacialTransactionList.get(a.id) , errorMessage, 'Inventory Received');
                }else if(assetType == 'InventoryWriteOff'){
                	errorMessage = checkFinacialTransationForErrors(assetIdToInventoryWriteOffFinacialTransactionList.get(a.id) , errorMessage, 'Inventory Write-Off');
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
               
                
                //NO RELATED JOURNAL ENTRIES CREATE JOURNAL
                if( (assetType == 'InventoryRecived' && (assetIdToInventoryReceivedJournalEntryMap.get(a.id) == null || assetIdToInventoryReceivedJournalEntryMap.get(a.id).size() == 0)) 
                	||
                	(assetType == 'InventoryWriteOff' && (assetIdToInventoryWriteOffJournalEntryMap.get(a.id) == null || assetIdToInventoryWriteOffJournalEntryMap.get(a.id).size() == 0)) 
                ){
                
                    
                    if(errorMessage == null || errorMessage == ''){
                        Journal_Entry__c newJE = new Journal_Entry__c();
                            newJE.Date__c = Datetime.Now();
                            newJE.Asset__c = a.id;
                            newJE.Order__c = a.Sold_Order__c;
                            newJE.Customer__c = a.Sold_Order__r.BillToContactId;

							if(assetType == 'InventoryRecived'){
	                            newJE.Type__c = 'Inventory Received';
	                            newJE.Debit_General_Ledger_Account__c = assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Debit_Account_Number__r.Name;
	                            newJE.Credit_General_Ledger_Account__c = assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Credit_Account_Number__r.Name;
	                            newJE.Amount__c = a.Quantity * a.Unit_Wholesale_Cost__c;
							}else if(assetType == 'InventoryWriteOff'){
								newJE.Type__c = 'Inventory Write-Off';
	                            newJE.Debit_General_Ledger_Account__c = assetIdToInventoryWriteOffFinacialTransactionList.get(a.id)[0].Debit_Account_Number__r.Name;
	                            newJE.Credit_General_Ledger_Account__c = assetIdToInventoryWriteOffFinacialTransactionList.get(a.id)[0].Credit_Account_Number__r.Name;
		
								newJE.Amount__c = (newQuantityWrittenOff - oldQuantityWrittenOff) * a.Unit_Wholesale_Cost__c;
							}
							
							if(newJE.Amount__c < 0){
                            	mapNew.get(a.id).addError(RMS_errorMessages.NEGATIVE_FINACIAL_TRANSACTION, FALSE);
                          	}
        
                        journalEntriesToUpsert.add(newJE);
                    }else{
                        //there is an error message
                        mapNew.get(a.id).addError(errorMessage, FALSE);
                    }
                }else{
                    //there is at least 1 related journal entry
                    if(errorMessage == null || errorMessage == ''){
                        list<Journal_Entry__c> jeListSentToBaan = new list<Journal_Entry__c>();
                        list<Journal_Entry__c> jeListNotSentToBaan = new list<Journal_Entry__c>();
                        if(assetType == 'InventoryRecived'){
	                        for(Journal_Entry__c je : assetIdToInventoryReceivedJournalEntryMap.get(a.id)){
	                            if(je.Sent_to_BaanERP__c == true){
	                                jeListSentToBaan.add(je);
	                            }else if(je.Sent_to_BaanERP__c == false){
	                                jeListNotSentToBaan.add(je);
	                            }   
	                        }
                        }else if(assetType == 'InventoryWriteOff'){
	                        for(Journal_Entry__c je : assetIdToInventoryWriteOffJournalEntryMap.get(a.id)){
	                            if(je.Sent_to_BaanERP__c == true){
	                                jeListSentToBaan.add(je);
	                            }else if(je.Sent_to_BaanERP__c == false){
	                                jeListNotSentToBaan.add(je);
	                            }   
	                        }
                        }
                        
                        system.debug('ads jeListSentToBaan: ' + jeListSentToBaan);
                        system.debug('ads jeListNotSentToBaan: ' + jeListNotSentToBaan);
                        
                        // More than 1 JE not sent to BAAN
                        // Error out
                        if(jeListNotSentToBaan.size() > 1){
                            mapNew.get(a.id).addError(RMS_errorMessages.MORE_THAN_ONE_JOURNAL_ENTERY_NOT_SUBMITTED, FALSE);
                        } 
                        
                        // All but 1 JE sent to BAAN
                        // then update that existing journal entry. The amount should be equal to --- 'Old Journal Entry->Amount + ( (Asset(new)->Quantity - Asset(old)->Quantity) * Unit WholesaleCost) 
                        else if(jeListNotSentToBaan.size() == 1){
                            Journal_Entry__c je = jeListNotSentToBaan[0];
                            je.Date__c = Datetime.Now();
                            je.Asset__c = a.id;
                            je.Order__c = a.Sold_Order__c;
                            je.Customer__c = a.Sold_Order__r.BillToContactId;
							
							if(assetType == 'InventoryRecived'){
	                            je.Type__c = 'Inventory Received';
	                            
	                            if(jeListSentToBaan.size() == 0){
	                                je.Amount__c = a.Quantity * a.Unit_Wholesale_Cost__c;
		                            je.Debit_General_Ledger_Account__c = assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Debit_Account_Number__r.Name;
		                            je.Credit_General_Ledger_Account__c = assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Credit_Account_Number__r.Name;
		                            
	                            }else{
	                            	
	                            	//CHECKING IF JE.AMOUNT SHOULD BE CALCULATED AS A NEGITIVE AMOUNT 
	                            	system.debug('ads je.Debit_General_Ledger_Account__c: '+je.Debit_General_Ledger_Account__c);
	                            	system.debug('ads je.Credit_General_Ledger_Account__c: '+je.Credit_General_Ledger_Account__c);
	                            	if(	je.Debit_General_Ledger_Account__c == assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Credit_Account_Number__r.Name && 
	                            		je.Credit_General_Ledger_Account__c == assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Debit_Account_Number__r.Name){
	                            			system.debug('ads changing to negative amount: '+je.Amount__c);
	                            			je.Amount__c = je.Amount__c*-1;
	                            	}
	                            	
	                            	
	                                if(je.Amount__c + ((newQuantity-oldQuantity) * a.Unit_Wholesale_Cost__c) > 0){
	                                    je.Amount__c = je.Amount__c + ((newQuantity-oldQuantity) * a.Unit_Wholesale_Cost__c);
	                                    je.Debit_General_Ledger_Account__c = assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Debit_Account_Number__r.Name;
	                           			je.Credit_General_Ledger_Account__c = assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Credit_Account_Number__r.Name;
	                            
	                                }else if(je.Amount__c + ((newQuantity-oldQuantity) * a.Unit_Wholesale_Cost__c) == 0){
	                                	journalEntriesToDelete.add(je);
	                                }else{
	                                	je.Amount__c = Math.abs(je.Amount__c + ((newQuantity-oldQuantity) * a.Unit_Wholesale_Cost__c));
	                                    je.Debit_General_Ledger_Account__c = assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Credit_Account_Number__r.Name;
	                           			je.Credit_General_Ledger_Account__c = assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Debit_Account_Number__r.Name;
	                            
	                                }   
	                            }
							}
							else if(assetType == 'InventoryWriteOff'){
								je.Type__c = 'Inventory Write-Off';
	                            je.Debit_General_Ledger_Account__c = assetIdToInventoryWriteOffFinacialTransactionList.get(a.id)[0].Debit_Account_Number__r.Name;
	                            je.Credit_General_Ledger_Account__c = assetIdToInventoryWriteOffFinacialTransactionList.get(a.id)[0].Credit_Account_Number__r.Name;
								je.Amount__c = (jeListNotSentToBaan[0].Amount__c + (newQuantityWrittenOff - oldQuantityWrittenOff) * a.Unit_Wholesale_Cost__c);
								
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
                        else if(jeListNotSentToBaan.size() == 0){
                        	system.debug('ads old Quantity: '+oldQuantity);
                            if(oldQuantity != newQuantity || oldQuantityWrittenOff != newQuantityWrittenOff){
                                Journal_Entry__c newJE = new Journal_Entry__c( );
        						newJE.Date__c = Datetime.Now();
	                            newJE.Asset__c = a.id;
	                            newJE.Order__c = a.Sold_Order__c;
	                            newJE.Customer__c = a.Sold_Order__r.BillToContactId;
	        						
								if(assetType == 'InventoryRecived'){
		                            newJE.Type__c = 'Inventory Received';
		                            newJE.Debit_General_Ledger_Account__c = assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Debit_Account_Number__r.Name;
		                            newJE.Credit_General_Ledger_Account__c = assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Credit_Account_Number__r.Name;
		                            
		                       		if(newQuantity > oldQuantity){
                                    	newJE.Amount__c = (newQuantity-oldQuantity) * a.Unit_Wholesale_Cost__c;
                                    	newJE.Debit_General_Ledger_Account__c = assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Debit_Account_Number__r.Name;
		                            	newJE.Credit_General_Ledger_Account__c = assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Credit_Account_Number__r.Name;
		                            
	                                }else if (newQuantity < oldQuantity){
	                                    newJE.Amount__c = Math.abs((newQuantity-oldQuantity) * a.Unit_Wholesale_Cost__c);
                                    	newJE.Debit_General_Ledger_Account__c = assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Credit_Account_Number__r.Name; 
		                            	newJE.Credit_General_Ledger_Account__c = assetIdToInventoryReceivedFinacialTransactionList.get(a.id)[0].Debit_Account_Number__r.Name;  
	                                }
		                     
								}else if(assetType == 'InventoryWriteOff'){
									newJE.Type__c = 'Inventory Write-Off';
		                            newJE.Debit_General_Ledger_Account__c = assetIdToInventoryWriteOffFinacialTransactionList.get(a.id)[0].Debit_Account_Number__r.Name;
		                            newJE.Credit_General_Ledger_Account__c = assetIdToInventoryWriteOffFinacialTransactionList.get(a.id)[0].Credit_Account_Number__r.Name;
									newJE.Amount__c = (mapNew.get(a.id).Quantity_Written_Off__c - mapOld.get(a.id).Quantity_Written_Off__c) * a.Unit_Wholesale_Cost__c;
								
	                                //CHECK THAT WOULD NOT RESULT IN NEGATIVE FINACNCIAL TRANSACTION
									if(newJE.Amount__c < 0){
		                            	mapNew.get(a.id).addError(RMS_errorMessages.NEGATIVE_FINACIAL_TRANSACTION, FALSE);
		                          	}
								}
        				 
                                
                               
                                journalEntriesToUpsert.add(newJE);  
                            }
                        }
                    }else{
                        //there is an error message
                        mapNew.get(a.id).addError(errorMessage, FALSE);
                    }
                    
                }//end of if there is atleast one related journal entery
        }//END OF ASSET FOR LOOP
        system.debug('ads journalEntriesToUpsert: '+journalEntriesToUpsert);
        upsert journalEntriesToUpsert;
        if(journalEntriesToDelete != null){
        	delete journalEntriesToDelete;
        }
    }//END createOrUpdateJournalEntryAsset Method



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
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedDepositFinacialTransactionList = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedLaborFinacialTransactionList = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedRefundDepositFinacialTransactionList = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedInternalLaborFinacialTransactionList = new map<Id, list<Financial_Transaction__c>>();
        
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedGrossSalesFinacialTransactionList = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedDiscountFinacialTransactionList = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedARFinacialTransactionList = new map<Id, list<Financial_Transaction__c>>();
        map<Id, list<Financial_Transaction__c>> orderIdToRevRecognizedFinanceFeesFinacialTransactionList = new map<Id, list<Financial_Transaction__c>>();
        
        if(extraFieldsList.size() > 0){
            orderIdToJournalEntryMap = linkJournalEntries(extraFieldsList);
            orderIdToRevRecognizedDepositFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Deposit');
            orderIdToRevRecognizedLaborFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Labor');
            
            orderIdToRevRecognizedRefundDepositFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Refund Deposit');
            orderIdToRevRecognizedInternalLaborFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Internal Labor');
            
            orderIdToRevRecognizedGrossSalesFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Gross Sales');
            orderIdToRevRecognizedDiscountFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Discount');
            orderIdToRevRecognizedARFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - AR');
            orderIdToRevRecognizedFinanceFeesFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Rev Recognized - Finance Fees');
            
            
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
                    system.debug('Method:createJournalEntryOrder orderIdToRevRecognizedDepositFinacialTransactionList: '+orderIdToRevRecognizedDepositFinacialTransactionList);
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedDepositFinacialTransactionList.get(o.id) , errorMessage, 'Rev Recognized - Deposit');
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedLaborFinacialTransactionList.get(o.id) , errorMessage, 'Rev Recognized - Labor');
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedRefundDepositFinacialTransactionList.get(o.id) , errorMessage, 'Rev Recognized - Refund Deposit');
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedInternalLaborFinacialTransactionList.get(o.id) , errorMessage, 'Rev Recognized - Internal Labor');
                    
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedGrossSalesFinacialTransactionList.get(o.id) , errorMessage, 'Rev Recognized - Gross Sales');
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedDiscountFinacialTransactionList.get(o.id) , errorMessage, 'Rev Recognized - Discount');
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedARFinacialTransactionList.get(o.id) , errorMessage, 'Rev Recognized - AR');
                    errorMessage = checkFinacialTransationForErrors(orderIdToRevRecognizedFinanceFeesFinacialTransactionList.get(o.id) , errorMessage, 'Rev Recognized - Finance Fees');
                    
                    
                    
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
                        
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedDepositFinacialTransactionList.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedDepositFinacialTransactionList.get(o.id)[0].Credit_Account_Number__r.Name
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
                            //does not have related JE records of type Revenue Recived labor
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
                                            
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedInternalLaborFinacialTransactionList.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedInternalLaborFinacialTransactionList.get(o.id)[0].Credit_Account_Number__r.Name
                                        );
                                        
                                        journalEntriesToUpsert.add(newJE);
                                    
                                    }else{
                                        break;
                                    }
                                }//END relatedDespoitJE LOOP

                            }
                            //has records Revenue Recived labor
                            else if(alreadyHasJEofTypeRevRecLabor == true && relatedRevRecognizedRefundDepositJE.size() > 0){
                                for(Journal_Entry__c je: relatedRevRecognizedRefundDepositJE){
                                    if(je.Sent_to_BaanERP__c == true){
                                        mapNew.get(o.id).addError(RMS_errorMessages.REVENUE_ALREADY_RECOGNIZED, FALSE);
                                        break;
                                    }
                                }
                            }
                            
                            //does not have related JE records of type Revenue Recived labor
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
                                            
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedLaborFinacialTransactionList.get(o.id)[0].Debit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedLaborFinacialTransactionList.get(o.id)[0].Credit_Account_Number__r.Name
                                        );
                                        
                                        journalEntriesToUpsert.add(newJE);
                                    
                                    }else{
                                        break;
                                    }
                                }//END relatedDespoitJE LOOP

                            }
                            //has records Revenue Recived labor
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
                                            
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedRefundDepositFinacialTransactionList.get(o.id)[0].Credit_Account_Number__r.Name,
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedRefundDepositFinacialTransactionList.get(o.id)[0].Debit_Account_Number__r.Name
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
                                            Credit_General_Ledger_Account__c = orderIdToRevRecognizedGrossSalesFinacialTransactionList.get(o.id)[0].Credit_Account_Number__r.Name
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
                                                        
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedDiscountFinacialTransactionList.get(o.id)[0].Debit_Account_Number__r.Name,
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
                                                        
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedARFinacialTransactionList.get(o.id)[0].Debit_Account_Number__r.Name,
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
                                                        
                                            Debit_General_Ledger_Account__c = orderIdToRevRecognizedFinanceFeesFinacialTransactionList.get(o.id)[0].Debit_Account_Number__r.Name,
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
                else if(mapOld.get(o.id).Revenue_Recognized_Date__c != null && mapNew.get(o.id).Revenue_Recognized_Date__c == null){
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
                else if(mapOld.get(o.id).Revenue_Recognized_Date__c != null && mapNew.get(o.id).Revenue_Recognized_Date__c != null){
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
        map<Id, list<Financial_Transaction__c>>  refundIdToDepositFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Deposit');
        map<Id, list<Financial_Transaction__c>>  refundIdToFinalPaymentFinacialTransactionList = linkFinacialTransactions(extraFieldsList, 'Final Payment');
        
        for(Refund__c ref : extraFieldsList){
            String refundType;
            if(ref.Order__r.Revenue_Recognized_Date__c == null){
                refundType = 'deposit';
            }else if(ref.Order__r.Revenue_Recognized_Date__c != null){
                refundType = 'finalPayment';
            }
            
            string errorMessage;
            if(refundType == 'deposit'){
                errorMessage = checkFinacialTransationForErrors(refundIdToDepositFinacialTransactionList.get(ref.id) , errorMessage, 'Deposit');
            }else if(refundType == 'finalPayment'){
                errorMessage = checkFinacialTransationForErrors(refundIdToFinalPaymentFinacialTransactionList.get(ref.id) , errorMessage, 'Final Payment');
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
                      newJE.Debit_General_Ledger_Account__c = refundIdToDepositFinacialTransactionList.get(ref.id)[0].Credit_Account_Number__r.Name;
                      newJE.Credit_General_Ledger_Account__c = refundIdToDepositFinacialTransactionList.get(ref.id)[0].Debit_Account_Number__r.Name;
                      
                    }else if(refundType == 'finalPayment'){
                      newJE.Type__c = 'Refund - Final Payment';
                      newJE.Debit_General_Ledger_Account__c = refundIdToFinalPaymentFinacialTransactionList.get(ref.id)[0].Credit_Account_Number__r.Name;
                      newJE.Credit_General_Ledger_Account__c = refundIdToFinalPaymentFinacialTransactionList.get(ref.id)[0].Debit_Account_Number__r.Name;
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
                                je.Debit_General_Ledger_Account__c = refundIdToDepositFinacialTransactionList.get(ref.id)[0].Credit_Account_Number__r.Name;
                                je.Credit_General_Ledger_Account__c = refundIdToDepositFinacialTransactionList.get(ref.id)[0].Debit_Account_Number__r.Name;
                            }else if(refundType == 'finalPayment'){
                                je.Type__c = 'Refund - Final Payment';
                                je.Debit_General_Ledger_Account__c = refundIdToFinalPaymentFinacialTransactionList.get(ref.id)[0].Credit_Account_Number__r.Name;
                                je.Credit_General_Ledger_Account__c = refundIdToFinalPaymentFinacialTransactionList.get(ref.id)[0].Debit_Account_Number__r.Name;
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
                                                                                        OR Refund__c IN :IdList];
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
            (labor.Installer__r.Account.Baan_Business_Partner_Number__c == null || labor.Installer__r.Account.Baan_Business_Partner_Number__c == '')){
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
    public String checkAssetForErrors(Asset asset, string errorMessage){
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
        if(asset.Quantity == 0){
            dynamicErrorMessage = RMS_errorMessages.QUANTITY_IS_ZERO;
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
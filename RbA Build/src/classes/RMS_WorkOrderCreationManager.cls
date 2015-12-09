public with sharing class RMS_WorkOrderCreationManager {
    
    
    /************************************************************
            createWorkOrderOnOrderActivation
    *************************************************************/
    public void createWorkOrderOnOrderActivation(List<Order> listOld, List<Order> listNew, Map<Id, Order> mapOld, Map<Id, Order> mapNew){
        system.debug('******INSIDE RMS_WorkOrderCreationManager/createWorkOrderOnActivation');

        list<Order> activatedOrders = new list<Order>();
        list<id> activatedOrderId = new list<id>();
        list<id> relatedDwellingIds = new list<id>();
        list<id> dwellingStoreLocationIds = new list<id>();
        
        //FILTERING OUT NON ACTIVATED ORDERS AS WELL AS BUILDING THE LIST OF DWELLINGS TO GET THEIR STORE CONFIGS
        for(Order ord : listNew){
            if(ord.Status == 'Activated' && mapOld.get(ord.Id).Status == 'Draft'){
                relatedDwellingIds.add(ord.AccountId);
                activatedOrders.add(ord);
                activatedOrderId.add(ord.id);
            }
        }
        
        //IF NO ORDERS HAVE BEEN ACTIVATED THEN SKIP REST OF LOGIC
        if(activatedOrders.size() > 0){
            
            //LOOPING THROUGH ALL DWELLINGS GETTING THEIR STORE LOCATIONS TO USE TO GET STORE CONFIGS
            for(Account dwelling : [SELECT id, Store_Location__c FROM Account WHERE Id IN :relatedDwellingIds]){
                dwellingStoreLocationIds.add(dwelling.Store_Location__c);
            }
            
            //GETTING ALL STORE CONFIGS FOR RELATED DWELLINGS
            map<Id, Store_Configuration__c> accountIdtoStoreConfigMap = UtilityMethods.mapStoreConfigs(dwellingStoreLocationIds);
        
            //QUERY FOR FIELDS ON DWELLING TO POPULATE WORK ORDER
            list<Account> relatedDwelling = [SELECT Id,  
                                                    Store_Location__c, 
                                                    HOA__c, Historical__c, 
                                                    Building_Permit__c,
                                                    BillingStreet,
                                                    BillingCity,
                                                    BillingState,
                                                    BillingStateCode,
                                                    BillingPostalCode, 
                                                    BillingCountry,
                                                    BillingCountryCode,
                                                    Year_Built__c
                                                FROM Account Where Id IN : relatedDwellingIds];
            
            //BUILDING MAP OF ID TO DWELLING TO USE WHILE LOOPING THROUGH ORDERS
            map<id, Account> dwellingIdtoDwellingMap = new map<id, Account>();
            for(Account dwel : relatedDwelling){
                dwellingIdtoDwellingMap.put(dwel.id, dwel);
                
            }
            
            
            //RETREVING RECORD TYPES USED IN WORK ORDER CREATION
            Id permitWORecordType = UtilityMethods.retrieveRecordTypeId('Permit', 'SVMXC__Service_Order__c');
            Id actionWORecordType = UtilityMethods.retrieveRecordTypeId('Actions', 'SVMXC__Service_Order__c');
            Id LeadWORecordType = UtilityMethods.retrieveRecordTypeId('Lead', 'SVMXC__Service_Order__c');
            
            
            
            //BUILDING MAP OF ORD ID TO LIST OF LEAD WORK ORDERS TO USE WHILE LOOPING THROUGH ORDERS
            map<id, list<SVMXC__Service_Order__c>> ordIdtoListOfLeadWOMap = new map<id, list<SVMXC__Service_Order__c>>();
            list<SVMXC__Service_Order__c> relatedLeadWorkOrders = [SELECT id, Sold_Order__c, RecordTypeId FROM SVMXC__Service_Order__c WHERE Sold_Order__c IN :activatedOrderId AND RecordTypeId = :LeadWORecordType];

            for(SVMXC__Service_Order__c wo : relatedLeadWorkOrders){
                if(ordIdtoListOfLeadWOMap.containsKey(wo.Sold_Order__c)){
                    ordIdtoListOfLeadWOMap.get(wo.Sold_Order__c).add(wo);
                }else{
                    ordIdtoListOfLeadWOMap.put(wo.Sold_Order__c, new list<SVMXC__Service_Order__c>{wo});
                }
            }
 
            //LIST OF ORDERS TO INSERT AFTER FOR LOOP
            list<SVMXC__Service_Order__c> workOrdersToAdd = new list<SVMXC__Service_Order__c>();
            
            //LOOP THROUGH ACTIVATED ORDERS AND CREATE WORK ORDERS
            for(Order ord : activatedOrders){
                
                Account dwelling = dwellingIdtoDwellingMap.get(ord.AccountId);
                Store_Configuration__c storeConfig;
                
                //NULL CHECKS AND ERRORS IF NO STORE LOCATION OR NO STORE CONFIGURATION
                if(dwelling.Store_Location__c == null){ 
                    ord.addError('Store has not been set on dwelling.');
                }else if(accountIdtoStoreConfigMap.get(dwelling.Store_Location__c) == null){
                    ord.addError('Store Configuation has not been created.');
                }else{
                    
                    //GET STORE CONFIG FROM MAP
                    storeConfig = accountIdtoStoreConfigMap.get(dwelling.Store_Location__c);
                
                    //CREATE HOA WORK ORDER IF DWELLING HAS HOA POPULATED
                    if(dwelling.HOA__c != null){
                        SVMXC__Service_Order__c hoaWorkOrder = UtilityMethods.buildWorkOrder(dwelling, ord, actionWORecordType, storeConfig.HOA_Work_Order_Queue_Id__c, 'HOA',  dwelling.HOA__c);
                        workOrdersToAdd.add(hoaWorkOrder);
                    }
                    
                    //CREATE HISTORICAL WORK ORDER IF DWELLING HAS HISTORICAL POPULATED
                    if(dwelling.Historical__c != null){
                        SVMXC__Service_Order__c historicalWorkOrder = UtilityMethods.buildWorkOrder(dwelling, ord, actionWORecordType, storeConfig.Historical_Work_Order_Queue_Id__c, 'Historical', dwelling.Historical__c );
                        workOrdersToAdd.add(historicalWorkOrder);
                    }
                    
                    //CREATE PERMIT WORK ORDER IF DWELLING HAS BUILDING PERMIT POPULATED
                    if(dwelling.Building_Permit__c != null){
                        SVMXC__Service_Order__c buildingPermitWorkOrder = UtilityMethods.buildWorkOrder(dwelling, ord, permitWORecordType, storeConfig.Building_Permit_Work_Order_Queue_Id__c, 'Building Permit', dwelling.Building_Permit__c );
                        workOrdersToAdd.add(buildingPermitWorkOrder);
                    }
                    //CREATE LEAD WORK ORDER IF NO LEAD WORK ORDER BU DWELLING Year_Built__c IS NULL OR BEFORE  1970
                    if(ordIdtoListOfLeadWOMap.get(ord.id) == null || ordIdtoListOfLeadWOMap.get(ord.id).size() == 0){
	                    if(dwelling.Year_Built__c == null || dwelling.Year_Built__c == ''  || Integer.valueof(Dwelling.Year_Built__c) < 1970){
	                        SVMXC__Service_Order__c leadWorkOrder = UtilityMethods.buildWorkOrder(dwelling, ord, LeadWORecordType, storeConfig.Paint_Stain_Work_Order_Queue_ID__c, 'Lead Paint', null );
	                        workOrdersToAdd.add(leadWorkOrder);
	                    }
                    }
                }
            }
            
            //INSERT ALL WORK ORDERS CREATED
            system.debug('****** RMS_WorkOrderCreationManager/createWorkOrderOnActivation Inserting workOrdersToAdd: '+workOrdersToAdd);
            insert workOrdersToAdd;
            
        }// END IF activatedOrders.size() > 0
    }// END createWorkOrderOnActivation METHOD
    
    

    /************************************************************
            createWorkOrderOnOrderCreation
    *************************************************************/
    
    public void createWorkOrderOnOrderCreation(List<Order> listNew, Map<Id, Order> mapNew){
        system.debug('******INSIDE RMS_WorkOrderCreationManager/createWorkOrderOnOrderCreation');
        
        list<SVMXC__Service_Order__c> workOrdersToAdd = new list<SVMXC__Service_Order__c>();
        Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'SVMXC__Service_Order__c');
        
        
        list<Id> relatedAccountIds = new list<Id>();
        list<id> relatedOpportunityIds = new list<id>();
        
        for(Order o : listNew){
            relatedAccountIds.add(o.AccountId);
            //IF OPPORTUNITY POPULATED THEN ADD TO LIST
            	system.debug('****** order: '+o);
                if(o.OpportunityId != null){
                    relatedOpportunityIds.add(o.OpportunityId);
                }  
        } 
        
        list<Account> relatedAccounts = [SELECT BillingStreet,
                                                BillingCity,
                                                BillingState,
                                                BillingStateCode,
                                                BillingPostalCode, 
                                                BillingCountry,
                                                BillingCountryCode,
                                                Store_Location__c
                                                
                                                FROM Account WHERE Id IN :relatedAccountIds];
        map<id, Account> accountIdToAccountMap = new map<id, Account>();        
        list<id> dwellingStoreLocationIds = new list<id>();
        for(Account a : relatedAccounts){
            accountIdToAccountMap.put(a.id, a);
            dwellingStoreLocationIds.add(a.Store_Location__c);
        }
        
        //IF ANY RELATED OPPS EXIST THEN QUERY FOR TECH MEASURE WORK ORDERS ON THEM
        map<id, list<SVMXC__Service_Order__c>> oppIdtoListOfTechMeasureWOMap = new map<id, list<SVMXC__Service_Order__c>>();
        if(relatedOpportunityIds.size() > 0){
            list<SVMXC__Service_Order__c> relatedTechMeasureWorkOrders = [SELECT    Id,  
                                                                                    Opportunity__c
                                                                    FROM SVMXC__Service_Order__c 
                                                                    WHERE Opportunity__c IN : relatedOpportunityIds
                                                                    AND SVMXC__Order_Type__c = 'Tech Measure'];
       
            //BUILDING MAP OF OPP ID TO LIST OF WORK ORDERS TO USE WHILE LOOPING THROUGH ORDERS
            
            for(SVMXC__Service_Order__c wo : relatedTechMeasureWorkOrders){
                if(oppIdtoListOfTechMeasureWOMap.containsKey(wo.Opportunity__c)){
                    oppIdtoListOfTechMeasureWOMap.get(wo.Opportunity__c).add(wo);
                }else{
                    oppIdtoListOfTechMeasureWOMap.put(wo.Opportunity__c, new list<SVMXC__Service_Order__c>{wo});
                }
            }
                
                
        }   
        
        //GETTING ALL STORE CONFIGS FOR RELATED DWELLINGS
        map<Id, Store_Configuration__c> accountIdtoStoreConfigMap = UtilityMethods.mapStoreConfigs(dwellingStoreLocationIds);
        

        for(Order ord : listNew){ 
            //CHECKING IF CURRENT ORDER'S OPPORTUNITY HAS ANY RELATED TECH MEASURES IF SO, SKIP LOGIC AND ASSIGN THOSE TO THIS WORK ORDER
            system.debug('****** ord ' + ord);
            if(ord.OpportunityId != null && oppIdtoListOfTechMeasureWOMap.get(ord.OpportunityId) != null){
                
	            list<SVMXC__Service_Order__c> techMeasureWorkOrders = oppIdtoListOfTechMeasureWOMap.get(ord.OpportunityId);
	            
	            for(SVMXC__Service_Order__c wo : techMeasureWorkOrders){
	                wo.Sold_Order__c = ord.id;
	                workOrdersToAdd.add(wo);
	            }
	            
            
            }else{
                Account relatedDwelling = accountIdToAccountMap.get(ord.AccountId);
    
                if(accountIdtoStoreConfigMap.get(relatedDwelling.Store_Location__c) == null){
                    ord.addError('Store Configuation has not been created.');
                }
                
                Id installQueueId = accountIdtoStoreConfigMap.get(relatedDwelling.Store_Location__c).Install_Work_Order_Queue_Id__c;
                Id techMeasureQueueId = accountIdtoStoreConfigMap.get(relatedDwelling.Store_Location__c).Tech_Measure_Work_Order_Queue_Id__c;
                
                //CREATE WORK ORDER (TECH MEASURE)
                SVMXC__Service_Order__c techWO = new SVMXC__Service_Order__c(
                    Sold_Order__c = ord.id,
                    RecordTypeId = serviceOrderVisitRecordTypeId,
                    SVMXC__Order_Type__c = 'Tech Measure',
                    SVMXC__Company__c = ord.AccountId,
                        
                    SVMXC__Street__c = relatedDwelling.BillingStreet,
                    SVMXC__City__c = relatedDwelling.BillingCity,
                    SVMXC__State__c = relatedDwelling.BillingStateCode,
                    SVMXC__Zip__c = relatedDwelling.BillingPostalCode, 
                    SVMXC__Country__c = relatedDwelling.BillingCountryCode,
    
                    OwnerId = techMeasureQueueId
                );
                workOrdersToAdd.add(techWO);
                
                /*
                //TODO: Remove if not used
                //CREATE WORK ORDER (INSTALL)
                SVMXC__Service_Order__c installWO = new SVMXC__Service_Order__c(
                    Sold_Order__c = ord.id, 
                    RecordTypeId =  serviceOrderVisitRecordTypeId,
                    SVMXC__Order_Type__c = 'Install',
                    SVMXC__Company__c = ord.AccountId,
                    
                    SVMXC__Street__c = relatedDwelling.BillingStreet,
                    SVMXC__City__c = relatedDwelling.BillingCity,
                    SVMXC__State__c = relatedDwelling.BillingStateCode,
                    SVMXC__Zip__c = relatedDwelling.BillingPostalCode, 
                    SVMXC__Country__c = relatedDwelling.BillingCountryCode,
                    
                    
                    OwnerId = installQueueId
                );
                system.debug('ads adding install WO: '+installWO);
                workOrdersToAdd.add(installWO); 
                */
    
                Store_Configuration__c storeConfig = accountIdtoStoreConfigMap.get(relatedDwelling.Store_Location__c);
                system.debug('ADS storeConfig :'+storeConfig);
    
            }
        }
        //INSERT ALL WORK ORDERS
        upsert workOrdersToAdd;    
           
    }// END OF createWorkOrderOnOrderCreation METHOD



}// EOF
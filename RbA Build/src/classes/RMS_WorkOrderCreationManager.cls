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
                                                    ShippingStreet,
                                                    ShippingCity,
                                                    ShippingState,
                                                    ShippingStateCode,
                                                    ShippingPostalCode, 
                                                    ShippingCountry,
                                                    ShippingCountryCode,
                                                    Year_Built__c
                                                FROM Account Where Id IN : relatedDwellingIds];
            
            //BUILDING MAP OF ID TO DWELLING TO USE WHILE LOOPING THROUGH ORDERS
            map<id, Account> dwellingIdtoDwellingMap = new map<id, Account>();
            for(Account dwel : relatedDwelling){
                dwellingIdtoDwellingMap.put(dwel.id, dwel);
                
            }
            
            
            //RETREVING RECORD TYPES USED IN WORK ORDER CREATION
            Id permitWORecordType = UtilityMethods.retrieveRecordTypeId('Permit', 'RbA_Work_Order__c');
            Id actionWORecordType = UtilityMethods.retrieveRecordTypeId('Actions', 'RbA_Work_Order__c');
            Id LSWPWORecordType = UtilityMethods.retrieveRecordTypeId('LSWP', 'RbA_Work_Order__c');
            
            
            
            //BUILDING MAP OF ORD ID TO LIST OF LSWP WORK ORDERS TO USE WHILE LOOPING THROUGH ORDERS
            map<id, list<RbA_Work_Order__c>> ordIdtoListOfLSWPWOMap = new map<id, list<RbA_Work_Order__c>>();
            list<RbA_Work_Order__c> relatedLSWPWorkOrders = [SELECT id, Sold_Order__c, RecordTypeId FROM RbA_Work_Order__c WHERE Sold_Order__c IN :activatedOrderId AND RecordTypeId = :LSWPWORecordType];

            for(RbA_Work_Order__c wo : relatedLSWPWorkOrders){
                if(ordIdtoListOfLSWPWOMap.containsKey(wo.Sold_Order__c)){
                    ordIdtoListOfLSWPWOMap.get(wo.Sold_Order__c).add(wo);
                }else{
                    ordIdtoListOfLSWPWOMap.put(wo.Sold_Order__c, new list<RbA_Work_Order__c>{wo});
                }
            }
 
            //LIST OF ORDERS TO INSERT AFTER FOR LOOP
            list<RbA_Work_Order__c> workOrdersToAdd = new list<RbA_Work_Order__c>();
            
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
                        RbA_Work_Order__c hoaWorkOrder = UtilityMethods.buildWorkOrder(dwelling, ord, actionWORecordType, storeConfig.HOA_Work_Order_Queue_Id__c, 'HOA',  dwelling.HOA__c);
                        workOrdersToAdd.add(hoaWorkOrder);
                    }
                    
                    //CREATE HISTORICAL WORK ORDER IF DWELLING HAS HISTORICAL POPULATED
                    if(dwelling.Historical__c != null){
                        RbA_Work_Order__c historicalWorkOrder = UtilityMethods.buildWorkOrder(dwelling, ord, actionWORecordType, storeConfig.Historical_Work_Order_Queue_Id__c, 'Historical', dwelling.Historical__c );
                        workOrdersToAdd.add(historicalWorkOrder);
                    }
                    
                    //CREATE PERMIT WORK ORDER IF DWELLING HAS BUILDING PERMIT POPULATED
                    if(dwelling.Building_Permit__c != null){
                        RbA_Work_Order__c buildingPermitWorkOrder = UtilityMethods.buildWorkOrder(dwelling, ord, permitWORecordType, storeConfig.Building_Permit_Work_Order_Queue_Id__c, 'Building Permit', dwelling.Building_Permit__c );
                        workOrdersToAdd.add(buildingPermitWorkOrder);
                    }
                    //CREATE LSWP WORK ORDER IF NO LSWP WORK ORDER BU DWELLING Year_Built__c IS NULL OR BEFORE  1978
                    if(ordIdtoListOfLSWPWOMap.get(ord.id) == null || ordIdtoListOfLSWPWOMap.get(ord.id).size() == 0){
	                    if(dwelling.Year_Built__c == null || dwelling.Year_Built__c == ''  || Integer.valueof(Dwelling.Year_Built__c) < 1978){
	                        RbA_Work_Order__c LSWPWorkOrder = UtilityMethods.buildWorkOrder(dwelling, ord, LSWPWORecordType, storeConfig.LSWP_WO_Owner_ID__c, 'LSWP', null );
	                        workOrdersToAdd.add(LSWPWorkOrder);
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
        
        list<RbA_Work_Order__c> workOrdersToAdd = new list<RbA_Work_Order__c>();
        Id serviceOrderVisitRecordTypeId = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
        
        
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
        
        list<Account> relatedAccounts = [SELECT ShippingStreet,
                                                ShippingCity,
                                                ShippingState,
                                                ShippingStateCode,
                                                ShippingPostalCode, 
                                                ShippingCountry,
                                                ShippingCountryCode,
                                                Store_Location__c
                                                
                                                FROM Account WHERE Id IN :relatedAccountIds];
        map<id, Account> accountIdToAccountMap = new map<id, Account>();        
        list<id> dwellingStoreLocationIds = new list<id>();
        for(Account a : relatedAccounts){
            accountIdToAccountMap.put(a.id, a);
            dwellingStoreLocationIds.add(a.Store_Location__c);
        }
        
        //IF ANY RELATED OPPS EXIST THEN QUERY FOR TECH MEASURE WORK ORDERS ON THEM
        map<id, list<RbA_Work_Order__c>> oppIdtoListOfTechMeasureWOMap = new map<id, list<RbA_Work_Order__c>>();
        if(relatedOpportunityIds.size() > 0){
            list<RbA_Work_Order__c> relatedTechMeasureWorkOrders = [SELECT    Id,  
                                                                                    Opportunity__c
                                                                    FROM RbA_Work_Order__c 
                                                                    WHERE Opportunity__c IN : relatedOpportunityIds
                                                                    AND Order_Type__c = 'Tech Measure'];
       
            //BUILDING MAP OF OPP ID TO LIST OF WORK ORDERS TO USE WHILE LOOPING THROUGH ORDERS
            
            for(RbA_Work_Order__c wo : relatedTechMeasureWorkOrders){
                if(oppIdtoListOfTechMeasureWOMap.containsKey(wo.Opportunity__c)){
                    oppIdtoListOfTechMeasureWOMap.get(wo.Opportunity__c).add(wo);
                }else{
                    oppIdtoListOfTechMeasureWOMap.put(wo.Opportunity__c, new list<RbA_Work_Order__c>{wo});
                }
            }
                
                
        }   
        
        //GETTING ALL STORE CONFIGS FOR RELATED DWELLINGS
        map<Id, Store_Configuration__c> accountIdtoStoreConfigMap = UtilityMethods.mapStoreConfigs(dwellingStoreLocationIds);
        

        for(Order ord : listNew){ 
            //CHECKING IF CURRENT ORDER'S OPPORTUNITY HAS ANY RELATED TECH MEASURES IF SO, SKIP LOGIC AND ASSIGN THOSE TO THIS WORK ORDER
            system.debug('****** ord ' + ord);
            if(ord.OpportunityId != null && oppIdtoListOfTechMeasureWOMap.get(ord.OpportunityId) != null){
                
	            list<RbA_Work_Order__c> techMeasureWorkOrders = oppIdtoListOfTechMeasureWOMap.get(ord.OpportunityId);
	            
	            for(RbA_Work_Order__c wo : techMeasureWorkOrders){
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
                RbA_Work_Order__c techWO = new RbA_Work_Order__c(
                    Sold_Order__c = ord.id,
                    RecordTypeId = serviceOrderVisitRecordTypeId,
                    Order_Type__c = 'Tech Measure',
                    Account__c = ord.AccountId,
                    Contact__c = ord.BillToContactId,
                    
                    
                    Street__c = relatedDwelling.ShippingStreet,
                    City__c = relatedDwelling.ShippingCity,
                    State__c = relatedDwelling.ShippingStateCode,
                    Zip__c = relatedDwelling.ShippingPostalCode, 
                    Country__c = relatedDwelling.ShippingCountryCode,
    
                    OwnerId = techMeasureQueueId
                );
                workOrdersToAdd.add(techWO);
                
                /*
                //TODO: Remove if not used
                //CREATE WORK ORDER (INSTALL)
                RbA_Work_Order__c installWO = new RbA_Work_Order__c(
                    Sold_Order__c = ord.id, 
                    RecordTypeId =  serviceOrderVisitRecordTypeId,
                    Order_Type__c = 'Install',
                    Account__c = ord.AccountId,
                    
                    Street__c = relatedDwelling.ShippingStreet,
                    City__c = relatedDwelling.ShippingCity,
                    State__c = relatedDwelling.ShippingStateCode,
                    Zip__c = relatedDwelling.ShippingPostalCode, 
                    Country__c = relatedDwelling.ShippingCountryCode,
                    
                    
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
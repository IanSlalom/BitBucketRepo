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
            if(ord.Status == 'Tech Measure Needed' && mapOld.get(ord.Id).Status == 'Draft'){
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
                                                    Year_Built__c,
                                                    Name
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
            
             
            
            //BUILDING MAPS OF ORDER ID TO LIST OF WORK ORDERS BASED ON WO TYPE TO USE WHILE LOOPING THROUGH ORDERS
            map<id, list<RbA_Work_Order__c>> ordIdtoListOfLSWPWOMap = new map<id, list<RbA_Work_Order__c>>();
            map<id, list<RbA_Work_Order__c>> ordIdtoListOfHOAWOMap = new map<id, list<RbA_Work_Order__c>>();
            map<id, list<RbA_Work_Order__c>> ordIdtoListOfBuildingPermitWOMap = new map<id, list<RbA_Work_Order__c>>();
            map<id, list<RbA_Work_Order__c>> ordIdtoListOfHistoricalWOMap = new map<id, list<RbA_Work_Order__c>>();
            list<RbA_Work_Order__c> relatedWorkOrders = [SELECT id, Sold_Order__c, Work_Order_Type__c, RecordTypeId FROM RbA_Work_Order__c WHERE Sold_Order__c IN :activatedOrderId];

            for(RbA_Work_Order__c wo : relatedWorkOrders){
            	if(wo.Work_Order_Type__c == 'LSWP'){
	                if(ordIdtoListOfLSWPWOMap.containsKey(wo.Sold_Order__c)){
	                    ordIdtoListOfLSWPWOMap.get(wo.Sold_Order__c).add(wo);
	                }else{
	                    ordIdtoListOfLSWPWOMap.put(wo.Sold_Order__c, new list<RbA_Work_Order__c>{wo});
	                }
            	}else if(wo.Work_Order_Type__c == 'HOA'){
	                if(ordIdtoListOfHOAWOMap.containsKey(wo.Sold_Order__c)){
	                    ordIdtoListOfHOAWOMap.get(wo.Sold_Order__c).add(wo);
	                }else{
	                    ordIdtoListOfHOAWOMap.put(wo.Sold_Order__c, new list<RbA_Work_Order__c>{wo});
	                }
            	}else if(wo.Work_Order_Type__c == 'Building Permit'){
	                if(ordIdtoListOfBuildingPermitWOMap.containsKey(wo.Sold_Order__c)){
	                    ordIdtoListOfBuildingPermitWOMap.get(wo.Sold_Order__c).add(wo);
	                }else{
	                    ordIdtoListOfBuildingPermitWOMap.put(wo.Sold_Order__c, new list<RbA_Work_Order__c>{wo});
	                }
            	}else if(wo.Work_Order_Type__c == 'Historical'){
	                if(ordIdtoListOfHistoricalWOMap.containsKey(wo.Sold_Order__c)){
	                    ordIdtoListOfHistoricalWOMap.get(wo.Sold_Order__c).add(wo);
	                }else{
	                    ordIdtoListOfHistoricalWOMap.put(wo.Sold_Order__c, new list<RbA_Work_Order__c>{wo});
	                }
            	}
 
            }
 
            //LIST OF ORDERS TO INSERT AFTER FOR LOOP
            list<RbA_Work_Order__c> workOrdersToAdd = new list<RbA_Work_Order__c>();
            
            //LOOP THROUGH ACTIVATED ORDERS AND CREATE WORK ORDERS
            for(Order ord : activatedOrders){
				System.Debug('*********ord' +ord);                
                Account dwelling = dwellingIdtoDwellingMap.get(ord.AccountId);
                Store_Configuration__c storeConfig;
                
                //NULL CHECKS AND ERRORS IF NO STORE LOCATION OR NO STORE CONFIGURATION
                if(dwelling.Store_Location__c == null){ 
                    ord.addError('Store has not been set on dwelling.');
                }else if(accountIdtoStoreConfigMap.get(dwelling.Store_Location__c) == null){
                    ord.addError('Store Configuration   has not been created.');
                }else{
                    
                    //GET STORE CONFIG FROM MAP
                    storeConfig = accountIdtoStoreConfigMap.get(dwelling.Store_Location__c);
                
                    //CREATE HOA WORK ORDER IF DWELLING HAS HOA POPULATED
                    if(ordIdtoListOfHOAWOMap.get(ord.id) == null || ordIdtoListOfHOAWOMap.get(ord.id).size() == 0){
	                    if(dwelling.HOA__c != null){
	                        RbA_Work_Order__c hoaWorkOrder = UtilityMethods.buildWorkOrder(dwelling, ord, actionWORecordType, storeConfig.HOA_Work_Order_Queue_Id__c, 'HOA',  dwelling.HOA__c);
	                        workOrdersToAdd.add(hoaWorkOrder);
	                    }
                    }
                    //CREATE HISTORICAL WORK ORDER IF DWELLING HAS HISTORICAL POPULATED
					if(ordIdtoListOfHistoricalWOMap.get(ord.id) == null || ordIdtoListOfHistoricalWOMap.get(ord.id).size() == 0){                   
	                    if(dwelling.Historical__c != null){
	                        RbA_Work_Order__c historicalWorkOrder = UtilityMethods.buildWorkOrder(dwelling, ord, actionWORecordType, storeConfig.Historical_Work_Order_Queue_Id__c, 'Historical', dwelling.Historical__c );
	                        workOrdersToAdd.add(historicalWorkOrder);
	                    }
					}
                    //CREATE PERMIT WORK ORDER IF DWELLING HAS BUILDING PERMIT POPULATED
                    if(ordIdtoListOfBuildingPermitWOMap.get(ord.id) == null || ordIdtoListOfBuildingPermitWOMap.get(ord.id).size() == 0){
	                    if(dwelling.Building_Permit__c != null){
	                        RbA_Work_Order__c buildingPermitWorkOrder = UtilityMethods.buildWorkOrder(dwelling, ord, permitWORecordType, storeConfig.Building_Permit_Work_Order_Queue_Id__c, 'Building Permit', dwelling.Building_Permit__c );
	                        workOrdersToAdd.add(buildingPermitWorkOrder);
	                    }
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
        Id orderCoroServiceRecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order');
        Id visitWORecordType = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
        
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
                                                Store_Location__c,
                                                Name
                                                
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
                                                                    AND Work_Order_Type__c = 'Tech Measure'];
       
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
	            
            //CHECK THE RECORD TYPE IS CORO SERVICE, IF IT IS, SKIP LOGIC
            }else{
                Account relatedDwelling = accountIdToAccountMap.get(ord.AccountId);
    			if (relatedDwelling.Name == 'RbA') continue;  //If this is RbA (Cost PO order), then continue
                if(accountIdtoStoreConfigMap.get(relatedDwelling.Store_Location__c) == null){
                    ord.addError('Store Configuation has not been created.');
                } 
                
                Id techMeasureQueueId = accountIdtoStoreConfigMap.get(relatedDwelling.Store_Location__c).Tech_Measure_Work_Order_Queue_Id__c;
                Id serviceQueueId;
                if(accountIdtoStoreConfigMap.get(relatedDwelling.Store_Location__c).Service_Work_Order_Queue_ID__c != null){
                	serviceQueueId = accountIdtoStoreConfigMap.get(relatedDwelling.Store_Location__c).Service_Work_Order_Queue_ID__c;
                }else{
                	serviceQueueId = UserInfo.getUserId();
            	}
                if(ord.RecordTypeId == orderCoroServiceRecordTypeId){
            		 RbA_Work_Order__c serviceWorkOrder = UtilityMethods.buildWorkOrder(relatedDwelling, ord, visitWORecordType, serviceQueueId, 'Service', null );
            		 
            		 workOrdersToAdd.add(serviceWorkOrder);
                }else{
	                //CREATE WORK ORDER (TECH MEASURE)
	                RbA_Work_Order__c techWO = new RbA_Work_Order__c(
	                    Sold_Order__c = ord.id,
	                    RecordTypeId = serviceOrderVisitRecordTypeId,
	                    Work_Order_Type__c = 'Tech Measure',
	                    Account__c = ord.AccountId,
	                    Contact__c = ord.BillToContactId,
	                    Opportunity__c = ord.OpportunityId,
	                    
	                    Street__c = relatedDwelling.ShippingStreet,
	                    City__c = relatedDwelling.ShippingCity,
	                    State__c = relatedDwelling.ShippingStateCode,
	                    Zip__c = relatedDwelling.ShippingPostalCode, 
	                    Country__c = relatedDwelling.ShippingCountryCode,
	    
	                    OwnerId = techMeasureQueueId
	                );
	                workOrdersToAdd.add(techWO);
                }
    
            }
        }
        //INSERT ALL WORK ORDERS
        upsert workOrdersToAdd;    
           
    }// END OF createWorkOrderOnOrderCreation METHOD














	/************************************************************
            createInstallWorkOrderOnTechMeasureComplete
    *************************************************************/
    public void createInstallWorkOrderOnTechMeasureComplete(List<RbA_Work_Order__c> listOld, List<RbA_Work_Order__c> listNew, Map<Id, RbA_Work_Order__c> mapOld, Map<Id, RbA_Work_Order__c> mapNew){
		system.debug('**** RMS_WorkOrderCreationManager/createInstallWorkOrderOnTechMeasureComplete');
		Id visitWORecordType = UtilityMethods.retrieveRecordTypeId('Visit', 'RbA_Work_Order__c');
	  	       
		list<RbA_Work_Order__c> workOrdersToInsert = new list<RbA_Work_Order__c>();
		list<RbA_Work_Order__c> completeWorkOrders = new list<RbA_Work_Order__c>();
		list<id> relatedDwellingIds = new list<id>();
		list<Id> relatedOrderIdList = new list<id>();
		list<id> dwellingStoreLocationIds = new list<id>();
		
		list<RbA_Work_Order__c> extraFieldsList = [SELECT 	id,
													Sold_Order__c, 
								                    Sold_Order__r.BillToContactId,
													Sold_Order__r.OpportunityId,
													
								                    RecordTypeId,
								                    Work_Order_Type__c,
								                    Account__c,
								                    Account__r.Store_Location__c,
								                    
								                    Street__c,
								                    City__c,
								                    State__c,
								                    Zip__c, 
								                    Country__c,
								                    OwnerId,
								                    
								                    Work_Order_Scheduling_Status__c
								                    
													FROM RbA_Work_Order__c WHERE Id IN :mapNew.keyset()];		
		
		
		for(RbA_Work_Order__c wo : extraFieldsList){
      		if(wo.Work_Order_Type__c != null && wo.Work_Order_Type__c == 'Tech Measure'){
	      		if(mapOld.get(wo.id).Work_Order_Scheduling_Status__c != 'Complete' && mapNew.get(wo.id).Work_Order_Scheduling_Status__c == 'Complete'){
	      			completeWorkOrders.add(wo);
	      			relatedOrderIdList.add(wo.Sold_Order__c);
	      			relatedDwellingIds.add(wo.Account__c);
	      		}
      		}
		}
		
		system.debug('**** relatedOrderIdList: '+relatedOrderIdList);
		system.debug('**** completeWorkOrders: '+completeWorkOrders);
		system.debug('**** relatedDwellingIds: '+relatedDwellingIds);
		//GET RELATED DWELLINGS AND ASSIGN TO MAP
		for(Account dwelling : [SELECT id, Store_Location__c FROM Account WHERE Id IN :relatedDwellingIds]){
                dwellingStoreLocationIds.add(dwelling.Store_Location__c);
        }
        map<Id, Store_Configuration__c> accountIdtoStoreConfigMap = UtilityMethods.mapStoreConfigs(dwellingStoreLocationIds);

		//GET RELATED WORK ORDERS ON SAME ORDER AND MAP THEM
		list<RbA_Work_Order__c> relatedWorkOrders = [SELECT Id, Sold_Order__c, Work_Order_Type__c  FROM RbA_Work_Order__c Where Sold_Order__c IN :relatedOrderIdList];
		
		map<id, list<RbA_Work_Order__c>> orderIdToListWorkOrdersMap = new map<id, list<RbA_Work_Order__c>>();
		for(RbA_Work_Order__c wo : relatedWorkOrders){
		   if(orderIdToListWorkOrdersMap.containsKey(wo.Sold_Order__c)){
                orderIdToListWorkOrdersMap.get(wo.Sold_Order__c).add(wo);
            }else{ 
                orderIdToListWorkOrdersMap.put(wo.Sold_Order__c, new list<RbA_Work_Order__c>{wo});
            }
		}
		   
      	
      	for(RbA_Work_Order__c wo : completeWorkOrders){
      		system.debug('ads orderIdToListWorkOrdersMap: '+orderIdToListWorkOrdersMap);
      		system.debug('ads wo.Sold_Order__c: '+wo.Sold_Order__c);
      		
      		system.debug('ads orderIdToListWorkOrdersMap.get(wo.Sold_Order__c): '+orderIdToListWorkOrdersMap.get(wo.Sold_Order__c));
  			boolean alreadyHaveInstall = false;
      		if(orderIdToListWorkOrdersMap.get(wo.Sold_Order__c) != null && orderIdToListWorkOrdersMap.get(wo.Sold_Order__c).size() > 0 ){
      			for(RbA_Work_Order__c relatedWO : orderIdToListWorkOrdersMap.get(wo.Sold_Order__c)){
      				if(relatedWO.Work_Order_Type__c == 'Install'){
      					alreadyHaveInstall = true;
      					break;
      				} 
      			}
      		}//end of check for null related	
  			if(alreadyHaveInstall == false){
  				system.debug('ads accountIdtoStoreConfigMap: '+accountIdtoStoreConfigMap);
          		system.debug('ads wo.Account__c: '+wo.Account__r.Store_Location__c);
          	
          	
          		if(wo.Account__c == null){ 
                    mapNew.get(wo.id).addError('Dwelling must be set to complete Tech Measure.');
          		}else if(wo.Account__r.Store_Location__c == null){
		            mapNew.get(wo.id).addError('Store Location must be set on related Dwelling');
                }else if(accountIdtoStoreConfigMap.get(wo.Account__r.Store_Location__c) == null){
                    mapNew.get(wo.id).addError('Store Configuration has not been created for the related Dwellings Store.');
                }
 
		        else{
	  				Id installQueueId = accountIdtoStoreConfigMap.get(wo.Account__r.Store_Location__c).Install_Work_Order_Queue_Id__c;
	  				
	  				RbA_Work_Order__c installWO = new RbA_Work_Order__c(
	                    Sold_Order__c = wo.Sold_Order__c, 
	                    RecordTypeId =  visitWORecordType,
	                    Work_Order_Type__c = 'Install',
	                    Account__c = wo.Account__c,
	                    
	                    Street__c = wo.Street__c,
	                    City__c = wo.City__c,
	                    State__c = wo.State__c,
	                    Zip__c = wo.Zip__c, 
	                    Country__c = wo.Country__c,
						
						Contact__c = wo.Sold_Order__r.BillToContactId,
						Opportunity__c = wo.Sold_Order__r.OpportunityId,
	                    OwnerId = installQueueId
	                ); 
	                workOrdersToInsert.add(installWO);
  				}
  			}// end of alreadyHaveInstall if
      		
      	}//end of loop of compleatedWorkOrders
		system.debug('**** workOrdersToInsert: '+workOrdersToInsert);
        insert workOrdersToInsert; 
    }//end of createInstallWorkOrderOnTechMeasureComplete method

}// EOF
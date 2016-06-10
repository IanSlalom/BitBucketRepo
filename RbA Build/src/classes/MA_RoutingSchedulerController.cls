global with sharing class MA_RoutingSchedulerController {

    private static Map<String, Object> configs = new Map<String,Object>();
    private static Map<String, Object> master  = new  Map<String, Object>();

    private static Map<Id, Long> routeEndMap = new Map<Id, Long>();
    private static Map<Id, Long> routeStartMap = new Map<Id, Long>();
    private static Map<Id, Long> routeLastBreakEndMap = new Map<Id, Long>();

    public RbA_Work_Order__c tempWo {get;set;}

    public MA_RoutingSchedulerController() {
        try {
            Id visitRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'RbA_Work_Order__c' AND DeveloperName = 'Visit'].Id;
            tempWo = new RbA_Work_Order__c(RecordTypeId = visitRecordTypeId);
        }
        catch(Exception e) {
            tempWo = new RbA_Work_Order__c();
        }
    }
    
    webService static String getESRIToken(String storeId, Boolean isVerification, String clientId, String clientSecret) {
        Http h = new Http();
        String esriClientId;
        String esriClientSecret;
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        String arcGISauth = 'https://www.arcgis.com/sharing/rest/oauth2/token/';
        
        if (isVerification) {
            esriClientId = clientId;
            esriClientSecret = clientSecret;
        }
        else {
            for (MA_Scheduler_Settings__c settings : [SELECT Settings__c FROM MA_Scheduler_Settings__c WHERE Store_Id__c = :storeId AND Resource_Id__c = null]) {
                if (String.isNotBlank(settings.Settings__c)) {
                    Map<String, Object> storeSettings = (Map<String, Object>)JSON.deserializeUntyped(settings.Settings__c);
                    esriClientId = (String)storeSettings.get('esriClientId');
                    esriClientSecret = (String)storeSettings.get('esriClientSecret');
                }

                if (String.isNotBlank(esriClientId) || String.isNotBlank(esriClientSecret)) {
                    break;
                }
            }
        }

        if (String.isNotBlank(esriClientId) && String.isNotBlank(esriClientSecret)) {
            req.setEndpoint(arcGISauth);
            req.setMethod('POST');
            req.setBody('client_id=' + EncodingUtil.urlEncode(esriClientId,'UTF-8') + '&client_secret=' + EncodingUtil.urlEncode(esriClientSecret,'UTF-8') + '&grant_type=' + 'client_credentials' + '&expiration=' + '8000');
            
            try {
                res = h.send(req);
            }
            catch (System.CalloutException e) {}
        
            return res.getBody();
        }

        Map<String, Object> responseMap = new Map<String, Object> {
            'error' => new Map<String, String> {
                'error' => 'MISSING CREDENTIALS',
                'message' => 'Your ESRI credentials have not been configured for this store.  Please go to settings and complete the setup.'
            }
        };
        return JSON.serialize(responseMap);
    }
    
    webservice static String retrieveResourceRouteRecords(Id resourceId, String dayString, Id storeId) {
        try {
            Integer sequence = 0;
            List<Object> features = new List<Object>();
            Map<String, Object> stopObj = new Map<String, Object>();
            Map<String, Object> geometry =  new Map<String, Object>();
            Map<String, Object> attributes = new Map<String, Object>();
            String storeTimezone = MA_SchedulerUtilities.retrieveStoreTimezone(storeId);
            Date day = Date.parse(dayString);
            DateTime startDateTime = DateTime.newInstanceGmt(day, Time.newInstance(0, 0, 0, 0));

            if (String.isNotBlank(storeTimezone)) {
                startDateTime = MA_SchedulerUtilities.convertGmtToTimezone(startDateTime, storeTimezone, null);
            }
            DateTime endDateTime = startDateTime.addDays(1);
            
            Long milliTime = startDateTime.getTime();
            master.put('defaultdate', milliTime);
            
            List<MA_Scheduler_Event__c> maEventList = [SELECT Id, Resource__c, RbA_Work_Order__c, RbA_Work_Order__r.Name,
                                                        RbA_Work_Order__r.Appointment_Duration__c, RbA_Work_Order__r.Account__c,
                                                        RbA_Work_Order__r.Account__r.ShippingLatitude, RbA_Work_Order__r.Account__r.ShippingLongitude,
                                                        Date__c, StartDateTime__c, EndDateTime__c
                                                        FROM MA_Scheduler_Event__c WHERE Resource__c = :resourceId AND RbA_Work_Order__c != null
                                                        AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime ORDER BY StartDateTime__c]; 
            
            for (MA_Scheduler_Event__c maEvent : maEventList) {
                stopObj = new Map<String, Object>();
                geometry =  new Map<String, Object>();
                attributes = new Map<String, Object>();

                if (maEvent.RbA_Work_Order__r.Account__r.ShippingLongitude != null && maEvent.RbA_Work_Order__r.Account__r.ShippingLatitude != null) {
                    geometry.put('x', maEvent.RbA_Work_Order__r.Account__r.ShippingLongitude);
                    geometry.put('y',  maEvent.RbA_Work_Order__r.Account__r.ShippingLatitude);
               
                    DateTime maEndDateTime = maEvent.EndDateTime__c;
                    DateTime maStartDateTime = maEvent.StartDateTime__c;

                    if (String.isNotBlank(storeTimezone)) {
                        maEndDateTime = MA_SchedulerUtilities.convertTimezoneToTimezone(maEndDateTime, null, storeTimezone);
                        maStartDateTime = MA_SchedulerUtilities.convertTimezoneToTimezone(maStartDateTime, null, storeTimezone);
                    }

                    Long serviceTime = maEndDateTime.getTime() - maStartDateTime.getTime();
                    serviceTime = (Integer)(serviceTime / 1000) / 60;
                    
                    attributes.put('Name', '{"woId":"' + maEvent.RbA_Work_Order__c + '","maEventId":"' + maEvent.Id + '","woName":"' + maEvent.RbA_Work_Order__r.Name + '"}');
                    attributes.put('TimeWindowStart', maStartDateTime.getTime());
                    attributes.put('TimeWindowEnd', maEndDateTime.getTime());
                    attributes.put('RouteName', resourceId);
                    attributes.put('Sequence', sequence);
                    attributes.put('Attr_TravelTime', serviceTime);
                    attributes.put('CurbApproach', 3);
                    stopObj.put('attributes', attributes);
                    stopObj.put('geometry', geometry);
                    features.add(stopObj);
                    sequence++;
                }
            }

            master.put('stops', new Map<String, Object> { 'features' => features });
            master.put('success', true);
        }
        catch(Exception ex) {
            MA_SchedulerUtilities.createErrorResponse(ex, master);
        }

        return JSON.serialize(master);
    }

    webService static String processConfirmBatch(String woToResIdsMapString, Id storeId, String batchDateString, String primaryResourceMapString) {
        System.Savepoint sp = Database.setSavepoint();
        Map<String, Object> response = new Map<String, Object>();

        try {
            Date batchDate = Date.valueOf(batchDateString);
            List<Event> sfEventsToCreate = new List<Event>();
            Map<Id, Id> resourceIdToUserIdMap = new Map<Id, Id>();
            Map<Id, Set<Id>> oldWoToResIdsMap = new Map<Id, Set<Id>>();
            Map<Id, Set<Id>> maEventsAlreadyCreatedFor = new Map<Id, Set<Id>>();
            String storeTimezone = MA_SchedulerUtilities.retrieveStoreTimezone(storeId);
            List<MA_Scheduler_Event__c> maEventsToCreate = new List<MA_Scheduler_Event__c>();
            Map<Id, MA_Scheduler_Event__c> woToMaEventMap = new Map<Id, MA_Scheduler_Event__c>();
            Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>();
            List<Assigned_Resources__c> assignedResourcesToUpdate = new List<Assigned_Resources__c>();
            List<Assigned_Resources__c> assignedResourcesToCreate = new List<Assigned_Resources__c>();
            List<Assigned_Resources__c> assignedResourcesToDelete = new List<Assigned_Resources__c>();
            Map<Id, Id> primaryResourceMap = (Map<Id, Id>)JSON.deserialize(primaryResourceMapString, Map<Id, Id>.class);
            Map<Id, Set<Id>> woToResIdsMap = (Map<Id, Set<Id>>)JSON.deserialize(woToResIdsMapString, Map<Id, Set<Id>>.class);
            Id woEventRecTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Event' AND DeveloperName = 'Work_Order_Event'].Id;

            for (Id woId : woToResIdsMap.keySet()) {
                List<Id> assignedResourceIds = new List<Id>(woToResIdsMap.get(woId));
                if (assignedResourceIds.size() > 1) {
                    assignedResourceIds.remove(0);
                }
                woToResIdsMap.put(woId, new Set<Id>(assignedResourceIds));
            }

            for (Assigned_Resources__c res : [SELECT Id, Work_Order__c, Scheduled_Resource__c FROM Assigned_Resources__c WHERE Work_Order__c IN :woToResIdsMap.keySet()]) {
                Set<Id> assignedResourceIds = woToResIdsMap.get(res.Work_Order__c);
                                    
                if (!assignedResourceIds.contains(res.Scheduled_Resource__c)) {
                    assignedResourcesToDelete.add(res);
                }
                else {
                    if (!oldWoToResIdsMap.containsKey(res.Work_Order__c)) {
                        oldWoToResIdsMap.put(res.Work_Order__c, new Set<Id>());
                    }
                    oldWoToResIdsMap.get(res.Work_Order__c).add(res.Scheduled_Resource__c);
                }
            }
            delete assignedResourcesToDelete;

            for (MA_Scheduler_Event__c maEvent : [SELECT Id, Name, RbA_Work_Order__c, RbA_Work_Order__r.Name, RbA_Work_Order__r.Work_Order_Type__c, Resource__c, StartDateTime__c, EndDateTime__c, Date__c, Event_Sequence__c FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c IN :woToResIdsMap.keySet() AND Date__c = :batchDate]) {
                Set<Id> assignedResourceIds = woToResIdsMap.get(maEvent.RbA_Work_Order__c);
                woToMaEventMap.put(maEvent.RbA_Work_Order__c, maEvent);

                if (!assignedResourceIds.contains(maEvent.Resource__c)) {
                    maEventsToDelete.put(maEvent.Id, maEvent);
                }
                else {
                    if (!maEventsAlreadyCreatedFor.containsKey(maEvent.RbA_Work_Order__c)) {
                        maEventsAlreadyCreatedFor.put(maEvent.RbA_Work_Order__c, new Set<Id>());
                    }
                    maEventsAlreadyCreatedFor.get(maEvent.RbA_Work_Order__c).add(maEvent.Resource__c);
                }
            }

            List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet()];
            for (Event ev : sfEventsToDelete) {
                ev.Type = 'Rescheduled';
            }
            delete sfEventsToDelete;

            for (Id woId : woToResIdsMap.keySet()) {
                if (woId.getSobjectType() == Schema.RbA_Work_Order__c.SObjectType) {
                    Id primaryResourceId = primaryResourceMap.get(woId);
                    Set<Id> assignedResourceIds = woToResIdsMap.get(woId);
                    Set<Id> assignedResourceIdsAlreadyCreated = oldWoToResIdsMap.containsKey(woId) ? oldWoToResIdsMap.get(woId) : new Set<Id>();
                    assignedResourceIds.removeAll(assignedResourceIdsAlreadyCreated);

                    Set<Id> assignedResourceIdsEvents = woToResIdsMap.get(woId);
                    Set<Id> assignedResourceIdsAlreadyCreatedEvents = maEventsAlreadyCreatedFor.containsKey(woId) ? maEventsAlreadyCreatedFor.get(woId) : new Set<Id>();
                    assignedResourceIdsEvents.removeAll(assignedResourceIdsAlreadyCreatedEvents);
                    MA_Scheduler_Event__c tempEvent = woToMaEventMap.get(woId);

                    if (tempEvent != null) {
                        for (Id resourceId : assignedResourceIdsEvents) {
                            resourceIdToUserIdMap.put(resourceId, null);
                            MA_Scheduler_Event__c maEvent = new MA_Scheduler_Event__c(
                                RbA_Work_Order__c = tempEvent.RbA_Work_Order__c,
                                Event_Sequence__c = tempEvent.Event_Sequence__c,
                                StartDateTime__c = tempEvent.StartDateTime__c,
                                EndDateTime__c = tempEvent.EndDateTime__c,
                                Name = tempEvent.RbA_Work_Order__r.Name,
                                Date__c = tempEvent.Date__c,
                                Resource__c = resourceId.getSobjectType() == Schema.Resource__c.SObjectType ? resourceId : null
                            );
                            maEventsToCreate.add(maEvent);
                        }
                    }

                    for (Id resourceId : assignedResourceIds) {
                        if (resourceId.getSobjectType() == Schema.Resource__c.SObjectType) {
                            Assigned_Resources__c assignedRes = new Assigned_Resources__c(
                                Work_Order__c = woId,
                                Scheduled_Resource__c = resourceId,
                                IsPrimary__c = primaryResourceId == resourceId || assignedResourceIds.size() + assignedResourceIdsAlreadyCreated.size() == 1
                            );
                            assignedResourcesToCreate.add(assignedRes);
                        }
                    }
                }
            }
            insert assignedResourcesToCreate;
            insert maEventsToCreate;

            for (Assigned_Resources__c res : [SELECT Id, Work_Order__c, Scheduled_Resource__c, IsPrimary__c FROM Assigned_Resources__c WHERE Work_Order__c IN :woToResIdsMap.keySet()]) {
                Id primaryResourceId = primaryResourceMap.get(res.Work_Order__c);
                Set<Id> assignedResourceIds = woToResIdsMap.get(res.Work_Order__c);
                Boolean isPrimary = res.Scheduled_Resource__c == primaryResourceId || assignedResourceIds.size() == 1;

                if (res.isPrimary__c != isPrimary) {
                    res.isPrimary__c = isPrimary;
                    assignedResourcesToUpdate.add(res);
                }
            }
            update assignedResourcesToUpdate;

            for (Resource__c res : [SELECT Id, RbA_User__c FROM Resource__c WHERE Id IN :resourceIdToUserIdMap.keySet()]) {
                resourceIdToUserIdMap.put(res.Id, res.RbA_User__c);
            }

            for (MA_Scheduler_Event__c maEvent : maEventsToCreate) {
                Id userId = resourceIdToUserIdMap.get(maEvent.Resource__c);
                if (userId != null) {
                    Id primaryResourceId = primaryResourceMap.get(maEvent.RbA_Work_Order__c);
                    Set<Id> assignedResourceIds = woToResIdsMap.get(maEvent.RbA_Work_Order__c);
                    MA_Scheduler_Event__c tempEvent = woToMaEventMap.get(maEvent.RbA_Work_Order__c);

                    Event sfEvent = new Event(
                        StartDateTime = maEvent.StartDateTime__c,
                        EndDateTime = maEvent.EndDateTime__c,
                        WhatId = maEvent.RbA_Work_Order__c,
                        MA_Scheduler_Event__c = maEvent.Id,
                        Subject = maEvent.Name,
                        OwnerId = userId,
                        RecordTypeId = woEventRecTypeId,
                        Type = tempEvent.RbA_Work_Order__r.Work_Order_Type__c,
                        Primary_Resource__c = maEvent.Resource__c == primaryResourceId || assignedResourceIds.size() == 1
                    );
                    sfEventsToCreate.add(sfEvent);
                }
            }
            insert sfEventsToCreate;
            delete maEventsToDelete.values();

            response.put('success', true);
        }
        catch(Exception ex) {
            Database.rollBack(sp);
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }

        return JSON.serialize(response);
    }
    
    webService static String getRecords(String dateString, String storeId, String workOrderType, String offsetPageMinutes) {
        try {
            if(String.isNotBlank(dateString) && String.isNotBlank(storeId) && String.isNotBlank(workOrderType) && workOrderType != '--None--') {
                Date dateToCheck = Date.valueOf(dateString);
	            DateTime dateTimeToCheck = (DateTime)dateToCheck;
            	configs = MA_SchedulerUtilities.retrieveAllStoreSettings(storeId, workOrderType);
	            String storeTimezone = (String)configs.get('storeTimezone');
				
				Integer offset = MA_SchedulerUtilities.determineTimezoneOffset(dateTimeToCheck, storeTimezone);
				Integer offsetMinutes = MA_SchedulerUtilities.determineOffsetMinutesFromTimezoneOffset(offset);

				if (String.isNotBlank(offsetPageMinutes)) {
					offsetMinutes += Integer.valueOf(offsetPageMinutes);
				}
				master.put('offsetResponseMinutes', offsetMinutes);

                setupDepots(storeId);
                Map<Id, Id> userIdToResourceIdMap = setupRoutes(dateToCheck, storeId, storeTimezone, workOrderType, new Set<Id>());
                setupOrders(dateToCheck, storeId, storeTimezone, workOrderType, userIdToResourceIdMap.values());
				setupBreaks(dateToCheck, storeTimezone, userIdToResourceIdMap);

                master.put('success', true);
                master.put('defaultdate', dateTimeToCheck.getTime());
            }
            else {
	            master.put('success', false);
	            master.put('error', 'You must select a date and work order type before proceeding');
            }
        }
        catch(Exception ex) {
            master.put('success', false);
            master.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }

        return JSON.serialize(master);
    }

    private static void setupDepots(String storeId) {
        try {
            Store_Configuration__c storeConfig = [SELECT Id, Name, Store__c, Store__r.ShippingLongitude, Store__r.ShippingLatitude
        											FROM Store_Configuration__c WHERE Id = :storeId LIMIT 1];

            Map<String, Object> depotObj = new Map<String, Object>();
            Map<String, Object> geometry = new Map<String, Object>();
            Map<String, Object> attributes = new Map<String, Object>();
            
            geometry.put('x', storeConfig.Store__r.ShippingLongitude);
            geometry.put('y', storeConfig.Store__r.ShippingLatitude);

            attributes.put('Name', '{"storeID":"' + storeConfig.Id + '"}');

            depotObj.put('attributes', attributes);
            depotObj.put('geometry', geometry);

            List<Object> features = new List<Object> {depotObj};
            master.put('depots', new Map<String, Object> { 'features' => features });
        }
        catch(Exception ex) {
            master.put('success', false);
            master.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }
    }
    
    private static Map<Id, Id> setupRoutes(Date dateToCheck, String storeId, String storeTimezone, String workOrderType, Set<Id> resourceIds) {
        Map<Id, Id> userIdToResourceIdMap = new Map<Id, Id>();
        try {
        	List<Resource__c> resourceList;
            List<Object> features = new List<Object>();
        	Map<Id, Map<String, Object>> resourceHours = new Map<Id, Map<String, Object>>();
        	Set<String> resourceTypes = MA_SchedulerUtilities.retrieveResourceTypeFromWorkOrderType(workOrderType);
            
            DateTime dateTimeToCheck = DateTime.newInstance(dateToCheck, Time.newInstance(0, 0, 0, 0));
            dateTimeToCheck = MA_SchedulerUtilities.convertTimezoneToTimezone(dateTimeToCheck, null, storeTimezone);
            String dayOfWeek = dateTimeToCheck.format('EEEE', storeTimezone);

        	if (configs != null) {
        		resourceHours = (Map<Id, Map<String, Object>>)configs.get('resourceHours');
        	}
            
            if (resourceIds != null && !resourceIds.isEmpty()) {
                resourceList = [SELECT Id, Name, RbA_User__c, Retail_Location__c,
                                    (SELECT Id, RbA_Skill__c FROM Resource_Skills__r)
                                    FROM Resource__c WHERE Id IN :resourceIds];
            }
            else {
                resourceList = [SELECT Id, Name, RbA_User__c, Retail_Location__c,
            						(SELECT Id, RbA_Skill__c FROM Resource_Skills__r)
            						FROM Resource__c WHERE Retail_Location__c = :storeId AND Active__c = true AND Resource_Type__c IN : resourceTypes];
            }

            for (Resource__c resource : resourceList) {
                Map<String, Object> attributes = new Map<String, Object>();
                Map<String, Object> resourceObj = new Map<String, Object>();
                Map<String, Object> resourceHoursMap = new Map<String, Object>();

                userIdToResourceIdMap.put(resource.RbA_User__c, resource.Id);
                attributes.put('Name', '{"resId":"' + resource.Id + '","userId":"' + resource.RbA_User__c + '"}');
                attributes.put('EndDepotName', '{"storeID":"' + resource.Retail_Location__c + '"}');

                if (resource.Resource_Skills__r != null && !resource.Resource_Skills__r.isEmpty()) {
                    Set<Id> skillIds = new Set<Id>();
                    for (Resource_Skill__c skill : resource.Resource_Skills__r) {
                        skillIds.add(skill.RbA_Skill__c);
                    }
                    attributes.put('SpecialtyNames', String.join(new List<Id>(skillIds), ' '));
                }
                else {
                    attributes.put('SpecialtyNames', '');
                }

                if (resourceHours.containsKey(resource.Id)) {
					resourceHoursMap = resourceHours.get(resource.Id);
				}
				else {
					MA_Scheduler_Settings__c storeSettings = (MA_Scheduler_Settings__c)configs.get('storeSettings');
					if (storeSettings != null) {
						Map<String, Object> storeSettingsMap = (Map<String, Object>)JSON.deserializeUntyped(storeSettings.Settings__c);
						resourceHoursMap = (Map<String, Object>)storeSettingsMap.get('storeHours');
					}
				}

		        if (resourceHoursMap.containsKey(dayOfWeek)) {
		            List<Object> daysHoursList = (List<Object>)resourceHoursMap.get(dayOfWeek);
		            Map<String, Object> dayHoursMap = (Map<String, Object>)daysHoursList[0];
		            DateTime resourceEndDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindowMilitary(dateToCheck, (String)dayHoursMap.get('end'), storeTimezone);
		            DateTime resourceStartDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindowMilitary(dateToCheck, (String)dayHoursMap.get('start'), storeTimezone);
                    Long milliDiff = resourceEndDateTime.getTime() - resourceStartDateTime.getTime();
                    Integer resourceDuration = (Integer)(milliDiff / 1000) / 60;

		            attributes.put('AssignmentRule', 1);
		            attributes.put('LatestStartTime', resourceEndDateTime.getTime());
		            attributes.put('EarliestStartTime', resourceStartDateTime.getTime());
                	attributes.put('MaxTotalTime', resourceDuration);
                
                    resourceObj.put('attributes', attributes);
                    features.add(resourceObj);

                    routeLastBreakEndMap.put(resource.Id, 0);
                    routeEndMap.put(resource.Id, resourceEndDateTime.getTime());
                    routeStartMap.put(resource.Id, resourceStartDateTime.getTime());
		        }
            }

            if (!resourceIds.isEmpty() && master.containsKey('routes') && ((Map<String, Object>)master.get('routes')).containsKey('features')) {
                Map<String, Object> routes = (Map<String, Object>)master.get('routes');
                features.addAll((List<Object>)routes.get('features'));
            }

            master.put('routes', new Map<String, Object> { 'features' => features });
        }
        catch(Exception ex) {
            master.put('success', false);
            master.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }

        return userIdToResourceIdMap;
    }

    private static void setupOrders(Date dateToCheck, String storeId, String storeTimezone, String workOrderType, List<Id> resourceIdsList) {
        try {
        	Set<Id> workOrderIds = new Set<Id>();
            Set<Id> extraResourceIds = new Set<Id>();
            List<Object> features = new List<Object>();
            Set<Id> resourceIds = new Set<Id>(resourceIdsList);
        	DateTime startDateTime = DateTime.newInstance(dateToCheck, Time.newInstance(0, 0, 0, 0));
        	startDateTime = MA_SchedulerUtilities.convertTimezoneToTimezone(startDateTime, null, storeTimezone);
        	DateTime endDateTime = startDateTime.addDays(1);
            
            Map<Id, MA_Scheduler_Event__c> maEventsMap = new Map<Id, MA_Scheduler_Event__c>([SELECT Id, Name, Event_Sequence__c, StartDateTime__c, EndDateTime__c, RbA_Work_Order__c, Resource__c, Resource__r.RbA_User__c
                                    				        									FROM MA_Scheduler_Event__c WHERE StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime
                                    				        									AND (RbA_Work_Order__r.Work_Order_Type__c = :workOrderType OR Resource__c IN :resourceIds)
                                                                                                AND RbA_Work_Order__c != null]);

            for (MA_Scheduler_Event__c maEvent : maEventsMap.values()) {
                if (maEvent.Resource__c != null && !resourceIds.contains(maEvent.Resource__c)) {
                    extraResourceIds.add(maEvent.Resource__c);
                }
            }

            if (!extraResourceIds.isEmpty()) {
                setupRoutes(dateToCheck, storeId, storeTimezone, workOrderType, extraResourceIds);

                maEventsMap.putAll(new Map<Id, MA_Scheduler_Event__c>([SELECT Id, Name, Event_Sequence__c, StartDateTime__c, EndDateTime__c, RbA_Work_Order__c, Resource__c, Resource__r.RbA_User__c
                                                                        FROM MA_Scheduler_Event__c WHERE StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime
                                                                        AND Resource__c IN :extraResourceIds AND Id NOT IN :maEventsMap.keySet() AND RbA_Work_Order__c != null]));
            }

            List<MA_Scheduler_Event__c> maEventsList = maEventsMap.values();

            for (MA_Scheduler_Event__c maEvent : maEventsList) {
				workOrderIds.add(maEvent.RbA_Work_Order__c);
			}

			Map<Id, RbA_Work_Order__c> workOrderList = new Map<Id, RbA_Work_Order__c>([SELECT Id, Name, Account__r.ShippingLongitude, Account__r.ShippingLatitude, Appointment_Duration__c, Work_Order_Type__c,
                                                                                        Contact__c, Contact__r.LastName, Contact__r.FirstName, City__c, State__c, Tech_Measure_Synced__c,
                                                                                        LSWP_Test_Results__c, Service_Request_Type__c, Total_Days__c,
																						(SELECT Id, RbA_Skill__c FROM Work_Order_Required_Skills__r)
																						FROM RbA_Work_Order__c WHERE Id IN :workOrderIds]);
                
            for (MA_Scheduler_Event__c maEvent : maEventsList) {
                Map<String, Object> orderObj = new Map<String, Object>();
                Map<String, Object> geometry =  new Map<String, Object>();
                Map<String, Object> attributes = new Map<String, Object>();
            	RbA_Work_Order__c workOrder = workOrderList.get(maEvent.RbA_Work_Order__c);
                String multiDayOrder = maEvent.Event_Sequence__c != null && workOrder.Total_Days__c > 1 ? ' ' + maEvent.Event_Sequence__c + (workOrder.Total_Days__c != null ? ' of ' + workOrder.Total_Days__c : '') : '';

                geometry.put('x', workOrder.Account__r.ShippingLongitude);
                geometry.put('y',  workOrder.Account__r.ShippingLatitude);

                attributes.put('Name', '{"woId":"' + workOrder.Id + '","maEventId":"' + maEvent.Id
                                            + '","woName":"' + workOrder.Name + '","woType":"' + workOrder.Work_Order_Type__c.toLowerCase().deleteWhitespace()
                                            + '","city":"' + workOrder.City__c + '","state":"' + workOrder.State__c
                                            + '","contactName":"' + workOrder.Contact__r.LastName + ', ' + workOrder.Contact__r.FirstName
                                            + '","isSynced":' + workOrder.Tech_Measure_Synced__c + ',"isLswp":' + workOrder.LSWP_Test_Results__c
                                            + ',"isJip":' + workOrder.Service_Request_Type__c + ',"multiDayOrder":"' + multiDayOrder + '"}');
				attributes.put('AssignmentRule', 3);
                attributes.put('CurbApproach', 3);
                    
                endDateTime = maEvent.EndDateTime__c;
                startDateTime = maEvent.StartDateTime__c;

                Long milliDiff = endDateTime.getTime() - startDateTime.getTime();
                Integer serviceTime = (Integer)(milliDiff / 1000) / 60;

                attributes.put('ServiceTime', serviceTime);
                attributes.put('TimeWindowEnd1', endDateTime.getTime());
                attributes.put('TimeWindowStart1', startDateTime.getTime());
	            attributes.put('MaxViolationTime1', 0);

                if (workOrder.Work_Order_Required_Skills__r != null && !workOrder.Work_Order_Required_Skills__r.isEmpty()) {
                    Set<Id> skillIds = new Set<Id>();
                    for (Work_Order_Required_Skill__c woSkill : workOrder.Work_Order_Required_Skills__r) {
                        skillIds.add(woSkill.RbA_Skill__c);
                    }
                    attributes.put('SpecialtyNames', String.join(new List<Id>(skillIds), ' '));
                }
                else {
                	attributes.put('SpecialtyNames', '');
                }
                
                if (maEvent.Resource__c != null) {
                    attributes.put('RouteName', '{"resId":"' + maEvent.Resource__c + '","userId":"' + maEvent.Resource__r.RbA_User__c + '"}');
                }
                else {
                    attributes.put('RouteName', null);
                }
                
                orderObj.put('attributes', attributes);
                orderObj.put('geometry', geometry);
                features.add(orderObj); 
            }
            
            master.put('orders', new Map<String, Object> { 'features' => features });
        }
        catch(Exception ex) {
            master.put('success', false);
            master.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }
    }

    private static void setupBreaks(Date dateToCheck, String storeTimezone, Map<Id, Id> userIdToResourceIdMap) {
        try {
            List<Object> features = new List<Object>();
            List<EsriBreak> esriBreaksList = new List<EsriBreak>();
            DateTime startDateTime = DateTime.newInstance(dateToCheck, Time.newInstance(0, 0, 0, 0));
            startDateTime = MA_SchedulerUtilities.convertTimezoneToTimezone(startDateTime, null, storeTimezone);
            DateTime endDateTime = startDateTime.addDays(1);

            List<Event> sfEventList = [SELECT Id, OwnerId, StartDateTime, EndDateTime, DurationInMinutes
                                        FROM Event WHERE OwnerId IN :userIdToResourceIdMap.keySet()
                                        AND StartDateTime < :endDateTime AND EndDateTime > :startDateTime AND MA_Scheduler_Event__c = null
                                        ORDER BY StartDateTime ASC];

            for (Event sfEvent : sfEventList) {
                esriBreaksList.add(new EsriBreak(sfEvent));
            }

            List<MA_Scheduler_Event__c> maEventList = [SELECT Id, Resource__c, Resource__r.RbA_User__c, StartDateTime__c, EndDateTime__c
                                                        FROM MA_Scheduler_Event__c WHERE Resource__c IN :userIdToResourceIdMap.values()
                                                        AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime AND RbA_Work_Order__c = null
                                                        ORDER BY StartDateTime__c ASC];
            
            for (MA_Scheduler_Event__c maEvent : maEventList) {
                esriBreaksList.add(new EsriBreak(maEvent));
            }
            
            Integer i = 1;
            for (EsriBreak eBrake : esriBreaksList) {
                Map<String, Object> breakObj = new Map<String, Object>();
                Map<String, Object> attributes = new Map<String, Object>();

                Id resourceId = eBrake.resourceId;
                if (String.isBlank(resourceId)) {
                    resourceId = userIdToResourceIdMap.get(eBrake.userId);
                }

                Long routeLastBreakEnd = routeLastBreakEndMap.get(resourceId);
                Long earliestStart = routeStartMap.get(resourceId);
                Long latestEnd = routeEndMap.get(resourceId);
                Long startEpoch = eBrake.startEpoch;
                Long endEpoch = eBrake.endEpoch;
                endEpoch = endEpoch <= latestEnd ? endEpoch : latestEnd;

                if (routeLastBreakEnd < endEpoch && startEpoch < latestEnd && endEpoch > earliestStart) {
                    startEpoch = startEpoch >= earliestStart ? startEpoch : earliestStart;
                    startEpoch = startEpoch > routeLastBreakEnd ? startEpoch : routeLastBreakEnd + 1;

                    attributes.put('RouteName', '{"resId":"' + resourceId + '","userId":"' + eBrake.userId + '"}');
                    attributes.put('TimeWindowEnd', startEpoch);
                    attributes.put('TimeWindowStart', startEpoch);
                    attributes.put('Precedence', i);
                    attributes.put('MaxViolationTime', 0);

                    Long milliDiff = endEpoch - startEpoch;
                    Integer serviceTime = (Integer)(milliDiff / 1000) / 60;
                    attributes.put('ServiceTime', serviceTime);

                    breakObj.put('attributes', attributes);
                    features.add(breakObj);
                    i++;

                    routeLastBreakEndMap.put(resourceId, endEpoch);
                }
            }

            master.put('breaks', new Map<String, Object> { 'features' => features }); 
        }
        catch(Exception ex) {
            master.put('success', false);
            master.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }
    }

    private class EsriBreak {

        private Id userId;
        private Id resourceId;
        private Long endEpoch;
        private Long startEpoch;

        private EsriBreak(Event sfEvent) {
            userId = sfEvent.OwnerId;
            endEpoch = sfEvent.EndDateTime.getTime();
            startEpoch = sfEvent.StartDateTime.getTime();
        }

        private EsriBreak(MA_Scheduler_Event__c maEvent) {
            resourceId = maEvent.Resource__c;
            userId = maEvent.Resource__r.RbA_User__c;
            endEpoch = maEvent.EndDateTime__c.getTime();
            startEpoch = maEvent.StartDateTime__c.getTime();
        }
    }

}
/************************************************************************************/
/*                                                                                  */
/*      This class holds the methods used during the normal flow of the scheduler   */
/*      Most of them are webservices to allow for asynchronous computation          */
/*                                                                                  */
/*      @author     Daniel Taylor   (MapAnything)                                   */
/*                  Ethan Rush      (MapAnything)                                   */
/*                                                                                  */
/*      @version    6/29/2016   MapAnything                                         */
/*      Created                                                                     */
/*                                                                                  */
/*      @copyright (c)2016 MapAnything. All Rights Reserved.                        */
/*      Unauthorized use is prohibited                                              */
/*                                                                                  */
/************************************************************************************/

global with sharing class MA_SchedulerController {

    public static Map<Integer, String> dayNumMap = new Map<Integer, String> {
        0 => 'Sunday',
        1 => 'Monday',
        2 => 'Tuesday',
        3 => 'Wednesday',
        4 => 'Thursday',
        5 => 'Friday',
        6 => 'Saturday'
    };

    public RbA_Work_Order__c tempWo {get;set;}

    /****************************************************/
    /*                                                  */
    /*      Initializes a temp work order in order      */
    /*          to utilize its picklist fields          */
    /*                                                  */
    /****************************************************/
    global MA_SchedulerController() {
        try {
            Id visitRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'RbA_Work_Order__c' AND DeveloperName = 'Visit'].Id;
            tempWo = new RbA_Work_Order__c(RecordTypeId = visitRecordTypeId);
        }
        catch(Exception e) {
            tempWo = new RbA_Work_Order__c();
        }
    }

    /****************************************************/
    /*                                                  */
    /*      webservice used to query records            */
    /*      filters are passed in                       */
    /*                                                  */
    /****************************************************/
    webService static String retrieveRecords(String objType, String filters, String workOrderType) {
        Map<String, Object> response = new Map<String, Object>();
        
        try {
            String query;
            List<SObject> objList = new List<SObject>();
            
            if (objType == 'Scheduler') {
                Id currentUserId = UserInfo.getUserId();
                query = 'SELECT Id, Resource_Type__c, Retail_Location__c, Retail_Location__r.Name'
                        + ' FROM Resource__c WHERE Active__c = TRUE AND RbA_User__c = :currentUserId ORDER BY Retail_Location__r.Name ASC';
            }
            else if (objType == 'Resource') {
                query = 'SELECT Id, Name, Active__c, Resource_Type__c, Retail_Location__c, Retail_Location__r.Name, RbA_User__c, Crew_Size__c FROM Resource__c';
            }
            else if (objType == 'MASettings') {
                query = 'SELECT Id, Store_Id__c, Resource_Id__c, Settings__c FROM MA_Scheduler_Settings__c';
            }
            else if (objType == 'WorkOrder') {
                query = 'SELECT Id, Account__c, Name, Contact__c, Contact__r.FirstName, Contact__r.LastName, Contact__r.HomePhone, Contact__r.MobilePhone, Contact__r.Phone, Appointment_Duration__c,'
                        + ' Street__c, City__c, State__c, Zip__c, Estimated_Ship_Date__c, Work_Order_Type__c, Cancel_Reason__c, Reschedule_Reason__c,'
                        + ' Appointment_Date__c, Reschedule_Date__c, Cancel_Date__c, Sold_Order__r.Original_Crew__c, Sold_Order__r.Original_Stainer__c, Sold_Order__r.Original_Tech_Measure__c,'
                        + ' (SELECT Id FROM Assigned_Resources__r)'
                        + ' FROM RbA_Work_Order__c';
            }
            
            if (String.isNotBlank(query)) {
                query += String.isNotBlank(filters) ? ' WHERE ' + filters : '';

                if (objType == 'Resource') {
                    objList.add(new Resource__c(Name = 'Unassigned', Active__c = true));

                    if (String.isNotBlank(workOrderType)) { 
                        Set<String> resourceTypes = MA_SchedulerUtilities.retrieveResourceTypeFromWorkOrderType(workOrderType);
                        query += ' AND Resource_Type__c IN (\'' + String.join(new List<String>(resourceTypes), '\', \'') + '\')';
                    }
                    else {
                        query += ' AND Resource_Type__c != \'Scheduler\'';
                    }
                }

                objList.addAll(Database.query(query));
            }

            response.put('success', true);
            response.put('objList', objList);
        }
        catch(Exception ex) {
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }
        
        return JSON.serialize(response);
    }

    /********************************************************/
    /*                                                      */
    /*      webservice used to query a store's settings     */
    /*                                                      */
    /********************************************************/
    webService static String retrieveSettings(Id storeId) {
        Map<String, Object> response = new Map<String, Object>();
        
        try {
            Set<Id> validProfileIds = new Set<Id>();
            Set<String> validProfileNames = new Set<String> { 'System Administrator', 'Sys Admin' };
            Map<String, Object> maSettingsMap = MA_SchedulerUtilities.retrieveAllStoreSettings(storeId, null);
            List<Resource__c> resourceList = [SELECT Id, Name, Resource_Type__c FROM Resource__c WHERE Retail_Location__c = :storeId AND Resource_Type__c != 'Scheduler' ORDER BY Resource_Type__c ASC, Name ASC];

            for (Profile profile : [SELECT Id FROM Profile WHERE Name IN :validProfileNames]) {
                validProfileIds.add(profile.Id);
            }

            response.put('success', true);
            response.put('resourceList', resourceList);
            response.put('showEsriCredentials', validProfileIds.contains(UserInfo.getProfileId()));
            response.put('storeSettings', (MA_Scheduler_Settings__c)maSettingsMap.get('storeSettings'));
            response.put('resourceSettingsMap', (Map<Id, MA_Scheduler_Settings__c>)maSettingsMap.get('resourceSettingsMap'));
        }
        catch(Exception ex) {
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }
        
        return JSON.serialize(response);
    }

    /********************************************************/
    /*                                                      */
    /*      webservice used to get correct timezone         */
    /*      options used in the settings tab                */
    /*                                                      */
    /********************************************************/
    webService static String retrieveTimezoneOptions() {
        Map<String, Object> response = new Map<String, Object>();
        
        try {
            Map<String, String> timezoneOptions = new Map<String, String>();
            List<Schema.PicklistEntry> timezonePicklistOptions = Schema.User.TimeZoneSidKey.getDescribe().getPicklistValues();
            for (Schema.PicklistEntry pe : timezonePicklistOptions) {
                timezoneOptions.put(pe.getValue(), pe.getLabel());
            }

            response.put('success', true);
            response.put('timezoneOptions', timezoneOptions);
        }
        catch(Exception ex) {
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }
        
        return JSON.serialize(response);
    }

    /********************************************************/
    /*                                                      */
    /*      webservice used to query the events             */
    /*      to display on the calendar                      */
    /*                                                      */
    /********************************************************/
    webService static String retrieveEvents(String objType, String filters, String altFilters, String resourceUserIdToIdMapString, String storeId) {
        Map<String, Object> response = new Map<String, Object>();
        
        try {
            String query;
            String altQuery;
            Set<Id> additionalAltFilterIds = new Set<Id>();
            List<MA_SchedulerEvent> eventList = new List<MA_SchedulerEvent>();

            String storeTimezone = MA_SchedulerUtilities.retrieveStoreTimezone(storeId);
            Map<Id, Id> resourceUserIdToIdMap = (Map<Id, Id>)JSON.deserialize(resourceUserIdToIdMapString, Map<Id, Id>.class);
        
            if (objType == 'allEvents') {
                query = 'SELECT Id, Name, Resource__c, Resource__r.Name, RbA_Work_Order__c, StartDateTime__c, EndDateTime__c, Estimated_Start_Date_Time__c, Estimated_End_Date_Time__c, RbA_Work_Order__r.State__c,'
                            + ' RbA_Work_Order__r.Work_Order_Type__c, RbA_Work_Order__r.Contact__c, RbA_Work_Order__r.Contact__r.FirstName, RbA_Work_Order__r.Contact__r.LastName, RbA_Work_Order__r.City__c,'
                            + ' RbA_Work_Order__r.Windows__c, RbA_Work_Order__r.Tech_Measure_Synced__c, RbA_Work_Order__r.LSWP_Test_Results__c, RbA_Work_Order__r.Service_Request_Type__c, RbA_Work_Order__r.Total_Days__c, Event_Sequence__c'
                            + ' FROM MA_Scheduler_Event__c';

                altQuery = 'SELECT Id, Subject, OwnerId, WhatId, StartDateTime, EndDateTime FROM Event';
            }
            else if (objType == 'WorkOrder') {
                query = 'SELECT Id, Name, Resource__c, Resource__r.Name, RbA_Work_Order__c, StartDateTime__c, EndDateTime__c, Estimated_Start_Date_Time__c, Estimated_End_Date_Time__c, RbA_Work_Order__r.State__c,'
                            + ' RbA_Work_Order__r.Work_Order_Type__c, RbA_Work_Order__r.Contact__c, RbA_Work_Order__r.Contact__r.FirstName, RbA_Work_Order__r.Contact__r.LastName, RbA_Work_Order__r.City__c,'
                            + ' RbA_Work_Order__r.Windows__c, RbA_Work_Order__r.Tech_Measure_Synced__c, RbA_Work_Order__r.LSWP_Test_Results__c, RbA_Work_Order__r.Service_Request_Type__c, RbA_Work_Order__r.Total_Days__c, Event_Sequence__c'
                            + ' FROM MA_Scheduler_Event__c';
            }
            
            if (String.isNotBlank(query)) {
                query += String.isNotBlank(filters) ? ' WHERE ' + filters : '';
                List<SObject> objList = Database.query(query);
                Map<String, MA_SchedulerEvent> tempMaEventsMap = new Map<String, MA_SchedulerEvent>();

                for (SObject obj : objList) {
                    MA_SchedulerEvent customEvent = new MA_SchedulerEvent(obj, new Map<Id, Id>(), true);
                    customEvent.createOffsetTimes(storeTimezone);

                    if (objType == 'WorkOrder') {
                        String mapKey = customEvent.workOrderId + ':' + customEvent.startDateTime.format();

                        if (!tempMaEventsMap.containsKey(mapKey)) {
                            tempMaEventsMap.put(mapKey, customEvent);
                        }
                        else if (String.isNotBlank(customEvent.resourceId)) {
                            MA_SchedulerEvent tempEvent = tempMaEventsMap.get(mapKey);

                            if (String.isNotBlank(tempEvent.resourceId)) {
                                tempEvent.addResource(((MA_Scheduler_Event__c)obj).Resource__r.Name);
                                tempMaEventsMap.put(mapKey, tempEvent);
                            }
                            else {
                                tempMaEventsMap.put(mapKey, customEvent);
                            }
                        }
                    }
                    else {
                        eventList.add(customEvent);
                    }

                    if (objType == 'allEvents') {
                        additionalAltFilterIds.add(obj.Id);
                    }
                }

                if (!tempMaEventsMap.isEmpty()) {
                    eventList.addAll(tempMaEventsMap.values());
                }
            }
            
            if (String.isNotBlank(altQuery)) {
                if (!additionalAltFilterIds.isEmpty()) {
                    altFilters += (String.isNotBlank(altFilters) ? ' AND' : '') + ' MA_Scheduler_Event__c NOT IN :additionalAltFilterIds';
                }

                altQuery += String.isNotBlank(altFilters) ? ' WHERE ' + altFilters : '';
                List<SObject> objList = Database.query(altQuery);

                for (SObject obj : objList) {
                    MA_SchedulerEvent customEvent = new MA_SchedulerEvent(obj, resourceUserIdToIdMap, true);
                    customEvent.createOffsetTimes(storeTimezone);
                    eventList.add(customEvent);
                }
            }

            response.put('success', true);
            response.put('eventList', eventList);
        }
        catch(Exception ex) {
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }
        
        return JSON.serialize(response);
    }

    /********************************************************/
    /*                                                      */
    /*      webservice used to get the holidays             */
    /*      to display on the calendar                      */
    /*                                                      */
    /********************************************************/
    webService static String retrieveHolidays(String storeId) {
        Map<String, Object> response = new Map<String, Object>();
        
        try {
            List<MA_SchedulerEvent> holidays = new List<MA_SchedulerEvent>();
            Map<String, Object> maSettingsMap = MA_SchedulerUtilities.retrieveAllStoreSettings(storeId, null);
            List<Object> storeHolidays = (List<Object>)maSettingsMap.get('storeHolidays');

            for (Object obj : storeHolidays) {
                MA_SchedulerEvent customEvent = new MA_SchedulerEvent(obj, 'storeHoliday');
                customEvent.createOffsetTimes(null);
                holidays.add(customEvent);
            }

            response.put('success', true);
            response.put('showEvents', true);
            response.put('eventList', holidays);
        }
        catch(Exception ex) {
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }
        
        return JSON.serialize(response);
    }

    /********************************************************/
    /*                                                      */
    /*      webservice used to query the related            */
    /*      accounts that need geocoding                    */
    /*                                                      */
    /********************************************************/
    webservice static String retrieveNonGeocodedAddresses(String appointmentDateString, String storeId, String workOrderType, String resourceId) {
        Map<String, Object> response = new Map<String, Object>();

        try {
            Set<Id> accIds = new Set<Id>();
            Date appointmentDate = Date.valueOf(appointmentDateString);

            String geoCodeQryStr = 'SELECT Id, RbA_Work_Order__r.Account__c FROM MA_Scheduler_Event__c'
                                    + ' WHERE (RbA_Work_Order__r.Account__r.Store_Location__r.Active_Store_Configuration__c = \'' + String.escapeSingleQuotes(storeId) + '\'';

            if (String.isNotBlank(workOrderType)) {
                geoCodeQryStr += ' AND (RbA_Work_Order__r.Work_Order_Type__c = \'' + String.escapeSingleQuotes(workOrderType) + '\''
                                + ' OR RbA_Work_Order__r.Scheduled_As_Type__c = \'' + String.escapeSingleQuotes(workOrderType) + '\')';
            }

            geoCodeQryStr += ' AND (DAY_ONLY(StartDateTime__c) = ' + String.escapeSingleQuotes(appointmentDateString) + ' OR DAY_ONLY(EndDateTime__c) = ' + String.escapeSingleQuotes(appointmentDateString) + '))';
            
            if (String.isNotBlank(resourceId)) {
                geoCodeQryStr += ' OR Resource__c = \'' + String.escapeSingleQuotes(resourceId) + '\'';
            }

            List<MA_Scheduler_Event__c> maEvents = Database.query(geoCodeQryStr);

            for (MA_Scheduler_Event__c maEvent : maEvents) {
                accIds.add(maEvent.RbA_Work_Order__r.Account__c);
            }

            List<Account> accList = [SELECT Id, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
                                        FROM Account WHERE (ShippingLatitude = null OR ShippingLongitude = null) AND (Active_Store_Configuration__c = :storeId OR Id IN :accIds)];

            response.put('success', true);
            response.put('accList', accList);
        }
        catch(Exception ex) {
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }

        return JSON.serialize(response);
    }

    /********************************************************/
    /*                                                      */
    /*      webservice used to update the related           */
    /*      accounts that were geocoded with the            */
    /*      correct latitude and longitude                  */
    /*                                                      */
    /********************************************************/
    webservice static String updateGeocodedAddresses(String geocodedAddressesString) {
        System.Savepoint sp = Database.setSavepoint();
        Map<String, Object> response = new Map<String, Object>();

        try {
            if (String.isNotBlank(geocodedAddressesString)) {
                List<SObject> objList = new List<SObject>();
                List<Object> geocodedAddresses = (List<Object>)JSON.deserializeUntyped(geocodedAddressesString);

                for(Object obj : geocodedAddresses) {
                    Map<String, Object> geocodeObj = (Map<String, Object>)obj;
                    Id objectId = (String)geocodeObj.get('Id');
                    Schema.SObjectType objectType = objectId.getSobjectType();
                    SObject objToUpdate = objectType.newSObject(objectId);

                    //Hard coded account values
                    objToUpdate.put('ShippingLatitude', (Decimal)geocodeObj.get('lat'));
                    objToUpdate.put('ShippingLongitude', (Decimal)geocodeObj.get('lng'));
                    objList.add(objToUpdate);
                }
                update objList;
            }

            response.put('success', true);
        }
        catch(Exception ex) {
            Database.rollBack(sp);
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }

        return JSON.serialize(response);
    }

    /********************************************************/
    /*                                                      */
    /*      webservice used to save a store's settings      */
    /*                                                      */
    /********************************************************/
    webService static String saveSettings(String jsonSettings, Boolean closeModal) {
        System.Savepoint sp = Database.setSavepoint();
        Map<String, Object> response = new Map<String, Object>();

        try {
            List<MA_Scheduler_Settings__c> settings = (List<MA_Scheduler_Settings__c>)JSON.deserialize(jsonSettings, List<MA_Scheduler_Settings__c>.class);

            if (settings != null && !settings.isEmpty()) {
                upsert settings;

                Id storeId = settings[0].Store_Id__c;
                Set<Id> settingsIds = (new Map<Id, MA_Scheduler_Settings__c>(settings)).keySet();
                delete [SELECT Id FROM MA_Scheduler_Settings__c WHERE Store_Id__c = :storeId AND Id NOT IN :settingsIds];
            }

            response.put('success', true);
            response.put('closeModal', closeModal);
        }
        catch(Exception ex) {
            Database.rollBack(sp);
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }

        return JSON.serialize(response);
    }

    /********************************************************/
    /*                                                      */
    /*      webservice used to create an event for          */
    /*      a resource from the calendar                    */
    /*                                                      */
    /********************************************************/
    webService static String createResourceEvent(String saveType, Id eventId, Id storeId, Id resourceId, String subject, String dateString, String startTime, String endTime) {
        System.Savepoint sp = Database.setSavepoint();
        Map<String, Object> response = new Map<String, Object>();

        try {
            Date day = Date.parse(dateString);
            String storeTimezone = MA_SchedulerUtilities.retrieveStoreTimezone(storeId);
            DateTime endDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(day, endTime, storeTimezone);
            DateTime startDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(day, startTime, storeTimezone);

            if (saveType == 'save') {
                MA_Scheduler_Event__c maEvent = new MA_Scheduler_Event__c(
                    Date__c = day,
                    Resource__c = resourceId,
                    EndDateTime__c = endDateTime,
                    StartDateTime__c = startDateTime,
                    Name = String.isBlank(subject) ? 'Busy' : subject
                );

                if (String.isNotBlank(eventId)) {
                    maEvent.Id = eventId;
                }

                upsert maEvent;
            }
            else {
                delete [SELECT Id FROM MA_Scheduler_Event__c WHERE Id = :eventId];
            }

            response.put('success', true);
        }
        catch(Exception ex) {
            Database.rollBack(sp);
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }

        return JSON.serialize(response);
    }

    /********************************************************/
    /*                                                      */
    /*      webservice used to get a resources events       */
    /*      to display on the calendar on the resource      */
    /*      route tab                                       */
    /*                                                      */
    /********************************************************/
    webservice static String retrieveResourceRouteRecords(Id resourceId, String startEpoch, String endEpoch, Id storeId) {
        Map<String, Object> response = new Map<String, Object>();

        try {
            Set<Id> maEventIds = new Set<Id>();
            DateTime endDateTime = DateTime.newInstance(Long.valueOf(endEpoch));
            List<MA_SchedulerEvent> customEvents = new List<MA_SchedulerEvent>();
            DateTime startDateTime = DateTime.newInstance(Long.valueOf(startEpoch));
            String storeTimezone = MA_SchedulerUtilities.retrieveStoreTimezone(storeId);

            Resource__c resource = [SELECT Id, RbA_User__c FROM Resource__c WHERE Id = :resourceId];
            Id userId = resource.RbA_User__c;
            Map<Id, Id> resourceUserIdToIdMap = new Map<Id, Id> { userId => resourceId };
            
            if (String.isNotBlank(storeTimezone)) {
                startDateTime = MA_SchedulerUtilities.convertGmtToTimezone(startDateTime, storeTimezone, null);
                endDateTime = MA_SchedulerUtilities.convertGmtToTimezone(endDateTime, storeTimezone, null);
            }

            List<MA_Scheduler_Event__c> maEventList = [SELECT Id, Name, Resource__c, Resource__r.Name, RbA_Work_Order__c, StartDateTime__c, EndDateTime__c, Estimated_Start_Date_Time__c, Estimated_End_Date_Time__c, RbA_Work_Order__r.State__c,
                                                        RbA_Work_Order__r.Work_Order_Type__c, RbA_Work_Order__r.Contact__c, RbA_Work_Order__r.Contact__r.FirstName, RbA_Work_Order__r.Contact__r.LastName, RbA_Work_Order__r.City__c,
                                                        RbA_Work_Order__r.Windows__c, RbA_Work_Order__r.Tech_Measure_Synced__c, RbA_Work_Order__r.LSWP_Test_Results__c, RbA_Work_Order__r.Service_Request_Type__c, RbA_Work_Order__r.Total_Days__c, Event_Sequence__c
                                                        FROM MA_Scheduler_Event__c WHERE Resource__c = :resourceId AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime]; 
            
            for (MA_Scheduler_Event__c maEvent : maEventList) {
                maEventIds.add(maEvent.Id);

                MA_SchedulerEvent customEvent = new MA_SchedulerEvent(maEvent, new Map<Id, Id>(), true);
                customEvent.createOffsetTimes(storeTimezone);
                customEvents.add(customEvent);
            }

            List<Event> sfEventList = [SELECT Id, Subject, OwnerId, WhatId, StartDateTime, EndDateTime FROM Event WHERE OwnerId = :userId AND StartDateTime < :endDateTime AND EndDateTime > :startDateTime AND MA_Scheduler_Event__c NOT IN :maEventIds];
            for (Event sfEvent : sfEventList) {
                MA_SchedulerEvent customEvent = new MA_SchedulerEvent(sfEvent, resourceUserIdToIdMap, true);
                customEvent.createOffsetTimes(storeTimezone);
                customEvents.add(customEvent);
            }

            response.put('success', true);
            response.put('customEvents', customEvents);
        }
        catch(Exception ex) {
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }

        return JSON.serialize(response);
    }

    /********************************************************************/
    /*                                                                  */
    /*      webservice used to get the available resources              */
    /*                                                                  */
    /*      used with the MA_SchedulerAssignResourceComp component      */
    /*                                                                  */
    /********************************************************************/
    webService static String retrieveAvailableResources(Id workOrderId, String assignForDay, String woToResIdsString) {
        Map<String, Object> response = new Map<String, Object>();
        
        try {
            if (String.isNotBlank(woToResIdsString)) {
                woToResIdsString = woToResIdsString.remove('"Unassigned"');
            }

            Id primaryResourceId;
            Date eventSchedulerDate;
            Set<Id> assignedResources = new Set<Id>();
            Boolean isSingleDay = String.isNotBlank(assignForDay);
            Map<Id, String> requiredSkills = new Map<Id, String>();
            Map<Id, Id> availableResourceIdToUserIdMap = new Map<Id, Id>();
            Set<Id> woToResIds = (Set<Id>)JSON.deserialize(woToResIdsString, Set<Id>.class);
            Map<Id, MA_SchedulerResource> availableResources = new Map<Id, MA_SchedulerResource>();
            Map<Id, MA_SchedulerResource> unAvailableResources = new Map<Id, MA_SchedulerResource>();

            if (isSingleDay) {
                eventSchedulerDate = Date.parse(assignForDay);
            }

            RbA_Work_Order__c workOrder = [SELECT Id, Name, Work_Order_Type__c, Appointment_Duration__c, Appointment_Date__c,
                                            Appointment_Start_Time__c, Appointment_End_Time__c, Recommended_Crew_Size__c,
                                            Street__c, City__c, State__c, Zip__c, Contact__c, Contact__r.Name,
                                            Account__r.Store_Location__r.Active_Store_Configuration__c,
                                            Contact__r.HomePhone, Contact__r.MobilePhone, Contact__r.Phone,
                                            Sold_Order__r.Original_Crew__c, Sold_Order__r.Original_Stainer__c, Sold_Order__r.Original_Tech_Measure__c,
                                            (SELECT Id, StartDateTime__c, EndDateTime__c, Resource__c FROM MA_Scheduler_Events__r WHERE Date__c = :eventSchedulerDate),
                                            (SELECT Id, Scheduled_Resource__c, Scheduled_Resource__r.Name, IsPrimary__c FROM Assigned_Resources__r),
                                            (SELECT Id, RbA_Skill__r.Name FROM Work_Order_Required_Skills__r)
                                            FROM RbA_Work_Order__c WHERE Id = :workOrderId];

            Id storeId = workOrder.Account__r.Store_Location__r.Active_Store_Configuration__c;
            Map<String, Object> maSettingsMap = MA_SchedulerUtilities.retrieveAllStoreSettings(storeId, workOrder.Work_Order_Type__c);

            String storeTimezone = (String)maSettingsMap.get('storeTimezone');
            Map<String, Object> storeBookingWindows = (Map<String, Object>)maSettingsMap.get('storeBookingWindows');
            Map<Id, Map<String, Object>> resourceHours = (Map<Id, Map<String, Object>>)maSettingsMap.get('resourceHours');

            Id visitRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'RbA_Work_Order__c' AND DeveloperName = 'Visit'].Id;

            /************************************************/
            /*                                              */
            /*      get all the assigned resources          */
            /*      and temporarilly set the work orders    */
            /*      fields if processing for a single day   */
            /*                                              */
            /************************************************/
            if (isSingleDay && !workOrder.MA_Scheduler_Events__r.isEmpty()) {
                for (MA_Scheduler_Event__c maEvent : workOrder.MA_Scheduler_Events__r) {
                    assignedResources.add(maEvent.Resource__c);
                }

                MA_Scheduler_Event__c maEvent = workOrder.MA_Scheduler_Events__r[0];
                workOrder.Appointment_Date__c = eventSchedulerDate;
                workOrder.Appointment_End_Time__c = maEvent.EndDateTime__c.format('hh:mm a', storeTimezone);
                workOrder.Appointment_Start_Time__c = maEvent.StartDateTime__c.format('hh:mm a', storeTimezone);

                Long milliDiff = maEvent.EndDateTime__c.getTime() - maEvent.StartDateTime__c.getTime();
                Decimal hoursDiff = ((Decimal)(milliDiff / 1000)) / 60 / 60;
                workOrder.Appointment_Duration__c = hoursDiff.setScale(1);
                workOrder.Appointment_End_Time__c = null;
            }
            else if (!isSingleDay) {
                for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                    assignedResources.add(resource.Scheduled_Resource__c);

                    if (resource.IsPrimary__c) {
                        primaryResourceId = resource.Scheduled_Resource__c;
                    }
                }
            }

            assignedResources.addAll(woToResIds);

            /************************************************/
            /*                                              */
            /*      get all the resources that were         */
            /*      previously assigned or have matching    */
            /*      skills                                  */
            /*                                              */
            /************************************************/
            for (Work_Order_Required_Skill__c skill : workOrder.Work_Order_Required_Skills__r) {
                requiredSkills.put(skill.RbA_Skill__c, skill.RbA_Skill__r.Name);
            }

            for (Resource__c resource : [SELECT Id, Name, Active__c, RbA_User__c, Crew_Size__c, Rank__c, Resource_Type__c,
                                            (SELECT Id, RbA_Skill__r.Name FROM Resource_Skills__r WHERE RbA_Skill__c IN :requiredSkills.keySet() AND Active__c = true)
                                            FROM Resource__c WHERE (Active__c = true AND Retail_Location__c = :storeId)
                                            OR Id IN :assignedResources]) {

                if (!resource.Resource_Skills__r.isEmpty() || assignedResources.contains(resource.Id)) {
                    if (resource.RbA_User__c != null) {
                        availableResourceIdToUserIdMap.put(resource.Id, resource.RbA_User__c);
                    }
                    availableResources.put(resource.Id, new MA_SchedulerResource(resource, requiredSkills, assignedResources));
                }
            }

            /************************************************/
            /*                                              */
            /*    determine which resources are available   */
            /*      for the entirety of the work order      */
            /*      all days must be concurrent             */
            /*      ther can be no gap between days         */
            /*                                              */
            /************************************************/
            if (workOrder.Appointment_Date__c != null && String.isNotBlank(workOrder.Appointment_Start_Time__c) 
                    && (String.isNotBlank(workOrder.Appointment_End_Time__c) || workOrder.Appointment_Duration__c != null)) {

                Set<Id> maEventIdsAlreadyChecked = new Set<Id>();
                Set<Id> resourceHoursKeySet = resourceHours.keySet();
                Set<Id> availableResourcesKeySet = availableResources.keySet();
                resourceHoursKeySet.retainAll(availableResourcesKeySet);

                /***********************************************************/
                /*                                                         */
                /*      determine the end date for the work order          */
                /*      if the work order last longer than a day           */
                /*      we will process one day at a time                  */
                /*      and use the current days end time                  */
                /*                                                         */
                /***********************************************************/
                DateTime endDateTime;
                Integer totalMinutes = workOrder.Appointment_Duration__c == null ? 0 : (Integer)(workOrder.Appointment_Duration__c * 60);
                Map<String, Map<String, Object>> latestHours = MA_SchedulerUtilities.determineEarliestStartAndLatestEndHours(storeBookingWindows);
                DateTime startDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_Start_Time__c, storeTimezone);

                DateTime tempStart = startDateTime;
                Integer tempTotalMinutes = totalMinutes;
                DateTime tempEnd = tempStart.addMinutes(tempTotalMinutes);

                if (totalMinutes == 0 && String.isNotBlank(workOrder.Appointment_End_Time__c)) {
                    endDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_End_Time__c, storeTimezone);
                }
                else {
                    endDateTime = startDateTime.addMinutes(totalMinutes);
                }

                /***********************************************************/
                /*                                                         */
                /*      if we could determine the start and end            */
                /*      times for a day verify that a resource is          */
                /*      available to work all days from start of day       */
                /*      till the end of day or the end of the work order   */
                /*                                                         */
                /***********************************************************/
                if (latestHours != null && !latestHours.isEmpty()) {
                    Date tempStartDate = Date.parse(tempStart.format('MM/dd/yyyy', storeTimezone));
                    Date startOfWeek = tempStartDate.toStartOfWeek();
                    Integer daysBetweenStartOfWeek = startOfWeek.daysBetween(tempStartDate);

                    do {
                        String dayOfWeek = dayNumMap.get(Math.mod(daysBetweenStartOfWeek, 7));
                        Map<String, Object> daysHours = latestHours.get(dayOfWeek);

                        if (daysHours != null) {
                            if (tempStartDate != Date.parse(tempStart.format('MM/dd/yyyy', storeTimezone))) {
                                tempStart = DateTime.newInstanceGmt(tempStartDate, (Time)daysHours.get('start'));
                                tempStart = MA_SchedulerUtilities.convertGmtToTimezone(tempStart, storeTimezone, null);
                                tempEnd = tempStart.addMinutes(tempTotalMinutes);
                            }

                            DateTime daysEndDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)(daysHours.get('end')));
                            daysEndDateTime = MA_SchedulerUtilities.convertGmtToTimezone(daysEndDateTime, storeTimezone, null);
                            
                            if (tempEnd > daysEndDateTime) {
                                tempEnd = daysEndDateTime;
                            }

                            Long totalMillisecondDifference = tempEnd.getTime() - tempStart.getTime();
                            tempTotalMinutes -= (Integer)(totalMillisecondDifference / 1000 / 60);

                            availableResourcesKeySet = availableResources.keySet();
                            resourceHoursKeySet.retainAll(availableResourcesKeySet);

                            for (Id resourceId : resourceHoursKeySet) {
                                Boolean resourceIsWorking = MA_SchedulerUtilities.determineIfResourceWorksSelectedHours(resourceHours, dayOfWeek, resourceId, storeTimezone, tempStart, tempEnd);
                                if (!resourceIsWorking) {
                                    availableResourceIdToUserIdMap.remove(resourceId);
                                    unAvailableResources.put(resourceId, availableResources.remove(resourceId));
                                }
                            }
                        }
                        else {
                            unAvailableResources.putAll(availableResources);
                            availableResources.clear();
                            availableResourceIdToUserIdMap.clear();
                        }

                        tempStartDate = tempStartDate.addDays(1);
                        daysBetweenStartOfWeek += 1;
                    }
                    while (tempTotalMinutes > 0);

                    endDateTime = tempEnd;
                }
                /***********************************************************/
                /*                                                         */
                /*      otherwise determine if resource is available       */
                /*      to work the entire work order with no break        */
                /*                                                         */
                /***********************************************************/
                else {
                    Date tempStartDate = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone));
                    Date startOfWeek = tempStartDate.toStartOfWeek();
                    Integer daysBetweenStartOfWeek = startOfWeek.daysBetween(tempStartDate);
                    String dayOfWeek = dayNumMap.get(daysBetweenStartOfWeek);

                    for (Id resourceId : resourceHoursKeySet) {
                        Boolean resourceIsWorking = MA_SchedulerUtilities.determineIfResourceWorksSelectedHours(resourceHours, dayOfWeek, resourceId, storeTimezone, startDateTime, endDateTime);
                        if (!resourceIsWorking) {
                            availableResourceIdToUserIdMap.remove(resourceId);
                            unAvailableResources.put(resourceId, availableResources.remove(resourceId));
                        }
                    }
                }

                /***********************************************************/
                /*                                                         */
                /*      remove resources that already have events          */
                /*      scheduled between the start and end dates          */
                /*                                                         */
                /***********************************************************/
                for (MA_Scheduler_Event__c maEvent : [SELECT Resource__c FROM MA_Scheduler_Event__c WHERE Resource__c IN :availableResources.keySet() AND RbA_Work_Order__c != :workOrderId AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime]) {
                    maEventIdsAlreadyChecked.add(maEvent.Id);
                    MA_SchedulerResource resource = availableResources.get(maEvent.Resource__c);
                    if (resource != null) {
                        if (resource.isAssigned) {
                            resource.isAvailable = false;
                        }
                        else {
                            availableResourceIdToUserIdMap.remove(maEvent.Resource__c);
                            unAvailableResources.put(maEvent.Resource__c, availableResources.remove(maEvent.Resource__c));
                        }
                    }
                }

                Set<Id> availableUserIds = new Set<Id>(availableResourceIdToUserIdMap.values());
                for (Event sfEvent : [SELECT OwnerId FROM Event WHERE OwnerId IN :availableUserIds AND MA_Scheduler_Event__c NOT IN :maEventIdsAlreadyChecked AND StartDateTime < :endDateTime AND EndDateTime > :startDateTime]) {
                    availableUserIds.remove(sfEvent.OwnerId);
                }

                for (Id resourceId : availableResourceIdToUserIdMap.keySet()) {
                    Id userId = availableResourceIdToUserIdMap.get(resourceId);
                    if (!availableUserIds.contains(userId)) {
                        MA_SchedulerResource resource = availableResources.get(resourceId);
                        if (resource != null) {
                            if (resource.isAssigned) {
                                resource.isAvailable = false;
                            }
                            else {
                                availableResourceIdToUserIdMap.remove(resourceId);
                                unAvailableResources.put(resourceId, availableResources.remove(resourceId));
                            }
                        }
                    }
                }
            }

            String endDay = '';
            String startDay = '';
            DateTime currentEndTime;
            DateTime currentStartTime;

            for (MA_Scheduler_Event__c maEvent : [SELECT Id, StartDateTime__c, EndDateTime__c, Date__c FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId ORDER BY StartDateTime__c ASC, EndDateTime__c DESC]) {
                if (!isSingleDay || (isSingleDay && maEvent.Date__c == eventSchedulerDate)) {
                    if (currentEndTime == null || currentEndTime < maEvent.EndDateTime__c) {
                        currentEndTime = maEvent.EndDateTime__c;
                        workOrder.Appointment_End_Time__c = maEvent.EndDateTime__c.format('hh:mm a', storeTimezone);
                        endDay = maEvent.EndDateTime__c.format('MM/dd/yyyy', storeTimezone);

                    }

                    if (currentStartTime == null || currentStartTime > maEvent.StartDateTime__c) {
                        currentStartTime = maEvent.StartDateTime__c;
                        workOrder.Appointment_Start_Time__c = maEvent.StartDateTime__c.format('hh:mm a', storeTimezone);
                        startDay = maEvent.StartDateTime__c.format('MM/dd/yyyy', storeTimezone);
                    }
                }
            }

            if (isSingleDay || startDay == endDay) {
                endDay = '';
                startDay = '';
            }

            List<MA_SchedulerResource> availableResourcesList = availableResources.values();
            availableResourcesList.sort();

            List<MA_SchedulerResource> unAvailableResourcesList = unAvailableResources.values();
            unAvailableResourcesList.sort();

            response.put('success', true);
            response.put('endDay', endDay);
            response.put('startDay', startDay);
            response.put('workOrder', workOrder);
            response.put('isSingleDay', isSingleDay);
            response.put('primaryResourceId', primaryResourceId);
            response.put('availableResources', availableResourcesList);
            response.put('unAvailableResources', unAvailableResourcesList);
        }
        catch(Exception ex) {
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }
        
        return JSON.serialize(response);
    }

    /********************************************************************/
    /*                                                                  */
    /*      webservice used to determine available booking windows      */
    /*                                                                  */
    /*      used with the MA_SchedulerWorkOrderSchedulingComp component */
    /*                                                                  */
    /********************************************************************/
    webService static String checkAvailability(Id workOrderId, String startDateTimeEpoch, String endDateTimeEpoch, String offsetPageMinutes, Boolean nextAvailable, String altType) {
        Map<String, Object> response = new Map<String, Object>();

        try {
            RbA_Work_Order__c workOrder = [SELECT Id, Windows__c, Work_Order_Type__c, Appointment_Duration__c, Account__r.Store_Location__r.Active_Store_Configuration__c,
                                            (SELECT Id, RbA_Skill__c FROM Work_Order_Required_Skills__r),
                                            (SELECT Id, Scheduled_Resource__c FROM Assigned_Resources__r) /*,
                                            (SELECT Id, Event_Sequence__c, Resource__c FROM MA_Scheduler_Events__r) */
                                            FROM RbA_Work_Order__c WHERE Id = :workOrderId];

            if (String.isNotBlank(altType)) {
                workOrder.Work_Order_Type__c = altType;
            }

            Set<Id> rbaSkillIds = new Set<Id>();
            Map<Id, Id> userMap = new Map<Id, Id>();
            Set<String> badSlots = new Set<String>();
            //Set<Id> maEventResourceIds = new Set<Id>();
            Set<Id> assignedResourceIds = new Set<Id>();
            Set<Integer> badIndexes = new Set<Integer>();
            Map<Id, Set<Id>> resourceToSkillsMap = new Map<Id, Set<Id>>();
            Map<Id, Integer> totalSkillsCountMap = new Map<Id, Integer>();
            //Map<Integer, Set<Id>> singleDayResourceMap = new Map<Integer, Set<Id>>();
            Id storeId = workOrder.Account__r.Store_Location__r.Active_Store_Configuration__c;
            List<MA_SchedulerBookingWindow> bookingWindows = new List<MA_SchedulerBookingWindow>();
            List<MA_SchedulerBookingWindow> unAvailableSlots = new List<MA_SchedulerBookingWindow>();
            Set<String> resourceTypes = MA_SchedulerUtilities.retrieveResourceTypeFromWorkOrderType(workOrder.Work_Order_Type__c);
            Integer totalMinutes = workOrder.Appointment_Duration__c == null ? 0 : (Integer)(workOrder.Appointment_Duration__c * 60);
            Map<String, Object> maSettingsMap = MA_SchedulerUtilities.retrieveAllStoreSettings(storeId, workOrder.Work_Order_Type__c);
            Map<String, Map<String, MA_SchedulerBookingWindow>> bookingWindowsRemainingMap = new Map<String, Map<String, MA_SchedulerBookingWindow>>();
            //Map<String, Map<String, MA_SchedulerBookingWindow>> bookingWindowsEventSequenceMap = new Map<String, Map<String, MA_SchedulerBookingWindow>>();

            String storeTimezone = (String)maSettingsMap.get('storeTimezone');
            List<Object> storeHolidays = (List<Object>)maSettingsMap.get('storeHolidays');
            Map<String, Object> storeBookingWindows = (Map<String, Object>)maSettingsMap.get('storeBookingWindows');
            Map<Id, Map<String, Object>> resourceHours = (Map<Id, Map<String, Object>>)maSettingsMap.get('resourceHours');

            if (storeBookingWindows == null || storeBookingWindows.isEmpty()) {
                response.put('success', false);
                response.put('error', 'The store hours and/or ' + workOrder.Work_Order_Type__c + ' booking windows have not been configured yet.  Please go to the settings page to set these up.');
                return JSON.serialize(response);
            }

            Map<String, Map<String, Object>> latestHours = MA_SchedulerUtilities.determineEarliestStartAndLatestEndHours(storeBookingWindows);
            Map<String, Set<String>> allConfiguredWindows = MA_SchedulerUtilities.determineAllConfiguredHours(storeBookingWindows);
            Set<String> storeHolidayDates = MA_SchedulerUtilities.determineStoreHolidays(storeHolidays);

            DateTime endDateTime = DateTime.newInstance(Long.valueOf(endDateTimeEpoch)).addDays(7);
            endDateTime = MA_SchedulerUtilities.convertGmtToTimezone(endDateTime, storeTimezone, offsetPageMinutes);
            Date endDate = Date.parse(endDateTime.format('MM/dd/yyyy', storeTimezone));

            DateTime startDateTime = DateTime.newInstance(Long.valueOf(startDateTimeEpoch)).addDays(-7);
            startDateTime = MA_SchedulerUtilities.convertGmtToTimezone(startDateTime, storeTimezone, offsetPageMinutes);
            Date startDate = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone));

            /****************************************************************************/
            /*                                                                          */
            /*      get all resources with matching skills or previously assigned,      */
            /*      determine resource to skills match, create booking windows,         */
            /*      and check resources availability                                    */
            /*                                                                          */
            /****************************************************************************/
            for (Work_Order_Required_Skill__c rbaSkill : workOrder.Work_Order_Required_Skills__r) {
                rbaSkillIds.add(rbaSkill.RbA_Skill__c);
            }

            for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                assignedResourceIds.add(resource.Scheduled_Resource__c);
            }

            /*
            for (MA_Scheduler_Event__c maEvent : workOrder.MA_Scheduler_Events__r) {
                Integer eventSequence = Integer.valueOf(maEvent.Event_Sequence__c);
                if (eventSequence == null || eventSequence == 0) {
                    eventSequence = 1;
                }

                if (!singleDayResourceMap.containsKey(eventSequence)) {
                    singleDayResourceMap.put(eventSequence, new Set<Id>());
                }

                if (maEvent.Resource__c != null) {
                    singleDayResourceMap.get(eventSequence).add(maEvent.Resource__c);
                    maEventResourceIds.add(maEvent.Resource__c);
                }
            }

            response.put('assignedResourceIds', assignedResourceIds);
            response.put('singleDayResourceMap', singleDayResourceMap);
            */

            List<Resource__c> resourceList = [SELECT Id, RbA_User__c,
                                                (SELECT Id, RbA_Skill__c FROM Resource_Skills__r WHERE RbA_Skill__c IN :rbaSkillIds AND Active__c = true)
                                                FROM Resource__c WHERE (Active__c = true AND Retail_Location__c = :storeId AND Resource_Type__c IN :resourceTypes) OR Id IN :assignedResourceIds /*OR Id IN :maEventResourceIds*/];

            for (Resource__c resource : resourceList) {
                if (!resource.Resource_Skills__r.isEmpty()) {
                    if (resource.RbA_User__c != null) {
                        userMap.put(resource.RbA_User__c, resource.Id);
                    }
                    resourceToSkillsMap.put(resource.Id, new Set<Id>());

                    for (Resource_Skill__c skill : resource.Resource_Skills__r) {
                        resourceToSkillsMap.get(resource.Id).add(skill.RbA_Skill__c);

                        if (!totalSkillsCountMap.containsKey(skill.RbA_Skill__c)) {
                            totalSkillsCountMap.put(skill.RbA_Skill__c, 1);
                        }
                        else {
                            Integer tempInt = totalSkillsCountMap.get(skill.RbA_Skill__c);
                            tempInt++;
                            totalSkillsCountMap.put(skill.RbA_Skill__c, tempInt);
                        }
                    }
                }
            }

            MA_SchedulerUtilities.createBookingWindows(bookingWindows, unAvailableSlots, storeBookingWindows, resourceToSkillsMap, totalSkillsCountMap, startDateTime, endDateTime, storeTimezone, storeHolidayDates, resourceHours);
            MA_SchedulerUtilities.checkResourceAvailability(bookingWindows, unAvailableSlots, userMap, startDateTime, endDateTime, resourceToSkillsMap, workOrder.Work_Order_Type__c, rbaSkillIds, storeId);
            
            /*
            for (MA_SchedulerBookingWindow unAvailableBw : unAvailableSlots) {
                if (unAvailableBw.overbooked *//*&& !unAvailableBw.timeBlocksMissingASkill.isEmpty()*//* && unAvailableBw.skillsTimeAvailabilityMap.keySet().size() > unAvailableBw.timeBlocksMissingASkill.size()) {
                    bookingWindowsRemainingMap.put(unAvailableBw.dayOfWeek + ' - ' + unAvailableBw.windowStart + ' - ' + unAvailableBw.windowEnd, unAvailableBw);
                }
            }
            */

            /**********************************************************/
            /*                                                        */
            /*    remove booking windows with no available resources  */
            /*                                                        */
            /**********************************************************/
            if (!assignedResourceIds.isEmpty() /*&& singleDayResourceMap.size() <= 1*/) {
                for (Integer i = 0, index = bookingWindows.size() - 1; index >= i; index--) {
                    MA_SchedulerBookingWindow bw = bookingWindows[index];

                    if (!bw.resourceToSkillsMap.keySet().containsAll(assignedResourceIds)) {
                        unAvailableSlots.add(bookingWindows[index]);
                        bookingWindows.remove(index);
                    }
                }
            }

            /****************************************************/
            /*                                                  */
            /*    create a map of remaining available windows   */
            /*                                                  */
            /****************************************************/
            Map<String, Set<String>> remainingSlots = new Map<String, Set<String>>();
            for (Integer i = 0, index = bookingWindows.size() - 1; index >= i; index--) {
                MA_SchedulerBookingWindow bw = bookingWindows[index];
                bw.determineSkillsMatched();

                if (bw.skillsMatched.size() < workOrder.Work_Order_Required_Skills__r.size()) {
                    unAvailableSlots.add(bookingWindows[index]);
                    bookingWindows.remove(index);
                }
                else {
                    String bookingWindowStartTime = bw.startDateTime.format('MM/dd/yyyy', storeTimezone);

                    if (!remainingSlots.containsKey(bookingWindowStartTime)) {
                        remainingSlots.put(bookingWindowStartTime, new Set<String>());
                    }
                    remainingSlots.get(bookingWindowStartTime).add(bw.dayOfWeek + ' - ' + bw.windowStart + ' - ' + bw.windowEnd);
                
                    /**/
                    if (!bw.timeBlocksMissingASkill.isEmpty()) {
                        if (!bookingWindowsRemainingMap.containsKey(bookingWindowStartTime)) {
                            bookingWindowsRemainingMap.put(bookingWindowStartTime, new Map<String, MA_SchedulerBookingWindow>());
                        }
                        bookingWindowsRemainingMap.get(bookingWindowStartTime).put(bw.dayOfWeek + ' - ' + bw.windowStart + ' - ' + bw.windowEnd, bw);
                    }
                    /**/

                    /*
                    if (singleDayResourceMap.size() > 1) {
                        if (!bookingWindowsEventSequenceMap.containsKey(bookingWindowStartTime)) {
                            bookingWindowsEventSequenceMap.put(bookingWindowStartTime, new Map<String, MA_SchedulerBookingWindow>());
                        }
                        bookingWindowsEventSequenceMap.get(bookingWindowStartTime).put(bw.dayOfWeek + ' - ' + bw.windowStart + ' - ' + bw.windowEnd, bw);
                    }
                    */
                }
            }

            /**/
            for (MA_SchedulerBookingWindow unAvailableBw : unAvailableSlots) {
                if (unAvailableBw.overbooked /**//*&& !unAvailableBw.timeBlocksMissingASkill.isEmpty() *//**/ && unAvailableBw.skillsTimeAvailabilityMap.keySet().size() > unAvailableBw.timeBlocksMissingASkill.size()) {
                    //bookingWindowsRemainingMap.put(unAvailableBw.dayOfWeek + ' - ' + unAvailableBw.windowStart + ' - ' + unAvailableBw.windowEnd, unAvailableBw);
                    String bookingWindowStartTime = unAvailableBw.startDateTime.format('MM/dd/yyyy', storeTimezone);

                    if (!bookingWindowsRemainingMap.containsKey(bookingWindowStartTime)) {
                        bookingWindowsRemainingMap.put(bookingWindowStartTime, new Map<String, MA_SchedulerBookingWindow>());
                    }
                    bookingWindowsRemainingMap.get(bookingWindowStartTime).put(unAvailableBw.dayOfWeek + ' - ' + unAvailableBw.windowStart + ' - ' + unAvailableBw.windowEnd, unAvailableBw);

                    /*
                    if (singleDayResourceMap.size() > 1) {
                        if (!bookingWindowsEventSequenceMap.containsKey(bookingWindowStartTime)) {
                            bookingWindowsEventSequenceMap.put(bookingWindowStartTime, new Map<String, MA_SchedulerBookingWindow>());
                        }
                        bookingWindowsEventSequenceMap.get(bookingWindowStartTime).put(unAvailableBw.dayOfWeek + ' - ' + unAvailableBw.windowStart + ' - ' + unAvailableBw.windowEnd, unAvailableBw);
                    }
                    */
                }
            }
            /**/

            /*
            response.put('remainingSlots', remainingSlots);
            response.put('allConfiguredWindows', allConfiguredWindows);
            response.put('bookingWindowsEventSequenceMap', bookingWindowsEventSequenceMap);
            response.put('latestHours', latestHours);
            */

            /***********************************************************/
            /*                                                         */
            /*      if we could determine the start and end            */
            /*      times for a day verify that all windows are        */
            /*      available to work all days from start of day       */
            /*      till the end of day or the end of the work order   */
            /*                                                         */
            /***********************************************************/
            if (latestHours != null && !latestHours.isEmpty()) {

                //response.put('bookingWindows1', bookingWindows.clone());

                //List<Map<String, Map<String, Object>>> debuggingMapList = new List<Map<String, Map<String, Object>>>();

                for (Integer i = 0, len = bookingWindows.size(); i < len; i++) {
                    MA_SchedulerBookingWindow bw = bookingWindows[i];
                    DateTime tempStart = bw.startDateTime;
                    Integer tempTotalMinutes = totalMinutes;
                    DateTime tempEnd = tempStart.addMinutes(tempTotalMinutes);
                    Date tempStartDate = Date.parse(tempStart.format('MM/dd/yyyy', storeTimezone));
                    Date startOfWeek = tempStartDate.toStartOfWeek();
                    Integer daysBetweenStartOfWeek = startOfWeek.daysBetween(tempStartDate);

                    /*
                    Integer workOrderEventSequence = 0;

                    Map<String, Map<String, Object>> debuggingMap = new Map<String, Map<String, Object>>();
                    Map<String, Object> innerDebuggingMap = new Map<String, Object>();
                    */

                    do {
                        //workOrderEventSequence++;
                        String dayOfWeek = dayNumMap.get(Math.mod(daysBetweenStartOfWeek, 7));
                        Map<String, Object> daysHours = latestHours.get(dayOfWeek);

                        Set<Id> assignedResourcesForDay = new Set<Id>();    //assignedResourceIds;

                        if (daysHours != null) {
                            if (tempStartDate != Date.parse(tempStart.format('MM/dd/yyyy', storeTimezone))) {
                                tempStart = DateTime.newInstanceGmt(tempStartDate, (Time)daysHours.get('start'));
                                tempStart = MA_SchedulerUtilities.convertGmtToTimezone(tempStart, storeTimezone, null);
                                tempEnd = tempStart.addMinutes(tempTotalMinutes);
                            }

                            DateTime daysEndDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)(daysHours.get('end')));
                            daysEndDateTime = MA_SchedulerUtilities.convertGmtToTimezone(daysEndDateTime, storeTimezone, null);
                        
                            if (tempEnd > daysEndDateTime) {
                                tempEnd = daysEndDateTime;
                            }

                            Long totalMillisecondDifference = tempEnd.getTime() - tempStart.getTime();
                            tempTotalMinutes -= (Integer)(totalMillisecondDifference / 1000 / 60);
                            Set<String> windowsSpannedToCheck = allConfiguredWindows.get(dayOfWeek);

                            Set<String> remainingSlotsSetForDay = new Set<String>();
                            if (remainingSlots.get(tempStart.format('MM/dd/yyyy', storeTimezone)) != null) {
                                remainingSlotsSetForDay = remainingSlots.get(tempStart.format('MM/dd/yyyy', storeTimezone)).clone();
                            }

                            /*
                            System.debug(tempStart.format('MM/dd/yyyy', storeTimezone));
                            System.debug(workOrderEventSequence);
                            System.debug(remainingSlotsSetForDay);
                            *//*

                            //debuggingMap.put('date', tempStart.format('MM/dd/yyyy', storeTimezone));
                            innerDebuggingMap.put('workOrderEventSequence', workOrderEventSequence);
                            innerDebuggingMap.put('remainingSlotsSetForDay', remainingSlotsSetForDay);

                            if (!bookingWindowsEventSequenceMap.isEmpty() && bookingWindowsEventSequenceMap.containsKey(tempStart.format('MM/dd/yyyy', storeTimezone))) {
                                Map<String, MA_SchedulerBookingWindow> bookingWindowsEventSequenceMapForDay = bookingWindowsEventSequenceMap.get(tempStart.format('MM/dd/yyyy', storeTimezone));

                                if (!singleDayResourceMap.containsKey(workOrderEventSequence) || singleDayResourceMap.get(workOrderEventSequence).isEmpty()) {
                                    singleDayResourceMap.put(workOrderEventSequence, new Set<Id>(assignedResourceIds));
                                }

                                assignedResourcesForDay = singleDayResourceMap.get(workOrderEventSequence);
                                
                                //System.debug(assignedResourcesForDay);

                                innerDebuggingMap.put('assignedResourcesForDay', assignedResourcesForDay);

                                List<String> remainingSlotsSetForDayList = new List<String>(remainingSlotsSetForDay);

                                for (Integer x = 0, index = remainingSlotsSetForDayList.size() - 1; index >= x; index--) {
                                    String mapKey = remainingSlotsSetForDayList[index];

                                    if (bookingWindowsEventSequenceMapForDay.containsKey(mapKey)) {
                                        MA_SchedulerBookingWindow bwTemp = bookingWindowsEventSequenceMapForDay.get(mapKey);

                                        if (bwTemp.overbooked || !bwTemp.resourceToSkillsMap.keySet().containsAll(assignedResourcesForDay)) {
                                            remainingSlotsSetForDay.remove(mapKey);
                                        }
                                    }
                                }
                            }
                            else if (singleDayResourceMap.size() > 1) {
                                remainingSlotsSetForDay.clear();
                            }
                            */

                            /*
                            System.debug(remainingSlotsSetForDay);
                            System.debug('************************************************');
                            */

                            //innerDebuggingMap.put('remainingSlotsSetForDay', remainingSlotsSetForDay);

                            if (remainingSlotsSetForDay == null) {
                                badIndexes.add(i);
                                tempTotalMinutes = 0;
                            }
                            else if (tempTotalMinutes > 0) {
                                if (!remainingSlotsSetForDay.containsAll(windowsSpannedToCheck)) {
                                    badIndexes.add(i);
                                    tempTotalMinutes = 0;
                                }

                                if (tempStart == bw.startDateTime) {
                                    List<String> tempList = new List<String>(windowsSpannedToCheck);
                                    String slotName = dayOfWeek + ' - ' + tempStart + ' - ';

                                    for (Integer x = tempList.size() - 1; x >= 0; x--) {
                                        String windowSpan = tempList[x];
                                        Integer indexOfEndTime = windowSpan.lastIndexOf(' - ');
                                        windowSpan = windowSpan.substring(0, indexOfEndTime);

                                        if (windowSpan >= slotName) {
                                            badSlots.add(tempList[x]);
                                        }
                                    }
                                }
                            }
                            else if (!remainingSlotsSetForDay.containsAll(windowsSpannedToCheck)) {
                                Set<String> badWindowsSpannedToCheckSet = new Set<String>(windowsSpannedToCheck);
                                badWindowsSpannedToCheckSet.removeAll(remainingSlotsSetForDay);
                                List<String> badRemainingList = new List<String>(badWindowsSpannedToCheckSet);

                                for (Integer x = 0, remainingLen = badRemainingList.size(); x < remainingLen; x++) {
                                    /*
                                    List<String> badRemainingSplit = badRemainingList[x].split(' - ');
                                    List<String> badRemainingStartTimeSplit = badRemainingSplit[1].split(':');
                                    List<String> badStartTimeSplit = tempStart.format('HH:mm', storeTimezone).split(':');
                                    Time badStartTime = Time.newInstance(Integer.valueOf(badStartTimeSplit[0]), Integer.valueOf(badStartTimeSplit[1]), 0, 0);
                                    Time badStartTimeRemaining = Time.newInstance(Integer.valueOf(badRemainingStartTimeSplit[0]), Integer.valueOf(badRemainingStartTimeSplit[1]), 0, 0);

                                    List<String> badRemainingEndTimeSplit = badRemainingSplit[2].split(':');
                                    List<String> badEndTimeSplit = tempEnd.format('HH:mm', storeTimezone).split(':');
                                    Time badEndTime = Time.newInstance(Integer.valueOf(badEndTimeSplit[0]), Integer.valueOf(badEndTimeSplit[1]), 0, 0);
                                    Time badEndTimeRemaining = Time.newInstance(Integer.valueOf(badRemainingEndTimeSplit[0]), Integer.valueOf(badRemainingEndTimeSplit[1]), 0, 0);

                                    if (badStartTimeRemaining < badEndTime && badEndTimeRemaining > badStartTime) {
                                        badIndexes.add(i);
                                        tempTotalMinutes = 0;
                                    }
                                    */

                                    String badRemainingKey = badRemainingList[x];
                                    List<String> badStartTimeSplit = tempStart.format('HH:mm', storeTimezone).split(':');
                                    Time badStartTime = Time.newInstance(Integer.valueOf(badStartTimeSplit[0]), Integer.valueOf(badStartTimeSplit[1]), 0, 0);
                                    
                                    List<String> badEndTimeSplit = tempEnd.format('HH:mm', storeTimezone).split(':');
                                    Time badEndTime = Time.newInstance(Integer.valueOf(badEndTimeSplit[0]), Integer.valueOf(badEndTimeSplit[1]), 0, 0);

                                    if (bookingWindowsRemainingMap.containsKey(tempStart.format('MM/dd/yyyy', storeTimezone)) && bookingWindowsRemainingMap.get(tempStart.format('MM/dd/yyyy', storeTimezone)).containsKey(badRemainingKey)) {

                                        MA_SchedulerBookingWindow bwTemp = bookingWindowsRemainingMap.get(tempStart.format('MM/dd/yyyy', storeTimezone)).get(badRemainingKey);
                                        Set<DateTime> badSubTimes = bwTemp.timeBlocksMissingASkill;

                                        for (DateTime badSubTime : badSubTimes) {
                                            List<String> badRemainingStartTimeSplit = badSubTime.format('HH:mm', storeTimezone).split(':');
                                            Time badStartTimeRemaining = Time.newInstance(Integer.valueOf(badRemainingStartTimeSplit[0]), Integer.valueOf(badRemainingStartTimeSplit[1]), 0, 0);

                                            List<String> badRemainingEndTimeSplit = badSubTime.addMinutes(30).format('HH:mm', storeTimezone).split(':');
                                            Time badEndTimeRemaining = Time.newInstance(Integer.valueOf(badRemainingEndTimeSplit[0]), Integer.valueOf(badRemainingEndTimeSplit[1]), 0, 0);

                                            if (badStartTimeRemaining < badEndTime && badEndTimeRemaining > badStartTime) {
                                                badIndexes.add(i);
                                                tempTotalMinutes = 0;
                                                break;
                                            }
                                        }

                                        if (!badIndexes.contains(i)) {
                                            Set<Id> availableResourceIds = assignedResourcesForDay.isEmpty() ? bwTemp.originalResourceToSkillsMap.keySet().clone() : assignedResourcesForDay.clone();
                                            Set<DateTime> avaialableSubTimes = bwTemp.skillsTimeAvailabilityMap.keySet().clone();
                                            avaialableSubTimes.removeAll(bwTemp.timeBlocksMissingASkill);

                                            for (DateTime avaialableSubTime : avaialableSubTimes) {
                                                List<String> avaialableStartTimeSplit = avaialableSubTime.format('HH:mm', storeTimezone).split(':');
                                                Time avaialableStartTimeRemaining = Time.newInstance(Integer.valueOf(avaialableStartTimeSplit[0]), Integer.valueOf(avaialableStartTimeSplit[1]), 0, 0);

                                                List<String> avaialableEndTimeSplit = avaialableSubTime.addMinutes(30).format('HH:mm', storeTimezone).split(':');
                                                Time avaialableEndTimeRemaining = Time.newInstance(Integer.valueOf(avaialableEndTimeSplit[0]), Integer.valueOf(avaialableEndTimeSplit[1]), 0, 0);

                                                if ((avaialableStartTimeRemaining < badEndTime && avaialableEndTimeRemaining > badStartTime) 
                                                        && (avaialableStartTimeRemaining < badStartTime || avaialableEndTimeRemaining > badEndTime)) {
                                                    availableResourceIds.retainAll(bwTemp.resourceTimeAvailabilityMap.get(avaialableSubTime));
                                                }
                                            }

                                            if (availableResourceIds.isEmpty()) {
                                                badIndexes.add(i);
                                                tempTotalMinutes = 0;
                                            }
                                        }
                                    }
                                    else {
                                        List<String> badRemainingSplit = badRemainingList[x].split(' - ');
                                        List<String> badRemainingStartTimeSplit = badRemainingSplit[1].split(':');
                                        Time badStartTimeRemaining = Time.newInstance(Integer.valueOf(badRemainingStartTimeSplit[0]), Integer.valueOf(badRemainingStartTimeSplit[1]), 0, 0);

                                        List<String> badRemainingEndTimeSplit = badRemainingSplit[2].split(':');
                                        Time badEndTimeRemaining = Time.newInstance(Integer.valueOf(badRemainingEndTimeSplit[0]), Integer.valueOf(badRemainingEndTimeSplit[1]), 0, 0);

                                        if (badStartTimeRemaining < badEndTime && badEndTimeRemaining > badStartTime) {
                                            badIndexes.add(i);
                                            tempTotalMinutes = 0;
                                        }
                                    }
                                }
                            }
                        }
                        else {
                            badIndexes.add(i);
                            tempTotalMinutes = 0;
                        }

                        tempStartDate = tempStartDate.addDays(1);
                        daysBetweenStartOfWeek += 1;

                        //debuggingMap.put(tempStart.format('MM/dd/yyyy', storeTimezone), innerDebuggingMap);
                    }
                    while (tempTotalMinutes > 0);

                    //debuggingMapList.add(debuggingMap);
                }

                //response.put('debuggingMapList', debuggingMapList);
            }

            /****************************************************/
            /*                                                  */
            /*    remove any windows that are outside of        */
            /*      selected dates or determined to be          */
            /*      unavailable above                           */
            /*                                                  */
            /****************************************************/
            endDateTime = endDateTime.addDays(-7);
            startDateTime = startDateTime.addDays(7);

            /*
            if (startDateTime.format('HH:mm') == endDateTime.format('HH:mm')) {
                if ((String.isBlank(storeTimezone) && startDateTime.format('HH:mm') == '00:00') || (String.isNotBlank(storeTimezone) && startDateTime.format('HH:mm', storeTimezone) == '00:00')) {
                    endDateTime = endDateTime.addDays(1);
                }
                else {
                    endDateTime = endDateTime.addMinutes(30);
                }
            }
            */

            endDateTime = endDateTime.addDays(1);

            for (Integer i = 0, index = bookingWindows.size() - 1; index >= i; index--) {
                MA_SchedulerBookingWindow bw = bookingWindows[index];
                String slotName = bw.dayOfWeek + ' - ' + bw.windowStart + ' - ' + bw.windowEnd;

                if (badSlots.contains(slotName) || badIndexes.contains(index) || bw.startDateTime >= endDateTime || bw.endDateTime <= startDateTime) {
                    if (!(bw.startDateTime >= endDateTime || bw.endDateTime <= startDateTime)) {
                        unAvailableSlots.add(bookingWindows[index]);
                    }
                    bookingWindows.remove(index);
                }
            }

            for (Integer i = 0, index = unAvailableSlots.size() - 1; index >= i; index--) {
                MA_SchedulerBookingWindow bw = unAvailableSlots[index];
                if (bw.startDateTime >= endDateTime || bw.endDateTime <= startDateTime) {
                    unAvailableSlots.remove(index);
                }
            }
            
            /****************************************************************/
            /*                                                              */
            /*    only return first 5 windows if checking next available    */
            /*                                                              */
            /****************************************************************/
            if (nextAvailable && bookingWindows.size() > 5) {
                bookingWindows = new List<MA_SchedulerBookingWindow> {
                    bookingWindows[0],
                    bookingWindows[1],
                    bookingWindows[2],
                    bookingWindows[3],
                    bookingWindows[4]
                };
            }

            /********************************************************************/
            /*                                                                  */
            /*    determine the number of available slots per booking window    */
            /*                                                                  */
            /********************************************************************/
            for (Integer i = 0, len = bookingWindows.size(); i < len; i++) {
                MA_SchedulerBookingWindow bw = bookingWindows[i];
                Set<Id> availableResourceIds = bw.originalResourceToSkillsMap.keySet().clone();
                bw.totalSlots = availableResourceIds.size();

                List<Set<Id>> availableResourceSets = bw.resourceTimeAvailabilityMap.values(); 
                for (Integer x = 0, resLen = availableResourceSets.size(); x < resLen; x++) {
                    availableResourceIds.retainAll(availableResourceSets[x]);

                    if (availableResourceIds.isEmpty()) {
                        break;
                    }
                }
                bw.availableSlots = availableResourceIds.size();
            }

            unAvailableSlots.sort();

            response.put('success', true);
            response.put('altType', altType);
            response.put('nextAvailable', nextAvailable);
            response.put('bookingWindows', bookingWindows);
            response.put('unAvailableSlots', unAvailableSlots);
            response.put('bookingWindowsRemainingMap', bookingWindowsRemainingMap);
        }
        catch(Exception ex) {
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }

        return JSON.serialize(response);
    }

    /***************************************************/
    /*                                                 */
    /*      webservice used to cancel work orders      */
    /*                                                 */
    /***************************************************/
    webService static String cancelWorkOrder(Id workOrderId, String cancellationReason) {
        System.Savepoint sp = Database.setSavepoint();
        Map<String, Object> response = new Map<String, Object>();

        try {
            RbA_Work_Order__c workOrder = new RbA_Work_Order__c(
                Id = workOrderId,
                Appointment_Date__c = null,
                Appointment_End_Time__c = '',
                Appointment_Start_Time__c = ''
            );

            if (String.isNotBlank(cancellationReason)) {
                workOrder.Cancel_Reason__c = cancellationReason;
                workOrder.Cancel_Date__c = Date.today();
            }

            update workOrder;

            MA_SchedulerUtilities.deleteEvents(workOrderId, 'Cancelled', '');
            delete [SELECT Id FROM Assigned_Resources__c WHERE Work_Order__c = :workOrderId];

            response.put('success', true);
        }
        catch(Exception ex) {
            Database.rollBack(sp);
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }

        return JSON.serialize(response);
    }

    /********************************************************************/
    /*                                                                  */
    /*      webservice used to save assigned resources                  */
    /*                                                                  */
    /*      used with the MA_SchedulerAssignResourceComp component      */
    /*                                                                  */
    /********************************************************************/
    webService static String saveAssignedResources(String workOrderId, List<Id> assignedResourceIdsList, Id primaryResourceId, String assignForDay) {
        System.Savepoint sp = Database.setSavepoint();
        Map<String, Object> response = new Map<String, Object>();

        try {
            Date eventSchedulerDate;
            String eventSchedulerDateString;
            Boolean isSingleDay = String.isNotBlank(assignForDay);

            if (isSingleDay) {
                eventSchedulerDate = Date.parse(assignForDay);

                Integer month = eventSchedulerDate.month();
                String monthString = String.valueOf(month);
                if (month < 10) {
                    monthString = '0' + monthString;
                }

                Integer day = eventSchedulerDate.day();
                String dayString = String.valueOf(day);
                if (day < 10) {
                    dayString = '0' + dayString;
                }

                eventSchedulerDateString = eventSchedulerDate.year() + '-' + monthString + '-' + dayString;
            }

            assignedResourceIdsList.remove(0);

            Integer singleDayWorkNum;
            Decimal originalTotalDays;
            Boolean hadMaEvents = false;
            Date originalAppointmentDate;
            String originalAppointmentEnd;
            String originalAppointmentStart;
            Decimal originalAppointmentDuration;
            Set<Id> alreadyAssignedResourceIds = new Set<Id>();
            Map<Id, Id> resourceIdToUserIdMap = new Map<Id, Id>();
            Set<Id> assignedResourceIds = new Set<Id>(assignedResourceIdsList);
            List<Assigned_Resources__c> newAssignedResources = new List<Assigned_Resources__c>();
            List<Assigned_Resources__c> assignedResourcesToDelete = new List<Assigned_Resources__c>();
            List<Assigned_Resources__c> assignedResources = [SELECT Id, Scheduled_Resource__c FROM Assigned_Resources__c WHERE Work_Order__c = :workOrderId];

            /*
            String additionalDeletionFilters = (!assignedResourceIdsList.isEmpty() ? ' AND Resource__c NOT IN (\'' + String.join(assignedResourceIdsList, '\', \'') + '\')' : '') + (isSingleDay ? ' AND Date__c = ' + eventSchedulerDateString : '');
            MA_SchedulerUtilities.deleteEvents(workOrderId, 'Reassigned', additionalDeletionFilters);
            */

            RbA_Work_Order__c workOrder = [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Appointment_Duration__c,
                                            Work_Order_Type__c, Account__r.Store_Location__r.Active_Store_Configuration__c, Total_Days__c,
                                            (SELECT Id, StartDateTime__c, EndDateTime__c, Resource__c, Event_Sequence__c FROM MA_Scheduler_Events__r WHERE Date__c = :eventSchedulerDate AND Resource__c != null)
                                            FROM RbA_Work_Order__c WHERE Id = :workOrderId];
            
            Id storeId = workOrder.Account__r.Store_Location__r.Active_Store_Configuration__c;
            Map<String, Object> maSettingsMap = MA_SchedulerUtilities.retrieveAllStoreSettings(storeId, workOrder.Work_Order_Type__c);
            Map<String, Object> storeBookingWindows = (Map<String, Object>)maSettingsMap.get('storeBookingWindows');
            String storeTimezone = (String)maSettingsMap.get('storeTimezone');
            
            /********************************************************************/
            /*                                                                  */
            /*      determine assigned resources removed and delete them        */
            /*      also create the necessary new assigned resources            */
            /*                                                                  */
            /********************************************************************/
            for (Resource__c resource : [SELECT Id, RbA_User__c FROM Resource__c WHERE Id IN :assignedResourceIds]) {
                if (resource.RbA_User__c != null) {
                    resourceIdToUserIdMap.put(resource.Id, resource.RbA_User__c);
                }
            }

            originalTotalDays = workOrder.Total_Days__c;
            originalAppointmentDate = workOrder.Appointment_Date__c;
            originalAppointmentEnd = workOrder.Appointment_End_Time__c;
            originalAppointmentStart = workOrder.Appointment_Start_Time__c;
            originalAppointmentDuration = workOrder.Appointment_Duration__c;

            if (isSingleDay) {
                if (!workOrder.MA_Scheduler_Events__r.isEmpty()) {
                    MA_Scheduler_Event__c maEvent = workOrder.MA_Scheduler_Events__r[0];
                    workOrder.Appointment_Date__c = eventSchedulerDate;
                    workOrder.Appointment_End_Time__c = maEvent.EndDateTime__c.format('hh:mm a', storeTimezone);
                    workOrder.Appointment_Start_Time__c = maEvent.StartDateTime__c.format('hh:mm a', storeTimezone);

                    Long milliDiff = maEvent.EndDateTime__c.getTime() - maEvent.StartDateTime__c.getTime();
                    Decimal hoursDiff = ((Decimal)(milliDiff / 1000)) / 60 / 60;
                    workOrder.Appointment_Duration__c = hoursDiff.setScale(1);

                    singleDayWorkNum = Integer.valueOf(maEvent.Event_Sequence__c);
                    hadMaEvents = true;
                }
            }
            else {
                for (Assigned_Resources__c assignedResource : assignedResources) {
                    if (assignedResourceIds.contains(assignedResource.Scheduled_Resource__c)) {
                        alreadyAssignedResourceIds.add(assignedResource.Scheduled_Resource__c);
                    }
                    else {
                        assignedResourcesToDelete.add(assignedResource);
                    }
                }

                for (Id resourceId : assignedResourceIds) {
                    if (!alreadyAssignedResourceIds.contains(resourceId)) {
                        newAssignedResources.add(
                            new Assigned_Resources__c(
                                Work_Order__c = workOrderId,
                                Scheduled_Resource__c = resourceId,
                                IsPrimary__c = primaryResourceId == resourceId
                            )
                        );
                    }
                }

                delete assignedResourcesToDelete;
                insert newAssignedResources;

                /*****************************************************/
                /*                                                   */
                /*     determine the correct primary resource        */
                /*                                                   */
                /*****************************************************/
                List<Assigned_Resources__c> incorrectPrimaryResources = [SELECT Id, Scheduled_Resource__c FROM Assigned_Resources__c WHERE Work_Order__c = :workOrderId
                                                                            AND ((IsPrimary__c = true AND Scheduled_Resource__c != :primaryResourceId)
                                                                                OR (IsPrimary__c = false AND Scheduled_Resource__c = :primaryResourceId))];

                if (!incorrectPrimaryResources.isEmpty()) {
                    for (Assigned_Resources__c assignedResource : incorrectPrimaryResources) {
                        assignedResource.IsPrimary__c = assignedResource.Scheduled_Resource__c == primaryResourceId;
                    }

                    update incorrectPrimaryResources;
                }
            }

            String additionalDeletionFilters = (!assignedResourceIdsList.isEmpty() ? ' AND Resource__c NOT IN (\'' + String.join(assignedResourceIdsList, '\', \'') + '\')' : '') + (isSingleDay ? ' AND Date__c = ' + eventSchedulerDateString : '');
            MA_SchedulerUtilities.deleteEvents(workOrderId, 'Reassigned', additionalDeletionFilters);
            
            /********************************************************************/
            /*                                                                  */
            /*      create new events; previous events were deleted above       */
            /*                                                                  */
            /********************************************************************/
            if (workOrder.Appointment_Date__c != null && String.isNotBlank(workOrder.Appointment_Start_Time__c) && (String.isNotBlank(workOrder.Appointment_End_Time__c) || workOrder.Appointment_Duration__c != null)) {
                List<Event> newSfEvents = new List<Event>();
                Set<Id> maEventsAlreadyCreatedFor = new Set<Id>();
                List<MA_Scheduler_Event__c> newMaEvents = new List<MA_Scheduler_Event__c>();
                DateTime endDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_End_Time__c, storeTimezone);
                DateTime startDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_Start_Time__c, storeTimezone);
                
                Map<Id, MA_Scheduler_Event__c> maEventsAlreadyCreated = new Map<Id, MA_Scheduler_Event__c>(
                    (List<MA_Scheduler_Event__c>)Database.query('SELECT Id, Resource__c FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c IN :assignedResourceIds' + (isSingleDay ? ' AND Date__c = :eventSchedulerDate' : ''))
                );

                for (MA_Scheduler_Event__c maEvent : maEventsAlreadyCreated.values()) {
                    maEventsAlreadyCreatedFor.add(maEvent.Resource__c);
                }

                Integer tempTotalMinutes = workOrder.Appointment_Duration__c == null ? 0 : (Integer)(workOrder.Appointment_Duration__c * 60);
                DateTime tempEnd = startDateTime.addMinutes(tempTotalMinutes);
                if (tempTotalMinutes == 0) {
                    tempEnd = endDateTime;
                }

                MA_SchedulerUtilities.createEvents(workOrder, storeBookingWindows, storeTimezone, startDateTime, tempEnd, tempTotalMinutes, assignedResourceIds, maEventsAlreadyCreatedFor, resourceIdToUserIdMap, singleDayWorkNum, new Map<Integer, Set<Id>>());
                
                if (isSingleDay && hadMaEvents) {
                    workOrder.Total_Days__c = originalTotalDays;
                    workOrder.Appointment_Date__c = originalAppointmentDate;
                    workOrder.Appointment_End_Time__c = originalAppointmentEnd;
                    workOrder.Appointment_Start_Time__c = originalAppointmentStart;
                    workOrder.Appointment_Duration__c = originalAppointmentDuration;
                }

                update workOrder;
            }

            response.put('success', true);
        }
        catch(Exception ex) {
            Database.rollBack(sp);
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }

        return JSON.serialize(response);
    }

    /********************************************************************/
    /*                                                                  */
    /*      webservice used to schedule a work order                    */
    /*      deletes old events and creates new ones                     */
    /*                                                                  */
    /*      used with the MA_SchedulerWorkOrderSchedulingComp component */
    /*                                                                  */
    /********************************************************************/
    webService static String scheduleWorkOrder(Id workOrderId, String selectedWindow, String rescheduleReason, String scheduledAsType) {
        System.Savepoint sp = Database.setSavepoint();
        Map<String, Object> response = new Map<String, Object>();

        try {
            Set<Id> assignedResourceIds = new Set<Id>();
            Map<Id, Id> resourceIdToUserIdMap = new Map<Id, Id>();
            List<String> windowTextSplit = selectedWindow.split(' ');
            Map<Integer, Set<Id>> singleDayResourceMap = new Map<Integer, Set<Id>>();

            response.put('appointmentDate', windowTextSplit[0]);

            RbA_Work_Order__c workOrder = [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Appointment_Duration__c,
                                            Work_Order_Type__c, Account__r.Store_Location__r.Active_Store_Configuration__c,
                                            (SELECT Id, Scheduled_Resource__c, Scheduled_Resource__r.RbA_User__c FROM Assigned_Resources__r) /*,
                                            (SELECT Id, Event_Sequence__c, Resource__c, Resource__r.RbA_User__c FROM MA_Scheduler_Events__r) */
                                            FROM RbA_Work_Order__c WHERE Id = :workOrderId];

            workOrder.Appointment_Date__c = Date.parse(windowTextSplit[0]);
            workOrder.Appointment_End_Time__c = windowTextSplit[4] + ' ' + windowTextSplit[5];
            workOrder.Appointment_Start_Time__c = windowTextSplit[1] + ' ' + windowTextSplit[2];
            workOrder.Scheduled_As_Type__c = String.isBlank(scheduledAsType) ? '' : scheduledAsType;

            /*
            for (MA_Scheduler_Event__c maEvent : workOrder.MA_Scheduler_Events__r) {
                Integer eventSequence = Integer.valueOf(maEvent.Event_Sequence__c);

                if (!singleDayResourceMap.containsKey(eventSequence)) {
                    singleDayResourceMap.put(eventSequence, new Set<Id>());
                }

                if (maEvent.Resource__c != null) {
                    singleDayResourceMap.get(eventSequence).add(maEvent.Resource__c);
                    resourceIdToUserIdMap.put(maEvent.Resource__c, maEvent.Resource__r.RbA_User__c);
                }
            }
            */

            if (String.isNotBlank(rescheduleReason)) {
                workOrder.Reschedule_Reason__c = rescheduleReason;
                workOrder.Reschedule_Date__c = Date.today();
            }
            MA_SchedulerUtilities.deleteEvents(workOrderId, 'Rescheduled', '');
                
            for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                assignedResourceIds.add(resource.Scheduled_Resource__c);
                resourceIdToUserIdMap.put(resource.Scheduled_Resource__c, resource.Scheduled_Resource__r.RbA_User__c);
            }

            Id storeId = workOrder.Account__r.Store_Location__r.Active_Store_Configuration__c;
            Map<String, Object> maSettingsMap = MA_SchedulerUtilities.retrieveAllStoreSettings(storeId, String.isBlank(scheduledAsType) ? workOrder.Work_Order_Type__c : scheduledAsType);
            Map<String, Object> storeBookingWindows = (Map<String, Object>)maSettingsMap.get('storeBookingWindows');
            String storeTimezone = (String)maSettingsMap.get('storeTimezone');

            DateTime startDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_Start_Time__c, storeTimezone);
            Integer totalMinutes = workOrder.Appointment_Duration__c == null ? 0 : (Integer)(workOrder.Appointment_Duration__c * 60);
            DateTime endDateTime = startDateTime.addMinutes(totalMinutes);

            if (totalMinutes == 0) {
                endDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_End_Time__c, storeTimezone);
            }

            MA_SchedulerUtilities.createEvents(workOrder, storeBookingWindows, storeTimezone, startDateTime, endDateTime, totalMinutes, assignedResourceIds, new Set<Id>(), resourceIdToUserIdMap, null, singleDayResourceMap);
            update workOrder;

            response.put('success', true);
        }
        catch(Exception ex) {
            Database.rollBack(sp);
            MA_SchedulerUtilities.createErrorResponse(ex, response);
        }

        return JSON.serialize(response);
    }

}
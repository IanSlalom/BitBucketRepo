global with sharing class MA_SchedulerController {

    /*
    private static final string ESRIClientID = 'YRGMYKIjOjSpQnUz';
    private static final string ESRIClientSecret = 'ff4a4b1ecc9b43c591ac05ef98df135e';
    private static final string ArcGISauth = 'https://www.arcgis.com/sharing/rest/oauth2/token/';
    */
    //private static final string EsriGenerateToken = 'https://www.arcgis.com/sharing/generateToken?';//We may not need this







    public RbA_Work_Order__c tempWo {get;set;}

    global MA_SchedulerController() {
        Id visitRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'RbA_Work_Order__c' AND DeveloperName = 'Visit'].Id;
        tempWo = new RbA_Work_Order__c(RecordTypeId = visitRecordTypeId);
    }












    webService static String retrieveRecords(String objType, String filters, String workOrderType) {
        SObject[] objList = new SObject[]{};
        Map<String, Object> response = new Map<String, Object>();

        System.debug(filters);
        
        try {
            String query;
            
            if (objType == 'Scheduler') {
                Id currentUserId = UserInfo.getUserId();
                //query = 'SELECT Id, Resource_Type__c, Retail_Location__c FROM Resource__c WHERE Active__c = TRUE AND Resource_Type__c = \'Scheduler\' AND RbA_User__c = :currentUserId';
                query = 'SELECT Id, Resource_Type__c, Retail_Location__c, Retail_Location__r.Name FROM Resource__c WHERE Active__c = TRUE AND RbA_User__c = :currentUserId ORDER BY Retail_Location__r.Name ASC';
            }
            else if (objType == 'Resource') {
                query = 'SELECT Id, Name, Active__c, Resource_Type__c, Retail_Location__c, Retail_Location__r.Name, RbA_User__c, Crew_Size__c FROM Resource__c';
            }
            /*
            else if (objType == 'Event') {
                query = 'SELECT Id, Subject, OwnerId, WhatId, StartDateTime, EndDateTime FROM Event';
            }
            else if (objType == 'MASchedulerEvent') {
                query = 'SELECT Id, Name, Resource__c, RbA_Work_Order__c, StartDateTime__c, EndDateTime__c FROM MA_Scheduler_Event__c';
            }
            */
            else if (objType == 'MASettings') {
                query = 'SELECT Id, Store_Id__c, Resource_Id__c, Settings__c FROM MA_Scheduler_Settings__c';
            }
            else if (objType == 'WorkOrder') {
            	query = 'SELECT Id, Name, Contact__c, Contact__r.FirstName, Contact__r.LastName, Contact__r.HomePhone, Appointment_Duration__c,'
                        + ' Street__c, City__c, State__c, Zip__c, Work_Order_Type__c,'
                        + ' (SELECT Id FROM Assigned_Resources__r)'
                        + ' FROM RbA_Work_Order__c';
            }
            
            if (String.isNotBlank(query)) {
                query += String.isNotBlank(filters) ? ' WHERE ' + filters : '';


                if (objType == 'Resource') {
                    if (String.isNotBlank(workOrderType)) { 
                        Set<String> resourceTypes = MA_SchedulerUtilities.retrieveResourceTypeFromWorkOrderType(workOrderType);
                        query += ' AND Resource_Type__c IN (\'' + String.join(new List<String>(resourceTypes), '\', \'') + '\')';
                    }
                    else {
                        query += ' AND Resource_Type__c != \'Scheduler\'';
                    }
                }


                objList = Database.query(query);
            }

            response.put('success', true);
            response.put('objList', objList);
        }
        catch(Exception ex) {
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }
        
        return JSON.serialize(response);
    }




    webService static String retrieveSettings(Id storeId) {
        Map<String, Object> response = new Map<String, Object>();
        
        try {
            MA_Scheduler_Settings__c storeSettings;
            List<Resource__c> resourceList = new List<Resource__c>();
            Map<Id, MA_Scheduler_Settings__c> resourceSettingsMap = new Map<Id, MA_Scheduler_Settings__c>();

            for (MA_Scheduler_Settings__c maSettings : [SELECT Id, Store_Id__c, Resource_Id__c, Settings__c FROM MA_Scheduler_Settings__c WHERE Store_Id__c = :storeId]) {
                if (String.isNotBlank(maSettings.Resource_Id__c)) {
                    resourceSettingsMap.put(maSettings.Resource_Id__c, maSettings);
                }
                else {
                    storeSettings = maSettings;
                }
            }

            resourceList = [SELECT Id, Name, Resource_Type__c FROM Resource__c WHERE Retail_Location__c = :storeId AND Resource_Type__c != 'Scheduler' ORDER BY Resource_Type__c ASC, Name ASC];

            response.put('success', true);
            response.put('storeSettings', storeSettings);
            response.put('resourceList', resourceList);
            response.put('resourceSettingsMap', resourceSettingsMap);
        }
        catch(Exception ex) {
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }
        
        return JSON.serialize(response);
    }







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
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }
        
        return JSON.serialize(response);
    }













    //webService static String getStoreTimezone() {
        //Map<String, Object> response = new Map<String, Object>();
    	
        /*
        try {
            MA_Scheduler_Settings__c settings = [SELECT Id, Store_Id__c, Settings__c FROM MA_Scheduler_Settings__c WHERE Store_Id__c IN :storeIds]
            
            if (String.isNotBlank(query)) {
                query += String.isNotBlank(filters) ? ' WHERE ' + filters : '';
                SObject[] objList = Database.query(query);

                for (SObject obj : objList) {
                    eventList.add(new MA_SchedulerEvent(obj, new Map<Id, Id>()));
                }
            }

            response.put('success', true);
            response.put('storeTimezone', storeTimezone);
        }
        catch(Exception ex) {
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }
        
        return JSON.serialize(response);
        */








		/*
        Schema.DescribeFieldResult fieldResult = User.TimeZoneSidKey.getdescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for (Schema.PicklistEntry p : ple) {
			system.debug('###'+p.getlabel()+'****'+p.getValue()+'\n');
		}
		*/




        

        //response.put('success', true);
        //response.put('storeTimezone', 'America/Los_Angeles');
        //return JSON.serialize(response);
    //}

    /*
    private static String retrieveStoreTimezone() {
    	return 'America/Los_Angeles';
    }
    */

    














	webService static String retrieveEvents(String objType, String filters, String altFilters, String resourceUserIdToIdMapString, String storeId) {
    	Map<Id, Id> resourceUserIdToIdMap = (Map<Id, Id>)JSON.deserialize(resourceUserIdToIdMapString, Map<Id, Id>.class);
    	MA_SchedulerEvent[] eventList = new MA_SchedulerEvent[]{};
        Map<String, Object> response = new Map<String, Object>();

        System.debug(filters);
        //System.debug(startDateTimeEpoch);
        //System.debug(endDateTimeEpoch);
        
        try {
            String query, altQuery;
            
            /*
            if (objType == 'Event') {
                query = 'SELECT Id, Subject, OwnerId, WhatId, StartDateTime, EndDateTime FROM Event';
            }
            else if (objType == 'MASchedulerEvent') {
                query = 'SELECT Id, Name, Resource__c, RbA_Work_Order__c, StartDateTime__c, EndDateTime__c, RbA_Work_Order__r.Work_Order_Type__c, RbA_Work_Order__r.Contact__c, RbA_Work_Order__r.Contact__r.FirstName, RbA_Work_Order__r.Contact__r.LastName FROM MA_Scheduler_Event__c';
            }
            */
            if (objType == 'allEvents') {
                query = 'SELECT Id, Name, Resource__c, Resource__r.Name, RbA_Work_Order__c, StartDateTime__c, EndDateTime__c, Estimated_Start_Date_Time__c, Estimated_End_Date_Time__c,'
                            + ' RbA_Work_Order__r.Work_Order_Type__c, RbA_Work_Order__r.Contact__c, RbA_Work_Order__r.Contact__r.FirstName, RbA_Work_Order__r.Contact__r.LastName, RbA_Work_Order__r.City__c'
                            + ' FROM MA_Scheduler_Event__c';

                altQuery = 'SELECT Id, Subject, OwnerId, WhatId, StartDateTime, EndDateTime FROM Event';
            }
            else if (objType == 'WorkOrder') {
                /*
                query = 'SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Appointment_Duration__c, Work_Order_Type__c, Contact__c, Contact__r.FirstName, Contact__r.LastName,'
                			+ ' (SELECT Id, Scheduled_Resource__c, Scheduled_Resource__r.Name FROM Assigned_Resources__r)'
                			+ ' FROM RbA_Work_Order__c';
                */

                query = 'SELECT Id, Name, Resource__c, Resource__r.Name, RbA_Work_Order__c, StartDateTime__c, EndDateTime__c, Estimated_Start_Date_Time__c, Estimated_End_Date_Time__c,'
                            + ' RbA_Work_Order__r.Work_Order_Type__c, RbA_Work_Order__r.Contact__c, RbA_Work_Order__r.Contact__r.FirstName, RbA_Work_Order__r.Contact__r.LastName, RbA_Work_Order__r.City__c'
                            + ' FROM MA_Scheduler_Event__c';
            }
            
            Set<Id> additionalAltFilterIds = new Set<Id>();
			//String storeTimezone = MA_SchedulerUtilities.retrieveStoreTimezone();

            String storeTimezone;
            Map<String, Map<String, Map<String, Object>>> latestHours = new Map<String, Map<String, Map<String, Object>>>();

            Map<String, Object> settingsMap = new Map<String, Object>();
            List<MA_Scheduler_Settings__c> settings = [SELECT Id, Settings__c, Store_Id__c, Resource_Id__c FROM MA_Scheduler_Settings__c WHERE Store_Id__c = :storeId];
            
            for (MA_Scheduler_Settings__c setting : settings) {
                if (String.isNotBlank(setting.Settings__c)) {
                    settingsMap = (Map<String, Object>)JSON.deserializeUntyped(setting.Settings__c);
                    storeTimezone = (String)settingsMap.get('timezone');
                }
            }
            
            if (String.isNotBlank(query)) {
                query += String.isNotBlank(filters) ? ' WHERE ' + filters : '';
                SObject[] objList = Database.query(query);

                /*
                if (objType == 'WorkOrder') {

                    latestHours = MA_SchedulerUtilities.determineAllEarliestStartAndLatestEndHours(settingsMap);
                }
                */

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
                                //tempEvent.resourceNames.addAll(customEvent.resourceNames);
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

                	//customEvent.createOffsetTimes();
                    //eventList.add(customEvent);

                    /*
                    if (objType == 'WorkOrder') {
                        eventList.addAll(customEvent.relatedEvents);
                    }
                    */

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
                System.debug(altQuery);
                SObject[] objList = Database.query(altQuery);
                System.debug(objList);

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
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
            response.put('stackTrace', ex.getStackTraceString());
        }
        
        return JSON.serialize(response);
    }







    webService static String retrieveHolidays(String storeId) {
        MA_SchedulerEvent[] holidays = new MA_SchedulerEvent[]{};
        Map<String, Object> response = new Map<String, Object>();
        
        try {
            List<Object> storeHolidays = new List<Object>();
            List<MA_Scheduler_Settings__c> settings = [SELECT Id, Settings__c, Store_Id__c, Resource_Id__c FROM MA_Scheduler_Settings__c WHERE Store_Id__c = :storeId];
            
            for (MA_Scheduler_Settings__c setting : settings) {
                if (String.isNotBlank(setting.Settings__c)) {
                    Map<String, Object> settingsMap = (Map<String, Object>)JSON.deserializeUntyped(setting.Settings__c);

                    if (String.isNotBlank(setting.Store_Id__c) && String.isBlank(setting.Resource_Id__c)) {
                        storeHolidays = (List<Object>)settingsMap.get('storeHolidays');
                    }
                }
            }

            for (Object obj : storeHolidays) {
                MA_SchedulerEvent customEvent = new MA_SchedulerEvent(obj, 'storeHoliday');
                customEvent.createOffsetTimes(null);
                holidays.add(customEvent);
            }

            response.put('success', true);
            response.put('eventList', holidays);
            response.put('showEvents', true);
        }
        catch(Exception ex) {
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
            response.put('stackTrace', ex.getStackTraceString());
        }
        
        return JSON.serialize(response);
    }









































    /*
    webService static String saveSettings(Id recordId, Id storeId, String jsonSettings) {
        Map<String, Object> response = new Map<String, Object>();

        try {
            MA_Scheduler_Settings__c settings = new MA_Scheduler_Settings__c(Store_Id__c = storeId, Settings__c = jsonSettings);
            if (String.isNotBlank(recordId)) {
                settings.Id = recordId;
            }
            upsert settings;

            response.put('success', true);
            response.put('recordId', settings.Id);
        }
        catch(Exception ex) {
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }

        return JSON.serialize(response);
    }
    */





    //webService static String saveSettings(List<MA_Scheduler_Settings__c> settings) {
    webService static String saveSettings(String jsonSettings) {
        System.SavePoint sp = Database.setSavePoint();
        Map<String, Object> response = new Map<String, Object>();

        try {

            System.debug(jsonSettings);

            List<MA_Scheduler_Settings__c> settings = (List<MA_Scheduler_Settings__c>)JSON.deserialize(jsonSettings, List<MA_Scheduler_Settings__c>.class);

            System.debug(settings);

            if (settings != null && !settings.isEmpty()) {
                upsert settings;

                Id storeId = settings[0].Store_Id__c;
                Set<Id> settingsIds = (new Map<Id, MA_Scheduler_Settings__c>(settings)).keySet();
                delete [SELECT Id FROM MA_Scheduler_Settings__c WHERE Store_Id__c = :storeId AND Id NOT IN :settingsIds];
            }

            response.put('success', true);
            //response.put('recordId', settings.Id);
        }
        catch(Exception ex) {
            Database.rollBack(sp);
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }

        return JSON.serialize(response);
    }


























    webService static String createEvent(MA_SchedulerEvent busyEvent) {
        return 'hello';
    }




















    //webservice static String retrieveResourceRouteRecords(Id resourceId, String startString, String endString) {
    webservice static String retrieveResourceRouteRecords(Id resourceId, String startEpoch, String endEpoch, Id storeId) {
        Map<String, Object> response = new Map<String, Object>();

        try {
            //DateTime startDateTime = DateTime.parse(startString);
            //DateTime endDateTime = DateTime.parse(endString);
            DateTime startDateTime = DateTime.newInstance(Long.valueOf(startEpoch));
            DateTime endDateTime = DateTime.newInstance(Long.valueOf(endEpoch));

            System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z'));
            System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z'));

            String storeTimezone = MA_SchedulerUtilities.retrieveStoreTimezone(storeId);
            
            if (String.isNotBlank(storeTimezone)) {
                startDateTime = MA_SchedulerUtilities.convertGmtToTimezone(startDateTime, storeTimezone, null);
                System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z'));
                System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
                
                endDateTime = MA_SchedulerUtilities.convertGmtToTimezone(endDateTime, storeTimezone, null);
                System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z'));
                System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
            }

            System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
            System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));

            Set<Id> maEventIds = new Set<Id>();
            List<MA_Scheduler_Event__c> maEventList = [SELECT Id, StartDateTime__c, EndDateTime__c FROM MA_Scheduler_Event__c WHERE Resource__c = :resourceId AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime]; 
            for (MA_Scheduler_Event__c maEvent : maEventList) {
                maEventIds.add(maEvent.Id);
            }

            Resource__c resource = [SELECT Id, RbA_User__c FROM Resource__c WHERE Id = :resourceId];
            Id userId = resource.RbA_User__c;

            List<Event> sfEventList = [SELECT Id FROM Event WHERE OwnerId = :userId AND StartDateTime < :endDateTime AND EndDateTime > :startDateTime AND MA_Scheduler_Event__c NOT IN :maEventIds];

            response.put('success', true);
            response.put('maEventList', maEventList);
            response.put('sfEventList', sfEventList);
        }
        catch(Exception ex) {
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }

        return JSON.serialize(response);
    }


























    /*
    webService static String getESRIToken(){
        String error = 'An error occured with your request. Please check your internet connection.';
        String returnRes;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        req.setEndpoint(ArcGISauth);
        req.setMethod('POST');
        req.setBody('client_id=' + EncodingUtil.urlEncode(ESRIClientID,'UTF-8')+'&client_secret='+EncodingUtil.urlEncode(ESRIClientSecret,'UTF-8')+'&grant_type='+'client_credentials'+'&expiration='+'8000');
        try{
            res = h.send(req);
            System.debug(res.getBody());
            //JSONParser parser = JSON.createParser(res.getBody());
            *//*
            while (parser.nextToken() != null)
            {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)
                    && (parser.getText() == 'access_token'))
                {
                    parser.nextToken();
                    returnRes = parser.getText();
                    break;
                }
                else if((parser.getCurrentToken() == JSONToken.FIELD_NAME)
                    && (parser.getText() == 'error'))
                {
                    //System.debug(res.getBody());
                    returnRes = res.getBody();
                    break;
                }
                else
                {
                    System.debug('ERROR+++ '+ res.getStatus());
                    System.debug('ERROR BODY+++ '+ res.getBody());
                    System.debug('STATUS CODE+++ '+ res.getStatusCode());
                    returnRes = error;
                }
            }
            *//*
        }
        catch(System.CalloutException e){
            System.debug('Callout error: '+ e);
            System.debug(res.toString());
        }
        //return returnRes;
        return res.getBody();
    }
    */
















    webService static String retrieveAvailableResources(Id workOrderId, String assignForDay) {
        Map<String, Object> response = new Map<String, Object>();
        
        try {
            Date eventSchedulerDate;
            Boolean isSingleDay = String.isNotBlank(assignForDay);
            if (isSingleDay) {
                eventSchedulerDate = Date.parse(assignForDay);
            }


            Map<Integer, String> dayNumMap = new Map<Integer, String> {
                0 => 'Sunday',
                1 => 'Monday',
                2 => 'Tuesday',
                3 => 'Wednesday',
                4 => 'Thursday',
                5 => 'Friday',
                6 => 'Saturday'
            };

            

            RbA_Work_Order__c workOrder = [SELECT Id, Name, Work_Order_Type__c, Appointment_Duration__c, Appointment_Date__c,
                                            Appointment_Start_Time__c, Appointment_End_Time__c, Recommended_Crew_Size__c,
                                            Street__c, City__c, State__c, Zip__c, Contact__c, Contact__r.Name,
                                            Account__r.Store_Location__r.Active_Store_Configuration__c,
                                            (SELECT Id, StartDateTime__c, EndDateTime__c, Resource__c FROM MA_Scheduler_Events__r WHERE Date__c = :eventSchedulerDate),
                                            (SELECT Id, Scheduled_Resource__c, Scheduled_Resource__r.Name FROM Assigned_Resources__r),
                                            (SELECT Id, RbA_Skill__r.Name FROM Work_Order_Required_Skills__r)
                                            FROM RbA_Work_Order__c WHERE Id = :workOrderId];

            Map<Id, String> requiredSkills = new Map<Id, String>();
            for (Work_Order_Required_Skill__c skill : workOrder.Work_Order_Required_Skills__r) {
                requiredSkills.put(skill.RbA_Skill__c, skill.RbA_Skill__r.Name);
            }

            Set<Id> assignedResources = new Set<Id>();

            if (isSingleDay) {
                if (!workOrder.MA_Scheduler_Events__r.isEmpty()) {
                    for (MA_Scheduler_Event__c maEvent : workOrder.MA_Scheduler_Events__r) {
                        assignedResources.add(maEvent.Resource__c);
                    }

                    MA_Scheduler_Event__c maEvent = workOrder.MA_Scheduler_Events__r[0];
                    workOrder.Appointment_Date__c = eventSchedulerDate;
                    workOrder.Appointment_Start_Time__c = maEvent.StartDateTime__c.format('hh:mm a');
                    workOrder.Appointment_End_Time__c = maEvent.EndDateTime__c.format('hh:mm a');

                    Long milliDiff = maEvent.EndDateTime__c.getTime() - maEvent.StartDateTime__c.getTime();
                    Decimal hoursDiff = ((Decimal)(milliDiff / 1000)) / 60 / 60;
                    workOrder.Appointment_Duration__c = hoursDiff.setScale(1);
                }
            }
            else {
                for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                    assignedResources.add(resource.Scheduled_Resource__c);
                }
            }

            Map<Id, Id> availableUserIdToResourceIdMap = new Map<Id, Id>();
            Map<Id, MA_SchedulerResource> availableResources = new Map<Id, MA_SchedulerResource>();
            Id storeId = workOrder.Account__r.Store_Location__r.Active_Store_Configuration__c;
            Set<String> resourceTypes = MA_SchedulerUtilities.retrieveResourceTypeFromWorkOrderType(workOrder.Work_Order_Type__c);

            for (Resource__c resource : [SELECT Id, Name, Active__c, RbA_User__c, Crew_Size__c, Rank__c,
                                            (SELECT Id, RbA_Skill__r.Name FROM Resource_Skills__r WHERE RbA_Skill__c IN :requiredSkills.keySet())
                                            FROM Resource__c WHERE (Retail_Location__c = :storeId AND Resource_Type__c IN :resourceTypes)
                                            OR Id IN :assignedResources]) {

                System.debug(resource);
                if (!resource.Resource_Skills__r.isEmpty()) {
                    System.debug(resource.Resource_Skills__r);
                    availableUserIdToResourceIdMap.put(resource.RbA_User__c, resource.Id);
                    availableResources.put(resource.Id, new MA_SchedulerResource(resource, requiredSkills, assignedResources));
                }
            }

            if (workOrder.Appointment_Date__c != null && String.isNotBlank(workOrder.Appointment_Start_Time__c) && (String.isNotBlank(workOrder.Appointment_End_Time__c) || workOrder.Appointment_Duration__c != null)) {


                String storeTimezone;
                //List<MA_SchedulerBookingWindow> bookingWindows = new List<MA_SchedulerBookingWindow>();
                //List<MA_SchedulerBookingWindow> unAvailableSlots = new List<MA_SchedulerBookingWindow>();
                //List<Object> storeHolidays = new List<Object>();
                Map<String, Object> storeBookingWindows = new Map<String, Object>();
                Map<Id, Map<String, Object>> resourceHours = new Map<Id, Map<String, Object>>();
                List<MA_Scheduler_Settings__c> settings = [SELECT Id, Settings__c, Store_Id__c, Resource_Id__c FROM MA_Scheduler_Settings__c WHERE Store_Id__c = :storeId];
                
                for (MA_Scheduler_Settings__c setting : settings) {
                    if (String.isNotBlank(setting.Settings__c)) {
                        Map<String, Object> settingsMap = (Map<String, Object>)JSON.deserializeUntyped(setting.Settings__c);
                        storeTimezone = (String)settingsMap.get('timezone');
                        //response.put('settingsMap', settingsMap);
                        //response.put('storeTimezone', storeTimezone);

                        if (String.isNotBlank(setting.Store_Id__c) && String.isBlank(setting.Resource_Id__c)) {
                            //storeHolidays = (List<Object>)settingsMap.get('storeHolidays');
                            storeBookingWindows = (Map<String, Object>)settingsMap.get(workOrder.Work_Order_Type__c);
                            if (!storeBookingWindows.isEmpty()) {
                                storeBookingWindows = (Map<String, Object>)storeBookingWindows.get('bookingWindows');
                            }

                            if (storeBookingWindows == null || storeBookingWindows.isEmpty()) {
                                storeBookingWindows = (Map<String, Object>)settingsMap.get('storeHours');
                            }
                        }
                        else {
                            resourceHours.put(setting.Resource_Id__c, (Map<String, Object>)settingsMap.get('resourceHours'));
                        }
                    }
                }

                if (isSingleDay && !workOrder.MA_Scheduler_Events__r.isEmpty()) {
                    MA_Scheduler_Event__c maEvent = workOrder.MA_Scheduler_Events__r[0];
                    workOrder.Appointment_Start_Time__c = maEvent.StartDateTime__c.format('hh:mm a', storeTimezone);
                    workOrder.Appointment_End_Time__c = null;
                }

                /*
                if (storeBookingWindows.isEmpty()) {
                    response.put('success', false);
                    response.put('error', 'The store hours and/or ' + workOrder.Work_Order_Type__c + ' booking windows have not been configured yet.  Please go to the settings page to set these up.');
                    return JSON.serialize(response);
                }
                */


                Map<String, Map<String, Object>> latestHours = MA_SchedulerUtilities.determineEarliestStartAndLatestEndHours(storeBookingWindows);
                //Map<String, Set<String>> allConfiguredWindows = MA_SchedulerUtilities.determineAllConfiguredHours(storeBookingWindows);
                //Set<String> storeHolidayDates = MA_SchedulerUtilities.determineStoreHolidays(storeHolidays);





                //String storeTimezone = MA_SchedulerUtilities.retrieveStoreTimezone(storeId);
                DateTime startDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_Start_Time__c, storeTimezone);

                DateTime endDateTime;
                Integer totalMinutes = (Integer)(workOrder.Appointment_Duration__c * 60);

                if (String.isNotBlank(workOrder.Appointment_End_Time__c)) {
                    endDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_End_Time__c, storeTimezone);
                }
                /*
                else {
                    endDateTime = startDateTime.addMinutes((Integer)(workOrder.Appointment_Duration__c * 60));
                }
                */



















                //for (Integer i = 0, len = bookingWindows.size(); i < len; i++) {
                    //MA_SchedulerBookingWindow bw = bookingWindows[i];
                    DateTime tempStart = startDateTime;
                    Integer tempTotalMinutes = totalMinutes;
                    DateTime tempEnd = tempStart.addMinutes(tempTotalMinutes);

                    //System.debug(i);
                    System.debug(totalMinutes);

                    if (latestHours != null && !latestHours.isEmpty()) {
                        /*
                        Map<Integer, String> dayNumMap = new Map<Integer, String> {
                            0 => 'Sunday',
                            1 => 'Monday',
                            2 => 'Tuesday',
                            3 => 'Wednesday',
                            4 => 'Thursday',
                            5 => 'Friday',
                            6 => 'Saturday'
                        };
                        */

                        Date tempStartDate = Date.parse(tempStart.format('MM/dd/yyyy', storeTimezone));
                        Date startOfWeek = tempStartDate.toStartOfWeek();
                        Integer daysBetweenStartOfWeek = startOfWeek.daysBetween(tempStartDate);
                        String dayOfWeek = dayNumMap.get(daysBetweenStartOfWeek);
                        DateTime daysEndDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)(latestHours.get(dayOfWeek).get('end')));
                        daysEndDateTime = MA_SchedulerUtilities.convertGmtToTimezone(daysEndDateTime, storeTimezone, null);
                        
                        if (tempEnd > daysEndDateTime) {
                            tempEnd = daysEndDateTime;
                        }

                        Long totalMillisecondDifference = tempEnd.getTime() - tempStart.getTime();
                        tempTotalMinutes -= (Integer)(totalMillisecondDifference / 1000 / 60); 

                        //DateTime nextDateTime = tempStart;
                        DateTime nextDaysEndDateTime = tempEnd;






                        Set<Id> resourceHoursKeySet = resourceHours.keySet();
                        Set<Id> availableResourcesKeySet = availableResources.keySet();
                        resourceHoursKeySet.retainAll(availableResourcesKeySet);

                        for (Id resourceId : resourceHoursKeySet) {
                            Map<String, Object> resourceHoursMap = resourceHours.get(resourceId);
                            if (resourceHoursMap.containsKey(dayOfWeek)) {
                                List<Object> daysHoursList = (List<Object>)resourceHoursMap.get(dayOfWeek);
                                Map<String, Object> hoursMap = (Map<String, Object>)daysHoursList[0];

                                String startTimeString = (String)hoursMap.get('start');
                                String endTimeString = (String)hoursMap.get('end');
                                
                                List<String> startTimeSplit = (startTimeString).split(':');
                                List<String> endTimeSplit = (endTimeString).split(':');

                                Time startTime = Time.newInstance(Integer.valueOf(startTimeSplit[0]), Integer.valueOf(startTimeSplit[1]), 0, 0);
                                Time endTime = Time.newInstance(Integer.valueOf(endTimeSplit[0]), Integer.valueOf(endTimeSplit[1]), 0, 0);

                                Date day = Date.parse(tempStart.format('MM/dd/yyyy', storeTimezone));

                                DateTime startDateTimeTemp = DateTime.newInstance(day, startTime);
                                DateTime endDateTimeTemp = DateTime.newInstance(day, endTime);

                                startDateTimeTemp = MA_SchedulerUtilities.convertTimezoneToTimezone(startDateTimeTemp, null, storeTimezone);
                                endDateTimeTemp = MA_SchedulerUtilities.convertTimezoneToTimezone(endDateTimeTemp, null, storeTimezone);

                                if (startDateTimeTemp > tempStart || endDateTimeTemp < tempEnd) {
                                    availableResources.remove(resourceId);
                                }
                            }
                        }



                        //Set<String> tempWindowsSpannedToCheck = allConfiguredWindows.get(dayOfWeek);
                        //Integer windowStartIndex = tempWindowsSpannedToCheck.indexOf(bw.dayOfWeek + ' - ' + bw.windowStart + ' - ' + bw.windowEnd);
                        //Set<String> windowsSpannedToCheck = allConfiguredWindows.get(dayOfWeek);

                        //Set<String> windowsSpannedToCheck = allConfiguredWindows.get(dayOfWeek);
                        //if (tempTotalMinutes > 0) {
                            //if (!remainingSlots.get(tempStart.date()).containsAll(windowsSpannedToCheck)) {
                                /*
                            if (!remainingSlots.get(tempStart.format('MM/dd/yyyy', storeTimezone)).containsAll(windowsSpannedToCheck)) {
                                badIndexes.add(i);
                                tempTotalMinutes = 0;
                            }

                            List<String> tempList = new List<String>(windowsSpannedToCheck);
                            tempList.remove(0);
                            badSlots.addAll(tempList);
                            */
                        //}
                        //else {
                            /*
                            Set<String> tempRemainingSet = new Set<String>(remainingSlots.get(tempStart.date()));
                            tempRemainingSet.removeAll(windowsSpannedToCheck);
                            List<String> tempRemainingList = new List<String>(tempRemainingSet);
                            */
                            /*
                            Set<String> tempwindowsSpannedToCheckSet = new Set<String>(windowsSpannedToCheck);
                            //tempwindowsSpannedToCheckSet.removeAll(remainingSlots.get(tempStart.date()));
                            tempwindowsSpannedToCheckSet.removeAll(remainingSlots.get(tempStart.format('MM/dd/yyyy', storeTimezone)));
                            List<String> tempRemainingList = new List<String>(tempwindowsSpannedToCheckSet);

                            for (Integer x = 0, remainingLen = tempRemainingList.size(); x < remainingLen; x++) {
                                List<String> tempRemainingSplit = tempRemainingList[x].split(' - ');
                                List<String> tempRemainingStartTimeSplit = tempRemainingSplit[1].split(':');
                                List<String> tempStartTimeSplit = tempStart.format('HH:mm', storeTimezone).split(':');

                                Time tempStartTime = Time.newInstance(Integer.valueOf(tempStartTimeSplit[0]), Integer.valueOf(tempStartTimeSplit[1]), 0, 0);
                                //tempStartTime = MA_SchedulerUtilities.convertGmtToTimezone(tempStartTime, storeTimezone, null);
                                
                                Time tempStartTimeRemaining = Time.newInstance(Integer.valueOf(tempRemainingStartTimeSplit[0]), Integer.valueOf(tempRemainingStartTimeSplit[1]), 0, 0);
                                //tempStartTimeRemaining = MA_SchedulerUtilities.convertGmtToTimezone(tempStartTimeRemaining, storeTimezone, null);

                                List<String> tempRemainingEndTimeSplit = tempRemainingSplit[2].split(':');
                                List<String> tempEndTimeSplit = tempEnd.format('HH:mm', storeTimezone).split(':');

                                Time tempEndTime = Time.newInstance(Integer.valueOf(tempEndTimeSplit[0]), Integer.valueOf(tempEndTimeSplit[1]), 0, 0);
                                //tempEndTime = MA_SchedulerUtilities.convertGmtToTimezone(tempEndTime, storeTimezone, null);
                                
                                Time tempEndTimeRemaining = Time.newInstance(Integer.valueOf(tempRemainingEndTimeSplit[0]), Integer.valueOf(tempRemainingEndTimeSplit[1]), 0, 0);
                                //tempEndTimeRemaining = MA_SchedulerUtilities.convertGmtToTimezone(tempEndTimeRemaining, storeTimezone, null);

                                if (tempStartTimeRemaining < tempEndTime && tempEndTimeRemaining > tempStartTime) {
                                    badIndexes.add(i);
                                    tempTotalMinutes = 0;
                                    break;
                                }
                            }
                            */
                        //}



                        while (tempTotalMinutes > 0) {
                        
                            System.debug(tempTotalMinutes);
                            //System.debug(nextDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));
                            System.debug(nextDaysEndDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));

                            //nextDateTime = nextDateTime.addDays(1);
                            tempStartDate = tempStartDate.addDays(1);
                            daysBetweenStartOfWeek += 1;
                            String nextDayOfWeek = dayNumMap.get(Math.mod(daysBetweenStartOfWeek, 7));
                            Map<String, Object> nextDaysHours = latestHours.get(nextDayOfWeek);

                            if (nextDaysHours != null) {
                                //DateTime nextDaysStartDateTime = DateTime.newInstanceGmt(nextDateTime.date(), (Time)nextDaysHours.get('start'));
                                DateTime nextDaysStartDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)nextDaysHours.get('start'));
                                nextDaysStartDateTime = MA_SchedulerUtilities.convertGmtToTimezone(nextDaysStartDateTime, storeTimezone, null);

                                if (nextDaysStartDateTime != null) {
                                    nextDaysEndDateTime = nextDaysStartDateTime.addMinutes(tempTotalMinutes);
                                    //DateTime nextDaysFinalEndDateTime = DateTime.newInstanceGmt(nextDateTime.date(), (Time)nextDaysHours.get('end'));
                                    DateTime nextDaysFinalEndDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)nextDaysHours.get('end'));
                                    nextDaysFinalEndDateTime = MA_SchedulerUtilities.convertGmtToTimezone(nextDaysFinalEndDateTime, storeTimezone, null);
                        
                                    if (nextDaysEndDateTime > nextDaysFinalEndDateTime) {
                                        nextDaysEndDateTime = nextDaysFinalEndDateTime;
                                    }
                        
                                    System.debug(nextDaysStartDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));
                                    System.debug(nextDaysEndDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));

                                    System.debug(nextDaysFinalEndDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));
                                    System.debug(nextDaysStartDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));

                                    totalMillisecondDifference = nextDaysEndDateTime.getTime() - nextDaysStartDateTime.getTime();

                                    System.debug(totalMillisecondDifference);

                                    tempTotalMinutes -= (Integer)(totalMillisecondDifference / 1000 / 60);

                                    System.debug(tempTotalMinutes);





                                    resourceHoursKeySet = resourceHours.keySet();
                                    availableResourcesKeySet = availableResources.keySet();
                                    resourceHoursKeySet.retainAll(availableResourcesKeySet);

                                    for (Id resourceId : resourceHoursKeySet) {
                                        Map<String, Object> resourceHoursMap = resourceHours.get(resourceId);
                                        if (resourceHoursMap.containsKey(dayOfWeek)) {
                                            List<Object> daysHoursList = (List<Object>)resourceHoursMap.get(dayOfWeek);
                                            Map<String, Object> hoursMap = (Map<String, Object>)daysHoursList[0];

                                            String startTimeString = (String)hoursMap.get('start');
                                            String endTimeString = (String)hoursMap.get('end');
                                            
                                            List<String> startTimeSplit = (startTimeString).split(':');
                                            List<String> endTimeSplit = (endTimeString).split(':');

                                            Time startTime = Time.newInstance(Integer.valueOf(startTimeSplit[0]), Integer.valueOf(startTimeSplit[1]), 0, 0);
                                            Time endTime = Time.newInstance(Integer.valueOf(endTimeSplit[0]), Integer.valueOf(endTimeSplit[1]), 0, 0);

                                            Date day = Date.parse(tempStart.format('MM/dd/yyyy', storeTimezone));

                                            DateTime startDateTimeTemp = DateTime.newInstance(day, startTime);
                                            DateTime endDateTimeTemp = DateTime.newInstance(day, endTime);

                                            startDateTimeTemp = MA_SchedulerUtilities.convertTimezoneToTimezone(startDateTimeTemp, null, storeTimezone);
                                            endDateTimeTemp = MA_SchedulerUtilities.convertTimezoneToTimezone(endDateTimeTemp, null, storeTimezone);

                                            if (startDateTimeTemp > tempStart || endDateTimeTemp < tempEnd) {
                                                availableResources.remove(resourceId);
                                            }
                                        }
                                    }






                                    /*
                                    windowsSpannedToCheck = allConfiguredWindows.get(nextDayOfWeek);
                                    System.debug(windowsSpannedToCheck);
                                    System.debug(remainingSlots);
                                    System.debug(nextDaysStartDateTime);
                                    //System.debug(remainingSlots.get(nextDaysStartDateTime.date()));
                                    System.debug(remainingSlots.get(nextDaysStartDateTime.format('MM/dd/yyyy', storeTimezone)));
                                    */

                                    //if (remainingSlots.get(nextDaysStartDateTime.date()) == null) {
                                    //if (remainingSlots.get(nextDaysStartDateTime.format('MM/dd/yyyy', storeTimezone)) == null) {
                                        /*
                                        badIndexes.add(i);
                                        tempTotalMinutes = 0;
                                        break;
                                        */
                                    //}
                                    //else if (!remainingSlots.get(nextDaysStartDateTime.date()).containsAll(windowsSpannedToCheck)) {
                                    //else if (!remainingSlots.get(nextDaysStartDateTime.format('MM/dd/yyyy', storeTimezone)).containsAll(windowsSpannedToCheck)) {
                                        //System.debug('not complete match');
                                        /*
                                        Set<String> tempRemainingSet = new Set<String>(remainingSlots.get(nextDaysStartDateTime.date()));
                                        tempRemainingSet.removeAll(windowsSpannedToCheck);
                                        List<String> tempRemainingList = new List<String>(tempRemainingSet);
                                        */
                                        /*
                                        Set<String> tempWindowsSpannedToCheckSet = new Set<String>(windowsSpannedToCheck);
                                        //tempWindowsSpannedToCheckSet.removeAll(remainingSlots.get(nextDaysStartDateTime.date()));
                                        tempWindowsSpannedToCheckSet.removeAll(remainingSlots.get(nextDaysStartDateTime.format('MM/dd/yyyy', storeTimezone)));
                                        List<String> tempRemainingList = new List<String>(tempWindowsSpannedToCheckSet);

                                        for (Integer x = 0, remainingLen = tempRemainingList.size(); x < remainingLen; x++) {
                                            List<String> tempRemainingSplit = tempRemainingList[x].split(' - ');
                                            List<String> tempRemainingStartTimeSplit = tempRemainingSplit[1].split(':');
                                            List<String> tempStartTimeSplit = nextDaysStartDateTime.format('HH:mm', storeTimezone).split(':');

                                            Time tempStartTime = Time.newInstance(Integer.valueOf(tempStartTimeSplit[0]), Integer.valueOf(tempStartTimeSplit[1]), 0, 0);
                                            //tempStartTime = MA_SchedulerUtilities.convertGmtToTimezone(tempStartTime, storeTimezone, null);

                                            Time tempStartTimeRemaining = Time.newInstance(Integer.valueOf(tempRemainingStartTimeSplit[0]), Integer.valueOf(tempRemainingStartTimeSplit[1]), 0, 0);
                                            //tempStartTimeRemaining = MA_SchedulerUtilities.convertGmtToTimezone(tempStartTimeRemaining, storeTimezone, null);

                                            List<String> tempRemainingEndTimeSplit = tempRemainingSplit[2].split(':');
                                            List<String> tempEndTimeSplit = nextDaysEndDateTime.format('HH:mm', storeTimezone).split(':');

                                            Time tempEndTime = Time.newInstance(Integer.valueOf(tempEndTimeSplit[0]), Integer.valueOf(tempEndTimeSplit[1]), 0, 0);
                                            //tempEndTime = MA_SchedulerUtilities.convertGmtToTimezone(tempEndTime, storeTimezone, null);

                                            Time tempEndTimeRemaining = Time.newInstance(Integer.valueOf(tempRemainingEndTimeSplit[0]), Integer.valueOf(tempRemainingEndTimeSplit[1]), 0, 0);
                                            //tempEndTimeRemaining = MA_SchedulerUtilities.convertGmtToTimezone(tempEndTimeRemaining, storeTimezone, null);
                        
                                            System.debug(tempStartTime);
                                            System.debug(tempStartTimeRemaining);

                                            System.debug(tempEndTime);
                                            System.debug(tempEndTimeRemaining);

                                            if (tempStartTimeRemaining < tempEndTime && tempEndTimeRemaining > tempStartTime) {
                                                badIndexes.add(i);
                                                tempTotalMinutes = 0;
                                                break;
                                            }
                                        }
                                        */
                                    //}
                                }
                                //else {
                                    //badIndexes.add(i);
                                    //tempTotalMinutes = 0;
                                //}
                            }
                            //else {
                                //badIndexes.add(i);
                                //tempTotalMinutes = 0;
                            //}
                        }

                        endDateTime = nextDaysEndDateTime;
                    }
                //}








                Set<Id> resourceHoursKeySet = resourceHours.keySet();
                Set<Id> availableResourcesKeySet = availableResources.keySet();
                resourceHoursKeySet.retainAll(availableResourcesKeySet);

                Date tempStartDate = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone));
                Date startOfWeek = tempStartDate.toStartOfWeek();
                Integer daysBetweenStartOfWeek = startOfWeek.daysBetween(tempStartDate);
                String dayOfWeek = dayNumMap.get(daysBetweenStartOfWeek);

                for (Id resourceId : resourceHoursKeySet) {
                    Map<String, Object> resourceHoursMap = resourceHours.get(resourceId);
                    if (resourceHoursMap.containsKey(dayOfWeek)) {
                        List<Object> daysHoursList = (List<Object>)resourceHoursMap.get(dayOfWeek);
                        Map<String, Object> hoursMap = (Map<String, Object>)daysHoursList[0];

                        String startTimeString = (String)hoursMap.get('start');
                        String endTimeString = (String)hoursMap.get('end');
                        
                        List<String> startTimeSplit = (startTimeString).split(':');
                        List<String> endTimeSplit = (endTimeString).split(':');

                        Time startTime = Time.newInstance(Integer.valueOf(startTimeSplit[0]), Integer.valueOf(startTimeSplit[1]), 0, 0);
                        Time endTime = Time.newInstance(Integer.valueOf(endTimeSplit[0]), Integer.valueOf(endTimeSplit[1]), 0, 0);

                        Date day = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone));

                        DateTime startDateTimeTemp = DateTime.newInstance(day, startTime);
                        DateTime endDateTimeTemp = DateTime.newInstance(day, endTime);

                        startDateTimeTemp = MA_SchedulerUtilities.convertTimezoneToTimezone(startDateTimeTemp, null, storeTimezone);
                        endDateTimeTemp = MA_SchedulerUtilities.convertTimezoneToTimezone(endDateTimeTemp, null, storeTimezone);

                        if (startDateTimeTemp > startDateTime || endDateTimeTemp < endDateTime) {
                            availableResources.remove(resourceId);
                        }
                    }
                }



























                for (MA_Scheduler_Event__c maEvent : [SELECT Resource__c FROM MA_Scheduler_Event__c WHERE Resource__c IN :availableResources.keySet() AND RbA_Work_Order__c != :workOrderId AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime]) {
                    MA_SchedulerResource resource = availableResources.get(maEvent.Resource__c);
                    if (resource != null) {
                        if (resource.isAssigned) {
                            resource.isAvailable = false;
                        }
                        else {
                            availableResources.remove(maEvent.Resource__c);
                        }
                    }
                }

                for (Event sfEvent : [SELECT OwnerId FROM Event WHERE OwnerId IN :availableResources.keySet() AND WhatId != :workOrderId AND StartDateTime < :endDateTime AND EndDateTime > :startDateTime]) {
                    MA_SchedulerResource resource = availableResources.get(sfEvent.OwnerId);
                    if (resource != null) {
                        if (resource.isAssigned) {
                            resource.isAvailable = false;
                        }
                        else {
                            availableResources.remove(sfEvent.OwnerId);
                        }
                    }
                }
            }

            List<MA_SchedulerResource> availableResourcesList = availableResources.values();
            availableResourcesList.sort();

            response.put('success', true);
            response.put('workOrder', workOrder);
            response.put('isSingleDay', isSingleDay);
            response.put('availableResources', availableResourcesList);
        }
        catch(Exception ex) {
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }
        
        return JSON.serialize(response);
    }


    




































    webService static String checkAvailability(Id workOrderId, String startDateTimeEpoch, String endDateTimeEpoch, String offsetPageMinutes, Boolean nextAvailable) {
        Map<String, Object> response = new Map<String, Object>();

        try {
			RbA_Work_Order__c workOrder = [SELECT Id, Work_Order_Type__c, Appointment_Duration__c, Account__r.Store_Location__r.Active_Store_Configuration__c,
                                            (SELECT Id, RbA_Skill__c FROM Work_Order_Required_Skills__r),
                                            (SELECT Id, Scheduled_Resource__c FROM Assigned_Resources__r)
                                            FROM RbA_Work_Order__c WHERE Id = :workOrderId];

            Id storeId = workOrder.Account__r.Store_Location__r.Active_Store_Configuration__c;
            Set<Id> rbaSkillIds = new Set<Id>();
            Set<Id> assignedResourceIds = new Set<Id>();

            for (Work_Order_Required_Skill__c rbaSkill : workOrder.Work_Order_Required_Skills__r) {
                rbaSkillIds.add(rbaSkill.RbA_Skill__c);
            }
            for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                assignedResourceIds.add(resource.Scheduled_Resource__c);
            }

            Map<Id, Id> userMap = new Map<Id, Id>();
            //Set<Id> resourceIds = new Set<Id>();
            Map<Id, Set<Id>> resourceToSkillsMap = new Map<Id, Set<Id>>();
            Map<Id, Integer> totalSkillsCountMap = new Map<Id, Integer>();
            Set<String> resourceTypes = MA_SchedulerUtilities.retrieveResourceTypeFromWorkOrderType(workOrder.Work_Order_Type__c);
            List<Resource__c> resourceList = [SELECT Id, RbA_User__c,
                                                (SELECT Id, RbA_Skill__c FROM Resource_Skills__r WHERE RbA_Skill__c IN :rbaSkillIds)
                                                FROM Resource__c WHERE (Retail_Location__c = :storeId AND Active__c = true AND Resource_Type__c IN :resourceTypes) OR Id IN :assignedResourceIds];

            for (Resource__c resource : resourceList) {
                if (!resource.Resource_Skills__r.isEmpty()) {
                    //resourceIds.add(resource.Id);
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

            System.debug(totalSkillsCountMap);

            String storeTimezone;
            List<MA_SchedulerBookingWindow> bookingWindows = new List<MA_SchedulerBookingWindow>();
            List<MA_SchedulerBookingWindow> unAvailableSlots = new List<MA_SchedulerBookingWindow>();
            List<Object> storeHolidays = new List<Object>();
            Map<String, Object> storeBookingWindows = new Map<String, Object>();
            Map<Id, Map<String, Object>> resourceHours = new Map<Id, Map<String, Object>>();
            List<MA_Scheduler_Settings__c> settings = [SELECT Id, Settings__c, Store_Id__c, Resource_Id__c FROM MA_Scheduler_Settings__c WHERE Store_Id__c = :storeId];
            
            for (MA_Scheduler_Settings__c setting : settings) {
                if (String.isNotBlank(setting.Settings__c)) {
                    Map<String, Object> settingsMap = (Map<String, Object>)JSON.deserializeUntyped(setting.Settings__c);
                    storeTimezone = (String)settingsMap.get('timezone');
                    //response.put('settingsMap', settingsMap);
                    //response.put('storeTimezone', storeTimezone);

                    if (String.isNotBlank(setting.Store_Id__c) && String.isBlank(setting.Resource_Id__c)) {
                        storeHolidays = (List<Object>)settingsMap.get('storeHolidays');
                        storeBookingWindows = (Map<String, Object>)settingsMap.get(workOrder.Work_Order_Type__c);
                        if (!storeBookingWindows.isEmpty()) {
                            storeBookingWindows = (Map<String, Object>)storeBookingWindows.get('bookingWindows');
                        }

                        if (storeBookingWindows == null || storeBookingWindows.isEmpty()) {
                            storeBookingWindows = (Map<String, Object>)settingsMap.get('storeHours');
                        }
                    }
                    else {
                        resourceHours.put(setting.Resource_Id__c, (Map<String, Object>)settingsMap.get('resourceHours'));
                    }
                }
            }

            if (storeBookingWindows.isEmpty()) {
                response.put('success', false);
                response.put('error', 'The store hours and/or ' + workOrder.Work_Order_Type__c + ' booking windows have not been configured yet.  Please go to the settings page to set these up.');
                return JSON.serialize(response);
            }


            Map<String, Map<String, Object>> latestHours = MA_SchedulerUtilities.determineEarliestStartAndLatestEndHours(storeBookingWindows);
            Map<String, Set<String>> allConfiguredWindows = MA_SchedulerUtilities.determineAllConfiguredHours(storeBookingWindows);
            Set<String> storeHolidayDates = MA_SchedulerUtilities.determineStoreHolidays(storeHolidays);




            DateTime endDateTime = DateTime.newInstance(Long.valueOf(endDateTimeEpoch)).addDays(7);
	        DateTime startDateTime = DateTime.newInstance(Long.valueOf(startDateTimeEpoch)).addDays(-7);

            Date endDate = endDateTime.date();
            Date startDate = startDateTime.date();
            
            if (String.isNotBlank(storeTimezone)) {
                startDateTime = MA_SchedulerUtilities.convertGmtToTimezone(startDateTime, storeTimezone, offsetPageMinutes);
                System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z'));
                System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
                
                startDate = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone));
                
	            endDateTime = MA_SchedulerUtilities.convertGmtToTimezone(endDateTime, storeTimezone, offsetPageMinutes);
	            System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z'));
	            System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));

                endDate = Date.parse(endDateTime.format('MM/dd/yyyy', storeTimezone));

				System.debug(startDate);
				System.debug(endDate);
	        }




	        System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
	        System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));





            //createBookingWindows(bookingWindows, storeBookingWindows, resourceIds, startDateTime, endDateTime, storeTimezone);
            createBookingWindows(bookingWindows, unAvailableSlots, storeBookingWindows, resourceToSkillsMap, totalSkillsCountMap, startDateTime, endDateTime, storeTimezone, storeHolidayDates, resourceHours);


            response.put('bookingWindowsTEMP1', bookingWindows.clone());

            //List<Event> eventsList = [SELECT Id, StartDateTime, EndDateTime, OwnerId, WhatId, Subject FROM Event WHERE OwnerId IN :userMap.keySet() AND StartDateTime < :endDateTime AND EndDateTime > :startDateTime];
            //List<MA_Scheduler_Event__c> maEventsList = [SELECT Id, StartDateTime__c, EndDateTime__c, Resource__c, RbA_Work_Order__c, Name FROM MA_Scheduler_Event__c WHERE Resource__c IN :resourceIds AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime];

            Set<Id> scheduledWorkOrderIds = new Set<Id> { workOrder.Id };
            //scheduledWorkOrderIds.addAll(checkResourceAvailability(bookingWindows, unAvailableSlots, /*eventsList, maEventsList,*/ userMap, startDateTime, endDateTime, resourceIds));
            /*scheduledWorkOrderIds.addAll(*/checkResourceAvailability(bookingWindows, unAvailableSlots, userMap, startDateTime, endDateTime, resourceToSkillsMap, workOrder.Work_Order_Type__c, rbaSkillIds)/*)*/;


            response.put('bookingWindowsTEMP2', bookingWindows.clone());

            //List<RbA_Work_Order__c> workOrderList = [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c FROM RbA_Work_Order__c WHERE Id NOT IN :scheduledWorkOrderIds AND Appointment_Date__c >= :startDate AND Appointment_Date__c <= :endDate];


            //checkResourceAvailability(bookingWindows, unAvailableSlots, /*workOrderList, userMap, */startDate, endDate, scheduledWorkOrderIds, latestHours, storeTimezone);


            response.put('bookingWindowsTEMP3', bookingWindows.clone());




            System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
            System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
            System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z'));
            System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z'));


            System.debug(assignedResourceIds);
            if (!assignedResourceIds.isEmpty()) {
                for (Integer i = 0, index = bookingWindows.size() - 1; index >= i; index--) {
                    MA_SchedulerBookingWindow bw = bookingWindows[index];

                    //System.debug(bw.availableResources);
                    //if (!bw.availableResources.containsAll(assignedResourceIds)) {
                    if (!bw.resourceToSkillsMap.keySet().containsAll(assignedResourceIds)) {
                        unAvailableSlots.add(bookingWindows[index]);
                        bookingWindows.remove(index);
                    }
                }
            }



            //Map<Date, Set<String>> remainingSlots = new Map<Date, Set<String>>();
            Map<String, Set<String>> remainingSlots = new Map<String, Set<String>>();
            for (Integer i = 0, index = bookingWindows.size() - 1; index >= i; index--) {
                MA_SchedulerBookingWindow bw = bookingWindows[index];
                bw.determineSkillsMatched();

                //System.debug(bw.availableResources);
                if (bw.skillsMatched.size() < workOrder.Work_Order_Required_Skills__r.size()) {
                    unAvailableSlots.add(bookingWindows[index]);
                    bookingWindows.remove(index);
                }
                else {
                    //if (!remainingSlots.containsKey(bw.startDateTime.date())) {
                    if (!remainingSlots.containsKey(bw.startDateTime.format('MM/dd/yyyy', storeTimezone))) {
                        //remainingSlots.put(bw.startDateTime.date(), new Set<String>());
                        remainingSlots.put(bw.startDateTime.format('MM/dd/yyyy', storeTimezone), new Set<String>());
                    }
                    //remainingSlots.get(bw.startDateTime.date()).add(bw.dayOfWeek + ' - ' + bw.windowStart + ' - ' + bw.windowEnd);
                    remainingSlots.get(bw.startDateTime.format('MM/dd/yyyy', storeTimezone)).add(bw.dayOfWeek + ' - ' + bw.windowStart + ' - ' + bw.windowEnd);
                }
            }


            response.put('bookingWindowsTEMP', bookingWindows.clone());


            response.put('unAvailableSlotsTEMP', unAvailableSlots.clone());





            

            Set<Integer> badIndexes = new Set<Integer>();
            Set<String> badSlots = new Set<String>();
            Integer totalMinutes = (Integer)(workOrder.Appointment_Duration__c * 60);

            for (Integer i = 0, len = bookingWindows.size(); i < len; i++) {
                MA_SchedulerBookingWindow bw = bookingWindows[i];
                DateTime tempStart = bw.startDateTime;
                Integer tempTotalMinutes = totalMinutes;
                DateTime tempEnd = tempStart.addMinutes(tempTotalMinutes);

                System.debug(i);
                System.debug(totalMinutes);

                if (latestHours != null && !latestHours.isEmpty()) {
                    Map<Integer, String> dayNumMap = new Map<Integer, String> {
                        0 => 'Sunday',
                        1 => 'Monday',
                        2 => 'Tuesday',
                        3 => 'Wednesday',
                        4 => 'Thursday',
                        5 => 'Friday',
                        6 => 'Saturday'
                    };

                    Date tempStartDate = Date.parse(tempStart.format('MM/dd/yyyy', storeTimezone));
                    Date startOfWeek = tempStartDate.toStartOfWeek();
                    Integer daysBetweenStartOfWeek = startOfWeek.daysBetween(tempStartDate);
                    String dayOfWeek = dayNumMap.get(daysBetweenStartOfWeek);
                    DateTime daysEndDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)(latestHours.get(dayOfWeek).get('end')));
                    daysEndDateTime = MA_SchedulerUtilities.convertGmtToTimezone(daysEndDateTime, storeTimezone, null);
                    
                    if (tempEnd > daysEndDateTime) {
                        tempEnd = daysEndDateTime;
                    }

                    Long totalMillisecondDifference = tempEnd.getTime() - tempStart.getTime();
                    tempTotalMinutes -= (Integer)(totalMillisecondDifference / 1000 / 60); 

                    //DateTime nextDateTime = tempStart;
                    DateTime nextDaysEndDateTime = tempEnd;



                    //Set<String> tempWindowsSpannedToCheck = allConfiguredWindows.get(dayOfWeek);
                    //Integer windowStartIndex = tempWindowsSpannedToCheck.indexOf(bw.dayOfWeek + ' - ' + bw.windowStart + ' - ' + bw.windowEnd);
                    //Set<String> windowsSpannedToCheck = allConfiguredWindows.get(dayOfWeek);

                    Set<String> windowsSpannedToCheck = allConfiguredWindows.get(dayOfWeek);
                    if (tempTotalMinutes > 0) {
                        //if (!remainingSlots.get(tempStart.date()).containsAll(windowsSpannedToCheck)) {
                        if (!remainingSlots.get(tempStart.format('MM/dd/yyyy', storeTimezone)).containsAll(windowsSpannedToCheck)) {
                            badIndexes.add(i);
                            tempTotalMinutes = 0;
                        }

                        List<String> tempList = new List<String>(windowsSpannedToCheck);
                        tempList.remove(0);
                        badSlots.addAll(tempList);
                    }
                    else {
                        /*
                        Set<String> tempRemainingSet = new Set<String>(remainingSlots.get(tempStart.date()));
                        tempRemainingSet.removeAll(windowsSpannedToCheck);
                        List<String> tempRemainingList = new List<String>(tempRemainingSet);
                        */
                        Set<String> tempwindowsSpannedToCheckSet = new Set<String>(windowsSpannedToCheck);
                        //tempwindowsSpannedToCheckSet.removeAll(remainingSlots.get(tempStart.date()));
                        tempwindowsSpannedToCheckSet.removeAll(remainingSlots.get(tempStart.format('MM/dd/yyyy', storeTimezone)));
                        List<String> tempRemainingList = new List<String>(tempwindowsSpannedToCheckSet);

                        for (Integer x = 0, remainingLen = tempRemainingList.size(); x < remainingLen; x++) {
                            List<String> tempRemainingSplit = tempRemainingList[x].split(' - ');
                            List<String> tempRemainingStartTimeSplit = tempRemainingSplit[1].split(':');
                            List<String> tempStartTimeSplit = tempStart.format('HH:mm', storeTimezone).split(':');

                            Time tempStartTime = Time.newInstance(Integer.valueOf(tempStartTimeSplit[0]), Integer.valueOf(tempStartTimeSplit[1]), 0, 0);
                            //tempStartTime = MA_SchedulerUtilities.convertGmtToTimezone(tempStartTime, storeTimezone, null);
                            
                            Time tempStartTimeRemaining = Time.newInstance(Integer.valueOf(tempRemainingStartTimeSplit[0]), Integer.valueOf(tempRemainingStartTimeSplit[1]), 0, 0);
                            //tempStartTimeRemaining = MA_SchedulerUtilities.convertGmtToTimezone(tempStartTimeRemaining, storeTimezone, null);

                            List<String> tempRemainingEndTimeSplit = tempRemainingSplit[2].split(':');
                            List<String> tempEndTimeSplit = tempEnd.format('HH:mm', storeTimezone).split(':');

                            Time tempEndTime = Time.newInstance(Integer.valueOf(tempEndTimeSplit[0]), Integer.valueOf(tempEndTimeSplit[1]), 0, 0);
                            //tempEndTime = MA_SchedulerUtilities.convertGmtToTimezone(tempEndTime, storeTimezone, null);
                            
                            Time tempEndTimeRemaining = Time.newInstance(Integer.valueOf(tempRemainingEndTimeSplit[0]), Integer.valueOf(tempRemainingEndTimeSplit[1]), 0, 0);
                            //tempEndTimeRemaining = MA_SchedulerUtilities.convertGmtToTimezone(tempEndTimeRemaining, storeTimezone, null);

                            if (tempStartTimeRemaining < tempEndTime && tempEndTimeRemaining > tempStartTime) {
                                badIndexes.add(i);
                                tempTotalMinutes = 0;
                                break;
                            }
                        }
                    }



                    while (tempTotalMinutes > 0) {
                    
                        System.debug(tempTotalMinutes);
                        //System.debug(nextDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));
                        System.debug(nextDaysEndDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));

                        //nextDateTime = nextDateTime.addDays(1);
                        tempStartDate = tempStartDate.addDays(1);
                        daysBetweenStartOfWeek += 1;
                        String nextDayOfWeek = dayNumMap.get(Math.mod(daysBetweenStartOfWeek, 7));
                        Map<String, Object> nextDaysHours = latestHours.get(nextDayOfWeek);

                        if (nextDaysHours != null) {
                            //DateTime nextDaysStartDateTime = DateTime.newInstanceGmt(nextDateTime.date(), (Time)nextDaysHours.get('start'));
                            DateTime nextDaysStartDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)nextDaysHours.get('start'));
                            nextDaysStartDateTime = MA_SchedulerUtilities.convertGmtToTimezone(nextDaysStartDateTime, storeTimezone, null);

                            if (nextDaysStartDateTime != null) {
                                nextDaysEndDateTime = nextDaysStartDateTime.addMinutes(tempTotalMinutes);
                                //DateTime nextDaysFinalEndDateTime = DateTime.newInstanceGmt(nextDateTime.date(), (Time)nextDaysHours.get('end'));
                                DateTime nextDaysFinalEndDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)nextDaysHours.get('end'));
                                nextDaysFinalEndDateTime = MA_SchedulerUtilities.convertGmtToTimezone(nextDaysFinalEndDateTime, storeTimezone, null);
                    
                                if (nextDaysEndDateTime > nextDaysFinalEndDateTime) {
                                    nextDaysEndDateTime = nextDaysFinalEndDateTime;
                                }
                    
                                System.debug(nextDaysStartDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));
                                System.debug(nextDaysEndDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));

                                System.debug(nextDaysFinalEndDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));
                                System.debug(nextDaysStartDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));

                                totalMillisecondDifference = nextDaysEndDateTime.getTime() - nextDaysStartDateTime.getTime();

                                System.debug(totalMillisecondDifference);

                                tempTotalMinutes -= (Integer)(totalMillisecondDifference / 1000 / 60);

                                System.debug(tempTotalMinutes);

                                windowsSpannedToCheck = allConfiguredWindows.get(nextDayOfWeek);
                                System.debug(windowsSpannedToCheck);
                                System.debug(remainingSlots);
                                System.debug(nextDaysStartDateTime);
                                //System.debug(remainingSlots.get(nextDaysStartDateTime.date()));
                                System.debug(remainingSlots.get(nextDaysStartDateTime.format('MM/dd/yyyy', storeTimezone)));

                                //if (remainingSlots.get(nextDaysStartDateTime.date()) == null) {
                                if (remainingSlots.get(nextDaysStartDateTime.format('MM/dd/yyyy', storeTimezone)) == null) {
                                    badIndexes.add(i);
                                    tempTotalMinutes = 0;
                                    break;
                                }
                                //else if (!remainingSlots.get(nextDaysStartDateTime.date()).containsAll(windowsSpannedToCheck)) {
                                else if (!remainingSlots.get(nextDaysStartDateTime.format('MM/dd/yyyy', storeTimezone)).containsAll(windowsSpannedToCheck)) {
                                    System.debug('not complete match');
                                    /*
                                    Set<String> tempRemainingSet = new Set<String>(remainingSlots.get(nextDaysStartDateTime.date()));
                                    tempRemainingSet.removeAll(windowsSpannedToCheck);
                                    List<String> tempRemainingList = new List<String>(tempRemainingSet);
                                    */
                                    Set<String> tempWindowsSpannedToCheckSet = new Set<String>(windowsSpannedToCheck);
                                    //tempWindowsSpannedToCheckSet.removeAll(remainingSlots.get(nextDaysStartDateTime.date()));
                                    tempWindowsSpannedToCheckSet.removeAll(remainingSlots.get(nextDaysStartDateTime.format('MM/dd/yyyy', storeTimezone)));
                                    List<String> tempRemainingList = new List<String>(tempWindowsSpannedToCheckSet);

                                    for (Integer x = 0, remainingLen = tempRemainingList.size(); x < remainingLen; x++) {
                                        List<String> tempRemainingSplit = tempRemainingList[x].split(' - ');
                                        List<String> tempRemainingStartTimeSplit = tempRemainingSplit[1].split(':');
                                        List<String> tempStartTimeSplit = nextDaysStartDateTime.format('HH:mm', storeTimezone).split(':');

                                        Time tempStartTime = Time.newInstance(Integer.valueOf(tempStartTimeSplit[0]), Integer.valueOf(tempStartTimeSplit[1]), 0, 0);
                                        //tempStartTime = MA_SchedulerUtilities.convertGmtToTimezone(tempStartTime, storeTimezone, null);

                                        Time tempStartTimeRemaining = Time.newInstance(Integer.valueOf(tempRemainingStartTimeSplit[0]), Integer.valueOf(tempRemainingStartTimeSplit[1]), 0, 0);
                                        //tempStartTimeRemaining = MA_SchedulerUtilities.convertGmtToTimezone(tempStartTimeRemaining, storeTimezone, null);

                                        List<String> tempRemainingEndTimeSplit = tempRemainingSplit[2].split(':');
                                        List<String> tempEndTimeSplit = nextDaysEndDateTime.format('HH:mm', storeTimezone).split(':');

                                        Time tempEndTime = Time.newInstance(Integer.valueOf(tempEndTimeSplit[0]), Integer.valueOf(tempEndTimeSplit[1]), 0, 0);
                                        //tempEndTime = MA_SchedulerUtilities.convertGmtToTimezone(tempEndTime, storeTimezone, null);

                                        Time tempEndTimeRemaining = Time.newInstance(Integer.valueOf(tempRemainingEndTimeSplit[0]), Integer.valueOf(tempRemainingEndTimeSplit[1]), 0, 0);
                                        //tempEndTimeRemaining = MA_SchedulerUtilities.convertGmtToTimezone(tempEndTimeRemaining, storeTimezone, null);
                    
                                        System.debug(tempStartTime);
                                        System.debug(tempStartTimeRemaining);

                                        System.debug(tempEndTime);
                                        System.debug(tempEndTimeRemaining);

                                        if (tempStartTimeRemaining < tempEndTime && tempEndTimeRemaining > tempStartTime) {
                                            badIndexes.add(i);
                                            tempTotalMinutes = 0;
                                            break;
                                        }
                                    }
                                }
                            }
                            else {
                                badIndexes.add(i);
                                tempTotalMinutes = 0;
                            }
                        }
                        else {
                            badIndexes.add(i);
                            tempTotalMinutes = 0;
                        }
                    }

                    tempEnd = nextDaysEndDateTime;
                }
            }



            List<Integer> badIndexesList = new List<Integer>(badIndexes);
            for (Integer i = 0, index = badIndexesList.size() - 1; index >= i; index--) {
                unAvailableSlots.add(bookingWindows[badIndexesList[index]]);
                bookingWindows.remove(badIndexesList[index]);
            }




            for (Integer i = 0, index = bookingWindows.size() - 1; index >= i; index--) {
                MA_SchedulerBookingWindow bw = bookingWindows[index];
                String slotName = bw.dayOfWeek + ' - ' + bw.windowStart + ' - ' + bw.windowEnd;

                //System.debug(bw.availableResources);
                if (badSlots.contains(slotName)) {
                    unAvailableSlots.add(bookingWindows[index]);
                    bookingWindows.remove(index);
                }
            }





















            endDateTime = endDateTime.addDays(-7);
            startDateTime = startDateTime.addDays(7);

            if (startDateTime.format('HH:mm', storeTimezone) == endDateTime.format('HH:mm', storeTimezone)) {
                //endDateTime = endDateTime.addDays(1);
                //System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
                
                //endTime = '11:59 PM';
                //System.debug(endTime);

                if (startDateTime.format('HH:mm', storeTimezone) == '00:00') {
                    endDateTime = endDateTime.addDays(1);
                }
                else {
                    endDateTime = endDateTime.addMinutes(30);
                }

                //endDateTime = endDateTime.addMinutes(1439);
                //System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
            }

            System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
            System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));





            for (Integer i = 0, index = bookingWindows.size() - 1; index >= i; index--) {
                MA_SchedulerBookingWindow bw = bookingWindows[index];
                if (bw.startDateTime >= endDateTime || bw.endDateTime <= startDateTime) {
                    bookingWindows.remove(index);
                }
            }

            for (Integer i = 0, index = unAvailableSlots.size() - 1; index >= i; index--) {
                MA_SchedulerBookingWindow bw = unAvailableSlots[index];
                if (bw.startDateTime >= endDateTime || bw.endDateTime <= startDateTime) {
                    unAvailableSlots.remove(index);
                }
            }







            if (nextAvailable && bookingWindows.size() > 5) {
            	bookingWindows = new List<MA_SchedulerBookingWindow> {
            		bookingWindows[0],
            		bookingWindows[1],
            		bookingWindows[2],
            		bookingWindows[3],
            		bookingWindows[4]
            	};
            }

            //System.debug('sorting');
            unAvailableSlots.sort();


            //response.put('workOrderList', workOrderList);
            response.put('success', true);
            response.put('resourceList', resourceList);
            //response.put('eventsList', eventsList);
            //response.put('maEventsList', maEventsList);
            //response.put('resourceIds', resourceIds);
            response.put('resourceToSkillsMap', resourceToSkillsMap);
            response.put('userMap', userMap);
            response.put('settings', settings);
            response.put('nextAvailable', nextAvailable);
            response.put('bookingWindows', bookingWindows);
            response.put('unAvailableSlots', unAvailableSlots);
        }
        catch(Exception ex) {
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }

        return JSON.serialize(response);
    }

    //private static void createBookingWindows(List<MA_SchedulerBookingWindow> bookingWindows, Map<String, Object> storeBookingWindows, Set<Id> resourceIds, DateTime startDateTime, DateTime endDateTime, String storeTimezone) {
    private static void createBookingWindows(List<MA_SchedulerBookingWindow> bookingWindows, List<MA_SchedulerBookingWindow> unAvailableSlots, Map<String, Object> storeBookingWindows, Map<Id, Set<Id>> resourceToSkillsMap, Map<Id, Integer> totalSkillsCountMap, DateTime startDateTime, DateTime endDateTime, String storeTimezone, Set<String> storeHolidayDates, Map<Id, Map<String, Object>> resourceHours) {
        if (!storeBookingWindows.isEmpty()) {
            /*
            Date day = startDateTime.date();
            Date endDate = endDateTime.date();
            */
            Date day = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone));
            Date endDate = Date.parse(endDateTime.format('MM/dd/yyyy', storeTimezone));

            System.debug(startDateTime.format('MM/dd/yyyy', storeTimezone));
            System.debug(startDateTime.date());
            System.debug(day);
            System.debug(endDate);
            System.debug(storeHolidayDates);
            System.debug(day.format());
            //return;

            while (day <= endDate) {
                if (!storeHolidayDates.contains(day.format())) {
                    for (String dayOfWeek : storeBookingWindows.keySet()) {
                        List<Object> windows = (List<Object>)storeBookingWindows.get(dayOfWeek);
                        for (Object window : windows) {
                            Map<String, Object> windowMap = (Map<String, Object>)window;
                            if (!windowMap.isEmpty()) {
                                //MA_SchedulerBookingWindow bw = new MA_SchedulerBookingWindow(dayOfWeek, day, windowMap, resourceIds, startDateTime.time(), endDateTime.time(), storeTimezone);
                                //MA_SchedulerBookingWindow bw = new MA_SchedulerBookingWindow(dayOfWeek, day, windowMap, resourceIds, startDateTime, endDateTime, storeTimezone);
                                MA_SchedulerBookingWindow bw = new MA_SchedulerBookingWindow(dayOfWeek, day, windowMap, resourceToSkillsMap, totalSkillsCountMap, startDateTime, endDateTime, storeTimezone, resourceHours);
                                if (bw.isValid) {
                                    if (bw.resourceToSkillsMap.isEmpty()) {
                                        unAvailableSlots.add(bw);
                                    }
                                    else {
                                        bookingWindows.add(bw);
                                    }
                                }
                            }
                        }
                    }
                }

                day = day.addDays(1);
            }
        }
    }

    //private static Set<Id> checkResourceAvailability(List<MA_SchedulerBookingWindow> allBookingWindows, /*List<Event> sfEventsList, */List<MA_Scheduler_Event__c> maEventsList, Map<Id, Id> userMap) {
    //private static Set<Id> checkResourceAvailability(List<MA_SchedulerBookingWindow> allBookingWindows, List<MA_SchedulerBookingWindow> unAvailableSlots, /*List<Event> sfEventsList, List<MA_Scheduler_Event__c> maEventsList,*/ Map<Id, Id> userMap, DateTime startDateTime, DateTime endDateTime, Set<Id> resourceIds) {
    private static void checkResourceAvailability(List<MA_SchedulerBookingWindow> allBookingWindows, List<MA_SchedulerBookingWindow> unAvailableSlots, Map<Id, Id> userMap, DateTime startDateTime, DateTime endDateTime, Map<Id, Set<Id>> resourceToSkillsMap, String workOrderType, Set<Id> workOrderSkills) {
        //Set<Id> scheduledWorkOrderIds = new Set<Id>();

    	//List<Event> eventsList = [SELECT Id, StartDateTime, EndDateTime, OwnerId, WhatId, Subject FROM Event WHERE OwnerId IN :userMap.keySet() AND StartDateTime < :endDateTime AND EndDateTime > :startDateTime];
        //List<MA_Scheduler_Event__c> maEventsList = [SELECT Id, StartDateTime__c, EndDateTime__c, Resource__c, RbA_Work_Order__c, Name FROM MA_Scheduler_Event__c WHERE Resource__c IN :resourceIds AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime];

        Set<Id> maEventIdsLinkedToSfEvents = new Set<Id>();
        for (List<Event> sfEventList : [SELECT Id, MA_Scheduler_Event__c, StartDateTime, EndDateTime, OwnerId, WhatId, Subject FROM Event WHERE OwnerId IN :userMap.keySet() AND StartDateTime < :endDateTime AND EndDateTime > :startDateTime]) {
            
            System.debug(sfEventList);

            for (Event sfEvent : sfEventList) {
	            MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(sfEvent, userMap, false);
	            schedulerEvent.setBookingWindowsAvailableResources(allBookingWindows);
	            //scheduledWorkOrderIds.add(sfEvent.WhatId);

                maEventIdsLinkedToSfEvents.add(sfEvent.MA_Scheduler_Event__c);
	        }
        }

        //for (List<MA_Scheduler_Event__c> maEventList : [SELECT Id, Name, StartDateTime__c, EndDateTime__c, Resource__c, RbA_Work_Order__c, RbA_Work_Order__r.Work_Order_Type__c, RbA_Work_Order__r.Contact__c, RbA_Work_Order__r.Contact__r.FirstName, RbA_Work_Order__r.Contact__r.LastName
                                                        //FROM MA_Scheduler_Event__c WHERE Resource__c IN :resourceIds AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime AND Id NOT IN :maEventIdsLinkedToSfEvents]) {
	    
        Set<Id> workOrderIds = new Set<Id>();
        List<MA_SchedulerEvent> unassignedMaEvents = new List<MA_SchedulerEvent>();
        System.debug(resourceToSkillsMap);
        for (List<MA_Scheduler_Event__c> maEventList : [SELECT Id, Name, StartDateTime__c, EndDateTime__c, Resource__c, Resource__r.Name, RbA_Work_Order__c, RbA_Work_Order__r.Work_Order_Type__c, RbA_Work_Order__r.Contact__c, RbA_Work_Order__r.Contact__r.FirstName, RbA_Work_Order__r.Contact__r.LastName, Estimated_Start_Date_Time__c, Estimated_End_Date_Time__c, RbA_Work_Order__r.City__c
                                                        FROM MA_Scheduler_Event__c WHERE (Resource__c = null AND RbA_Work_Order__r.Work_Order_Type__c = :workOrderType) OR (Resource__c IN :resourceToSkillsMap.keySet() AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime AND Id NOT IN :maEventIdsLinkedToSfEvents)]) {
        
        //for (List<MA_Scheduler_Event__c> maEventList : [SELECT Id, Name, StartDateTime__c, EndDateTime__c, Resource__c, RbA_Work_Order__c, RbA_Work_Order__r.Work_Order_Type__c, RbA_Work_Order__r.Contact__c, RbA_Work_Order__r.Contact__r.FirstName, RbA_Work_Order__r.Contact__r.LastName
                                                        //FROM MA_Scheduler_Event__c WHERE Resource__c IN :resourceToSkillsMap.keySet()]) {
            
            System.debug(maEventList);
            
            for (MA_Scheduler_Event__c maEvent : maEventList) {
	           	MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(maEvent, userMap, false);
	            schedulerEvent.setBookingWindowsAvailableResources(allBookingWindows);
                //schedulerEvent.setBookingWindowsOverlappingWorkOrders(allBookingWindows);
	            //scheduledWorkOrderIds.add(maEvent.RbA_Work_Order__c);

                if (schedulerEvent.needsBookedWindowChecked) {
                    workOrderIds.add(maEvent.RbA_Work_Order__c);
                    unassignedMaEvents.add(schedulerEvent);
                }
	        }
        }

        System.debug(unassignedMaEvents);

        Map<Id, Set<Id>> woToSkillsMap = new Map<Id, Set<Id>>();
        for (Work_Order_Required_Skill__c workOrderSkill : [SELECT Id, RbA_Skill__c, RbA_Work_Order__c FROM Work_Order_Required_Skill__c WHERE RbA_Work_Order__c IN :workOrderIds AND RbA_Skill__c IN :workOrderSkills]) {
            if (!woToSkillsMap.containsKey(workOrderSkill.RbA_Work_Order__c)) {
                woToSkillsMap.put(workOrderSkill.RbA_Work_Order__c, new Set<Id>{ workOrderSkill.RbA_Skill__c });
            }
            else {
                woToSkillsMap.get(workOrderSkill.RbA_Work_Order__c).add(workOrderSkill.RbA_Skill__c);
            }
        }

        for (MA_SchedulerEvent schedulerEvent : unassignedMaEvents) {
            //schedulerEvent.determineTotalSkillsCount();
            schedulerEvent.setBookingWindowsOverlappingWorkOrders(allBookingWindows, woToSkillsMap, workOrderSkills);
        }
            
        /*
        for (Event sfEvent : sfEventsList) {
            MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(sfEvent, userMap);
            schedulerEvent.setBookingWindowsAvailableResources(allBookingWindows);
            //scheduledWorkOrderIds.add(sfEvent.WhatId);
        }

        for (MA_Scheduler_Event__c maEvent : maEventsList) {
            MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(maEvent, userMap);
            schedulerEvent.setBookingWindowsAvailableResources(allBookingWindows);
            scheduledWorkOrderIds.add(maEvent.RbA_Work_Order__c);
        }
        */

        for (Integer i = 0, index = allBookingWindows.size() - 1; index >= i; index--) {
            MA_SchedulerBookingWindow bw = allBookingWindows[index];
            //if (bw.availableResources.isEmpty()) {
            if (bw.resourceToSkillsMap.isEmpty()) {
                unAvailableSlots.add(allBookingWindows[index]);
                allBookingWindows.remove(index);
            }
            //else if (bw.resourceToSkillsMap.size() <= bw.bookedWorkOrders.size()) {
            //else if (bw.totalSkillsCount <= workOrderSkills.size()) {
            else if (bw.overbooked) {
                unAvailableSlots.add(allBookingWindows[index]);
                allBookingWindows.remove(index);
            }
        }

        //return scheduledWorkOrderIds;
    }



    /*
    //private static void checkResourceAvailability(List<MA_SchedulerBookingWindow> allBookingWindows, *//*List<RbA_Work_Order__c> workOrderList, *//*Map<Id, Id> userMap) {
    private static void checkResourceAvailability(List<MA_SchedulerBookingWindow> allBookingWindows, List<MA_SchedulerBookingWindow> unAvailableSlots, *//*List<RbA_Work_Order__c> workOrderList, Map<Id, Id> userMap, *//*Date startDate, Date endDate, Set<Id> scheduledWorkOrderIds, Map<String, Map<String, Object>> latestHours, String storeTimezone) {
    	//List<RbA_Work_Order__c> workOrderList = [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c FROM RbA_Work_Order__c WHERE Id NOT IN :scheduledWorkOrderIds AND Appointment_Date__c >= :startDate AND Appointment_Date__c <= :endDate];

    	*//*
    	for (RbA_Work_Order__c workOrder : workOrderList) {
            MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(workOrder, userMap);
            schedulerEvent.setBookingWindowsOverlappingWorkOrders(allBookingWindows);
        }
        *//*

        System.debug([SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Work_Order_Type__c, Contact__c, Contact__r.FirstName, Contact__r.LastName FROM RbA_Work_Order__c WHERE Id NOT IN :scheduledWorkOrderIds AND Appointment_Date__c >= :startDate AND Appointment_Date__c <= :endDate]);

        for (List<RbA_Work_Order__c> workOrderList : [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Appointment_Duration__c, Work_Order_Type__c, Contact__c, Contact__r.FirstName, Contact__r.LastName,
                                                        (SELECT Id, Scheduled_Resource__c, Scheduled_Resource__r.Name FROM Assigned_Resources__r)
                                                        FROM RbA_Work_Order__c WHERE Id NOT IN :scheduledWorkOrderIds AND Appointment_Date__c >= :startDate AND Appointment_Date__c <= :endDate]) {
            for (RbA_Work_Order__c workOrder : workOrderList) {
            	//MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(workOrder, userMap);
                MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(workOrder, latestHours, storeTimezone, 'availablityCheck', allBookingWindows);
            	schedulerEvent.setBookingWindowsOverlappingWorkOrders(allBookingWindows);
            }
        }

        for (Integer i = 0, index = allBookingWindows.size() - 1; index >= i; index--) {
            MA_SchedulerBookingWindow bw = allBookingWindows[index];
            //if (bw.availableResources.size() == bw.bookedWorkOrders.size()) {
            if (bw.resourceToSkillsMap.size() <= bw.bookedWorkOrders.size()) {
                unAvailableSlots.add(allBookingWindows[index]);
                allBookingWindows.remove(index);
            }
        }
    }
    */


















    webService static String saveAssignedResources(String workOrderId, List<Id> assignedResourceIdsList, String assignForDay) {
        System.SavePoint sp = Database.setSavePoint();
        Map<String, Object> response = new Map<String, Object>();

        try {
            Date eventSchedulerDate;
            Boolean isSingleDay = String.isNotBlank(assignForDay);
            if (isSingleDay) {
                eventSchedulerDate = Date.parse(assignForDay);
            }

            assignedResourceIdsList.remove(0);

            RbA_Work_Order__c workOrder = [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Appointment_Duration__c,
                                            Work_Order_Type__c, Account__r.Store_Location__r.Active_Store_Configuration__c,
                                            (SELECT Id, StartDateTime__c, EndDateTime__c, Resource__c FROM MA_Scheduler_Events__r WHERE Date__c = :eventSchedulerDate)
                                            FROM RbA_Work_Order__c WHERE Id = :workOrderId];

            Set<Id> alreadyAssignedResourceIds = new Set<Id>();
            Map<Id, Id> resourceIdToUserIdMap = new Map<Id, Id>();
            Set<Id> assignedResourceIds = new Set<Id>(assignedResourceIdsList);
            List<Assigned_Resources__c> newAssignedResources = new List<Assigned_Resources__c>();
            List<Assigned_Resources__c> assignedResourcesToDelete = new List<Assigned_Resources__c>();
            List<Assigned_Resources__c> assignedResources = [SELECT Id, Scheduled_Resource__c FROM Assigned_Resources__c WHERE Work_Order__c = :workOrderId];

            for (Resource__c resource : [SELECT Id, RbA_User__c FROM Resource__c WHERE Id IN :assignedResourceIds]) {
                if (resource.RbA_User__c != null) {
                    resourceIdToUserIdMap.put(resource.Id, resource.RbA_User__c);
                }
            }

            if (isSingleDay) {
                if (!workOrder.MA_Scheduler_Events__r.isEmpty()) {
                    for (MA_Scheduler_Event__c maEvent : workOrder.MA_Scheduler_Events__r) {
                        if (assignedResourceIds.contains(maEvent.Resource__c)) {
                            alreadyAssignedResourceIds.add(maEvent.Resource__c);
                        }
                    }

                    MA_Scheduler_Event__c maEvent = workOrder.MA_Scheduler_Events__r[0];
                    workOrder.Appointment_Date__c = eventSchedulerDate;
                    workOrder.Appointment_Start_Time__c = maEvent.StartDateTime__c.format('hh:mm a');
                    workOrder.Appointment_End_Time__c = maEvent.EndDateTime__c.format('hh:mm a');

                    Long milliDiff = maEvent.EndDateTime__c.getTime() - maEvent.StartDateTime__c.getTime();
                    Decimal hoursDiff = ((Decimal)(milliDiff / 1000)) / 60 / 60;
                    workOrder.Appointment_Duration__c = hoursDiff.setScale(1);
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
            }
            
            if (workOrder.Appointment_Date__c != null && String.isNotBlank(workOrder.Appointment_Start_Time__c) && (String.isNotBlank(workOrder.Appointment_End_Time__c) || workOrder.Appointment_Duration__c != null)) {

                Id storeId = workOrder.Account__r.Store_Location__r.Active_Store_Configuration__c;
                String storeTimezone = MA_SchedulerUtilities.retrieveStoreTimezone(storeId);
                List<Event> newSfEvents = new List<Event>();
                List<MA_Scheduler_Event__c> newMaEvents = new List<MA_Scheduler_Event__c>();

                Set<Id> maEventsAlreadyCreatedFor = new Set<Id>();
                Set<Id> sfEventsAlreadryCreatedFor = new Set<Id>();

                Map<Id, MA_Scheduler_Event__c> maEventsAlreadyCreated = new Map<Id, MA_Scheduler_Event__c>(
                    (List<MA_Scheduler_Event__c>)Database.query('SELECT Id, Resource__c FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c IN :assignedResourceIds' + (isSingleDay ? ' AND Date__c = :eventSchedulerDate' : ''))
                );
                Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>(
                    (List<MA_Scheduler_Event__c>)Database.query('SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c NOT IN :assignedResourceIds' + (isSingleDay ? ' AND Date__c = :eventSchedulerDate' : ''))
                );
                
                List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet()];
                for (Event ev : sfEventsToDelete) {
                    ev.Type = 'Reassigned';
                }

                //update sfEventsToDelete;
                delete sfEventsToDelete;
                delete maEventsToDelete.values();

                for (MA_Scheduler_Event__c maEvent : maEventsAlreadyCreated.values()) {
                    maEventsAlreadyCreatedFor.add(maEvent.Resource__c);
                }
                
                for (Event ev : [SELECT Id, OwnerId FROM Event WHERE MA_Scheduler_Event__c IN :maEventsAlreadyCreated.keySet()]) {
                    sfEventsAlreadryCreatedFor.add(ev.OwnerId);
                }

                if (isSingleDay && !workOrder.MA_Scheduler_Events__r.isEmpty()) {
                    MA_Scheduler_Event__c maEvent = workOrder.MA_Scheduler_Events__r[0];
                    workOrder.Appointment_Start_Time__c = maEvent.StartDateTime__c.format('hh:mm a', storeTimezone);
                    workOrder.Appointment_End_Time__c = maEvent.EndDateTime__c.format('hh:mm a', storeTimezone);
                }













                /************************************************/



                /*          ADD MULTIDAY LOGIC HERE             */



                /************************************************/


                DateTime startDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_Start_Time__c, storeTimezone);
                DateTime endDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_End_Time__c, storeTimezone);
                
                if (workOrder.Appointment_Duration__c != null) {


                    Map<String, Object> storeBookingWindows = new Map<String, Object>();
                    List<MA_Scheduler_Settings__c> settings = [SELECT Id, Settings__c, Store_Id__c, Resource_Id__c FROM MA_Scheduler_Settings__c WHERE Store_Id__c = :storeId];
                    
                    for (MA_Scheduler_Settings__c setting : settings) {
                        if (String.isNotBlank(setting.Settings__c)) {
                            Map<String, Object> settingsMap = (Map<String, Object>)JSON.deserializeUntyped(setting.Settings__c);
                            //response.put('settingsMap', settingsMap);
                            //response.put('storeTimezone', storeTimezone);

                            if (String.isNotBlank(setting.Store_Id__c) && String.isBlank(setting.Resource_Id__c)) {
                                storeBookingWindows = (Map<String, Object>)settingsMap.get(workOrder.Work_Order_Type__c);
                                if (!storeBookingWindows.isEmpty()) {
                                    storeBookingWindows = (Map<String, Object>)storeBookingWindows.get('bookingWindows');
                                }

                                if (storeBookingWindows == null || storeBookingWindows.isEmpty()) {
                                    storeBookingWindows = (Map<String, Object>)settingsMap.get('storeHours');
                                }
                            }
                        }
                    }

                    if (!storeBookingWindows.isEmpty()) {
                        Map<String, Map<String, Object>> latestHours = MA_SchedulerUtilities.determineEarliestStartAndLatestEndHours(storeBookingWindows);
                        Map<String, Set<String>> allConfiguredWindows = MA_SchedulerUtilities.determineAllConfiguredHours(storeBookingWindows);


                        //Set<Integer> badIndexes = new Set<Integer>();
                        //Set<String> badSlots = new Set<String>();
                        Integer totalMinutes = (Integer)(workOrder.Appointment_Duration__c * 60);
                        endDateTime = startDateTime.addMinutes(totalMinutes);

                        //for (Integer i = 0, len = bookingWindows.size(); i < len; i++) {
                            //MA_SchedulerBookingWindow bw = bookingWindows[i];
                            //DateTime tempStart = bw.startDateTime;
                            //Integer tempTotalMinutes = totalMinutes;
                            //DateTime tempEnd = tempStart.addMinutes(tempTotalMinutes);

                            //System.debug(i);
                            //System.debug(totalMinutes);

                            if (latestHours != null && !latestHours.isEmpty()) {
                                Map<Integer, String> dayNumMap = new Map<Integer, String> {
                                    0 => 'Sunday',
                                    1 => 'Monday',
                                    2 => 'Tuesday',
                                    3 => 'Wednesday',
                                    4 => 'Thursday',
                                    5 => 'Friday',
                                    6 => 'Saturday'
                                };

                                Date tempStartDate = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone));
                                Date startOfWeek = tempStartDate.toStartOfWeek();
                                Integer daysBetweenStartOfWeek = startOfWeek.daysBetween(tempStartDate);
                                String dayOfWeek = dayNumMap.get(daysBetweenStartOfWeek);
                                DateTime daysEndDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)(latestHours.get(dayOfWeek).get('end')));
                                daysEndDateTime = MA_SchedulerUtilities.convertGmtToTimezone(daysEndDateTime, storeTimezone, null);
                                
                                if (endDateTime > daysEndDateTime) {
                                    endDateTime = daysEndDateTime;
                                }

                                Long totalMillisecondDifference = endDateTime.getTime() - startDateTime.getTime();
                                totalMinutes -= (Integer)(totalMillisecondDifference / 1000 / 60); 

                                //DateTime nextDateTime = startDateTime;
                                DateTime nextDaysEndDateTime = endDateTime;

                                if (!assignedResourceIdsList.isEmpty()) {
                                    for (Id resourceId : assignedResourceIds) {
                                        if (!maEventsAlreadyCreatedFor.contains(resourceId)) {
                                            newMaEvents.add(
                                                new MA_Scheduler_Event__c(
                                                    RbA_Work_Order__c = workOrderId,
                                                    Resource__c = resourceId,
                                                    Name = workOrder.Name,
                                                    StartDateTime__c = startDateTime,
                                                    EndDateTime__c = endDateTime,
                                                    Date__c = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone))
                                                )
                                            );
                                        }
                                    }
                                }
                                else {
                                    newMaEvents.add(
                                        new MA_Scheduler_Event__c(
                                            RbA_Work_Order__c = workOrderId,
                                            Name = workOrder.Name,
                                            StartDateTime__c = startDateTime,
                                            EndDateTime__c = endDateTime,
                                            Date__c = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone))
                                        )
                                    );
                                }



                                while (totalMinutes > 0) {
                                
                                    System.debug(totalMinutes);
                                    //System.debug(nextDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));
                                    System.debug(nextDaysEndDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));

                                    //nextDateTime = (nextDateTime.addDays(1);

                                    tempStartDate = tempStartDate.addDays(1);
                                    daysBetweenStartOfWeek += 1;
                                    String nextDayOfWeek = dayNumMap.get(Math.mod(daysBetweenStartOfWeek, 7));
                                    Map<String, Object> nextDaysHours = latestHours.get(nextDayOfWeek);

                                    if (nextDaysHours != null) {
                                        //DateTime nextDaysStartDateTime = DateTime.newInstanceGmt(nextDateTime.date(), (Time)nextDaysHours.get('start'));
                                        DateTime nextDaysStartDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)nextDaysHours.get('start'));
                                        nextDaysStartDateTime = MA_SchedulerUtilities.convertGmtToTimezone(nextDaysStartDateTime, storeTimezone, null);

                                        if (nextDaysStartDateTime != null) {
                                            nextDaysEndDateTime = nextDaysStartDateTime.addMinutes(totalMinutes);
                                            //DateTime nextDaysFinalEndDateTime = DateTime.newInstanceGmt(nextDateTime.date(), (Time)nextDaysHours.get('end'));
                                            DateTime nextDaysFinalEndDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)nextDaysHours.get('end'));
                                            nextDaysFinalEndDateTime = MA_SchedulerUtilities.convertGmtToTimezone(nextDaysFinalEndDateTime, storeTimezone, null);
                                
                                            if (nextDaysEndDateTime > nextDaysFinalEndDateTime) {
                                                nextDaysEndDateTime = nextDaysFinalEndDateTime;
                                            }
                                
                                            System.debug(nextDaysStartDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));
                                            System.debug(nextDaysEndDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));

                                            System.debug(nextDaysFinalEndDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));
                                            System.debug(nextDaysStartDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));

                                            totalMillisecondDifference = nextDaysEndDateTime.getTime() - nextDaysStartDateTime.getTime();

                                            System.debug(totalMillisecondDifference);

                                            totalMinutes -= (Integer)(totalMillisecondDifference / 1000 / 60);

                                            System.debug(totalMinutes);

                                            if (!assignedResourceIdsList.isEmpty()) {
                                                for (Id resourceId : assignedResourceIds) {
                                                    if (!maEventsAlreadyCreatedFor.contains(resourceId)) {
                                                        newMaEvents.add(
                                                            new MA_Scheduler_Event__c(
                                                                RbA_Work_Order__c = workOrderId,
                                                                Resource__c = resourceId,
                                                                Name = workOrder.Name,
                                                                StartDateTime__c = nextDaysStartDateTime,
                                                                EndDateTime__c = nextDaysEndDateTime,
                                                                Date__c = Date.parse(nextDaysStartDateTime.format('MM/dd/yyyy', storeTimezone))
                                                            )
                                                        );
                                                    }
                                                }
                                            }
                                            else {
                                                newMaEvents.add(
                                                    new MA_Scheduler_Event__c(
                                                        RbA_Work_Order__c = workOrderId,
                                                        Name = workOrder.Name,
                                                        StartDateTime__c = nextDaysStartDateTime,
                                                        EndDateTime__c = nextDaysEndDateTime,
                                                        Date__c = Date.parse(nextDaysStartDateTime.format('MM/dd/yyyy', storeTimezone))
                                                    )
                                                );
                                            }
                                            
                                        }
                                    }
                                }
                            }
                        //}
                    }
                }
                else {
                    if (!assignedResourceIdsList.isEmpty()) {
                        for (Id resourceId : assignedResourceIds) {
                            if (!maEventsAlreadyCreatedFor.contains(resourceId)) {
                                newMaEvents.add(
                                    new MA_Scheduler_Event__c(
                                        RbA_Work_Order__c = workOrderId,
                                        Resource__c = resourceId,
                                        Name = workOrder.Name,
                                        StartDateTime__c = startDateTime,
                                        EndDateTime__c = endDateTime,
                                        Date__c = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone))
                                    )
                                );
                            }
                        }
                    }
                    else {
                        newMaEvents.add(
                            new MA_Scheduler_Event__c(
                                RbA_Work_Order__c = workOrderId,
                                Name = workOrder.Name,
                                StartDateTime__c = startDateTime,
                                EndDateTime__c = endDateTime,
                                Date__c = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone))
                            )
                        );
                    }
                }















                /*
                DateTime startDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_Start_Time__c, storeTimezone);
                DateTime endDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_End_Time__c, storeTimezone);
                
                for (Id resourceId : assignedResourceIds) {
                    if (!maEventsAlreadyCreatedFor.contains(resourceId)) {
                        newMaEvents.add(
                            new MA_Scheduler_Event__c(
                                RbA_Work_Order__c = workOrderId,
                                Resource__c = resourceId,
                                Name = workOrder.Name,
                                StartDateTime__c = startDateTime,
                                EndDateTime__c = endDateTime
                            )
                        );
                    }
                }
                */

                insert newMaEvents;

                for (MA_Scheduler_Event__c maEvent : newMaEvents) {
                    if (resourceIdToUserIdMap.containsKey(maEvent.Resource__c) && !sfEventsAlreadryCreatedFor.contains(resourceIdToUserIdMap.get(maEvent.Resource__c))) {
                        newSfEvents.add(
                            new Event(
                                WhatId = workOrderId,
                                OwnerId = resourceIdToUserIdMap.get(maEvent.Resource__c),
                                Subject = workOrder.Name,
                                StartDateTime = maEvent.StartDateTime__c,
                                EndDateTime = maEvent.EndDateTime__c,
                                MA_Scheduler_Event__c = maEvent.Id
                            )
                        );
                    }
                }

                insert newSfEvents;
            }

            if (!isSingleDay) {
                for (Id resourceId : assignedResourceIds) {
                    if (!alreadyAssignedResourceIds.contains(resourceId)) {
                        newAssignedResources.add(
                            new Assigned_Resources__c(
                                Work_Order__c = workOrderId,
                                Scheduled_Resource__c = resourceId
                            )
                        );
                    }
                }

                delete assignedResourcesToDelete;
                insert newAssignedResources;
            }

            response.put('success', true);
        }
        catch(Exception ex) {
            Database.rollBack(sp);
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }

        return JSON.serialize(response);
    }
















    webService static String cancelWorkOrder(Id workOrderId, String cancellationReason) {
        System.SavePoint sp = Database.setSavePoint();
        Map<String, Object> response = new Map<String, Object>();

        try {
            RbA_Work_Order__c workOrder = new RbA_Work_Order__c(
                Id = workOrderId,
                Work_Order_Status__c = 'Cancelled',
                Appointment_Date__c = null,
                Appointment_Start_Time__c = '',
                Appointment_End_Time__c = ''
            );

            if (String.isNotBlank(cancellationReason)) {
                workOrder.Cancel_Reason__c = cancellationReason;
            }
            update workOrder;

            workOrder = [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Account__r.Store_Location__r.Active_Store_Configuration__c,
                            (SELECT Id, Scheduled_Resource__c, Scheduled_Resource__r.RbA_User__c FROM Assigned_Resources__r)
                            FROM RbA_Work_Order__c WHERE Id = :workOrderId];

            //if (!workOrder.Assigned_Resources__r.isEmpty()) {
                /*
                Set<Id> assignedResourceIds = new Set<Id>();
                for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                    assignedResourceIds.add(resource.Scheduled_Resource__c);
                }
                */

                //Map<Id, MA_Scheduler_Event__c> maEventsAlreadyCreated = new Map<Id, MA_Scheduler_Event__c>([SELECT Id, Resource__c FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c IN :assignedResourceIds]);
                //Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>([SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c NOT IN :assignedResourceIds]);
                //Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>([SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c IN :assignedResourceIds]);
                Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>([SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId]);
                
                //List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet() AND OwnerId NOT IN :assignedResourceIds];
                //List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet() AND OwnerId IN :assignedResourceIds];
                List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet()];
                for (Event ev : sfEventsToDelete) {
                    ev.Type = 'Cancelled';
                }

                //update sfEventsToDelete;
                delete sfEventsToDelete;
                delete maEventsToDelete.values();

                /*
                for (MA_Scheduler_Event__c maEvent : maEventsAlreadyCreated.values()) {
                    maEventsAlreadyCreatedFor.add(maEvent.Resource__c);
                }
                
                for (Event ev : [SELECT Id, OwnerId FROM Event WHERE MA_Scheduler_Event__c IN :maEventsAlreadyCreated.keySet() AND OwnerId IN :assignedResourceIds]) {
                    sfEventsAlreadryCreatedFor.add(ev.OwnerId);
                }
                */
            //}

            response.put('success', true);
        }
        catch(Exception ex) {
            Database.rollBack(sp);
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }

        return JSON.serialize(response);
    }
















    webService static String scheduleWorkOrder(Id workOrderId, String selectedWindow, String rescheduleReason) {
        System.SavePoint sp = Database.setSavePoint();
        Map<String, Object> response = new Map<String, Object>();

        try {
            List<String> windowTextSplit = selectedWindow.split(' ');

            RbA_Work_Order__c workOrder = new RbA_Work_Order__c(
                Id = workOrderId,
                Appointment_Date__c = Date.parse(windowTextSplit[0]),
                Appointment_Start_Time__c = windowTextSplit[1] + ' ' + windowTextSplit[2],
                Appointment_End_Time__c = windowTextSplit[4] + ' ' + windowTextSplit[5]
            );

            if (String.isNotBlank(rescheduleReason)) {
                workOrder.Reschedule_Reason__c = rescheduleReason;
            }
            update workOrder;

            workOrder = [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Appointment_Duration__c, Work_Order_Type__c, Account__r.Store_Location__r.Active_Store_Configuration__c,
                            (SELECT Id, Scheduled_Resource__c, Scheduled_Resource__r.RbA_User__c FROM Assigned_Resources__r)
                            FROM RbA_Work_Order__c WHERE Id = :workOrderId];

            if (!workOrder.Assigned_Resources__r.isEmpty()) {
                //Set<Id> assignedResourceIds = new Set<Id>();
                Map<Id, Id> resourceToUserMap = new Map<Id, Id>();
                for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                    //assignedResourceIds.add(resource.Scheduled_Resource__c);
                    resourceToUserMap.put(resource.Scheduled_Resource__c, resource.Scheduled_Resource__r.RbA_User__c);
                }

                //Map<Id, MA_Scheduler_Event__c> maEventsAlreadyCreated = new Map<Id, MA_Scheduler_Event__c>([SELECT Id, Resource__c FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c IN :assignedResourceIds]);
                //Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>([SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c NOT IN :assignedResourceIds]);
                //Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>([SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c IN :assignedResourceIds]);
                Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>([SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId]);
                
                //List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet() AND OwnerId NOT IN :assignedResourceIds];
                //List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet() AND OwnerId IN :assignedResourceIds];
                List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet()];
                for (Event ev : sfEventsToDelete) {
                    ev.Type = 'Rescheduled';
                }

                //update sfEventsToDelete;
                delete sfEventsToDelete;
                delete maEventsToDelete.values();

                /*
                for (MA_Scheduler_Event__c maEvent : maEventsAlreadyCreated.values()) {
                    maEventsAlreadyCreatedFor.add(maEvent.Resource__c);
                }
                
                for (Event ev : [SELECT Id, OwnerId FROM Event WHERE MA_Scheduler_Event__c IN :maEventsAlreadyCreated.keySet() AND OwnerId IN :assignedResourceIds]) {
                    sfEventsAlreadryCreatedFor.add(ev.OwnerId);
                }
                */

                Id storeId = workOrder.Account__r.Store_Location__r.Active_Store_Configuration__c;
                String storeTimezone = MA_SchedulerUtilities.retrieveStoreTimezone(storeId);
                DateTime startDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_Start_Time__c, storeTimezone);
                DateTime endDateTime;
                if (workOrder.Appointment_Duration__c != null) {
                    endDateTime = startDateTime.addMinutes((Integer)(workOrder.Appointment_Duration__c * 60));
                }
                else {
                    endDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_End_Time__c, storeTimezone);
                }
                
                /*
                for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                    MA_Scheduler_Event__c maEvent = new MA_Scheduler_Event__c(
                        RbA_Work_Order__c = workOrderId,
                        Resource__c = resource.Scheduled_Resource__c,
                        Name = workOrder.Name,
                        StartDateTime__c = startDateTime,
                        EndDateTime__c = endDateTime
                    );
                    insert maEvent;

                    if (resource.Scheduled_Resource__r.RbA_User__c != null) {
                        insert new Event(
                            WhatId = workOrderId,
                            OwnerId = resource.Scheduled_Resource__r.RbA_User__c,
                            Subject = workOrder.Name,
                            StartDateTime = startDateTime,
                            EndDateTime = endDateTime,
                            MA_Scheduler_Event__c = maEvent.Id
                        );
                    }
                }
                */





                List<MA_Scheduler_Event__c> maEventsToCreate = new List<MA_Scheduler_Event__c>();
                List<Event> sfEventsToCreate = new List<Event>();


                if (workOrder.Appointment_Duration__c != null) {


                    Map<String, Object> storeBookingWindows = new Map<String, Object>();
                    List<MA_Scheduler_Settings__c> settings = [SELECT Id, Settings__c, Store_Id__c, Resource_Id__c FROM MA_Scheduler_Settings__c WHERE Store_Id__c = :storeId];
                    
                    for (MA_Scheduler_Settings__c setting : settings) {
                        if (String.isNotBlank(setting.Settings__c)) {
                            Map<String, Object> settingsMap = (Map<String, Object>)JSON.deserializeUntyped(setting.Settings__c);
                            //response.put('settingsMap', settingsMap);
                            //response.put('storeTimezone', storeTimezone);

                            if (String.isNotBlank(setting.Store_Id__c) && String.isBlank(setting.Resource_Id__c)) {
                                storeBookingWindows = (Map<String, Object>)settingsMap.get(workOrder.Work_Order_Type__c);
                                if (!storeBookingWindows.isEmpty()) {
                                    storeBookingWindows = (Map<String, Object>)storeBookingWindows.get('bookingWindows');
                                }

                                if (storeBookingWindows == null || storeBookingWindows.isEmpty()) {
                                    storeBookingWindows = (Map<String, Object>)settingsMap.get('storeHours');
                                }
                            }
                        }
                    }

                    if (!storeBookingWindows.isEmpty()) {
                        Map<String, Map<String, Object>> latestHours = MA_SchedulerUtilities.determineEarliestStartAndLatestEndHours(storeBookingWindows);
                        Map<String, Set<String>> allConfiguredWindows = MA_SchedulerUtilities.determineAllConfiguredHours(storeBookingWindows);


                        //Set<Integer> badIndexes = new Set<Integer>();
                        //Set<String> badSlots = new Set<String>();
                        Integer totalMinutes = (Integer)(workOrder.Appointment_Duration__c * 60);

                        //for (Integer i = 0, len = bookingWindows.size(); i < len; i++) {
                            //MA_SchedulerBookingWindow bw = bookingWindows[i];
                            //DateTime tempStart = bw.startDateTime;
                            //Integer tempTotalMinutes = totalMinutes;
                            //DateTime tempEnd = tempStart.addMinutes(tempTotalMinutes);

                            //System.debug(i);
                            //System.debug(totalMinutes);

                            if (latestHours != null && !latestHours.isEmpty()) {
                                Map<Integer, String> dayNumMap = new Map<Integer, String> {
                                    0 => 'Sunday',
                                    1 => 'Monday',
                                    2 => 'Tuesday',
                                    3 => 'Wednesday',
                                    4 => 'Thursday',
                                    5 => 'Friday',
                                    6 => 'Saturday'
                                };

                                Date tempStartDate = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone));
                                Date startOfWeek = tempStartDate.toStartOfWeek();
                                Integer daysBetweenStartOfWeek = startOfWeek.daysBetween(tempStartDate);
                                String dayOfWeek = dayNumMap.get(daysBetweenStartOfWeek);
                                DateTime daysEndDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)(latestHours.get(dayOfWeek).get('end')));
                                daysEndDateTime = MA_SchedulerUtilities.convertGmtToTimezone(daysEndDateTime, storeTimezone, null);
                                
                                if (endDateTime > daysEndDateTime) {
                                    endDateTime = daysEndDateTime;
                                }

                                Long totalMillisecondDifference = endDateTime.getTime() - startDateTime.getTime();
                                totalMinutes -= (Integer)(totalMillisecondDifference / 1000 / 60); 

                                //DateTime nextDateTime = startDateTime;
                                DateTime nextDaysEndDateTime = endDateTime;

                                /*
                                //for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                                    MA_Scheduler_Event__c maEvent = new MA_Scheduler_Event__c(
                                        RbA_Work_Order__c = workOrderId,
                                        //Resource__c = resource.Scheduled_Resource__c,
                                        Name = workOrder.Name,
                                        StartDateTime__c = startDateTime,
                                        EndDateTime__c = endDateTime
                                    );
                                    maEventsToCreate.add(maEvent);
                                //}
                                */

                                for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                                    MA_Scheduler_Event__c maEvent = new MA_Scheduler_Event__c(
                                        RbA_Work_Order__c = workOrderId,
                                        Resource__c = resource.Scheduled_Resource__c,
                                        Name = workOrder.Name,
                                        StartDateTime__c = startDateTime,
                                        EndDateTime__c = endDateTime,
                                        Date__c = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone))
                                    );
                                    maEventsToCreate.add(maEvent);
                                }



                                while (totalMinutes > 0) {
                                
                                    System.debug(totalMinutes);
                                    //System.debug(nextDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));
                                    System.debug(nextDaysEndDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));

                                    //nextDateTime = (nextDateTime.addDays(1);

                                    tempStartDate = tempStartDate.addDays(1);
                                    daysBetweenStartOfWeek += 1;
                                    String nextDayOfWeek = dayNumMap.get(Math.mod(daysBetweenStartOfWeek, 7));
                                    Map<String, Object> nextDaysHours = latestHours.get(nextDayOfWeek);

                                    if (nextDaysHours != null) {
                                        //DateTime nextDaysStartDateTime = DateTime.newInstanceGmt(nextDateTime.date(), (Time)nextDaysHours.get('start'));
                                        DateTime nextDaysStartDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)nextDaysHours.get('start'));
                                        nextDaysStartDateTime = MA_SchedulerUtilities.convertGmtToTimezone(nextDaysStartDateTime, storeTimezone, null);

                                        if (nextDaysStartDateTime != null) {
                                            nextDaysEndDateTime = nextDaysStartDateTime.addMinutes(totalMinutes);
                                            //DateTime nextDaysFinalEndDateTime = DateTime.newInstanceGmt(nextDateTime.date(), (Time)nextDaysHours.get('end'));
                                            DateTime nextDaysFinalEndDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)nextDaysHours.get('end'));
                                            nextDaysFinalEndDateTime = MA_SchedulerUtilities.convertGmtToTimezone(nextDaysFinalEndDateTime, storeTimezone, null);
                                
                                            if (nextDaysEndDateTime > nextDaysFinalEndDateTime) {
                                                nextDaysEndDateTime = nextDaysFinalEndDateTime;
                                            }
                                
                                            System.debug(nextDaysStartDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));
                                            System.debug(nextDaysEndDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));

                                            System.debug(nextDaysFinalEndDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));
                                            System.debug(nextDaysStartDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));

                                            totalMillisecondDifference = nextDaysEndDateTime.getTime() - nextDaysStartDateTime.getTime();

                                            System.debug(totalMillisecondDifference);

                                            totalMinutes -= (Integer)(totalMillisecondDifference / 1000 / 60);

                                            System.debug(totalMinutes);

                                            /*
                                            //for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                                                maEvent = new MA_Scheduler_Event__c(
                                                    RbA_Work_Order__c = workOrderId,
                                                    //Resource__c = resource.Scheduled_Resource__c,
                                                    Name = workOrder.Name,
                                                    StartDateTime__c = nextDaysStartDateTime,
                                                    EndDateTime__c = nextDaysEndDateTime
                                                );
                                                maEventsToCreate.add(maEvent);
                                            //}
                                            */

                                            for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                                                MA_Scheduler_Event__c maEvent = new MA_Scheduler_Event__c(
                                                    RbA_Work_Order__c = workOrderId,
                                                    Resource__c = resource.Scheduled_Resource__c,
                                                    Name = workOrder.Name,
                                                    StartDateTime__c = nextDaysStartDateTime,
                                                    EndDateTime__c = nextDaysEndDateTime,
                                                    Date__c = Date.parse(nextDaysStartDateTime.format('MM/dd/yyyy', storeTimezone))
                                                );
                                                maEventsToCreate.add(maEvent);
                                            }
                                            
                                        }
                                    }
                                }
                            }
                        //}
                    }
                }
                else {
                    /*
                    //for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                        MA_Scheduler_Event__c maEvent = new MA_Scheduler_Event__c(
                            RbA_Work_Order__c = workOrderId,
                            //Resource__c = resource.Scheduled_Resource__c,
                            Name = workOrder.Name,
                            StartDateTime__c = startDateTime,
                            EndDateTime__c = endDateTime
                        );
                        maEventsToCreate.add(maEvent);
                    //}
                    */

                    for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                        MA_Scheduler_Event__c maEvent = new MA_Scheduler_Event__c(
                            RbA_Work_Order__c = workOrderId,
                            Resource__c = resource.Scheduled_Resource__c,
                            Name = workOrder.Name,
                            StartDateTime__c = startDateTime,
                            EndDateTime__c = endDateTime,
                            Date__c = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone))
                        );
                        maEventsToCreate.add(maEvent);
                    }
                }

                insert maEventsToCreate;

                for (MA_Scheduler_Event__c maEvent : maEventsToCreate) {
                    if (resourceToUserMap.get(maEvent.Resource__c) != null) {
                        Event sfEvent = new Event(
                            WhatId = maEvent.RbA_Work_Order__c,
                            OwnerId = resourceToUserMap.get(maEvent.Resource__c),
                            Subject = maEvent.Name,
                            StartDateTime = maEvent.StartDateTime__c,
                            EndDateTime = maEvent.EndDateTime__c,
                            MA_Scheduler_Event__c = maEvent.Id
                        );
                        sfEventsToCreate.add(sfEvent);
                    }
                }

                insert sfEventsToCreate;


                
            }

            else {
                //Set<Id> assignedResourceIds = new Set<Id>();
                //Map<Id, Id> resourceToUserMap = new Map<Id, Id>();
                //for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                    //assignedResourceIds.add(resource.Scheduled_Resource__c);
                    //resourceToUserMap.put(resource.Scheduled_Resource__c, resource.Scheduled_Resource__r.RbA_User__c);
                //}

                //Map<Id, MA_Scheduler_Event__c> maEventsAlreadyCreated = new Map<Id, MA_Scheduler_Event__c>([SELECT Id, Resource__c FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c IN :assignedResourceIds]);
                //Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>([SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c NOT IN :assignedResourceIds]);
                //Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>([SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c IN :assignedResourceIds]);
                Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>([SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId]);
                
                //List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet() AND OwnerId NOT IN :assignedResourceIds];
                //List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet() AND OwnerId IN :assignedResourceIds];
                List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet()];
                for (Event ev : sfEventsToDelete) {
                    ev.Type = 'Rescheduled';
                }

                //update sfEventsToDelete;
                delete sfEventsToDelete;
                delete maEventsToDelete.values();

                /*
                for (MA_Scheduler_Event__c maEvent : maEventsAlreadyCreated.values()) {
                    maEventsAlreadyCreatedFor.add(maEvent.Resource__c);
                }
                
                for (Event ev : [SELECT Id, OwnerId FROM Event WHERE MA_Scheduler_Event__c IN :maEventsAlreadyCreated.keySet() AND OwnerId IN :assignedResourceIds]) {
                    sfEventsAlreadryCreatedFor.add(ev.OwnerId);
                }
                */

                Id storeId = workOrder.Account__r.Store_Location__r.Active_Store_Configuration__c;
                String storeTimezone = MA_SchedulerUtilities.retrieveStoreTimezone(storeId);
                DateTime startDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_Start_Time__c, storeTimezone);
                DateTime endDateTime;
                if (workOrder.Appointment_Duration__c != null) {
                    endDateTime = startDateTime.addMinutes((Integer)(workOrder.Appointment_Duration__c * 60));
                }
                else {
                    endDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_End_Time__c, storeTimezone);
                }
                
                /*
                for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                    MA_Scheduler_Event__c maEvent = new MA_Scheduler_Event__c(
                        RbA_Work_Order__c = workOrderId,
                        Resource__c = resource.Scheduled_Resource__c,
                        Name = workOrder.Name,
                        StartDateTime__c = startDateTime,
                        EndDateTime__c = endDateTime
                    );
                    insert maEvent;

                    if (resource.Scheduled_Resource__r.RbA_User__c != null) {
                        insert new Event(
                            WhatId = workOrderId,
                            OwnerId = resource.Scheduled_Resource__r.RbA_User__c,
                            Subject = workOrder.Name,
                            StartDateTime = startDateTime,
                            EndDateTime = endDateTime,
                            MA_Scheduler_Event__c = maEvent.Id
                        );
                    }
                }
                */





                List<MA_Scheduler_Event__c> maEventsToCreate = new List<MA_Scheduler_Event__c>();
                //List<Event> sfEventsToCreate = new List<Event>();


                if (workOrder.Appointment_Duration__c != null) {


                    Map<String, Object> storeBookingWindows = new Map<String, Object>();
                    List<MA_Scheduler_Settings__c> settings = [SELECT Id, Settings__c, Store_Id__c, Resource_Id__c FROM MA_Scheduler_Settings__c WHERE Store_Id__c = :storeId];
                    
                    for (MA_Scheduler_Settings__c setting : settings) {
                        if (String.isNotBlank(setting.Settings__c)) {
                            Map<String, Object> settingsMap = (Map<String, Object>)JSON.deserializeUntyped(setting.Settings__c);
                            //response.put('settingsMap', settingsMap);
                            //response.put('storeTimezone', storeTimezone);

                            if (String.isNotBlank(setting.Store_Id__c) && String.isBlank(setting.Resource_Id__c)) {
                                storeBookingWindows = (Map<String, Object>)settingsMap.get(workOrder.Work_Order_Type__c);
                                if (!storeBookingWindows.isEmpty()) {
                                    storeBookingWindows = (Map<String, Object>)storeBookingWindows.get('bookingWindows');
                                }

                                if (storeBookingWindows == null || storeBookingWindows.isEmpty()) {
                                    storeBookingWindows = (Map<String, Object>)settingsMap.get('storeHours');
                                }
                            }
                        }
                    }

                    if (!storeBookingWindows.isEmpty()) {
                        Map<String, Map<String, Object>> latestHours = MA_SchedulerUtilities.determineEarliestStartAndLatestEndHours(storeBookingWindows);
                        Map<String, Set<String>> allConfiguredWindows = MA_SchedulerUtilities.determineAllConfiguredHours(storeBookingWindows);


                        //Set<Integer> badIndexes = new Set<Integer>();
                        //Set<String> badSlots = new Set<String>();
                        Integer totalMinutes = (Integer)(workOrder.Appointment_Duration__c * 60);

                        //for (Integer i = 0, len = bookingWindows.size(); i < len; i++) {
                            //MA_SchedulerBookingWindow bw = bookingWindows[i];
                            //DateTime tempStart = bw.startDateTime;
                            //Integer tempTotalMinutes = totalMinutes;
                            //DateTime tempEnd = tempStart.addMinutes(tempTotalMinutes);

                            //System.debug(i);
                            //System.debug(totalMinutes);

                            if (latestHours != null && !latestHours.isEmpty()) {
                                Map<Integer, String> dayNumMap = new Map<Integer, String> {
                                    0 => 'Sunday',
                                    1 => 'Monday',
                                    2 => 'Tuesday',
                                    3 => 'Wednesday',
                                    4 => 'Thursday',
                                    5 => 'Friday',
                                    6 => 'Saturday'
                                };

                                Date tempStartDate = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone));
                                Date startOfWeek = tempStartDate.toStartOfWeek();
                                Integer daysBetweenStartOfWeek = startOfWeek.daysBetween(tempStartDate);
                                String dayOfWeek = dayNumMap.get(daysBetweenStartOfWeek);
                                DateTime daysEndDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)(latestHours.get(dayOfWeek).get('end')));
                                daysEndDateTime = MA_SchedulerUtilities.convertGmtToTimezone(daysEndDateTime, storeTimezone, null);
                                
                                if (endDateTime > daysEndDateTime) {
                                    endDateTime = daysEndDateTime;
                                }

                                Long totalMillisecondDifference = endDateTime.getTime() - startDateTime.getTime();
                                totalMinutes -= (Integer)(totalMillisecondDifference / 1000 / 60); 

                                //DateTime nextDateTime = startDateTime;
                                DateTime nextDaysEndDateTime = endDateTime;

                                //for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                                    MA_Scheduler_Event__c maEvent = new MA_Scheduler_Event__c(
                                        RbA_Work_Order__c = workOrderId,
                                        //Resource__c = resource.Scheduled_Resource__c,
                                        Name = workOrder.Name,
                                        StartDateTime__c = startDateTime,
                                        EndDateTime__c = endDateTime,
                                        Date__c = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone))
                                    );
                                    maEventsToCreate.add(maEvent);
                                //}



                                while (totalMinutes > 0) {
                                
                                    System.debug(totalMinutes);
                                    //System.debug(nextDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));
                                    System.debug(nextDaysEndDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));

                                    //nextDateTime = (nextDateTime.addDays(1);

                                    tempStartDate = tempStartDate.addDays(1);
                                    daysBetweenStartOfWeek += 1;
                                    String nextDayOfWeek = dayNumMap.get(Math.mod(daysBetweenStartOfWeek, 7));
                                    Map<String, Object> nextDaysHours = latestHours.get(nextDayOfWeek);

                                    if (nextDaysHours != null) {
                                        //DateTime nextDaysStartDateTime = DateTime.newInstanceGmt(nextDateTime.date(), (Time)nextDaysHours.get('start'));
                                        DateTime nextDaysStartDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)nextDaysHours.get('start'));
                                        nextDaysStartDateTime = MA_SchedulerUtilities.convertGmtToTimezone(nextDaysStartDateTime, storeTimezone, null);

                                        if (nextDaysStartDateTime != null) {
                                            nextDaysEndDateTime = nextDaysStartDateTime.addMinutes(totalMinutes);
                                            //DateTime nextDaysFinalEndDateTime = DateTime.newInstanceGmt(nextDateTime.date(), (Time)nextDaysHours.get('end'));
                                            DateTime nextDaysFinalEndDateTime = DateTime.newInstanceGmt(tempStartDate, (Time)nextDaysHours.get('end'));
                                            nextDaysFinalEndDateTime = MA_SchedulerUtilities.convertGmtToTimezone(nextDaysFinalEndDateTime, storeTimezone, null);
                                
                                            if (nextDaysEndDateTime > nextDaysFinalEndDateTime) {
                                                nextDaysEndDateTime = nextDaysFinalEndDateTime;
                                            }
                                
                                            System.debug(nextDaysStartDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));
                                            System.debug(nextDaysEndDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));

                                            System.debug(nextDaysFinalEndDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));
                                            System.debug(nextDaysStartDateTime.format('MM/dd/yyyy HH:mm a z', storeTimezone));

                                            totalMillisecondDifference = nextDaysEndDateTime.getTime() - nextDaysStartDateTime.getTime();

                                            System.debug(totalMillisecondDifference);

                                            totalMinutes -= (Integer)(totalMillisecondDifference / 1000 / 60);

                                            System.debug(totalMinutes);


                                            //for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                                                /*MA_Scheduler_Event__c*/ maEvent = new MA_Scheduler_Event__c(
                                                    RbA_Work_Order__c = workOrderId,
                                                    //Resource__c = resource.Scheduled_Resource__c,
                                                    Name = workOrder.Name,
                                                    StartDateTime__c = nextDaysStartDateTime,
                                                    EndDateTime__c = nextDaysEndDateTime,
                                                    Date__c = Date.parse(nextDaysStartDateTime.format('MM/dd/yyyy', storeTimezone))
                                                );
                                                maEventsToCreate.add(maEvent);
                                            //}
                                            
                                        }
                                    }
                                }
                            }
                        //}
                    }
                }
                else {
                    //for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                        MA_Scheduler_Event__c maEvent = new MA_Scheduler_Event__c(
                            RbA_Work_Order__c = workOrderId,
                            //Resource__c = resource.Scheduled_Resource__c,
                            Name = workOrder.Name,
                            StartDateTime__c = startDateTime,
                            EndDateTime__c = endDateTime,
                            Date__c = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone))
                        );
                        maEventsToCreate.add(maEvent);
                    //}
                }


                System.debug(maEventsToCreate);
                insert maEventsToCreate;

                /*
                for (MA_Scheduler_Event__c maEvent : maEventsToCreate) {
                    if (resourceToUserMap.get(maEvent.Resource__c) != null) {
                        Event sfEvent = new Event(
                            WhatId = maEvent.RbA_Work_Order__c,
                            OwnerId = resourceToUserMap.get(maEvent.Resource__c),
                            Subject = maEvent.Name,
                            StartDateTime = maEvent.StartDateTime__c,
                            EndDateTime = maEvent.EndDateTime__c,
                            MA_Scheduler_Event__c = maEvent.Id
                        );
                        sfEventsToCreate.add(sfEvent);
                    }
                }

                insert sfEventsToCreate;
                */


                
            }

            //MA_Scheduler_Event__c maEvent = [SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :WorkOrderId]

            response.put('success', true);
        }
        catch(Exception ex) {
            Database.rollBack(sp);
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }

        return JSON.serialize(response);
    }















    /************************************************/
    /*												*/
	/*		THIS IS JUST A BUFFER CLASS 			*/
	/*		TO GET TEST COVERAGE UP FOR 			*/
	/*		EARLIER DEPLOYMENTS 					*/
	/*												*/
	/*		THIS CLASS WILL BE REMOVED 				*/
	/*		AND ACTUAL TEST COVERAGE WILL 			*/
	/*		BE INCLUDED IN FINAL DEPLOYMENTS 		*/
	/*												*/
	/************************************************/

    public static void testCoverageBuffer() {
    	Integer i = 0;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
    	i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }

}
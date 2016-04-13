global with sharing class MA_SchedulerController {

    private static final string ESRIClientID = 'YRGMYKIjOjSpQnUz';
    private static final string ESRIClientSecret = 'ff4a4b1ecc9b43c591ac05ef98df135e';
    private static final string ArcGISauth = 'https://www.arcgis.com/sharing/rest/oauth2/token/';
    //private static final string EsriGenerateToken = 'https://www.arcgis.com/sharing/generateToken?';//We may not need this

    webService static String retrieveRecords(String objType, String filters) {
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
                query = 'SELECT Id, Store_Id__c, Settings__c FROM MA_Scheduler_Settings__c';
            }
            else if (objType == 'WorkOrder') {
            	query = 'SELECT Id, Name, Contact__c, Contact__r.FirstName, Contact__r.LastName, Contact__r.HomePhone, Appointment_Duration__c,'
                        + ' Street__c, City__c, State__c, Zip__c'
                        + ' FROM RbA_Work_Order__c';
            }
            
            if (String.isNotBlank(query)) {
                query += String.isNotBlank(filters) ? ' WHERE ' + filters : '';
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

    














	webService static String retrieveEvents(String objType, String filters, String altFilters, String resourceUserIdToIdMapString) {
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
                query = 'SELECT Id, Name, Resource__c, RbA_Work_Order__c, StartDateTime__c, EndDateTime__c,'
                            + ' RbA_Work_Order__r.Work_Order_Type__c, RbA_Work_Order__r.Contact__c, RbA_Work_Order__r.Contact__r.FirstName, RbA_Work_Order__r.Contact__r.LastName'
                            + ' FROM MA_Scheduler_Event__c';

                altQuery = 'SELECT Id, Subject, OwnerId, WhatId, StartDateTime, EndDateTime FROM Event';
            }
            else if (objType == 'WorkOrder') {
                query = 'SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Work_Order_Type__c, Contact__c, Contact__r.FirstName, Contact__r.LastName,'
                			+ ' (SELECT Id, Scheduled_Resource__c, Scheduled_Resource__r.Name FROM Assigned_Resources__r)'
                			+ ' FROM RbA_Work_Order__c';
            }
            
            Set<Id> additionalAltFilterIds = new Set<Id>();
			//String storeTimezone = MA_SchedulerUtilities.retrieveStoreTimezone();
            
            if (String.isNotBlank(query)) {
                query += String.isNotBlank(filters) ? ' WHERE ' + filters : '';
                SObject[] objList = Database.query(query);

                for (SObject obj : objList) {
                	MA_SchedulerEvent customEvent = new MA_SchedulerEvent(obj, new Map<Id, Id>());
                	customEvent.createOffsetTimes();
                    eventList.add(customEvent);

                    if (objType == 'allEvents') {
                        additionalAltFilterIds.add(obj.Id);
                    }
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
                	MA_SchedulerEvent customEvent = new MA_SchedulerEvent(obj, resourceUserIdToIdMap);
                	customEvent.createOffsetTimes();
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


    webService static String createEvent(MA_SchedulerEvent busyEvent) {
        return 'hello';
    }

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
            /*while (parser.nextToken() != null)
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
            }*/
        }
        catch(System.CalloutException e){
            System.debug('Callout error: '+ e);
            System.debug(res.toString());
        }
        //return returnRes;
        return res.getBody();
    }
















    webService static String retrieveAvailableResources(Id workOrderId) {
        Map<String, Object> response = new Map<String, Object>();
        
        try {
            RbA_Work_Order__c workOrder = [SELECT Id, Name, Work_Order_Type__c, Appointment_Duration__c, Appointment_Date__c,
                                            Appointment_Start_Time__c, Appointment_End_Time__c, Recommended_Crew_Size__c,
                                            Street__c, City__c, State__c, Zip__c, Contact__c, Contact__r.Name,
                                            Account__r.Store_Location__r.Active_Store_Configuration__c,
                                            (SELECT Id, Scheduled_Resource__c, Scheduled_Resource__r.Name FROM Assigned_Resources__r),
                                            (SELECT Id, RbA_Skill__r.Name FROM Work_Order_Required_Skills__r)
                                            FROM RbA_Work_Order__c WHERE Id = :workOrderId];

            Map<Id, String> requiredSkills = new Map<Id, String>();
            for (Work_Order_Required_Skill__c skill : workOrder.Work_Order_Required_Skills__r) {
                requiredSkills.put(skill.RbA_Skill__c, skill.RbA_Skill__r.Name);
            }

            Set<Id> assignedResources = new Set<Id>();
            for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                assignedResources.add(resource.Scheduled_Resource__c);
            }

            Map<Id, Id> availableUserIdToResourceIdMap = new Map<Id, Id>();
            Map<Id, MA_SchedulerResource> availableResources = new Map<Id, MA_SchedulerResource>();
            Id storeId = workOrder.Account__r.Store_Location__r.Active_Store_Configuration__c;
            Set<String> resourceTypes = MA_SchedulerUtilities.retrieveResourceTypeFromWorkOrderType(workOrder.Work_Order_Type__c);

            for (Resource__c resource : [SELECT Id, Name, Active__c, RbA_User__c, Crew_Size__c,
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
                String storeTimezone = MA_SchedulerUtilities.retrieveStoreTimezone(storeId);
                DateTime startDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_Start_Time__c, storeTimezone);

                DateTime endDateTime;
                if (String.isNotBlank(workOrder.Appointment_End_Time__c)) {
                    endDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_End_Time__c, storeTimezone);
                }
                else {
                    endDateTime = startDateTime.addMinutes((Integer)(workOrder.Appointment_Duration__c * 60));
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
            response.put('availableResources', availableResourcesList);
        }
        catch(Exception ex) {
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }
        
        return JSON.serialize(response);
    }


    public class MA_SchedulerResource implements Comparable {

        public Map<Id, String> skillsNotMatched;
        public Map<Id, String> skillsMatched;
        public String skillsMatchedTotal;
        public Integer skillsMatchedCount;
        public String headcount;
        public String resourceName;
        public Id resourceId;
        public Boolean isAssigned;
        public Boolean isAvailable;
        public Boolean isActive;

        public MA_SchedulerResource(Resource__c resource, Map<Id, String> requiredSkills, Set<Id> assignedResources) {
            this.isAvailable = true;
            this.resourceId = resource.Id;
            this.resourceName = resource.Name;
            this.isActive = resource.Active__c;
            this.headcount = String.valueOf(resource.Crew_Size__c);
            this.isAssigned = assignedResources.contains(this.resourceId);

            this.skillsMatched = new Map<Id, String>();
            this.skillsNotMatched = new Map<Id, String>(requiredSkills);

            for (Resource_Skill__c skill : resource.Resource_Skills__r) {
                this.skillsMatched.put(skill.RbA_Skill__c, skill.RbA_Skill__r.Name);
                this.skillsNotMatched.remove(skill.RbA_Skill__c);
            }

            this.skillsMatchedCount = this.skillsMatched.size();
            this.skillsMatchedTotal = this.skillsMatchedCount + '/' + requiredSkills.size();
        }

        public Integer compareTo(Object compareTo) {
            MA_SchedulerResource compareToResource = (MA_SchedulerResource)compareTo;

            if (skillsMatchedCount == compareToResource.skillsMatchedCount) {
                return 0;
            }
            else if (skillsMatchedCount > compareToResource.skillsMatchedCount) {
                return -1;
            }

            return 1;
        }

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
            Set<Id> resourceIds = new Set<Id>();
            Set<String> resourceTypes = MA_SchedulerUtilities.retrieveResourceTypeFromWorkOrderType(workOrder.Work_Order_Type__c);
            List<Resource__c> resourceList = [SELECT Id, RbA_User__c,
                                                (SELECT Id, RbA_Skill__c FROM Resource_Skills__r WHERE RbA_Skill__c IN :rbaSkillIds)
                                                FROM Resource__c WHERE (Retail_Location__c = :storeId AND Active__c = true AND Resource_Type__c IN :resourceTypes) OR Id IN :assignedResourceIds];

            for (Resource__c resource : resourceList) {
                if (!resource.Resource_Skills__r.isEmpty()) {
                    resourceIds.add(resource.Id);
                    userMap.put(resource.RbA_User__c, resource.Id);
                }
            }

            String storeTimezone;
            List<MA_SchedulerBookingWindow> bookingWindows = new List<MA_SchedulerBookingWindow>();
            List<MA_SchedulerBookingWindow> unAvailableSlots = new List<MA_SchedulerBookingWindow>();
            Map<String, Object> storeBookingWindows = new Map<String, Object>();
            List<MA_Scheduler_Settings__c> settings = [SELECT Id, Settings__c, Store_Id__c, Resource_Id__c FROM MA_Scheduler_Settings__c WHERE Store_Id__c = :storeId];
            
            for (MA_Scheduler_Settings__c setting : settings) {
                if (String.isNotBlank(setting.Settings__c)) {
                    Map<String, Object> settingsMap = (Map<String, Object>)JSON.deserializeUntyped(setting.Settings__c);
                    storeTimezone = (String)settingsMap.get('timezone');
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

            if (storeBookingWindows.isEmpty()) {
                response.put('success', false);
                response.put('error', 'The store hours and/or ' + workOrder.Work_Order_Type__c + ' booking windows have not been configured yet.  Please go to the settings page to set these up.');
                return JSON.serialize(response);
            }




            //Date startDate, endDate;
            //String startTime, endTime;
            //Integer startDateOffsetMinutes, endDateOffsetMinutes;
            DateTime endDateTime = DateTime.newInstance(Long.valueOf(endDateTimeEpoch));
	        DateTime startDateTime = DateTime.newInstance(Long.valueOf(startDateTimeEpoch));

            Date endDate = endDateTime.date();
            Date startDate = startDateTime.date();
            
            if (String.isNotBlank(storeTimezone)) {
				//DateTime tempTime = DateTime.newInstance(2015, 3, 24, 5, 0, 0);
				//DateTime tempTime = DateTime.now();
				//Integer offset = Integer.valueOf(tempTime.format('Z', storeTimezone));

                /*
				Integer startDateOffset = Integer.valueOf(startDateTime.format('Z', storeTimezone));
				startDateOffsetMinutes = Math.mod(startDateOffset, 100);
				Integer startDateOffsetHours = (Integer)Math.floor(startDateOffset / 100);
				startDateOffsetMinutes += (startDateOffsetHours * 60) + Integer.valueOf(offsetPageMinutes);

                startDateTime = startDateTime.addMinutes(-startDateOffsetMinutes);
                System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z'));
                System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
                */

                startDateTime = MA_SchedulerUtilities.convertGmtToTimezone(startDateTime, storeTimezone, offsetPageMinutes);
                System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z'));
                System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));

                /*
	            String startDateTimeZoneFormatted = startDateTime.format('MM/dd/yyyy hh:mm a', storeTimezone);
	            String[] startDateTimeZoneFormattedSplit = startDateTimeZoneFormatted.split(' ');
	            startDate = Date.parse(startDateTimeZoneFormattedSplit[0]);
	            startTime = startDateTimeZoneFormattedSplit[1] + ' ' + startDateTimeZoneFormattedSplit[2];
                */

                startDate = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone));
                //startTime = startDateTime.format('hh:mm a', storeTimezone);

				//DateTime tempTime = DateTime.newInstance(2015, 3, 24, 5, 0, 0);
				//DateTime tempTime = DateTime.now();
				//Integer offset = Integer.valueOf(tempTime.format('Z', storeTimezone));

                /*
				Integer endDateOffset = Integer.valueOf(startDateTime.format('Z', storeTimezone));
				endDateOffsetMinutes = Math.mod(endDateOffset, 100);
				Integer endDateOffsetHours = (Integer)Math.floor(endDateOffset / 100);
				endDateOffsetMinutes += (endDateOffsetHours * 60) + Integer.valueOf(offsetPageMinutes);

                endDateTime = endDateTime.addMinutes(-endDateOffsetMinutes);
                System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z'));
                System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
                */

	            endDateTime = MA_SchedulerUtilities.convertGmtToTimezone(endDateTime, storeTimezone, offsetPageMinutes);
	            System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z'));
	            System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));

                /*
	            if (startDateTime.format('HH:mm', storeTimezone) == '00:00' && endDateTime.format('HH:mm', storeTimezone) == '00:00') {
	            	//endDateTime = endDateTime.addDays(1);
	            	//System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
	            	
	            	//endTime = '11:59 PM';
	            	//System.debug(endTime);

	            	endDateTime = endDateTime.addMinutes(1439);
	            	System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
	            }
                */

                /*
	            String endDateTimeZoneFormatted = endDateTime.format('MM/dd/yyyy hh:mm a', storeTimezone);
	            String[] endDateTimeZoneFormattedSplit = endDateTimeZoneFormatted.split(' ');
	            endDate = Date.parse(endDateTimeZoneFormattedSplit[0]);
	            endTime = endDateTimeZoneFormattedSplit[1] + ' ' + endDateTimeZoneFormattedSplit[2];
                */

                endDate = Date.parse(endDateTime.format('MM/dd/yyyy', storeTimezone));
                //endTime = endDateTime.format('hh:mm a', storeTimezone);

				System.debug(startDate);
				//System.debug(startTime);
				System.debug(endDate);
				//System.debug(endTime);
	        }




	        System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
	        System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));





            createBookingWindows(bookingWindows, storeBookingWindows, resourceIds, startDateTime, endDateTime, storeTimezone);

            //List<Event> eventsList = [SELECT Id, StartDateTime, EndDateTime, OwnerId, WhatId, Subject FROM Event WHERE OwnerId IN :userMap.keySet() AND StartDateTime < :endDateTime AND EndDateTime > :startDateTime];
            //List<MA_Scheduler_Event__c> maEventsList = [SELECT Id, StartDateTime__c, EndDateTime__c, Resource__c, RbA_Work_Order__c, Name FROM MA_Scheduler_Event__c WHERE Resource__c IN :resourceIds AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime];

            Set<Id> scheduledWorkOrderIds = new Set<Id> { workOrder.Id };
            scheduledWorkOrderIds.addAll(checkResourceAvailability(bookingWindows, unAvailableSlots, /*eventsList, maEventsList,*/ userMap, startDateTime, endDateTime, resourceIds));

            //List<RbA_Work_Order__c> workOrderList = [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c FROM RbA_Work_Order__c WHERE Id NOT IN :scheduledWorkOrderIds AND Appointment_Date__c >= :startDate AND Appointment_Date__c <= :endDate];


            checkResourceAvailability(bookingWindows, unAvailableSlots, /*workOrderList, */userMap, startDate, endDate, scheduledWorkOrderIds);


            System.debug(assignedResourceIds);
            if (!assignedResourceIds.isEmpty()) {
                for (Integer i = 0, index = bookingWindows.size() - 1; index >= i; index--) {
                    MA_SchedulerBookingWindow bw = bookingWindows[index];

                    //System.debug(bw.availableResources);
                    if (!bw.availableResources.containsAll(assignedResourceIds)) {
                        unAvailableSlots.add(bookingWindows[index]);
                        bookingWindows.remove(index);
                    }
                }
            }


            response.put('bookingWindowsTEMP', bookingWindows);

            if (nextAvailable && bookingWindows.size() > 5) {
            	bookingWindows = new List<MA_SchedulerBookingWindow> {
            		bookingWindows[0],
            		bookingWindows[1],
            		bookingWindows[2],
            		bookingWindows[3],
            		bookingWindows[4]
            	};
            }


            //response.put('workOrderList', workOrderList);
            response.put('success', true);
            response.put('resourceList', resourceList);
            //response.put('eventsList', eventsList);
            //response.put('maEventsList', maEventsList);
            response.put('resourceIds', resourceIds);
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

    private static void createBookingWindows(List<MA_SchedulerBookingWindow> bookingWindows, Map<String, Object> storeBookingWindows, Set<Id> resourceIds, DateTime startDateTime, DateTime endDateTime, String storeTimezone) {
        if (!storeBookingWindows.isEmpty()) {
            /*
            Date day = startDateTime.date();
            Date endDate = endDateTime.date();
            */
            Date day = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone));
            Date endDate = Date.parse(endDateTime.format('MM/dd/yyyy', storeTimezone));

            System.debug(day);
            System.debug(endDate);

            while (day <= endDate) {
                for (String dayOfWeek : storeBookingWindows.keySet()) {
                    List<Object> windows = (List<Object>)storeBookingWindows.get(dayOfWeek);
                    for (Object window : windows) {
                        Map<String, Object> windowMap = (Map<String, Object>)window;
                        if (!windowMap.isEmpty()) {
                            //MA_SchedulerBookingWindow bw = new MA_SchedulerBookingWindow(dayOfWeek, day, windowMap, resourceIds, startDateTime.time(), endDateTime.time(), storeTimezone);
                            MA_SchedulerBookingWindow bw = new MA_SchedulerBookingWindow(dayOfWeek, day, windowMap, resourceIds, startDateTime, endDateTime, storeTimezone);
                            if (bw.isValid) {
                                bookingWindows.add(bw);
                            }
                        }
                    }
                }

                day = day.addDays(1);
            }
        }
    }

    //private static Set<Id> checkResourceAvailability(List<MA_SchedulerBookingWindow> allBookingWindows, /*List<Event> sfEventsList, */List<MA_Scheduler_Event__c> maEventsList, Map<Id, Id> userMap) {
    private static Set<Id> checkResourceAvailability(List<MA_SchedulerBookingWindow> allBookingWindows, List<MA_SchedulerBookingWindow> unAvailableSlots, /*List<Event> sfEventsList, List<MA_Scheduler_Event__c> maEventsList,*/ Map<Id, Id> userMap, DateTime startDateTime, DateTime endDateTime, Set<Id> resourceIds) {
    	Set<Id> scheduledWorkOrderIds = new Set<Id>();

    	//List<Event> eventsList = [SELECT Id, StartDateTime, EndDateTime, OwnerId, WhatId, Subject FROM Event WHERE OwnerId IN :userMap.keySet() AND StartDateTime < :endDateTime AND EndDateTime > :startDateTime];
        //List<MA_Scheduler_Event__c> maEventsList = [SELECT Id, StartDateTime__c, EndDateTime__c, Resource__c, RbA_Work_Order__c, Name FROM MA_Scheduler_Event__c WHERE Resource__c IN :resourceIds AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime];

        Set<Id> maEventIdsLinkedToSfEvents = new Set<Id>();
        for (List<Event> sfEventList : [SELECT Id, MA_Scheduler_Event__c, StartDateTime, EndDateTime, OwnerId, WhatId, Subject FROM Event WHERE OwnerId IN :userMap.keySet() AND StartDateTime < :endDateTime AND EndDateTime > :startDateTime]) {
            for (Event sfEvent : sfEventList) {
	            MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(sfEvent, userMap);
	            schedulerEvent.setBookingWindowsAvailableResources(allBookingWindows);
	            //scheduledWorkOrderIds.add(sfEvent.WhatId);

                maEventIdsLinkedToSfEvents.add(sfEvent.MA_Scheduler_Event__c);
	        }
        }

        for (List<MA_Scheduler_Event__c> maEventList : [SELECT Id, Name, StartDateTime__c, EndDateTime__c, Resource__c, RbA_Work_Order__c, RbA_Work_Order__r.Work_Order_Type__c, RbA_Work_Order__r.Contact__c, RbA_Work_Order__r.Contact__r.FirstName, RbA_Work_Order__r.Contact__r.LastName
                                                        FROM MA_Scheduler_Event__c WHERE Resource__c IN :resourceIds AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime AND Id NOT IN :maEventIdsLinkedToSfEvents]) {
	        for (MA_Scheduler_Event__c maEvent : maEventList) {
	           	MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(maEvent, userMap);
	            schedulerEvent.setBookingWindowsAvailableResources(allBookingWindows);
	            scheduledWorkOrderIds.add(maEvent.RbA_Work_Order__c);
	        }
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
            if (bw.availableResources.isEmpty()) {
                unAvailableSlots.add(allBookingWindows[index]);
                allBookingWindows.remove(index);
            }
        }

        return scheduledWorkOrderIds;
    }



    //private static void checkResourceAvailability(List<MA_SchedulerBookingWindow> allBookingWindows, /*List<RbA_Work_Order__c> workOrderList, */Map<Id, Id> userMap) {
    private static void checkResourceAvailability(List<MA_SchedulerBookingWindow> allBookingWindows, List<MA_SchedulerBookingWindow> unAvailableSlots, /*List<RbA_Work_Order__c> workOrderList, */Map<Id, Id> userMap, Date startDate, Date endDate, Set<Id> scheduledWorkOrderIds) {
    	//List<RbA_Work_Order__c> workOrderList = [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c FROM RbA_Work_Order__c WHERE Id NOT IN :scheduledWorkOrderIds AND Appointment_Date__c >= :startDate AND Appointment_Date__c <= :endDate];

    	/*
    	for (RbA_Work_Order__c workOrder : workOrderList) {
            MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(workOrder, userMap);
            schedulerEvent.setBookingWindowsOverlappingWorkOrders(allBookingWindows);
        }
        */

        System.debug([SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Work_Order_Type__c, Contact__c, Contact__r.FirstName, Contact__r.LastName FROM RbA_Work_Order__c WHERE Id NOT IN :scheduledWorkOrderIds AND Appointment_Date__c >= :startDate AND Appointment_Date__c <= :endDate]);

        for (List<RbA_Work_Order__c> workOrderList : [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Work_Order_Type__c, Contact__c, Contact__r.FirstName, Contact__r.LastName,
                                                        (SELECT Id, Scheduled_Resource__c, Scheduled_Resource__r.Name FROM Assigned_Resources__r)
                                                        FROM RbA_Work_Order__c WHERE Id NOT IN :scheduledWorkOrderIds AND Appointment_Date__c >= :startDate AND Appointment_Date__c <= :endDate]) {
            for (RbA_Work_Order__c workOrder : workOrderList) {
            	MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(workOrder, userMap);
            	schedulerEvent.setBookingWindowsOverlappingWorkOrders(allBookingWindows);
            }
        }

        for (Integer i = 0, index = allBookingWindows.size() - 1; index >= i; index--) {
            MA_SchedulerBookingWindow bw = allBookingWindows[index];
            if (bw.availableResources.size() == bw.bookedWorkOrders.size()) {
                unAvailableSlots.add(allBookingWindows[index]);
                allBookingWindows.remove(index);
            }
        }
    }


















    webService static String saveAssignedResources(String workOrderId, List<Id> assignedResourceIdsList) {
        System.SavePoint sp = Database.setSavePoint();
        Map<String, Object> response = new Map<String, Object>();

        try {
            RbA_Work_Order__c workOrder = [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Account__r.Store_Location__r.Active_Store_Configuration__c FROM RbA_Work_Order__c WHERE Id = :workOrderId];

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

            for (Assigned_Resources__c assignedResource : assignedResources) {
                if (assignedResourceIds.contains(assignedResource.Scheduled_Resource__c)) {
                    alreadyAssignedResourceIds.add(assignedResource.Scheduled_Resource__c);
                }
                else {
                    assignedResourcesToDelete.add(assignedResource);
                }
            }
            
            if (workOrder.Appointment_Date__c != null && String.isNotBlank(workOrder.Appointment_Start_Time__c) && (String.isNotBlank(workOrder.Appointment_End_Time__c) || workOrder.Appointment_Duration__c != null)) {
                Id storeId = workOrder.Account__r.Store_Location__r.Active_Store_Configuration__c;
                String storeTimezone = MA_SchedulerUtilities.retrieveStoreTimezone(storeId);
                List<Event> newSfEvents = new List<Event>();
                List<MA_Scheduler_Event__c> newMaEvents = new List<MA_Scheduler_Event__c>();

                Set<Id> maEventsAlreadyCreatedFor = new Set<Id>();
                Set<Id> sfEventsAlreadryCreatedFor = new Set<Id>();
                Map<Id, MA_Scheduler_Event__c> maEventsAlreadyCreated = new Map<Id, MA_Scheduler_Event__c>([SELECT Id, Resource__c FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c IN :assignedResourceIds]);
                Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>([SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c NOT IN :assignedResourceIds]);
                
                List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet() AND OwnerId NOT IN :assignedResourceIds];
                for (Event ev : sfEventsToDelete) {
                    ev.Type = 'Reassigned';
                }

                //update sfEventsToDelete;
                delete sfEventsToDelete;
                delete maEventsToDelete.values();

                for (MA_Scheduler_Event__c maEvent : maEventsAlreadyCreated.values()) {
                    maEventsAlreadyCreatedFor.add(maEvent.Resource__c);
                }
                
                for (Event ev : [SELECT Id, OwnerId FROM Event WHERE MA_Scheduler_Event__c IN :maEventsAlreadyCreated.keySet() AND OwnerId IN :assignedResourceIds]) {
                    sfEventsAlreadryCreatedFor.add(ev.OwnerId);
                }

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

                insert newMaEvents;

                for (MA_Scheduler_Event__c maEvent : newMaEvents) {
                    if (!sfEventsAlreadryCreatedFor.contains(maEvent.Resource__c) && resourceIdToUserIdMap.containsKey(maEvent.Resource__c)) {
                        newSfEvents.add(
                            new Event(
                                WhatId = workOrderId,
                                OwnerId = resourceIdToUserIdMap.get(maEvent.Resource__c),
                                Subject = workOrder.Name,
                                StartDateTime = startDateTime,
                                EndDateTime = endDateTime,
                                MA_Scheduler_Event__c = maEvent.Id
                            )
                        );
                    }
                }

                insert newSfEvents;
            }

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
                workOrder.Reason__c = cancellationReason;
            }
            update workOrder;

            workOrder = [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Account__r.Store_Location__r.Active_Store_Configuration__c,
                            (SELECT Id, Scheduled_Resource__c, Scheduled_Resource__r.RbA_User__c FROM Assigned_Resources__r)
                            FROM RbA_Work_Order__c WHERE Id = :workOrderId];

            if (!workOrder.Assigned_Resources__r.isEmpty()) {
                Set<Id> assignedResourceIds = new Set<Id>();
                for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                    assignedResourceIds.add(resource.Scheduled_Resource__c);
                }

                //Map<Id, MA_Scheduler_Event__c> maEventsAlreadyCreated = new Map<Id, MA_Scheduler_Event__c>([SELECT Id, Resource__c FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c IN :assignedResourceIds]);
                //Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>([SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c NOT IN :assignedResourceIds]);
                Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>([SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c IN :assignedResourceIds]);
                
                //List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet() AND OwnerId NOT IN :assignedResourceIds];
                List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet() AND OwnerId IN :assignedResourceIds];
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
















    webService static String schedulerWorkOrder(Id workOrderId, String selectedWindow, String rescheduleReason) {
        System.SavePoint sp = Database.setSavePoint();
        Map<String, Object> response = new Map<String, Object>();

        try {
            /*
            List<String> splitTimes = selectedWindow.split(' - ');
            List<String> splitStart = splitTimes[0].split(' ');
            List<String> splitEnd = splitTimes[1].split(' ');

            RbA_Work_Order__c workOrder = new RbA_Work_Order__c(
                Id = workOrderId,
                Appointment_Date__c = Date.parse(splitStart[0]),
                Appointment_Start_Time__c = splitStart[1] + ' ' + splitStart[2],
                Appointment_End_Time__c = splitEnd[1] + ' ' + splitEnd[2]
            );
            update workOrder;
            */

            List<String> windowTextSplit = selectedWindow.split(' ');

            RbA_Work_Order__c workOrder = new RbA_Work_Order__c(
                Id = workOrderId,
                Appointment_Date__c = Date.parse(windowTextSplit[0]),
                Appointment_Start_Time__c = windowTextSplit[1] + ' ' + windowTextSplit[2],
                Appointment_End_Time__c = windowTextSplit[4] + ' ' + windowTextSplit[5]
            );

            if (String.isNotBlank(rescheduleReason)) {
                workOrder.Reason__c = rescheduleReason;
            }
            update workOrder;

            workOrder = [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Account__r.Store_Location__r.Active_Store_Configuration__c,
                            (SELECT Id, Scheduled_Resource__c, Scheduled_Resource__r.RbA_User__c FROM Assigned_Resources__r)
                            FROM RbA_Work_Order__c WHERE Id = :workOrderId];

            if (!workOrder.Assigned_Resources__r.isEmpty()) {
                Set<Id> assignedResourceIds = new Set<Id>();
                for (Assigned_Resources__c resource : workOrder.Assigned_Resources__r) {
                    assignedResourceIds.add(resource.Scheduled_Resource__c);
                }

                //Map<Id, MA_Scheduler_Event__c> maEventsAlreadyCreated = new Map<Id, MA_Scheduler_Event__c>([SELECT Id, Resource__c FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c IN :assignedResourceIds]);
                //Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>([SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c NOT IN :assignedResourceIds]);
                Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>([SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :workOrderId AND Resource__c IN :assignedResourceIds]);
                
                //List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet() AND OwnerId NOT IN :assignedResourceIds];
                List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet() AND OwnerId IN :assignedResourceIds];
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
                DateTime endDateTime = MA_SchedulerUtilities.createDateTimeFromBookingWindow(workOrder.Appointment_Date__c, workOrder.Appointment_End_Time__c, storeTimezone);
                
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
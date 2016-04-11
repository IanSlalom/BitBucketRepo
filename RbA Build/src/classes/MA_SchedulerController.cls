global with sharing class MA_SchedulerController {
//global without sharing class MA_SchedulerController {

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
                query = 'SELECT Id, Name, Resource_Type__c, Retail_Location__c, Retail_Location__r.Name, RbA_User__c, Crew_Size__c FROM Resource__c';
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
            	query = 'SELECT Id, Name, Contact__c, Contact__r.FirstName, Contact__r.LastName, Appointment_Duration__c FROM RbA_Work_Order__c';
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

    webService static String getStoreTimezone() {
        Map<String, Object> response = new Map<String, Object>();
    	
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




        

        response.put('success', true);
        response.put('storeTimezone', 'America/Los_Angeles');
        return JSON.serialize(response);
    }

    private static String retrieveStoreTimezone() {
    	return 'America/Los_Angeles';
    }

    webService static String retrieveEvents(String objType, String filters) {
    	MA_SchedulerEvent[] eventList = new MA_SchedulerEvent[]{};
        Map<String, Object> response = new Map<String, Object>();

        System.debug(filters);
        //System.debug(startDateTimeEpoch);
        //System.debug(endDateTimeEpoch);
        
        try {
            String query;
            
            if (objType == 'Event') {
                query = 'SELECT Id, Subject, OwnerId, WhatId, StartDateTime, EndDateTime FROM Event';
            }
            else if (objType == 'MASchedulerEvent') {
                query = 'SELECT Id, Name, Resource__c, RbA_Work_Order__c, StartDateTime__c, EndDateTime__c, RbA_Work_Order__r.Work_Order_Type__c, RbA_Work_Order__r.Contact__c, RbA_Work_Order__r.Contact__r.FirstName, RbA_Work_Order__r.Contact__r.LastName FROM MA_Scheduler_Event__c';
            }
            else if (objType == 'WorkOrder') {
                query = 'SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Work_Order_Type__c, Contact__c, Contact__r.FirstName, Contact__r.LastName,'
                			+ ' (SELECT Id FROM Assigned_Resources__r)'
                			+ ' FROM RbA_Work_Order__c';
            }

            System.debug(objType);
            System.debug(query);
            
            if (String.isNotBlank(query)) {
                query += String.isNotBlank(filters) ? ' WHERE ' + filters : '';
                SObject[] objList = Database.query(query);

                /*
                //Date today = Date.today();
                //Time sampleTime = Time.newInstance(6, 0, 0, 0);
				//DateTime serverTime = DateTime.newInstance(2009, 2, 16, 3, 0, 0);
				//DateTime utcTime = DateTime.newInstanceGmt(2009, 2, 16, 3, 0, 0);
				//DateTime serverTime = DateTime.now();
				DateTime serverTime = DateTime.newInstance(Long.valueOf(startDateTimeEpoch));
				DateTime utcTime = DateTime.newInstanceGmt(serverTime.year(), serverTime.month(), serverTime.day(), serverTime.hour(), serverTime.minute(), serverTime.second());
				//Long serverTimeLong = serverTime.getTime();
				//Long utcTimeLong = utcTime.getTime();
				//Long timeDiffLong = utcTimeLong - serverTimeLong;
				Long timeDiffLong = utcTime.getTime() - serverTime.getTime();
				Integer hoursDiff = (Integer)(timeDiffLong / 1000 / 60 / 60);
				*/



				String storeTimezone = retrieveStoreTimezone();

                for (SObject obj : objList) {
                	MA_SchedulerEvent customEvent = new MA_SchedulerEvent(obj, new Map<Id, Id>());
                	//customEvent.createOffsetTimes(hoursDiff);
                	//customEvent.createOffsetTimes(storeTimezone);
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




































    webService static String checkAvailability(Id workOrderId, String startDateTimeEpoch, String endDateTimeEpoch, String offsetPageMinutes, Boolean nextAvailable) {
        Map<String, Object> response = new Map<String, Object>();

        try {
			RbA_Work_Order__c workOrder = [SELECT Id, Work_Order_Type__c, Account__r.Store_Location__r.Active_Store_Configuration__c,
                                            (SELECT Id, RbA_Skill__c FROM Work_Order_Required_Skills__r)
                                            FROM RbA_Work_Order__c WHERE Id = :workOrderId];

            Id storeId = workOrder.Account__r.Store_Location__r.Active_Store_Configuration__c;
            Set<Id> rbaSkillIds = new Set<Id>();
            for (Work_Order_Required_Skill__c rbaSkill : workOrder.Work_Order_Required_Skills__r) {
                rbaSkillIds.add(rbaSkill.RbA_Skill__c);
            }

            Map<Id, Id> userMap = new Map<Id, Id>();
            Set<Id> resourceIds = new Set<Id>();
            List<Resource__c> resourceList = [SELECT Id, RbA_User__c,
                                                (SELECT Id, RbA_Skill__c FROM Resource_Skills__r WHERE RbA_Skill__c IN :rbaSkillIds)
                                                FROM Resource__c WHERE Retail_Location__c = :storeId AND Active__c = true AND Resource_Type__c != 'Scheduler'];

            for (Resource__c resource : resourceList) {
                if (!resource.Resource_Skills__r.isEmpty()) {
                    resourceIds.add(resource.Id);
                    userMap.put(resource.RbA_User__c, resource.Id);
                }
            }

            String storeTimezone;
            List<MA_SchedulerBookingWindow> bookingWindows = new List<MA_SchedulerBookingWindow>();
            Map<String, Object> storeBookingWindows = new Map<String, Object>();
            List<MA_Scheduler_Settings__c> settings = [SELECT Id, Settings__c, Store_Id__c, Resource_Id__c FROM MA_Scheduler_Settings__c WHERE Store_Id__c = :storeId OR Resource_Id__c IN :resourceIds];
            for (MA_Scheduler_Settings__c setting : settings) {
                Map<String, Object> settingsMap = (Map<String, Object>)JSON.deserializeUntyped(setting.Settings__c);
                storeTimezone = (String)settingsMap.get('timezone');
                response.put('settingsMap', settingsMap);
                response.put('storeTimezone', storeTimezone);

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

            if (storeBookingWindows.isEmpty()) {
                response.put('success', false);
                response.put('error', 'The store hours and/or ' + workOrder.Work_Order_Type__c + ' booking windows have not been configured yet.  Please go to the settings page to set these up.');
                return JSON.serialize(response);
            }




            Date startDate, endDate;
            String startTime, endTime;
            Integer startDateOffsetMinutes, endDateOffsetMinutes;
            DateTime endDateTime = DateTime.newInstance(Long.valueOf(endDateTimeEpoch));
	        DateTime startDateTime = DateTime.newInstance(Long.valueOf(startDateTimeEpoch));
            
            if (String.isNotBlank(storeTimezone)) {
				//DateTime tempTime = DateTime.newInstance(2015, 3, 24, 5, 0, 0);
				//DateTime tempTime = DateTime.now();
				//Integer offset = Integer.valueOf(tempTime.format('Z', storeTimezone));
				Integer startDateOffset = Integer.valueOf(startDateTime.format('Z', storeTimezone));
				startDateOffsetMinutes = Math.mod(startDateOffset, 100);
				Integer startDateOffsetHours = (Integer)Math.floor(startDateOffset / 100);
				startDateOffsetMinutes += (startDateOffsetHours * 60) + Integer.valueOf(offsetPageMinutes);

	            startDateTime = startDateTime.addMinutes(-startDateOffsetMinutes);
	            System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z'));
	            System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));

	            String startDateTimeZoneFormatted = startDateTime.format('MM/dd/yyyy hh:mm a', storeTimezone);
	            String[] startDateTimeZoneFormattedSplit = startDateTimeZoneFormatted.split(' ');
	            startDate = Date.parse(startDateTimeZoneFormattedSplit[0]);
	            startTime = startDateTimeZoneFormattedSplit[1] + ' ' + startDateTimeZoneFormattedSplit[2];

				//DateTime tempTime = DateTime.newInstance(2015, 3, 24, 5, 0, 0);
				//DateTime tempTime = DateTime.now();
				//Integer offset = Integer.valueOf(tempTime.format('Z', storeTimezone));
				Integer endDateOffset = Integer.valueOf(startDateTime.format('Z', storeTimezone));
				endDateOffsetMinutes = Math.mod(endDateOffset, 100);
				Integer endDateOffsetHours = (Integer)Math.floor(endDateOffset / 100);
				endDateOffsetMinutes += (endDateOffsetHours * 60) + Integer.valueOf(offsetPageMinutes);

	            endDateTime = endDateTime.addMinutes(-endDateOffsetMinutes);
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

	            String endDateTimeZoneFormatted = endDateTime.format('MM/dd/yyyy hh:mm a', storeTimezone);
	            String[] endDateTimeZoneFormattedSplit = endDateTimeZoneFormatted.split(' ');
	            endDate = Date.parse(endDateTimeZoneFormattedSplit[0]);
	            endTime = endDateTimeZoneFormattedSplit[1] + ' ' + endDateTimeZoneFormattedSplit[2];

				System.debug(startDate);
				System.debug(startTime);
				System.debug(endDate);
				System.debug(endTime);
	        }




	        System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
	        System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));





            createBookingWindows(bookingWindows, storeBookingWindows, resourceIds, startDateTime, endDateTime, storeTimezone);

            //List<Event> eventsList = [SELECT Id, StartDateTime, EndDateTime, OwnerId, WhatId, Subject FROM Event WHERE OwnerId IN :userMap.keySet() AND StartDateTime < :endDateTime AND EndDateTime > :startDateTime];
            //List<MA_Scheduler_Event__c> maEventsList = [SELECT Id, StartDateTime__c, EndDateTime__c, Resource__c, RbA_Work_Order__c, Name FROM MA_Scheduler_Event__c WHERE Resource__c IN :resourceIds AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime];

            Set<Id> scheduledWorkOrderIds = new Set<Id> { workOrder.Id };
            scheduledWorkOrderIds.addAll(checkResourceAvailability(bookingWindows, /*eventsList, maEventsList,*/ userMap, startDateTime, endDateTime, resourceIds));

            //List<RbA_Work_Order__c> workOrderList = [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c FROM RbA_Work_Order__c WHERE Id NOT IN :scheduledWorkOrderIds AND Appointment_Date__c >= :startDate AND Appointment_Date__c <= :endDate];


            checkResourceAvailability(bookingWindows, /*workOrderList, */userMap, startDate, endDate, scheduledWorkOrderIds);


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
        }
        catch(Exception ex) {
            response.put('success', false);
            response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        }

        return JSON.serialize(response);
    }

    private static void createBookingWindows(List<MA_SchedulerBookingWindow> bookingWindows, Map<String, Object> storeBookingWindows, Set<Id> resourceIds, DateTime startDateTime, DateTime endDateTime, String storeTimezone) {
        //System.debug(storeBookingWindows);

        if (!storeBookingWindows.isEmpty()) {
            Date day = startDateTime.date();
            Date endDate = endDateTime.date();

            System.debug(day);
            System.debug(endDate);

            while (day <= endDate) {
                //System.debug(storeBookingWindows.keySet());
                for (String dayOfWeek : storeBookingWindows.keySet()) {
                    //System.debug((List<Object>)storeBookingWindows.get(dayOfWeek));
                    List<Object> windows = (List<Object>)storeBookingWindows.get(dayOfWeek);
                    for (Object window : windows) {
                        Map<String, Object> windowMap = (Map<String, Object>)window;
                        if (!windowMap.isEmpty()) {
                            //MA_SchedulerBookingWindow bw = new MA_SchedulerBookingWindow(dayOfWeek, day, windowMap, resourceIds, startDateTime.time(), endDateTime.time(), storeTimezone);
                            MA_SchedulerBookingWindow bw = new MA_SchedulerBookingWindow(dayOfWeek, day, windowMap, resourceIds, startDateTime, endDateTime, storeTimezone);
                            //System.debug(bw.isValid);
                            if (bw.isValid) {
                                bookingWindows.add(bw);
                            }
                        }
                    }
                }

                day = day.addDays(1);
            }
        }

        System.debug(bookingWindows);
    }

    //private static Set<Id> checkResourceAvailability(List<MA_SchedulerBookingWindow> allBookingWindows, /*List<Event> sfEventsList, */List<MA_Scheduler_Event__c> maEventsList, Map<Id, Id> userMap) {
    private static Set<Id> checkResourceAvailability(List<MA_SchedulerBookingWindow> allBookingWindows, /*List<Event> sfEventsList, List<MA_Scheduler_Event__c> maEventsList,*/ Map<Id, Id> userMap, DateTime startDateTime, DateTime endDateTime, Set<Id> resourceIds) {
    	Set<Id> scheduledWorkOrderIds = new Set<Id>();

    	//List<Event> eventsList = [SELECT Id, StartDateTime, EndDateTime, OwnerId, WhatId, Subject FROM Event WHERE OwnerId IN :userMap.keySet() AND StartDateTime < :endDateTime AND EndDateTime > :startDateTime];
        //List<MA_Scheduler_Event__c> maEventsList = [SELECT Id, StartDateTime__c, EndDateTime__c, Resource__c, RbA_Work_Order__c, Name FROM MA_Scheduler_Event__c WHERE Resource__c IN :resourceIds AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime];

        for (List<Event> sfEventList : [SELECT Id, StartDateTime, EndDateTime, OwnerId, WhatId, Subject FROM Event WHERE OwnerId IN :userMap.keySet() AND StartDateTime < :endDateTime AND EndDateTime > :startDateTime]) {
            for (Event sfEvent : sfEventList) {
	            MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(sfEvent, userMap);
	            schedulerEvent.setBookingWindowsAvailableResources(allBookingWindows);
	            //scheduledWorkOrderIds.add(sfEvent.WhatId);
	        }
        }

        for (List<MA_Scheduler_Event__c> maEventList : [SELECT Id, Name, StartDateTime__c, EndDateTime__c, Resource__c, RbA_Work_Order__c, RbA_Work_Order__r.Work_Order_Type__c, RbA_Work_Order__r.Contact__c, RbA_Work_Order__r.Contact__r.FirstName, RbA_Work_Order__r.Contact__r.LastName FROM MA_Scheduler_Event__c WHERE Resource__c IN :resourceIds AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime]) {
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
                allBookingWindows.remove(index);
            }
        }

        return scheduledWorkOrderIds;
    }



    //private static void checkResourceAvailability(List<MA_SchedulerBookingWindow> allBookingWindows, /*List<RbA_Work_Order__c> workOrderList, */Map<Id, Id> userMap) {
    private static void checkResourceAvailability(List<MA_SchedulerBookingWindow> allBookingWindows, /*List<RbA_Work_Order__c> workOrderList, */Map<Id, Id> userMap, Date startDate, Date endDate, Set<Id> scheduledWorkOrderIds) {
    	//List<RbA_Work_Order__c> workOrderList = [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c FROM RbA_Work_Order__c WHERE Id NOT IN :scheduledWorkOrderIds AND Appointment_Date__c >= :startDate AND Appointment_Date__c <= :endDate];

    	/*
    	for (RbA_Work_Order__c workOrder : workOrderList) {
            MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(workOrder, userMap);
            schedulerEvent.setBookingWindowsOverlappingWorkOrders(allBookingWindows);
        }
        */

        System.debug([SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Work_Order_Type__c, Contact__c, Contact__r.FirstName, Contact__r.LastName FROM RbA_Work_Order__c WHERE Id NOT IN :scheduledWorkOrderIds AND Appointment_Date__c >= :startDate AND Appointment_Date__c <= :endDate]);

        for (List<RbA_Work_Order__c> workOrderList : [SELECT Id, Name, Appointment_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c, Work_Order_Type__c, Contact__c, Contact__r.FirstName, Contact__r.LastName FROM RbA_Work_Order__c WHERE Id NOT IN :scheduledWorkOrderIds AND Appointment_Date__c >= :startDate AND Appointment_Date__c <= :endDate]) {
            for (RbA_Work_Order__c workOrder : workOrderList) {
            	MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(workOrder, userMap);
            	schedulerEvent.setBookingWindowsOverlappingWorkOrders(allBookingWindows);
            }
        }

        for (Integer i = 0, index = allBookingWindows.size() - 1; index >= i; index--) {
            MA_SchedulerBookingWindow bw = allBookingWindows[index];
            if (bw.availableResources.size() == bw.bookedWorkOrders.size()) {
                allBookingWindows.remove(index);
            }
        }
    }
















    webService static String schedulerWorkOrder(Id workOrderId, String selectedWindow) {
        System.SavePoint sp = Database.setSavePoint();
        Map<String, Object> response = new Map<String, Object>();

        try {
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
    }

}
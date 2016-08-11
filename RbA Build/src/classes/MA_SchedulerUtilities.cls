/************************************************************************************/
/*                                                                                  */
/*      This class holds the utility methods used to throughout the scheduler       */
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

public with sharing class MA_SchedulerUtilities {

    /********************************************************/
    /*                                                      */
    /*      generates the error for a webservice response   */
    /*                                                      */
    /********************************************************/
    public static void createErrorResponse(Exception ex, Map<String, Object> response) {
        response.put('success', false);
        response.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
        response.put('stackTrace', ex.getStackTraceString());
    }

	/****************************************************/
    /*                                                  */
    /*      creates a datetime from a date and          */
    /*      time string based on a timezone             */
    /*                                                  */
    /****************************************************/
    public static DateTime createDateTimeFromBookingWindow(Date appointmentDate, String appointmentTime, String timezone) {
		List<String> appointmentTimeSplit = appointmentTime.split(' ');
        List<String> timeSplit = appointmentTimeSplit[0].split(':');
        Integer hour = Integer.valueOf(timeSplit[0]);

        if (hour == 12) {
            hour = 0;
        }

        if (appointmentTimeSplit[1].toLowerCase() == 'pm') {
            hour += 12;
        }

        Time tm = Time.newInstance(hour, Integer.valueOf(timeSplit[1]), 0, 0);
        DateTime dt = DateTime.newInstanceGmt(appointmentDate, tm);

        if (String.isNotBlank(timezone)) {
        	dt = convertGmtToTimezone(dt, timezone, null);
        }
        return dt;
	}
	
	/********************************************************/
    /*                                                      */
    /*      creates a GMT datetime to the correct timezone  */
    /*                                                      */
    /********************************************************/
    public static DateTime convertGmtToTimezone(DateTime dtGmt, String timezone, String offsetPageMinutes) {
		Integer offset = determineTimezoneOffset(dtGmt, timezone);
		Integer offsetMinutes = determineOffsetMinutesFromTimezoneOffset(offset);

		if (String.isNotBlank(offsetPageMinutes)) {
			offsetMinutes += Integer.valueOf(offsetPageMinutes);
		}

		dtGmt = dtGmt.addMinutes(-offsetMinutes);
		return dtGmt;
	}

    /****************************************************/
    /*                                                  */
    /*      creates a datetime from a date and          */
    /*      military time string based on a timezone    */
    /*                                                  */
    /****************************************************/
    public static DateTime createDateTimeFromBookingWindowMilitary(Date appointmentDate, String appointmentTime, String timezone) {
        List<String> timeSplit = appointmentTime.split(':');
        Time tm = Time.newInstance(Integer.valueOf(timeSplit[0]), Integer.valueOf(timeSplit[1]), 0, 0);
        DateTime dt = DateTime.newInstance(appointmentDate, tm);

        if (String.isNotBlank(timezone)) {
            dt = convertTimezoneToTimezone(dt, null, timezone);
        }
        return dt;
    }
	
	/************************************************************/
    /*                                                          */
    /*      creates a datetime from one timezone to another     */
    /*                                                          */
    /************************************************************/
    public static DateTime convertTimezoneToTimezone(DateTime dt, String originalTimezone, String newTimezone) {
		Integer currentOffset = determineTimezoneOffset(dt, originalTimezone);
		Integer newOffset = determineTimezoneOffset(dt, newTimezone);

		Integer currentOffsetMinutes = determineOffsetMinutesFromTimezoneOffset(currentOffset);
		Integer newOffsetMinutes = determineOffsetMinutesFromTimezoneOffset(newOffset);

		Integer offset = newOffsetMinutes - currentOffsetMinutes;
		dt = dt.addMinutes(-offset);
		return dt;
	}

	/****************************************************/
    /*                                                  */
    /*      returns the timezone offset for a datetime  */
    /*                                                  */
    /****************************************************/
    public static Integer determineTimezoneOffset(DateTime dt, String timezone) {
		Integer offset = 0;
		if (dt != null) {
			if (String.isNotBlank(timezone)) {
				offset = Integer.valueOf(dt.format('Z', timezone));
			}
			else {
				offset = Integer.valueOf(dt.format('Z'));
			}
		}
		return offset;
	}

	/****************************************************/
    /*                                                  */
    /*      converts a timezone offset to total minutes */
    /*                                                  */
    /****************************************************/
    public static Integer determineOffsetMinutesFromTimezoneOffset(Integer offset) {
		Integer offsetMinutes = 0;
		if (offset != null) {
			offsetMinutes = (Integer)(Math.floor(offset / 100) * 60) + Math.mod(offset, 100);
		}
		return offsetMinutes;
	}

    /****************************************************/
    /*                                                  */
    /*      retrieves the store's timezone              */
    /*                                                  */
    /****************************************************/
    public static String retrieveStoreTimezone(Id storeId) {
    	String storeTimezone = UserInfo.getTimeZone().toString();
    	for (MA_Scheduler_Settings__c settings : [SELECT Settings__c FROM MA_Scheduler_Settings__c WHERE Store_Id__c = :storeId AND Resource_Id__c = null]) {
    		if (String.isNotBlank(settings.Settings__c)) {
    			Map<String, Object> storeSettings = (Map<String, Object>)JSON.deserializeUntyped(settings.Settings__c);
    			storeTimezone = (String)storeSettings.get('timezone');
    		}

    		if (String.isNotBlank(storeTimezone)) {
    			break;
    		}
    	}
    	return storeTimezone;
    }

    /****************************************************/
    /*                                                  */
    /*      returns all of a store's settings           */
    /*      in a map                                    */
    /*                                                  */
    /****************************************************/
    public static Map<String, Object> retrieveAllStoreSettings(Id storeId, String workOrderType) {
        MA_Scheduler_Settings__c storeSettings;
        List<Object> storeHolidays = new List<Object>();
        Map<String, Object> response = new Map<String, Object>();
        String storeTimezone = UserInfo.getTimeZone().toString();
        Map<String, Object> storeBookingWindows = new Map<String, Object>();
        Map<Id, Map<String, Object>> resourceHours = new Map<Id, Map<String, Object>>();
        Map<Id, MA_Scheduler_Settings__c> resourceSettingsMap = new Map<Id, MA_Scheduler_Settings__c>();
        List<MA_Scheduler_Settings__c> maSettings = [SELECT Id, Settings__c, Store_Id__c, Resource_Id__c FROM MA_Scheduler_Settings__c WHERE Store_Id__c != null AND Store_Id__c = :storeId];

        for (MA_Scheduler_Settings__c maSetting : maSettings) {
            if (String.isNotBlank(maSetting.Settings__c)) {
                Map<String, Object> maSettingsMap = (Map<String, Object>)JSON.deserializeUntyped(maSetting.Settings__c);

                if (String.isBlank(maSetting.Resource_Id__c)) {
                    storeSettings = maSetting;
                    storeTimezone = (String)maSettingsMap.get('timezone');
                    storeHolidays = (List<Object>)maSettingsMap.get('storeHolidays');
                    storeBookingWindows = (Map<String, Object>)maSettingsMap.get(workOrderType);
                    if (storeBookingWindows != null && !storeBookingWindows.isEmpty()) {
                        storeBookingWindows = (Map<String, Object>)storeBookingWindows.get('bookingWindows');
                    }

                    if (storeBookingWindows == null || storeBookingWindows.isEmpty()) {
                        storeBookingWindows = (Map<String, Object>)maSettingsMap.get('storeHours');
                    }
                }
                else {
                    resourceSettingsMap.put(maSetting.Resource_Id__c, maSetting);
                    resourceHours.put(maSetting.Resource_Id__c, (Map<String, Object>)maSettingsMap.get('resourceHours'));
                }
            }
        }

        response.put('storeTimezone', storeTimezone);
        response.put('storeHolidays', storeHolidays);
        response.put('storeSettings', storeSettings);
        response.put('resourceHours', resourceHours);
        response.put('resourceSettingsMap', resourceSettingsMap);
        response.put('storeBookingWindows', storeBookingWindows);
        return response;
    }

    /****************************************************/
    /*                                                  */
    /*      determines the start and stop for           */
    /*      each day a store is open                    */
    /*                                                  */
    /****************************************************/
    public static Map<String, Map<String, Object>> determineEarliestStartAndLatestEndHours(Map<String, Object> storeBookingWindows) {
    	Map<String, Map<String, Object>> latestHours = new Map<String, Map<String, Object>>();

    	if (!storeBookingWindows.isEmpty()) {
            for (String dayOfWeek : storeBookingWindows.keySet()) {
                List<Object> windows = (List<Object>)storeBookingWindows.get(dayOfWeek);

                for (Object window : windows) {
                    Map<String, Object> windowMap = (Map<String, Object>)window;

                    if (!windowMap.isEmpty()) {
                        if (!latestHours.containsKey(dayOfWeek)) {
                        	String newStartTimeString = (String)windowMap.get('start');
                        	List<String> newStartTimeStringSplit = newStartTimeString.split(':');
                        	Time newStartTime = Time.newInstance(Integer.valueOf(newStartTimeStringSplit[0]), Integer.valueOf(newStartTimeStringSplit[1]), 0, 0);

                        	String newEndTimeString = (String)windowMap.get('end');
                        	List<String> newEndTimeStringSplit = newEndTimeString.split(':');
                        	Time newEndTime = Time.newInstance(Integer.valueOf(newEndTimeStringSplit[0]), Integer.valueOf(newEndTimeStringSplit[1]), 0, 0);

                        	latestHours.put(dayOfWeek, new Map<String, Object> { 'start' => newStartTime, 'end' => newEndTime, 'timesBetween' => new Set<String> { dayOfWeek + ' - ' + newStartTimeString + ' - ' + newEndTimeString } });
                        }
                        else {
                        	Map<String, Object> hours = latestHours.get(dayOfWeek);
                        	Time startTime = (Time)hours.get('start');
                        	Time endTime = (Time)hours.get('end');

                        	String newStartTimeString = (String)windowMap.get('start');
                        	List<String> newStartTimeStringSplit = newStartTimeString.split(':');
                        	Time newStartTime = Time.newInstance(Integer.valueOf(newStartTimeStringSplit[0]), Integer.valueOf(newStartTimeStringSplit[1]), 0, 0);

                        	String newEndTimeString = (String)windowMap.get('end');
                        	List<String> newEndTimeStringSplit = newEndTimeString.split(':');
                        	Time newEndTime = Time.newInstance(Integer.valueOf(newEndTimeStringSplit[0]), Integer.valueOf(newEndTimeStringSplit[1]), 0, 0);

                        	if (newStartTime < startTime) {
                        		hours.put('start', newStartTime);
                        	}

                        	if (newEndTime > endTime) {
                        		hours.put('end', newEndTime);
                        	}

                        	if (newStartTime < startTime || newEndTime > endTime) {
	                        	Set<String> tempSet = (Set<String>)hours.get('timesBetween');
	                        	tempSet.add(dayOfWeek + ' - ' + newStartTimeString + ' - ' + newEndTimeString);
	                        	hours.put('timesBetween', tempSet);
	                        }
                        	
                        	latestHours.put(dayOfWeek, hours);
                        }
                    }
                }
            }
        }

        return latestHours;
    }

    /****************************************************/
    /*                                                  */
    /*      determines all time windows for             */
    /*      each day a store is open                    */
    /*                                                  */
    /****************************************************/
    public static Map<String, Set<String>> determineAllConfiguredHours(Map<String, Object> storeBookingWindows) {
    	Map<String, Set<String>> configuredHours = new Map<String, Set<String>>();

    	if (!storeBookingWindows.isEmpty()) {
            for (String dayOfWeek : storeBookingWindows.keySet()) {
                List<Object> windows = (List<Object>)storeBookingWindows.get(dayOfWeek);

                if (!configuredHours.containsKey(dayOfWeek)) {
                	configuredHours.put(dayOfWeek, new Set<String>());
                }

                for (Object window : windows) {
                    Map<String, Object> windowMap = (Map<String, Object>)window;

                    if (!windowMap.isEmpty()) {
                    	configuredHours.get(dayOfWeek).add(dayOfWeek + ' - ' + (String)windowMap.get('start') + ' - ' + (String)windowMap.get('end'));
                    }
                }
            }
        }

    	return configuredHours;
    }

    /****************************************************/
    /*                                                  */
    /*      determines the store's holidays             */
    /*                                                  */
    /****************************************************/
    public static Set<String> determineStoreHolidays(List<Object> storeHolidays) {
    	Set<String> storeHolidayDates = new Set<String>();

    	if (!storeHolidays.isEmpty()) {
            for (Object holidayObj : storeHolidays) {
            	Map<String, Object> holidayMap = (Map<String, Object>)holidayObj;
                if (!holidayMap.isEmpty()) {
                	String dateString = (String)holidayMap.get('date');
                	storeHolidayDates.add(Date.parse(dateString).format());
                }
            }
        }

    	return storeHolidayDates;
    }

    /****************************************************/
    /*                                                  */
    /*      maps work order types to available          */
    /*      resource types                              */
    /*                                                  */
    /****************************************************/
    public static Set<String> retrieveResourceTypeFromWorkOrderType(String workOrderType) {
    	Map<String, Set<String>> workOrderTypetoResourceTypesMap = new Map<String, Set<String>> {
    		'Tech Measure' => new Set<String> { 'Tech Measure', 'Tech Measure Manager' },
    		'Install' => new Set<String> { 'Install Crew' },
    		'Service' => new Set<String> { 'Field Service', 'Field Service Manager' }
    	};

    	Set<String> resourceTypes = new Set<String>();
    	if (workOrderTypetoResourceTypesMap.containsKey(workOrderType)) {
    		resourceTypes = workOrderTypetoResourceTypesMap.get(workOrderType);
    	}
    	return resourceTypes;
    }

    /****************************************************/
    /*                                                  */
    /*      determines if a resource is working         */
    /*      certain hours                               */
    /*                                                  */
    /****************************************************/
    public static Boolean determineIfResourceWorksSelectedHours(Map<Id, Map<String, Object>> resourceHours, String dayOfWeek, Id resourceId, String storeTimezone, DateTime dayStart, DateTime dayEnd) {
        Map<String, Object> resourceHoursMap = resourceHours.get(resourceId);
        if (resourceHoursMap.containsKey(dayOfWeek)) {
            List<Object> daysHoursList = (List<Object>)resourceHoursMap.get(dayOfWeek);
            Map<String, Object> dayHoursMap = (Map<String, Object>)daysHoursList[0];
            Date day = Date.parse(dayStart.format('MM/dd/yyyy', storeTimezone));
            DateTime resourceEndDateTime = createDateTimeFromBookingWindowMilitary(day, (String)dayHoursMap.get('end'), storeTimezone);
            DateTime resourceStartDateTime = createDateTimeFromBookingWindowMilitary(day, (String)dayHoursMap.get('start'), storeTimezone);

            if (resourceStartDateTime > dayStart || resourceEndDateTime < dayEnd) {
                return false;
            }
        }
        else {
            return false;
        }

        return true;
    }

    /****************************************************/
    /*                                                  */
    /*      creates the booking windows                 */
    /*                                                  */
    /****************************************************/
    public static void createBookingWindows(List<MA_SchedulerBookingWindow> bookingWindows, List<MA_SchedulerBookingWindow> unAvailableSlots, Map<String, Object> storeBookingWindows, Map<Id, Set<Id>> resourceToSkillsMap, Map<Id, Integer> totalSkillsCountMap, DateTime startDateTime, DateTime endDateTime, String storeTimezone, Set<String> storeHolidayDates, Map<Id, Map<String, Object>> resourceHours) {
        if (!storeBookingWindows.isEmpty()) {
            Date day;
            Date endDate;

            if (String.isNotBlank(storeTimezone)) {
                day = Date.parse(startDateTime.format('MM/dd/yyyy', storeTimezone));
                endDate = Date.parse(endDateTime.format('MM/dd/yyyy', storeTimezone));
            }
            else {
                day = Date.parse(startDateTime.format('MM/dd/yyyy'));
                endDate = Date.parse(endDateTime.format('MM/dd/yyyy'));
            }

            while (day <= endDate) {
                if (!storeHolidayDates.contains(day.format())) {
                    for (String dayOfWeek : storeBookingWindows.keySet()) {
                        List<Object> windows = (List<Object>)storeBookingWindows.get(dayOfWeek);
                        for (Object window : windows) {
                            Map<String, Object> windowMap = (Map<String, Object>)window;
                            if (!windowMap.isEmpty()) {
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

    /****************************************************/
    /*                                                  */
    /*      checks all resources availability           */
    /*      by comparing their scheduled events         */
    /*                                                  */
    /****************************************************/
    public static void checkResourceAvailability(List<MA_SchedulerBookingWindow> allBookingWindows, List<MA_SchedulerBookingWindow> unAvailableSlots, Map<Id, Id> userMap, DateTime startDateTime, DateTime endDateTime, Map<Id, Set<Id>> resourceToSkillsMap, String workOrderType, Set<Id> workOrderSkills) {
        Set<Id> workOrderIds = new Set<Id>();
        Set<Id> maEventIdsLinkedToSfEvents = new Set<Id>();
        Map<Id, Set<Id>> woToSkillsMap = new Map<Id, Set<Id>>();
        List<MA_SchedulerEvent> unassignedMaEvents = new List<MA_SchedulerEvent>();
        
        for (List<Event> sfEventList : [SELECT Id, MA_Scheduler_Event__c, StartDateTime, EndDateTime, OwnerId, WhatId, Subject FROM Event WHERE OwnerId IN :userMap.keySet() AND StartDateTime < :endDateTime AND EndDateTime > :startDateTime]) {
            for (Event sfEvent : sfEventList) {
                MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(sfEvent, userMap, false);
                schedulerEvent.setBookingWindowsAvailableResources(allBookingWindows);
                maEventIdsLinkedToSfEvents.add(sfEvent.MA_Scheduler_Event__c);
            }
        }

        for (List<MA_Scheduler_Event__c> maEventList : [SELECT Id, Name, StartDateTime__c, EndDateTime__c, Resource__c, Resource__r.Name, RbA_Work_Order__c, RbA_Work_Order__r.Work_Order_Type__c, RbA_Work_Order__r.Contact__c, RbA_Work_Order__r.Contact__r.FirstName, RbA_Work_Order__r.Contact__r.LastName, Estimated_Start_Date_Time__c, Estimated_End_Date_Time__c,
                                                        RbA_Work_Order__r.Tech_Measure_Synced__c, RbA_Work_Order__r.LSWP_Test_Results__c, RbA_Work_Order__r.Service_Request_Type__c, RbA_Work_Order__r.Total_Days__c, Event_Sequence__c, RbA_Work_Order__r.City__c, RbA_Work_Order__r.State__c
                                                        FROM MA_Scheduler_Event__c WHERE ((Resource__c = null AND RbA_Work_Order__r.Work_Order_Type__c = :workOrderType) OR (Resource__c IN :resourceToSkillsMap.keySet() AND Id NOT IN :maEventIdsLinkedToSfEvents))
                                                        AND StartDateTime__c < :endDateTime AND EndDateTime__c > :startDateTime]) {
        
            for (MA_Scheduler_Event__c maEvent : maEventList) {
                MA_SchedulerEvent schedulerEvent = new MA_SchedulerEvent(maEvent, userMap, false);
                schedulerEvent.setBookingWindowsAvailableResources(allBookingWindows);

                if (schedulerEvent.needsBookedWindowChecked) {
                    workOrderIds.add(maEvent.RbA_Work_Order__c);
                    unassignedMaEvents.add(schedulerEvent);
                }
            }
        }

        for (Work_Order_Required_Skill__c workOrderSkill : [SELECT Id, RbA_Skill__c, RbA_Work_Order__c FROM Work_Order_Required_Skill__c WHERE RbA_Work_Order__c IN :workOrderIds AND RbA_Skill__c IN :workOrderSkills]) {
            if (!woToSkillsMap.containsKey(workOrderSkill.RbA_Work_Order__c)) {
                woToSkillsMap.put(workOrderSkill.RbA_Work_Order__c, new Set<Id>{ workOrderSkill.RbA_Skill__c });
            }
            else {
                woToSkillsMap.get(workOrderSkill.RbA_Work_Order__c).add(workOrderSkill.RbA_Skill__c);
            }
        }

        for (MA_SchedulerEvent schedulerEvent : unassignedMaEvents) {
            schedulerEvent.setBookingWindowsOverlappingWorkOrders(allBookingWindows, woToSkillsMap, workOrderSkills);
        }

        for (Integer i = 0, index = allBookingWindows.size() - 1; index >= i; index--) {
            MA_SchedulerBookingWindow bw = allBookingWindows[index];
            
            if (bw.resourceToSkillsMap.isEmpty()) {
                unAvailableSlots.add(allBookingWindows[index]);
                allBookingWindows.remove(index);
            }
            else if (bw.overbooked) {
                unAvailableSlots.add(allBookingWindows[index]);
                allBookingWindows.remove(index);
            }
        }
    }

    /****************************************************/
    /*                                                  */
    /*      deletes related events                      */
    /*                                                  */
    /****************************************************/
    public static void deleteEvents(Id workOrderId, String deletionReason, String additionalFilters) {
        if (String.isNotBlank(workOrderId)) {
            Map<Id, MA_Scheduler_Event__c> maEventsToDelete = new Map<Id, MA_Scheduler_Event__c>(
                (List<MA_Scheduler_Event__c>)Database.query('SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = \'' + workOrderId + '\'' + additionalFilters)
            );

            List<Event> sfEventsToDelete = [SELECT Id FROM Event WHERE MA_Scheduler_Event__c IN :maEventsToDelete.keySet()];
            for (Event ev : sfEventsToDelete) {
                ev.Type = deletionReason;
            }

            delete sfEventsToDelete;
            delete maEventsToDelete.values();
        }
    }

    /****************************************************/
    /*                                                  */
    /*      creates necessary events                    */
    /*                                                  */
    /****************************************************/
    public static void createEvents(RbA_Work_Order__c workOrder, Map<String, Object> storeBookingWindows, String storeTimezone, DateTime tempStart, DateTime tempEnd, Integer tempTotalMinutes, Set<Id> assignedResourceIds, Set<Id> maEventsAlreadyCreatedFor, Map<Id, Id> resourceToUserMap) {
        Id primaryResourceUserId;
        List<Event> sfEventsToCreate = new List<Event>();
        List<MA_Scheduler_Event__c> maEventsToCreate = new List<MA_Scheduler_Event__c>();
        Id woEventRecTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Event' AND DeveloperName = 'Work_Order_Event'].Id;

        for (Assigned_Resources__c primaryResource : [SELECT Id, Scheduled_Resource__r.RbA_User__c FROM Assigned_Resources__c WHERE Work_Order__c = :workOrder.Id AND IsPrimary__c = true]) {
            primaryResourceUserId = primaryResource.Scheduled_Resource__r.RbA_User__c;
            break;
        }
        
        if (!storeBookingWindows.isEmpty()) {
            Map<String, Map<String, Object>> latestHours = determineEarliestStartAndLatestEndHours(storeBookingWindows);

            /****************************************************/
            /*                                                  */
            /*      creates an event for all necessary days     */
            /*                                                  */
            /****************************************************/
            if (latestHours != null && !latestHours.isEmpty()) {
                Integer totalDays = 0;
                Date tempStartDate = Date.parse(tempStart.format('MM/dd/yyyy', storeTimezone));
                Date startOfWeek = tempStartDate.toStartOfWeek();
                Integer daysBetweenStartOfWeek = startOfWeek.daysBetween(tempStartDate);

                do {
                    totalDays++;
                    String dayOfWeek = MA_SchedulerController.dayNumMap.get(Math.mod(daysBetweenStartOfWeek, 7));
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

                        if (!assignedResourceIds.isEmpty()) {
                            for (Id resourceId : assignedResourceIds) {
                                if (!maEventsAlreadyCreatedFor.contains(resourceId)) {
                                    MA_Scheduler_Event__c maEvent = new MA_Scheduler_Event__c(
                                        Name = workOrder.Name,
                                        Date__c = tempStartDate,
                                        Resource__c = resourceId,
                                        EndDateTime__c = tempEnd,
                                        StartDateTime__c = tempStart,
                                        Event_Sequence__c = totalDays,
                                        RbA_Work_Order__c = workOrder.Id
                                    );
                                    maEventsToCreate.add(maEvent);
                                }
                            }
                        }
                        else {
                            MA_Scheduler_Event__c maEvent = new MA_Scheduler_Event__c(
                                Name = workOrder.Name,
                                Date__c = tempStartDate,
                                EndDateTime__c = tempEnd,
                                StartDateTime__c = tempStart,
                                Event_Sequence__c = totalDays,
                                RbA_Work_Order__c = workOrder.Id
                            );
                            maEventsToCreate.add(maEvent);
                        }
                    }

                    tempStartDate = tempStartDate.addDays(1);
                    daysBetweenStartOfWeek += 1;
                }
                while (tempTotalMinutes > 0);

                workOrder.Total_Days__c = totalDays;
            }
        }

        insert maEventsToCreate;

        for (MA_Scheduler_Event__c maEvent : maEventsToCreate) {
            if (maEvent.Resource__c != null && resourceToUserMap.get(maEvent.Resource__c) != null) {
                Id ownerId = resourceToUserMap.get(maEvent.Resource__c);

                Event sfEvent = new Event(
                    OwnerId = ownerId,
                    Subject = maEvent.Name,
                    RecordTypeId = woEventRecTypeId,
                    WhatId = maEvent.RbA_Work_Order__c,
                    MA_Scheduler_Event__c = maEvent.Id,
                    Type = workOrder.Work_Order_Type__c,
                    EndDateTime = maEvent.EndDateTime__c,
                    StartDateTime = maEvent.StartDateTime__c,
                    Primary_Resource__c = ownerId == primaryResourceUserId
                );
                sfEventsToCreate.add(sfEvent);
            }
        }

        insert sfEventsToCreate;
    }

}
public with sharing class MA_SchedulerUtilities {

	public static DateTime createDateTimeFromBookingWindow(Date appointmentDate, String appointmentTime, String timezone) {
		String[] appointmentTimeSplit = appointmentTime.split(' ');
        String[] timeSplit = appointmentTimeSplit[0].split(':');
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
	
	public static DateTime convertGmtToTimezone(DateTime dtGmt, String timezone, String offsetPageMinutes) {
		Integer offset = determineTimezoneOffset(dtGmt, timezone);
		Integer offsetMinutes = determineOffsetMinutesFromTimezoneOffset(offset);

		if (String.isNotBlank(offsetPageMinutes)) {
			offsetMinutes += Integer.valueOf(offsetPageMinutes);
		}

		dtGmt = dtGmt.addMinutes(-offsetMinutes);
		return dtGmt;
	}
	
	public static DateTime convertTimezoneToTimezone(DateTime dt, String originalTimezone, String newTimezone) {
		Integer currentOffset = determineTimezoneOffset(dt, originalTimezone);
		Integer newOffset = determineTimezoneOffset(dt, newTimezone);

		Integer currentOffsetMinutes = determineOffsetMinutesFromTimezoneOffset(currentOffset);
		Integer newOffsetMinutes = determineOffsetMinutesFromTimezoneOffset(newOffset);

		Integer offset = newOffsetMinutes - currentOffsetMinutes;
		dt = dt.addMinutes(-offset);
		return dt;
	}

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

	public static Integer determineOffsetMinutesFromTimezoneOffset(Integer offset) {
		Integer offsetMinutes = 0;
		if (offset != null) {
			offsetMinutes = (Integer)(Math.floor(offset / 100) * 60) + Math.mod(offset, 100);
		}
		return offsetMinutes;
	}

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

    public static Map<String, Map<String, Map<String, Object>>> determineAllEarliestStartAndLatestEndHours(Map<String, Object> storeBookingWindows) {
    	Map<String, Map<String, Map<String, Object>>> latestHours = new Map<String, Map<String, Map<String, Object>>>();

    	List<String> validSettingsCategories = new List<String> { 'storeHours', 'Tech Measure', 'Install', 'Service' };

    	System.debug(storeBookingWindows);

    	if (!storeBookingWindows.isEmpty()) {
    		for (Integer i = 0, len = validSettingsCategories.size(); i < len; i++) {
    			String category = validSettingsCategories[i];

    			System.debug(category);

    			if (storeBookingWindows.containsKey(category)) {
    				Map<String, Object> bookingWindows = (Map<String, Object>)storeBookingWindows.get(category);
    				if (category != 'storeHours') {
    					bookingWindows = (Map<String, Object>)bookingWindows.get('bookingWindows');
    				}

    				if (!latestHours.containsKey(category)) {
    					latestHours.put(category, new Map<String, Map<String, Object>>());
    				}

    				//Map<String, Map<String, Object>> latestCategoryHours = latestHours.get(category);

    				System.debug(bookingWindows);

    				Map<String, Map<String, Object>> latestCategoryHours = determineEarliestStartAndLatestEndHours(bookingWindows);

    				/*
		            for (String dayOfWeek : bookingWindows.keySet()) {
		            	
		            	System.debug(bookingWindows.get(dayOfWeek));

		                List<Object> windows = (List<Object>)bookingWindows.get(dayOfWeek);

		                for (Object window : windows) {
		                    Map<String, Object> windowMap = (Map<String, Object>)window;

		                    if (!windowMap.isEmpty()) {
		                        if (!latestCategoryHours.containsKey(dayOfWeek)) {
		                        	String newStartTimeString = (String)windowMap.get('start');
		                        	List<String> newStartTimeStringSplit = newStartTimeString.split(':');
		                        	Time newStartTime = Time.newInstance(Integer.valueOf(newStartTimeStringSplit[0]), Integer.valueOf(newStartTimeStringSplit[1]), 0, 0);

		                        	String newEndTimeString = (String)windowMap.get('end');
		                        	List<String> newEndTimeStringSplit = newEndTimeString.split(':');
		                        	Time newEndTime = Time.newInstance(Integer.valueOf(newEndTimeStringSplit[0]), Integer.valueOf(newEndTimeStringSplit[1]), 0, 0);

		                        	latestCategoryHours.put(dayOfWeek, new Map<String, Time> { 'start' => newStartTime, 'end' => newEndTime });
		                        }
		                        else {
		                        	Map<String, Time> hours = latestCategoryHours.get(dayOfWeek);
		                        	Time startTime = hours.get('start');
		                        	Time endTime = hours.get('end');

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
		                        	
		                        	latestCategoryHours.put(dayOfWeek, hours);
		                        }
		                    }
		                }
		            }
		            */

		            latestHours.put(category, latestCategoryHours);
		        }
		    }
        }

        return latestHours;
    }

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

}
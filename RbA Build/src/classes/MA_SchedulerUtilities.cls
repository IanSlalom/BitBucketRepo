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
	
	/*
	public static DateTime convertLocalToTimezone(DateTime dt, String timezone) {
		Integer currentOffset = determineTimezoneOffset(dt, null);
		Integer newOffset = determineTimezoneOffset(dt, timezone);

		Integer currentOffsetMinutes = determineOffsetMinutesFromTimezoneOffset(currentOffset);
		Integer newOffsetMinutes = determineOffsetMinutesFromTimezoneOffset(newOffset);

		dt = dt.addMinutes(currentOffsetMinutes - newOffsetMinutes);
		return dt;
	}
	*/
	
	public static DateTime convertTimezoneToTimezone(DateTime dt, String originalTimezone, String newTimezone) {
		Integer currentOffset = determineTimezoneOffset(dt, originalTimezone);
		Integer newOffset = determineTimezoneOffset(dt, newTimezone);

		Integer currentOffsetMinutes = determineOffsetMinutesFromTimezoneOffset(currentOffset);
		Integer newOffsetMinutes = determineOffsetMinutesFromTimezoneOffset(newOffset);

		/*
		Integer offset = currentOffsetMinutes - newOffsetMinutes;
		if (addOffset) {
			dt = dt.addMinutes(offset);
		}
		else {
			dt = dt.addMinutes(-offset);
		}
		*/

		Integer offset = newOffsetMinutes - currentOffsetMinutes;
		dt = dt.addMinutes(-offset);
		return dt;
	}

	/*
	public static DateTime convertClientSideTimezoneToTimezone(DateTime dt, String timezone, String offsetPageMinutes) {
		Integer offset = determineTimezoneOffset(dt, storeTimezone);
		Integer offsetMinutes = determineOffsetMinutesFromTimezoneOffset(offset);

		if (String.isNotBlank(offsetPageMinutes)) {
			offsetMinutes += Integer.valueOf(offsetPageMinutes);
		}

        dt = dt.addMinutes(-offsetMinutes);
        return dt;
	}
	*/

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
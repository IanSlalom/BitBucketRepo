global with sharing class MA_SchedulerBookingWindow implements Comparable {
	
	public Boolean isValid;
	public String dayOfWeek;
	public String windowStart;
	public String windowEnd;
    public String endDateTimeFormated;
    public String startDateTimeFormated;
    public DateTime endDateTime;
    public DateTime startDateTime;
    //public Set<Id> availableResources;
    public Map<Id, Set<Id>> resourceToSkillsMap;
    public Set<Id> bookedWorkOrders;
    public Set<Id> skillsMatched;
    //public Integer totalSkillsCount;
    public Map<Id, Integer> totalSkillsCountMap;
    //public Set<String> relatedWindows;
    public Boolean overbooked;

    //public MA_SchedulerBookingWindow(String dayOfWeek, Date day, Map<String, Object> window, Set<Id> resourceIds/*, DateTime startDateTime, DateTime endDateTime, Integer startDateOffsetMinutes, Integer endDateOffsetMinutes*/) {
    //public MA_SchedulerBookingWindow(String dayOfWeek, Date day, Map<String, Object> window, Set<Id> resourceIds, Time startTime, Time endTime, String storeTimezone) {
    //public MA_SchedulerBookingWindow(String dayOfWeek, Date day, Map<String, Object> window, Set<Id> resourceIds, DateTime startDateTime, DateTime endDateTime, String storeTimezone) {
    public MA_SchedulerBookingWindow(String dayOfWeek, Date day, Map<String, Object> window, Map<Id, Set<Id>> resourceToSkillsMap, Map<Id, Integer> totalSkillsCountMap, DateTime startDateTime, DateTime endDateTime, String storeTimezone, Map<Id, Map<String, Object>> resourceHours) {
        this.isValid = false;
        //this.relatedWindows = new Set<String>();

        /**/
        Date startOfWeek = day.toStartOfWeek();

        Map<String, Integer> dayNumMap = new Map<String, Integer> {
            'sunday' => 0,
            'monday' => 1,
            'tuesday' => 2,
            'wednesday' => 3,
            'thursday' => 4,
            'friday' => 5,
            'saturday' => 6
        };

        System.debug(day);
        System.debug(dayOfWeek);
        System.debug(startOfWeek.daysBetween(day));

        if (startOfWeek.daysBetween(day) == dayNumMap.get(dayOfWeek.toLowercase())) {
        /**/
        //if (DateTime.newInstance(day, Time.newInstance(12, 0, 0, 0)).format('EEEE').toLowercase() == dayOfWeek.toLowercase()) {


        	/*
        	System.debug(storeTimezone);
        	//System.debug(startTime);
        	//System.debug(endTime);
        	System.debug(startDateTime);
        	System.debug(endDateTime);
        	*/


        	this.windowStart = (String)window.get('start');
        	this.windowEnd = (String)window.get('end');
        	
            List<String> startWindowSplit = (windowStart).split(':');
            List<String> endWindowSplit = (windowEnd).split(':');

            Time startWindowTime = Time.newInstance(Integer.valueOf(startWindowSplit[0]), Integer.valueOf(startWindowSplit[1]), 0, 0);
            Time endWindowTime = Time.newInstance(Integer.valueOf(endWindowSplit[0]), Integer.valueOf(endWindowSplit[1]), 0, 0);

            DateTime startDateTimeTemp = DateTime.newInstance(day, startWindowTime);
            DateTime endDateTimeTemp = DateTime.newInstance(day, endWindowTime);

            //DateTime startDateTimeChecked = DateTime.newInstance(day, startTime);
            //DateTime endDateTimeChecked = DateTime.newInstance(day, endTime);

            //DateTime startDateTimeChecked = startDateTime;
            //DateTime endDateTimeChecked = endDateTime;

            List<String> startDateTimeCheckedTimeSplit = startDateTime.format('HH:mm', storeTimezone).split(':');
            Time startDateTimeCheckedTime = Time.newInstance(Integer.valueOf(startDateTimeCheckedTimeSplit[0]), Integer.valueOf(startDateTimeCheckedTimeSplit[1]), 0, 0);
            //DateTime startDateTimeChecked = DateTime.newInstance(day, startDateTime.time());
            DateTime startDateTimeChecked = DateTime.newInstance(day, startDateTimeCheckedTime);

            List<String> endDateTimeCheckedTimeSplit = endDateTime.format('HH:mm', storeTimezone).split(':');
            Time endDateTimeCheckedTime = Time.newInstance(Integer.valueOf(endDateTimeCheckedTimeSplit[0]), Integer.valueOf(endDateTimeCheckedTimeSplit[1]), 0, 0);
            //DateTime endDateTimeChecked = DateTime.newInstance(day, endDateTime.time());
            DateTime endDateTimeChecked = DateTime.newInstance(day, endDateTime.time());


            ///*
            if (startDateTime.format('HH:mm', storeTimezone) == endDateTime.format('HH:mm', storeTimezone)) {
            	//endDateTime = endDateTime.addDays(1);
            	//System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
            	
            	//endTime = '11:59 PM';
            	//System.debug(endTime);

            	if (startDateTime.format('HH:mm', storeTimezone) == '00:00') {
            		endDateTimeChecked = startDateTimeChecked.addDays(1);
            	}
            	else {
					endDateTimeChecked = startDateTimeChecked.addMinutes(30);
            	}

            	//endDateTime = endDateTime.addMinutes(1439);
            	//System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
            }
            //*/




            /*
            startDateTimeTemp = MA_SchedulerUtilities.convertTimezoneToTimezone(startDateTimeTemp, null, storeTimezone, false);
            endDateTimeTemp = MA_SchedulerUtilities.convertTimezoneToTimezone(endDateTimeTemp, null, storeTimezone, false);
            */

            startDateTimeTemp = MA_SchedulerUtilities.convertTimezoneToTimezone(startDateTimeTemp, null, storeTimezone);
            endDateTimeTemp = MA_SchedulerUtilities.convertTimezoneToTimezone(endDateTimeTemp, null, storeTimezone);

            startDateTimeChecked = MA_SchedulerUtilities.convertTimezoneToTimezone(startDateTimeChecked, null, storeTimezone);
            endDateTimeChecked = MA_SchedulerUtilities.convertTimezoneToTimezone(endDateTimeChecked, null, storeTimezone);


            /*
            Integer serverOffset = Integer.valueOf(startDateTimeTemp.format('Z'));
        	Integer storeOffset = Integer.valueOf(startDateTimeTemp.format('Z', storeTimezone));

			Integer storeOffsetMinutes = Math.mod(storeOffset, 100);
			Integer storeOffsetHours = (Integer)Math.floor(storeOffset / 100);
			storeOffsetMinutes += (storeOffsetHours * 60);
			//System.debug(storeOffsetMinutes);

			Integer serverOffsetMinutes = Math.mod(serverOffset, 100);
			Integer serverOffsetHours = (Integer)Math.floor(serverOffset / 100);
			serverOffsetMinutes += (serverOffsetHours * 60);
			//System.debug(serverOffsetMinutes);

			Integer offsetMinutes = storeOffsetMinutes - serverOffsetMinutes;
			//System.debug(offsetMinutes);

			startDateTimeTemp = startDateTimeTemp.addMinutes(-offsetMinutes);
			//System.debug(startDateTimeTemp);
            */
			/*
			startDateTimeTemp = DateTime.newInstance(day, startDateTimeTemp.time());
			System.debug(startDateTimeTemp);
			*/

			//endDateTimeTemp = endDateTimeTemp.addMinutes(-offsetMinutes);
			//System.debug(endDateTimeTemp);
			/*
			endDateTimeTemp = DateTime.newInstance(day, endDateTimeTemp.time());
			System.debug(endDateTimeTemp);
			*/



			/*
            startDateTime = startDateTime.addMinutes(-startDateOffsetMinutes);
            System.debug(startDateTime.format('MM/dd/yyyy HH:mm a Z'));
            System.debug(startDateTime.format('MM/dd/yyyy HH:mm a Z', storeTimezone));

            String startDateTimeZoneFormatted = startDateTime.format('MM/dd/yyyy HH:mm a', storeTimezone);
            String[] startDateTimeZoneFormattedSplit = startDateTimeZoneFormatted.split(' ');
            startDate = Date.parse(startDateTimeZoneFormattedSplit[0]);
            startTime = startDateTimeZoneFormattedSplit[1] + ' ' + startDateTimeZoneFormattedSplit[2];
            */





            /**/
            System.debug('NEW BOOKING WINDOW');
            System.debug(endDateTimeTemp.format('MM/dd/yyyy hh:mm a Z', storeTimezone) + '     >     ' + startDateTimeChecked.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
            //System.debug(startDateTimeTemp.format('MM/dd/yyyy h:mm a Z', storeTimezone));
            System.debug(startDateTimeTemp.format('MM/dd/yyyy h:mm a Z', storeTimezone) + '     <     ' + endDateTimeChecked.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
            //System.debug(endDateTimeTemp.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
            //

            System.debug(endDateTimeTemp.format() + '     >     ' + startDateTimeChecked.format());
            System.debug(startDateTimeTemp.format() + '     <     ' + endDateTimeChecked.format());

            System.debug(startDateTimeTemp);
            System.debug(startDateTimeChecked);
            System.debug(endDateTimeTemp);
            System.debug(endDateTimeChecked);
            /**/

            //System.debug(startDateTimeTemp < endDateTimeChecked && endDateTimeTemp > startDateTimeChecked);

            if (startDateTimeTemp < endDateTimeChecked && endDateTimeTemp > startDateTimeChecked) {
	            this.isValid = true;
	            this.dayOfWeek = dayOfWeek.capitalize();
	            //this.availableResources = new Set<Id>(resourceIds);
	            //this.availableResources = resourceIds.clone();
	            this.resourceToSkillsMap = resourceToSkillsMap.clone();
	            this.bookedWorkOrders = new Set<Id>();
	            this.skillsMatched = new Set<Id>();
	            //this.totalSkillsCount = 9999;
	            this.totalSkillsCountMap = totalSkillsCountMap.clone();
	            this.overbooked = false;
	            
	            this.startDateTime = startDateTimeTemp;
	            this.endDateTime = endDateTimeTemp;

	            this.startDateTimeFormated = this.startDateTime.format('MM/dd/yyyy hh:mm a', storeTimezone);
	            //this.endDateTimeFormated = this.endDateTime.format('MM/dd/yyyy hh:mm a', storeTimezone);
	            this.endDateTimeFormated = this.endDateTime.format('hh:mm a', storeTimezone);

	            //determineTotalSkillsCount();
	            checkResourceAvailability(day, resourceHours, startDateTimeTemp, endDateTimeTemp, storeTimezone);
	        }
        }
    }

    public void determineSkillsMatched() {
    	for (Set<Id> skillsSet : resourceToSkillsMap.values()) {
    		skillsMatched.addAll(skillsSet);
    	}
    }

    public void checkResourceAvailability(Date day, Map<Id, Map<String, Object>> resourceHours, DateTime startDateTimeChecked, DateTime endDateTimeChecked, String storeTimezone) {
    	Set<Id> resourceHoursKeySet = resourceHours.keySet();
        Set<Id> resourceSkillsMapKeySet = resourceToSkillsMap.keySet();
        resourceHoursKeySet.retainAll(resourceSkillsMapKeySet);

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

	            DateTime startDateTimeTemp = DateTime.newInstance(day, startTime);
	            DateTime endDateTimeTemp = DateTime.newInstance(day, endTime);

	            startDateTimeTemp = MA_SchedulerUtilities.convertTimezoneToTimezone(startDateTimeTemp, null, storeTimezone);
	            endDateTimeTemp = MA_SchedulerUtilities.convertTimezoneToTimezone(endDateTimeTemp, null, storeTimezone);

	            if (resourceToSkillsMap.containsKey(resourceId) && (startDateTimeTemp > startDateTimeChecked || endDateTimeTemp < endDateTimeChecked)) {
	            	for (Id skillId : resourceToSkillsMap.get(resourceId)) {
						if (totalSkillsCountMap.containsKey(skillId)) {
							Integer tempInt = totalSkillsCountMap.get(skillId);
							tempInt--;
							totalSkillsCountMap.put(skillId, tempInt);

							/*
							if (tempInt <= 0) {
								window.overbooked = true;
								break;
							}
							*/
						}
					}

		            resourceToSkillsMap.remove(resourceId);
		        }
    		}
    	}
    }

    /*
    public void determineTotalSkillsCount() {
    	totalSkillsCount = 0;
    	for (Set<Id> skillsSet : resourceToSkillsMap.values()) {
    		totalSkillsCount += skillsSet.size();
    	}
    }
    */

    /*
    public void determineTotalSkillsCount() {
    	List<Id> tempSkillsList = new List<Id>();
    	totalSkillsCountMap = new Map<Id, Integer>();
    	
    	for (Set<Id> skillsSet : resourceToSkillsMap.values()) {
    		tempSkillsList.addAll(skillsSet);
    	}

    	for (Id)
    }
    */

    global Integer compareTo(Object compareTo) {
        MA_SchedulerBookingWindow compareToBookingWindow = (MA_SchedulerBookingWindow)compareTo;

        //System.debug(this.startDateTime);
        //System.debug(compareToBookingWindow.startDateTime);

        if (this.startDateTime == compareToBookingWindow.startDateTime) {
            return 0;
        }
        else if (this.startDateTime < compareToBookingWindow.startDateTime) {
            return -1;
        }

        return 1;
    }

}
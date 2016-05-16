global with sharing class MA_SchedulerBookingWindow implements Comparable {
	
	public String dayOfWeek;
    public String windowEnd;
	public String windowStart;
    public DateTime endDateTime;
    public DateTime startDateTime;
    public String endDateTimeFormated;
    public String startDateTimeFormated;

    public Boolean isValid = false;
    public Boolean overbooked = false;
    public Set<Id> skillsMatched = new Set<Id>();
    public Set<Id> bookedWorkOrders = new Set<Id>();
    public Map<Id, Integer> totalSkillsCountMap = new Map<Id, Integer>();
    public Map<Id, Set<Id>> resourceToSkillsMap = new Map<Id, Set<Id>>();

    public MA_SchedulerBookingWindow(String dayOfWeek, Date day, Map<String, Object> window, Map<Id, Set<Id>> resourceToSkillsMap, Map<Id, Integer> totalSkillsCountMap, DateTime startDateTime, DateTime endDateTime, String storeTimezone, Map<Id, Map<String, Object>> resourceHours) {
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

        if (startOfWeek.daysBetween(day) == dayNumMap.get(dayOfWeek.toLowercase())) {
            DateTime endDateTimeChecked;
            this.windowEnd = (String)window.get('end');
            this.windowStart = (String)window.get('start');
            String endTimeString = endDateTime.format('HH:mm', storeTimezone);
            String startTimeString = startDateTime.format('HH:mm', storeTimezone);
            DateTime endDateTimeTemp = MA_SchedulerUtilities.createDateTimeFromBookingWindowMilitary(day, this.windowEnd, storeTimezone);
            DateTime startDateTimeTemp = MA_SchedulerUtilities.createDateTimeFromBookingWindowMilitary(day, this.windowStart, storeTimezone);
            DateTime startDateTimeChecked = MA_SchedulerUtilities.createDateTimeFromBookingWindowMilitary(day, startTimeString, storeTimezone);

            if (startTimeString == endTimeString) {
            	if (startTimeString == '00:00') {
            		endDateTimeChecked = startDateTimeChecked.addDays(1);
            	}
            	else {
					endDateTimeChecked = startDateTimeChecked.addMinutes(30);
            	}
            }
            else {
                endDateTimeChecked = MA_SchedulerUtilities.createDateTimeFromBookingWindowMilitary(day, endTimeString, storeTimezone);
            }

            if (startDateTimeTemp < endDateTimeChecked && endDateTimeTemp > startDateTimeChecked) {
	            this.isValid = true;
                this.endDateTime = endDateTimeTemp;
                this.startDateTime = startDateTimeTemp;
	            this.dayOfWeek = dayOfWeek.capitalize();
	            this.resourceToSkillsMap = resourceToSkillsMap.clone();
	            this.totalSkillsCountMap = totalSkillsCountMap.clone();
                this.endDateTimeFormated = this.endDateTime.format('hh:mm a', storeTimezone);
	            this.startDateTimeFormated = this.startDateTime.format('MM/dd/yyyy hh:mm a', storeTimezone);

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

                String endTimeString = (String)hoursMap.get('end');
    			String startTimeString = (String)hoursMap.get('start');

                DateTime endDateTimeTemp = MA_SchedulerUtilities.createDateTimeFromBookingWindowMilitary(day, endTimeString, storeTimezone);
                DateTime startDateTimeTemp = MA_SchedulerUtilities.createDateTimeFromBookingWindowMilitary(day, startTimeString, storeTimezone);

	            if (resourceToSkillsMap.containsKey(resourceId) && (startDateTimeTemp > startDateTimeChecked || endDateTimeTemp < endDateTimeChecked)) {
	            	for (Id skillId : resourceToSkillsMap.get(resourceId)) {
						if (totalSkillsCountMap.containsKey(skillId)) {
							Integer tempInt = totalSkillsCountMap.get(skillId);
							tempInt--;
							totalSkillsCountMap.put(skillId, tempInt);
						}
					}

		            resourceToSkillsMap.remove(resourceId);
		        }
    		}
            else {
                for (Id skillId : resourceToSkillsMap.get(resourceId)) {
                    if (totalSkillsCountMap.containsKey(skillId)) {
                        Integer tempInt = totalSkillsCountMap.get(skillId);
                        tempInt--;
                        totalSkillsCountMap.put(skillId, tempInt);
                    }
                }

                resourceToSkillsMap.remove(resourceId);
            }
    	}
    }

    global Integer compareTo(Object compareTo) {
        MA_SchedulerBookingWindow compareToBookingWindow = (MA_SchedulerBookingWindow)compareTo;

        if (this.startDateTime == compareToBookingWindow.startDateTime) {
            return 0;
        }
        else if (this.startDateTime < compareToBookingWindow.startDateTime) {
            return -1;
        }

        return 1;
    }

}
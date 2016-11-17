/************************************************************************************/
/*                                                                                  */
/*      This wrapper class holds the methods used to create booking windows         */
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
    public Set<DateTime> timeBlocksMissingASkill = new Set<DateTime>();
    public Map<Id, Integer> totalSkillsCountMap = new Map<Id, Integer>();
    public Map<Id, Set<Id>> resourceToSkillsMap = new Map<Id, Set<Id>>();
    public Map<Id, Set<Id>> originalResourceToSkillsMap = new Map<Id, Set<Id>>();
    public Map<DateTime, Set<Id>> resourceTimeAvailabilityMap = new Map<DateTime, Set<Id>>();
    public Map<DateTime, Map<Id, Integer>> skillsTimeAvailabilityMap = new Map<DateTime, Map<Id, Integer>>();

    /****************************************************/
    /*                                                  */
    /*      detemines if window is valid for a day      */
    /*      and creates the window if so                */
    /*                                                  */
    /****************************************************/
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

            /*
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
            */

            endDateTimeChecked = startDateTimeChecked.addDays(1);

            if (startDateTimeTemp < endDateTimeChecked && endDateTimeTemp > startDateTimeChecked) {
	            this.isValid = true;
                this.endDateTime = endDateTimeTemp;
                this.startDateTime = startDateTimeTemp;
	            this.dayOfWeek = dayOfWeek.capitalize();
	            this.resourceToSkillsMap = resourceToSkillsMap.clone();
	            this.totalSkillsCountMap = totalSkillsCountMap.clone();
                this.originalResourceToSkillsMap = resourceToSkillsMap.clone();
                this.endDateTimeFormated = this.endDateTime.format('hh:mm a', storeTimezone);
	            this.startDateTimeFormated = this.startDateTime.format('MM/dd/yyyy hh:mm a', storeTimezone);
                
	            checkResourceAvailability(day, resourceHours, startDateTimeTemp, endDateTimeTemp, storeTimezone);
                createSubWindows();
	        }
        }
    }

    /****************************************************************/
    /*                                                              */
    /*      creates a map of 30 minute booking windows              */
    /*      to available skills to solve overlapping                */
    /*      booking windows                                         */
    /*                                                              */
    /****************************************************************/
    public void createSubWindows() {
        DateTime loopDateTimeStart = startDateTime;

        while (loopDateTimeStart < endDateTime) {
            /*
            skillsTimeAvailabilityMap.put(loopDateTimeStart, totalSkillsCountMap.clone());
            loopDateTimeStart = loopDateTimeStart.addMinutes(30);
            */

            Set<Id> tempBadResourceTimesSet = new Set<Id>();
            Map<Id, Integer> tempSkillsTimeMap = new Map<Id, Integer>();
            Map<Id, Integer> skillsCountMapClone = totalSkillsCountMap.clone();
            Set<Id> availableResourceIds = originalResourceToSkillsMap.keySet().clone();

            if (skillsTimeAvailabilityMap.containsKey(loopDateTimeStart)) {
                tempSkillsTimeMap = skillsTimeAvailabilityMap.get(loopDateTimeStart);
            }

            if (resourceTimeAvailabilityMap.containsKey(loopDateTimeStart)) {
                tempBadResourceTimesSet = resourceTimeAvailabilityMap.get(loopDateTimeStart);
                availableResourceIds.removeAll(tempBadResourceTimesSet);
            }

            if (!resourceTimeAvailabilityMap.containsKey(loopDateTimeStart)) {
                resourceTimeAvailabilityMap.put(loopDateTimeStart, new Set<Id>());
            }

            for (Id skillId : tempSkillsTimeMap.keySet()) {
                if (skillsCountMapClone.containsKey(skillId)) {
                    Integer tempInt = skillsCountMapClone.get(skillId);
                    tempInt += tempSkillsTimeMap.get(skillId);
                    skillsCountMapClone.put(skillId, tempInt);
                }
                /*
                else {
                    skillsCountMapClone.put(skillId, 1);
                }
                */
            }

            resourceTimeAvailabilityMap.put(loopDateTimeStart, availableResourceIds);
            skillsTimeAvailabilityMap.put(loopDateTimeStart, skillsCountMapClone);
            loopDateTimeStart = loopDateTimeStart.addMinutes(30);
        }
    }

    /****************************************************/
    /*                                                  */
    /*      creates a list of matched skills            */
    /*      for the booking window                      */
    /*                                                  */
    /****************************************************/
    public void determineSkillsMatched() {
    	for (Set<Id> skillsSet : resourceToSkillsMap.values()) {
    		skillsMatched.addAll(skillsSet);
    	}
    }

    /****************************************************/
    /*                                                  */
    /*      determines which resources are not          */
    /*      available for this window and removes       */
    /*      them and their skills match                 */
    /*                                                  */
    /****************************************************/
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

                        DateTime loopDateTimeEnd = DateTime.now();
                        DateTime loopDateTimeStart = loopDateTimeEnd;
                        DateTime startDateTimeCheckedTemp = startDateTimeChecked;

                        if (startDateTimeTemp > startDateTimeChecked && startDateTimeTemp < endDateTimeChecked) {
                            loopDateTimeEnd = endDateTimeChecked;
                            loopDateTimeStart = startDateTimeTemp;
                        }
                        else if (endDateTimeTemp > startDateTimeChecked && endDateTimeTemp < endDateTimeChecked) {
                            loopDateTimeEnd = endDateTimeTemp;
                            loopDateTimeStart = startDateTimeChecked;
                        }

                        while (startDateTimeCheckedTemp < endDateTimeChecked) {
                            if (startDateTimeCheckedTemp < loopDateTimeStart || startDateTimeCheckedTemp >= loopDateTimeEnd) {
                                if (!resourceTimeAvailabilityMap.containsKey(startDateTimeCheckedTemp)) {
                                    resourceTimeAvailabilityMap.put(startDateTimeCheckedTemp, new Set<Id>());
                                }

                                resourceTimeAvailabilityMap.get(startDateTimeCheckedTemp).add(resourceId);
                            }
                            else {
                                Map<Id, Integer> tempSkillsTimeMap = new Map<Id, Integer>();

                                if (skillsTimeAvailabilityMap.containsKey(startDateTimeCheckedTemp)) {
                                    tempSkillsTimeMap = skillsTimeAvailabilityMap.get(startDateTimeCheckedTemp);
                                }

                                if (tempSkillsTimeMap.containsKey(skillId)) {
                                    Integer tempInt = tempSkillsTimeMap.get(skillId);
                                    tempInt--;
                                    tempSkillsTimeMap.put(skillId, tempInt);
                                }
                                else {
                                    tempSkillsTimeMap.put(skillId, 1);
                                }

                                skillsTimeAvailabilityMap.put(startDateTimeCheckedTemp, tempSkillsTimeMap);
                            }
                            
                            startDateTimeCheckedTemp = startDateTimeCheckedTemp.addMinutes(30);
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

    /****************************************************/
    /*                                                  */
    /*      used to properly sort a list of windows     */
    /*                                                  */
    /****************************************************/
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
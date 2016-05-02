global with sharing class MA_SchedulerEvent {

	public Id workOrderId;
	//public Id resourceId;
	public String resourceId;
	public String title;
	public DateTime startDateTime;
	public DateTime endDateTime;
	public DateTime startDateTimeOffset;
	public DateTime endDateTimeOffset;
	public String className;
	public Boolean editable = false;
	public String url;
	public String contactName;
	public String eventType;
	public Boolean missingResource = false;
	public Boolean needsBookedWindowChecked = false;
	public Map<Id, String> assignedResourceMap = new Map<Id, String>();
	public List<MA_SchedulerEvent> relatedEvents = new List<MA_SchedulerEvent>();
	public DateTime estimatedStartDateTime;
	public DateTime estimatedEndDateTime;
	public DateTime estimatedStartDateTimeOffset;
	public DateTime estimatedEndDateTimeOffset;
	public List<String> resourceNames = new List<String>();
	public String resourceNamesText = '';
	public String city;

	public MA_SchedulerEvent() {}

	public MA_SchedulerEvent(SObject obj, Object objMap, Boolean isDisplay) {
		Schema.SObjectType objType = obj.getSObjectType();
		if (objType == Event.getSObjectType()) {
			convertStandardEvent((Event)obj, (Map<Id, Id>)objMap);
		}
		else if (objType == MA_Scheduler_Event__c.getSObjectType()) {
			convertMASchedulerEvent((MA_Scheduler_Event__c)obj, isDisplay);
		}
	}

	public MA_SchedulerEvent(Object obj, String objType) {
		if (objType == 'storeHoliday') {
			convertStoreHoliday((Map<String, Object>)obj);
		}
	}

	public MA_SchedulerEvent(SObject obj, Object objMap, String storeTimezone, String eventCreatedFrom, List<MA_SchedulerBookingWindow> allBookingWindows) {
		Schema.SObjectType objType = obj.getSObjectType();
		if (objType == RbA_Work_Order__c.getSObjectType()) {
			convertWorkOrderEvent((RbA_Work_Order__c)obj, (Map<String, Map<String, Object>>)objMap, storeTimezone, eventCreatedFrom, allBookingWindows);
		}
	}

	public void convertStoreHoliday(Map<String, Object> holiday) {
		workOrderId = null;
		//title = sfEvent.Subject;
		title = (String)holiday.get('reason');
		if (String.isBlank(title)) {
			title = 'Holiday';
		}
		startDateTime = DateTime.newInstance(Date.parse((String)holiday.get('date')), Time.newInstance(0, 0, 0, 0));
		endDateTime = startDateTime.addDays(1);
		resourceId = resourceId = startDateTime.format('EEE MMM dd yyyy');
		className = 'holiday';
		//url = new PageReference('/' + workOrderId).getUrl();
		url = '';
		contactName = '';
		eventType = 'holiday';
	}

	public void convertStandardEvent(Event sfEvent, Map<Id, Id> userMap) {
		workOrderId = sfEvent.WhatId;
		resourceId = userMap != null && userMap.containsKey(sfEvent.OwnerId) ? userMap.get(sfEvent.OwnerId) : sfEvent.OwnerId;
		//title = sfEvent.Subject;
		title = sfEvent.Subject;
		startDateTime = sfEvent.StartDateTime;
		endDateTime = sfEvent.EndDateTime;
		className = 'sfEvent';
		//url = new PageReference('/' + workOrderId).getUrl();
		url = '';
		contactName = '';
		eventType = 'personal';
	}

	public void convertMASchedulerEvent(MA_Scheduler_Event__c maEvent, Boolean isDisplay) {
		workOrderId = maEvent.RbA_Work_Order__c;
		resourceId = maEvent.Resource__c;
		title = maEvent.Name;
		startDateTime = maEvent.StartDateTime__c;
		endDateTime = maEvent.EndDateTime__c;
		url = new PageReference('/' + workOrderId).getUrl();
		contactName = discoverContactName(maEvent.RbA_Work_Order__r);
		eventType = maEvent.RbA_Work_Order__r.Work_Order_Type__c.toLowerCase().deleteWhitespace();
		missingResource = maEvent.Resource__c == null;
		className = 'maEvent' + (missingResource ? ' missingResource' : '');
		addResource(maEvent.Resource__r.Name);
		city = maEvent.RbA_Work_Order__r.City__c;

		if (missingResource && isDisplay) {
			resourceId = startDateTime.format('EEE MMM dd yyyy');
		}

		estimatedStartDateTime = maEvent.Estimated_Start_Date_Time__c;
		estimatedEndDateTime = maEvent.Estimated_End_Date_Time__c;
	}

	public void convertWorkOrderEvent(RbA_Work_Order__c woEvent, Map<String, Map<String, Object>> latestHours, String storeTimezone, String eventCreatedFrom, List<MA_SchedulerBookingWindow> allBookingWindows) {
		workOrderId = woEvent.Id;
		title = woEvent.Name;

		url = new PageReference('/' + workOrderId).getUrl();
		contactName = discoverContactName(woEvent);
		eventType = woEvent.Work_Order_Type__c.toLowerCase().deleteWhitespace();
		className = 'woEvent';
		missingResource = woEvent.Assigned_Resources__r.isEmpty();

		for (Assigned_Resources__c resource : woEvent.Assigned_Resources__r) {
			assignedResourceMap.put(resource.Scheduled_Resource__c, resource.Scheduled_Resource__r.Name);
		}


		/*
		startDateTime = DateTime.newInstance(woEvent.Appointment_Date__c, woEvent.Appointment_Start_Time__c);
		endDateTime = DateTime.newInstance(woEvent.Appointment_Date__c, woEvent.Appointment_End_Time__c);
		*/
		//if (woEvent.Appointment_Date__c != null && String.isNotBlank(woEvent.Appointment_Start_Time__c) && String.isNotBlank(woEvent.Appointment_End_Time__c)) {
		if (woEvent.Appointment_Date__c != null && String.isNotBlank(woEvent.Appointment_Start_Time__c) && (String.isNotBlank(woEvent.Appointment_Start_Time__c) || woEvent.Appointment_Duration__c != null)) {
			startDateTime = DateTime.parse(woEvent.Appointment_Date__c.format() + ' ' + woEvent.Appointment_Start_Time__c);
			resourceId = startDateTime.format('EEE MMM dd yyyy');

			System.debug(woEvent);
			System.debug(latestHours);

			if (woEvent.Appointment_Duration__c == null) {
				endDateTime = DateTime.parse(woEvent.Appointment_Date__c.format() + ' ' + woEvent.Appointment_End_Time__c);
			}
			else {
				Integer totalMinutes = (Integer)(woEvent.Appointment_Duration__c * 60);
				endDateTime = startDateTime.addMinutes(totalMinutes);
				//DateTime originalEndDateTime = endDateTime;

				Map<Integer, String> dayNumMap = new Map<Integer, String> {
		            0 => 'Sunday',
		            1 => 'Monday',
		            2 => 'Tuesday',
		            3 => 'Wednesday',
		            4 => 'Thursday',
		            5 => 'Friday',
		            6 => 'Saturday'
		        };

		        Date startOfWeek = woEvent.Appointment_Date__c.toStartOfWeek();
		        Integer daysBetweenStartOfWeek = startOfWeek.daysBetween(woEvent.Appointment_Date__c);
		        String dayOfWeek = dayNumMap.get(daysBetweenStartOfWeek);
			        
				if (latestHours != null && !latestHours.isEmpty() && latestHours.get(dayOfWeek) != null) {
			        DateTime daysEndDateTime = DateTime.newInstance(woEvent.Appointment_Date__c, (Time)(latestHours.get(dayOfWeek).get('end')));
		        	
		        	if (endDateTime > daysEndDateTime) {
		        		endDateTime = daysEndDateTime;
		        	}

		        	Long totalMillisecondDifference = endDateTime.getTime() - startDateTime.getTime();
		        	totalMinutes -= (Integer)(totalMillisecondDifference / 1000 / 60); 

		        	DateTime nextDateTime = startDateTime;
		        	DateTime nextDaysEndDateTime = endDateTime;

			        while (totalMinutes > 0) {
			        	System.debug(totalMinutes);

			        	nextDateTime = nextDateTime.addDays(1);
			        	daysBetweenStartOfWeek += 1;
			        	String nextDayOfWeek = dayNumMap.get(Math.mod(daysBetweenStartOfWeek, 7));
			        	Map<String, Object> nextDaysHours = latestHours.get(nextDayOfWeek);

			        	if (nextDaysHours != null) {
				        	DateTime nextDaysStartDateTime = DateTime.newInstance(nextDateTime.date(), (Time)nextDaysHours.get('start'));

				        	if (nextDaysStartDateTime != null) {
				        		nextDaysEndDateTime = nextDaysStartDateTime.addMinutes(totalMinutes);
				        		DateTime nextDaysFinalEndDateTime = DateTime.newInstance(nextDateTime.date(), (Time)nextDaysHours.get('end'));
		        	
					        	if (nextDaysEndDateTime > nextDaysFinalEndDateTime) {
					        		nextDaysEndDateTime = nextDaysFinalEndDateTime;
					        	}

					        	totalMillisecondDifference = nextDaysFinalEndDateTime.getTime() - nextDaysStartDateTime.getTime();
					        	totalMinutes -= (Integer)(totalMillisecondDifference / 1000 / 60); 

					        	MA_SchedulerEvent relatedEvent = new MA_SchedulerEvent();
					        	relatedEvent.workOrderId = this.workOrderId;
								relatedEvent.title = this.title;
								relatedEvent.relatedEvents = new List<MA_SchedulerEvent>();

								relatedEvent.editable = this.editable;
								relatedEvent.url = this.url;
								relatedEvent.contactName = this.contactName;
								relatedEvent.eventType = this.eventType;
								relatedEvent.className = this.className;
								relatedEvent.missingResource = this.missingResource;
								relatedEvent.assignedResourceMap = this.assignedResourceMap;
								relatedEvent.resourceId = nextDaysStartDateTime.format('EEE MMM dd yyyy');
								relatedEvent.needsBookedWindowChecked = this.needsBookedWindowChecked;
								relatedEvent.resourceNames = this.resourceNames;

					        	relatedEvent.startDateTime = nextDaysStartDateTime;
					        	relatedEvent.endDateTime = nextDaysEndDateTime;

					        	/*if (eventCreatedFrom == 'availablityCheck') {
					        		relatedEvent.setBookingWindowsOverlappingWorkOrders(allBookingWindows);
					        	}
					        	else*/ if (eventCreatedFrom == 'retrievingEvents') {
					        		relatedEvent.createOffsetTimes(null);
					        	}

					        	this.relatedEvents.add(relatedEvent);
					        }
					    }
			        }


		        	if (eventCreatedFrom == 'availablityCheck') {
			        	MA_SchedulerEvent relatedEvent = new MA_SchedulerEvent();
			        	relatedEvent.workOrderId = this.workOrderId;
						relatedEvent.title = this.title;
						relatedEvent.relatedEvents = new List<MA_SchedulerEvent>();

						relatedEvent.editable = this.editable;
						relatedEvent.url = this.url;
						relatedEvent.contactName = this.contactName;
						relatedEvent.eventType = this.eventType;
						relatedEvent.className = this.className;
						relatedEvent.missingResource = this.missingResource;
						relatedEvent.assignedResourceMap = this.assignedResourceMap;
						relatedEvent.resourceId = this.resourceId;
						relatedEvent.needsBookedWindowChecked = this.needsBookedWindowChecked;
						relatedEvent.resourceNames = this.resourceNames;

			        	relatedEvent.startDateTime = this.startDateTime;
			        	relatedEvent.endDateTime = this.endDateTime;

			        	this.relatedEvents.add(relatedEvent);
			        	this.endDateTime = nextDaysEndDateTime;
		        	}
			    }



				
			}
			
		}
	}

	private String discoverContactName(RbA_Work_Order__c workOrder) {
		String name = '';
		if (String.isNotBlank(workOrder.Contact__c)) {
			name = workOrder.Contact__r.LastName + (String.isNotBlank(workOrder.Contact__r.FirstName) ? ', ' + workOrder.Contact__r.FirstName : '');
		}
		return name;
	}

	public void addResource(String resourceName) {
		resourceNames.add(resourceName);
		if (!resourceNames.isEmpty()) {
			resourceNamesText = String.join(resourceNames, ', ');
		}
	}

	/*
	public void createOffsetTimes(Integer offset) {
		DateTime startDateTimeUtcTemp = startDateTime.addHours(offset);
		DateTime endDateTimeUtcTemp = endDateTime.addHours(offset);

		startDateTimeOffset = DateTime.newInstance(startDateTimeUtcTemp.year(), startDateTimeUtcTemp.month(), startDateTimeUtcTemp.day(), startDateTimeUtcTemp.hour(), startDateTimeUtcTemp.minute(), startDateTimeUtcTemp.second());
		endDateTimeOffset = DateTime.newInstance(endDateTimeUtcTemp.year(), endDateTimeUtcTemp.month(), endDateTimeUtcTemp.day(), endDateTimeUtcTemp.hour(), endDateTimeUtcTemp.minute(), endDateTimeUtcTemp.second());
	}
	*/

	public void createOffsetTimes(String storeTimezone) {
		startDateTimeOffset = DateTime.newInstanceGmt(startDateTime.year(), startDateTime.month(), startDateTime.day(), startDateTime.hour(), startDateTime.minute(), startDateTime.second());
		endDateTimeOffset = DateTime.newInstanceGmt(endDateTime.year(), endDateTime.month(), endDateTime.day(), endDateTime.hour(), endDateTime.minute(), endDateTime.second());

		if (String.isNotBlank(storeTimezone)) {
			startDateTimeOffset = MA_SchedulerUtilities.convertTimezoneToTimezone(startDateTimeOffset, storeTimezone, null);
			endDateTimeOffset = MA_SchedulerUtilities.convertTimezoneToTimezone(endDateTimeOffset, storeTimezone, null);
		}

		if (estimatedStartDateTime != null && estimatedEndDateTime != null) {
			estimatedStartDateTimeOffset = DateTime.newInstanceGmt(estimatedStartDateTime.year(), estimatedStartDateTime.month(), estimatedStartDateTime.day(), estimatedStartDateTime.hour(), estimatedStartDateTime.minute(), estimatedStartDateTime.second());
			estimatedEndDateTimeOffset = DateTime.newInstanceGmt(estimatedEndDateTime.year(), estimatedEndDateTime.month(), estimatedEndDateTime.day(), estimatedEndDateTime.hour(), estimatedEndDateTime.minute(), estimatedEndDateTime.second());

			if (String.isNotBlank(storeTimezone)) {
				estimatedStartDateTimeOffset = MA_SchedulerUtilities.convertTimezoneToTimezone(estimatedStartDateTimeOffset, storeTimezone, null);
				estimatedEndDateTimeOffset = MA_SchedulerUtilities.convertTimezoneToTimezone(estimatedEndDateTimeOffset, storeTimezone, null);
			}
		}
	}

	/*
	public void createOffsetTimes(String storeTimezone) {
		*//*
		Integer offset = Integer.valueOf(DateTime.now().format('Z', storeTimezone));
		Integer offsetMinutes = Math.mod(offset, 100);
		Integer offsetHours = (Integer)Math.floor(offset / 100);
		offsetMinutes += (offsetHours * 60) + Integer.valueOf(offsetPageMinutes);

        startDateTime = startDateTime.addMinutes(-offsetMinutes);
        System.debug(startDateTime.format('MM/dd/yyyy HH:mm a Z'));
        System.debug(startDateTime.format('MM/dd/yyyy HH:mm a Z', storeTimezone));

        String startDateTimeZoneFormatted = startDateTime.format('MM/dd/yyyy HH:mm a', storeTimezone);
        String[] startDateTimeZoneFormattedSplit = startDateTimeZoneFormatted.split(' ');
        startDate = Date.parse(startDateTimeZoneFormattedSplit[0]);
        startTime = startDateTimeZoneFormattedSplit[1] + ' ' + startDateTimeZoneFormattedSplit[2];

        endDateTime = endDateTime.addMinutes(-offsetMinutes);
        System.debug(endDateTime.format('MM/dd/yyyy HH:mm a Z'));
        System.debug(endDateTime.format('MM/dd/yyyy HH:mm a Z', storeTimezone));

        String endDateTimeZoneFormatted = endDateTime.format('MM/dd/yyyy HH:mm a', storeTimezone);
        String[] endDateTimeZoneFormattedSplit = endDateTimeZoneFormatted.split(' ');
        endDate = Date.parse(endDateTimeZoneFormattedSplit[0]);
        endTime = endDateTimeZoneFormattedSplit[1] + ' ' + endDateTimeZoneFormattedSplit[2];
        */





        //System.debug(startDateTime.format('MM/dd/yyyy HH:mm a Z'));
        //System.debug(startDateTime.format('MM/dd/yyyy HH:mm a Z', UserInfo.getTimeZone().getId()));






        /*
		//Date today = Date.today();
        //Time sampleTime = Time.newInstance(6, 0, 0, 0);
		//DateTime serverTime = DateTime.newInstance(2009, 2, 16, 3, 0, 0);
		//DateTime utcTime = DateTime.newInstanceGmt(2009, 2, 16, 3, 0, 0);
		//DateTime serverTime = DateTime.now();
		//DateTime serverTime = DateTime.newInstance(Long.valueOf(startDateTimeEpoch));
		DateTime utcTime = DateTime.newInstanceGmt(startDateTime.year(), startDateTime.month(), startDateTime.day(), startDateTime.hour(), startDateTime.minute(), startDateTime.second());
		//System.debug(utcTime);
		//Long serverTimeLong = serverTime.getTime();
		//Long utcTimeLong = utcTime.getTime();
		//Long timeDiffLong = utcTimeLong - serverTimeLong;
		Long timeDiffLong = utcTime.getTime() - startDateTime.getTime();
		Integer hoursDiff = (Integer)(timeDiffLong / 1000 / 60 / 60);

		//System.debug(hoursDiff);

		DateTime startDateTimeTemp = startDateTime.addHours(hoursDiff);
		//System.debug(startDateTimeTemp);



		//Date today = Date.today();
        //Time sampleTime = Time.newInstance(6, 0, 0, 0);
		//DateTime serverTime = DateTime.newInstance(2009, 2, 16, 3, 0, 0);
		//DateTime utcTime = DateTime.newInstanceGmt(2009, 2, 16, 3, 0, 0);
		//DateTime serverTime = DateTime.now();
		//DateTime serverTime = DateTime.newInstance(Long.valueOf(startDateTimeEpoch));
		utcTime = DateTime.newInstanceGmt(endDateTime.year(), endDateTime.month(), endDateTime.day(), endDateTime.hour(), endDateTime.minute(), endDateTime.second());
		//Long serverTimeLong = serverTime.getTime();
		//Long utcTimeLong = utcTime.getTime();
		//Long timeDiffLong = utcTimeLong - serverTimeLong;
		timeDiffLong = utcTime.getTime() - endDateTime.getTime();
		hoursDiff = (Integer)(timeDiffLong / 1000 / 60 / 60);

		DateTime endDateTimeTemp = endDateTime.addHours(hoursDiff);
		*/












		/*
        Integer startServerOffset = Integer.valueOf(startDateTime.format('Z'));
    	Integer startStoreOffset = Integer.valueOf(startDateTime.format('Z', storeTimezone));

		Integer startStoreOffsetMinutes = Math.mod(startStoreOffset, 100);
		Integer startStoreOffsetHours = (Integer)Math.floor(startStoreOffset / 100);
		startStoreOffsetMinutes += (startStoreOffsetHours * 60);
		System.debug(startStoreOffsetMinutes);

		Integer startServerOffsetMinutes = Math.mod(startServerOffset, 100);
		Integer startServerOffsetHours = (Integer)Math.floor(startServerOffset / 100);
		startServerOffsetMinutes += (startServerOffsetHours * 60);
		System.debug(startServerOffsetMinutes);

		Integer startOffsetMinutes = startStoreOffsetMinutes - startServerOffsetMinutes;
		System.debug(startOffsetMinutes);

		DateTime startDateTimeTemp = startDateTime.addMinutes(-startOffsetMinutes);
		System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
		System.debug(startDateTimeTemp.format('MM/dd/yyyy hh:mm a Z', storeTimezone));













        Integer endServerOffset = Integer.valueOf(endDateTime.format('Z'));
    	Integer endStoreOffset = Integer.valueOf(endDateTime.format('Z', storeTimezone));

		Integer endStoreOffsetMinutes = Math.mod(endStoreOffset, 100);
		Integer endStoreOffsetHours = (Integer)Math.floor(endStoreOffset / 100);
		endStoreOffsetMinutes += (endStoreOffsetHours * 60);
		System.debug(endStoreOffsetMinutes);

		Integer endServerOffsetMinutes = Math.mod(endServerOffset, 100);
		Integer endServerOffsetHours = (Integer)Math.floor(endServerOffset / 100);
		endServerOffsetMinutes += (endServerOffsetHours * 60);
		System.debug(endServerOffsetMinutes);

		Integer endOffsetMinutes = endStoreOffsetMinutes - endServerOffsetMinutes;
		System.debug(endOffsetMinutes);

		DateTime endDateTimeTemp = endDateTime.addMinutes(-endOffsetMinutes);
		System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
		System.debug(endDateTimeTemp.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
		*/






		/*
		startDateTimeOffset = DateTime.newInstanceGmt(startDateTimeTemp.year(), startDateTimeTemp.month(), startDateTimeTemp.day(), startDateTimeTemp.hour(), startDateTimeTemp.minute(), startDateTimeTemp.second());
		endDateTimeOffset = DateTime.newInstanceGmt(endDateTimeTemp.year(), endDateTimeTemp.month(), endDateTimeTemp.day(), endDateTimeTemp.hour(), endDateTimeTemp.minute(), endDateTimeTemp.second());
		*//*


		startDateTimeOffset = DateTime.newInstanceGmt(startDateTime.year(), startDateTime.month(), startDateTime.day(), startDateTime.hour(), startDateTime.minute(), startDateTime.second());
		endDateTimeOffset = DateTime.newInstanceGmt(endDateTime.year(), endDateTime.month(), endDateTime.day(), endDateTime.hour(), endDateTime.minute(), endDateTime.second());
	}
	*/



	public void setBookingWindowsAvailableResources(List<MA_SchedulerBookingWindow> allBookingWindows) {
		for (MA_SchedulerBookingWindow window : allBookingWindows) {

			/**/
			System.debug('EVENT FOR WINDOW BOOKING');
			System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
			System.debug(window.startDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
			System.debug(window.startDateTimeFormated);
			System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
			System.debug(window.endDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
			System.debug(window.endDateTimeFormated);
			/**/


			if (startDateTime < window.endDateTime && endDateTime > window.startDateTime) {
				//window.availableResources.remove(resourceId);

				/*
				System.debug('Bad Resource');
				System.debug(resourceId);
				System.debug(window.resourceToSkillsMap);
				window.resourceToSkillsMap.remove(resourceId);
				System.debug(window.resourceToSkillsMap);
				*/


				if (className.contains('maEvent') && String.isBlank(resourceId)) {
					needsBookedWindowChecked = true;
					//window.bookedWorkOrders.add(workOrderId);

					/*
					if (!assignedResourceMap.isEmpty()) {
						//window.availableResources.removeAll(assignedResourceMap.keySet());
						for (Id assignedResourceId : assignedResourceMap.keySet()) {
							window.resourceToSkillsMap.remove(assignedResourceId);
						}
						
					}
					*/
				}
				else {
					System.debug('Bad Resource');
					System.debug(resourceId);
					System.debug(window.resourceToSkillsMap);
					if (window.resourceToSkillsMap.get(resourceId) != null ) {
						//window.totalSkillsCount -= window.resourceToSkillsMap.get(resourceId).size();
						checkWindowOverbooked(window, window.resourceToSkillsMap.get(resourceId));
					}
					window.resourceToSkillsMap.remove(resourceId);
					System.debug(window.resourceToSkillsMap);
				}
			}
		}
	}

	public void checkWindowOverbooked(MA_SchedulerBookingWindow window, Set<Id> workOrderSkills) {
		if (!window.overbooked) {
			//window.totalSkillsCount -= window.resourceToSkillsMap.get(resourceId).size();

			System.debug(window.totalSkillsCountMap);
			System.debug(workOrderSkills);

			for (Id skillId : workOrderSkills) {
				if (window.totalSkillsCountMap.containsKey(skillId)) {
					Integer tempInt = window.totalSkillsCountMap.get(skillId);
					tempInt--;
					window.totalSkillsCountMap.put(skillId, tempInt);

					if (tempInt <= 0) {
						window.overbooked = true;
						break;
					}
				}
			}
		}
	}





	public void setBookingWindowsOverlappingWorkOrders(List<MA_SchedulerBookingWindow> allBookingWindows, Map<Id, Set<Id>> woToSkillsMap, Set<Id> workOrderSkills) {
		for (MA_SchedulerBookingWindow window : allBookingWindows) {

			if (workOrderId == 'a0V4B000000SN7GUAW') {

				/*
				System.debug('WORK ORDER FOR WINDOW BOOKING');
				System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
				System.debug(window.startDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
				System.debug(window.startDateTimeFormated);
				System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
				System.debug(window.endDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
				System.debug(window.endDateTimeFormated);
				*/

			}


			if (startDateTime < window.endDateTime && endDateTime > window.startDateTime) {
				Set<Id> workOrderSkillToCompare = woToSkillsMap.get(workOrderId);
				System.debug(workOrderSkillToCompare);
				if (workOrderSkillToCompare != null && !workOrderSkillToCompare.isEmpty()) {
					//window.totalSkillsCount -= workOrderSkillToCompare.size();
					checkWindowOverbooked(window, workOrderSkillToCompare);
				}

			}

			/*
			if (woToSkillMap.containsKey(workOrderId) && startDateTime < window.endDateTime && endDateTime > window.startDateTime) {
				Set<Id> workOrderSkillToCompare = woToSkillMap.get(workOrderId);
				if (workOrderSkillToCompare != null && !workOrderSkillToCompare.isEmpty()) {
					window.bookedWorkOrders.add(workOrderId);
					window.totalSkillsCount -= workOrderSkillToCompare.size();
				}


				*//*
				if (workOrderSkillToCompare != null && !workOrderSkillToCompare.isEmpty() && workOrderSkillToCompare.size() >= workOrderSkills.size()) {
					window.bookedWorkOrders.add(workOrderId);
					window.totalSkillsCount -= workOrderSkillToCompare.size();
				}
				else {

				}
				*/

				/*
				if (!assignedResourceMap.isEmpty()) {
					//window.availableResources.removeAll(assignedResourceMap.keySet());
					for (Id assignedResourceId : assignedResourceMap.keySet()) {
						window.resourceToSkillsMap.remove(assignedResourceId);
					}
					
				}
				*//*
			}
			*/
		}
	}






	/*
	public void setBookingWindowsOverlappingWorkOrders(List<MA_SchedulerBookingWindow> allBookingWindows) {
		for (MA_SchedulerBookingWindow window : allBookingWindows) {

			if (workOrderId == 'a0V4B000000SN7GUAW') {

				*//*
				System.debug('WORK ORDER FOR WINDOW BOOKING');
				System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
				System.debug(window.startDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
				System.debug(window.startDateTimeFormated);
				System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
				System.debug(window.endDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
				System.debug(window.endDateTimeFormated);
				*//*

			}


			if (startDateTime < window.endDateTime && endDateTime > window.startDateTime) {
				window.bookedWorkOrders.add(workOrderId);

				if (!assignedResourceMap.isEmpty()) {
					//window.availableResources.removeAll(assignedResourceMap.keySet());
					for (Id assignedResourceId : assignedResourceMap.keySet()) {
						window.resourceToSkillsMap.remove(assignedResourceId);
					}
					
				}
			}
		}
	}
	*/
	
}
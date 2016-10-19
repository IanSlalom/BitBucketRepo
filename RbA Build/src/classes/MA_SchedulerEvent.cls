/************************************************************************************/
/*                                                                                  */
/*      This wrapper class holds the methods used to 				                */
/* 		standardize events for the calendar 										*/
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

global with sharing class MA_SchedulerEvent {

	public String url;
	public String city;
	public String state;
	public String title;
	public Id workOrderId;
	public String className;
	public String eventType;
	public String resourceId;
	public String contactName;
	public DateTime endDateTime;
	public DateTime startDateTime;
	public DateTime endDateTimeOffset;
	public DateTime startDateTimeOffset;
	public DateTime estimatedEndDateTime;
	public DateTime estimatedStartDateTime;
	public DateTime estimatedEndDateTimeOffset;
	public DateTime estimatedStartDateTimeOffset;

	public Boolean isJip = false;
	public Boolean isLswp = false;
	public Boolean editable = false;
	public Boolean isSynced = false;
	public String multiDayOrder = '';
	public String resourceNamesText = '';
	public Boolean missingResource = false;
	public Boolean needsBookedWindowChecked = false;
	public List<String> resourceNames = new List<String>();
	public Map<Id, String> assignedResourceMap = new Map<Id, String>();
	public List<MA_SchedulerEvent> relatedEvents = new List<MA_SchedulerEvent>();

	/****************************************************/
    /*                                                  */
    /*      multiple constructors to initialize the     */
    /*      a MA_SchedulerEvent for various objects     */
    /*                                                  */
    /****************************************************/
    public MA_SchedulerEvent() {}

	public MA_SchedulerEvent(Object obj, String objType) {
		if (objType == 'storeHoliday') {
			convertStoreHoliday((Map<String, Object>)obj);
		}
	}

	public MA_SchedulerEvent(SObject obj, Object objMap, Boolean isDisplay) {
		Schema.SObjectType objType = obj.getSObjectType();
		if (objType == Event.getSObjectType()) {
			convertStandardEvent((Event)obj, (Map<Id, Id>)objMap);
		}
		else if (objType == MA_Scheduler_Event__c.getSObjectType()) {
			convertMASchedulerEvent((MA_Scheduler_Event__c)obj, isDisplay);
		}
	}

	/****************************************************/
    /*                                                  */
    /*      standardizes a store holiday 			    */
    /*                                                  */
    /****************************************************/
    public void convertStoreHoliday(Map<String, Object> holiday) {
		url = '';
		contactName = '';
		workOrderId = null;
		className = 'holiday';
		eventType = 'holiday';

		startDateTime = DateTime.newInstance(Date.parse((String)holiday.get('date')), Time.newInstance(0, 0, 0, 0));
		endDateTime = startDateTime.addDays(1);
		resourceId = resourceId = startDateTime.format('EEE MMM dd yyyy');

		title = (String)holiday.get('reason');
		if (String.isBlank(title)) {
			title = 'Holiday';
		}
	}

	/****************************************************/
    /*                                                  */
    /*      standardizes a Salesforce Event 			*/
    /*                                                  */
    /****************************************************/
    public void convertStandardEvent(Event sfEvent, Map<Id, Id> userMap) {
		url = '';
		contactName = '';
		className = 'sfEvent';
		eventType = 'personal';
		title = sfEvent.Subject;
		workOrderId = sfEvent.WhatId;
		endDateTime = sfEvent.EndDateTime;
		startDateTime = sfEvent.StartDateTime;
		resourceId = userMap != null && userMap.containsKey(sfEvent.OwnerId) ? userMap.get(sfEvent.OwnerId) : sfEvent.OwnerId;
	}

	/****************************************************/
    /*                                                  */
    /*      standardizes a MapAnything Event		    */
    /*                                                  */
    /****************************************************/
    public void convertMASchedulerEvent(MA_Scheduler_Event__c maEvent, Boolean isDisplay) {
		title = maEvent.Name;
		resourceId = maEvent.Resource__c;
		endDateTime = maEvent.EndDateTime__c;
		startDateTime = maEvent.StartDateTime__c;
		missingResource = maEvent.Resource__c == null;
		estimatedEndDateTime = maEvent.Estimated_End_Date_Time__c;
		contactName = discoverContactName(maEvent.RbA_Work_Order__r);
		estimatedStartDateTime = maEvent.Estimated_Start_Date_Time__c;
		className = 'maEvent' + (missingResource ? ' missingResource' : '');

		if (maEvent.RbA_Work_Order__c != null) {
			workOrderId = maEvent.RbA_Work_Order__c;
			city = maEvent.RbA_Work_Order__r.City__c;
			state = maEvent.RbA_Work_Order__r.State__c;
			isLswp = maEvent.RbA_Work_Order__r.LSWP_Test_Results__c;
			isJip = maEvent.RbA_Work_Order__r.Service_Request_Type__c;
			isSynced = maEvent.RbA_Work_Order__r.Tech_Measure_Synced__c;
			eventType = maEvent.RbA_Work_Order__r.Work_Order_Type__c.toLowerCase().deleteWhitespace();

			if (maEvent.RbA_Work_Order__r.Total_Days__c != null && maEvent.RbA_Work_Order__r.Total_Days__c > 1) {
				multiDayOrder = maEvent.Event_Sequence__c != null ? ' ' + maEvent.Event_Sequence__c + (maEvent.RbA_Work_Order__r.Total_Days__c != null ? ' of ' + maEvent.RbA_Work_Order__r.Total_Days__c : '') : '';
			}
		}
		else {
			eventType = 'personal';
			className += ' personal';
			workOrderId = maEvent.Id;
		}

		url = new PageReference('/' + workOrderId).getUrl();
		addResource(maEvent.Resource__r.Name);

		if (missingResource && isDisplay) {
			resourceId = startDateTime.format('EEE MMM dd yyyy');
		}
	}

	/****************************************************/
    /*                                                  */
    /*      determines the related contact's name	    */
    /*                                                  */
    /****************************************************/
    private String discoverContactName(RbA_Work_Order__c workOrder) {
		String name = '';
		if (workOrder != null && String.isNotBlank(workOrder.Contact__c)) {
			name = workOrder.Contact__r.LastName + (String.isNotBlank(workOrder.Contact__r.FirstName) ? ', ' + workOrder.Contact__r.FirstName : '');
		}
		return name;
	}

	/****************************************************/
    /*                                                  */
    /*      adds a resource to the event 			    */
    /*                                                  */
    /****************************************************/
    public void addResource(String resourceName) {
		resourceNames.add(resourceName);
		if (!resourceNames.isEmpty()) {
			resourceNamesText = String.join(resourceNames, ', ');
		}
	}

	/****************************************************/
    /*                                                  */
    /*      determines the correct GMT times 		    */
    /* 		based on the store's timezone 				*/
    /*													*/
    /*		this is needed to properly align the 		*/
    /*		times between Salesforce and the calendar 	*/
    /*		to be viewed the same from any where 		*/
    /*                                                  */
    /****************************************************/
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

	/****************************************************/
    /*                                                  */
    /*      determines if this event is booked 		    */
    /* 		during a corresponding booking window 		*/
    /*		and is used to determine if there are 		*/
    /* 		more events booked/scheduled than there 	*/
    /*		are available resources 					*/
    /*                                                  */
    /****************************************************/
    public void setBookingWindowsAvailableResources(List<MA_SchedulerBookingWindow> allBookingWindows) {
		for (MA_SchedulerBookingWindow window : allBookingWindows) {
			if (startDateTime < window.endDateTime && endDateTime > window.startDateTime) {
				if (className.contains('maEvent') && String.isBlank(resourceId)) {
					needsBookedWindowChecked = true;
				}
				else {
					if (window.resourceToSkillsMap.get(resourceId) != null) {
						checkWindowOverbooked(window, window.resourceToSkillsMap.get(resourceId));
					}
					window.resourceToSkillsMap.remove(resourceId);
				}
			}
		}
	}

	/****************************************************/
    /*                                                  */
    /*      determines if a booking window has		    */
    /*		been overbooked and does not have 			*/
    /*		enough remaining skills matched				*/
    /*                                                  */
    /****************************************************/
    public void checkWindowOverbooked(MA_SchedulerBookingWindow window, Set<Id> workOrderSkills) {
		if (!window.overbooked) {
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

	/****************************************************/
    /*                                                  */
    /*      determines if this event is booked 		    */
    /* 		during a corresponding booking window 		*/
    /*		and is used to determine if there are 		*/
    /* 		more events booked/scheduled than there 	*/
    /*		are available resources 					*/
    /*                                                  */
    /****************************************************/
    public void setBookingWindowsOverlappingWorkOrders(List<MA_SchedulerBookingWindow> allBookingWindows, Map<Id, Set<Id>> woToSkillsMap, Set<Id> workOrderSkills) {
		for (MA_SchedulerBookingWindow window : allBookingWindows) {
			if (startDateTime < window.endDateTime && endDateTime > window.startDateTime) {
				Set<Id> workOrderSkillToCompare = woToSkillsMap.get(workOrderId);
				if (workOrderSkillToCompare != null && !workOrderSkillToCompare.isEmpty()) {
					checkWindowOverbooked(window, workOrderSkillToCompare);
				}

			}
		}
	}
	
}
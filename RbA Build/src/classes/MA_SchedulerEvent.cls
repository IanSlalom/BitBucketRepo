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
	public Boolean editable;
	public String url;
	public String contactName;
	public String eventType;
	public Boolean missingResource;

	public MA_SchedulerEvent(SObject obj, Map<Id, Id> userMap) {
		Schema.SObjectType objType = obj.getSObjectType();
		if (objType == Event.getSObjectType()) {
			convertStandardEvent((Event)obj, userMap);
		}
		else if (objType == MA_Scheduler_Event__c.getSObjectType()) {
			convertMASchedulerEvent((MA_Scheduler_Event__c)obj);
		}
		else if (objType == RbA_Work_Order__c.getSObjectType()) {
			convertMASchedulerEvent((RbA_Work_Order__c)obj);
		}
	}

	public void convertStandardEvent(Event sfEvent, Map<Id, Id> userMap) {
		workOrderId = sfEvent.WhatId;
		resourceId = userMap != null && userMap.containsKey(sfEvent.OwnerId) ? userMap.get(sfEvent.OwnerId) : sfEvent.OwnerId;
		//title = sfEvent.Subject;
		title = 'busy';
		startDateTime = sfEvent.StartDateTime;
		endDateTime = sfEvent.EndDateTime;
		className = 'sfEvent';
		editable = false;
		//url = new PageReference('/' + workOrderId).getUrl();
		url = '';
		contactName = '';
		eventType = '';
		missingResource = false;
	}

	public void convertMASchedulerEvent(MA_Scheduler_Event__c maEvent) {
		workOrderId = maEvent.RbA_Work_Order__c;
		resourceId = maEvent.Resource__c;
		title = maEvent.Name;
		startDateTime = maEvent.StartDateTime__c;
		endDateTime = maEvent.EndDateTime__c;
		editable = false;
		url = new PageReference('/' + workOrderId).getUrl();
		contactName = discoverContactName(maEvent.RbA_Work_Order__r);
		eventType = maEvent.RbA_Work_Order__r.Work_Order_Type__c.toLowerCase().deleteWhitespace();
		className = 'maEvent ' + eventType;
		missingResource = false;
	}

	public void convertMASchedulerEvent(RbA_Work_Order__c woEvent) {
		workOrderId = woEvent.Id;
		title = woEvent.Name;
		/*
		startDateTime = DateTime.newInstance(woEvent.Appointment_Date__c, woEvent.Appointment_Start_Time__c);
		endDateTime = DateTime.newInstance(woEvent.Appointment_Date__c, woEvent.Appointment_End_Time__c);
		*/
		if (woEvent.Appointment_Date__c != null && String.isNotBlank(woEvent.Appointment_Start_Time__c) && String.isNotBlank(woEvent.Appointment_End_Time__c)) {
			startDateTime = DateTime.parse(woEvent.Appointment_Date__c.format() + ' ' + woEvent.Appointment_Start_Time__c);
			endDateTime = DateTime.parse(woEvent.Appointment_Date__c.format() + ' ' + woEvent.Appointment_End_Time__c);
			resourceId = startDateTime.format('EEE MMM dd yyyy');
		}

		editable = false;
		url = new PageReference('/' + workOrderId).getUrl();
		contactName = discoverContactName(woEvent);
		eventType = woEvent.Work_Order_Type__c.toLowerCase().deleteWhitespace();
		className = 'woEvent ' + eventType;
		missingResource = woEvent.Assigned_Resources__r.isEmpty();
	}

	private String discoverContactName(RbA_Work_Order__c workOrder) {
		String name = '';
		if (String.isNotBlank(workOrder.Contact__c)) {
			name = workOrder.Contact__r.LastName + (String.isNotBlank(workOrder.Contact__r.FirstName) ? ', ' + workOrder.Contact__r.FirstName : '');
		}
		return name;
	}

	/*
	public void createOffsetTimes(Integer offset) {
		DateTime startDateTimeUtcTemp = startDateTime.addHours(offset);
		DateTime endDateTimeUtcTemp = endDateTime.addHours(offset);

		startDateTimeOffset = DateTime.newInstance(startDateTimeUtcTemp.year(), startDateTimeUtcTemp.month(), startDateTimeUtcTemp.day(), startDateTimeUtcTemp.hour(), startDateTimeUtcTemp.minute(), startDateTimeUtcTemp.second());
		endDateTimeOffset = DateTime.newInstance(endDateTimeUtcTemp.year(), endDateTimeUtcTemp.month(), endDateTimeUtcTemp.day(), endDateTimeUtcTemp.hour(), endDateTimeUtcTemp.minute(), endDateTimeUtcTemp.second());
	}
	*/

	public void createOffsetTimes() {
		startDateTimeOffset = DateTime.newInstanceGmt(startDateTime.year(), startDateTime.month(), startDateTime.day(), startDateTime.hour(), startDateTime.minute(), startDateTime.second());
		endDateTimeOffset = DateTime.newInstanceGmt(endDateTime.year(), endDateTime.month(), endDateTime.day(), endDateTime.hour(), endDateTime.minute(), endDateTime.second());
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

			/*
			System.debug('EVENT FOR WINDOW BOOKING');
			System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
			System.debug(window.startDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
			System.debug(window.startDateTimeFormated);
			System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
			System.debug(window.endDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
			System.debug(window.endDateTimeFormated);
			*/


			if (startDateTime < window.endDateTime && endDateTime > window.startDateTime) {
				window.availableResources.remove(resourceId);
			}
		}
	}



	public void setBookingWindowsOverlappingWorkOrders(List<MA_SchedulerBookingWindow> allBookingWindows) {
		for (MA_SchedulerBookingWindow window : allBookingWindows) {

			///*
			System.debug('WORK ORDER FOR WINDOW BOOKING');
			System.debug(startDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
			System.debug(window.startDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
			System.debug(window.startDateTimeFormated);
			System.debug(endDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
			System.debug(window.endDateTime.format('MM/dd/yyyy hh:mm a Z', 'America/Los_Angeles'));
			System.debug(window.endDateTimeFormated);
			//*/


			if (startDateTime < window.endDateTime && endDateTime > window.startDateTime) {
				window.bookedWorkOrders.add(workOrderId);
			}
		}
	}
	
}
global with sharing class MA_SchedulerBookingWindow {
	
	public Boolean isValid;
    public String endDateTimeFormated;
    public String startDateTimeFormated;
    public DateTime endDateTime;
    public DateTime startDateTime;
    public Set<Id> availableResources;
    public Set<Id> bookedWorkOrders;

    //public MA_SchedulerBookingWindow(String dayOfWeek, Date day, Map<String, Object> window, Set<Id> resourceIds/*, DateTime startDateTime, DateTime endDateTime, Integer startDateOffsetMinutes, Integer endDateOffsetMinutes*/) {
    //public MA_SchedulerBookingWindow(String dayOfWeek, Date day, Map<String, Object> window, Set<Id> resourceIds, Time startTime, Time endTime, String storeTimezone) {
    public MA_SchedulerBookingWindow(String dayOfWeek, Date day, Map<String, Object> window, Set<Id> resourceIds, DateTime startDateTime, DateTime endDateTime, String storeTimezone) {
        this.isValid = false;

        /*
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

        if (startOfWeek.daysBetween(day) == dayNumMap.get(dayOfWeek)) {
        */
        if (DateTime.newInstance(day, Time.newInstance(12, 0, 0, 0)).format('EEEE').toLowercase() == dayOfWeek.toLowercase()) {


        	/*
        	System.debug(storeTimezone);
        	//System.debug(startTime);
        	//System.debug(endTime);
        	System.debug(startDateTime);
        	System.debug(endDateTime);
        	*/



            List<String> startWindowSplit = ((String)window.get('start')).split(':');
            List<String> endWindowSplit = ((String)window.get('end')).split(':');

            Time startWindowTime = Time.newInstance(Integer.valueOf(startWindowSplit[0]), Integer.valueOf(startWindowSplit[1]), 0, 0);
            Time endWindowTime = Time.newInstance(Integer.valueOf(endWindowSplit[0]), Integer.valueOf(endWindowSplit[1]), 0, 0);

            DateTime startDateTimeTemp = DateTime.newInstance(day, startWindowTime);
            DateTime endDateTimeTemp = DateTime.newInstance(day, endWindowTime);

            //DateTime startDateTimeChecked = DateTime.newInstance(day, startTime);
            //DateTime endDateTimeChecked = DateTime.newInstance(day, endTime);

            //DateTime startDateTimeChecked = startDateTime;
            //DateTime endDateTimeChecked = endDateTime;

            DateTime startDateTimeChecked = DateTime.newInstance(day, startDateTime.time());
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
			/*
			startDateTimeTemp = DateTime.newInstance(day, startDateTimeTemp.time());
			System.debug(startDateTimeTemp);
			*/

			endDateTimeTemp = endDateTimeTemp.addMinutes(-offsetMinutes);
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





            ///*
            System.debug('NEW BOOKING WINDOW');
            System.debug(endDateTimeTemp.format('MM/dd/yyyy hh:mm a Z', storeTimezone) + '     >     ' + startDateTimeChecked.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
            //System.debug(startDateTimeTemp.format('MM/dd/yyyy h:mm a Z', storeTimezone));
            System.debug(startDateTimeTemp.format('MM/dd/yyyy h:mm a Z', storeTimezone) + '     <     ' + endDateTimeChecked.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
            //System.debug(endDateTimeTemp.format('MM/dd/yyyy hh:mm a Z', storeTimezone));
            //*/

            System.debug(endDateTimeTemp.format() + '     >     ' + startDateTimeChecked.format());
            System.debug(startDateTimeTemp.format() + '     <     ' + endDateTimeChecked.format());

            System.debug(startDateTimeTemp);
            System.debug(startDateTimeChecked);
            System.debug(endDateTimeTemp);
            System.debug(endDateTimeChecked);

            System.debug(startDateTimeTemp < endDateTimeChecked && endDateTimeTemp > startDateTimeChecked);

            if (startDateTimeTemp < endDateTimeChecked && endDateTimeTemp > startDateTimeChecked) {
	            this.isValid = true;
	            this.availableResources = new Set<Id>(resourceIds);
	            this.bookedWorkOrders = new Set<Id>();
	            
	            this.startDateTime = startDateTimeTemp;
	            this.endDateTime = endDateTimeTemp;

	            this.startDateTimeFormated = this.startDateTime.format('MM/dd/yyyy hh:mm a', storeTimezone);
	            this.endDateTimeFormated = this.endDateTime.format('MM/dd/yyyy hh:mm a', storeTimezone);
	        }
        }
    }

}
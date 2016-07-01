/************************************************************************************/
/*                                                                                  */
/*      This class is used to test MA_SchedulerController 	 						*/
/* 		and its related wrapper classes 											*/
/*                                                                                  */
/*      @author     Daniel Taylor   (MapAnything)                                   */
/*                                                                                  */
/*      @version    6/29/2016   MapAnything                                         */
/*      Created                                                                     */
/*                                                                                  */
/*      @copyright (c)2016 MapAnything. All Rights Reserved.                        */
/*      Unauthorized use is prohibited                                              */
/*                                                                                  */
/************************************************************************************/

@isTest (SeeAllData = false)
private class MA_SchedulerTESTS {
	
	@isTest static void testMaSchedulerConstructor() {
		MA_SchedulerController maCon = new MA_SchedulerController();
		System.assertNotEquals(null, maCon.tempWo);

		MA_SchedulerEvent maEvent = new MA_SchedulerEvent();
		System.assertNotEquals(null, maEvent);

		try {
			insert new Account();
		}
		catch(Exception ex) {
			Map<String, Object> response = new Map<String, Object>();
			MA_SchedulerUtilities.createErrorResponse(ex, response);
			System.assertEquals(false, (Boolean)response.get('success'));
		}
	}

	@isTest static void testMaSchedulerRetrieveRecords() {
		MA_SchedulerFakeDataGenerator.createFakeResource(true, 'Tech Measure', null);

		String responseString = MA_SchedulerController.retrieveRecords('Resource', 'Active__c = true', 'Tech Measure');
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		List<Object> objList = (List<Object>)responseObj.get('objList');
		System.assertEquals(1, objList.size());

		responseString = MA_SchedulerController.retrieveRecords('Resource', 'Active__c = true', null);
		responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		objList = (List<Object>)responseObj.get('objList');
		System.assertEquals(1, objList.size());

		responseString = MA_SchedulerController.retrieveRecords('Scheduler', null, null);
		responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		objList = (List<Object>)responseObj.get('objList');
		System.assertEquals(1, objList.size());

		responseString = MA_SchedulerController.retrieveRecords('MASettings', null, null);
		responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		objList = (List<Object>)responseObj.get('objList');
		System.assertEquals(0, objList.size());

		responseString = MA_SchedulerController.retrieveRecords('WorkOrder', null, null);
		responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		objList = (List<Object>)responseObj.get('objList');
		System.assertEquals(0, objList.size());
	}

	@isTest static void testMaSchedulerRetrieveSettings() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		Resource__c res = MA_SchedulerFakeDataGenerator.createFakeResource(true, 'Tech Measure', storeConfig.Id);
		MA_Scheduler_Settings__c storeSetting = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, null, false);
		MA_Scheduler_Settings__c resourceSetting = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res.Id, false);
		insert new List<MA_Scheduler_Settings__c> { storeSetting, resourceSetting };

		String responseString = MA_SchedulerController.retrieveSettings(storeConfig.Id);
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);

		Object storeSettings = (Object)responseObj.get('storeSettings');
		List<Object> resourceList = (List<Object>)responseObj.get('resourceList');
		Map<String, Object> resourceSettingsMap = (Map<String, Object>)responseObj.get('resourceSettingsMap');
		
		System.assertEquals(1, resourceList.size());
		System.assertNotEquals(null, storeSettings);
		System.assertEquals(1, resourceSettingsMap.size());
	}

	@isTest static void testMaSchedulerRetrieveTimezoneOptions() {
		String responseString = MA_SchedulerController.retrieveTimezoneOptions();
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		Map<String, Object> timezoneOptions = (Map<String, Object>)responseObj.get('timezoneOptions');
		System.assert(!timezoneOptions.isEmpty());
	}

	@isTest static void testMaSchedulerRetrieveEvents() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Account dwelling = MA_SchedulerFakeDataGenerator.createFakeDwelling(true, store.Id);
		Contact homeOwner = MA_SchedulerFakeDataGenerator.createFakeContact(true, store.Id);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		Resource__c res = MA_SchedulerFakeDataGenerator.createFakeResource(true, 'Tech Measure', storeConfig.Id);
		RbA_Work_Order__c wo = MA_SchedulerFakeDataGenerator.createFakeWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure');
		MA_Scheduler_Event__c maEvent = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo.Id, res.Id);
		MA_Scheduler_Event__c maEventWithRes1 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo.Id, res.Id);
		MA_Scheduler_Event__c maEventWithRes2 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo.Id, res.Id);

		maEventWithRes1.Resource__c = res.Id;
		maEventWithRes2.Resource__c = res.Id;
		insert new List<MA_Scheduler_Event__c> { maEvent, maEventWithRes1, maEventWithRes2 };
		MA_SchedulerFakeDataGenerator.createFakeSetting(true, storeConfig.Id, null, false);
		MA_SchedulerFakeDataGenerator.createFakeSfEvent(true, null);

		String filters = 'RbA_Work_Order__c = \'' + wo.Id + '\'';
		String altFilters = 'OwnerId = \'' + UserInfo.getUserId() + '\'';
		Map<Id, Id> resourceUserIdToIdMap = new Map<Id, Id> {
			res.RbA_User__c => res.Id
		};

		String responseString = MA_SchedulerController.retrieveEvents('allEvents', filters, altFilters, JSON.serialize(resourceUserIdToIdMap), storeConfig.Id);
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		List<Object> eventList = (List<Object>)responseObj.get('eventList');
		System.assert(eventList.size() >= 2);

		responseString = MA_SchedulerController.retrieveEvents('WorkOrder', filters, altFilters, JSON.serialize(resourceUserIdToIdMap), storeConfig.Id);
		responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		eventList = (List<Object>)responseObj.get('eventList');
		System.assertEquals(1, eventList.size());
	}

	@isTest static void testMaSchedulerRetrieveHolidays() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		MA_SchedulerFakeDataGenerator.createFakeSetting(true, storeConfig.Id, null, false);

		String responseString = MA_SchedulerController.retrieveHolidays(storeConfig.Id);
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		List<Object> eventList = (List<Object>)responseObj.get('eventList');
		System.assertEquals(7, eventList.size());
	}

	@isTest static void testMaSchedulerRetrieveNonGeocodedAddresses() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(false);
		store.ShippingLongitude = null;
		store.ShippingLatitude = null;
		insert store;

		Account dwelling = MA_SchedulerFakeDataGenerator.createFakeDwelling(false, store.Id);
		dwelling.ShippingLongitude = null;
		dwelling.ShippingLatitude = null;
		insert dwelling;

		Contact homeOwner = MA_SchedulerFakeDataGenerator.createFakeContact(true, store.Id);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		Resource__c res = MA_SchedulerFakeDataGenerator.createFakeResource(true, 'Tech Measure', storeConfig.Id);
		RbA_Work_Order__c wo = MA_SchedulerFakeDataGenerator.createFakeWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure');
		MA_SchedulerFakeDataGenerator.createFakeMaEvent(true, wo.Id, res.Id);

		String responseString = MA_SchedulerController.retrieveNonGeocodedAddresses('1987-01-10', storeConfig.Id, 'Tech Measure', res.Id);
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		List<Object> accList = (List<Object>)responseObj.get('accList');
		System.assertEquals(2, accList.size());
	}

	@isTest static void testMaSchedulerUpdateGeocodedAddresses() {
		Decimal lat = 34.0441545;
		Decimal lng = -84.0095322;
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		String storeAddress = store.ShippingAddress + ', ' + store.ShippingCity + ', ' + store.ShippingState + ' ' + store.ShippingPostalCode;

		Map<Id, String> accIdToAddressMap = new Map<Id, String> {
			store.Id => storeAddress
		};

		Map<String, Map<String, Decimal>> addressToGeocodeMap = new Map<String, Map<String, Decimal>> {
			storeAddress => new Map<String, Decimal> {
				'lat' => lat,
				'lng' => lng
			}
		};

		String responseString = MA_SchedulerController.updateGeocodedAddresses(JSON.serialize(accIdToAddressMap), JSON.serialize(addressToGeocodeMap));
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		System.assert((Boolean)responseObj.get('success'));

		store = [SELECT ShippingLatitude, ShippingLongitude FROM Account WHERE Id = :store.Id];
		System.assertEquals(lat, store.ShippingLatitude);
		System.assertEquals(lng, store.ShippingLongitude);
	}

	@isTest static void testMaSchedulerSaveSettings() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		MA_Scheduler_Settings__c storeSetting = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, null, false);
		List<MA_Scheduler_Settings__c> settingsList = new List<MA_Scheduler_Settings__c> { storeSetting };
		MA_SchedulerFakeDataGenerator.createFakeSetting(true, storeConfig.Id, null, false);

		String responseString = MA_SchedulerController.saveSettings(JSON.serialize(settingsList));
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		System.assert((Boolean)responseObj.get('success'));

		settingsList = [SELECT Id FROM MA_Scheduler_Settings__c];
		System.assertEquals(1, settingsList.size());
	}

	@isTest static void testMaSchedulerCreateResourceEvent() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Account dwelling = MA_SchedulerFakeDataGenerator.createFakeDwelling(true, store.Id);
		Contact homeOwner = MA_SchedulerFakeDataGenerator.createFakeContact(true, store.Id);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		Resource__c res = MA_SchedulerFakeDataGenerator.createFakeResource(true, 'Tech Measure', storeConfig.Id);
		RbA_Work_Order__c wo = MA_SchedulerFakeDataGenerator.createFakeWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure');
		MA_Scheduler_Event__c maEvent = MA_SchedulerFakeDataGenerator.createFakeMaEvent(true, wo.Id, res.Id);

		MA_SchedulerController.createResourceEvent('save', maEvent.Id, store.Id, res.Id, 'Test Personal Event', '01/10/1987', '3:45 PM', '5:20 PM');
		maEvent = [SELECT Id, Name FROM MA_Scheduler_Event__c WHERE Id = :maEvent.Id];
		System.assertEquals('Test Personal Event', maEvent.Name);

		MA_SchedulerController.createResourceEvent('delete', maEvent.Id, store.Id, res.Id, 'Test Personal Event', '01/10/1987', '3:45 PM', '5:20 PM');
		List<MA_Scheduler_Event__c> maEventsList = [SELECT Id FROM MA_Scheduler_Event__c WHERE Id = :maEvent.Id];
		System.assert(maEventsList.isEmpty());
	}

	@isTest static void testMaSchedulerRetrieveResourceRouteRecords() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Account dwelling = MA_SchedulerFakeDataGenerator.createFakeDwelling(true, store.Id);
		Contact homeOwner = MA_SchedulerFakeDataGenerator.createFakeContact(true, store.Id);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		Resource__c res = MA_SchedulerFakeDataGenerator.createFakeResource(true, 'Tech Measure', storeConfig.Id);
		RbA_Work_Order__c wo = MA_SchedulerFakeDataGenerator.createFakeWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure');
		MA_Scheduler_Event__c maEvent = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo.Id, res.Id);
		MA_Scheduler_Event__c personalMaEvent = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, null, res.Id);
		insert new List<MA_Scheduler_Event__c> { maEvent, personalMaEvent };
		MA_SchedulerFakeDataGenerator.createFakeSfEvent(true, null);

		Date d = Date.parse('01/10/1987');
		Time t = Time.newInstance(0, 0, 0, 0);
		DateTime dt = DateTime.newInstance(d, t);

		String startEpoch = String.valueOf(dt.getTime());
		dt = dt.addDays(1);
		String endEpoch = String.valueOf(dt.getTime());

		String responseString = MA_SchedulerController.retrieveResourceRouteRecords(res.Id, startEpoch, endEpoch, store.Id);
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		System.assertEquals(3, ((List<Object>)responseObj.get('customEvents')).size());
	}

	@isTest static void testMaSchedulerRetrieveAvailableResources() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Account dwelling = MA_SchedulerFakeDataGenerator.createFakeDwelling(true, store.Id);
		Contact homeOwner = MA_SchedulerFakeDataGenerator.createFakeContact(true, store.Id);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		RbA_Work_Order__c wo = MA_SchedulerFakeDataGenerator.createFakeBookedWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure', true);

		Resource__c res1 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		Resource__c res2 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		Resource__c res3 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		insert new List<Resource__c> { res1, res2, res3 };

		MA_SchedulerFakeDataGenerator.createFakeSfEvent(true, null);
		MA_Scheduler_Event__c maEvent1 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo.Id, res1.Id);
		MA_Scheduler_Event__c maEvent2 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, null, res2.Id);
		insert new List<MA_Scheduler_Event__c> { maEvent1, maEvent2 };

		MA_Scheduler_Settings__c resourceSetting1 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res1.Id, false);
		MA_Scheduler_Settings__c resourceSetting2 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res2.Id, false);
		MA_Scheduler_Settings__c resourceSetting3 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res3.Id, false);
		MA_Scheduler_Settings__c storeSetting = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, null, false);
		insert new List<MA_Scheduler_Settings__c> { resourceSetting1, resourceSetting2, resourceSetting3, storeSetting };

		RbA_Skills__c skill = MA_SchedulerFakeDataGenerator.createFakeSkill(true, 'skill1');
		MA_SchedulerFakeDataGenerator.createFakeWorkOrderSkill(true, skill.Id, wo.Id);
		MA_SchedulerFakeDataGenerator.createFakeAssignedResource(true, wo.Id, res1.Id, true);
		Resource_Skill__c resSkill1 = MA_SchedulerFakeDataGenerator.createFakeResourceSkill(false, skill.Id, res1.Id);
		Resource_Skill__c resSkill2 = MA_SchedulerFakeDataGenerator.createFakeResourceSkill(false, skill.Id, res2.Id);
		Resource_Skill__c resSkill3 = MA_SchedulerFakeDataGenerator.createFakeResourceSkill(false, skill.Id, res3.Id);
		insert new List<Resource_Skill__c> { resSkill1, resSkill2, resSkill3 };

		String responseString = MA_SchedulerController.retrieveAvailableResources(wo.Id, '01/10/1987', JSON.serialize(new Set<Id>()));
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		System.assertEquals(1, ((List<Object>)responseObj.get('availableResources')).size());
		System.assertEquals(2, ((List<Object>)responseObj.get('unAvailableResources')).size());

		responseString = MA_SchedulerController.retrieveAvailableResources(wo.Id, null, JSON.serialize(new Set<Id>()));
		responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		System.assertEquals(1, ((List<Object>)responseObj.get('availableResources')).size());
		System.assertEquals(2, ((List<Object>)responseObj.get('unAvailableResources')).size());

		delete storeSetting;

		responseString = MA_SchedulerController.retrieveAvailableResources(wo.Id, null, JSON.serialize(new Set<Id>()));
		responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		System.assertEquals(0, ((List<Object>)responseObj.get('availableResources')).size());
		System.assertEquals(3, ((List<Object>)responseObj.get('unAvailableResources')).size());
	}

	@isTest static void testMaSchedulerCheckAvailability() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Account dwelling = MA_SchedulerFakeDataGenerator.createFakeDwelling(true, store.Id);
		Contact homeOwner = MA_SchedulerFakeDataGenerator.createFakeContact(true, store.Id);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		RbA_Work_Order__c wo = MA_SchedulerFakeDataGenerator.createFakeBookedWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure', false);

		Resource__c res1 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		Resource__c res2 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		Resource__c res3 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		insert new List<Resource__c> { res1, res2, res3 };

		MA_Scheduler_Event__c maEvent1 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo.Id, res1.Id);
		MA_Scheduler_Event__c maEvent2 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, null, res2.Id);
		insert new List<MA_Scheduler_Event__c> { maEvent1, maEvent2 };

		MA_Scheduler_Settings__c resourceSetting1 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res1.Id, false);
		MA_Scheduler_Settings__c resourceSetting2 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res2.Id, false);
		MA_Scheduler_Settings__c resourceSetting3 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res3.Id, false);
		MA_Scheduler_Settings__c storeSetting = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, null, false);
		insert new List<MA_Scheduler_Settings__c> { resourceSetting1, resourceSetting2, resourceSetting3, storeSetting };

		Assigned_Resources__c assignedResource = MA_SchedulerFakeDataGenerator.createFakeAssignedResource(true, wo.Id, res1.Id, true);

		RbA_Skills__c skill = MA_SchedulerFakeDataGenerator.createFakeSkill(true, 'skill1');
		MA_SchedulerFakeDataGenerator.createFakeWorkOrderSkill(true, skill.Id, wo.Id);
		Resource_Skill__c resSkill1 = MA_SchedulerFakeDataGenerator.createFakeResourceSkill(false, skill.Id, res1.Id);
		Resource_Skill__c resSkill2 = MA_SchedulerFakeDataGenerator.createFakeResourceSkill(false, skill.Id, res2.Id);
		Resource_Skill__c resSkill3 = MA_SchedulerFakeDataGenerator.createFakeResourceSkill(false, skill.Id, res3.Id);
		insert new List<Resource_Skill__c> { resSkill1, resSkill2, resSkill3 };

		Date d = Date.parse('01/10/1987');
		Time t = Time.newInstance(0, 0, 0, 0);
		DateTime dt = DateTime.newInstance(d, t);

		String startEpoch = String.valueOf(dt.getTime());
		dt = dt.addDays(1);
		String endEpoch = String.valueOf(dt.getTime());
		Integer pageOffset = MA_SchedulerUtilities.determineTimezoneOffset(dt, null);
		pageOffset = MA_SchedulerUtilities.determineOffsetMinutesFromTimezoneOffset(pageOffset);

		String responseString = MA_SchedulerController.checkAvailability(wo.Id, startEpoch, endEpoch, String.valueOf(-pageOffset), true);
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);

		System.assertEquals(5, ((List<Object>)responseObj.get('bookingWindows')).size());
		System.assertEquals(1, ((List<Object>)responseObj.get('unAvailableSlots')).size());

		delete assignedResource;
		delete maEvent1;

		responseString = MA_SchedulerController.checkAvailability(wo.Id, startEpoch, endEpoch, String.valueOf(-pageOffset), true);
		responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);

		System.assertEquals(5, ((List<Object>)responseObj.get('bookingWindows')).size());
		System.assertEquals(0, ((List<Object>)responseObj.get('unAvailableSlots')).size());

		delete storeSetting;

		responseString = MA_SchedulerController.checkAvailability(wo.Id, startEpoch, endEpoch, String.valueOf(-pageOffset), true);
		responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		System.assertEquals(false, (Boolean)responseObj.get('success'));
	}

	@isTest static void testMaSchedulerCancelWorkOrder() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Account dwelling = MA_SchedulerFakeDataGenerator.createFakeDwelling(true, store.Id);
		Contact homeOwner = MA_SchedulerFakeDataGenerator.createFakeContact(true, store.Id);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		Resource__c res = MA_SchedulerFakeDataGenerator.createFakeResource(true, 'Tech Measure', storeConfig.Id);
		RbA_Work_Order__c wo = MA_SchedulerFakeDataGenerator.createFakeWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure');
		MA_Scheduler_Event__c maEvent = MA_SchedulerFakeDataGenerator.createFakeMaEvent(true, wo.Id, res.Id);
		MA_SchedulerFakeDataGenerator.createFakeSfEvent(true, maEvent.Id);

		MA_SchedulerController.cancelWorkOrder(wo.Id, 'Test Cancel');
		wo = [SELECT Id, Appointment_Date__c, Cancel_Reason__c FROM RbA_Work_Order__c WHERE Id = :wo.Id];
		System.assertEquals('Test Cancel', wo.Cancel_Reason__c);
		System.assertEquals(null, wo.Appointment_Date__c);
		System.assert([SELECT Id FROM Event WHERE MA_Scheduler_Event__c = :maEvent.Id].isEmpty());
		System.assert([SELECT Id FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__c = :wo.Id].isEmpty());
	}

	@isTest static void testMaSchedulerSaveAssignedResources() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Account dwelling = MA_SchedulerFakeDataGenerator.createFakeDwelling(true, store.Id);
		Contact homeOwner = MA_SchedulerFakeDataGenerator.createFakeContact(true, store.Id);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		RbA_Work_Order__c wo = MA_SchedulerFakeDataGenerator.createFakeBookedWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure', false);

		Resource__c res1 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		Resource__c res2 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		Resource__c res3 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		insert new List<Resource__c> { res1, res2, res3 };

		Assigned_Resources__c assignedRes1 = MA_SchedulerFakeDataGenerator.createFakeAssignedResource(false, wo.Id, res1.Id, false);
		Assigned_Resources__c assignedRes2 = MA_SchedulerFakeDataGenerator.createFakeAssignedResource(false, wo.Id, res2.Id, true);
		insert new List<Assigned_Resources__c> { assignedRes1, assignedRes2 };

		MA_Scheduler_Event__c maEvent1 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo.Id, res1.Id);
		MA_Scheduler_Event__c maEvent2 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo.Id, res2.Id);
		insert new List<MA_Scheduler_Event__c> { maEvent1, maEvent2 };

		MA_Scheduler_Settings__c resourceSetting1 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res1.Id, false);
		MA_Scheduler_Settings__c resourceSetting2 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res2.Id, false);
		MA_Scheduler_Settings__c resourceSetting3 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res3.Id, false);
		MA_Scheduler_Settings__c storeSetting = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, null, false);
		insert new List<MA_Scheduler_Settings__c> { resourceSetting1, resourceSetting2, resourceSetting3, storeSetting };

		String responseString = MA_SchedulerController.saveAssignedResources(wo.Id, new List<Id> { wo.Id, res2.Id }, res2.Id, '01/10/1987');
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		System.assertEquals(2, [SELECT Id FROM Assigned_Resources__c WHERE Work_Order__c = :wo.Id].size());

		responseString = MA_SchedulerController.saveAssignedResources(wo.Id, new List<Id> { wo.Id, res2.Id, res3.Id }, res3.Id, null);
		responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		System.assertEquals(2, [SELECT Id FROM Assigned_Resources__c WHERE Work_Order__c = :wo.Id].size());
	}

	@isTest static void testMaSchedulerScheduleWorkOrder() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Account dwelling = MA_SchedulerFakeDataGenerator.createFakeDwelling(true, store.Id);
		Contact homeOwner = MA_SchedulerFakeDataGenerator.createFakeContact(true, store.Id);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		RbA_Work_Order__c wo = MA_SchedulerFakeDataGenerator.createFakeBookedWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure', false);

		Resource__c res1 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		Resource__c res2 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		Resource__c res3 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		insert new List<Resource__c> { res1, res2, res3 };

		Assigned_Resources__c assignedRes1 = MA_SchedulerFakeDataGenerator.createFakeAssignedResource(false, wo.Id, res1.Id, false);
		Assigned_Resources__c assignedRes2 = MA_SchedulerFakeDataGenerator.createFakeAssignedResource(false, wo.Id, res2.Id, true);
		insert new List<Assigned_Resources__c> { assignedRes1, assignedRes2 };

		MA_Scheduler_Event__c maEvent1 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo.Id, res1.Id);
		MA_Scheduler_Event__c maEvent2 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo.Id, res2.Id);
		insert new List<MA_Scheduler_Event__c> { maEvent1, maEvent2 };

		MA_Scheduler_Settings__c resourceSetting1 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res1.Id, false);
		MA_Scheduler_Settings__c resourceSetting2 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res2.Id, false);
		MA_Scheduler_Settings__c resourceSetting3 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res3.Id, false);
		MA_Scheduler_Settings__c storeSetting = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, null, false);
		insert new List<MA_Scheduler_Settings__c> { resourceSetting1, resourceSetting2, resourceSetting3, storeSetting };

		String responseString = MA_SchedulerController.scheduleWorkOrder(wo.Id, '01/10/1987 10:00 AM - 12:00 PM', 'testing');
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		wo = [SELECT Id, Appointment_Start_Time__c, Appointment_End_Time__c, Reschedule_Reason__c FROM RbA_Work_Order__c WHERE Id = :wo.Id];
		System.assertEquals('testing', wo.Reschedule_Reason__c);
		System.assertEquals('10:00 am', wo.Appointment_Start_Time__c);
		System.assertEquals('12:00 pm', wo.Appointment_End_Time__c);
	}
	
}
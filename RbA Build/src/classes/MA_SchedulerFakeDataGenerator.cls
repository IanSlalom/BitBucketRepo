/************************************************************************************/
/*                                                                                  */
/*      This class is used to create fake data for the test classes 				*/
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

public class MA_SchedulerFakeDataGenerator {
	
	public static Map<String, Object> deserializeResponse(String responseString) {
		return (Map<String, Object>)JSON.deserializeUntyped(responseString);
	}

	public static Store_Configuration__c createFakeStoreConfig(Boolean insertNeeded, Id storeId) {
		Store_Configuration__c storeConfig = new Store_Configuration__c(
			Store__c = storeId,
			Order_Number__c = 1
		);

		if (insertNeeded) {
			insert storeConfig;

			Account store = [SELECT Id FROM Account WHERE Id = :storeId];
			store.Active_Store_Configuration__c = storeConfig.Id;
			update store;
		}

		return storeConfig;
	}

	public static Account createFakeStore(Boolean insertNeeded) {
		Id storeRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Store'].Id;

		if (RMS_Settings__c.getInstance('Data Loading Profile ID') == null || String.isBlank(RMS_Settings__c.getValues('Data Loading Profile ID').value__c)) {
			insert new RMS_Settings__c(
				Name = 'Data Loading Profile ID',
				Value__c = '2'
			);
		}

		Account store = new Account(
			Type = 'South',
			Name = 'Atlanta Office',
			ShippingCity = 'Atlanta',
			ShippingState = 'Georgia',
			ShippingPostalCode = '30328',
			RecordTypeId = storeRecordTypeId,
			ShippingStreet = '10 Glenlake Pkwy',
			ShippingLongitude = -84.361648, 
			ShippingLatitude = 33.936008
		);

		if (insertNeeded) {
			insert store;
		}

		return store;
	}

	public static Resource__c createFakeResource(Boolean insertNeeded, String resType, Id storeConfigId) {
		Resource__c res = new Resource__c(
			Active__c = true,
			Crew_Size__c = 5,
			Resource_Type__c = resType,
			Retail_Location__c = storeConfigId,
			RbA_User__c = UserInfo.getUserId()
		);

		if (insertNeeded) {
			insert res;
		}

		return res;
	}

	public static MA_Scheduler_Settings__c createFakeSetting(Boolean insertNeeded, Id storeConfigId, Id resId, Boolean isError) {
		String resourceSetting = '{"resourceHours":{"Monday":[{"start":"07:00","end":"20:00"}],"Tuesday":[{"start":"07:00","end":"20:00"}],"Wednesday":[{"start":"07:00","end":"20:00"}],"Thursday":[{"start":"07:00","end":"20:00"}],"Friday":[{"start":"07:00","end":"20:00"}],"Saturday":[{"start":"07:00","end":"20:00"}],"Sunday":[{"start":"07:00","end":"20:00"}]}}';
		String storeSetting = '{"timezone":"America/Chicago",';
		if (!isError) {
		      storeSetting += '"esriClientId":"1J1NXVUC9GGzfaqN","esriClientSecret":"de5b27126b874e34abda94f8a66de056","esriClientSecretVerified":true,';
		}
		storeSetting += '"storeHours":{"Monday":[{"start":"10:00","end":"16:00"}],"Tuesday":[{"start":"10:00","end":"16:00"}],"Wednesday":[{"start":"10:00","end":"16:00"}],"Thursday":[{"start":"10:00","end":"18:00"}],"Friday":[{"start":"06:00","end":"20:00"}],"Saturday":[{"start":"06:00","end":"20:00"}]},'
						+ '"Tech Measure":{"bookingWindows":{"Monday":[{"start":"10:00","end":"12:00"},{"start":"14:00","end":"16:00"}],"Tuesday":[{"start":"10:00","end":"12:00"},{"start":"14:00","end":"16:00"}],"Wednesday":[{"start":"10:00","end":"12:00"},{"start":"14:00","end":"16:00"}],"Thursday":[{"start":"10:00","end":"12:00"},{"start":"14:00","end":"16:00"},{"start":"16:00","end":"18:00"}],"Friday":[{"start":"08:00","end":"10:00"},{"start":"10:00","end":"12:00"},{"start":"14:00","end":"16:00"},{"start":"16:00","end":"18:00"}],"Saturday":[{"start":"08:00","end":"10:00"},{"start":"10:00","end":"12:00"},{"start":"14:00","end":"16:00"},{"start":"16:00","end":"18:00"}],"Sunday":[{"start":"08:00","end":"10:00"},{"start":"10:00","end":"12:00"},{"start":"14:00","end":"16:00"},{"start":"16:00","end":"18:00"}]}},'
						+ '"Install":{"bookingWindows":{"Monday":[{"start":"10:00","end":"16:00"}],"Tuesday":[{"start":"10:00","end":"16:00"}],"Wednesday":[{"start":"10:00","end":"16:00"}],"Thursday":[{"start":"10:00","end":"14:00"},{"start":"14:00","end":"18:00"}],"Friday":[{"start":"06:00","end":"10:00"},{"start":"10:00","end":"14:00"},{"start":"14:00","end":"20:00"}],"Saturday":[{"start":"06:00","end":"10:00"},{"start":"10:00","end":"14:00"},{"start":"14:00","end":"20:00"}]}},'
						+ '"storeHolidays":[{"date":"01/01/2016","reason":"New Year\'s","dayOfWeek":"Friday"},{"date":"05/10/2016","reason":"Memorial Day","dayOfWeek":"Tuesday"},{"date":"11/24/2016","reason":"Thanksgiving","dayOfWeek":"Thursday"},{"date":"11/25/2016","reason":"Black Friday","dayOfWeek":"Friday"},{"date":"12/23/2016","reason":"Christmas Eve","dayOfWeek":"Friday"},{"date":"12/26/2016","reason":"Christmas Day","dayOfWeek":"Monday"},{"date":"01/02/2017","reason":"","dayOfWeek":"Monday"}]}';
		
		MA_Scheduler_Settings__c setting = new MA_Scheduler_Settings__c(
			Resource_Id__c = resId,
			Store_Id__c = storeConfigId,
			Settings__c = resId == null ? storeSetting : resourceSetting
		);

		if (insertNeeded) {
			insert setting;
		}

		return setting;
	}

	public static Account createFakeDwelling(Boolean insertNeeded, Id storeId) {
		Id dwellingRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Dwelling'].Id;

		Account dwelling = new Account(
			Type = 'South',
			Name = 'House',
			ShippingState = 'Georgia',
			Dwelling_Style__c = 'House',
			Store_Location__c = storeId,
			ShippingPostalCode = '30043',
			ShippingCity = 'Lawrenceville',
			RecordTypeId = dwellingRecordTypeId,
			ShippingStreet = '2820 Springtime Ct', 
			ShippingLongitude = 34.044074,
			ShippingLatitude = -84.007345
		);

		if (insertNeeded) {
			insert dwelling;
		}

		return dwelling;
	}

	public static Contact createFakeContact(Boolean insertNeeded, Id storeId) {
		Contact homeOwner = new Contact(
			LastName = 'Taylor',
			AccountId = storeId,
			FirstName = 'Daniel'
		);

		if (insertNeeded) {
			insert homeOwner;
		}

		return homeOwner;
	}

	public static RbA_Work_Order__c createFakeWorkOrder(Boolean insertNeeded, Id dwellingId, Id homeOwnerId, String workOrderType) {
		RbA_Work_Order__c wo = new RbA_Work_Order__c(
			Account__c = dwellingId,
			Contact__c = homeOwnerId,
			Work_Order_Type__c = workOrderType
		);

		if (insertNeeded) {
			insert wo;
		}

		return wo;
	}

	public static RbA_Work_Order__c createFakeBookedWorkOrder(Boolean insertNeeded, Id dwellingId, Id homeOwnerId, String workOrderType, Boolean isMultiDay) {
		RbA_Work_Order__c wo = new RbA_Work_Order__c(
			Account__c = dwellingId,
			Contact__c = homeOwnerId,
			Work_Order_Type__c = workOrderType,
			Appointment_End_Time__c = '12:00 PM',
			Appointment_Start_Time__c = '10:00 AM',
			Appointment_Duration__c = isMultiDay ? 20 : 2,
			Appointment_Date__c = Date.parse('01/10/1987')
		);

		if (insertNeeded) {
			insert wo;
		}

		return wo;
	}

	public static MA_Scheduler_Event__c createFakeMaEvent(Boolean insertNeeded, Id woId, Id resourceId) {
		Date startDate = Date.parse('01/10/1987');
		Time startTime = Time.newInstance(12, 0, 0, 0);
		DateTime startDateTime = DateTime.newInstance(startDate, startTime);
		DateTime endDateTime = startDateTime.addHours(2);

		MA_Scheduler_Event__c maEvent = new MA_Scheduler_Event__c(
			Date__c = startDate,
			Resource__c = resourceId,
			RbA_Work_Order__c = woId,
			EndDateTime__c = endDateTime,
			StartDateTime__c = startDateTime,
			Estimated_End_Date_Time__c = endDateTime,
			Estimated_Start_Date_Time__c = startDateTime
		);

		if (insertNeeded) {
			insert maEvent;
		}

		return maEvent;
	}

	public static Event createFakeSfEvent(Boolean insertNeeded, Id maEventId) {
		Date startDate = Date.parse('01/10/1987');
		Time startTime = Time.newInstance(12, 0, 0, 0);
		DateTime startDateTime = DateTime.newInstance(startDate, startTime);

		Event sfEvent = new Event(
			StartDateTime = startDateTime,
			OwnerId = UserInfo.getUserId(),
			MA_Scheduler_Event__c = maEventId,
			EndDateTime = startDateTime.addHours(2)
		);

		if (insertNeeded) {
			try {
				insert sfEvent;
			}
			catch(Exception ex) {}
		}

		return sfEvent;
	}

	public static RbA_Skills__c createFakeSkill(Boolean insertNeeded, String skillName) {
		RbA_Skills__c skill = new RbA_Skills__c(
			Name = skillName
		);

		if (insertNeeded) {
			insert skill;
		}

		return skill;
	}

	public static Resource_Skill__c createFakeResourceSkill(Boolean insertNeeded, Id skillId, Id resourceId) {
		Resource_Skill__c skill = new Resource_Skill__c(
			Type__c = 'Primary',
			RbA_Skill__c = skillId,
			Resource__c = resourceId
		);

		if (insertNeeded) {
			insert skill;
		}

		return skill;
	}

	public static Work_Order_Required_Skill__c createFakeWorkOrderSkill(Boolean insertNeeded, Id skillId, Id woId) {
		Work_Order_Required_Skill__c skill = new Work_Order_Required_Skill__c(
			RbA_Skill__c = skillId,
			RbA_Work_Order__c = woId
		);

		if (insertNeeded) {
			insert skill;
		}

		return skill;
	}

	public static Assigned_Resources__c createFakeAssignedResource(Boolean insertNeeded, Id woId, Id resourceId, Boolean isPrimary) {
		Assigned_Resources__c assignedResource = new Assigned_Resources__c(
			Work_Order__c = woId,
			IsPrimary__c = isPrimary,
			Scheduled_Resource__c = resourceId
		);

		if (insertNeeded) {
			insert assignedResource;
		}

		return assignedResource;
	}
	
}
/************************************************************************************/
/*                                                                                  */
/*      This class is used to test MA_SchedulerRoutingController 	 				*/
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
private class MA_SchedulerRouteTESTS {

	@isTest static void testMARoutingSchedulerConstructor() {
		MA_RoutingSchedulerController maRoute = new MA_RoutingSchedulerController();
		System.assertNotEquals(null, maRoute.tempWo);
	}

 	public class MockHttpResponseGeneratorESRIToken implements HttpCalloutMock{
   		public HTTPResponse respond(HTTPRequest req) {
	       HttpResponse res2 = new HttpResponse();
	       res2.setHeader('Content-Type', 'application/json');
	       res2.setBody('{"access_token":"rbgBLBZiCr1vywSE2Ks3iZbwzqJyWiSc8BSA7rtaU06_GERZeVCMpEPDj3Vv2MoIvQ0hKDAfPW0ti72RV0TL7n4J08xx4_R57ofYMuJXpX35RUcRWyHqd46CcLIDcdntPC2pj6MMf28__GjZ_ilJOQ..","expires_in":480000}');
	       res2.setStatusCode(200);
	       return res2;
		}
	}

	@isTest static void testMARoutingSchedulerGETESRIToken() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		MA_Scheduler_Settings__c storeSetting = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, null, false);
		insert new List<MA_Scheduler_Settings__c> { storeSetting };

		Test.startTest();
 		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorESRIToken());
		String responseString = MA_RoutingSchedulerController.getESRIToken(storeConfig.Id, false, null, null);
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		Object accessToken = (Object)responseObj.get('access_token');
		System.assertNotEquals(null, accessToken);

 		responseString = MA_RoutingSchedulerController.getESRIToken(storeConfig.Id, true, null, null);
		responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		Object error = (Object)responseObj.get('error');
		System.assertNotEquals(null, error);
		Test.stopTest();
	}
	
	@isTest static void testMARoutingSchedulerGetRecords() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Account dwelling = MA_SchedulerFakeDataGenerator.createFakeDwelling(true, store.Id);
		Contact homeOwner = MA_SchedulerFakeDataGenerator.createFakeContact(true, store.Id);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		RbA_Work_Order__c wo = MA_SchedulerFakeDataGenerator.createFakeBookedWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure', false);
		RbA_Work_Order__c wo2 = MA_SchedulerFakeDataGenerator.createFakeBookedWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure', false);
		RbA_Work_Order__c wo3 = MA_SchedulerFakeDataGenerator.createFakeBookedWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure', false );
		RbA_Work_Order__c wo4 = MA_SchedulerFakeDataGenerator.createFakeBookedWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure', false );

		Resource__c res1 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		Resource__c res2 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		Resource__c res3 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		Resource__c res4 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		insert new List<Resource__c> { res1, res2, res3, res4 };

		MA_SchedulerFakeDataGenerator.createFakeSfEvent(true, wo4.Id);
		MA_SchedulerFakeDataGenerator.createFakeSfEvent(true, null);
		MA_Scheduler_Event__c maEvent1 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo.Id, null);
		MA_Scheduler_Event__c maEvent2 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo2.Id, null);
		MA_Scheduler_Event__c maEvent3 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo3.Id, null);
		MA_Scheduler_Event__c maEvent4 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo4.Id, res2.Id);
		MA_Scheduler_Event__c maEvent5 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, null, res3.Id);
		MA_Scheduler_Event__c maEvent6 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, null, res4.Id);
		insert new List<MA_Scheduler_Event__c> { maEvent1, maEvent2, maEvent3, maEvent4, maEvent5, maEvent6 };

		MA_Scheduler_Settings__c resourceSetting1 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res1.Id, false);
		MA_Scheduler_Settings__c resourceSetting2 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res2.Id, false);
		MA_Scheduler_Settings__c resourceSetting3 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res3.Id, false);
		MA_Scheduler_Settings__c storeSetting = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, null, false);
		insert new List<MA_Scheduler_Settings__c> { resourceSetting1, resourceSetting2, resourceSetting3, storeSetting };

		RbA_Skills__c skill = MA_SchedulerFakeDataGenerator.createFakeSkill(true, 'skill1');
		MA_SchedulerFakeDataGenerator.createFakeWorkOrderSkill(true, skill.Id, wo.Id);
		MA_SchedulerFakeDataGenerator.createFakeWorkOrderSkill(true, skill.Id, wo2.Id);
		MA_SchedulerFakeDataGenerator.createFakeWorkOrderSkill(true, skill.Id, wo3.Id);
		MA_SchedulerFakeDataGenerator.createFakeWorkOrderSkill(true, skill.Id, wo4.Id);
		MA_SchedulerFakeDataGenerator.createFakeAssignedResource(true, wo4.Id, res2.Id, true);

		Resource_Skill__c resSkill1 = MA_SchedulerFakeDataGenerator.createFakeResourceSkill(false, skill.Id, res1.Id);
		Resource_Skill__c resSkill2 = MA_SchedulerFakeDataGenerator.createFakeResourceSkill(false, skill.Id, res2.Id);
		Resource_Skill__c resSkill3 = MA_SchedulerFakeDataGenerator.createFakeResourceSkill(false, skill.Id, res3.Id);
		Resource_Skill__c resSkill4 = MA_SchedulerFakeDataGenerator.createFakeResourceSkill(false, skill.Id, res4.Id);
		insert new List<Resource_Skill__c> { resSkill1, resSkill2, resSkill3, resSkill4 };

		Test.startTest();
		String responseString = MA_RoutingSchedulerController.getRecords('1987-01-10', String.valueOf(storeConfig.Id), 'Tech Measure', '0');
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		System.debug(responseObj);
		System.assertEquals(true, (Object)responseObj.get('success'));
		Test.stopTest();
	}

	@isTest static void testMARoutingSchedulerProcessConfirmBatch() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Account dwelling = MA_SchedulerFakeDataGenerator.createFakeDwelling(true, store.Id);
		Contact homeOwner = MA_SchedulerFakeDataGenerator.createFakeContact(true, store.Id);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		RbA_Work_Order__c wo = MA_SchedulerFakeDataGenerator.createFakeBookedWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure', false);
		RbA_Work_Order__c wo2 = MA_SchedulerFakeDataGenerator.createFakeBookedWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure', false);

		Resource__c res1 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		Resource__c res2 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		insert new List<Resource__c> { res1, res2};

		MA_SchedulerFakeDataGenerator.createFakeSfEvent(true, wo.Id);
		MA_SchedulerFakeDataGenerator.createFakeSfEvent(true, wo2.Id);
		MA_Scheduler_Event__c maEvent1 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo.Id, res1.Id);
		MA_Scheduler_Event__c maEvent2 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo2.Id, res2.Id);
		insert new List<MA_Scheduler_Event__c> { maEvent1, maEvent2 };

		MA_Scheduler_Settings__c resourceSetting1 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res1.Id, false);
		MA_Scheduler_Settings__c resourceSetting2 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res2.Id, false);
		MA_Scheduler_Settings__c storeSetting = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, null, false);
		insert new List<MA_Scheduler_Settings__c> { resourceSetting1, resourceSetting2, storeSetting };

		RbA_Skills__c skill = MA_SchedulerFakeDataGenerator.createFakeSkill(true, 'skill1');
		MA_SchedulerFakeDataGenerator.createFakeWorkOrderSkill(true, skill.Id, wo.Id);
		MA_SchedulerFakeDataGenerator.createFakeWorkOrderSkill(true, skill.Id, wo2.Id);
		Assigned_Resources__c assignedRes = MA_SchedulerFakeDataGenerator.createFakeAssignedResource(true, wo2.Id, res1.Id, true);
		Assigned_Resources__c assignedRes2 = MA_SchedulerFakeDataGenerator.createFakeAssignedResource(true, wo2.Id, res2.Id, true);
		
		Resource_Skill__c resSkill1 = MA_SchedulerFakeDataGenerator.createFakeResourceSkill(false, skill.Id, res1.Id);
		Resource_Skill__c resSkill2 = MA_SchedulerFakeDataGenerator.createFakeResourceSkill(false, skill.Id, res2.Id);
		insert new List<Resource_Skill__c> { resSkill1, resSkill2 };

		Map<Id, Set<Id>> woToResIdsMapString = new Map<Id, Set<Id>>();
	  	Map<Id, Id> primaryResourceMap = new Map<Id, Id> ();
		Assigned_Resources__c[] rbaAssignedResources = new Assigned_Resources__c[]{assignedRes, assignedRes2};

		for(Assigned_Resources__c resource : rbaAssignedResources){
			if(woToResIdsMapString.containsKey(resource.Work_Order__c)){
				woToResIdsMapString.get(resource.Work_Order__c).add(resource.Scheduled_Resource__c);
			}
			else{
				woToResIdsMapString.put(resource.Work_Order__c, new Set<Id>{ resource.Scheduled_Resource__c });
			}

			if(resource.isPrimary__c){
				primaryResourceMap.put(resource.Work_Order__c, resource.Scheduled_Resource__c);
			}
		}

		Test.startTest();
		String responseString = MA_RoutingSchedulerController.processConfirmBatch( JSON.serialize(woToResIdsMapString), storeConfig.Id, '1987-01-10', JSON.serialize(primaryResourceMap));
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		System.assertEquals(true, (Object)responseObj.get('success'));
		Test.stopTest();
	}

	@isTest static void testMARoutingSchedulerRetrieveResourceRouteRecords() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Account dwelling = MA_SchedulerFakeDataGenerator.createFakeDwelling(true, store.Id);
		Contact homeOwner = MA_SchedulerFakeDataGenerator.createFakeContact(true, store.Id);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);
		RbA_Work_Order__c wo = MA_SchedulerFakeDataGenerator.createFakeBookedWorkOrder(true, dwelling.Id, homeOwner.Id, 'Tech Measure', false);

		Resource__c res1 = MA_SchedulerFakeDataGenerator.createFakeResource(false, 'Tech Measure', storeConfig.Id);
		insert new List<Resource__c> { res1 };

		MA_SchedulerFakeDataGenerator.createFakeSfEvent(true, null);
		MA_Scheduler_Event__c maEvent1 = MA_SchedulerFakeDataGenerator.createFakeMaEvent(false, wo.Id, res1.Id);
		insert new List<MA_Scheduler_Event__c> { maEvent1 };

		MA_Scheduler_Settings__c resourceSetting1 = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, res1.Id, false);
		MA_Scheduler_Settings__c storeSetting = MA_SchedulerFakeDataGenerator.createFakeSetting(false, storeConfig.Id, null, false);
		insert new List<MA_Scheduler_Settings__c> { resourceSetting1, storeSetting };

		RbA_Skills__c skill = MA_SchedulerFakeDataGenerator.createFakeSkill(true, 'skill1');
		MA_SchedulerFakeDataGenerator.createFakeWorkOrderSkill(true, skill.Id, wo.Id);
		Resource_Skill__c resSkill1 = MA_SchedulerFakeDataGenerator.createFakeResourceSkill(false, skill.Id, res1.Id);
		insert new List<Resource_Skill__c> { resSkill1 };

		Test.startTest();
		String responseString = MA_RoutingSchedulerController.retrieveResourceRouteRecords(res1.Id ,'01/10/1987' , storeConfig.Id, new List<Id>());
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		Object retrieveSuccess = (Object)responseObj.get('success');
		System.assertEquals(true, retrieveSuccess);

		responseString = MA_RoutingSchedulerController.retrieveResourceRouteRecords(res1.Id ,'01/10/1987' , storeConfig.Id, new List<Id>{res1.Id});
		responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		retrieveSuccess = (Object)responseObj.get('success');
		System.assertEquals(true, retrieveSuccess);
		Test.stopTest();
	}

	@isTest static void testMARoutingSchedulerErrorTest() {
		Account store = MA_SchedulerFakeDataGenerator.createFakeStore(true);
		Store_Configuration__c storeConfig = MA_SchedulerFakeDataGenerator.createFakeStoreConfig(true, store.Id);

 		Test.startTest();
 		Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorESRIToken());
		String responseString = MA_RoutingSchedulerController.getESRIToken(storeConfig.Id, false, null, null);
		Map<String, Object> responseObj = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString);
		Object errorAccessToken = (Object)responseObj.get('error');
		System.assertNotEquals(null, errorAccessToken);

		String responseString2 = MA_RoutingSchedulerController.getRecords('', String.valueOf(store.Id), '', '0');
		Map<String, Object> responseObjMaster = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString2);
		Object masterSuccessFalse = (Object)responseObjMaster.get('success');
		System.assertEquals(false, masterSuccessFalse);
	
		String responseString3 = MA_RoutingSchedulerController.retrieveResourceRouteRecords(String.valueOf(store.Id),'01/10/1987', String.valueOf(store.Id), new List<Id>());
		Map<String, Object> responseObjReRouteRec = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString2);
		Object masterRouteRecFalse = (Object)responseObjReRouteRec.get('success');
		System.assertEquals(false, masterRouteRecFalse);
		
		String responseString4 = MA_RoutingSchedulerController.processConfirmBatch('', String.valueOf(store.Id),'1987-01-10', '');
		Map<String, Object> responseObjConfirmBatch = MA_SchedulerFakeDataGenerator.deserializeResponse(responseString4);
		Object masterConfirmBatch = (Object)responseObjConfirmBatch.get('success');
		System.assertEquals(false, masterConfirmBatch);
		Test.stopTest();
	}

}
/**
 *@class	RMS_mobileAppRequestHelper
 *@brief	Help class for handling api call business logic
 *@author  Anthony Strafaccia (Slalom.ADS)
 *@author  Mark Wochnick (Slalom.MAW)
 *@version	2015-09/16  Slalom.ADS	Created.
 *@version	2015-10/12  Slalom.MAW
 *@copyright  (c)2015 Slalom.  All Rights Reserved.	Unauthorized use is prohibited.
 */
@isTest
private class RMS_mobileAppRequestHelperTest {

	static testmethod void testFindAppointments(){
		
		TestUtilityMethods tUtil = new TestUtilityMethods();
		tUtil.setUpConfigsMark();
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
		// setup configuration stuff
//		Datetime existingApptTime = Datetime.newInstance(2016, 1, 10, 8, 0, 0);
		Datetime newApptTime = Datetime.now().addDays(1);

		User u = tUtil.createUser(p.id);
		insert u;
//		tUtil.createSalesAppt(u.Id, existingApptTime, true);
		tUtil.createSalesAppt(u.Id, newApptTime, false);
        System.runAs(u) {
			Test.startTest();
        	RMS_mobileAppRequestHelper mHelper = new RMS_mobileAppRequestHelper();
			String jsonResult = mHelper.findAppointments(u.Id, newApptTime.addDays(-1));
			Test.stopTest();
//			System.debug('###################################### ' + jsonResult);
			System.assert(jsonResult.startsWith('{"tmAppts":'));
        }
	}
}
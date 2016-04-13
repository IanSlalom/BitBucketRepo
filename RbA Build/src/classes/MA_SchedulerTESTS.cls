@isTest (SeeAllData = false)
private class MA_SchedulerTESTS {
	
	@isTest static void testBuffer1() {
		MA_SchedulerController.testCoverageBuffer();
	}
	
	@isTest static void testBuffer2() {
		MA_RoutingSchedulerController.testCoverageBuffer();
	}
	
}
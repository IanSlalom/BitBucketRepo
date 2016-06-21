@isTest
public class CanvassLeadSheetTriggerTest {
    /*
      public static testMethod void testResultToEmailIscAfterInsertAndUpdate() {
        // Setup Test Data
        // Create a Canvass Market
        CNVSS_Canvass_Market__c testCanvassMarket = CanvassTestDataUtils.createTestCanvassMarket();
        ID canvassMarketId = testCanvassMarket.Id;
            
        // Create Canvass Units
        List<CNVSS_Canvass_Unit__c> canvassUnits = CanvassTestDataUtils.createTestCanvassUnits(canvassMarketId);
        
        // Create Lead Sheet(s)
        CNVSS_Canvass_Lead_Sheet__c testLeadSheetNotHome = CanvassTestDataUtils.createTestCanvassLeadSheet(canvassUnits[0], 'Not Home');
        CNVSS_Canvass_Lead_Sheet__c testLeadSheetCallBack = CanvassTestDataUtils.createTestCanvassLeadSheet(canvassUnits[1], 'Interested: Call Back');
        CNVSS_Canvass_Lead_Sheet__c testLeadSheetSetAppointment = CanvassTestDataUtils.createTestCanvassLeadSheet(canvassUnits[2], 'Set Appointment');
        CNVSS_Canvass_Lead_Sheet__c testLeadSheetDoNotKnock = CanvassTestDataUtils.createTestCanvassLeadSheet(canvassUnits[3], 'Submit for Do Not Knock List');
        
        
        
        // Perform Test
        Test.startTest();
        // Insert test
        List<CNVSS_Canvass_Lead_Sheet__c> testLeadSheets = new List<CNVSS_Canvass_Lead_Sheet__c> {
            testLeadSheetNotHome, testLeadSheetCallBack, testLeadSheetSetAppointment, testLeadSheetDoNotKnock
                };
        CanvassLeadSheetTriggerHandler.SendSetAppointmentEmailToISC(testLeadSheets);
        
        // Update test
        testLeadSheets[1].Canvass_Result__c = 'Set Appointment';
        testLeadSheets[2].Canvass_Result__c = 'Interested: Call Back';
        update testLeadSheets;
        CanvassLeadSheetTriggerHandler.SendSetAppointmentEmailToISC(testLeadSheets);
        
        // Sig Test
        CanvassLeadSheetUtils.saveSignature('Test', testLeadSheets[1].id);
        
        Test.stopTest();
        // Verify Test Results
    } 
	*/
    
    public static testMethod void saveSignature() {
 		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();
        // Create a Canvass Market
        CNVSS_Canvass_Market__c testCanvassMarket = CanvassTestDataUtils.createTestCanvassMarket();
        ID canvassMarketId = testCanvassMarket.Id;
        
        // Create Canvass Units
        CNVSS_Canvass_Unit__c canvassUnit = CanvassTestDataUtils.createTestCanvassUnit(canvassMarketId, false);
        
         // Create Lead Sheet(s)
        CNVSS_Canvass_Lead_Sheet__c testLeadSheet = CanvassTestDataUtils.createTestCanvassLeadSheet(canvassUnit, 'Not Home');
        
        Test.startTest();
        // Sig Test
        CanvassLeadSheetUtils.saveSignature('Test', testLeadSheet.id);
        
        Test.stopTest();
    }
    
    public static testMethod void testDoNotContactFunctionality() {
 		TestUtilityMethods utility = new TestUtilityMethods();
		utility.setUpConfigs();
        /* Setup Test Data */
        // Create a Canvass Market
        CNVSS_Canvass_Market__c testCanvassMarket = CanvassTestDataUtils.createTestCanvassMarket();
        ID canvassMarketId = testCanvassMarket.Id;
            
        // Create Canvass Units
        List<CNVSS_Canvass_Unit__c> canvassUnits = CanvassTestDataUtils.createTestCanvassUnits(canvassMarketId);
        
        // Create Lead Sheet
        CNVSS_Canvass_Lead_Sheet__c testLeadSheetDoNotKnock = CanvassTestDataUtils.createTestCanvassLeadSheet(canvassUnits[2], 'Submit for Do Not Knock List');
        
        /* Perform Test */
        Test.startTest();
        
        // Update Submit for Do Not Knock List
        testLeadSheetDoNotKnock.CNVSS_Status__c = 'Approved: DO NOT CONTACT';
        update testLeadSheetDoNotKnock;
        CNVSS_Canvass_Lead_Sheet__c testCls = CanvassLeadSheetUtils.getCanvassLeadSheetById(testLeadSHeetDoNotKnock.Id);
        boolean canvassUnitDoNotContactField = testCls.CNVSS_Canvass_Unit__r.CNVSS_DO_NOT_CONTACT__c;
        
        Test.stopTest();
        /* Verify Test Results */
        system.assertEquals(true, canvassUnitDoNotContactField);
    }

    
}
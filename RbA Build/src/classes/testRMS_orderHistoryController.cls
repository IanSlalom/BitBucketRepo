/*************************************************************
@brief  Test Class for RMS_orderHistoryController

@author  Brianne Wilson (Slalom.BLW)

@version    2016-5-11  Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
@isTest
(SeeAllData=true)
public class testRMS_orderHistoryController {

        
        static testMethod void mytestRMS_orderHistoryController() {
            
            
            //create controller
          	RMS_orderHistoryController controller = new RMS_orderHistoryController();
            //null myObject
            system.assert(controller.getObjectHistory().size() == 0);
            
            //Account allows for history in related lists in visualforce, this is simply a standard object being used to get code coverage so you can use the component for other custom and standard objects.
            system.assert([select Accountid from accounthistory where isdeleted=false limit 1].size() == 1); //limit in case of 50,000 record governor limit
            string accid = [select Accountid from accounthistory where isdeleted=false limit 1].accountid;
            
            //Set myObject
            controller.myObject = [select id from Account where id=:accid];             
            system.assert(controller.getObjectHistory().size() > 0);        
        }
        
    }
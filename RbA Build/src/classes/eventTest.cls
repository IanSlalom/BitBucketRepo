@isTest
private class eventTest {

    static testMethod void eventTest() {
		 TestUtilityMethods utility = new TestUtilityMethods();
		
		 utility.setUpConfigs();

         Account acct = utility.createAccount('account');
         insert acct;
         Contact cont = utility.createContact(acct.Id, 'contactname');
         insert cont;
         
         Event e = new Event();
         e.Subject='Test for trigger';
         e.WhatId=acct.Id;
         e.WhoId=cont.Id;
         e.Type='Visit';
         e.IsAllDayEvent=false;
         e.DurationInMinutes=60;
         e.activitydatetime=system.now();
         e.ShowAs = 'Busy';
         e.IsReminderSet = false;

        
         insert e;
		
    }
}
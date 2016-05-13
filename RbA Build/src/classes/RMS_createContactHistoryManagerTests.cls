@isTest
private class RMS_createContactHistoryManagerTests {
	
	static Id customerContactRecordType = UtilityMethods.retrieveRecordTypeId('Customer_Contacts', 'Contact');
	@testSetup static void setupData() {
		TestUtilityMethods utility = new TestUtilityMethods();
		
		utility.setUpConfigs();
		
		Account account1 = utility.createVendorAccount('Vendor Account 1 ');
		insert account1;

		Account account2 = new Account(	Name = 'RbA',
										AccountNumber = '1234567890',
										Phone = '(763) 555-2000'
									);
		insert account2;

		Account dwelling = utility.createDwellingAccount('Dwelling Account');

		Account store = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
		dwelling.Store_Location__c = store.Id;
		insert dwelling;		
	}

	@isTest
	static void testcreateContactHistoryonInsert(){
		Account dwelling = [Select Id from Account Where Name = 'Dwelling Account'];

		//Insert first contact
		Contact con = new Contact(AccountId = dwelling.Id, recordTypeId = customerContactRecordType, LastName = 'TestCon1');
		insert con;
		List<Contact_History__c> conHist = [Select Id, Contact__c, Type__c from Contact_History__c where Contact__c =: con.Id AND Dwelling__c =: dwelling.Id];
		System.AssertEquals(conHist.size(),1);
		System.assertEquals(conHist[0].Type__c, 'Current Resident');

		//Update Contact History to another type, then insert a second contact that has the first contact as a spouse. Verify the history is updated to 'Current Resideent'
		conHist[0].Type__c = 'Past Resident';
		update conHist;
		Contact con2 = new Contact(AccountId = dwelling.Id, recordTypeId = customerContactRecordType, LastName = 'TestCon2', Spouse__c = con.Id);
		insert con2;
		conHist = [Select Id, Contact__c, Type__c from Contact_History__c where Dwelling__c =: dwelling.Id];
		System.AssertEquals(conHist.size(),2);
		for(Contact_History__c contactHistory: conHist){
			System.assertEquals(contactHistory.Type__c, 'Current Resident');
		}


	}

	@isTest
	static void testcreateContactHistoryonUpdate(){
		TestUtilityMethods utility = new TestUtilityMethods();
		Account dwelling = [Select Id from Account Where Name = 'Dwelling Account'];

		//Insert first contact
		Contact con = new Contact(AccountId = dwelling.Id, recordTypeId = customerContactRecordType, LastName = 'TestCon1');
		insert con;

		//insert 3 contacts on second account. One will be set as a spouse to the first contact
		Account dwelling2 = utility.createDwellingAccount('Dwelling Account 2');
		insert dwelling2;
		Account dwelling3 = utility.createDwellingAccount('Dwelling Account 3');
		insert dwelling3;
		Contact con2 = new Contact(AccountId = dwelling2.Id, recordTypeId = customerContactRecordType, LastName = 'TestCon2');
		insert con2;
		Contact con3 = new Contact(AccountId = dwelling2.Id, recordTypeId = customerContactRecordType, LastName = 'TestCon3');
		insert con3;
		Contact con1Spouse = new Contact(AccountId = dwelling2.Id, recordTypeId = customerContactRecordType, LastName = 'TestCon1Spouse');
		insert con1Spouse;

		insert new Contact_History__c(Dwelling__c = dwelling3.Id, Contact__c = con3.Id, Type__c = 'Current Resident' );

		con.Spouse__c = con1Spouse.Id;
		con.AccountId = dwelling2.Id;
		update con;

		//Verify the Spouse and the updated contact are Current Resident on the second account, and the other contact gets updated to 'Past Resident'
		List<Contact_History__c> conHist = [Select Id, Contact__c, Type__c from Contact_History__c where Dwelling__c =: dwelling2.Id];
		System.assertEquals(conHist.size(),4);
		for(Contact_History__c ch : conHist){
			if(ch.Contact__c == con.Id || ch.Contact__c == con1Spouse.Id){
				System.assertEquals(ch.Type__c, 'Current Resident');
			}else{
				System.assertEquals(ch.Type__c, 'Past Resident');
			}
		}

		//Verify the 2nd Contact is reparented to the Unassigned Account
		map<String, RMS_Settings__c> RMS_Settings_map = RMS_Settings__c.getAll(); 
    	Id masterAccountId = RMS_Settings_map.get('Unassigned Account Id').Value__c;
		con2 = [Select AccountId from Contact where Id =: con2.Id];
		System.assertEquals(con2.AccountId,masterAccountId);

		//Verify the 3rd Contact is reparented to the Dwelling where a Contact History with Current Resident type exists for it
		con3 = [Select AccountId from Contact where Id =: con3.Id];
		System.assertEquals(con3.AccountId,dwelling3.Id);


	}
}
/*******************************************************//**

@class	RMS_prodConfigExtensionTest

@brief	Test Class for RMS_prodConfigExtension

@author  Creston Kuenzi (Slalom.CDK)

@version	2015-11-22  Slalom.CDK
	Created.

@see		RMS_prodConfigExtension

@copyright  (c)2015 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_prodConfigManagerTest {

	/*******************************************************
					createTestRecords
	*******************************************************/
	static testmethod void createTestRecords(){
		
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
	

		
//		Pricebook2 pricebook1 =  utility.createPricebook2Name('Standard Price Book');
//		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Master Product',
			Vendor__c = account1.id,
			RecordTypeId = UtilityMethods.RecordTypeFor('Product2', 'Master_Product')
		);
		
		insert product1;

		Product_Configuration__c prodConfig= new Product_Configuration__c(
			Name='Product Config',
			Product__c = product1.Id
		);
		
		insert prodConfig;

		Pricing_Configuration__c pricingConfig= new Pricing_Configuration__c(
			Name='Pricing Config'
		);
		
		insert pricingConfig;

		Product2 product2 = new Product2(
			Name='Child Product',
			Vendor__c = account1.id,
			UI_Minimum__c = 0,
			UI_Maximum__c = 40,
			
			Master_Product__c = product1.Id,
			RecordTypeId = UtilityMethods.RecordTypeFor('Product2', 'Child_Product')
		);
		
		insert product2;


		Opportunity opp1 = utility.createOpportunity(dwelling.id, 'Closed - Won');
		insert opp1;
		
		PricebookEntry pricebookEntry1 = utility.createPricebookEntry(Test.getStandardPricebookId(), product2.id);		
		pricebookEntry1.Pricing_Configuration__c = pricingConfig.Id;
		insert pricebookEntry1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling.id, 
									EffectiveDate= Date.Today(), 
									Store_Location__c = store.Id,
									Opportunity = opp1, 									
									Status ='Draft', 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		
		OrderItem orderItem1 = new OrderItem(OrderId = Order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100 );
		insert orderItem1;		

	}

	/*******************************************************
					ProdConfigWrapperTest
	*******************************************************/
	static testmethod void ProdConfigWrapperTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];

		RMS_prodConfigManager.ProductConfigWrapper pcw1 = new RMS_prodConfigManager.ProductConfigWrapper();
		System.Assert(pcw1 != null);

		RMS_prodConfigManager.ProductConfigWrapper pcw2 = new RMS_prodConfigManager.ProductConfigWrapper(priceConfig, soldOrderItem, prodConfig);
		System.AssertEquals(soldOrderItem.Id, pcw2.orderLI.Id);

	}

	/*******************************************************
					findProductConfigurationTest
	*******************************************************/
	static testmethod void findProductConfigurationTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		RMS_prodConfigManager.ProductConfigWrapper pcw1 = new RMS_prodConfigManager.ProductConfigWrapper();

		// retrieve the prodConfigWrapper
		pcw1 = RMS_prodConfigManager.findProductConfiguration(soldOrderItem, childProd.Id, prodConfig);

		// Verify the wrapper has the order line item
		System.AssertEquals(soldOrderItem.Id, pcw1.orderLI.Id);
	}	

	/*******************************************************
					findPricingConfigurationTest
	*******************************************************/
	static testmethod void findPricingConfigurationTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		RMS_prodConfigManager.ProductConfigWrapper pcw1 = new RMS_prodConfigManager.ProductConfigWrapper();

		// retrieve the prodConfigWrapper
		pcw1 = RMS_prodConfigManager.findProductConfiguration(soldOrderItem, childProd.Id, prodConfig);

		// retrieve the pricingConfigWrapper
		pcw1 = RMS_prodConfigManager.findPricingConfiguration(pcw1, priceBookId, childProd.Id);

		// Verify the wrapper has the pricing config
		System.AssertEquals(priceConfig.Id, pcw1.pricingConfig.Id);

	}	

	/*******************************************************
					getObjectFieldsMapTest
	*******************************************************/
	static testmethod void getObjectFieldsMapTest(){
		
		// Retrieve the fieldMap for the account object
		Map<String, Schema.SObjectField> accountMap = RMS_prodConfigManager.getObjectFieldsMap('Account');
		
		// Verify we can retrieve the account name from the map				
		System.Assert(accountMap.get('Name') != null);

	}	

	/*******************************************************
					getCommaSeparatedFieldsTest
	*******************************************************/
	static testmethod void getCommaSeparatedFieldsTest(){
		
		// Retrieve the comma separated fields for the account object
		String fieldString = RMS_prodConfigManager.getCommaSeparatedFields('Account');
		
		// Verify the string contains the account name with a comma				
		System.Assert(fieldString.contains('name, '));

	}	


	/*******************************************************
					retrievePickListItemsTest
	*******************************************************/
	static testmethod void retrievePickListItemsTest(){		
		
		String testString = 'option1;option2;option3';
		// Retrieve the comma separated fields for the account object
		List<SelectOption> options = RMS_prodConfigManager.retrievePickListItems(testString);
		
		// Verify there are 4 options in the list (including the --select--)			
		System.AssertEquals(4, options.size());

	}	

	/*******************************************************
					checkMakeabilityTestNoProdConfig
	*******************************************************/
	static testmethod void checkMakeabilityTestNoProdConfig(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];

		// check the makeability
		String returnMessage = RMS_prodConfigManager.checkMakeability(null, soldOrderItem, 'Master Product');

		// verify no prod config error is thrown
		System.AssertEquals(RMS_errorMessages.PRODUCT_CONFIG_NOT_FOUND, returnMessage);
	}


	/*******************************************************
					checkMakeabilityTestNullHeightWidth
	*******************************************************/
	static testmethod void checkMakeabilityTestNullHeightWidth(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		// Set the width / height to null
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = null;
		soldOrderItem.Height_Inches__c = null;

		// check the makeability
		String returnMessage = RMS_prodConfigManager.checkMakeability(prodConfig, soldOrderItem, 'Master Product');

		// verify no width / height error is thrown
		System.AssertEquals(RMS_errorMessages.WIDTH_HEIGHT_EMPTY, returnMessage);
	}

	/*******************************************************
					checkMakeabilityTestMin
	*******************************************************/
	static testmethod void checkMakeabilityTestMin(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		// Set the minimum width & height and leg
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.Min_Width__c = 15;
		prodConfig.Min_Height__c = 15;
		prodConfig.Minimum_Leg_Height__c = 10;

		// Set the width & height and legs
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 14;
		soldOrderItem.Width_Fraction__c = '15/16';
		soldOrderItem.Height_Inches__c = 14;
		soldOrderItem.Height_Fraction__c = '15/16';
		soldOrderItem.Left_Leg_Inches__c = 9;
		soldOrderItem.Left_Leg_Fraction__c = '15/16';
		soldOrderItem.Right_Leg_Inches__c = 9;
		soldOrderItem.Right_Leg_Fraction__c = '15/16';

		// check the makeability
		String returnMessage = RMS_prodConfigManager.checkMakeability(prodConfig, soldOrderItem, 'Master Product');

		// verify width/height/leg below min errors are thrown
//		System.Assert(returnMessage.contains(RMS_errorMessages.WIDTH_BELOW_MIN));
//		System.Assert(returnMessage.contains(RMS_errorMessages.HEIGHT_BELOW_MIN));
//		System.Assert(returnMessage.contains(RMS_errorMessages.MINIMUM_LEG_HEIGHT_LEFT));
//		System.Assert(returnMessage.contains(RMS_errorMessages.MINIMUM_LEG_HEIGHT_RIGHT));

		// Set the width & height to 15 1/16
		soldOrderItem.Width_Inches__c = 15;
		soldOrderItem.Width_Fraction__c = '1/16';
		soldOrderItem.Height_Inches__c = 15;
		soldOrderItem.Height_Fraction__c = '1/16';
		soldOrderItem.Left_Leg_Inches__c = 10;
		soldOrderItem.Left_Leg_Fraction__c = '1/16';
		soldOrderItem.Right_Leg_Inches__c = 10;
		soldOrderItem.Right_Leg_Fraction__c = '1/16';

		// check the makeability
		returnMessage = RMS_prodConfigManager.checkMakeability(prodConfig, soldOrderItem, 'Master Product');

		// verify width/height/leg below min errors are NOT thrown
		System.Assert(!returnMessage.contains(RMS_errorMessages.WIDTH_BELOW_MIN));
		System.Assert(!returnMessage.contains(RMS_errorMessages.HEIGHT_BELOW_MIN));
		System.Assert(!returnMessage.contains(RMS_errorMessages.MINIMUM_LEG_HEIGHT_LEFT));
		System.Assert(!returnMessage.contains(RMS_errorMessages.MINIMUM_LEG_HEIGHT_RIGHT));

	}

	/*******************************************************
					checkMakeabilityTestMax
	*******************************************************/
	static testmethod void checkMakeabilityTestMax(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		// Set the minimum width & height to 15 and united inch max to 30
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.Max_Width__c = 15;
		prodConfig.Max_Height__c = 15;
		prodConfig.United_Inch_Maximum__c = 30;
		prodConfig.Glass_Square_Ft_Max__c = 1.56;
		
		// Set the width & height to 14 15/16
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 14;
		soldOrderItem.Width_Fraction__c = '15/16';
		soldOrderItem.Height_Inches__c = 14;
		soldOrderItem.Height_Fraction__c = '15/16';

		// check the makeability
		String returnMessage = RMS_prodConfigManager.checkMakeability(prodConfig, soldOrderItem, 'Master Product');

		// verify width/height/united/square foot above max errors are NOT thrown
		System.Assert(!returnMessage.contains(RMS_errorMessages.WIDTH_ABOVE_MAX));
		System.Assert(!returnMessage.contains(RMS_errorMessages.HEIGHT_ABOVE_MAX));
		System.Assert(!returnMessage.contains(RMS_errorMessages.UNITED_INCH_ABOVE_MAX));
		System.Assert(!returnMessage.contains(RMS_errorMessages.GLASS_MAX_SQ_FEET));

		// Set the width & height to 15 1/16
		soldOrderItem.Width_Inches__c = 15;
		soldOrderItem.Width_Fraction__c = '1/16';
		soldOrderItem.Height_Inches__c = 15;
		soldOrderItem.Height_Fraction__c = '1/16';

		// check the makeability
		returnMessage = RMS_prodConfigManager.checkMakeability(prodConfig, soldOrderItem, 'Master Product');

		// verify width/height/united inch above max errors are thrown
//		System.Assert(returnMessage.contains(RMS_errorMessages.WIDTH_ABOVE_MAX));
//		System.Assert(returnMessage.contains(RMS_errorMessages.HEIGHT_ABOVE_MAX));
//		System.Assert(returnMessage.contains(RMS_errorMessages.UNITED_INCH_ABOVE_MAX));
//		System.Assert(returnMessage.contains(RMS_errorMessages.GLASS_MAX_SQ_FEET));
	}

	/*******************************************************
					checkMakeabilityTestHWCap
	*******************************************************/
	static testmethod void checkMakeabilityTestHWCap(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		// Set the caps
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.Width_to_Height_Cap_Height__c = 80;
		prodConfig.Width_to_Height_Cap_Width__c = 60;
		prodConfig.Height_to_Width_Cap_Height__c = 80;
		prodConfig.Height_to_Width_Cap_Width__c = 60;

		// Set the width below the cap and the height above
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 59;
		soldOrderItem.Width_Fraction__c = '15/16';
		soldOrderItem.Height_Inches__c = 80;
		soldOrderItem.Height_Fraction__c = '5/16';

		// check the makeability
		String returnMessage = RMS_prodConfigManager.checkMakeability(prodConfig, soldOrderItem, 'Master Product');

		// verify cap errors are NOT thrown
		System.Assert(!returnMessage.contains(RMS_errorMessages.HEIGHT_TO_WIDTH_CAP));
		System.Assert(!returnMessage.contains(RMS_errorMessages.WIDTH_TO_HEIGHT_CAP));

		// Set the width above the caps
		soldOrderItem.Width_Inches__c = 60;
		soldOrderItem.Width_Fraction__c = '1/16';

		// check the makeability
		returnMessage = RMS_prodConfigManager.checkMakeability(prodConfig, soldOrderItem, 'Master Product');

		// verify cap errors are thrown
		System.Assert(returnMessage.contains(RMS_errorMessages.HEIGHT_TO_WIDTH_CAP));
		System.Assert(returnMessage.contains(RMS_errorMessages.WIDTH_TO_HEIGHT_CAP));
	}
}
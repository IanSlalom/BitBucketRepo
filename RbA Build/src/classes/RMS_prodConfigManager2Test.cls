/*******************************************************//**

@class	RMS_prodConfigManager2Test

@brief	Test Class for RMS_prodConfigManager2

@author  Kai Ruan (Slalom.CDK)

@version	2016-09-06  Slalom.CDK
	Created.

@see		RMS_prodConfigManager2

@copyright  (c)2016 Slalom.  All Rights Reserved. 
			Unauthorized use is prohibited.

***********************************************************/
@isTest
private class RMS_prodConfigManager2Test {

	/*******************************************************
					createTestRecords
	*******************************************************/
	@testSetup
	static void createTestRecords(){
		
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
		
		//Changed from product2.Id to product1.Id, so prod config and order item are both linked to the same product

		//PricebookEntry pricebookEntry1 = utility.createPricebookEntry(Test.getStandardPricebookId(), product2.id);	
		PricebookEntry pricebookEntry1 = utility.createPricebookEntry(Test.getStandardPricebookId(), product1.id);		
	
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
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		RMS_prodConfigManager2.ProductConfigWrapper pcw1 = new RMS_prodConfigManager2.ProductConfigWrapper();

		// retrieve the prodConfigWrapper
		pcw1 = RMS_prodConfigManager2.findProductConfiguration(soldOrderItem, childProd.Id, prodConfig);

		// Verify the wrapper has the order line item
		System.AssertEquals(soldOrderItem.Id, pcw1.orderLI.Id);
	}	

	/*******************************************************
					findPricingConfigurationTest
	*******************************************************/
	static testmethod void findPricingConfigurationTest(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Master Product'];

		RMS_prodConfigManager2.ProductConfigWrapper pcw1 = new RMS_prodConfigManager2.ProductConfigWrapper();

		// retrieve the prodConfigWrapper
		pcw1 = RMS_prodConfigManager2.findProductConfiguration(soldOrderItem, childProd.Id, prodConfig);

		// retrieve the pricingConfigWrapper
		pcw1 = RMS_prodConfigManager2.findPricingConfiguration(pcw1, priceBookId, childProd.Id);

		// Verify the wrapper has the pricing config
		System.AssertEquals(priceConfig.Id, pcw1.pricingConfig.Id);

	}	

	/*******************************************************
					checkMakeabilityTestNoProdConfig
	*******************************************************/
	static testmethod void checkMakeabilityTestNoProdConfig(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		delete prodConfig;
		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
	
		// verify no prod config error is thrown
		System.Assert(returnMessage.contains(RMS_errorMessages.PRODUCT_CONFIG_NOT_FOUND));
	}


	/*******************************************************
					checkMakeabilityTestNullHeightWidth
	*******************************************************/
	static testmethod void checkMakeabilityTestNullHeightWidth(){
		

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
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);

		// verify no width / height error is thrown
		System.Assert(returnMessage.contains(RMS_errorMessages.WIDTH_HEIGHT_EMPTY));
	}

	/*******************************************************
					checkMakeabilityTestMax
	*******************************************************/
	static testmethod void checkMakeabilityTestMax(){
		

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
		prodConfig.Rectangular_Area_Limitation__c = 1.56;
		prodConfig.Maximum_Leg_Height__c = 15;

		// Set the extended height / width
		prodConfig.Extended_Max_Height__c = 15;
		prodConfig.Extended_Max_Width__c = 15;
		
		update prodConfig;
		
		// Set the width & height to 14 15/16
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 14;
		soldOrderItem.Width_Fraction__c = '15/16';
		soldOrderItem.Height_Inches__c = 14;
		soldOrderItem.Height_Fraction__c = '15/16';
		soldOrderItem.Left_Leg_Inches__c = 14;
		soldOrderItem.Left_Leg_Fraction__c = '15/16';
		soldOrderItem.Right_Leg_Inches__c = 14;
		soldOrderItem.Right_Leg_Fraction__c = '15/16';

		update soldOrderItem;
		Test.startTest();
		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);

		// verify width/height/united/square foot above max errors are NOT thrown
		System.Assert(!returnMessage.contains('above the maximum'));
		System.Assert(!returnMessage.contains('united inch total'));
		System.Assert(!returnMessage.contains('max square feet'));
		System.Assert(!returnMessage.contains('rectangular area limitation'));

		// Set the width & height to 15 1/16
		soldOrderItem.Width_Inches__c = 15;
		soldOrderItem.Width_Fraction__c = '1/16';
		soldOrderItem.Height_Inches__c = 15;
		soldOrderItem.Height_Fraction__c = '1/16';
		soldOrderItem.Left_Leg_Inches__c = 15;
		soldOrderItem.Left_Leg_Fraction__c = '1/16';
		soldOrderItem.Right_Leg_Inches__c = 15;
		soldOrderItem.Right_Leg_Fraction__c = '1/16';
		update soldOrderItem;
		// check the makeability
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		test.stopTest();

		// verify width/height/united inch above max errors are thrown
		System.Assert(returnMessage.contains('above the maximum'));
		System.Assert(returnMessage.contains('united inch total'));
		System.Assert(returnMessage.contains('max square feet'));
		System.Assert(returnMessage.contains('rectangular area limitation'));
		System.Assert(returnMessage.contains('left leg height'));
		System.Assert(returnMessage.contains('right leg height'));

	}
	

	/*******************************************************
					checkMakeabilityTestMin
	*******************************************************/
	static testmethod void checkMakeabilityTestMin(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		// Set the minimum width & height and leg
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.Min_Width__c = 15;
		prodConfig.Min_Height__c = 15;
		prodConfig.Minimum_Leg_Height__c = 10;
		prodConfig.United_Inch_Minimum__c = 30;
		update prodConfig;

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
		update soldOrderItem;

		test.startTest();
		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);

		// verify width/height/leg below min errors are thrown
//		System.Assert(returnMessage.contains(RMS_errorMessages.WIDTH_BELOW_MIN));
//		System.Assert(returnMessage.contains(RMS_errorMessages.HEIGHT_BELOW_MIN));
//		System.Assert(returnMessage.contains(RMS_errorMessages.MINIMUM_LEG_HEIGHT_LEFT));
//		System.Assert(returnMessage.contains(RMS_errorMessages.MINIMUM_LEG_HEIGHT_RIGHT));
		Decimal widthInches = soldOrderItem.Width_Inches__c + UtilityMethods.calculateFraction(soldOrderItem.Width_Fraction__c);
		Decimal heightInches = soldOrderItem.Height_Inches__c + UtilityMethods.calculateFraction(soldOrderItem.Height_Fraction__c);
		System.Assert(returnMessage.contains(RMS_prodConfigManager.fillInErrorRuleValues(RMS_errorMessages.UNITED_INCH_BELOW_MIN, String.ValueOf(widthInches + heightInches), String.ValueOf(prodConfig.United_Inch_Minimum__c))));

		// Set the width & height to 15 1/16
		soldOrderItem.Width_Inches__c = 15;
		soldOrderItem.Width_Fraction__c = '1/16';
		soldOrderItem.Height_Inches__c = 15;
		soldOrderItem.Height_Fraction__c = '1/16';
		soldOrderItem.Left_Leg_Inches__c = 10;
		soldOrderItem.Left_Leg_Fraction__c = '1/16';
		soldOrderItem.Right_Leg_Inches__c = 10;
		soldOrderItem.Right_Leg_Fraction__c = '1/16';
		update soldOrderItem;
		// check the makeability
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);

		// verify width/height/leg below min errors are NOT thrown
		System.Assert(!returnMessage.contains(RMS_errorMessages.WIDTH_BELOW_MIN));
		System.Assert(!returnMessage.contains(RMS_errorMessages.HEIGHT_BELOW_MIN));
		System.Assert(!returnMessage.contains(RMS_errorMessages.MINIMUM_LEG_HEIGHT_LEFT));
		System.Assert(!returnMessage.contains(RMS_errorMessages.MINIMUM_LEG_HEIGHT_RIGHT));
		System.Assert(!returnMessage.contains(RMS_prodConfigManager.fillInErrorRuleValues(RMS_errorMessages.UNITED_INCH_BELOW_MIN, String.valueOf(30.0+1.0/8), String.ValueOf(prodConfig.United_Inch_Minimum__c))));
		Test.stopTest();
	}

	/*******************************************************
					checkMakeabilityTestHWCap
	*******************************************************/
	static testmethod void checkMakeabilityTestHWCap(){
		

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

		// Set the extended height / width
		prodConfig.Extended_Max_Height__c = 80;
		prodConfig.Extended_Max_Width__c = 60;
		
		update prodConfig;
		// Set the width below the cap and the height above
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 59;
		soldOrderItem.Width_Fraction__c = '15/16';
		soldOrderItem.Height_Inches__c = 80;
		soldOrderItem.Height_Fraction__c = '5/16';

		update soldOrderItem;

		Test.startTest();
		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);

		// verify cap errors are NOT thrown
		System.Assert(!returnMessage.contains(RMS_errorMessages.HEIGHT_TO_WIDTH_CAP));
		System.Assert(!returnMessage.contains(RMS_errorMessages.WIDTH_TO_HEIGHT_CAP));
		System.Assert(!returnMessage.contains(RMS_errorMessages.EXTENDED_MAX));

		// Set the width above the caps
		soldOrderItem.Width_Inches__c = 60;
		soldOrderItem.Width_Fraction__c = '1/16';

		update soldOrderItem;
		// check the makeability
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);

		// verify cap errors are thrown
		System.Assert(returnMessage.contains(RMS_errorMessages.HEIGHT_TO_WIDTH_CAP));
		System.Assert(returnMessage.contains(RMS_errorMessages.WIDTH_TO_HEIGHT_CAP));
		Test.stopTest();
		//System.Assert(returnMessage.contains(RMS_errorMessages.EXTENDED_MAX));
	}

	/*******************************************************
					checkMakeabilityTestPeakHeight
	*******************************************************/
	static testmethod void checkMakeabilityTestPeakHeight(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		// Set the peak height min and max
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		//prodConfig.Peak_Height__c = 0.8;
		prodConfig.Peak_Height_Min__c = 0.5;
		prodConfig.Peak_Height_Max__c = 1.5;
		update prodConfig;

		// Set the difference between left and right leg at 10 inches, and Width at 5.5
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 5;
		soldOrderItem.Width_Fraction__c = '8/16';
		soldOrderItem.Height_Inches__c = 5;
		
		
		soldOrderItem.Left_Leg_Inches__c = 40;
		soldOrderItem.Left_Leg_Fraction__c = '5/16';
		soldOrderItem.Right_Leg_Inches__c = 50;
		soldOrderItem.Right_Leg_Fraction__c = '5/16';
		update soldOrderItem;

		test.StartTest();
		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		system.debug(returnMessage);

		// assert peak height max error message is included
		System.assert(returnMessage.contains(RMS_ErrorMessages.PEAK_HEIGHT_MAX));
		System.assert(!returnMessage.contains(RMS_ErrorMessages.PEAK_HEIGHT_MIN));

		soldOrderItem.Left_Leg_Inches__c = 49;
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);

		// assert peak height min error message is included
		System.assert(!returnMessage.contains(RMS_ErrorMessages.PEAK_HEIGHT_MAX));
		System.assert(returnMessage.contains(RMS_ErrorMessages.PEAK_HEIGHT_MIN));
		test.stopTest();
	}

	/*******************************************************
					checkMakeabilityspecWidthtoHeight
	*******************************************************/
	static testmethod void checkMakeabilityspecWidthtoHeight(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		// Set the caps
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.Specialty_Width_to_Height_Ratio_Max__c = 0.8;
		prodConfig.Specialty_Width_to_Height_Ratio_Min__c = 2.5;
		update prodConfig;

		// Set the width below the cap and the height above
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 60;
		soldOrderItem.Width_Fraction__c = '15/16';
		soldOrderItem.Height_Inches__c = 30;
		
		soldOrderItem.Height_Fraction__c = '15/16';
		update soldOrderItem;
		test.startTest();
		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		test.stopTest();
		// TODO: Asserts
	}

	/*******************************************************
					checkMakeabilityBrickMouldSlopeTest
	*******************************************************/
	static testmethod void checkMakeabilityBrickMouldSlopeTest(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];
		childProd.Name = 'Double-Hung';
		update childProd;

		// Set the caps
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.Specialty_Width_to_Height_Ratio_Max__c = 0.8;
		prodConfig.Specialty_Width_to_Height_Ratio_Min__c = 0.1;
		update prodConfig;

		// Set the width below the cap and the height above
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 59;
		soldOrderItem.Width_Fraction__c = '15/16';
		soldOrderItem.Height_Inches__c = 59;
		soldOrderItem.Height_Fraction__c = '15/16';
		soldOrderItem.Frame_Type__c = 'Insert Frame';
		soldOrderItem.Sill_Angle__c = 'FS';
		soldOrderItem.Exterior_Trim__c = 'Brickmould - Picture Frame';
		update soldOrderItem;

		test.startTest();
		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		test.stopTest();
		// TODO: Asserts
	}

	/*******************************************************
					checkMakeabilityScreenConfigTest
	*******************************************************/
	static testmethod void checkMakeabilityScreenConfigTest(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		// Set the caps
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.Min_Width__c = 10;
		update prodConfig;

		Screen_Configuration__c sc = new Screen_Configuration__c(Product_Configuration__c = prodConfig.Id, Max_Width_Inches__c = 20, Max_Height_Inches__c = 20);
		insert sc;

		// Set the width below the cap and the height above
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 59;
		soldOrderItem.Width_Fraction__c = '15/16';
		soldOrderItem.Height_Inches__c = 59;
		soldOrderItem.Height_Fraction__c = '15/16';
		update soldOrderItem;

		test.startTest();
		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		test.stopTest();
		// TODO: Asserts
	}

	/*******************************************************
					checkMakeabilitySashConfigTest
	*******************************************************/
	static testmethod void checkMakeabilitySashConfigTest(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.Sash_Ratio__c = '1:1';
		prodConfig.Sash_Operation__c = 'Left Vent/Stationary;Left';
		update prodConfig;

		Sash_Configuration__c sc = new Sash_Configuration__c(Product_Configuration__c = prodConfig.Id, Sash_Ratio__c='1:1', Sash_Operation__c = 'Left Vent/Stationary');
		insert sc;

		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Sash_Ratio__c = '1:1';
		soldOrderItem.Sash_Operation__c = 'Left Vent/Stationary';
		soldOrderItem.Width_Inches__c = 59;
		soldOrderItem.Height_Inches__c = 59;
		update soldOrderItem;

		test.startTest();
		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(!returnMessage.contains(RMS_errorMessages.SASH_RATIO_OPERATION));

		soldOrderItem.Sash_Operation__c = 'Left';
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(returnMessage.contains(RMS_errorMessages.SASH_RATIO_OPERATION));
		test.stopTest();
	}

	/*******************************************************
					checkMakeabilityEJConfigTest
	*******************************************************/
	static testmethod void checkMakeabilityEJConfigTest(){
		
		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.EJ_Species__c = 'Oak';
		prodConfig.EJ_Color__c = 'White;Black';
		update prodConfig;

		EJ_Color_Configuration__c ejc = new EJ_Color_Configuration__c(Product_Configuration__c = prodConfig.Id, EJ_Species__c='Oak', EJ_Color__c = 'White');
		insert ejc;

		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.EJ_Species__c = 'Oak';
		soldOrderItem.EJ_Color__c = 'White';
		soldOrderItem.Width_Inches__c = 59;
		soldOrderItem.Height_Inches__c = 59;
		update soldOrderItem;

		Test.startTest();
		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(!returnMessage.contains(RMS_errorMessages.EJ_SPECIES_COLOR));

		soldOrderItem.EJ_Color__c = 'Black';
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(returnMessage.contains(RMS_errorMessages.EJ_SPECIES_COLOR));
		Test.stopTest();
	}

	/*******************************************************
					checkMakeabilityColorConfigTest
	*******************************************************/
	static testmethod void checkMakeabilityColorConfigTest(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.Exterior_Color__c = 'Red';
		prodConfig.Interior_Color__c = 'White;Black';
		update prodConfig;
		
		Color_Configuration__c cc = new Color_Configuration__c(Product_Configuration__c = prodConfig.Id, Exterior_Color__c='Red', Interior_Color__c = 'White');
		insert cc;

		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Exterior_Color__c = 'Red';
		soldOrderItem.Interior_Color__c = 'White';
		soldOrderItem.Width_Inches__c = 59;
		soldOrderItem.Height_Inches__c = 59;
		update soldOrderItem;
		// check the makeability
		test.startTest();
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(!returnMessage.contains(RMS_errorMessages.COLOR_EXT_INT));

		soldOrderItem.Interior_Color__c = 'Black';
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id); 
	
		System.assert(returnMessage.contains(RMS_errorMessages.COLOR_EXT_INT));
		test.StopTest();
	}
	
	/*******************************************************
					checkMakeabilityGrilleControlTest
	*******************************************************/
	static testmethod void checkMakeabilityGrilleControlTest(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		// Set the caps
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.EJ_Species__c = 'Oak';
		prodConfig.EJ_Color__c = 'White;Black';
		update prodConfig;
		
		Specialty_Grille_Control__c gc = new Specialty_Grille_Control__c(Product_Configuration__c = prodConfig.Id, Grille_Style__c= 'Required', Grille_Pattern__c = 'Colonial',
																					Specialty_Shape__c = 'Pentagon' ,Hubs__c = 'Required', Spokes__c = 'Required', 
																					Lites_High__c = 'Required', Lites_Wide__c ='Required');
		insert gc;


		// Set the Grille Style, Grille Pattern, and Specialty Shape
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 14;
		soldOrderItem.Height_Inches__c = 14;
		soldOrderItem.Grille_Pattern_S1__c = 'Colonial';
		soldOrderItem.Specialty_Shape__c = 'Pentagon';
		update soldOrderItem;

		Test.startTest();

		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(returnMessage.contains(RMS_errorMessages.GRILLE_SPOKES_REQUIRED));
		System.assert(returnMessage.contains(RMS_errorMessages.GRILLE_HUBS_REQUIRED));
		System.assert(returnMessage.contains(RMS_errorMessages.GRILLE_LITES_HIGH_REQUIRED));
		System.assert(returnMessage.contains(RMS_errorMessages.GRILLE_LITES_WIDE_REQUIRED));
		System.assert(returnMessage.contains(RMS_errorMessages.GRILLE_STYLE_REQUIRED));
		
		soldOrderItem.Spokes__c = '2';
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(!returnMessage.contains(RMS_errorMessages.GRILLE_SPOKES_REQUIRED));

		soldOrderItem.Hubs__c = '1';
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(!returnMessage.contains(RMS_errorMessages.GRILLE_HUBS_REQUIRED));

		
		soldOrderItem.Lites_High_S1__c = 1;
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(!returnMessage.contains(RMS_errorMessages.GRILLE_LITES_HIGH_REQUIRED));

		soldOrderItem.Lites_Wide_S1__c =2;
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(!returnMessage.contains(RMS_errorMessages.GRILLE_LITES_WIDE_REQUIRED));

		soldOrderItem.Grille_Style__c = 'Colonial';
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(!returnMessage.contains(RMS_errorMessages.GRILLE_STYLE_REQUIRED));

		gc.Hubs__c = 'Disabled';
		gc.Spokes__c = 'Disabled';
		gc.Lites_Wide__c = 'Disabled';
		gc.Lites_High__c = 'Disabled';
		gc.Grille_Style__c = 'Disabled';
		update gc;
	
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(returnMessage.contains(RMS_errorMessages.GRILLE_SPOKES_DISABLED));
		System.assert(returnMessage.contains(RMS_errorMessages.GRILLE_HUBS_DISABLED));
		System.assert(returnMessage.contains(RMS_errorMessages.GRILLE_LITES_HIGH_DISABLED));
		System.assert(returnMessage.contains(RMS_errorMessages.GRILLE_LITES_WIDE_DISABLED));
		System.assert(returnMessage.contains(RMS_errorMessages.GRILLE_STYLE_DISABLED));
		test.stoptest();
	
	}

	/*******************************************************
					checkMakeabilityGrilleConfigTest
	*******************************************************/
	static testmethod void checkMakeabilityGrilleConfigTest(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		

		// Set the caps
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.EJ_Species__c = 'Oak';
		prodConfig.EJ_Color__c = 'White;Black';
		update prodConfig;
		
		Specialty_Grille_Configuration__c gc = new Specialty_Grille_Configuration__c(Product_Configuration__c = prodConfig.Id, Grille_Style__c='Interior Wood Only', Grille_Pattern__c = 'Colonial',
																					Specialty_Shape__c = 'Pentagon' ,Hubs__c = 1, Spokes__c = 1, Lites_High__c = 1, Lites_Wide__c =1);
		insert gc;

		Specialty_Grille_Configuration__c gc2 = new Specialty_Grille_Configuration__c(Product_Configuration__c = prodConfig.Id, Grille_Style__c='Interior Wood Only', Grille_Pattern__c = 'Colonial',
																					Specialty_Shape__c = 'Pentagon' ,Hubs__c = 2, Spokes__c = 2, Lites_High__c = 2, Lites_Wide__c =2);
		insert gc2;

		// Set the width below the cap and the height above
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 14;
		soldOrderItem.Height_Inches__c = 14;
		soldOrderItem.Grille_Style__c='No Grilles';
		soldOrderItem.Grille_Pattern_S1__c = 'Colonial';
		soldOrderItem.Specialty_Shape__c = 'Pentagon';
		update soldOrderItem;


		Test.startTest();
		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(returnMessage.contains(RMS_errorMessages.GRILLE_STYLE_SHAPE_PATTERN));

		soldOrderItem.Grille_Style__c='Interior Wood Only';
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(!returnMessage.contains(RMS_errorMessages.GRILLE_STYLE_SHAPE_PATTERN));

		soldOrderItem.Hubs__c = '1';
		soldOrderItem.Spokes__c = '2';
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(returnMessage.contains(RMS_errorMessages.GRILLE_HUBS_SPOKES));

		soldOrderItem.Spokes__c = '1';
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(!returnMessage.contains(RMS_errorMessages.GRILLE_HUBS_SPOKES));

		soldOrderItem.Lites_High_S1__c = 1;
		soldOrderItem.Lites_Wide_S1__c =2;
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(returnMessage.contains(RMS_errorMessages.GRILLE_LITES));

		soldOrderItem.Lites_High_S1__c =2;
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(!returnMessage.contains(RMS_errorMessages.GRILLE_LITES));
		test.stoptest();
	
	}

	/*******************************************************
					checkMakeabilityGrillePatternConfigTest
	*******************************************************/
	static testmethod void checkMakeabilityGrillePatternConfigTest(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		// Set the caps
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.Min_Width__c = 1;
		prodConfig.Min_Height__c = 1;
		update prodConfig;
		
		Grille_Pattern_Configuration__c gc = new Grille_Pattern_Configuration__c(			Product_Configuration__c = prodConfig.Id,  Grille_Pattern__c = 'Colonial',
																							Grille_Style__c = 'Interior Wood Only',
																							Sash_Ratio__c = '1:1', Min_Width_Inches__c = 1,
																							Min_Width_Fraction__c = '1/2',
																							Min_Height_Inches__c = 1,
																							Min_Height_Fraction__c = '1/2');
		insert gc;


		// Set the width below the cap and the height above
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 1;
		soldOrderItem.Height_Inches__c = 1;
		soldOrderItem.Grille_Pattern_S1__c = 'Colonial';
		soldOrderItem.Grille_Style__c = 'Interior Wood Only';
		soldOrderItem.Sash_Ratio__c = '1:1';
		update soldOrderItem;

		Test.startTest();

		// check the makeability
		String requiredHeightString =  String.ValueOf(gc.Min_Height_Inches__c) + ' '+ (gc.Min_Height_Fraction__c == null? '' : String.valueOf(gc.Min_Height_Fraction__c));
		String heightErrorMessage = RMS_ProdConfigManager.fillInErrorRuleValues(RMS_errorMessages.GRILLE_MIN_HEIGHT, '', requiredHeightString);
		String requiredWidthString =  String.ValueOf(gc.Min_Width_Inches__c) + ' '+(gc.Min_Width_Fraction__c == null? '' : String.valueOf(gc.Min_Width_Fraction__c));
		String widthErrorMessage = RMS_ProdConfigManager.fillInErrorRuleValues(RMS_errorMessages.GRILLE_MIN_WIDTH, '', requiredWidthString);
											
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(returnMessage.contains(heightErrorMessage));
		System.assert(returnMessage.contains(widthErrorMessage));

		soldOrderItem.Width_Fraction__c = '7/8';
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(returnMessage.contains(heightErrorMessage));
		System.assert(!returnMessage.contains(widthErrorMessage));

		soldOrderItem.Height_Fraction__c = '7/8';
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(!returnMessage.contains(heightErrorMessage));
		System.assert(!returnMessage.contains(widthErrorMessage));
		Test.stopTest();
	}

	/*******************************************************
					checkMakeabilityGlazingConfigTest
	*******************************************************/
	static testmethod void checkMakeabilityGlazingConfigTest(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];

		// Set the caps
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.Min_Width__c = 1;
		prodConfig.Min_Height__c = 1;
		update prodConfig;

		Glazing_Configuration__c gc = new Glazing_Configuration__c(			Product_Configuration__c = prodConfig.Id,  Glazing__c ='High Performance Obscure',
																							Sash_Ratio__c = '1:1', Max_Width_Inches__c = 1,
																							Max_Width_Fraction__c = '1/2',
																							Max_Height_Inches__c = 1,
																							Max_Height_Fraction__c = '1/2');
		insert gc;


		// Set the width below the cap and the height above
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 1;
		soldOrderItem.Height_Inches__c = 1;
		soldOrderItem.Glazing_S1__c = 'High Performance Obscure';
		soldOrderItem.Sash_Ratio__c = '1:1';
		update soldOrderItem;

		Test.startTest();

		// check the makeability
		String requiredHeightString =  String.ValueOf(gc.Max_Height_Inches__c) + ' ' + (gc.Max_Height_Fraction__c == null? '' : String.valueOf(gc.Max_Height_Fraction__c));
		String heightErrorMessage = RMS_ProdConfigManager.fillInErrorRuleValues(RMS_errorMessages.GLAZING_MAX_HEIGHT, '', requiredHeightString);
		String requiredWidthString =  String.ValueOf(gc.Max_Width_Inches__c) + ' ' + (gc.Max_Width_Fraction__c == null? '' : String.valueOf(gc.Max_Width_Fraction__c));
		String widthErrorMessage = RMS_ProdConfigManager.fillInErrorRuleValues(RMS_errorMessages.GLAZING_MAX_WIDTH, '', requiredWidthString);
											
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(!returnMessage.contains(heightErrorMessage));
		System.assert(!returnMessage.contains(widthErrorMessage));

		soldOrderItem.Width_Fraction__c = '7/8';
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.debug('GLAZINGCONFIGMESSAGE ' + returnMessage);
		System.assert(!returnMessage.contains(heightErrorMessage));
		System.assert(returnMessage.contains(widthErrorMessage));

		soldOrderItem.Height_Fraction__c = '7/8';
		update soldOrderItem;
		returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		System.assert(returnMessage.contains(heightErrorMessage));
		System.assert(returnMessage.contains(widthErrorMessage));
		Test.stopTest();
	}	

/*******************************************************
					checkMakeabilityLockMaxTest
	*******************************************************/
	static testmethod void checkMakeabilityLockMaxTest(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		// Set the caps
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.Lock_Max_Width_Inches__c = 60;
		prodConfig.Lock_Max_Width_Locks__c = '1';
		prodConfig.Lock_Max_Height_Inches__c = 60;
		prodConfig.Lock_Max_Height_Locks__c = '1';
		update prodConfig;

		// Set the width below the cap and the height above
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 59;
		soldOrderItem.Width_Fraction__c = '15/16';
		soldOrderItem.Height_Inches__c = 59;
		soldOrderItem.Height_Fraction__c = '15/16';
		soldOrderItem.Locks_Sash__c = '2';
		update soldOrderItem;
		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);
		// TODO: Asserts
	}

	/*******************************************************
					checkMakeabilityLockMinTest
	*******************************************************/
	static testmethod void checkMakeabilityLockMinTest(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		// Set the caps
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.Lock_Min_Width_Inches__c = 50;
		prodConfig.Lock_Min_Width_Locks__c = '2';
		prodConfig.Lock_Min_Height_Inches__c = 50;
		prodConfig.Lock_Min_Height_Locks__c = '2';
		update prodConfig;

		// Set the width below the cap and the height above
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 59;
		soldOrderItem.Width_Fraction__c = '15/16';
		soldOrderItem.Height_Inches__c = 59;
		soldOrderItem.Height_Fraction__c = '15/16';
		soldOrderItem.Locks_Sash__c = '1';
		update soldOrderItem;

		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);

		// TODO: Asserts
	}

	/*******************************************************
					checkMakeabilityMaxColorTest
	*******************************************************/
	static testmethod void checkMakeabilityMaxColorTest(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		// Set the caps
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.Int_Color_Max_Width_Inches__c = 50;
		prodConfig.Int_Color_Max__c = 'White';
		prodConfig.Int_Color_Max_Height_Inches__c = 50;
		update prodConfig;

		// Set the width below the cap and the height above
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 59;
		soldOrderItem.Width_Fraction__c = '15/16';
		soldOrderItem.Height_Inches__c = 59;
		soldOrderItem.Height_Fraction__c = '15/16';
		soldOrderItem.Interior_Color__c = 'White';
		update soldOrderItem;
		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);

		// TODO: Asserts
	}

	/*******************************************************
					checkMakeabilityHWFinishRequiredTest
	*******************************************************/
	static testmethod void checkMakeabilityHWFinishRequiredTest(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		// Set the caps
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.HW_Finish_Required__c = true;
		update prodConfig;

		// Set the width below the cap and the height above
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 59;
		soldOrderItem.Width_Fraction__c = '15/16';
		soldOrderItem.Height_Inches__c = 59;
		soldOrderItem.Height_Fraction__c = '15/16';
		soldOrderItem.Hardware_Style__c = 'trad';
		update soldOrderItem;

		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);

		// TODO: Asserts
	}

	/*******************************************************
					checkMakeabilityTemperedTest
	*******************************************************/
	static testmethod void checkMakeabilityTemperedTest(){
		

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Pricing_Configuration__c priceConfig = [SELECT Id FROM Pricing_Configuration__c WHERE Name = 'Pricing Config'];
		Product2 childProd = [SELECT Id FROM Product2 WHERE Name = 'Child Product'];

		// Set the caps
		Product_Configuration__c prodConfig = [SELECT Id FROM Product_Configuration__c WHERE Name = 'Product Config'];
		prodConfig.Tempered_Square_Ft_Max__c = 100;
		prodConfig.Height_Backdown_Inches__c = 2;
		prodConfig.Width_Backdown_Inches__c = 2;
		update prodConfig;

		// Set the width below the cap and the height above
		OrderItem soldOrderItem = [SELECT Id, PricebookEntryId FROM OrderItem WHERE OrderId =: soldOrder.Id];
		soldOrderItem.Width_Inches__c = 90;
		soldOrderItem.Width_Fraction__c = '15/16';
		soldOrderItem.Height_Inches__c = 90;
		soldOrderItem.Height_Fraction__c = '15/16';
		soldOrderItem.Tempered_S1__c = false;
		update soldOrderItem;
		// check the makeability
		String returnMessage = RMS_prodConfigManager2.checkMakeabilityForOrderById(soldOrder.Id);

		// TODO: Asserts
	}

	/*******************************************************
					getOrderStatusTest
	*******************************************************/
	static testmethod void getOrderStatusTest(){

		String status = RMS_prodConfigManager2.getOrderStatus('nothing');
		System.AssertEquals('drf', status);
	}

	static testmethod void updateTaxesTest(){
		// Turn off the financial trigger to avoid SOQL limits in test class
		RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
		insert turnOffFinancialTrigger;

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		Purchase_Order__c purchaseOrder = new Purchase_Order__c(Order__c = soldOrder.id);
		insert purchaseOrder;
		test.starttest();
		System.assertEquals(RMS_prodConfigManager2.updateTaxes(purchaseOrder.Id),null);
		System.assertEquals(RMS_prodConfigManager2.updateTaxes(null),RMS_errorMessages.PO_TAX_ISSUE);
		test.stoptest();
	}
	

	
}
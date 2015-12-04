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
private class RMS_prodConfigExtensionTest {

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
	
		Product_Configuration__c prodConfig= new Product_Configuration__c(
			Name='Product Config'
		);
		
		insert prodConfig;

		Pricing_Configuration__c pricingConfig= new Pricing_Configuration__c(
			Name='Pricing Config'
		);
		
		insert pricingConfig;

		
//		Pricebook2 pricebook1 =  utility.createPricebook2Name('Standard Price Book');
//		insert pricebook1;

		Product2 product1 = new Product2(
			Name='Master Product',
			Vendor__c = account1.id,
			RecordTypeId = UtilityMethods.RecordTypeFor('Product2', 'Master_Product'),
			Product_Configuration__c = prodConfig.Id
		);
		
		insert product1;

		Product2 product2 = new Product2(
			Name='Child Product',
			Vendor__c = account1.id,
			UI_Minimum__c = 0,
			UI_Maximum__c = 40,
			
			Master_Product__c = product1.Id,
			RecordTypeId = UtilityMethods.RecordTypeFor('Product2', 'Child_Product')
		);
		
		insert product2;

		Opportunity opp1 = utility.createOpportunity(account1.id, 'Closed - Won');
		insert opp1;
		
		PricebookEntry pricebookEntry1 = utility.createPricebookEntry(Test.getStandardPricebookId(), product2.id);		
		pricebookEntry1.Pricing_Configuration__c = pricingConfig.Id;
		insert pricebookEntry1;
		
		Order order1 = new Order(	Name='Sold Order 1', 
									AccountId = dwelling.id, 
									EffectiveDate= Date.Today(), 
									Store_Location2__c = store.Id,
									Opportunity = opp1, 									
									Status ='Draft', 
									Pricebook2Id = Test.getStandardPricebookId()
								);
		insert order1;
		
		OrderItem orderItem1 = new OrderItem(OrderId = Order1.id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100 );
		insert orderItem1;		
		System.Debug('***************Test.getStandardPricebookId()=' +Test.getStandardPricebookId());
//		System.Debug('***************pricebook1=' +pricebook1.Id);
	}
	/*******************************************************
					ConstructorTest
	*******************************************************/
	static testmethod void ConstructorTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		OrderItem oi = new OrderItem();

		// Set up controller without any ids 
		PageReference pageRef = Page.RMS_prodConfigEdit;
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController stdController = new ApexPages.StandardController(oi);
		RMS_prodConfigExtension customController  = new RMS_prodConfigExtension(stdController);
				
	
		OrderItem oi2 = [SELECT Id from OrderItem where Order.Id =: soldOrder.Id];

		// Set up controller with order line id only
		PageReference pageRef2 = Page.RMS_prodConfigEdit;
		Test.setCurrentPage(pageRef2);
		ApexPages.StandardController stdController2 = new ApexPages.StandardController(oi2);
		RMS_prodConfigExtension customController2  = new RMS_prodConfigExtension(stdController2);

		// Set up controller with pricebook and order ids
		PageReference pageRef3 = Page.RMS_prodConfigEdit;
		Test.setCurrentPage(pageRef3);
		ApexPages.currentPage().getParameters().put('oid',soldOrder.id);
		ApexPages.currentPage().getParameters().put('id',priceBookId);
		ApexPages.StandardController stdController3 = new ApexPages.StandardController(oi2);
		RMS_prodConfigExtension customController3  = new RMS_prodConfigExtension(stdController3);

	}

	/*******************************************************
					Product Property Tests
	*******************************************************/
	static testmethod void ProductPropertyTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
	
		OrderItem oi = [SELECT Id from OrderItem where Order.Id =: soldOrder.Id];

		// Set up controller with order line id only
		PageReference pageRef = Page.RMS_prodConfigEdit;
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController stdController = new ApexPages.StandardController(oi);
		RMS_prodConfigExtension ext = new RMS_prodConfigExtension(stdController);
		
		// Verify the master prod id
		String masterProdId = ext.masterProductId;
		System.Assert(masterProdId != null);

		// Verify the master prod
		Product2 masterProd = ext.masterProduct;
		System.AssertEquals('Master Product', masterProd.Name);

		// Verify the master prod config
		Product_Configuration__c masterProdConfig = ext.masterProductConfig;
		System.AssertEquals(masterProd.Product_Configuration__c, masterProdConfig.Id);

		// Verify the prod config wrapper
		RMS_prodConfigManager.productConfigWrapper prodConfig = ext.prodConfig;
		System.Assert(prodConfig != null);

		// Verify the child prod
		Product2 childProd = ext.childProduct;
		System.AssertEquals('Child Product', childProd.Name);

		// Verify the master prod item options
		List<SelectOption> masterProductItems = ext.masterProductItems;		
		System.Assert(!masterProductItems.isEmpty());
	}

	/*******************************************************
					Product Property Tests
	*******************************************************/
	static testmethod void PicklistOptionTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
	
		OrderItem oi = [SELECT Id,PricebookEntryId from OrderItem where Order.Id =: soldOrder.Id];
		Product_Configuration__c prodConfig = [SELECT Id from Product_Configuration__c where Name = 'Product Config'];
		prodConfig.Measurement_Fractions__c = '1/2;3/4';
		prodConfig.Exterior_Color__c = 'White; Red';
		prodConfig.Interior_Color__c = 'White; Red';
		prodConfig.Glazing__c = 'Glaze1; Glaze2';
		prodConfig.Glass_Pattern__c = 'GP1; GP2';
		prodConfig.Grille_Style__c = 'GS1; GS2';
		prodConfig.Grille_Patterns__c = 'GP1; GP2';
		prodConfig.Colonial_Grille_Lites_Wide__c = '1; 2';
		prodConfig.Colonial_Grille_Lites_High__c = '1; 2';
		prodConfig.Exterior_Trim__c = '1; 2';
		prodConfig.Frame_Type__c = 'FT1; FT2';
		prodConfig.Checkrail_Style__c = 'CR1; CR2';
		prodConfig.Interior_Trim__c = 'TR1; TR2';
		prodConfig.Handing__c = 'HO1; HO2';
		prodConfig.Hardware_Finish_Color__c = 'HF1; HF2';
		prodConfig.Hardware_Style__c = 'HS1; HS2';
		prodConfig.Hardware_Option__c = 'HO1; HO2';
		prodConfig.Lifts_Pulls__c = '1; 2';
		prodConfig.Locks_Sash__c = '1; 2';
		prodConfig.Screen_Type__c = 'ST1; ST2';
		prodConfig.Screen_Vaneer_Type__c = 'SV1; SV2';
		prodConfig.Sill_Angle__c = '1; 2';
		prodConfig.Mull_Sequence_Mullion__c = 'a; b';
		prodConfig.Sash_Operation__c = 'SO1; SO2';
		prodConfig.EJ_Thickness__c = 'EJ1; EJ2';
		prodConfig.EJ_Wall_Depth__c = 'DP1; DP2';
		prodConfig.EJ_Species__c = 'EJS1; EJS2';
		prodConfig.EJ_Color__c = 'White; Red';
		prodConfig.Casing_Profile__c = 'P1; P2';
		prodConfig.Casing_Species__c = 'S1; S2';
		prodConfig.Casing_Location__c = 'L1; L2';
		prodConfig.Brickmould_Location__c = 'B1; B2';
		prodConfig.Drip_Cap_Pieces__c = 'D1; D2';
		prodConfig.Screen_Color__c = 'Red; White';
		prodConfig.Exterior_Grille_Color__c = 'Red; White';
		prodConfig.Interior_Grille_Color__c = 'Red; White';
		prodConfig.Storm_Window_Color__c = 'Red; White';
		prodConfig.Exterior_Trim_Color__c = 'Red; White';
		prodConfig.Jamb_Liner_Color__c = 'Red; White';
		prodConfig.Interior_Sash_Color__c = 'Red; White';
		prodConfig.Astragal__c = 'Red; White';
		prodConfig.Storm_Window__c = 'SW1; SW2';
		prodConfig.Storm_Window_Style__c = 'SWS1; SWS2';
		prodConfig.Install_Track_Location__c = 'L1; L2';
		
		update prodConfig;

		// Set up controller with order line id only
		PageReference pageRef = Page.RMS_prodConfigEdit;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('oid',soldOrder.id);
		ApexPages.currentPage().getParameters().put('id',priceBookId);
		ApexPages.StandardController stdController = new ApexPages.StandardController(oi);
		RMS_prodConfigExtension ext = new RMS_prodConfigExtension(stdController);
		ext.enterProduct();

		
		// Verify the master product picklist items
		List<SelectOption> masterProdItems = ext.masterProductItems;
		System.Assert(masterProdItems.size() > 0);

		// Verify the measurement fraction picklist items
		List<SelectOption> measurementFracItems = ext.measurementFractionItems;
		System.AssertEquals(3, measurementFracItems.size());

		// Verify the exterior color picklist items
		List<SelectOption> exteriorColItems = ext.exteriorColorItems;
		System.AssertEquals(3, exteriorColItems.size());

		// Verify the interior color picklist items
		List<SelectOption> interiorColItems = ext.interiorColorItems;
		System.AssertEquals(3, interiorColItems.size());

		// Verify the glazing picklist items
		List<SelectOption> glazItems = ext.glazingItems;
		System.AssertEquals(3, glazItems.size());

		// Verify the glass pattern picklist items
		List<SelectOption> glassPattItems = ext.glassPatternItems;
		System.AssertEquals(3, glassPattItems.size());

		// Verify the grille style picklist items
		List<SelectOption> grilleStyItems = ext.grilleStyleItems;
		System.AssertEquals(3, grilleStyItems.size());

		// Verify the grille pattern picklist items
		List<SelectOption> grillePattItems = ext.grillePatternItems;
		System.AssertEquals(3, grillePattItems.size());

		// Verify the grille lites wide picklist items
		List<SelectOption> colonialGriLitesWideItems = ext.colonialGrilleLitesWideItems;
		System.AssertEquals(3, colonialGriLitesWideItems.size());

		// Verify the grille lites high picklist items
		List<SelectOption> colonialGriLitesHighItems = ext.colonialGrilleLitesHighItems;
		System.AssertEquals(3, colonialGriLitesHighItems.size());

		// Verify the exterior trim picklist items
		List<SelectOption> exteriorTrmItems = ext.exteriorTrimItems;
		System.AssertEquals(3, exteriorTrmItems.size());

		// Verify the frame type picklist items
		List<SelectOption> frameTypItems = ext.frameTypeItems;
		System.AssertEquals(3, frameTypItems.size());

		// Verify the checkrail picklist items
		List<SelectOption> checkrailStyItems = ext.checkrailStyleItems;
		System.AssertEquals(3, checkrailStyItems.size());

		// Verify the interior trim picklist items
		List<SelectOption> interiorTrmItems = ext.interiorTrimItems;
		System.AssertEquals(3, interiorTrmItems.size());

		// Verify the handing option picklist items
		List<SelectOption> handingOptItems = ext.handingOptionItems;
		System.AssertEquals(3, handingOptItems.size());

		// Verify the hardwareFinishColorItems
		List<SelectOption> hardwareFinishColorItems = ext.hardwareFinishColorItems;
		System.AssertEquals(3, hardwareFinishColorItems.size());

		// Verify the hardware style picklist items
		List<SelectOption> hardwareStyItems = ext.hardwareStyleItems;
		System.AssertEquals(3, hardwareStyItems.size());

		// Verify the hardware option picklist items
		List<SelectOption> hardwareOptItems = ext.hardwareOptionItems;
		System.AssertEquals(3, hardwareOptItems.size());

		// Verify the liftsPullsItems
		List<SelectOption> liftsPullsItems = ext.liftsPullsItems;
		System.AssertEquals(3, liftsPullsItems.size());

		// Verify the locksSashItems
		List<SelectOption> locksSashItems = ext.locksSashItems;
		System.AssertEquals(3, locksSashItems.size());

		// Verify the screenTypeItems
		List<SelectOption> screenTypeItems = ext.screenTypeItems;
		System.AssertEquals(3, screenTypeItems.size());

		// Verify the screenVaneerTypeItems
		List<SelectOption> screenVaneerTypeItems = ext.screenVaneerTypeItems;
		System.AssertEquals(3, screenVaneerTypeItems.size());

		// Verify the sillAngleItems
		List<SelectOption> sillAngleItems = ext.sillAngleItems;
		System.AssertEquals(3, sillAngleItems.size());

		// Verify the mullSequenceMullionItems
		List<SelectOption> mullSequenceMullionItems = ext.mullSequenceMullionItems;
		System.AssertEquals(3, mullSequenceMullionItems.size());

		// Verify the sashOperationItems
		List<SelectOption> sashOperationItems = ext.sashOperationItems;
		System.AssertEquals(3, sashOperationItems.size());

		// Verify the EJThicknessItems
		List<SelectOption> EJThicknessItems = ext.EJThicknessItems;
		System.AssertEquals(3, EJThicknessItems.size());

		// Verify the EJWallDepthItems
		List<SelectOption> EJWallDepthItems = ext.EJWallDepthItems;
		System.AssertEquals(3, EJWallDepthItems.size());

		// Verify the EJSpeciesItems
		List<SelectOption> EJSpeciesItems = ext.EJSpeciesItems;
		System.AssertEquals(3, EJSpeciesItems.size());

		// Verify the EJColorItems
		List<SelectOption> EJColorItems = ext.EJColorItems;
		System.AssertEquals(3, EJColorItems.size());

		// Verify the casingProfileItems
		List<SelectOption> casingProfileItems = ext.casingProfileItems;
		System.AssertEquals(3, casingProfileItems.size());

		// Verify the casingSpeciesItems
		List<SelectOption> casingSpeciesItems = ext.casingSpeciesItems;
		System.AssertEquals(3, casingSpeciesItems.size());

		// Verify the casingLocationItems
		List<SelectOption> casingLocationItems = ext.casingLocationItems;
		System.AssertEquals(3, casingLocationItems.size());

		// Verify the brickmouldLocationItems
		List<SelectOption> brickmouldLocationItems = ext.brickmouldLocationItems;
		System.AssertEquals(3, brickmouldLocationItems.size());

		// Verify the dripCapPiecesItems
		List<SelectOption> dripCapPiecesItems = ext.dripCapPiecesItems;
		System.AssertEquals(3, dripCapPiecesItems.size());

		// Verify the screenColorItems
		List<SelectOption> screenColorItems = ext.screenColorItems;
		System.AssertEquals(3, screenColorItems.size());

		// Verify the exteriorGrilleColorItems
		List<SelectOption> exteriorGrilleColorItems = ext.exteriorGrilleColorItems;
		System.AssertEquals(3, exteriorGrilleColorItems.size());

		// Verify the interiorGrilleColorItems
		List<SelectOption> interiorGrilleColorItems = ext.interiorGrilleColorItems;
		System.AssertEquals(3, interiorGrilleColorItems.size());

		// Verify the StormWindowColorItems
		List<SelectOption> StormWindowColorItems = ext.StormWindowColorItems;
		System.AssertEquals(3, StormWindowColorItems.size());

		// Verify the ExteriorTrimColorItems
		List<SelectOption> ExteriorTrimColorItems = ext.ExteriorTrimColorItems;
		System.AssertEquals(3, ExteriorTrimColorItems.size());

		// Verify the JambLinerColorItems
		List<SelectOption> JambLinerColorItems = ext.JambLinerColorItems;
		System.AssertEquals(3, JambLinerColorItems.size());

		// Verify the interiorSashColorItems
		List<SelectOption> interiorSashColorItems = ext.interiorSashColorItems;
		System.AssertEquals(3, interiorSashColorItems.size());

		// Verify the astragalColorItems
		List<SelectOption> astragalColorItems = ext.astragalColorItems;
		System.AssertEquals(3, astragalColorItems.size());

		// Verify the stormWindowItems
		List<SelectOption> stormWindowItems = ext.stormWindowItems;
		System.AssertEquals(3, stormWindowItems.size());

		// Verify the stormWindowStyleItems
		List<SelectOption> stormWindowStyleItems = ext.stormWindowStyleItems;
		System.AssertEquals(3, stormWindowStyleItems.size());

		// Verify the installTrackLocationItems
		List<SelectOption> installTrackLocationItems = ext.installTrackLocationItems;
		System.AssertEquals(3, installTrackLocationItems.size());


	}

	/*******************************************************
					Enter Product Test
	*******************************************************/
	static testmethod void EnterProductTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
	
		OrderItem oi = [SELECT Id, PricebookEntryId from OrderItem where Order.Id =: soldOrder.Id];

		// Set up controller with order line id only
		PageReference pageRef = Page.RMS_prodConfigEdit;
		Test.setCurrentPage(pageRef);
		ApexPages.StandardController stdController = new ApexPages.StandardController(oi);
		RMS_prodConfigExtension ext = new RMS_prodConfigExtension(stdController);
		
		pageReference newPage = ext.enterProduct();
		System.AssertEquals(true, ext.productSelected);
		
	}

	/*******************************************************
					Save Product Test
	*******************************************************/
	static testmethod void SaveProductTest(){
		createTestRecords();

		Order soldOrder = [SELECT Id FROM Order WHERE Name = 'Sold Order 1'];
		Id priceBookId = Test.getStandardPricebookId();
		PricebookEntry pBookEntry = [SELECT Id FROM PricebookEntry WHERE Pricing_Configuration__c != null limit 1];
		Product2 masterProd = [SELECT Id FROM Product2 WHERE Name = 'Master Product' limit 1];
	
		OrderItem oi = new OrderItem(OrderId = soldOrder.Id, Width_Inches__c = 19, Height_Inches__c = 19);
		
		// Set up controller with order line id, order, and pricebook only for a new product
		PageReference pageRef = Page.RMS_prodConfigEdit;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('oid',soldOrder.id);
		ApexPages.currentPage().getParameters().put('id',priceBookId);
		ApexPages.StandardController stdController = new ApexPages.StandardController(oi);
		RMS_prodConfigExtension ext = new RMS_prodConfigExtension(stdController);
		ext.masterProductId = masterProd.Id;
		ext.priceBookId = priceBookId;	
		
		pageReference newPage = ext.enterProduct();
		pageReference savePage = ext.saveProduct();
		System.Assert(savePage != null);

		OrderItem oi2 = [SELECT Id, PricebookEntryId, Width_Inches__c, Height_Inches__c from OrderItem where Order.Id =: soldOrder.Id limit 1];
		oi2.Width_Inches__c = 19;
		oi2.Height_Inches__c = 19;
		update oi2;

		// Set up controller with order line id only for existing products
		PageReference pageRef2 = Page.RMS_prodConfigEdit;
		Test.setCurrentPage(pageRef2);
		ApexPages.StandardController stdController2 = new ApexPages.StandardController(oi2);
		RMS_prodConfigExtension ext2 = new RMS_prodConfigExtension(stdController2);
		pageReference newPage2 = ext2.enterProduct();
		pageReference savePage2 = ext2.saveProduct();
		System.Assert(savePage2 != null);

		
	}

}
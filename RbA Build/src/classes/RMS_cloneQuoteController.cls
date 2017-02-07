public with sharing class RMS_cloneQuoteController {
	public Quote newQuote{get;set;}
	public Quote clonedQuote{get;set;}
	public list<QuoteLineItem> newQuoteLineItems{get;set;}
	public list<QuoteLineItem> clonedQuoteLineItems{get;set;}
	public String clonedQuoteId{get;set;}
	public list<Opportunity> opportunities{get;set;}
	public String quoteStatus{get;set;}

	public RMS_cloneQuoteController(ApexPages.StandardController controller) {
		if (clonedQuoteId == null){
			clonedQuoteId = ApexPages.currentpage().getparameters().get('id');
		}
		
		clonedQuote = [Select AccountId, AdditionalAddress, AdditionalCity, AdditionalCountry,
		AdditionalCountryCode, AdditionalGeocodeAccuracy, AdditionalLatitude, AdditionalLongitude,
		AdditionalName, AdditionalPostalCode, AdditionalState, AdditionalStateCode, AdditionalStreet,
		Amount_Financed__c, BillingAddress, BillingCity, BillingCountry, BillingCountryCode,
		BillingGeocodeAccuracy, BillingLatitude, BillingLongitude, BillingName, BillingPostalCode,
		BillingState, BillingStateCode, BillingStreet, Cloned_Quote_Id__c, ContactId, ContractId,
		Date__c, Description, Discount, Discount_Amount__c, Discount__c, Email, ExpirationDate,
		Fax, GrandTotal, Id, IsDeleted, isSold__c, IsSyncing, LineItemCount, Name, OpportunityId,
		Phone, Pivotal_Id__c, Pricebook2Id, Primary__c, QuoteToAddress, QuoteToCity, QuoteToCountry,
		QuoteToCountryCode, QuoteToGeocodeAccuracy, QuoteToLatitude, QuoteToLongitude, QuoteToName,
		QuoteToPostalCode, QuoteToState, QuoteToStateCode, QuoteToStreet, RecordTypeId, rSuite_Id__c,
		ShippingAddress, ShippingCity, ShippingCountry, ShippingCountryCode, ShippingGeocodeAccuracy,
		ShippingHandling, ShippingLatitude, ShippingLongitude, ShippingName, ShippingPostalCode,
		ShippingState, ShippingStateCode, ShippingStreet, Status, Subtotal, Sub_Total__c,
		Tax, TotalPrice, Total__c 
		FROM Quote 
		WHERE id=: clonedQuoteId];

		if (newQuote == null){
			newQuote = new Quote();
		}

		opportunities = [select id, StageName 
			FROM Opportunity 
			WHERE AccountId =: clonedQuote.AccountId
			AND IsClosed = FALSE ];

		if (clonedQuote.Status == 'New'){
			quoteStatus = 'A Quote in New Status Can Not be Cloned';
		}else if(clonedQuote.Status =='Draft'){
			quoteStatus = 'A Quote in Draft Status Can Not be Cloned';
		}
		
		newQuote.Id = null;
		newQuote.Date__c = System.today();
		newQuote.Cloned_Quote_Id__c = clonedQuoteId;
		newQuote.Status = 'Draft';
		newQuote.isSold__c = False;
		newQuote.Pricebook2Id = clonedQuote.Pricebook2Id;
		
		newQuote.AdditionalCity = clonedQuote.AdditionalCity;
		newQuote.AdditionalCountry = clonedQuote.AdditionalCountry;
		newQuote.AdditionalCountryCode = clonedQuote.AdditionalCountryCode;
		newQuote.AdditionalGeocodeAccuracy = clonedQuote.AdditionalGeocodeAccuracy;
		newQuote.AdditionalLatitude = clonedQuote.AdditionalLatitude;
		newQuote.AdditionalLongitude = clonedQuote.AdditionalLongitude;
		newQuote.AdditionalName = clonedQuote.AdditionalName;
		newQuote.AdditionalPostalCode = clonedQuote.AdditionalPostalCode;
		newQuote.AdditionalState = clonedQuote.AdditionalState;
		newQuote.AdditionalStateCode = clonedQuote.AdditionalStateCode;
		newQuote.AdditionalStreet = clonedQuote.AdditionalStreet;
		newQuote.BillingCity = clonedQuote.BillingCity;
		newQuote.BillingCountry = clonedQuote.BillingCountry;
		newQuote.BillingCountryCode = clonedQuote.BillingCountryCode;
		newQuote.BillingGeocodeAccuracy = clonedQuote.BillingGeocodeAccuracy;
		newQuote.BillingLatitude = clonedQuote.BillingLatitude;
		newQuote.BillingLongitude = clonedQuote.BillingLongitude;
		newQuote.BillingName = clonedQuote.BillingName;
		newQuote.BillingPostalCode = clonedQuote.BillingPostalCode;
		newQuote.BillingState = clonedQuote.BillingState;
		newQuote.BillingStateCode = clonedQuote.BillingStateCode;
		newQuote.BillingStreet = clonedQuote.BillingStreet;
		newQuote.ContactId = clonedQuote.ContactId;
		newQuote.ContractId = clonedQuote.ContractId;
		newQuote.Description = clonedQuote.Description;
		newQuote.Email = clonedQuote.Email;
		newQuote.ExpirationDate = clonedQuote.ExpirationDate;
		newQuote.Fax = clonedQuote.Fax;
		newQuote.Name = clonedQuote.Name;
		newQuote.Phone = clonedQuote.Phone;
		newQuote.Primary__c = clonedQuote.Primary__c;
		newQuote.QuoteToCity = clonedQuote.QuoteToCity;
		newQuote.QuoteToCountry = clonedQuote.QuoteToCountry;
		newQuote.QuoteToCountryCode = clonedQuote.QuoteToCountryCode;
		newQuote.QuoteToGeocodeAccuracy = clonedQuote.QuoteToGeocodeAccuracy;
		newQuote.QuoteToLatitude = clonedQuote.QuoteToLatitude;
		newQuote.QuoteToLongitude = clonedQuote.QuoteToLongitude;
		newQuote.QuoteToName = clonedQuote.QuoteToName;
		newQuote.QuoteToPostalCode = clonedQuote.QuoteToPostalCode;
		newQuote.QuoteToState = clonedQuote.QuoteToState;
		newQuote.QuoteToStateCode = clonedQuote.QuoteToStateCode;
		newQuote.QuoteToStreet = clonedQuote.QuoteToStreet;
		newQuote.RecordTypeId = clonedQuote.RecordTypeId;
		newQuote.ShippingCity = clonedQuote.ShippingCity;
		newQuote.ShippingCountry = clonedQuote.ShippingCountry;
		newQuote.ShippingCountryCode = clonedQuote.ShippingCountryCode;
		newQuote.ShippingGeocodeAccuracy = clonedQuote.ShippingGeocodeAccuracy;
		newQuote.ShippingHandling = clonedQuote.ShippingHandling;
		newQuote.ShippingLatitude = clonedQuote.ShippingLatitude;
		newQuote.ShippingLongitude = clonedQuote.ShippingLongitude;
		newQuote.ShippingName = clonedQuote.ShippingName;
		newQuote.ShippingPostalCode = clonedQuote.ShippingPostalCode;
		newQuote.ShippingState = clonedQuote.ShippingState;
		newQuote.ShippingStateCode = clonedQuote.ShippingStateCode;
		newQuote.ShippingStreet = clonedQuote.ShippingStreet;
		newQuote.Tax = clonedQuote.Tax;

	}

	public PageReference save(){
		//first save the quote
		//need Quote Name, Opportunity Name
		if (opportunities.size() == 1){
			newQuote.OpportunityId = opportunities[0].Id;
		} else{
			//throw an error there should only be one Opportunity
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: There is no Distinct Opporyunity to Attach thie Quote');
            ApexPages.addMessage(myMsg);
            return null;
		}
		insert newQuote;

		//next update the Quote Line items with the QuoteID
		clonedQuoteLineItems = [SELECT Aluminum_Sill_Support__c,Applied_Grilles__c,
			Apply_to_All_Sashes_Glass__c, Apply_to_All_Sashes_Grilles__c, Astragal__c,
			Auxillary_Foot_Lock_Color_Match__c, Breather_Tubes__c,
			Casing_Location__c, Casing_Profile__c, Casing_Species__c,
			Checkrail_Style__c, Child_Product_Pricebook_Entry_Id__c,
			Color_Match_Hinges__c, Corrosion_Resistant_Hardware__c,
			Corrosion_Resistant_Hinges__c, Corrosion_Resistant_Lock__c,
			Cross_Reference__c,Custom_Grille_Details_S1__c,
			Custom_Grille_Details_S2__c, Custom_Grille_Details_S3__c,
			Custom_Grille_Details_S4__c,
			Custom_Grille_Price_S1__c, Custom_Grille_Price_S2__c,
			Custom_Grille_Price_S3__c, Custom_Grille_Price_S4__c,
			Description, Discount, Door_Sill_Color__c, Drip_Cap_Pieces__c,
			EJ_Color__c, EJ_Frame__c, EJ_Kerf__c,EJ_Species__c,
			EJ_Thickness__c, EJ_Wall_Depth__c, Entered_Price__c, Exterior_Color__c,
			Exterior_Door_Jamb__c, Exterior_Frame_Depth__c,
			Exterior_Grille_Color__c, Exterior_Keyed_Lock__c, Exterior_Trim_Color__c,
			Exterior_Trim__c, Fibrex_L_Trim__c, Finger_Lifts__c,
			Finish_Matched_Panel_Stop__c, Floor__c, Frame_Type__c, Glass_Pattern_S1__c,
			Glass_Pattern_S2__c, Glass_Pattern_S3__c, Glass_Pattern_S4__c,
			Glazing_S1__c, Glazing_S2__c, Glazing_S3__c, Glazing_S4__c,
			Gliding_Screen__c, Grille_Alignment__c,Grille_Pattern_S1__c,
			Grille_Pattern_S2__c, Grille_Pattern_S4__c, Grille_Style__c,
			Handing__c, Handle_Type__c, Hardware_Color__c, Hardware_Finish_Color__c,
			Hardware_Finish__c, Hardware_Option__c, Hardware_Style__c,
			Hubs__c, Insect_Screen_Style__c, Install_Holes_Location__c,
			Interior_Color__c, Interior_Extension_Jamb_Kit__c,
			Interior_Grille_Color__c, Interior_Pre_Finish__c,
			Interior_Sash_Color__c, Interior_Trim__c, IsDeleted, isInactive__c,
			Jamb_Liner_Color__c,Left_Leg_Fraction__c, Left_Leg_Inches__c, Lifts_Pulls__c,
			Linear_Inches__c,LineNumber, ListPrice, Lites_High_S4__c,
			Lites_High_Wide_Total_S1__c, Lites_High_Wide_Total_S2__c,
			Lites_High_Wide_Total_S4__c, Lites_Wide_S1__c,Lites_Wide_S2__c,
			Lites_Wide_S4__c, Locks_Sash__c, Mfg_Mull_Sequence__c,
			Mull_Sequence_Mullion__c,Number_of_Panels__c,Parent_Quote_Line_Item__c,
			Parent_Unit_rSuite_Id__c,Part_of_Bay__c,
			Part_of_Bow__c, Permanently_Applied_Interior_Wood_Grille__c,
			Perm_Applied_Int_Wood_Grille__c,Pivotal_Id__c, PricebookEntryId,
			Pricing_Cross_Reference__c, Product2Id, Product_Category__c,
			Product_Class__c,Product_Family__c, Product_Sub_Category__c,
			Quantity,QuoteId,Right_Leg_Fraction__c, Right_Leg_Inches__c,
			Room__c,rSuite_Product_Type__c, Sales_Height_Fraction__c,
			Sales_Height_Inches__c,Sales_Width_Fraction__c, Sales_Width_Inches__c,
			Sash_Operation__c, Sash_Ratio__c, Screen_Color__c,
			Screen_Size__c, Screen_Type__c, Screen_Vaneer_Type__c,
			Screen_Veneer_Type__c,ServiceDate,SortOrder,Spokes__c,Subtotal,
			SW_Grille_Alignment__c,SystemModstamp,Tax_Credit_Qualified__c,
			Tempered_S1__c,Tempered_S2__c,Tempered_S3__c,Tempered_S4__c,
			TotalPrice,UnitPrice,Unit_Id__c,Upgrade_Hinges_To_Metal_Finish__c,
			Wide_Bar__c,Window_Opening_Control_Device__c
			FROM QuoteLineItem 
			WHERE QuoteId =: clonedQuoteId];

		//We're storing the initial quote values in case we ever need to refer to them.
		//The new quote line items should be the same as the existing ones with the exception of the fields we are updating here	
		list<QuoteLineItem> newQuoteLineItems = new list<QuoteLineItem>();
		
		for (QuoteLineItem qli:clonedQuoteLineItems){

			QuoteLineItem qli2 = new QuoteLineItem();
			
			qli2.QuoteId = newQuote.Id;
			qli2.Pivotal_Id__c = '';
			qli2.Parent_Unit_rSuite_Id__c = '';
			
			qli2.Aluminum_Sill_Support__c = qli.Aluminum_Sill_Support__c;
			qli2.Applied_Grilles__c = qli.Applied_Grilles__c;
			qli2.Apply_to_All_Sashes_Glass__c = qli.Apply_to_All_Sashes_Glass__c; 
			qli2.Apply_to_All_Sashes_Grilles__c = qli.Apply_to_All_Sashes_Grilles__c; 
			qli2.Astragal__c = qli.Astragal__c;
			qli2.Auxillary_Foot_Lock_Color_Match__c = qli.Auxillary_Foot_Lock_Color_Match__c; 
			qli2.Breather_Tubes__c = qli.Breather_Tubes__c;
			qli2.Casing_Location__c = qli.Casing_Location__c; 
			qli2.Casing_Profile__c = qli.Casing_Profile__c; 
			qli2.Casing_Species__c = qli.Casing_Species__c;
			qli2.Checkrail_Style__c = qli.Checkrail_Style__c; 
			qli2.Child_Product_Pricebook_Entry_Id__c = qli.Child_Product_Pricebook_Entry_Id__c;
			qli2.Color_Match_Hinges__c = qli.Color_Match_Hinges__c; 
			qli2.Corrosion_Resistant_Hardware__c = qli.Corrosion_Resistant_Hardware__c;
			qli2.Corrosion_Resistant_Hinges__c = qli.Corrosion_Resistant_Hinges__c; 
			qli2.Corrosion_Resistant_Lock__c = qli.Corrosion_Resistant_Lock__c;
			qli2.Cross_Reference__c = qli.Cross_Reference__c;
			qli2.Custom_Grille_Details_S1__c = qli.Custom_Grille_Details_S1__c;
			qli2.Custom_Grille_Details_S2__c = qli.Custom_Grille_Details_S2__c; 
			qli2.Custom_Grille_Details_S3__c = qli.Custom_Grille_Details_S3__c; 
			qli2.Custom_Grille_Details_S4__c = qli.Custom_Grille_Details_S4__c;
			qli2.Custom_Grille_Price_S1__c = qli.Custom_Grille_Price_S1__c; 
			qli2.Custom_Grille_Price_S2__c = qli.Custom_Grille_Price_S2__c;
			qli2.Custom_Grille_Price_S3__c = qli.Custom_Grille_Price_S3__c; 
			qli2.Custom_Grille_Price_S4__c = qli.Custom_Grille_Price_S4__c;
			qli2.Description = qli.Description; 
			qli2.Door_Sill_Color__c = qli.Door_Sill_Color__c; 
			qli2.Drip_Cap_Pieces__c = qli.Drip_Cap_Pieces__c;
			qli2.EJ_Color__c = qli.EJ_Color__c; 
			qli2.EJ_Frame__c = qli.EJ_Frame__c; 
			qli2.EJ_Kerf__c = qli.EJ_Kerf__c;
			qli2.EJ_Species__c = qli.EJ_Species__c;
			qli2.EJ_Thickness__c = qli.EJ_Thickness__c; 
			qli2.EJ_Wall_Depth__c = qli.EJ_Wall_Depth__c; 
			qli2.Entered_Price__c = qli.Entered_Price__c; 
			qli2.Exterior_Color__c = qli.Exterior_Color__c;
			qli2.Exterior_Door_Jamb__c = qli.Exterior_Door_Jamb__c; 
			qli2.Exterior_Frame_Depth__c = qli.Exterior_Frame_Depth__c;
			qli2.Exterior_Grille_Color__c = qli.Exterior_Grille_Color__c; 
			qli2.Exterior_Keyed_Lock__c = qli.Exterior_Keyed_Lock__c;
			qli2.Exterior_Trim_Color__c = qli.Exterior_Trim_Color__c;
			qli2.Exterior_Trim__c = qli.Exterior_Trim__c; 
			qli2.Fibrex_L_Trim__c = qli.Fibrex_L_Trim__c; 
			qli2.Finger_Lifts__c = qli.Finger_Lifts__c;
			qli2.Finish_Matched_Panel_Stop__c = qli.Finish_Matched_Panel_Stop__c; 
			qli2.Floor__c = qli.Floor__c;
			qli2.Frame_Type__c = qli.Frame_Type__c; 
			qli2.Glass_Pattern_S1__c = qli.Glass_Pattern_S1__c;
			qli2.Glass_Pattern_S2__c = qli.Glass_Pattern_S2__c; 
			qli2.Glass_Pattern_S3__c = qli.Glass_Pattern_S3__c; 
			qli2.Glass_Pattern_S4__c = qli.Glass_Pattern_S4__c;
			qli2.Glazing_S1__c = qli.Glazing_S1__c; 
			qli2.Glazing_S2__c = qli.Glazing_S2__c; 
			qli2.Glazing_S3__c = qli.Glazing_S3__c; 
			qli2.Glazing_S4__c = qli.Glazing_S4__c;
			qli2.Gliding_Screen__c = qli.Gliding_Screen__c; 
			qli2.Grille_Alignment__c = qli.Grille_Alignment__c;
			qli2.Grille_Pattern_S1__c = qli.Grille_Pattern_S1__c;
			qli2.Grille_Pattern_S2__c = qli.Grille_Pattern_S2__c; 
			qli2.Grille_Pattern_S4__c = qli.Grille_Pattern_S4__c; 
			qli2.Grille_Style__c = qli.Grille_Style__c;
			qli2.Handing__c = qli.Handing__c; 
			qli2.Handle_Type__c = qli.Handle_Type__c; 
			qli2.Hardware_Color__c = qli.Hardware_Color__c; 
			qli2.Hardware_Finish_Color__c = qli.Hardware_Finish_Color__c;
			qli2.Hardware_Finish__c = qli.Hardware_Finish__c;
			qli2.Hardware_Option__c = qli.Hardware_Option__c; 
			qli2.Hardware_Style__c = qli.Hardware_Style__c;
			qli2.Hubs__c = qli.Hubs__c; 
			qli2.Insect_Screen_Style__c = qli.Insect_Screen_Style__c; 
			qli2.Install_Holes_Location__c = qli.Install_Holes_Location__c;
			qli2.Interior_Color__c = qli.Interior_Color__c; 
			qli2.Interior_Extension_Jamb_Kit__c = qli.Interior_Extension_Jamb_Kit__c;
			qli2.Interior_Grille_Color__c = qli.Interior_Grille_Color__c; 
			qli2.Interior_Pre_Finish__c = qli.Interior_Pre_Finish__c;
			qli2.Interior_Sash_Color__c = qli.Interior_Sash_Color__c; 
			qli2.Interior_Trim__c = qli.Interior_Trim__c; 
			qli2.isInactive__c = qli.isInactive__c;
			qli2.Jamb_Liner_Color__c = qli.Jamb_Liner_Color__c;
			qli2.Left_Leg_Fraction__c = qli.Left_Leg_Fraction__c; 
			qli2.Left_Leg_Inches__c = qli.Left_Leg_Inches__c; 
			qli2.Lifts_Pulls__c = qli.Lifts_Pulls__c;
			qli2.Linear_Inches__c = qli.Linear_Inches__c;
			qli2.Lites_High_S4__c = qli.Lites_High_S4__c;
			qli2.Lites_Wide_S1__c = qli.Lites_Wide_S1__c;
			qli2.Lites_Wide_S2__c = qli.Lites_Wide_S2__c;
			qli2.Lites_Wide_S4__c = qli.Lites_Wide_S4__c; 
			qli2.Locks_Sash__c = qli.Locks_Sash__c; 
			qli2.Mfg_Mull_Sequence__c = qli.Mfg_Mull_Sequence__c;
			qli2.Mull_Sequence_Mullion__c = qli.Mull_Sequence_Mullion__c;
			qli2.Number_of_Panels__c = qli.Number_of_Panels__c;
			qli2.Parent_Quote_Line_Item__c = qli.Parent_Quote_Line_Item__c;
			qli2.Part_of_Bay__c = qli.Part_of_Bay__c;
			qli2.Part_of_Bow__c = qli.Part_of_Bow__c; 
			qli2.Permanently_Applied_Interior_Wood_Grille__c = qli.Permanently_Applied_Interior_Wood_Grille__c;
			qli2.Perm_Applied_Int_Wood_Grille__c = qli.Perm_Applied_Int_Wood_Grille__c;
			qli2.PricebookEntryId = qli.PricebookEntryId;
			qli2.Pricing_Cross_Reference__c = qli.Pricing_Cross_Reference__c;
			qli2.Product2Id = qli.Product2Id;
			qli2.Quantity = qli.Quantity;
			qli2.Right_Leg_Fraction__c = qli.Right_Leg_Fraction__c; 
			qli2.Right_Leg_Inches__c = qli.Right_Leg_Inches__c;
			qli2.Room__c = qli.Room__c;
			qli2.Sales_Height_Fraction__c = qli.Sales_Height_Fraction__c;
			qli2.Sales_Height_Inches__c = qli.Sales_Height_Inches__c;
			qli2.Sales_Width_Fraction__c = qli.Sales_Width_Fraction__c;
			qli2.Sales_Width_Inches__c = qli.Sales_Width_Inches__c;
			qli2.Sash_Operation__c = qli.Sash_Operation__c; 
			qli2.Sash_Ratio__c = qli.Sash_Ratio__c; 
			qli2.Screen_Color__c = qli.Screen_Color__c;
			qli2.Screen_Size__c = qli.Screen_Size__c; 
			qli2.Screen_Type__c = qli.Screen_Type__c; 
			qli2.Screen_Vaneer_Type__c = qli.Screen_Vaneer_Type__c;
			qli2.Screen_Veneer_Type__c = qli.Screen_Veneer_Type__c;
			qli2.ServiceDate = qli.ServiceDate;
			qli2.Spokes__c = qli.Spokes__c;
			qli2.SW_Grille_Alignment__c = qli.SW_Grille_Alignment__c;
			qli2.Tax_Credit_Qualified__c = qli.Tax_Credit_Qualified__c;
			qli2.Tempered_S1__c = qli.Tempered_S1__c;
			qli2.Tempered_S2__c = qli.Tempered_S2__c;
			qli2.Tempered_S3__c = qli.Tempered_S3__c;
			qli2.Tempered_S4__c = qli.Tempered_S4__c;
			qli2.UnitPrice = qli.UnitPrice;
			qli2.Unit_Id__c = qli.Unit_Id__c;
			qli2.Upgrade_Hinges_To_Metal_Finish__c = qli.Upgrade_Hinges_To_Metal_Finish__c;
			qli2.Wide_Bar__c = qli.Wide_Bar__c;

			newQuoteLineItems.add(qli2);
		}

		if (newQuoteLineItems.size() > 0){
			insert newQuoteLineItems;
		}
		
		PageReference pageRef = new PageReference('/'+ newQuote.id);
		return pageRef;
	}
}
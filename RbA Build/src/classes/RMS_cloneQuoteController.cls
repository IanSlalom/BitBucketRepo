public with sharing class RMS_cloneQuoteController {
	public Quote newQuote{get;set;}
	public Quote clonedQuote{get;set;}
	public list<QuoteLineItem> newQuoteLineItems{get;set;}
	public list<QuoteLineItem> clonedQuoteLineItems{get;set;}
	public String clonedQuoteId{get;set;}
	public list<Opportunity> opportunities{get;set;}

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
			//newQuote = clonedQuote;
		}

		opportunities = [select id 
			FROM Opportunity 
			WHERE AccountId =: clonedQuote.AccountId
			AND IsClosed = FALSE ];

		//if (opportunities.size() == 1){
		//	newQuote.OpportunityId = opportunities[0].Id;
		//} else{
		//	//throw an error there should only be one Opportunity
		//	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: There is no Distinct Opporyunity to Attach thie Quote');
  //          ApexPages.addMessage(myMsg);
  //          return null;
		//}
		
		newQuote.Id = null;
		newQuote.Date__c = System.today();
		newQuote.Cloned_Quote_Id__c = clonedQuoteId;
		newQuote.Status = 'Draft';
		newQuote.isSold__c = False;
		newQuote.Pricebook2Id = clonedQuote.Pricebook2Id;
		//newQuote.AccountId = clonedQuote.AccountId;
		//newQuote.AdditionalAddress = clonedQuote.AdditionalAddress;
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
		//newQuote.Amount_Financed__c = clonedQuote.Amount_Financed__c;
		//newQuote.BillingAddress = clonedQuote.BillingAddress;
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
		//newQuote.Discount = clonedQuote.Discount;
		//newQuote.Discount_Amount__c = clonedQuote.Discount_Amount__c;
		//newQuote.Discount__c = clonedQuote.Discount__c;
		newQuote.Email = clonedQuote.Email;
		newQuote.ExpirationDate = clonedQuote.ExpirationDate;
		newQuote.Fax = clonedQuote.Fax;
		//newQuote.GrandTotal = clonedQuote.GrandTotal;
		//newQuote.IsDeleted = clonedQuote.Pricebook2Id;
		//newQuote.IsSyncing I don't think we want to copy this
		//newQuote.LineItemCount = clonedQuote.LineItemCount;
		newQuote.Name = clonedQuote.Name;
		newQuote.Phone = clonedQuote.Phone;
		newQuote.Primary__c = clonedQuote.Primary__c;
		//newQuote.QuoteToAddress = clonedQuote.QuoteToAddress;
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
		//newQuote.ShippingAddress = clonedQuote.ShippingAddress;
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
		//newQuote.Subtotal = clonedQuote.Subtotal;
		//newQuote.Sub_Total__c = clonedQuote.Sub_Total__c;
		//newQuote.TotalPrice = clonedQuote.TotalPrice;
		//newQuote.Total__c = clonedQuote.Total__c;
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
		clonedQuoteLineItems = [SELECT IsDeleted, isInactive__c, LineNumber, Parent_Quote_Line_Item__c,
			Parent_Unit_rSuite_Id__c, Pivotal_Id__c, PricebookEntryId, Pricing_Cross_Reference__c, UnitPrice,
			Product2Id, Product_Category__c, Product_Class__c, Product_Family__c, Product_Sub_Category__c,
			Quantity, QuoteId, rSuite_Product_Type__c, Child_Product_Pricebook_Entry_Id__c
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
			qli2.Product2Id = qli.Product2Id;
			qli2.Quantity = qli.Quantity;
			qli2.UnitPrice = qli.UnitPrice;
			qli2.Child_Product_Pricebook_Entry_Id__c = qli.Child_Product_Pricebook_Entry_Id__c;
			qli2.PricebookEntryId = qli.PricebookEntryId;

			newQuoteLineItems.add(qli2);
			system.debug('***testing qli2: '+ qli2);
		}

		if (newQuoteLineItems.size() > 0){
			insert newQuoteLineItems;
		}
		PageReference pageRef = new PageReference('/'+ newQuote.id);
		return pageRef;
	}
}
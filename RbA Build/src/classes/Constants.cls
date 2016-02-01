public with sharing class Constants {
	
	public static final String DWELLING_ACCOUNT_RECORD_TYPE_NAME = 'Dwelling';
	public static final String PERMIT_MUNICIPALITY_RECORD_TYPE_NAME = 'Permit';

	// locked Order Fields by Status
	public static final Map<String, List<String>> lockedOrderFieldMap = new Map<String, List<String>>
	{'Order Released'=>new String[]
		{	'AccountId',
			'Name',
			'BillToContactId',
			'BillingStreet', 
			'BillingCity',
			'BillingState',
			'BillingPostalCode',
			'OpportunityId',
			'RecordTypeId',
			'EffectiveDate',
			'QuoteId',
			'ShippingStreet', 
			'ShippingCity',
			'ShippingState',
			'ShippingPostalCode',
			'Store_Location__c'
		}
	};



}
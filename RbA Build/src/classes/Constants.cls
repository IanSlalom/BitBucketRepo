public with sharing class Constants {
	
	// Record Type Developer names
	public static final String DWELLING_ACCOUNT_RECORD_TYPE_NAME = 'Dwelling';
	public static final String PERMIT_MUNICIPALITY_RECORD_TYPE_NAME = 'Permit';
	public static final String MASTER_PRODUCT_RECORD_TYPE_NAME = 'Master_Product';
	public static final String CHILD_PRODUCT_RECORD_TYPE_NAME = 'Child_Product';
	public static final String CONSTRUCTION_MATERIALS_PRODUCT_RECORD_TYPE_NAME = 'Construction_Materials';
	public static final String MISC_JOB_AND_UNIT_CHARGES_PRODUCT_RECORD_TYPE_NAME = 'Misc_Job_and_Unit_Charges';
 

	// locked Order Fields by Status
	public static final Map<String, List<String>> lockedOrderFieldMap = new Map<String, List<String>>
	{UtilityMethods.RecordTypeFor('Order','CORO_Record_Type') + 'Order Released'=>new String[]
		{	'AccountId',
			'Name',
			'BillToContactId',
			'BillingStreet', 
			'BillingCity',
			'BillingState',
			'BillingStateCode',
			'BillingPostalCode',
			'OpportunityId',
			'RecordTypeId',
			'EffectiveDate',
			'QuoteId',
			'ShippingStreet', 
			'ShippingCity',
			'ShippingState',
			'ShippingStateCode',
			'ShippingPostalCode',
			'Store_Location__c'
		},
		UtilityMethods.RecordTypeFor('Order','Change_Order') + 'Job in Progress'=>new String[]
		{	'AccountId',
			'Name',
			'Sold_Order__c',
			'Store_Location__c',
			'OpportunityId',
			'RecordTypeId',
			'EffectiveDate',
			'QuoteId',
			'Change_Order_Total__c'
		},
		UtilityMethods.RecordTypeFor('Order','Change_Order') + 'Job Closed'=>new String[]
		{	'AccountId',
			'Name',
			'Sold_Order__c',
			'Store_Location__c',
			'OpportunityId',
			'RecordTypeId',
			'EffectiveDate',
			'QuoteId',
			'Change_Order_Total__c'
		},
		'TestClass'=>new String[]
		{	'Name'

		}
	};



}
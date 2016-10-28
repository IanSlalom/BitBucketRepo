public with sharing class Constants {
	
	// Record Type Developer names
	public static final String DWELLING_ACCOUNT_RECORD_TYPE_NAME = 'Dwelling';
	public static final String PERMIT_MUNICIPALITY_RECORD_TYPE_NAME = 'Permit';
	public static final String MASTER_PRODUCT_RECORD_TYPE_NAME = 'Master_Product';
	public static final String CHILD_PRODUCT_RECORD_TYPE_NAME = 'Child_Product';
	public static final String CONSTRUCTION_MATERIALS_PRODUCT_RECORD_TYPE_NAME = 'Construction_Materials';
	public static final String MISC_JOB_AND_UNIT_CHARGES_PRODUCT_RECORD_TYPE_NAME = 'Misc_Job_and_Unit_Charges';
 
	// Product Family constants
	public static final String PF_PATIO_DOOR = 'Patio Door';
	public static final String PF_SPECIALTY = 'Specialty';
	public static final String PF_WINDOW = 'Window';

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
		UtilityMethods.RecordTypeFor('Order','Change_Order') + 'In Progress'=>new String[]
		{	'AccountId',
			'Name',
			'Sold_Order__c',
			'Store_Location__c',
			'OpportunityId',
			'RecordTypeId',
			'EffectiveDate',
			'QuoteId',
			'Order_Processed_Date__c'
		},
		UtilityMethods.RecordTypeFor('Order','Change_Order') + 'Job Closed'=>new String[]
		{	'AccountId',
			'Name',
			'Sold_Order__c',
			'Store_Location__c',
			'OpportunityId',
			'RecordTypeId',
			'EffectiveDate',
			'QuoteId'
		},
		UtilityMethods.RecordTypeFor('Order','Change_Order') + 'Cancelled'=>new String[]
		{	'AccountId',
			'Name',
			'Sold_Order__c',
			'Store_Location__c',
			'OpportunityId',
			'RecordTypeId',
			'EffectiveDate',
			'QuoteId'
		},
		'TestClass'=>new String[]
		{	'Name'

		}
	};

	public static final Map<String,Double> fractionConversionMap = new Map<String,Double>{
		'Even' => 0.0d, '1/16' => 0.0625d,'1/8' => 0.125d,'3/16' => 0.1875d, 
		'1/4' => 0.25d, '5/16' => 0.3125d, '3/8' => 0.25d, '7/16' => 0.4375d, 
		'1/2' => 0.25d, '9/16' => 0.5625d, '5/8' => 0.625d, '11/16' => 0.6875d, 
		'3/4' => 0.75d, '13/16' => 0.8125d, '7/8' => 0.825d, '15/16' => 0.8375d
	};


}
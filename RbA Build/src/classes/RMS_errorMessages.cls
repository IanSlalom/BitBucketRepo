public with sharing class RMS_errorMessages {

	/*******************************************************
					Purchase Order Errors
	*******************************************************/
	public static final String SHIP_DATE_REQUIRED = 'Please enter an estimated ship date before changing the status to Received.';
	public static final String UNIT_COST_REQUIRED = 'Please enter a unit cost for all products before changing the status to Received.';
	public static final String DATA_LOADING_CUSTOM_SETTING_REQUIRED = 'Please populate the \'Data Loading Profile ID\' in Custom Settings.';
	public static final String ADD_PRODUCT_FIELDS_REQUIRED = 'Please enter an item name and quantity before adding a new product.';
	public static final String PRICEBOOK_ENTRY_NOT_FOUND = 'A pricebook entry could not be found for this product. Please contact your system admin for help.';
	public static final String ADD_PRODUCT_EXCEPTION = 'The system was unable to add the item to the purchase order. Please contact your system admin for help.';
	public static final String SAVE_PO_EXCEPTION = 'The system was unable to save the purchase order. Please contact your system admin for help.';
	public static final String UPDATE_PO_LINES_EXCEPTION = 'The system was unable to update the purchase order line items. Please contact your system admin for help.';
	public static final String UPDATE_PO_EXCEPTION = 'The system was unable to update the purchase order. Please contact your system admin for help.';
	public static final String USER_STORE_LOCATION_BLANK = 'Your user record is not associated with a store location. Please contact your system admin for help.';
	public static final String STORE_LOCATION_BLANK = 'The order is not associated with a store location. Please add the store location and try again.';
	public static final String INVENTORY_GL_ACCOUNT_NOT_FOUND = 'The inventory GL account number could not be found. Please contact your system admin for help.';
	public static final String INTERCOMPANY_AP_ACCOUNT_NOT_FOUND = 'The intercompany AP account number could not be found. Please contact your system admin for help.';


	/*******************************************************
					Product Configuration Errors
	*******************************************************/
	public static final String PRODUCT_EMPTY = '&bull; Please choose a product and try again.';
	public static final String QUANTITY_EMPTY = '&bull; Please enter a quantity and try again.';
	public static final String WIDTH_HEIGHT_EMPTY = '&bull; Please enter a width and height.';
	public static final String INVALID_HEIGHT_FORMAT = '&bull; Please enter the height as either a whole number or decimal.';
	public static final String INVALID_WIDTH_FORMAT = '&bull; Please enter the width as either a whole number or decimal.';
	public static final String WIDTH_BELOW_MIN = '&bull; The width you entered[enteredValue] is below the minimum[requiredValue] for this product .';
	public static final String HEIGHT_BELOW_MIN = '&bull; The height you entered[enteredValue] is below the minimum[requiredValue] for this product.';
	public static final String WIDTH_ABOVE_MAX = '&bull; The width you entered[enteredValue] is above the maximum[requiredValue] for this product.';
	public static final String HEIGHT_ABOVE_MAX = '&bull; The height you entered[enteredValue] is above the maximum[requiredValue] for this product.';
	public static final String UNITED_INCH_ABOVE_MAX = '&bull; The united inch total for the measurements entered[enteredValue] is above the maximum[requiredValue] for this product.';
	public static final String HEIGHT_TO_WIDTH_CAP = '&bull; The height and width you entered exceeds the height to width cap.';
	public static final String WIDTH_TO_HEIGHT_CAP = '&bull; The width and height you entered exceeds the width to height cap.';
	public static final String PEAK_HEIGHT = '&bull; The left and right leg difference is greater then the width times the product\'s peak height.'; 
	public static final String GLASS_MAX_SQ_FEET = '&bull; The height and width you have entered exceeds the max square feet allowed for this product.';
	public static final String WIDTH_TO_HEIGHT_RATIO_MAX = '&bull; The height and width you have entered[enteredValue] exceeds the width to height ratio max[requiredValue] for this product.';
	public static final String WIDTH_TO_HEIGHT_RATIO_MIN = '&bull; The height and width you have entered[enteredValue] is below the width to height ratio minimum[requiredValue] for this product.';
	public static final String MINIMUM_LEG_HEIGHT_RIGHT = '&bull; The right leg height you entered[enteredValue] is below the minimum[requiredValue] leg height for this product.';
	public static final String MINIMUM_LEG_HEIGHT_LEFT = '&bull; The left leg height you entered[enteredValue] is below the minimum[requiredValue] leg height for this product.';
	public static final String BRICKMOULD_NOT_AVALIABLE_DOUBLE_HUNG_SLOPED = '&bull; The Brickmould exterior trim is not available on Double Hung Insert Frames with Sloped Sills.'; 
 	public static final String SCREEN_WIDTH_MAX = '&bull; The width you entered[enteredValue] is above the maximum[requiredValue] for the type of screen you selected on this product.'; 
 	public static final String SCREEN_HEIGHT_MAX = '&bull; The height you entered[enteredValue] is above the maximum[requiredValue] for the type of screen you selected on this product.'; 
 	
 	public static final String LOCK_MAX_WIDTH = '&bull; You cannot select more than [enteredValue] locks when the width is less than [requiredValue] inches.';
 	public static final String LOCK_MAX_HEIGHT = '&bull; You cannot select more than [enteredValue] locks when the height is less than [requiredValue] inches.';
 	public static final String LOCK_MIN_WIDTH = '&bull; You must select at least [enteredValue] locks when the width is greater than [requiredValue] inches.';
 	public static final String LOCK_MIN_HEIGHT = '&bull; You must select at least [enteredValue] locks when the height is greater than [requiredValue] inches.';
 	public static final String INTERIOR_COLOR_MAX_WIDTH = '&bull; The width cannot be more than [enteredValue] when the Interior Color is set to [requiredValue].';
 	 	
	public static final String PRODUCT_CONFIG_NOT_FOUND = '&bull; A suitable product configuration for this product could not be found based on the information you entered. Please contact your Administrator for help in resolving this issue.';
	public static final String ORDER_NOT_FOUND = '&bull; The order was not found. Please go back and try again.';
	public static final String ORDER_ACTIVATED_NEW = '&bull; Sorry, you cannot add product line items to an activated order.';
	public static final String ORDER_ACTIVATED_EDIT = '&bull; Sorry, you cannot edit product line items on an activated order.';


	/*******************************************************
					Financial Transation Errors
	*******************************************************/
	
	public static final String NO_FINACIAL_TRANSACTION_RECORDS = '&bull;There is no financial transaction record of type [Transaction Type] for your store. Please consult your system admin for help resolving this error.';
	public static final String EXTRA_FINACIAL_TRANSACTION_RECORDS = '&bull;There are two or more financial transaction records of type [Transaction Type] for your store. Please consult your system admin for help resolving this error.';
	public static final String FINACIAL_TRANSACTION_RECORDS_NO_CREDIT_ACCOUNT_NUMBER = '&bull;The financial transaction record of type [Transaction Type] for your store does not have a Credit Account Number.';
	public static final String FINACIAL_TRANSACTION_RECORDS_NO_DEBIT_ACCOUNT_NUMBER = '&bull;The financial transaction record of type [Transaction Type] for your store does not have a Debit Account Number.';
		
	public static final String PAYMENT_ID_IS_NULL = '&bull;The Payment Id is null.';
	public static final String ORDER_IS_NULL = '&bull;Please enter an Order before creating a payment record on this order';
	public static final String PAYMENT_AMOUNT_IS_NULL = '&bull;Please enter a Payment Amount before creating a payment record on this order';
	public static final String CONTACT_IS_NULL = '&bull;Please enter a Contact on the Order before creating a payment record on this order';
	public static final String PAYMENT_ALREADY_SUBMITTED = '&bull;This payment has already been submitted, so you cannot change it.';
	
	public static final String PAYMENT_ALREADY_SUBMITTED_DELETE = '&bull;This payment has already been submitted, so you cannot delete it.';
	public static final String MULTIPLE_JOURNAL_ENTRIES = '&bull;This payment has more then one journal entry. Please consult your system admin for help resolving this error.';
	
	
}
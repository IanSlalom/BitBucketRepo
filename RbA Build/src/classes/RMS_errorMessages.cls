public with sharing class RMS_errorMessages {

	/*******************************************************
					Purchase Order Errors
	*******************************************************/
	public static final String SHIP_DATE_REQUIRED = 'Please enter an estimated ship date before changing the status to Received.'; 
	public static final String UNIT_COST_REQUIRED = 'Please enter a unit cost for all products before changing the status to Received.';
	public static final String ADD_PRODUCT_FIELDS_REQUIRED = 'Please enter an item name, cost center, description, and quantity before saving a line item.';
	public static final String PRICEBOOK_ENTRY_NOT_FOUND = 'A pricebook entry could not be found for this product. Please contact your system admin for help.';
	public static final String ADD_PRODUCT_EXCEPTION = 'The system was unable to add the item to the purchase order. Please contact your system admin for help.';
	public static final String SAVE_PO_EXCEPTION = 'The system was unable to save the purchase order. Please contact your system admin for help.';
	public static final String NO_DUMMY_ORDER = 'The system was unable to retrieve the dummy order id from custom settings. Please contact your system admin for help.';
	public static final String UPDATE_PO_LINES_EXCEPTION = 'The system was unable to update the purchase order line items. Please contact your system admin for help.';
	public static final String UPDATE_PO_EXCEPTION = 'The system was unable to update the purchase order. Please contact your system admin for help.';
	public static final String USER_STORE_LOCATION_BLANK = 'Your user record is not associated with a store location. Please contact your system admin for help.';
	public static final String STORE_LOCATION_BLANK = 'The order is not associated with a store location. Please add the store location and try again.';
	public static final String INVENTORY_GL_ACCOUNT_NOT_FOUND = 'The inventory GL account number could not be found. Please contact your system admin for help.';
	public static final String INTERCOMPANY_AP_ACCOUNT_NOT_FOUND = 'The intercompany AP account number could not be found. Please contact your system admin for help.';
	public static final String COST_CENTER_NUMBER_NOT_FOUND = 'The cost center number was not entered. Please try again.';
	public static final String PRODUCT_ACCOUNT_NUMBER_NOT_FOUND = 'The product account number could not be found for that product. Please contact your system admin for help.';
	public static final String STORE_LOCATION_NUMBER_NOT_FOUND = 'The store location number could not be found for your store. Please contact your system admin for help.';
	public static final String OVERRECEIVING_NOT_ALLOWED = 'Receiving more than the quantity ordered is not allowed for this vendor. Please try again.';
	public static final String OVERWRITINGOFF_NOT_ALLOWED = 'The quantity written off for this item cannot be more than the quantity ordered. Please try again.';
	public static final String OVERVENDORCREDIT_NOT_ALLOWED = 'The amount of vendor credit for this item cannot be more than the total wholesale cost. Please try again.';
	public static final String REC_DATE_QUANTITY_REQUIRED = 'You must enter both a quantity and date to receive an item. Please try again.';
	public static final String QUANTITY_NEGATIVE = 'You cannot enter a negative quantity. Please try again.';
	public static final String VENDOR_CREDIT_NEGATIVE = 'You cannot enter a negative vendor credit. Please try again.';
	public static final String WRITEOFF_DATE_QUANTITY_REQUIRED = 'You must enter both a quantity and date to write off an item. Please try again.';
	public static final String VENDORCREDIT_DATE_AMOUNT_REQUIRED = 'You must enter both an amount and date to of vendor credit for an item. Please try again.';
	public static final String WHOLESALE_COST_REQUIRED = 'You must enter a unit wholesale cost to receive an item. Please try again.';
	public static final String WHOLESALE_COST_NEGATIVE = 'Please enter a positive cost amount.';
	public static final String WHOLESALE_COST_REQUIRED_CREDIT = 'You must enter a unit wholesale cost to apply a vendor credit. Please try again.';
	public static final String PO_NOT_READY_TO_RELEASE = 'The order must be in the Ready to Order status before you can release this purchase order.';
	public static final String ORDER_STATUS_INVALID_FOR_PO_RELEASE = 'Purchase Order cannot be released until the Order is in Ready to Order Status.';
	public static final String ORDER_STATUS_INVALID_FOR_PO_CREATION = 'Purchase Order cannot be created until the Order is in Ready to Order Status.';
	public static final String PO_STATUS_INVALID_FOR_PO_RELEASE = 'Purchase Order cannot be released in the current status.';
	public static final String PO_LINE_ITEMS_INVALID_FOR_PO_RELEASE = 'Purchase Order cannot be released until all Purchase Order line items have been verified';
	public static final String ORDER_TYPE_STATUS_DATE_INVALID_FOR_PO_CREATION = 'Purchase Order cannot be created for CORO Orders if Revenue Recognized Date is not empty or Order Status is not Ready to Order, Order Released, Install Needed, Install Scheduled, Install Complete, or Job In Progress';
	public static final String DUPLICATE_SERVICE_PRODUCTS = 'Multiple service purchase orders cannot be created for a single service product.';
	public static final String VENDOR_NOT_FOUND = 'The vendor could not be found for one of the selected service products original installed product.';

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
	public static final String UNITED_INCH_BELOW_MIN = '&bull; The united inch total for the measurements entered[enteredValue] is below the minimum[requiredValue] for this product.';
	public static final String HEIGHT_TO_WIDTH_CAP = '&bull; The height and width you entered exceeds the height to width cap.';
	public static final String WIDTH_TO_HEIGHT_CAP = '&bull; The width and height you entered exceeds the width to height cap.';
	public static final String EXTENDED_MAX = '&bull; The height and width you entered exceeds the extended max height & width.';
	public static final String PEAK_HEIGHT = '&bull; The left and right leg difference is greater then the width times the product\'s peak height.'; 
	public static final String PEAK_HEIGHT_MAX = '&bull; The left and right leg difference is greater than the width times the product\'s peak height max.'; 
	public static final String PEAK_HEIGHT_MIN = '&bull; The left and right leg difference is less than the width times the product\'s peak height min.'; 
	public static final String GLASS_MAX_SQ_FEET = '&bull; The height and width you have entered[enteredValue] exceeds the max square feet[requiredValue] allowed for this product.';
	public static final String RECTANGULAR_AREA_LIMITATION = '&bull; The height and width you have entered[enteredValue] exceeds the rectangular area limitation[requiredValue] allowed for this product.';
	public static final String WIDTH_TO_HEIGHT_RATIO_MAX = '&bull; The height and width you have entered[enteredValue] exceeds the width to height ratio max[requiredValue] for this product.';
	public static final String WIDTH_TO_HEIGHT_RATIO_MIN = '&bull; The height and width you have entered[enteredValue] is below the width to height ratio minimum[requiredValue] for this product.';
	public static final String MINIMUM_LEG_HEIGHT_RIGHT = '&bull; The right leg height you entered[enteredValue] is below the minimum[requiredValue] leg height for this product.';
	public static final String MINIMUM_LEG_HEIGHT_LEFT = '&bull; The left leg height you entered[enteredValue] is below the minimum[requiredValue] leg height for this product.';
	public static final String MAXIMUM_LEG_HEIGHT_RIGHT = '&bull; The right leg height you entered[enteredValue] is above the maximum[requiredValue] leg height for this product.';
	public static final String MAXIMUM_LEG_HEIGHT_LEFT = '&bull; The left leg height you entered[enteredValue] is above the maximum[requiredValue] leg height for this product.';
	public static final String BRICKMOULD_NOT_AVALIABLE_DOUBLE_HUNG_SLOPED = '&bull; The Brickmould exterior trim is not available on Double Hung Insert Frames with Sloped Sills.'; 
 	public static final String SCREEN_WIDTH_MAX = '&bull; The width you entered[enteredValue] is above the maximum[requiredValue] for the type of screen you selected on this product.'; 
 	public static final String SCREEN_HEIGHT_MAX = '&bull; The height you entered[enteredValue] is above the maximum[requiredValue] for the type of screen you selected on this product.'; 
 	public static final String SASH_RATIO_OPERATION = '&bull; The Sash Ratio and Operation combination that you selected is not valid for this product.';
 	public static final String EJ_SPECIES_COLOR = '&bull; The EJ Species and Color combination that you selected is not valid for this product.';
 	public static final String GRILLE_STYLE_SHAPE_PATTERN = '&bull; This combination of specialty shape, grille pattern, and grille type is not valid. Please try again.';
 	public static final String GRILLE_HUBS_SPOKES = '&bull; The combination of Hubs/Spokes are not valid for this specialty shape, grille style, and type.';
 	public static final String GRILLE_LITES = '&bull; The combination of Lites High/Wide are not valid for this specialty shape, grille style, and type.';
 	public static final String COLOR_EXT_INT = '&bull; The Exterior Color / Interior Color combination that you selected is not valid for this product.';
 	public static final String GRILLE_MIN_HEIGHT = '&bull; The height cannot be less than [requiredValue] with that combination of grille style / grille pattern.';
 	public static final String GRILLE_MIN_WIDTH = '&bull; The width cannot be less than [requiredValue] with that combination of grille style / grille pattern.';
 	public static final String GLAZING_MAX_HEIGHT = '&bull; The height cannot be more than [requiredValue] with that glazing.';
 	public static final String GLAZING_MAX_WIDTH = '&bull; The width cannot be more than [requiredValue] with that glazing.';
 	public static final String GRILLE_STYLE_REQUIRED = '&bull; Grille Style is required for this combination of specialty shape and grille pattern.';
 	public static final String GRILLE_LITES_HIGH_REQUIRED = '&bull; Lites High is required for this combination of specialty shape and grille pattern.';
 	public static final String GRILLE_LITES_WIDE_REQUIRED = '&bull; Lites Wide is required for this combination of specialty shape and grille pattern.';
 	public static final String GRILLE_HUBS_REQUIRED = '&bull;  Hubs is required for this combination of specialty shape and grille pattern.';
 	public static final String GRILLE_SPOKES_REQUIRED = '&bull; Spokes is required for this combination of specialty shape and grille pattern.';
 	public static final String GRILLE_STYLE_DISABLED = '&bull; Grille Style cannot be entered for this combination of specialty shape and grille pattern.';
 	public static final String GRILLE_LITES_HIGH_DISABLED = '&bull; Lites High cannot be entered for this combination of specialty shape and grille pattern.';
 	public static final String GRILLE_LITES_WIDE_DISABLED = '&bull; Lites Wide cannot be entered for this combination of specialty shape and grille pattern.';
 	public static final String GRILLE_HUBS_DISABLED = '&bull;  Hubs cannot be entered for this combination of specialty shape and grille pattern.';
 	public static final String GRILLE_SPOKES_DISABLED = '&bull; Spokes cannot be entered for this combination of specialty shape and grille pattern.';


 	public static final String LOCK_MAX_WIDTH = '&bull; You cannot select more than [enteredValue] locks when the width is less than [requiredValue] inches.';
 	public static final String LOCK_MAX_HEIGHT = '&bull; You cannot select more than [enteredValue] locks when the height is less than [requiredValue] inches.';
 	public static final String LOCK_MIN_WIDTH = '&bull; You must select at least [enteredValue] locks when the width is greater than [requiredValue] inches.';
 	public static final String LOCK_MIN_HEIGHT = '&bull; You must select at least [enteredValue] locks when the height is greater than [requiredValue] inches.';
 	public static final String INTERIOR_COLOR_MAX_WIDTH = '&bull; The width cannot be more than [enteredValue] when the Interior Color is set to [requiredValue].';
 	public static final String INTERIOR_COLOR_MAX_HEIGHT = '&bull; The height cannot be more than [enteredValue] when the Interior Color is set to [requiredValue].';
 	 	
	public static final String PRODUCT_CONFIG_NOT_FOUND = '&bull; A suitable product configuration for this product could not be found based on the information you entered. Please contact your Administrator for help in resolving this issue.';
	public static final String ORDER_NOT_FOUND = '&bull; The order was not found. Please go back and try again.';
	public static final String ORDER_ACTIVATED_NEW = '&bull; Sorry, you cannot add product line items to an activated order.';
	public static final String ORDER_ACTIVATED_EDIT = '&bull; Sorry, you cannot edit product line items on an activated order.';
	public static final String PO_TAX_ISSUE = '&bull; Sorry, there was an issue updating the tax on the order line items. Please contact your system administrator';

	public static final String HARDWARE_FINISH_BLANK = '&bull;For this product, if you enter a hardware style, you must also enter a hardware finish.';
	public static final String TEMPERED_GLASS_REQUIRED = '&bull;Units of this size require Tempered Glass. Please select the "Tempered Glass" checkbox and try again.';
	public static final String SCREEN_COLOR_SELECTED_WITH_WOOD_VENEER = '&bull;You cannot select a screen color when the screen type is set to Wood Veneer';
	public static final String GRILLE_COLOR_WITHOUT_STYPE = '&bull;You cannot select an interior/exterior grille color without selecting a grille style';
	public static final String TRACK_HOLE_LOCATION_NULL = '&bull;Install Track/Holes Location is required when Special Options is selected.';
	
	/*******************************************************
					Financial Transation Errors
	*******************************************************/
	public static final String REQUIRED_FIELD_IS_NULL = '&bull;Please enter a [field] before creating this record';
	
	public static final String NO_FINACIAL_TRANSACTION_RECORDS = '&bull;There is no financial transaction record of type [Transaction Type] for your store. Please consult your system admin for help resolving this error.';
	public static final String EXTRA_FINACIAL_TRANSACTION_RECORDS = '&bull;There are two or more financial transaction records of type [Transaction Type] for your store. Please consult your system admin for help resolving this error.';
	public static final String FINACIAL_TRANSACTION_RECORDS_NO_CREDIT_ACCOUNT_NUMBER = '&bull;The financial transaction record of type [Transaction Type] for your store does not have a Credit Account Number.';
	public static final String FINACIAL_TRANSACTION_RECORDS_NO_DEBIT_ACCOUNT_NUMBER = '&bull;The financial transaction record of type [Transaction Type] for your store does not have a Debit Account Number.';
		
	public static final String PAYMENT_ID_IS_NULL = '&bull;The Payment Id is null.';
	public static final String STORE_LOCATION_IS_BLANK = '&bull;The Store Location is blank, this is a required field.';
	public static final String ACCOUNT_NUMBER_NULL = '&bull;The Account number is blank, this is a required field.';
	public static final String ORDER_IS_NULL = '&bull;Please enter an Order before creating this record.';
	public static final String PAYMENT_AMOUNT_IS_NULL = '&bull;Please enter a Payment Amount before creating a payment record on this order';
	public static final String CONTACT_IS_NULL = '&bull;Please enter a Contact on the Order before creating a payment record on this order';
	public static final String PAYMENT_ALREADY_SUBMITTED = '&bull;This Record has already been submitted, so you cannot change it.';
	public static final String LOCATION_ID_IS_NULL = '&bull;Location Number is null in the related store configuration. Please contact and administrator to resolve the issue';
	public static final String GLA_NUMBER_NULL = '&bull;The GLA Account must not be blank';
	public static final String GLA_NUMBER_THREE_OR_LESS = '&bull;The GLA Account must be longer than 3 characters.';
	
	public static final String ALREADY_SUBMITTED_DELETE = '&bull;This record has already been submitted, so you cannot delete it.';
	public static final String MULTIPLE_JOURNAL_ENTRIES = '&bull;This payment has more then one journal entry. Please consult your system admin for help resolving this error.';
	
	public static final String LABOR_ID_IS_NULL = '&bull;The Labor Id is null.';
	public static final String ORDER_ON_WORK_ORDER_NULL = '&bull;The Order on the related Work Order is null.';
	public static final String LABOR_AMOUNTS_NULL = '&bull;Both Internal and External Costs are null.';
	public static final String INSTALLER_HAS_NO_BAAN_NUMBER = '&bull;The Installer you have selected\'s account has no Baan Business Partner Number';
	public static final String VENDOR_HAS_NO_BAAN_NUMBER = '&bull;The Vendor you have selected\'s account has no Baan Business Partner Number';
	public static final String EXTERNAL_AMOUNT_NULL = '&bull;The External payment amount cannot be zero or empty on a Misc Reimbursement.';

	public static final String ASSET_ID_IS_NULL = '&bull;The Asset Id is null.';
	public static final String MORE_THAN_ONE_JOURNAL_ENTERY_NOT_SUBMITTED = '&bull;The Asset you are trying to edit has more than one unsubmitted Journal Entry. Please consult your system admin for help resolving this error.';
	public static final String NEGATIVE_FINACIAL_TRANSACTION = '&bull;This change is not permitted because it would result in a financial transaction with a negative amount.';
	public static final String BILL_TO_CONTACT_ON_ORDER_NULL = '&bull;The \'Bill to Contact\' field on the related order is null.';
	public static final String STORE_LOCATION_ON_ORDER_NULL = '&bull;The \'Store Location\' field on the related order is null.';
	public static final String RETAIL_SUBTOTAL_ON_ORDER_NULL = '&bull;The \'Retail Subtotal\' field on the related order is null.';
	public static final String QUANTITY_IS_LESS_THAN_ZERO = '&bull;The Asset Quantity cannot be lower than zero.';
	
	public static final String JOURNAL_ENTRY_FIELD_NULL_ON_ORDER_NULL_DEPOSIT = '&bull;The [field] field could not be found. This must be entered to recognize revenue for Deposits. Please contact your system admin for assistance';
	public static final String JOURNAL_ENTRY_FIELD_NULL_ON_ORDER_NULL_INSTALL_ADJ = '&bull;The [field] field could not be found. This must be entered to recognize revenue for Install Adjustments. Please contact your system admin for assistance';
	public static final String JOURNAL_ENTRY_FIELD_NULL_ON_ORDER_NULL_LABOR = '&bull;The [field] field could not be found. This must be entered to recognize revenue for Labor. Please contact your system admin for assistance.';
	public static final String NO_RELATED_DEPOSIT_JOURNAL_ENTRY = '&bull;This Order Has no related Journal Entries with deposit type.';
	public static final String REVENUE_ALREADY_RECOGNIZED = '&bull;This revenue has already been recognized and submitted for this order and you cannot change it.';
	public static final String CHANGE_REVENUE_RECOGNIZED_DATE_NOT_CLEAR = '&bull;You cannot change the Revenue Recognized Date to another date, you must first clear it.';					

	public static final String REQUIRED_REFUND_FIELD_NULL = '&bull;Please enter a [field] before creating a Refund record on this order.';
	
//  commented out per JETT-3638
//	public static final String AMOUNT_OF_PAYMENT_EXCEEDS_PRICE = '&bull;The amount of payment exceeds the quoted price. Please issue a refund or adjust/correct a payment.';
	public static final String CHANGED_WRITE_OFF_AND_VENDOR_CREDIT = '&bull;You are unable to change the Quantity Written Off the same time you change Vendor Credit.';
	
	
	/*******************************************************
					Redirect Errors
	*******************************************************/ 
	public static final String STORE_LOCATION_IS_BLANK_PAYMENT = 'The Store Location must be entered on the Order before creating a deposit.';
	public static final String STORE_LOCATION_IS_BLANK_LABOR = 'The Store Location must be entered on the Work Order before creating a labor record.';
	public static final String STORE_LOCATION_IS_BLANK_USER = 'Your user record must be associated with a store location before creating a misc reimbursement.';

	/*******************************************************
					Misc Errors 
	*******************************************************/
	public static final String CUSTOM_SETTING_REQUIRED = 'Require custom settings are missing: \'Data Loading Profile ID\' or \'Unassigned Account Id\'.';
	public static final String DATA_LOADING_CUSTOM_SETTING_REQUIRED = 'Please populate the \'Data Loading Profile ID\' in Custom Settings.';
	public static final String RECORD_IS_LOCKED = 'This record is locked so you cannot change it.';
	public static final String FIELD_IS_LOCKED = '&bull;The [field] field cannot be changed in the current status.';
	public static final String WORK_ORDERS_WITH_OPEN_EVENTS = 'Please close appointments within any Tech Measure or Install Work Orders before cancelling this order.';
	public static final String ORDER_CLOSED = 'You cannot add or edit products on a closed order.';


}
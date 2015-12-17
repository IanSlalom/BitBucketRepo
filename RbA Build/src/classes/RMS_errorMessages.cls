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
	public static final String HEIGHT_TO_WIDTH_CAP = '&bull; The height and width you entered[enteredValue] exceeds the height to width cap[requiredValue].';
	public static final String WIDTH_TO_HEIGHT_CAP = '&bull; The width and height you entered[enteredValue] exceeds the width to height cap[requiredValue].';
	public static final String PEAK_HEIGHT = '&bull; The left and right leg difference[enteredValue] is greater then the width times the product\'s peak height[requiredValue].';
	public static final String GLASS_MAX_SQ_FEET = '&bull; The height and width you have entered[enteredValue] exceeds the max[requiredValue] square feet allowed for this product.';
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
 	
 	
	public static final String CHILD_PRODUCT_NOT_FOUND = '&bull; A suitable product could not be found based on the product information you entered. Please contact your Administrator for help in resolving this issue.';
	public static final String MULTIPLE_CHILD_PRODUCTS = '&bull; Multiple products were found based on the product information you entered. Please contact your Administrator for help in resolving this issue.';
	public static final String INVALID_CHILD_PRODUCT = '&bull; A suitable product could not be found based on the product information you entered. Either zero or multiple products were found in the system. Please contact your Administrator for help in resolving this issue.';
	public static final String PRODUCT_CONFIG_NOT_FOUND = '&bull; A suitable product configuration for this product could not be found based on the information you entered. Please contact your Administrator for help in resolving this issue.';
	public static final String ORDER_NOT_FOUND = '&bull; The order was not found. Please go back and try again.';
	public static final String ORDER_ACTIVATED_NEW = '&bull; Sorry, you cannot add product line items to an activated order.';
	public static final String ORDER_ACTIVATED_EDIT = '&bull; Sorry, you cannot edit product line items on an activated order.';
}
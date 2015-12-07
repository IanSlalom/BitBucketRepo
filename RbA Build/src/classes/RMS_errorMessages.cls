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
	public static final String PRODUCT_EMPTY = 'Please choose a product and try again.';
	public static final String QUANTITY_EMPTY = 'Please enter a quantity and try again.';
	public static final String WIDTH_HEIGHT_EMPTY = 'Please enter a width and height.';
	public static final String INVALID_HEIGHT_FORMAT = 'Please enter the height as either a whole number or decimal.';
	public static final String INVALID_WIDTH_FORMAT = 'Please enter the width as either a whole number or decimal.';
	public static final String WIDTH_BELOW_MIN = 'The width you entered is below the minimum for this product.';
	public static final String HEIGHT_BELOW_MIN = 'The height you entered is below the minimum for this product.';
	public static final String WIDTH_ABOVE_MAX = 'The width you entered is above the maximum for this product.';
	public static final String HEIGHT_ABOVE_MAX = 'The height you entered is above the maximum for this product.';
	public static final String UNITED_INCH_ABOVE_MAX = 'The united inch total for the measurements entered is above the maximum for this product.';
	public static final String HEIGHT_TO_WIDTH_CAP = 'The height and width you entered exceeds the height to width cap.';
	public static final String WIDTH_TO_HEIGHT_CAP = 'The width and height you entered exceeds the width to height cap.';
	public static final String PEAK_HEIGHT = 'The left and right leg difference is greater then the width times the product\'s peak height.';
	public static final String GLASS_MAX_SQ_FEET = 'The height and width you have entered exceededs the max square feet allowed for this product.';
	public static final String WIDTH_TO_HEIGHT_RATIO_MAX = 'The height and width you have entered exceededs the width to height ratio max for this product.';
	public static final String WIDTH_TO_HEIGHT_RATIO_MIN = 'The height and width you have entered is below the width to height ratio minimum for this product.';
	public static final String MINIMUM_LEG_HEIGHT_RIGHT = 'The right leg height is below the minimum leg height for this product.';
	public static final String MINIMUM_LEG_HEIGHT_LEFT = 'The left leg height is below the minimum leg height for this product.';
	public static final String BRICKMOULD_NOT_AVALIABLE_DOUBLE_HUNG_SLOPED = 'Brickmould is not available on Double Hung Insert Frames with Sloped Sills'; 
 
	public static final String CHILD_PRODUCT_NOT_FOUND = 'A suitable product could not be found based on the product information you entered. Please contact your Administrator for help in resolving this issue.';
	public static final String MULTIPLE_CHILD_PRODUCTS = 'Multiple products were found based on the product information you entered. Please contact your Administrator for help in resolving this issue.';
	public static final String INVALID_CHILD_PRODUCT = 'A suitable product could not be found based on the product information you entered. Either zero or multiple products were found in the system. Please contact your Administrator for help in resolving this issue.';
	public static final String PRODUCT_CONFIG_NOT_FOUND = 'A suitable product configuration for this product could not be found based on the information you entered. Please contact your Administrator for help in resolving this issue.';
	public static final String ORDER_NOT_FOUND = 'The order was not found. Please go back and try again.';
	public static final String ORDER_ACTIVATED_NEW = 'Sorry, you cannot add product line items to an activated order.';
	public static final String ORDER_ACTIVATED_EDIT = 'Sorry, you cannot edit product line items on an activated order.';
}
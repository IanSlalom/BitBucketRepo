public class ProdConfigUtility {

    /*******************************************************
                    retrievePickListItems method
    *******************************************************/
	//Utility method to receive a multi picklist and return select options for use in a single picklist.
    public static List<SelectOption> retrievePickListItems(String multiPickList) {
        List<SelectOption> pickListItems = new List<SelectOption>();
        pickListItems.add(new SelectOption('', '-- Select --'));
    	// need to limit to pricebook
        if (String.isBlank(multiPickList)) return pickListItems;
        
        for (String pickListItem : multiPickList.split(';')) {
            pickListItems.add(new SelectOption(pickListItem, pickListItem));
        }               
        return pickListItems;
    } 
}
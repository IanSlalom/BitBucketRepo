public with sharing class RMS_prodConfigUtility {

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

    /*******************************************************
                    retrievePickListItems method
    *******************************************************/
	//Utility method to receive a multi picklist and return select options for use in a single picklist.
    public static List<SelectOption> retrievePickListItems2(List<Schema.FieldSetMember> fieldSetMembers, RMS_prodConfigManager.ProductConfigWrapper prodConfig) {
        List<SelectOption> pickListItems = new List<SelectOption>();
        pickListItems.add(new SelectOption('', '-- Select --'));
    	// need to limit to pricebook
        if (fieldSetMembers == null) return pickListItems;
        
        for (Schema.FieldSetMember fsm : fieldSetMembers) {
            pickListItems.add(new SelectOption(fsm.getLabel(), fsm.getLabel()));
        }               
        return pickListItems;
    } 

}
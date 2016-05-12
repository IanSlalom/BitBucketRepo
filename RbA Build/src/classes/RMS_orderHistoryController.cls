/*******************************************************//**

@class  RMS_orderHistoryController

@brief  This class is used for the View Order page RMS_viewServiceRequest.
Since we cannot use "detail" for Service Requests, we have to build the 
field history changes from scratch as the related list for Order History does not
exist. This controller is used for the component added to the page to display
the Order History (field history)

@author  Brianne Wilson (Slalom.BLW)

@version    2016-5-10  Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/

public class RMS_orderHistoryController {
    
    
    public Id orderId {get; set;}
    public cHistories[] histories; 
    
    // Variables
    public Static final Map<String, Schema.SObjectField> OrderFieldmap = Schema.SObjectType.Order.fields.getMap();
    public Static final List<Schema.PicklistEntry> fieldPicklistValues = OrderHistory.Field.getDescribe().getPicklistValues();
    
    public List<cHistories> getHistories()
    {
        list<cHistories> histories = new list<cHistories>();
        String prevDate = '';
        for(OrderHistory cHistory : [Select CreatedDate, CreatedBy.Name, CreatedBy.Id, Field, NewValue, OldValue from OrderHistory where OrderId = :orderId order by CreatedDate desc])
        {
            if((cHistory.newValue == null && cHistory.oldValue == null) 
               || (cHistory.newValue != null && !(string.valueOf(cHistory.newValue).startsWith('005') || string.valueOf(cHistory.newValue).startsWith('00G')))
               || (cHistory.oldValue != null && !(string.valueOf(cHistory.oldValue).startsWith('005') || string.valueOf(cHistory.oldValue).startsWith('00G'))))
            {
                cHistories tempHistory = new cHistories();
                // Set the Date and who performed the action
                if(String.valueOf(cHistory.CreatedDate) != prevDate)
                {
                    tempHistory.theDate = ((Datetime)cHistory.get('CreatedDate')).format('MM/dd/YYYY hh:mm a'); 
                    tempHistory.who = cHistory.CreatedBy.Name;
                    tempHistory.userId = cHistory.CreatedBy.Id;
                }
                else
                {
                    tempHistory.theDate = '';
                    tempHistory.who = '';
                    tempHistory.userId = cHistory.CreatedBy.Id;
                }
                prevDate = String.valueOf(cHistory.CreatedDate);
                
                // Get the field label
                String fieldLabel = RMS_orderHistoryController.returnFieldLabel(String.valueOf(cHistory.Field));
                
                // Set the Action value
                if (String.valueOf(cHistory.Field) == 'created') { // on Creation
                    tempHistory.action = 'Created.';
                }
                else if(cHistory.OldValue != null && cHistory.NewValue == null){ // when deleting a value from a field
                    // Format the Date and if there's an error, catch it and re
                    try {
                        tempHistory.action = 'Deleted ' + Date.valueOf(cHistory.OldValue).format() + ' in <b>' + fieldLabel + '</b>.';
                    } catch (Exception e){
                        tempHistory.action = 'Deleted ' + String.valueOf(cHistory.OldValue) + ' in <b>' + fieldLabel + '</b>.';
                    }
                }
                else{ // all other scenarios
                    String fromText = '';
                    if (cHistory.OldValue != null) {
                        try {
                            fromText = ' from ' + Date.valueOf(cHistory.OldValue).format();
                        } catch (Exception e) {
                            fromText = ' from ' + String.valueOf(cHistory.OldValue);
                        }
                    }
                    
                    String toText = '';
                    if (cHistory.OldValue != null) {
                        try {
                            toText = Date.valueOf(cHistory.NewValue).format();
                        } catch (Exception e) {
                            toText = String.valueOf(cHistory.NewValue);
                        }
                    }
                    if(toText != '')
                        tempHistory.action = 'Changed <b>' + fieldLabel + '</b>' + fromText + ' to <b>' + toText + '</b>.';
                    else
                        tempHistory.action = 'Changed <b>' + fieldLabel;
                }
                
                // Add to the list
                histories.add(tempHistory);
            }
        }
        
        return histories;
    }	
    
    // Function to return Field Label of a Case field given a Field API name
    public Static String returnFieldLabel(String fieldName)
    {
        if(RMS_orderHistoryController.OrderFieldmap.containsKey(fieldName))
            return RMS_orderHistoryController.OrderFieldmap.get(fieldName).getDescribe().getLabel();
        else
        {
            for(Schema.PicklistEntry pickList : fieldPicklistValues)
            {
                if(pickList.getValue() == fieldName)
                {
                    if(pickList.getLabel() != null)
                        return pickList.getLabel();
                    else
                        return pickList.getValue();
                }
            }
        }
        return '';
    }
    // Inner Class to store the detail of the case histories	
    public class cHistories {
        
        public String theDate {get; set;}
        public String who {get; set;}
        public Id userId {get; set;} 
        public String action {get; set;}
    }
}
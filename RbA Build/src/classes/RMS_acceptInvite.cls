/*******************************************************//**

@class  RMS_acceptInvite

@brief  This class is used to automatically create accepted invitations
to group events. Necessary for MapAnything scheduling

@author  Brianne Wilson (Slalom.BLW)

@version    2016-5-27  Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
public with sharing class RMS_acceptInvite {    
    
    public void acceptInvite(List<Event> listNew, Map<Id, Event> mapNew){
        
        List<EventRelation> childRecords = [Select Id, EventId, Status                                    
                                            FROM EventRelation WHERE EventId IN: Trigger.newMap.keySet() AND IsInvitee = true];
        
        system.debug(childRecords);
        
        Map<Id,EventRelation> eventMap = new Map<Id,EventRelation>([select Id,EventId,Status from EventRelation where Id in:childRecords]);
        Id woRecordType = UtilityMethods.RecordTypeFor('Event','Work_Order_Event');
        
        for(EventRelation child :childRecords){
            
            
            child.Status = 'Accepted';  

        }                              
        
        
        if(childRecords.size() > 0){
            update childRecords;
        }    
    }
}
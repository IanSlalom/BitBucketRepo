public class RMS_addApplicationNotes {    
    
    public void populateApplicationNotesCreate(List<RbA_Work_Order__c> listNew, Map<Id, RbA_Work_Order__c> mapNew){
        
        List <Id> municipality = new List<Id>();
        
        for(RbA_Work_Order__c wo : listNew){
            If(wo.Work_Order_Type__c == 'Building Permit' || wo.Work_Order_Type__c == 'HOA' || wo.Work_Order_Type__c == 'Historical'){                                
                municipality.add(wo.Municipality__c);                
            }   
        }
        
        List <Municipality__c> mun = [Select ID, Application_Notes__c from Municipality__c where Id in :municipality];
        
        for (Integer i = 0; i <listNew.size(); i++){
            if (mun.size() > 0){
                for (Municipality__c z:mun){
                    if (listNew[i].Municipality__c != null){
                        listNew[i].Application_Notes__c = z.Application_Notes__c;
                    }
                }
            }
            
        }
        
    }
    
    public void populateApplicationNotesUpdate (List<RbA_Work_Order__c> listOld, List<RbA_Work_Order__c> listNew, Map<Id, RbA_Work_Order__c> mapOld, Map<Id, RbA_Work_Order__c> mapNew){
        List <Id> municipality = new List<Id>();
        
        for(RbA_Work_Order__c wo : listNew){
            If(wo.Work_Order_Type__c == 'Building Permit' || wo.Work_Order_Type__c == 'HOA' || wo.Work_Order_Type__c == 'Historical'){                                
                municipality.add(wo.Municipality__c);                
            }   
        }
        
        List <Municipality__c> mun = [Select ID, Application_Notes__c from Municipality__c where Id in :municipality];
        
        for (Integer i = 0; i <listNew.size(); i++){
            if (mun.size() > 0){               
                for (Municipality__c z:mun){
                    if (listNew[i].Municipality__c != null && mapOld.get(listNew[i].Id).Municipality__c != listNew[i].Municipality__c){
                        listNew[i].Application_Notes__c = z.Application_Notes__c;
                    }
                }
            }
            
        }
    }
    
}
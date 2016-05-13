/*******************************************************//**

@class  RMS_assignServiceTaskOwner

@brief  When a Task is for a Service Work Order (Work Order Type = Service)
via the "Add Service Task" visualforce page. The Task assignee is determined 
by the Store Configuration from related Work Order-->Account-->Store-->Active
Store Configuration-->Service Task Owner and Service Material Owner

@author  Brianne Wilson (Slalom.CDK)

@version    2015-4-19  Slalom.CDK
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/

public with sharing class RMS_assignServiceTaskOwner {
    
    public void assignServiceTaskOwner(List<Task> listOld, List<Task> listNew, Map<Id, Task> mapOld, Map<Id, Task> mapNew){
        
        //Creating lists of ids for users, st = service task, sm = service material
        // List<Id> st = new List<Id>(); 
        List<Id> sm = new List<Id>();
        
        List<Id> st = new List<Id>();
        //for the task created, if Service Type is not equal to null
        //and the Service Type is Service Task, add the Service Task
        //Owner Id field to the st list. if the Service Type is Service
        //Material, add the Service Material Owner Id to the sm list.
        //Note that there are formula fields on the Task pulling in the Ids
        //to pull from to limit the nested loops
        for(Task e : listNew){
            If(e.Assigned_To__c == null){
                If(e.Service_Type__c != null ){
                    If(e.Service_Type__c != 'Service Task'){
                        sm.add(e.Service_Material_Owner_Id__c);       
                    } 
                }
            } else {               
                st.add(e.Assigned_To__c);
            }   
        }
        
        //lists for the user ids found in st and sm
        List <User> stList = [Select ID from User where Id in :st];
        List <User> smList = [Select ID from User where Id in :sm];
        
        //when the Service Type is Service Task, add the Service Task Owner Id value to the 
        //Task Owner field. When the Service Type is not Service Task, add the Service
        //Material Owner Id value to the Task Owner field. Iterate over all tasks.  
        //5-12 Update: Only Service Material Owner, Service Task goes to record creator.     
        for (Integer i = 0; i <listNew.size(); i++){            
            if (listNew[i].Assigned_To__c == null){
                if (listNew[i].Service_Type__c != 'Service Task'){
                    for (User x:smList){
                        if (listNew[i].Service_Material_Owner_Id__c == x.Id){
                            listNew[i].OwnerId = x.ID;
                        }
                    }
                }                  
                
            }  else {
                for (User z:stList){
                    if (listNew[i].Assigned_To__c == z.Id){
                        listNew[i].OwnerId = z.ID;
                    }
                }
            }  
        }
    }
}
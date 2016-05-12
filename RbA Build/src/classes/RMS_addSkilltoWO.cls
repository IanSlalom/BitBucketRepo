/*******************************************************//**

@class  RMS_addSkilltoWO

@brief  For Install and Tech Measure Work Orders, on create, system queries
the Products of the related Order and finds the Skills assigned
to each Product. Then for each skill for each product, a Work
Order Required Skill record is created to denote which skills are 
required for the Work Order. 

data model: RbA Skill represents each actual "Skill" with the name field
a text field. Product Skill is a junction object between Product and RbA Skill.
Resource Skill is a junction object between Resource and RbA Skill. 
Work Order Required Skill is a junction object between RbA Work Order and RbA Skill.

This process is used in part with scheduling, by matching Product Skills to Work 
Order Products to determine the required skills for an install work order. From there,
Resources can be matched to the work order based on resource skills compared to work 
order required skills.

@author  Brianne Wilson (Slalom.BLW)

@version    2016-4-19  Slalom.BLW
Created.


@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/

public with sharing class RMS_addSkilltoWO {
    
    
    public void addSkilltoWO (List<RbA_Work_Order__c> listNew, Map<Id, RbA_Work_Order__c> mapNew){
        
        //create list to hold Work Order Required Skills
        List<Work_Order_Required_Skill__c> newWORS = new list<Work_Order_Required_Skill__c>();        
        
        //List of ids for the related Sold Orders
        List<Id> relatedOrder = new list<Id>();
        
        //for the new RbA Work Order, add to the related Order Id list the Sold Order field on the WO
        for(RbA_Work_Order__c rwo : listNew){
            if(rwo.Sold_Order__c != null){
                relatedOrder.add(rwo.Sold_Order__c);    
            }            
        }
        
        //Store the list of Order Items of the related Sold Order to find the products and their
        //product skills
        List<id> oiIds = new List<id>();{
            for(OrderItem oi : [SELECT  Id, PricebookEntry.Product2Id
                                FROM OrderItem 
                                WHERE OrderId = :relatedOrder]){
                                    
                                    oiIds.add(oi.PricebookEntry.Product2Id);
                                }   
        }
        
        
        //List of RbA Skill ids of the Products in the Order Items
        //of the related Sold Order. Store the RbA Skill value in the Product Skill to the 
        //skillids list
        List<id> skillIds = new List<id>();{
            for(Product_Skill__c s : [SELECT  Id,RbA_Skill__c, Product__c
                                      FROM Product_Skill__c 
                                      WHERE Product__c = :oiIds]){
                                          
                                          skillIds.add(s.RbA_Skill__c);
                                      } 
            
            //if the new RbA Work Order has a Work Order Type of Install,
            //then for each RbA Skill in the skillids list, create a 
            //Work Order Required Skill record
            for(RbA_Work_Order__c rwo : listNew){ 
                If(rwo.Work_Order_Type__c == 'Install' || rwo.Work_Order_Type__c == 'Tech Measure'){
                    for (RbA_Skills__c r :[Select Id FROM RbA_Skills__c WHERE Id = :skillIds] ) {          
                        Work_Order_Required_Skill__c ch = new Work_Order_Required_Skill__c(
                            RbA_Work_Order__c = rwo.Id,
                            RbA_Skill__c = r.Id);
                        
                        newWORS.add(ch);
                    }
                }
            }
            insert newWORS;
            
        }
        
    }
}
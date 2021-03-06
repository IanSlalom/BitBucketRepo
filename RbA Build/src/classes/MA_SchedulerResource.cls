/************************************************************************************/
/*                                                                                  */
/*      This wrapper class holds the methods used to create resources               */
/*                                                                                  */
/*      @author     Daniel Taylor   (MapAnything)                                   */
/*                  Ethan Rush      (MapAnything)                                   */
/*                                                                                  */
/*      @version    6/29/2016   MapAnything                                         */
/*      Created                                                                     */
/*                                                                                  */
/*      @copyright (c)2016 MapAnything. All Rights Reserved.                        */
/*      Unauthorized use is prohibited                                              */
/*                                                                                  */
/************************************************************************************/

public with sharing class MA_SchedulerResource implements Comparable {

    public String type;
    public Integer rank;
    public Id resourceId;
    public String headcount;
    public Boolean isActive;
    public Boolean isAssigned;
    public Boolean isAvailable;
    public String resourceName;
    public String skillsMatchedTotal;
    public Integer skillsMatchedCount;
	public Map<Id, String> skillsMatched;
    public Map<Id, String> skillsNotMatched;
    
    /****************************************************/
    /*                                                  */
    /*      creates the resource                        */
    /*                                                  */
    /****************************************************/
    public MA_SchedulerResource(Resource__c resource, Map<Id, String> requiredSkills, Set<Id> assignedResources) {
        this.isAvailable = true;
        this.resourceId = resource.Id;
        this.resourceName = resource.Name;
        this.isActive = resource.Active__c;
        this.type = resource.Resource_Type__c;
    	this.rank = (Integer)resource.Rank__c;
        this.skillsMatched = new Map<Id, String>();
        this.headcount = String.valueOf(resource.Crew_Size__c);
        this.skillsNotMatched = new Map<Id, String>(requiredSkills);
        this.isAssigned = assignedResources.contains(this.resourceId);

        for (Resource_Skill__c skill : resource.Resource_Skills__r) {
            this.skillsNotMatched.remove(skill.RbA_Skill__c);
            this.skillsMatched.put(skill.RbA_Skill__c, skill.RbA_Skill__r.Name);
        }

        this.skillsMatchedCount = this.skillsMatched.size();
        this.skillsMatchedTotal = this.skillsMatchedCount + '/' + requiredSkills.size();
    }

    /****************************************************/
    /*                                                  */
    /*      used to properly sort a list of resources   */
    /*                                                  */
    /****************************************************/
    public Integer compareTo(Object compareTo) {
        MA_SchedulerResource compareToResource = (MA_SchedulerResource)compareTo;

        if (skillsMatchedCount == compareToResource.skillsMatchedCount) {
            if (rank == compareToResource.rank) {
            	return 0;
            }
            else if (rank < compareToResource.rank) {
            	return -1;
            }
        }
        else if (skillsMatchedCount > compareToResource.skillsMatchedCount) {
            return -1;
        }

        return 1;
    }

}
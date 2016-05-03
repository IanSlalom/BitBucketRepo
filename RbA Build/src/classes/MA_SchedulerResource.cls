public with sharing class MA_SchedulerResource implements Comparable {

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
    
    public MA_SchedulerResource(Resource__c resource, Map<Id, String> requiredSkills, Set<Id> assignedResources) {
        this.isAvailable = true;
        this.resourceId = resource.Id;
        this.resourceName = resource.Name;
        this.isActive = resource.Active__c;
    	this.rank = (Integer)resource.Rank__c;
        this.headcount = String.valueOf(resource.Crew_Size__c);
        this.isAssigned = assignedResources.contains(this.resourceId);

        this.skillsMatched = new Map<Id, String>();
        this.skillsNotMatched = new Map<Id, String>(requiredSkills);

        for (Resource_Skill__c skill : resource.Resource_Skills__r) {
            this.skillsNotMatched.remove(skill.RbA_Skill__c);
            this.skillsMatched.put(skill.RbA_Skill__c, skill.RbA_Skill__r.Name);
        }

        this.skillsMatchedCount = this.skillsMatched.size();
        this.skillsMatchedTotal = this.skillsMatchedCount + '/' + requiredSkills.size();
    }

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
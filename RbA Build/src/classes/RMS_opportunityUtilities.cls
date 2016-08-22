global with sharing class RMS_opportunityUtilities {

	webservice static String convertOpportunity(String oppId) {
		Opportunity opp = [SELECT Id, IsWon, StageName, SyncedQuoteId FROM Opportunity WHERE Id = :oppId];
		System.Debug('***************iswon=' +opp.IsWon);
		System.Debug('***************StageName=' +opp.StageName);
		List<Order> orderList = [SELECT Id, Status FROM Order WHERE OpportunityId = :oppId AND Status != 'Cancelled'];
		System.Debug('***************orderList=' +orderList);
		
		String tempStatus;
		if(orderList.size() > 0){
			 return 'alreadyConverted'; 
		}
		else{
			if (opp.isWon) {
				tempStatus = opp.StageName;
				opp.StageName = 'New';
				update opp;				
				opp.StageName = tempStatus;
			}
			else {
				opp.StageName = 'Sold';
			}
			update opp;
			Order ord;
			for (Order o : [SELECT Id, OpportunityId FROM Order WHERE OpportunityId = :oppId]){
				ord = o;
			}
			if (ord == null) {
				return 'noOrderCreated';
			}
			return String.ValueOf(ord.id);
		}
	}
}
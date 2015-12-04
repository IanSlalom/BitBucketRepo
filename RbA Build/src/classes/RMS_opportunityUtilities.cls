global with sharing class RMS_opportunityUtilities {

	webservice static String convertOpportunity(String oppId) {
		Opportunity opp = [SELECT Id, IsWon, StageName, SyncedQuoteId FROM Opportunity WHERE Id = :oppId];
		List<Order> orderList = [SELECT Id, Status FROM Order WHERE OpportunityId = :oppId AND Status != 'Cancelled'];
		
		if(orderList.size() > 0){
			 return 'alreadyConverted';
		}
		else if(opp.SyncedQuoteId == null ){
			return 'noSyncedQuote';
		}
		else{
			opp.StageName = 'Closed Won';
			update opp;
			Order ord = [SELECT Id, OpportunityId FROM Order WHERE OpportunityId = :oppId];
			return String.ValueOf(ord.id);
		}
	}
}
public class Utilities {

	// Retrieves Id for recordtype using object name and dev name
	public static Id RecordTypeFor(String sObjectName, String devName) {

		String devString = sObjectName + devName;
		if (masterRTList == null || masterRTList.isEmpty()) {
			for (RecordType rt : [SELECT Id, developerName, sObjectType FROM RecordType]) {
				masterRTList.put(rt.sObjectType + rt.DeveloperName, rt.Id);
			}
		}
				
		System.Debug('***************masterRTList.get(sObjectName + devName)=' +masterRTList.get(sObjectName + devName));
		return masterRTList.get(sObjectName + devName);
	}
	
	// Persistant variable used by RecordTypeFor()
	public static Map<String,Id> masterRTList = new Map<String,Id>();
}
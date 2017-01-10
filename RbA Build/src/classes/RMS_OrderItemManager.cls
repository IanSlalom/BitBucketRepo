/***************************************
    @class RMS_OrderItemManager
    @brief  class for processing actions on OrderItems - generally used in the OrderItemTrigger
    @author  Anthony Strafaccia (Slalom.ADS)
	@author  Mark Wochnick (Slalom.MAW)
    @version    2016-3/3  Slalom.ADS
	    Created.
    @version    2016-9/30  Slalom.MAW
		added -linkChildProducts method
		added -documentation comments	
    @see        OrderItemTriggerTest
    
    @copyright  (c)2016 Slalom.  All Rights Reserved.
    Unauthorized use is prohibited.
    
    ***********************************************************/
public with sharing class RMS_OrderItemManager {

//TODO: add method comment	
	public void setUpChangeHistoryOnCreate(list<OrderItem> newList, map<id,OrderItem> newMap){

		system.debug('ads creating new change history: '+ newList);
		list<Change_History__c> changeHistoryToInsert = new list<Change_History__c>();
		for(OrderItem oi : newlist){
			Change_History__c ch = new Change_History__c();
			ch.Order_Product__c = oi.Id;
			ch.Retail_Price__c = oi.Total_Retail_Price__c;
			ch.Retail_Price_Change__c =  oi.Total_Retail_Price__c;
			ch.Responsible_Party__c = oi.Responsible_Party__c;
			ch.RecordtypeId = UtilityMethods.RecordTypeFor('Change_History__c', 'Order_Product');
			ch.Subtype__c = 'Initial';
			ch.Line_Processed_Date__c = System.today();
			ch.Order_Booking_Date__c = oi.Order_Booking_Date__c;
			ch.Order_Revenue_Recognition_Date__c = oi.Order_Revenue_Recognition_Date__c;
			changeHistoryToInsert.add(ch);
		}
		insert changeHistoryToInsert;
	}
	
//TODO: add method comment	
	public void updateChangeHistoryOnUpdate(list<OrderItem> newList, list<OrderItem> oldList, map<id,OrderItem> newMap, map<id,OrderItem> oldMap){
		system.debug('ads updating new change history: '+ newList);
		list<Change_History__c> changeHistoryToUpsert = new list<Change_History__c>();
		
		list<Change_History__c> relatedChangeHistories = [SELECT 	id, 
																	Changes__c, 
																	Order_Product__c, 
																	Retail_Price__c, 
																	Retail_Price_Change__c 
																	FROM Change_History__c 
																	WHERE Order_Product__c 
																	IN :oldMap.Keyset()
																	AND CreatedById = :UserInfo.getUserId() 
																	AND CreatedDate = TODAY
																	order by CreatedDate desc];
																	
		map<id, list<Change_History__c>> orderItemIdToListChangeHistory = new map<id, list<Change_History__c>>();

		for(Change_History__c ch : relatedChangeHistories){
			if(orderItemIdToListChangeHistory.containsKey(ch.Order_Product__c)){
				orderItemIdToListChangeHistory.get(ch.Order_Product__c).add(ch);
			}else{
				orderItemIdToListChangeHistory.put(ch.Order_Product__c, new list<Change_History__c>{ch});
			}
		}
		
		//DYNAMICLY QUERY ALL FIELDS ON ORDER ITEM
		SObjectType xOI = Schema.getGlobalDescribe().get('OrderItem');
		map<String,Schema.SObjectField> oiFieldsMap = xOI.getDescribe().fields.getMap();
	    set<id> newListIds = newMap.keyset(); 
		String oiQuery = 'SELECT ';
		for(String oiField : oiFieldsMap.KeySet()){
			oiQuery = oiQuery + oiField + ', ';
	    }
	    oiQuery = oiQuery.substring(0,oiQuery.length()-2);
	    oiQuery = oiQuery + ' FROM OrderItem WHERE Id IN :newListIds';
	    list<OrderItem> extraFieldsList = Database.query(oiQuery);
                                                     
		
		for(OrderItem oi : extraFieldsList){
			//IF NO CHANGE HISTORY CREATED BY CURRENT USER TODAY	 		
				
			Change_History__c rCH = new Change_History__c();
			if(	orderItemIdToListChangeHistory.get(oi.id) == null || 
				orderItemIdToListChangeHistory.get(oi.id).size() == 0 || 
				oldMap.get(oi.id).Total_Retail_Price__c != newMap.get(oi.id).Total_Retail_Price__c ||
				oldMap.get(oi.id).UnitPrice != newMap.get(oi.id).UnitPrice){
					
				rCH.Order_Product__c = oi.Id;
				rCH.Retail_Price__c = oi.Total_Retail_Price__c;
				rCH.Retail_Price_Change__c =  oi.Total_Retail_Price__c - oldMap.get(oi.id).Total_Retail_Price__c;
				rCH.Subtype__c = 'Change';
			}
			//GET MOST RECENTLY CREATED CHANGE HISTORY			
			else {
				rCH = orderItemIdToListChangeHistory.get(oi.id)[0];
			}

			rCH.Responsible_Party__c = newMap.get(oi.id).Responsible_Party__c;
			rCH.RecordtypeId = UtilityMethods.RecordTypeFor('Change_History__c', 'Order_Product');
			rCH.Line_Processed_Date__c = System.today();
			rCH.Order_Booking_Date__c = oi.Order_Booking_Date__c;
			rCH.Order_Revenue_Recognition_Date__c = oi.Order_Revenue_Recognition_Date__c;

			Boolean somethingChanged = false;

			//JETT-2363 do not show updates to fields in change history, must be lowercase strings
			Set<String> fieldsToExclude = new Set<String>{'responsible_party__c','commission_amount__c','commission_due__c','total_retail_price__c',
															'availablequantity','listprice','createddate','createdbyid','lastmodifieddate','lastmodifiedbyid',
															'systemmodstamp','orderitemnumber','billable_amount__c'};
			//LOOP THROUGH ALL FIELDS AND DETERMINES IF THE OLD VALUE DIFFERENT THAN THE NEW VALUE
			for(String oiField : oiFieldsMap.KeySet()){ 
				string oldValue = string.valueOf(oldMap.get(oi.id).get(oiField));
				string newValue = string.valueOf(newMap.get(oi.id).get(oiField));
				string oiLabel = oiFieldsMap.get(oiField).getDescribe().getLabel();
				if(oldValue != newValue && !fieldsToExclude.contains(oiField)){
					somethingChanged = true;
					if(oldValue == null){
						oldValue = 'none'; 
					}
					if(newValue == null){
						newValue = 'none';
					}
					system.debug('ads oi: '+oi);
					system.debug('ads rCH: '+rCH);
					system.debug('ads oiField: '+oiField); 
					system.debug('ads oiLabel: '+oiLabel);
					system.debug('ads oldValue: '+oldValue);
					system.debug('ads newValue: '+newValue);
					
					//IF THAT FIELD HAS NOT BEEN CHANGED ALREADY
					if(rCH.Changes__c == null){
						rCH.Changes__c = '*'+oiLabel+'* : '+oldValue+' -> '+newValue+',';
					}else if(rCH.Changes__c.contains('*'+oiLabel+'*') == false){
						rCH.Changes__c = rCH.Changes__c+' *'+oiLabel+'* : '+oldValue+' -> '+newValue+',';
					}
					//IF THAT FIELD HAS BEEN CHANGED
					else if(rCH.Changes__c != null || rCH.Changes__c.contains('*'+oiLabel+'*') == true){
						
						
						string regex = '\\*'+oiLabel+'\\* :([\\s\\S]*?),';
						Matcher match = Pattern.compile(regex).matcher(rCH.Changes__c);
						system.debug('ads regex: '+regex);
						system.debug('ads rCH.Changes__c: '+rCH.Changes__c);
						match.find();
						string fieldsChangeHistory = match.group(0);
				
						system.debug('ads fieldsChangeHistory: ' + fieldsChangeHistory);
						String newFieldChangeHistory = fieldsChangeHistory.removeEnd(',') + ' -> '+newValue+',';
						rCH.Changes__c = rCH.Changes__c.replace(fieldsChangeHistory, newFieldChangeHistory);
					}
				}
			}
			if(somethingChanged == true && orderItemIdToListChangeHistory.get(oi.id) != null && orderItemIdToListChangeHistory.get(oi.id).size() != 0){
				rCH.Retail_Price__c = newMap.get(oi.id).Total_Retail_Price__c;
				
				Decimal newPrice = newMap.get(oi.id).Total_Retail_Price__c;
				Decimal oldPrice = oldMap.get(oi.id).Total_Retail_Price__c;
				if (newPrice == null) newPrice = 0;
				if (oldPrice == null) oldPrice = 0;
				if (rCH.Retail_Price_Change__c == null) rCH.Retail_Price_Change__c = 0;
				rCH.Retail_Price_Change__c = (newPrice - oldPrice) + rCH.Retail_Price_Change__c;
			}  
			changeHistoryToUpsert.add(rCH);	
		
			
	
		}
		upsert changeHistoryToUpsert;
	}
	
	
  /* @method: linkChildProducts(List<OrderItem> oiList)
   * @description: This method will find link Child Product pricebook entries to the line item
   *				for items created outside of rSuite so that rSuite can pull up the order correclty
   * @param: olLIst - List of OrderItems that need to have the child product line item linked
   * @return: void
   */
	public void linkNewChildProducts(List<OrderItem> oiList) {
		List<OrderItem> unlinkedOIList = new List<OrderItem>(); // list of orderitems to process
		Set<Id> masterProductPBEs = new Set<Id>(); // Set of pricebook entries ids to process
		Set<Id> ordersToProcess = new Set<Id>(); // list of orders that will be processed - used to find the Pricebooks
//		Set<Id> usedPriceBooks = new Set<Id>(); // set of pricebooks used with this group of orders
		//Only proceess items that are not already linked
		for (OrderItem oi : oiList) {
			if (oi.Child_Product_Pricebook_Entry_Id__c == null || oi.Child_Product_Pricebook_Entry_Id__c.equals('') &&
				oi.PricebookEntryId != null) {
				// add to list to process
				unlinkedOIList.add(oi);
				masterProductPBEs.add(oi.PricebookEntryId);
				ordersToProcess.add(oi.OrderId);
			}
		}
		// get the list of pricebooks used on orderitems we are going to process
//		Map<Id,AggregateResult> pricebookResults = new Map<Id,AggregateResult>([SELECT Pricebook2Id Id, COUNT(Id) orderCount FROM Order WHERE Id in :ordersToProcess group by Pricebook2Id]);
		// get the list of master product Ids
//		Map<Id,AggregateResult> masterProducts = new Map<Id,AggregateResult>([select Product2Id Id, count(Id) pbeCount from PricebookEntry where Id in :masterProductPBEs group by Product2Id]);
		// get the list of master product details via the PBE ids - not that te above query can be eliminated if we spin this list through and create a set instead
		Map<Id,PricebookEntry> masterProductsMap = new Map<Id,PricebookEntry>([select Id, Pricebook2Id, Product2Id, Product2.Family from PricebookEntry where Id in :masterProductPBEs]);
		Set<Id> masterProducts = new Set<Id>();
		Set<Id> pricebooks = new Set<Id>();
		for (PricebookEntry pbe : masterProductsMap.values()) {
			masterProducts.add(pbe.Product2Id);
			pricebooks.add(pbe.Pricebook2Id);
		}
		// get a list of child products from the pricebook entries for the master products
		List<PricebookEntry> childPBEs = [select Id, Product2Id, Pricebook2Id, 
			Product2.Name, 
			Product2.Master_Product__r.Name,
			Product2.Family,
			Product2.Master_Product__c,
			Product2.Master_Product__r.Master_Product__c,
			Product2.UI_Maximum__c,
			Product2.UI_Minimum__c,
			Product2.Height__c,
			Product2.Width__c 
			from PricebookEntry where
				(Product2.Master_Product__c in :masterProducts OR 
				Product2.Master_Product__r.Master_Product__c in :masterProducts)
//				(Product2.Master_Product__c in :masterProducts.keySet() OR 
//				Product2.Master_Product__r.Master_Product__c in :masterProducts.keySet())
				and
				Pricebook2Id in :pricebooks and 
//				Pricebook2Id in :pricebookResults.keySet() and 
				Product2.RecordType.DeveloperName = :Constants.CHILD_PRODUCT_RECORD_TYPE_NAME 
			order by Product2.Name ASC, Product2.UI_Minimum__c ASC, Product2.Height__c ASC];

		//add the child product pbes to the order line items
		for(OrderItem oi : unLinkedOIList) {
			// get the master product entry
			PricebookEntry masterProductPBE = masterProductsMap.get(oi.PricebookEntryId);
			Double unitedInches = null;
			Double height = null;
			Double width = null;
			if (!masterProductPBE.Product2.Family.equals(Constants.PF_PATIO_DOOR)) {
				// we have a window, specialty window or mullion get the united inches
				unitedInches = getUnitedInches(oi, masterProductPBE.Product2.Family);
			} else {
				// converst the door measurements
				if (oi.Height_Inches__c == null) {
					// uses sales measurements
					height = getCombinedMeasurement(oi.Sales_Height_Inches__c, oi.Sales_Height_Fraction__c);
					width = getCombinedMeasurement(oi.Sales_Width_Inches__c, oi.Sales_Width_Fraction__c);
				} else {
					// use the detail measurements
					height = getCombinedMeasurement(oi.Height_Inches__c, oi.Height_Fraction__c);
					width = getCombinedMeasurement(oi.Width_Inches__c, oi.Width_Fraction__c);
				}
			}
			// now match it to the correct child product
			for (PricebookEntry cPBE : childPBEs) {
				// need to match
				// 1. Pricebook Id
				// 2. Master Product or Master_Product__r.Master_Product for specialty windows - family
				// 3. size bucket (UI for windows and Specialty) - width and height for door
				// 4. mullions are different only need to match on pricebook and master product they are one to one
				// check the pricebook
				if (!cPBE.Pricebook2Id.equals(masterProductPBE.Pricebook2Id)) {
					// no match get the next record
					break;
				}
				// check the master product
				if (masterProductPBE.Product2.Family.equals(Constants.PF_SPECIALTY)) {
					if(cPBE.Product2.Master_Product__r.Master_Product__c == null || 
						!masterProductPBE.Product2Id.equals(cPBE.Product2.Master_Product__r.Master_Product__c)) {
						// no match get the next record
						break;
					}
				} else if (!masterProductPBE.Product2Id.equals(cPBE.Product2.Master_Product__c)) {
					// no match get the next record
					break;
				}
				// match on the size
				if (masterProductPBE.Product2.Family.equals(Constants.PF_PATIO_DOOR)) {
					//match doors on height and width
					if (cPBE.Product2.Height__c == height && cPBE.Product2.Width__c == width) {
						// we found a match assign the value to the order item
						oi.Child_Product_Pricebook_Entry_Id__c = cPBE.Id;
					} else {
						// no match get the next record
						break; 
					}
				} else {
					// match windows and specialty on UI  ?? how are we handling mullions?
					if ( unitedInches >= cPBE.Product2.UI_Minimum__c && unitedInches <= cPBE.Product2.UI_Maximum__c) {
						// we found a match assign the value to the order item
						oi.Child_Product_Pricebook_Entry_Id__c = cPBE.Id;
					} else {
						// no match get the next record
						break; 
					}
				}
			}
		}
	}
	
//TODO		// handle changes where the measurement changes
  /* @method: updateLinkedChildProducts(List<OrderItem> newOIList, List<OrderItem> oldOIList)
   * @description: blah blah blah
   * @param: newOIList - blah blah blah
   * @param: oldOIList - blah blah blah
   * @return: void
   */
	public void updateLinkedChildProducts(List<OrderItem> newOIList, List<OrderItem> oldOIList) {
	}
	
  /* @method: getUnitedInches(OrderItem myOI, String family)
   * @description: calculates united inches for windows, specialty windows and mullions
   * @param: myOI - orderItem to calculate united inches for
   * @param: family - orderItem product family
   * @return: Double - the calculated united inches
   */
	@TestVisible private Double getUnitedInches(OrderItem myOI, String family) {
		// convert the fractions to doubles
		// use the tech measure height and width if available otherwise use the sales measurements
		// not going to check the opportunity stage to avoid making a soql call
		Double height, width;
		if (family.equals(Constants.PF_WINDOW)) {
			// processs window united inches
			if (myOI.Height_Inches__c == null) {
				// uses sales measurements
				height = getCombinedMeasurement(myOI.Sales_Height_Inches__c, myOI.Sales_Height_Fraction__c);
				width = getCombinedMeasurement(myOI.Sales_Width_Inches__c, myOI.Sales_Width_Fraction__c);
			} else {
				// use the detail measurements
				height = getCombinedMeasurement(myOI.Height_Inches__c, myOI.Height_Fraction__c);
				width = getCombinedMeasurement(myOI.Width_Inches__c, myOI.Width_Fraction__c);
			}
			return height + width;
		} else if (family.equals(Constants.PF_SPECIALTY)){
			//process specialty windows
			//specialty winodw united inches is calculated by making a rectatangle around the shape and then use that to calculate the United inches
			//triangle/right triangle = base + height
			//circle = diameter + diameter
			//quarter cirlce = radius + raduis
			//chord - base + height
			//circle top
			//octogon
			//hexagon
			//peak pentagon, pentagon
			//trapezoid
			//unequal leg arch
			//equal leg arch
			//half springline
			//springline

			return -1.0d;
		} else {
			// process mullions
			//TODO:
			return -1.0d;
		}
	}

  /* @method: getCombinedMeasurement(String wholeInch, String fraction)
   * @description: creates a combined measurement from string whole inch and a string fraction and converts it to a double
   * @param: wholeInch - Decimal rep of a whole inch measurment
   * @param: fraction - string rep of a fraction measurment
   * @return: Double - double of the combined strings converted to a double
   */
	@TestVisible private Double getCombinedMeasurement(Decimal wholeInch, String fraction) {
		Double value = wholeInch + ((Constants.fractionConversionMap.containsKey(fraction)) ? Constants.fractionConversionMap.get(fraction) : 0.0d);
		return value;
	}
}
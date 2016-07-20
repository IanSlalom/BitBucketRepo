@isTest
private class RMS_OrderTriggerHandlerTests {
    
    @testSetup static void setupData() {
        TestUtilityMethods utility = new TestUtilityMethods();
        
        utility.setUpConfigs();
        
        Account account1 = utility.createVendorAccount('Vendor Account 1 ');
        insert account1;

        Account account2 = new Account( Name = 'RbA',
                                        AccountNumber = '1234567890',
                                        Phone = '(763) 555-2000'
                                    );
        insert account2;

        Account dwelling = utility.createDwellingAccount('Dwelling Account');

        Account store = [SELECT Id from Account Where Name = '77 - Twin Cities, MN'];
        dwelling.Store_Location__c = store.Id;
        insert dwelling;

        
        Opportunity opp1 = utility.createOpportunity(dwelling.id, 'Closed - Won');
        insert opp1;
    
        //Store_Configuration__c stconfig = new Store_Configuration__c(Store__c = store.Id);
        //insert stconfig;
        
        Financial_Account_Number__c fan = new Financial_Account_Number__c(Name ='Finan Acc');
        insert fan;
        Product2 product1 = new Product2(
            Name='Test Product',
            Vendor__c = account1.id,
            Cost_PO__c = true,
            isActive = true,
            Account_Number__c =  fan.Id
        );
        
        insert product1;
        
        PricebookEntry pricebookEntry1 = utility.createPricebookEntry(Test.getStandardPricebookId(), product1.id);
        insert pricebookEntry1;
        
        List<Order> orderList =  new List<Order>{ new Order(    Name='TMNeeded', 
                                    AccountId = dwelling.id, 
                                    EffectiveDate= Date.Today(), 
                                    Store_Location__c = store.Id,
                                    Opportunity = opp1,                                 
                                    Status ='Draft', 
                                    Tech_Measure_Status__c = 'New',
                                    Pricebook2Id = Test.getStandardPricebookId()
                                ),  new Order(  Name='TMScheduled', 
                                    AccountId = dwelling.id, 
                                    EffectiveDate= Date.Today(), 
                                    Store_Location__c = store.Id,
                                    Opportunity = opp1,                                     
                                    Status ='Draft',
                                    Tech_Measure_Status__c = 'New', 
                                    Pricebook2Id = Test.getStandardPricebookId()
                                ),  new Order(Name='InstallScheduled', 
                                    AccountId = dwelling.id, 
                                    EffectiveDate= Date.Today(), 
                                    Store_Location__c = store.Id,
                                    Opportunity = opp1,                                     
                                    Status ='Draft', 
                                    Install_Order_Status__c = 'New',
                                    Pricebook2Id = Test.getStandardPricebookId()
                                ),  new Order(Name='InstallNeeded', 
                                    AccountId = dwelling.id, 
                                    EffectiveDate= Date.Today(), 
                                    Store_Location__c = store.Id,
                                    Opportunity = opp1,                                     
                                    Status ='Draft', 
                                    Install_Order_Status__c = 'New',
                                    Pricebook2Id = Test.getStandardPricebookId()
                                ),new Order(Name='ChangeOrder', 
                                    AccountId = dwelling.id, 
                                    EffectiveDate= Date.Today(), 
                                    Store_Location__c = store.Id,
                                    Opportunity = opp1,                                     
                                    Status ='Draft', 
                                    Install_Order_Status__c = 'New',
                                    Pricebook2Id = Test.getStandardPricebookId(),
                                    RecordTypeId = UtilityMethods.retrieveRecordTypeId('Change_Order', 'Order')
                                )};     
        insert orderList;

        List<OrderItem> oiList = new List<OrderItem>();
        for(Order o: orderList){
            oiList.add(new OrderItem(OrderId = o.Id, PricebookentryId = pricebookEntry1.Id, Quantity = 2, UnitPrice = 100 ));
        }
        insert oiList;
        
        //System.debug('OLIST' +  [Select Status, Tech_Measure_Status__c, Install_Order_Status__c, Apex_Context__C from Order]);
        
    }
    
    @isTest static void testUpdateOrderStatus() {

        Account dwelling = [Select Id from Account where Name = 'Dwelling Account'];
        /*List<Order> orderList = [Select Name, Status from Order where accountId =:dwelling.Id];
        for(Order o: orderList){
            //o.Apex_Context__c = true;
            if(o.Name == 'TMNeeded'){
                o.Status = 'Tech Measure Needed';
            }else if(o.Name == 'TMScheduled'){
                o.Status = 'Tech Measure Scheduled';
            }else if(o.Name == 'InstallScheduled'){
                o.Status = 'Install Scheduled';
            }else if(o.Name == 'InstallNeeded'){
                o.Status = 'Install Needed';
            }
        }
        update orderList;*/

        Map<Id,Order> oldMap = new Map<Id,Order>([Select Id, RecordTypeId, Name, Status, Tech_Measure_Status__c,Install_Order_Status__c from Order where accountId =: dwelling.Id]);
        
        
        Map<Id,Order> newMap = new Map<Id,Order>();
        for(Order o: oldMap.values()){
            Order clonedOrder = o.clone(true,true,false,false);
            if(o.Name == 'TMNeeded'){
                o.Status = 'Tech Measure Needed';
                clonedOrder.Status = 'Tech Measure Needed';
                clonedOrder.Tech_Measure_Status__c = 'Scheduled';
            }else if(o.Name == 'TMScheduled'){
                o.Status = 'Tech Measure Scheduled';
                clonedOrder.Status = 'Tech Measure Scheduled';
                clonedOrder.Tech_Measure_Status__c = 'Complete';
            }else if(o.Name == 'InstallNeeded'){
                o.Status = 'Install Needed';
                clonedOrder.Status = 'Install Needed';
                clonedOrder.Install_Order_Status__c = 'Scheduled';
            }else if(o.Name == 'InstallScheduled'){
                o.Status = 'Install Scheduled';
                clonedOrder.Status = 'Install Scheduled';
                clonedOrder.Install_Order_Status__c = 'Complete';
            }else if(o.Name == 'ChangeOrder'){
                clonedOrder.Revenue_Recognized_Date__c = System.Today();
            }
            
            newMap.put(o.Id, clonedOrder);
        }

        System.assertEquals(newMap.keySet().size(),oldMap.keySet().size());

        RMS_OrderTriggerHandler handler = new RMS_OrderTriggerHandler(false,200);
        handler.updateOrderStatus(oldMap, newMap);
        for(Order o: newMap.values()){
            if(o.Tech_Measure_Status__c == 'Scheduled'){
                System.assert(o.Status == 'Tech Measure Scheduled');
            }else if(o.Tech_Measure_Status__c == 'Complete'){
                System.assert(o.Status == 'Ready to Order');
            }else if(o.Install_Order_Status__c == 'Scheduled'){
                System.assert(o.Status == 'Install Scheduled');
            }/* removing per JETT-1601 else if(o.Install_Order_Status__c == 'Complete'){
                System.assert(o.Status == 'Install Complete');
            }*/else if(o.Name == 'ChangeOrder'){
                System.assert(o.Status == 'Job Closed');
            }
        }

/*

        //Used to verify the Apex Context field is set to false by workflow rule
        for(Order o: oldMap.values()){
            if(o.Status == 'Tech Measure Needed'){
                o.Tech_Measure_Status__c = 'Scheduled';
            }else if(o.Status == 'Tech Measure Scheduled'){
                o.Tech_Measure_Status__c = 'Complete';
            }else if(o.Status == 'Install Scheduled'){
                o.Install_Order_Status__c = 'Complete';
            }
        }
        update oldMap.values();
        List<Order> orderl = [Select Status, Tech_Measure_Status__c, Install_Order_Status__c, Apex_Context__C from Order];
        System.debug('ORDERS ' + orderl);*/
    }
    
    @isTest static void testUpdateTimeStamps() {
        Account dwelling = [Select Id from Account where Name = 'Dwelling Account'];
        Map<Id,Order> oldMap = new Map<Id,Order>([Select Id, Name, Status, Tech_Measure_Status__c,Install_Order_Status__c from Order where accountId =: dwelling.Id]);
        Map<Id,Order> newMap = new Map<Id,Order>();
        for(Order o: oldMap.values()){
            Order clonedOrder = o.clone(true,true,false,false);
            if(o.Name == 'TMNeeded'){
                clonedOrder.Status = 'Tech Measure Needed';
            }else if(o.Name == 'TMScheduled'){
                clonedOrder.Status = 'Tech Measure Scheduled';
            }else if(o.Name == 'InstallScheduled'){
                clonedOrder.Status = 'Install Scheduled';
            }else if(o.Name == 'InstallNeeded'){
                clonedOrder.Status = 'Install Needed';
            }
            newMap.put(o.Id, clonedOrder);
        }

        System.assertEquals(newMap.keySet().size(),oldMap.keySet().size());

        RMS_OrderTriggerHandler handler = new RMS_OrderTriggerHandler(false,200);
        handler.updateOrderTimeStamps(oldMap, newMap);
        for(Order o: newMap.values()){
            if(o.Status == 'Install Scheduled'){
                System.assert(o.Time_Install_Scheduled__c != null);
            }else if(o.Status == 'Install Needed'){
                System.assert(o.Time_Install_Needed__c != null);
            }else if(o.Status == 'Tech Measure Needed'){
                System.assert(o.Time_Tech_Measure_Needed__c != null);
            }else if(o.Status == 'Tech Measure Scheduled'){
                System.assert(o.Time_Tech_Measure_Scheduled__c != null);
            }
        }

        //Overwrite previous values of newMap to test for additional status timetamp fields
        for(Order o: oldMap.values()){
            Order clonedOrder = o.clone(true,true,false,false);
            if(o.Name == 'TMNeeded'){
                clonedOrder.Status = 'On Hold';
            }else if(o.Name == 'TMScheduled'){
                clonedOrder.Status = 'Ready to Order';
            }else if(o.Name == 'InstallScheduled'){
                clonedOrder.Status = 'Order Released';
            }else if(o.Name == 'InstallNeeded'){
                clonedOrder.Status = 'Install Complete';
            }
            newMap.put(o.Id, clonedOrder);
        }

        handler.updateOrderTimeStamps(oldMap, newMap);
        for(Order o: newMap.values()){
            if(o.Status == 'On Hold'){
                System.assert(o.Time_On_Hold__c != null);
            }else if(o.Status == 'Ready to Order'){
                System.assert(o.Time_Ready_to_Order__c != null);
            }else if(o.Status == 'Order Released'){
                System.assert(o.Time_Order_Released__c != null);
            }else if(o.Status == 'Install Complete'){
                System.assert(o.Time_Install_Complete__c != null);
            }
        }

        //Overwrite previous values of newMap to test for additional status timetamp fields
        for(Order o: oldMap.values()){
            Order clonedOrder = o.clone(true,true,false,false);
            if(o.Name == 'TMNeeded'){
                clonedOrder.Status = 'Job in Progress';
            }else if(o.Name == 'TMScheduled'){
                clonedOrder.Status = 'Job Closed';
            }else if(o.Name == 'InstallScheduled'){
                clonedOrder.Status = 'Cancelled';
            }else if(o.Name == 'InstallNeeded' || o.Name == 'ChangeOrder'){
                o.Status = 'On Hold';
                clonedOrder.Status = 'Draft';
            }
            newMap.put(o.Id, clonedOrder);
        }

        handler.updateOrderTimeStamps(oldMap, newMap);
        for(Order o: newMap.values()){
            if(o.Status == 'Job in Progress'){
                System.assert(o.Time_Job_In_Progress__c != null);
            }else if(o.Status == 'Job Closed'){
                System.assert(o.Time_Job_Close__c != null);
            }else if(o.Status == 'Cancelled'){
                System.assert(o.Time_Cancelled__c != null);
            }else if(o.Status == 'Draft'){
                System.assert(o.Time_Draft__c != null);
            }
        }
    }

    @isTest static void testUpdateJIPCOROServiceOrders() {
        // Turn off the financial trigger to avoid SOQL limits in test class
        RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
        insert turnOffFinancialTrigger;

        Account dwelling = [Select Id from Account where Name = 'Dwelling Account'];
        List<Order> soldOrder = [Select Id, Name, Status, Tech_Measure_Status__c,Install_Order_Status__c, Store_Location__c, OpportunityId from Order where accountId =: dwelling.Id 
                                                  and Name = 'InstallScheduled'];
        System.assertEquals(soldOrder.size(),1);
        
        Order newOrder = new Order(Sold_Order__c = soldOrder[0].Id,AccountId = dwelling.Id, Name = 'New Order',Store_Location__c = soldOrder[0].store_Location__c, EffectiveDate= Date.Today(), 
                                                    OpportunityId = soldOrder[0].OpportunityId, Status = 'Draft', recordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order'),
                                                    Service_Type__c = 'Job in Progress' );
        insert newOrder;
        Test.startTest();
        soldOrder[0].Status = 'Install Scheduled';
        update soldOrder[0];
        RMS_OrderTriggerHandler handler = new RMS_OrderTriggerHandler(false,200);
        handler.updateJIPCOROServiceOrders(new List<Order>{newOrder});
        newOrder = [Select Id, Status from Order where Id =: newOrder.Id];
        system.assertEquals(newOrder.Status, 'Job in Progress');
        Test.stopTest();
    }

    @isTest static void testUpdateRevenueRecDate(){
        // Turn off the financial trigger to avoid SOQL limits in test class
        RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
        insert turnOffFinancialTrigger;

        Account dwelling = [Select Id from Account where Name = 'Dwelling Account'];
        List<Order> soldOrder = [Select Id, Name, Status, Tech_Measure_Status__c,Install_Order_Status__c, Store_Location__c, OpportunityId from Order where accountId =: dwelling.Id 
                                                  and Name = 'InstallScheduled'];
        System.assertEquals(soldOrder.size(),1);
        
        Order newOrder = new Order(Sold_Order__c = soldOrder[0].Id,AccountId = dwelling.Id, Name = 'New Order',Store_Location__c = soldOrder[0].store_Location__c, EffectiveDate= Date.Today(), 
                                                    OpportunityId = soldOrder[0].OpportunityId, Status = 'Draft', recordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order'),
                                                    Service_Type__c = 'Job in Progress',Pricebook2Id = Test.getStandardPricebookId() );
        insert newOrder;
        List<PricebookEntry> pbeList = [Select Id from PricebookEntry];
        OrderItem oi = new OrderItem(OrderId = newOrder.Id, PricebookentryId = pbeList[0].Id, Quantity = 2, UnitPrice = 100, 
            Quote_Accepted__c = true, Billable_Amount__c = 2);
        Test.startTest();
        insert oi;
        newOrder.Status = 'Closed';
        update newOrder;
        newOrder = [Select Revenue_Recognized_Date__c from Order where Id =: newOrder.Id];
        System.assertEquals(newOrder.Revenue_Recognized_Date__c, System.Today());
        Test.stopTest();    
    }

    @isTest static void testCreateOnHoldTasks(){
        Account dwelling = [Select Id from Account where Name = 'Dwelling Account'];
        List<Order> soldOrder = [Select Id, Name, Status, Tech_Measure_Status__c,Install_Order_Status__c, Store_Location__c, OpportunityId, OwnerId
                                 from Order where accountId =: dwelling.Id 
                                                  and Name = 'InstallScheduled'];
        System.assertEquals(soldOrder.size(),1);

        Test.startTest();
        soldOrder[0].Status = 'On Hold';
        update soldOrder;
        List<Task> onHoldTasks = [Select Id, WhatId, OwnerId, recordTypeId from Task Where WhatId =: soldOrder[0].Id];
        System.assertEquals(onHoldTasks.size(),1);
        System.assertEquals(onHoldTasks[0].OwnerId, soldOrder[0].OwnerId);
        System.assertEquals(onHoldTasks[0].recordTypeId, UtilityMethods.retrieveRecordTypeId('On_Hold', 'Task'));
        Test.stopTest();
    }

    @isTest static void testUpdateUniqueIdentifier(){
        // Turn off the financial trigger to avoid SOQL limits in test class
        RMS_Settings__c turnOffFinancialTrigger = new RMS_Settings__c(Name='Turn Financial Transactions Off', Value__c = 'Yes');
        insert turnOffFinancialTrigger;

        Account store = [SELECT Id, Store_Number__c, Active_Store_Configuration__r.Order_Number__c from Account Where Name = '77 - Twin Cities, MN'];
        Decimal orderNumBeforeUpdate = store.Active_Store_Configuration__r.Order_Number__c; 
        System.assertNotEquals(store.Store_Number__c, null);
        System.assertNotEquals(store.Active_Store_Configuration__r.Order_Number__c, null);
        Account dwelling = [Select Id from Account where Name = 'Dwelling Account'];
        List<Order> soldOrder = [Select Id, Name, Status, Tech_Measure_Status__c,Install_Order_Status__c, Store_Location__c, OpportunityId, OwnerId
                                 from Order where accountId =: dwelling.Id 
                                                  and Name = 'InstallScheduled'];
        System.assertEquals(soldOrder.size(),1);

        Order newOrder = new Order(Sold_Order__c = soldOrder[0].Id,AccountId = dwelling.Id, Name = 'New Order',Store_Location__c = soldOrder[0].store_Location__c, EffectiveDate= Date.Today(), 
                                                    OpportunityId = soldOrder[0].OpportunityId, Status = 'Draft', recordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Record_Type', 'Order'),
                                                    Service_Type__c = 'Draft' );
        Order newOrder2 = new Order(Sold_Order__c = soldOrder[0].Id,AccountId = dwelling.Id, Name = 'New Order',Store_Location__c = soldOrder[0].store_Location__c, EffectiveDate= Date.Today(), 
                                                    OpportunityId = soldOrder[0].OpportunityId, Status = 'Draft', recordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Record_Type', 'Order'),
                                                    Service_Type__c = 'Draft' );
        List<Order> oList = new List<Order>{newOrder,newOrder2};
        Test.startTest();
        insert oList;
        newOrder.Status = 'Ready to Order';
        newOrder2.Status = 'Ready to Order';
        update oList;
        oList= [Select Id, Unique_Identifier__c, Status from Order where Id in: oList];
        String uniqueIDString = store.Store_Number__c + store.Active_Store_Configuration__r.Order_Number__c.toPlainString();
        while(uniqueIdString.length() < 11){
          uniqueIdString = uniqueIdString.substring(0,4) + '0' + uniqueIdString.substring(4);
        }
       
        String uniqueIDString2 = store.Store_Number__c + (store.Active_Store_Configuration__r.Order_Number__c + 1).toPlainString();
        while(uniqueIdString2.length() < 11){
          uniqueIdString2 = uniqueIdString2.substring(0,4) + '0' + uniqueIdString2.substring(4);
        }

        for(Order o: oList){
            System.debug('UNIQUE ID' + o.Unique_Identifier__c);
            system.debug(uniqueIdString);
            system.debug(uniqueIdString2);
            System.assert(o.Unique_Identifier__c == uniqueIdString || o.Unique_Identifier__c == uniqueIdString2 );
        }

        store = [SELECT Id, Store_Number__c, Active_Store_Configuration__r.Order_Number__c from Account Where Name = '77 - Twin Cities, MN'];
        System.assertEquals(store.Active_Store_Configuration__r.Order_Number__c, orderNumBeforeUpdate + oList.size());
        Test.stopTest();
        
    }

     @isTest static void testSetPriceBookId(){
        Account dwelling = [Select Id from Account where Name = 'Dwelling Account'];
        Account store = [SELECT Id, Store_Number__c, Active_Store_Configuration__r.Order_Number__c from Account Where Name = '77 - Twin Cities, MN'];
        List<Order> soldOrder = [Select Id, Name, Pricebook2Id, Status, Tech_Measure_Status__c,Install_Order_Status__c, Store_Location__c, OpportunityId, OwnerId
                                 from Order where Name = 'InstallScheduled'];
        System.assertEquals(soldOrder[0].Pricebook2Id, Test.getStandardPricebookId());

        Test.startTest();
        Order changeOrder = new Order(Name = 'Change', Sold_Order__c = soldOrder[0].Id, 
                                    AccountId = dwelling.Id, Store_Location__c = store.Id,EffectiveDate= Date.Today(), Status = 'Draft');
        insert changeOrder;
        Test.stopTest();
        changeOrder = [Select Id, Pricebook2Id from Order where Id =: changeOrder.Id];
        System.assertEquals(changeOrder.Pricebook2Id, soldOrder[0].Pricebook2Id);
       
    }
}
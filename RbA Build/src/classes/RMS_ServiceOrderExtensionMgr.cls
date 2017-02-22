/*******************************************************//**

@class  RMS_ServiceOrderExtensionMgr

@brief  code for driving the create service request process. This controller
is used for RMS_createServiceRequestRedirect, RMS_createServiceOrderP1, and 
RMS_createServiceOrderP2. Note that there is a separate controller for the 
case where the Account is legacy and does not have any Asset records.

@author  Brianne Wilson (Slalom.BLW)

@version    2016-4-19  Slalom.BLW
Created.


Unauthorized use is prohibited.

***********************************************************/
public with sharing class RMS_ServiceOrderExtensionMgr  {
    
    public final Order o;   
    public integer num_orders;
    public integer num_assets;
    public integer sales_tax;
    public list<OrderItem > listOI{ get; set; }  
    public Integer invalidRequest;
    public List<Service_Product__c> serviceProducts {
        get{
            system.debug('***** '+ serviceProducts);
            if(serviceProducts == null){
                serviceProducts = [SELECT Id, Name, Master_Product__c,
                                    Service_Product__c, Service_Product__r.Name
                                    FROM Service_Product__c
                                    WHERE Master_Product__c in: assetIdToProductIdMap.values()
                                    ORDER BY Name];                 
            } 
            return serviceProducts;
        }
        set;
    }
    public List<Asset> selectedAssets {
         get{
            system.debug('******** selectedAssets ' + selectedAssets);
            if (selectedAssets ==  null){
                selectedAssets = [SELECT Id, Name, Product_Name__c, Install_Date__c,
                          Product2Id, Variant_Number__c, Product2.Name, Original_Order_Variant_Number__c, 
                          Location_Details__c, Original_Order_Product__c, Status
                          FROM Asset 
                          WHERE Id = :assetIds
                          AND Status != 'Replaced'
                          ORDER BY Name];
            }  
            return selectedAssets;            
        }
        set;
    }
    public Id masterProductId = UtilityMethods.GetRecordTypeIdsMapForSObject(Product2.sObjectType).get('Master_Product');    
    public Map<Id,List<ProductWrapper>> AssetToProductWrapperMap{get;set;} //transient   
    public Boolean hasValidationErrors {
        get{
            return ApexPages.hasMessages(ApexPages.Severity.ERROR);
        }
    }
    public String baseURL{get;set;}
    public String cancelUpdateURL{get;set;}
    public string propPickValSelected2 { get; set; }
    public String updateSTURL{get;set;}
    public String editRedirect{get;set;}
    public List<OrderItem> allAccs {get; set;}
    public List<GroupWrapper> groups {get; set;}
    public String groupFieldName {get; set;}
    public List<SelectOption> groupOptions {get; set;}
    public List<Charge__c> charges {get; set;}
    public list<OrderItem> listOILegacy{ get; set; }  
    private static List<id> productIds{
        get{
            system.debug('****** '+ productIds);
            if (productIds == null){
                productIds = new List<id>();
                for(Product2 p : [SELECT Id,Has_Service_Products__c
                                  FROM Product2 
                                  WHERE Has_Service_Products__c = TRUE]){
                    productIds.add(p.id);
                } 
            }
            return productIds;
        }
        set;
    }  //transient
    public Map<Id, String> selectedProductsLegacy {
        get{
            if(selectedProductsLegacy == null){
                selectedProductsLegacy = new Map<Id,String>();
                List<Product2> listselectedProductsLegacy = [SELECT Id, Name
                                          FROM Product2
                                          WHERE Id IN: productIds
                                          ORDER BY Name
                                          LIMIT 100];
                                          for (Product2 p:listselectedProductsLegacy){
                                            selectedProductsLegacy.put(p.Id, p.Name);
                                          }
            }  
            return selectedProductsLegacy;                    
        }
        set;
    } //transient
    private List<Service_Product__c> serviceProductsLegacy {
        get{
            if (serviceProductsLegacy == null ){
                serviceProductsLegacy = new List<Service_Product__c>();
                serviceProductsLegacy = [SELECT    Id, Name, Master_Product__c,
                  Service_Product__c, Service_Product__r.Name
                  FROM Service_Product__c
                  WHERE Master_Product__c in: selectedProductsLegacy.keySet()
                  ORDER BY Name];
            }
            return serviceProductsLegacy;
           }
        set;
    }
    public Map<Id,List<ProductWrapper2>> ProductToProductWrapperMapLegacy{
        get{
            if (ProductToProductWrapperMapLegacy == null && masterProductToProductWrapperMapLegacy != null){
                ProductToProductWrapperMapLegacy = new Map<Id, List<ProductWrapper2>>();
                integer i=1;
                for(Id p: selectedProductsLegacy.keySet()){
                    if(masterProductToProductWrapperMapLegacy.containsKey(p)){
                        ProductToProductWrapperMapLegacy.put(p,masterProductToProductWrapperMapLegacy.get(p).clone());
                    }else{
                        ProductToProductWrapperMapLegacy.put(p, new List<ProductWrapper2>());
                    }

                    i=i+1;
                    system.debug('incrementing counter  ProductToProductWrapperMapLegacy '+ i);
                    if(i>100){
                        //break;
                    }
                }
            } 
            return ProductToProductWrapperMapLegacy;
        }
        set;
    } //transient
    public Map<Id,List<ProductWrapper2>> masterProductToProductWrapperMapLegacy{
        get{
            if (masterProductToProductWrapperMapLegacy == null){
                masterProductToProductWrapperMapLegacy = new Map<Id,List<ProductWrapper2>>();
                integer i=1;
                for(Service_Product__c prod: [SELECT Id, Name, Master_Product__c,
                                              Service_Product__c, Service_Product__r.Name
                                              FROM Service_Product__c
                                              WHERE Master_Product__c in: selectedProductsLegacy.keySet()
                                              ORDER BY Name]){

                    if(masterProductToProductWrapperMapLegacy.containsKey(prod.Master_Product__c)){
                        masterProductToProductWrapperMapLegacy.get(prod.Master_Product__c).add(new ProductWrapper2(prod));
                    }else{
                        masterProductToProductWrapperMapLegacy.put(prod.Master_Product__c,new List<ProductWrapper2>{new ProductWrapper2(prod)});
                    }

                    i=i+1;
                    system.debug('incrementing counter masterProductToProductWrapperMapLegacy '+ i);
                    if(i>100){
                        //break;
                    }
                }
            }
        return masterProductToProductWrapperMapLegacy;
        }
        set;
    } //transient
    public Map<Id,List<ProductWrapper>> masterProductToProductWrapperMap{
        get{
            if (masterProductToProductWrapperMap == null){
                masterProductToProductWrapperMap = new Map<Id,List<ProductWrapper>>();
                integer i=1;
                for(Service_Product__c prod: serviceProducts){
                    if(masterProductToProductWrapperMap.containsKey(prod.Master_Product__c)){
                        masterProductToProductWrapperMap.get(prod.Master_Product__c).add(new ProductWrapper(prod));
                    }else{
                        masterProductToProductWrapperMap.put(prod.Master_Product__c,new List<ProductWrapper>{new ProductWrapper(prod)});
                    }

                    i=i+1;
                    system.debug('incrementing counter masterProductToProductWrapperMap '+ i);
                    if(i>100){
                        //break;
                    }
                }
            }
            return masterProductToProductWrapperMap;
        }
        set;
    } //transient
    public Map<Id,Id> assetIdToProductIdMap{
        get{
            if (assetIdToProductIdMap == null){
                assetIdToProductIdMap = new Map<Id,Id>();
                system.debug('******* ' + assetIdToProductIdMap);
                for(Asset a: [SELECT    Id, Name, Product_Name__c, Install_Date__c,
                              Product2Id, Variant_Number__c, Product2.Name, 
                              Original_Order_Variant_Number__c, Location_Details__c, 
                              Original_Order_Product__c, Status
                              FROM Asset 
                              WHERE Id = :assetIds
                              AND Status != 'Replaced'
                              ORDER BY Name]){
                    assetIdToProductIdMap.put(a.Id, a.Product2Id);
                }
                system.debug('******* assetIdToProductIdMap ' + assetIdToProductIdMap);
            } 
            return assetIdToProductIdMap;
        }
        set;
    } //transient
    public List<id> assetIds{
        get{
            system.debug('******* in getassetIds()');
            system.debug('******* in o.AccountId '+ o.AccountId);
            if (assetIds == null){
                system.debug('******* assetIds = was null ' + o.AccountId);
                assetIds = new List<id>();
                for(Asset a : [SELECT Id,Product2.RecordTypeId,Product2.Has_Service_Products__c
                               FROM Asset 
                               WHERE AccountId = :o.AccountId
                               AND Product2.Has_Service_Products__c = TRUE]){
                                   assetIds.add(a.id);
                } 
            }
            system.debug('******* in getassetIds() ' + assetIds);
            return assetIds;
        }
        set;
    } //transient
    
    public RMS_ServiceOrderExtensionMgr(ApexPages.StandardController stdController) {
        if(!test.isRunningTest()){
            stdController.addFields(new List<String>{'AccountId','PriceBook2Id','Service_Type__c','Id'});           
        }
        
        this.o = (Order)stdController.getRecord();
        propPickValSelected2 = o.Service_Type__c;
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        cancelUpdateURL = '/' + o.Id;
        updateSTURL = '/apex/RMS_updateServiceType?id=' + o.Id;
        editRedirect ='/apex/RMS_editServiceRequest?id='+o.Id;
        
        //these aggregate result lists are used to count the number of Orders 
        //and assets for the related Account to determine where the user is taken
        //on the redirect page --> P1 or Legacy P1
        
        List<AggregateResult> results=[select COUNT (Id) 
                                       FROM Order 
                                       WHERE AccountId = :aid 
                                       AND RecordTypeId = :rt];
        num_orders = (Integer) results[0].get('expr0');
        
        List<AggregateResult> results2=[select COUNT (Id) 
                                        FROM Asset 
                                        WHERE AccountId = :aid];
        num_assets = (Integer) results2[0].get('expr0');
        
        listOI = new list<OrderItem>();
        system.debug('****** ApexPages.currentPage().getParameters().get(Id) ' + ApexPages.currentPage().getParameters().get('Id'));
        allAccs = [select id, OrderId, Product_Name__c,Installed_Product_Name__c,
                 (select id, Charge_Cost_To__c, Category__c, What_Where__c, Service_Product__c, Service_Request__c from Charges__r)
                 from OrderItem
                 where OrderId =: o.Id];
        system.debug('*******  allAccs ' +allAccs);         
        //ApexPages.currentPage().getParameters().get('Id')         
        
        groupFieldName = 'Installed_Product_Name__c';
        
        setupGrouping();
        groupOptions = new List<SelectOption>();
        groupOptions.add(new SelectOption('Installed_Product_Name__c', 'Installed_Product_Name__c'));
        listOILegacy = new list<OrderItem>();
        //finding the Assets of the related Account to populate on P2 list
        //code then finds the products for each of the Assets and then
        //displays the Service Products for each Product availble to select
        //for the Service Request
        //assetIds = new List<id>();
        //for(Asset a : [SELECT Id,Product2.RecordTypeId,Product2.Has_Service_Products__c
        //               FROM Asset 
        //               WHERE AccountId = :o.AccountId
        //               AND Product2.Has_Service_Products__c = TRUE]){
        //                   assetIds.add(a.id);
        //}        
        //selectedAssets = [SELECT Id, Name, Product_Name__c, Install_Date__c,
        //                  Product2Id, Variant_Number__c, Product2.Name, Original_Order_Variant_Number__c, 
        //                  Location_Details__c, Original_Order_Product__c, Status
        //                  FROM Asset 
        //                  WHERE Id = :assetIds
        //                  AND Status != 'Replaced'
        //                  ORDER BY Name];
        
        ////Mapping Assets to Products, grabbing ids
        //assetIdToProductIdMap = new Map<Id,Id>();
        //for(Asset a: selectedAssets){
        //    assetIdToProductIdMap.put(a.Id,a.Product2Id);
        //}
        //serviceProducts = [SELECT    Id,
        //                                            Name,
        //                                            Master_Product__c,
        //                                            Service_Product__c,
        //                                            Service_Product__r.Name
        //                                            FROM Service_Product__c
        //                                            WHERE Master_Product__c in: assetIdToProductIdMap.values()
        //                                            ORDER BY Name];

        //masterProductToProductWrapperMap = new Map<Id,List<ProductWrapper>>();
        //for(Service_Product__c prod: serviceProducts){
        //    if(masterProductToProductWrapperMap.containsKey(prod.Master_Product__c)){
        //        masterProductToProductWrapperMap.get(prod.Master_Product__c).add(new ProductWrapper(prod));
        //    }else{
        //        masterProductToProductWrapperMap.put(prod.Master_Product__c,new List<ProductWrapper>{new ProductWrapper(prod)});
        //    }
        //}
        
        
        AssetToProductWrapperMap = new Map<Id, List<ProductWrapper>>();
        for(Asset a: selectedAssets){
            if(masterProductToProductWrapperMap.containsKey(a.Product2Id)){
                List<ProductWrapper> wrapperList = new List<ProductWrapper>();
                for(ProductWrapper wrap: masterProductToProductWrapperMap.get(a.Product2Id)){
                    wrapperList.add(new ProductWrapper(wrap.product));
                }
                AssetToProductWrapperMap.put(a.Id,wrapperList);
            }else{
                AssetToProductWrapperMap.put(a.Id, new List<ProductWrapper>());
            }
        }
        system.debug(AssetToProductWrapperMap);
        
        
        //productIds = new List<id>();
        //for(Product2 p : [SELECT    Id,Has_Service_Products__c
        //                  FROM Product2 
        //                  WHERE Has_Service_Products__c = TRUE]){
        //                      productIds.add(p.id);
        //                  }        
        //selectedProductsLegacy = [SELECT Id, 
        //                          Name
        //                          FROM Product2
        //                          WHERE Id IN: productIds
        //                          ORDER BY Name];
        
        assetIdToProductIdMap = new Map<Id,Id>();
        for(Asset a: selectedAssets){
            assetIdToProductIdMap.put(a.Id,a.Product2Id);
        }
        
        //serviceProductsLegacy = [SELECT    Id, Name, Master_Product__c,
        //                      Service_Product__c, Service_Product__r.Name
        //                      FROM Service_Product__c
        //                      WHERE Master_Product__c in: selectedProductsLegacy.keySet()
        //                      ORDER BY Name];
        
    } 
    //public List<OrderItem> getallAccs(){
    //    if (allAccs == null){
    //        allAccs = [select id, OrderId, Product_Name__c,Installed_Product_Name__c,
    //         (select id, Charge_Cost_To__c, Category__c, What_Where__c, Service_Product__c, Service_Request__c from Charges__r)
    //         from OrderItem
    //         where OrderId =:ApexPages.currentPage().getParameters().get('Id')];
    //        return allAccs;
    //     } else {
    //        return allAccs;
    //     }
    //}
    //public List<Asset> getselectedAssets(){
    //    system.debug('********** in getselectedAssets ');
    //    if (selectedAssets == null){
    //        system.debug('********** assetIds ' + assetIds);
    //        selectedAssets = [SELECT Id, Name, Product_Name__c, Install_Date__c, Product2Id,
    //              Variant_Number__c,Product2.Name, Original_Order_Variant_Number__c, 
    //              Location_Details__c, Original_Order_Product__c, Status
    //              FROM Asset 
    //              WHERE Id = :assetIds
    //              AND Status != 'Replaced'
    //              ORDER BY Name];
    //        return selectedAssets;
    //    } else {
    //        return selectedAssets;
    //    }
    //}
    //public List<id> getAssetIds(){
    //    system.debug('******* in getassetIds()');
    //    system.debug('******* in o.AccountId '+ o.AccountId);
    //    if (assetIds == null){
    //        system.debug('******* ' + o.AccountId);
    //        assetIds = new List<id>();
    //        for(Asset a : [SELECT Id,Product2.RecordTypeId,Product2.Has_Service_Products__c
    //                       FROM Asset 
    //                       WHERE AccountId = :o.AccountId
    //                       AND Product2.Has_Service_Products__c = TRUE]){
    //                           assetIds.add(a.id);
    //        } 
    //        return assetIds;
    //    } else {
    //        return assetIds;
    //    }
    //}

    //public List<Service_Product__c> getserviceProducts(){
    //    if (serviceProducts == null){
    //        serviceProducts = [SELECT Id, Name, Master_Product__c,
    //                            Service_Product__c, Service_Product__r.Name
    //                            FROM Service_Product__c
    //                            WHERE Master_Product__c in: assetIdToProductIdMap.values()
    //                            ORDER BY Name];                      
    //    }
    //    return serviceProducts;
    //}
    //public Map<Id,Id> getassetIdToProductIdMap(){
        
    //    if (assetIdToProductIdMap == null){
    //        assetIdToProductIdMap = new Map<Id,Id>();
    //        for(Asset a: [SELECT    Id,
    //                          Name,
    //                          Product_Name__c, 
    //                          Install_Date__c,
    //                          Product2Id,
    //                          Variant_Number__c,
    //                          Product2.Name, 
    //                          Original_Order_Variant_Number__c, 
    //                          Location_Details__c,
    //                          Original_Order_Product__c,
    //                          Status
    //                          FROM Asset 
    //                          WHERE Id = :assetIds
    //                          AND Status != 'Replaced'
    //                          ORDER BY Name]){
    //            assetIdToProductIdMap.put(a.Id, a.Product2Id);
    //        }
    //        return assetIdToProductIdMap;
    //    } else {
    //        return assetIdToProductIdMap;
    //    }
    //}
    public Map<Id,List<ProductWrapper>> getmasterProductToProductWrapperMap(){
        if (masterProductToProductWrapperMap == null){
            masterProductToProductWrapperMap = new Map<Id,List<ProductWrapper>>();
            for(Service_Product__c prod: serviceProducts){
                if(masterProductToProductWrapperMap.containsKey(prod.Master_Product__c)){
                    masterProductToProductWrapperMap.get(prod.Master_Product__c).add(new ProductWrapper(prod));
                }else{
                    masterProductToProductWrapperMap.put(prod.Master_Product__c,new List<ProductWrapper>{new ProductWrapper(prod)});
                }
            }
        }
        return masterProductToProductWrapperMap;

    }
    //public Map<Id, List<ProductWrapper>> getAssetToProductWrapperMap(){
    //    if (AssetToProductWrapperMap == null){
    //        AssetToProductWrapperMap = new Map<Id, List<ProductWrapper>>();
    //        system.debug('****** selectedAssets '+ selectedAssets);
    //        for(Asset a: selectedAssets){
    //            if(masterProductToProductWrapperMap.containsKey(a.Product2Id)){
    //                List<ProductWrapper> wrapperList = new List<ProductWrapper>();
    //                for(ProductWrapper wrap: masterProductToProductWrapperMap.get(a.Product2Id)){
    //                    wrapperList.add(new ProductWrapper(wrap.product));
    //                }
    //                AssetToProductWrapperMap.put(a.Id,wrapperList);
    //            }else{
    //                AssetToProductWrapperMap.put(a.Id, new List<ProductWrapper>());
    //            }
    //        }
    //    } 
    //    system.debug('******** AssetToProductWrapperMap '+ AssetToProductWrapperMap);
    //    return AssetToProductWrapperMap;
    //}
    //public List<id> getproductIds(){
    //    if (productIds == null){
    //        productIds = new List<id>();
    //        for(Product2 p : [SELECT    Id,Has_Service_Products__c FROM Product2 
    //                          WHERE Has_Service_Products__c = TRUE]){
    //            productIds.add(p.id);
    //        } 
    //    } 
    //    return productIds;                   
    //}

    //public List<Product2> getselectedProductsLegacy(){
    //    if (selectedProductsLegacy == null){
    //        selectedProductsLegacy = [SELECT Id, 
    //                      Name
    //                      FROM Product2
    //                      WHERE Id IN: productIds
    //                      ORDER BY Name];
    //    }
    //    return selectedProductsLegacy;
    //}

    //public Map<Id,List<ProductWrapper2>> getmasterProductToProductWrapperMapLegacy(){
    //    if (masterProductToProductWrapperMapLegacy == null){
    //        masterProductToProductWrapperMapLegacy = new Map<Id,List<ProductWrapper2>>();
    //        for(Service_Product__c prod: [SELECT    Id,
    //                                      Name,
    //                                      Master_Product__c,
    //                                      Service_Product__c,
    //                                      Service_Product__r.Name
    //                                      FROM Service_Product__c
    //                                      WHERE Master_Product__c in: selectedProductsLegacy
    //                                      ORDER BY Name]){
    //            if(masterProductToProductWrapperMapLegacy.containsKey(prod.Master_Product__c)){
    //                masterProductToProductWrapperMapLegacy.get(prod.Master_Product__c).add(new ProductWrapper2(prod));
    //            }else{
    //                masterProductToProductWrapperMapLegacy.put(prod.Master_Product__c,new List<ProductWrapper2>{new ProductWrapper2(prod)});
    //            }
    //        }
    //        return masterProductToProductWrapperMapLegacy;
    //    } else {
    //        return masterProductToProductWrapperMapLegacy;
    //    }    
    //}
    //public Map<Id,List<ProductWrapper2>> getProductToProductWrapperMapLegacy(){
    //    if (ProductToProductWrapperMapLegacy == null && masterProductToProductWrapperMapLegacy != null){
    //        ProductToProductWrapperMapLegacy = new Map<Id, List<ProductWrapper2>>();
    //        for(Product2 p: selectedProductsLegacy){
    //            if(masterProductToProductWrapperMapLegacy.containsKey(p.Id)){
    //                ProductToProductWrapperMapLegacy.put(p.Id,masterProductToProductWrapperMapLegacy.get(p.Id).clone());
    //            }else{
    //                ProductToProductWrapperMapLegacy.put(p.Id, new List<ProductWrapper2>());
    //            }
    //        }
    //        system.debug('*** constructing ProductToProductWrapperMapLegacy '+ ProductToProductWrapperMapLegacy);
    //        return ProductToProductWrapperMapLegacy;
    //    } 
    //    return ProductToProductWrapperMapLegacy;
         
        
    //}
    ///End of getters    
    
    //Universal Methods
    public PageReference customDelete(){
        //deletes the order and redirects to delete confirmation page
        
        PageReference deletePage = new PageReference('/'+ o.AccountId);
        deletePage.setRedirect(true);
        delete o;
        return deletePage;

    }
    
    //Redirect Page Methods
    
    //grabbing those aggregate result calculcations
    Public Integer getnumorders() {
        return num_orders;
    }
    
    Public Integer getnumassets(){
        return num_assets;
    }
    
    
    public String aid { get; set; }{
        aid = apexpages.currentpage().getparameters().get('aid');
        if ( aid == null ) aid = '';
    }
    
    public String slid { get; set; }{
        slid = apexpages.currentpage().getparameters().get('slid');
        if ( slid == null ) slid = '';
    }
    
    //order is automatically saved on the redirect page, this is 
    //to populate all required fields and parent object records
    //which we either do not want in the UI or need populated
    //in order to make the UI work (i.e. Account)
    //
    public PageReference saveOrder(){
        
        try{
            
            Id standardPriceBookId;  
            if(Test.isRunningTest()){
                standardPriceBookId = Test.getStandardPricebookId();
            } else{
                standardPriceBookId = [
                    select Id 
                    from Pricebook2 
                    where isStandard=true
                ].Id;
            }
            
            //populates the Account, a standard price book which is needed
            //to create orderitems, store, sets record type, and status
            o.AccountId = aid;
            o.Pricebook2Id = standardPriceBookId;
            o.Store_Location__c = slid;                              
            o.RecordTypeId = UtilityMethods.retrieveRecordTypeId('CORO_Service', 'Order');
            o.Status = 'New';           
            upsert o;
            
            
            //if the Account has at least 1 sold order, user is taken to the Select an Order
            //page. If the Account does not have an order, but has assets (legacy), user is taken to
            //Page 2 where they select the Service Products. If the Account does not have any orders
            //or any assets, user is taken to the legacy page where all Service Products are displayed
            //for selection 
            PageReference newPage;
            
            If (num_orders > 0){
                newPage = new PageReference('/apex/RMS_createServiceRequestP1?id='+ o.Id + '&retUrl=' + o.Id);
            } else {
                If (num_assets > 0){
                    list<Contact_History__c> ch = [Select Contact__c, Dwelling__c, Primary_Contact__c, Id 
                        FROM Contact_History__c 
                       WHERE Dwelling__c =: o.AccountId 
                        AND Primary_Contact__c = true];
                    if (ch.size()>0){
                        o.BillToContactId = ch[0].Contact__c;
                        upsert o;
                    }  
                    newPage = new PageReference('/apex/RMS_createServiceRequestP2?id='+ o.Id + '&retUrl=' + o.Id); 
                } else{
                   list<Contact_History__c> ch = [Select Contact__c, Dwelling__c, Primary_Contact__c, Id 
                        FROM Contact_History__c 
                       WHERE Dwelling__c =: o.AccountId 
                        AND Primary_Contact__c = true];
                    if (ch.size()>0){
                        o.BillToContactId = ch[0].Contact__c;
                        upsert o;
                    }           
                    
                    newPage = new PageReference('/apex/RMS_ServiceRequestLegacyP1?id='+ o.Id + '&retUrl=' + o.Id);
                    //newPage = new PageReference('/apex/RMS_createServiceRequestAsset?aid='+o.AccountId);
                    //delete o; 
                }
            }
            
            newPage.setRedirect(true);
            return newPage;
        }catch(DMLException saveEx){
            ApexPages.addMessages(saveEx);
            PageReference newPage = new PageReference('/apex/RMS_createServiceRequestP1?id='+ o.Id + '&retUrl=' + o.Id);
            newPage.setRedirect(false);
            return newPage;
        }
        
    }    
    
    
    //Page 1 Methods    
    Id rt = Schema.SObjectType.Order.RecordTypeInfosByName.get('CORO Record Type').RecordTypeId;
    
    //grabbing all Sold Orders from the related Account and displaying them as a picklist for selection
    public List<selectOption> getOrds() {
        List<selectOption> options = new List<selectOption>(); //new list for holding all of the picklist options        
        for (Order orders : [SELECT Id, OrderNumber, Activated_Date__c, Status 
                             FROM Order 
                             WHERE Status NOT IN('Cancelled')
                             AND RecordTypeId = :rt 
                             AND AccountId = :o.AccountId 
                             ORDER BY Order.OrderNumber DESC]) { 
                                 options.add(new selectOption(orders.Id, orders.OrderNumber + ' - ' + orders.Activated_Date__c + ' - ' + orders.Status)); //for all records found - add them to the picklist options
                             }
        options.add(new selectOption('', 'None')); //add the first option of '- None -' in case the user doesn't want to select a value or in case no values are returned from query below
        return options; //return the picklist options        
    }               
    
    //save method for P1 to P2
    public PageReference saveP2(){
        try{      
            
            //find the Sales Tax from the Store Location and set on Order
            Account sl = new Account();
            sl = [SELECT Store_Location__r.Sales_Tax__c FROM Account WHERE id =: o.AccountId];
            if(sl != null){
                o.Sales_Tax_Percent__c = sl.Store_Location__r.Sales_Tax__c;    
            }
            
            //populate Bill to Contact, either from related Sold Order or the Primary
            //Contact for the Account based on Contact History. This is 
            //a failsafe to ensure Bill to Contact is always populated on P2 which is
            //necessary for all of the UI elements rerendering.           
            Order bc = new Order();
            Order so = new Order();
            Contact_History__c ch = new Contact_History__c();
            
            if(o.Sold_Order__c != null){
                bc = [Select BilltoContactId FROM Order WHERE id =: o.Sold_Order__c];
                if(bc != null){
                    o.BillToContactId = bc.BilltoContactId;
                }
                so = [SELECT ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,ShippingCountry,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry FROM Order where id =: o.Sold_Order__c];
                if(so != null){
                    o.BillingStreet = so.BillingStreet;
                    o.BillingCity = so.BillingCity;
                    o.BillingState = so.BillingState;
                    o.BillingPostalCode = so.BillingPostalCode;
                    o.BillingCountry = so.BillingCountry;
                    o.ShippingStreet = so.ShippingStreet;
                    o.ShippingCity = so.ShippingCity;
                    o.ShippingState = so.ShippingState;
                    o.ShippingPostalCode = so.ShippingPostalCode;
                    o.ShippingCountry = so.ShippingCountry;                    
                }
            } else {
                ch = [Select Contact__c, Dwelling__c, Primary_Contact__c, Id FROM Contact_History__c WHERE Dwelling__c =: o.AccountId AND Primary_Contact__c = true LIMIT 1];
                o.BillToContactId = ch.Contact__c;
            }            
            
            upsert o;
            
            PageReference pageRef = new PageReference('/apex/RMS_createServiceRequestP2?id='+ o.Id + '&retUrl=' + o.Id);
            pageRef.setRedirect(true);
            return pageRef;
        }catch(DMLException saveEx){
            ApexPages.addMessages(saveEx);
            PageReference pageRef = new PageReference('/apex/RMS_createServiceRequestP2?id='+ o.Id + '&retUrl=' + o.Id);
            pageRef.setRedirect(false);
            return pageRef;
        }
        
    }
    
    //Page 2 Methods 
    //
    //
    
    
    
    public PageReference saveClose(){
        PageReference newPage;
        
        
        try{           
            Id standardPriceBookId;  
            if(Test.isRunningTest()){
                standardPriceBookId = Test.getStandardPricebookId();
            } else{
                standardPriceBookId = [
                    select Id 
                    from Pricebook2 
                    where isStandard=true
                ].Id;
            }
            
            
            //in the wrapper, displaying all Service Products for the Master Products in each
            //Asset for the Account, a checkbox and three fields appear. For each Service Product
            //selected...create an OrderItem for the Service Request and populate appropriate fields.
            for(Id assetID : AssetToProductWrapperMap.keySet()){
                for(ProductWrapper wrapper: AssetToProductWrapperMap.get(assetId)){
                    if(wrapper.manufacturer || wrapper.local || wrapper.customer){
                        if(!wrapper.isSelected){                            
                            invalidRequest = 1;
                        } else {
                            invalidRequest = 0;
                        } 
                    }
                }
            }
            
            
            for(Id assetID : AssetToProductWrapperMap.keySet()){
                for(ProductWrapper wrapper: AssetToProductWrapperMap.get(assetId)){
                    if(wrapper.isSelected && invalidRequest == 0){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];
                        
                        Asset oa = [
                            SELECT Id,Product2Id,Original_Order_Product__c
                            FROM Asset
                            WHERE Id = :assetId];                        
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;
                        oi.Sold_Order_Product_Asset__c = assetId; 
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;
                        oi.Notes__c = wrapper.description;
                        listOI.add(oi); 
                        
                    }
                }        
            }
            
            //checkbox on Order set to true, needed to ensure we validate required fields, but
            //only when the entire request is filled out and not during a rerender.
            o.Validate_Service_Order__c = true;
            //convert the selectOption value to picklist value, set on Ordre
            If(propPickValSelected != null){
            o.Service_Type__c = propPickValSelected;
            }
            
            upsert o;
            system.debug(listOI);
            system.debug(invalidRequest);            
            
            //inserts the OrderItems  
            
            If(invalidRequest==1){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Validation Failed: If selecting a responsible party, you must select the checkbox to the left of the Product.'));            
                return null; 
                listOI.clear();
                invalidRequest = 0;
            }      else {   
                insert listOi;
                invalidRequest = 0;
            }
            
            
            if(listOI.Size() > 0){
                newPage = new PageReference('/'+o.id);                
            } else {
                newPage = new PageReference('/' + o.id);
            }
            
            newPage.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            //needed to make sure the collapsed rows stay collapsed when validation error occurs
            listOI.clear();
            invalidRequest = 0;
        }
        
        return newPage;
    }  
    
    
    public PageReference saveContinue(){
        PageReference newPage;
        
        
        try{           
            Id standardPriceBookId;  
            if(Test.isRunningTest()){
                standardPriceBookId = Test.getStandardPricebookId();
            } else{
                standardPriceBookId = [
                    select Id 
                    from Pricebook2 
                    where isStandard=true
                ].Id;
            }
            
            
            //in the wrapper, displaying all Service Products for the Master Products in each
            //Asset for the Account, a checkbox and three fields appear. For each Service Product
            //selected...create an OrderItem for the Service Request and populate appropriate fields.
            for(Id assetID : AssetToProductWrapperMap.keySet()){
                for(ProductWrapper wrapper: AssetToProductWrapperMap.get(assetId)){
                    if(wrapper.manufacturer || wrapper.local || wrapper.customer){
                        if(!wrapper.isSelected){                            
                            invalidRequest = 1;
                        } else {
                            invalidRequest = 0;
                        } 
                    }
                }
            }
            
            for(Id assetID : AssetToProductWrapperMap.keySet()){
                for(ProductWrapper wrapper: AssetToProductWrapperMap.get(assetId)){                    
                    if(wrapper.isSelected && invalidRequest == 0){                            
                        System.Debug('*******wrapper.Product.Service_Product__c=' +wrapper.Product.Service_Product__c);
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];
                        
                        Asset oa = [
                            SELECT Id,Product2Id,Original_Order_Product__c
                            FROM Asset
                            WHERE Id = :assetId];                        
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;
                        oi.Sold_Order_Product_Asset__c = assetId;                         
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;
                        oi.Notes__c = wrapper.description;
                        listOI.add(oi); 
                        
                    }
                }                
            }        
            
            
            //checkbox on Order set to true, needed to ensure we validate required fields, but
            //only when the entire request is filled out and not during a rerender.
            o.Validate_Service_Order__c = true;
            //convert the selectOption value to picklist value, set on Ordre
            If(propPickValSelected != null){
                o.Service_Type__c = propPickValSelected;
            }
            
            
            upsert o;
            system.debug(listOI); 
            system.debug(invalidRequest);            
            
            //inserts the OrderItems  
            
            If(invalidRequest==1){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Validation Failed: If selecting a responsible party, you must select the checkbox to the left of the Product.'));            
                return null; 
                listOI.clear();
                invalidRequest = 0;
            }      else {   
                insert listOi;
                invalidRequest = 0;
            }
            
            
            if(listOI.Size() > 0){
                newPage = new PageReference('/apex/RMS_createServiceRequestP3?id='+o.id);
            } else {
                newPage = new PageReference('/' + o.id);
            }
            
            newPage.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            //needed to make sure the collapsed rows stay collapsed when validation error occurs
            listOI.clear();
            invalidRequest = 0;
        }
        
        return newPage;
    }  
    
    //page3 Methods
    public PageReference regroup()
    {
        setupGrouping();
        return null;
    }
    private void setupGrouping()
    {
        Map<String, List<OrderItem>> groupedMap = new Map<String, List<OrderItem>>();
        system.debug('*****printing allAccs '+ allAccs);
        for (OrderItem acc : allAccs)
        {
            String key = String.valueof(acc.get(groupFieldName));
            if ( (null == key) || (0 == key.length()) )
            {
                key='Undefined';
            }
            
            List<OrderItem> groupedAccs = groupedMap.get(key);
            if (null == groupedAccs)
            {
                groupedAccs=new List<OrderItem>();
                groupedMap.put(key, groupedAccs);
            }
            
            groupedAccs.add(acc);
        }
        
        groups = new List<GroupWrapper>();
        for (String key : groupedMap.keySet())
        {
            GroupWrapper gr=new GroupWrapper();
            groups.add(gr);
            gr.accs=groupedMap.get(key);
            gr.groupedVal=key;
        }
    }
    
    public class GroupWrapper
    {
        public List<OrderItem> accs {get; set;}
        public String groupedVal {get; set;}
        public Integer count {get {return accs.size(); } set;}
    }
    
    Public PageReference saveCharges()
    {
        Savepoint sp = Database.setSavepoint();
        PageReference pr;
        
        // List<Charge__c> ch = [SELECT Id, Charge_Cost_To__c, Service_Product__c, Primary_Reason__c, Secondary_Reason__c FROM Charge__c WHERE Service_Product__c =: allAccs];
        List<Charge__c> ch = new list<Charge__c>();
        for(OrderItem oi: allAccs){
            ch.addAll(oi.Charges__r);
        }
        if(ch.size() > 0 ){
            update ch;  
            pr = new PageReference('/apex/RMS_viewServiceRequest?id=' + o.Id);
            pr.setRedirect(true);
            return pr;
        } else {
            return null;
        } 
    }
    
    //Legacy Orders Pages
    
    public PageReference saveCloseLegacy(){
        PageReference newPage;
        
        
        try{
            Id standardPriceBookId;  
            if(Test.isRunningTest()){
                standardPriceBookId = Test.getStandardPricebookId();
            } else{
                standardPriceBookId = [
                    select Id 
                    from Pricebook2 
                    where isStandard=true
                ].Id;
            }
            
            for(Id productId : ProductToProductWrapperMapLegacy.keySet()){
                for(ProductWrapper2 wrapper: ProductToProductWrapperMapLegacy.get(productId)){
                    if(wrapper.manufacturer || wrapper.local || wrapper.customer){
                        if(!wrapper.isSelected){                            
                            invalidRequest = 1;
                        } else {
                            invalidRequest = 0;
                        } 
                    }
                }
            }
            
            for(Id productId : ProductToProductWrapperMapLegacy.keySet()){
                for(ProductWrapper2 wrapper: ProductToProductWrapperMapLegacy.get(productId)){
                    if(wrapper.isSelected && invalidRequest == 0){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];                       
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;                        
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;                        
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Notes__c = wrapper.description;
                        listOILegacy.add(oi);                           
                    }
                }        
            }
            
            o.Validate_Service_Order__c = true;
            
            If(propPickValSelectedLegacy != null){
                o.Service_Type__c = propPickValSelectedLegacy;
            }
            
            upsert o;
            system.debug(listOILegacy);
            system.debug(invalidRequest);
            
            If(invalidRequest==1){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Validation Failed: If selecting a responsible party, you must select the checkbox to the left of the Product.'));            
                return null; 
                listOILegacy.clear();
                invalidRequest = 0;
            }      else {   
                insert listOILegacy;
                invalidRequest = 0;
            }
            
            
            if(listOiLegacy.Size() > 0){
                newPage = new PageReference('/'+o.id);
            } else {
                newPage = new PageReference('/' + o.id);
            }
            newPage.setRedirect(true); 
            
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            listOILegacy.clear();
            invalidRequest = 0;
        }
        
        return newPage;
    }  
    
    
    
    public PageReference saveContinueLegacy(){
        PageReference newPage;
        
        
        try{
            Id standardPriceBookId;  
            if(Test.isRunningTest()){
                standardPriceBookId = Test.getStandardPricebookId();
            } else{
                standardPriceBookId = [
                    select Id 
                    from Pricebook2 
                    where isStandard=true
                ].Id;
            }
            
            for(Id productId : ProductToProductWrapperMapLegacy.keySet()){
                for(ProductWrapper2 wrapper: ProductToProductWrapperMapLegacy.get(productId)){
                    if(wrapper.manufacturer || wrapper.local || wrapper.customer){
                        if(!wrapper.isSelected){                            
                            invalidRequest = 1;
                        } else {
                            invalidRequest = 0;
                        } 
                    }
                }
            }
            
            for(Id productId : ProductToProductWrapperMapLegacy.keySet()){
                for(ProductWrapper2 wrapper: ProductToProductWrapperMapLegacy.get(productId)){
                    if(wrapper.isSelected && invalidRequest == 0){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];                       
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;                        
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;                        
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Notes__c = wrapper.description;
                        listOILegacy.add(oi);                           
                    }
                }        
            }
            o.Validate_Service_Order__c = true;
            
            If(propPickValSelectedLegacy != null){
                o.Service_Type__c = propPickValSelectedLegacy;
            }
            
            upsert o;
            system.debug(listOILegacy);
            
            
            If(invalidRequest==1){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Validation Failed: If selecting a responsible party, you must select the checkbox to the left of the Product.'));            
                return null; 
                listOILegacy.clear();
                invalidRequest = 0;
            }      else {   
                insert listOILegacy;
                invalidRequest = 0;
            }
            
            
            if(listOiLegacy.Size() > 0){
                newPage = new PageReference('/apex/RMS_createServiceRequestP3?id='+o.id);
            } else {
                newPage = new PageReference('/' + o.id);
            }
            
            newPage.setRedirect(true); 
            
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            listOILegacy.clear();
            invalidRequest = 0;
        }
        
        return newPage;
    } 
    
    
    Public string propPickValSelectedLegacy { get; set; }
    public List<SelectOption> getPickLstValueLegacy()
    {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Order.Service_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        Order od = new order();
        od = [SELECT Sold_Order_JIP_Eligible__c 
              FROM Order 
              WHERE Id =:o.id];    
        system.debug('********** od.Sold_Order_JIP_Eligible__c '+ od.Sold_Order_JIP_Eligible__c);            
        IF (od.Sold_Order_JIP_Eligible__c){
            for(Schema.PicklistEntry f : ple){
                if(f.getValue() == 'Job In Progress' || f.getValue() == 'Save'){
                    options.add(new SelectOption(f.getLabel(), f.getValue()));                          
                }                      
            }
        }
        ELSE{
            //options.add(new SelectOption('--None--','--None--')); 
            for(Schema.PicklistEntry f : ple){
                if(f.getValue() != 'Job In Progress'){
                    options.add(new SelectOption(f.getLabel(), f.getValue()));
                }
            } 
        }
        
        return options;           
    }
    
    public String getpropPickValSelectedLegacy() {
        return propPickValSelectedLegacy;
    }
    
    public void setpropPickValSelectedLegacy(String propPickValSelectedLegacy) {
        this.propPickValSelectedLegacy = propPickValSelectedLegacy;
    }
    
    public class ProductWrapper2{
        public Service_Product__c product{get;set;}
        public Boolean isSelected{get;set;}        
        public Asset asset{get;set;}
        public Boolean manufacturer {get;set;}
        public Boolean local {get;set;}
        public Boolean customer {get;set;}
        public String description {get;set;}
        
        public ProductWrapper2(Service_Product__c prod){
            product = prod;
            isSelected = false;  
            manufacturer = false;
            local = false;
            customer = false;
            description = '';
        }
        
        public String getDescription(){
            return description;
        }
        
        public void description (String description){
            this.description = description;
        }
        
    }
    
    
    //add product pages
    public PageReference saveNewProducts(){
        
        PageReference newPage;
        
        
        try{           
            Id standardPriceBookId;  
            if(Test.isRunningTest()){
                standardPriceBookId = Test.getStandardPricebookId();
            } else{
                standardPriceBookId = [
                    select Id 
                    from Pricebook2 
                    where isStandard=true
                ].Id;
            }
            
            
            //in the wrapper, displaying all Service Products for the Master Products in each
            //Asset for the Account, a checkbox and three fields appear. For each Service Product
            //selected...create an OrderItem for the Service Request and populate appropriate fields.
            for(Id assetID : AssetToProductWrapperMap.keySet()){
                for(ProductWrapper wrapper: AssetToProductWrapperMap.get(assetId)){
                    if(wrapper.manufacturer || wrapper.local || wrapper.customer){
                        if(!wrapper.isSelected){                            
                            invalidRequest = 1;
                        } else {
                            invalidRequest = 0;
                        } 
                    }
                }
            }
            
            
            for(Id assetID : AssetToProductWrapperMap.keySet()){
                for(ProductWrapper wrapper: AssetToProductWrapperMap.get(assetId)){
                    if(wrapper.isSelected && invalidRequest == 0){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];
                        
                        Asset oa = [
                            SELECT Id,Product2Id,Original_Order_Product__c
                            FROM Asset
                            WHERE Id = :assetId];                        
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;
                        oi.Sold_Order_Product_Asset__c = assetId; 
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Description = wrapper.description;
                        listOI.add(oi);                           
                    }
                }        
            }
            
            
            //checkbox on Order set to true, needed to ensure we validate required fields, but
            //only when the entire request is filled out and not during a rerender.
            o.Validate_Service_Order__c = true;
            upsert o;
            system.debug(listOI);
            
            //inserts the OrderItems
            If(invalidRequest==1){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Validation Failed: If selecting a responsible party, you must select the checkbox to the left of the Product.'));            
                return null; 
                listOI.clear();
                invalidRequest = 0;
            }      else {   
                insert listOi;
                invalidRequest = 0;
            }
            
            
            if(listOI.Size() > 0){
                newPage = new PageReference('/'+o.id);
            } else {
                newPage = new PageReference('/' + o.id);
            }
            newPage.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            //needed to make sure the collapsed rows stay collapsed when validation error occurs
            listOI.clear();
            invalidRequest = 0;
        }
        
        return newPage;
    }
    
    
    public PageReference saveNewProductsContinue(){
        
        PageReference newPage;
        
        
        try{           
            Id standardPriceBookId;  
            if(Test.isRunningTest()){
                standardPriceBookId = Test.getStandardPricebookId();
            } else{
                standardPriceBookId = [
                    select Id 
                    from Pricebook2 
                    where isStandard=true
                ].Id;
            }
            
            
            //in the wrapper, displaying all Service Products for the Master Products in each
            //Asset for the Account, a checkbox and three fields appear. For each Service Product
            //selected...create an OrderItem for the Service Request and populate appropriate fields.
            for(Id assetID : AssetToProductWrapperMap.keySet()){
                for(ProductWrapper wrapper: AssetToProductWrapperMap.get(assetId)){
                    if(wrapper.manufacturer || wrapper.local || wrapper.customer){
                        if(!wrapper.isSelected){                            
                            invalidRequest = 1;
                        } else {
                            invalidRequest = 0;
                        } 
                    }
                }
            }
            
            for(Id assetID : AssetToProductWrapperMap.keySet()){
                for(ProductWrapper wrapper: AssetToProductWrapperMap.get(assetId)){
                    if(wrapper.isSelected && invalidRequest == 0){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];
                        
                        Asset oa = [
                            SELECT Id,Product2Id,Original_Order_Product__c
                            FROM Asset
                            WHERE Id = :assetId];                        
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;
                        oi.Sold_Order_Product_Asset__c = assetId; 
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;
                        oi.Description = wrapper.description;
                        listOI.add(oi);                           
                    }
                }        
            }
            
            
            //checkbox on Order set to true, needed to ensure we validate required fields, but
            //only when the entire request is filled out and not during a rerender.
            o.Validate_Service_Order__c = true;
            upsert o;
            system.debug(listOI);
            
            If(invalidRequest==1){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Validation Failed: If selecting a responsible party, you must select the checkbox to the left of the Product.'));            
                return null; 
                listOI.clear();
                invalidRequest = 0;
            }      else {   
                insert listOi;
                invalidRequest = 0;
            }
            
            
            if(listOI.Size() > 0){
                newPage = new PageReference('/apex/RMS_createServiceRequestP3?id='+o.id);
            } else {
                newPage = new PageReference('/' + o.id);
            }
            
            newPage.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            //needed to make sure the collapsed rows stay collapsed when validation error occurs
            listOI.clear();
            invalidRequest = 0;
        }
        
        return newPage;
    } 
    
    
    public PageReference saveNewProductsLegacy(){
        
        PageReference newPage;
        
        try{           
            Id standardPriceBookId;  
            if(Test.isRunningTest()){
                standardPriceBookId = Test.getStandardPricebookId();
            } else{
                standardPriceBookId = [
                    select Id 
                    from Pricebook2 
                    where isStandard=true
                ].Id;
            }
            
            
            //in the wrapper, displaying all Service Products for the Master Products in each
            //Asset for the Account, a checkbox and three fields appear. For each Service Product
            //selected...create an OrderItem for the Service Request and populate appropriate fields.
            for(Id productId : ProductToProductWrapperMapLegacy.keySet()){
                for(ProductWrapper2 wrapper: ProductToProductWrapperMapLegacy.get(productId)){
                    if(wrapper.manufacturer || wrapper.local || wrapper.customer){
                        if(!wrapper.isSelected){                            
                            invalidRequest = 1;
                        } else {
                            invalidRequest = 0;
                        } 
                    }
                }
            }
            
            for(Id productId : ProductToProductWrapperMapLegacy.keySet()){
                for(ProductWrapper2 wrapper: ProductToProductWrapperMapLegacy.get(productId)){
                    if(wrapper.isSelected && invalidRequest == 0){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];                        
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Description = wrapper.description;
                        listOI.add(oi);                           
                    }
                }        
            }
            
            
            //checkbox on Order set to true, needed to ensure we validate required fields, but
            //only when the entire request is filled out and not during a rerender.
            o.Validate_Service_Order__c = true;
            upsert o;
            system.debug(listOI);
            
            //inserts the OrderItems
            If(invalidRequest==1){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Validation Failed: If selecting a responsible party, you must select the checkbox to the left of the Product.'));            
                return null; 
                listOI.clear();
                invalidRequest = 0;
            }      else {   
                insert listOi;
                invalidRequest = 0;
            }
            
            
            if(listOI.Size() > 0){
                newPage = new PageReference('/apex/RMS_createServiceRequestP3?id='+o.id);
            } else {
                newPage = new PageReference('/' + o.id);
            }
            
            newPage.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            //needed to make sure the collapsed rows stay collapsed when validation error occurs
            listOI.clear();
            invalidRequest = 0;
        }
        
        return newPage;
    }  
    
    
    public PageReference saveNewProductsLegacyContinue(){
        
        PageReference newPage;
        
        
        try{           
            Id standardPriceBookId;  
            if(Test.isRunningTest()){
                standardPriceBookId = Test.getStandardPricebookId();
            } else{
                standardPriceBookId = [
                    select Id 
                    from Pricebook2 
                    where isStandard=true
                ].Id;
            }
            
            
            //in the wrapper, displaying all Service Products for the Master Products in each
            //Asset for the Account, a checkbox and three fields appear. For each Service Product
            //selected...create an OrderItem for the Service Request and populate appropriate fields.
            for(Id productId : ProductToProductWrapperMapLegacy.keySet()){
                for(ProductWrapper2 wrapper: ProductToProductWrapperMapLegacy.get(productId)){
                    if(wrapper.manufacturer || wrapper.local || wrapper.customer){
                        if(!wrapper.isSelected){                            
                            invalidRequest = 1;
                        } else {
                            invalidRequest = 0;
                        } 
                    }
                }
            }
            
            for(Id productId : ProductToProductWrapperMapLegacy.keySet()){
                for(ProductWrapper2 wrapper: ProductToProductWrapperMapLegacy.get(productId)){
                    if(wrapper.isSelected && invalidRequest == 0){
                        PricebookEntry pbe = [ 
                            SELECT Id,Product2Id,Pricebook2Id,UnitPrice 
                            FROM PricebookEntry 
                            WHERE Pricebook2Id = :standardPriceBookId 
                            AND isActive = true
                            AND Product2Id = :wrapper.Product.Service_Product__c];                        
                        
                        OrderItem oi = new OrderItem();                                              
                        oi.UnitPrice = pbe.UnitPrice;
                        oi.OrderId = o.Id;
                        oi.PriceBookEntryId = pbe.id;
                        oi.Quanity_Ordered__c = 1;
                        oi.Quantity = 1;
                        oi.Service__c = true;
                        oi.Manufacturer_Replace__c = wrapper.manufacturer;
                        oi.Local_Remake__c = wrapper.local;
                        oi.Customer_Replace__c = wrapper.customer;
                        oi.Description = wrapper.description;
                        listOI.add(oi);                           
                    }
                }        
            }
            
            
            //checkbox on Order set to true, needed to ensure we validate required fields, but
            //only when the entire request is filled out and not during a rerender.
            o.Validate_Service_Order__c = true;
            upsert o;
            system.debug(listOI);
            
            //inserts the OrderItems
            If(invalidRequest==1){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Validation Failed: If selecting a responsible party, you must select the checkbox to the left of the Product.'));            
                return null; 
                listOI.clear();
                invalidRequest = 0;
            }      else {   
                insert listOi;
                invalidRequest = 0;
            }
            
            if(listOI.Size() > 0){
                newPage = new PageReference('/apex/RMS_createServiceRequestP3?id='+o.id);
            } else {
                newPage = new PageReference('/' + o.id);
            }
            
            newPage.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
            //needed to make sure the collapsed rows stay collapsed when validation error occurs
            listOI.clear();
            invalidRequest = 0;
        }
        
        return newPage;
    }   
    
    
    
    //method for creating Service Type picklist, defaulted to JIP when appropriate, hiding
    //JIP as a value when appropriate
    Public string propPickValSelected { get; set; }
    public List<SelectOption> getPickLstValue()
    {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Order.Service_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        Order od = new order();
        od = [SELECT Sold_Order_JIP_Eligible__c 
              FROM Order 
              WHERE Id =:o.id]; 
        system.debug('******* '+ od.Sold_Order_JIP_Eligible__c);           
        IF (od.Sold_Order_JIP_Eligible__c){
            for(Schema.PicklistEntry f : ple){
                if(f.getValue() == 'Job In Progress' || f.getValue() == 'Save'){
                    options.add(new SelectOption(f.getLabel(), f.getValue()));                          
                }                      
            }
        }
        ELSE{           
            for(Schema.PicklistEntry f : ple){
                if(f.getValue() != 'Job In Progress'){
                    options.add(new SelectOption(f.getLabel(), f.getValue()));
                }
            } 
        }
        
        return options;           
    }
    
    public String getpropPickValSelected() {
        return propPickValSelected;
    }
    
    public void setpropPickValSelected(String propPickValSelected) {
        this.propPickValSelected = propPickValSelected;
    }       
    
    
    
    //RMS_updateServiceType Methods
    public List<SelectOption> getPickLstValue2()
    {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Order.Service_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        Order od = new order();
        od = [SELECT Sold_Order_JIP_Eligible__c 
              FROM Order 
              WHERE Id =:o.id];            
        IF (od.Sold_Order_JIP_Eligible__c){
            for(Schema.PicklistEntry f : ple){
                if(f.getValue() == 'Job In Progress' || f.getValue() == 'Save'){
                    options.add(new SelectOption(f.getLabel(), f.getValue()));                          
                }                      
            }
        }
        ELSE{
            
            for(Schema.PicklistEntry f : ple){
                if(f.getValue() != 'Job In Progress'){
                    options.add(new SelectOption(f.getLabel(), f.getValue()));
                }
            } 
        }
        
        return options;           
    }
    
    public String getpropPickValSelected2() {
        return propPickValSelected2;
    }
    
    public void setpropPickValSelected2(String propPickValSelected2) {
        this.propPickValSelected2 = propPickValSelected2;
    }
    
    public PageReference saveST(){
        PageReference pageRef = null;
        try{
            o.Service_Type__c = propPickValSelected2;
            upsert o;
            pageRef = new PageReference('/' + o.id);
            pageRef.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
        }
        
        return pageRef;
    }
    
    public PageReference cancelUpdate(){
        PageReference newPage;
        newPage = new PageReference('/apex/RMS_viewServiceRequest?id='+o.Id);
        newPage.setRedirect(true); 
        return newPage;
    } 
    
    //public PageReference cancelOrder(){
    //  PageReference pageRef = null;
    //try{
    //  o.Status = 'Cancelled';
    //upsert o;
    //pageRef = new PageReference('/' + o.id);
    //pageRef.setRedirect(true); 
    //}catch(DMLException ex){
    //   ApexPages.addMessages(ex);
    //}
    
    // return pageRef;
    //}
    
    public PageReference cancelP3(){
        PageReference pageRef = null;
        try{            
            upsert o;
            pageRef = new PageReference('/' + o.id);
            pageRef.setRedirect(true); 
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
        }
        
        return pageRef;
    }
    
    
    //product wrapper for creating table of Service Products
    public class ProductWrapper{
        public Service_Product__c product{get;set;}
        public Boolean isSelected{get;set;}        
        public Asset asset{get;set;}
        public Boolean manufacturer {get;set;}
        public Boolean local {get;set;}
        public Boolean customer {get;set;}
        public String description {get;set;}
        
        
        public ProductWrapper(Service_Product__c prod){
            product = prod;  
            isSelected = false;
            manufacturer = false;
            local = false;
            customer = false;
            description = '';
        }
        
        public String getDescription(){
            return description;
        }
        
        public void description (String description){
            this.description = description;
        }
        
        
        
    }    
    
    
}
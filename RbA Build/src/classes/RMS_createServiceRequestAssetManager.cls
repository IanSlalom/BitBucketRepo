public with sharing class RMS_createServiceRequestAssetManager  {
    
    public final Asset o;
    
    public RMS_createServiceRequestAssetManager(ApexPages.StandardController stdController) {
        this.o = (Asset)stdController.getRecord();
    }
    
    public String aid { get; set; }{
        aid = apexpages.currentpage().getparameters().get('aid');
        if ( aid == null ) aid = '';
    }
    
    public String slid { get; set; }{
        slid = apexpages.currentpage().getparameters().get('slid');
        if ( slid == null ) slid = '';
    }
    
    public String name { get; set; }{
        name = apexpages.currentpage().getparameters().get('name');
        if ( name == null ) name = 'New Asset';
    }
    
    public PageReference saveAsset(){
        
        try{
            
            
            o.Name='New Asset';
            o.AccountId = aid;                                                    
            o.RecordTypeId = UtilityMethods.retrieveRecordTypeId('Installed_Products', 'Asset');
            o.Status = 'Installed'; 
            o.Quantity = 1;
            upsert o;            
            
            List<Account> store = [SELECT Store_Location__c FROM Account WHERE Id =: o.AccountId];
            
            If(store.size()>0){
                o.Store_Location__c = store[0].Store_Location__c;
                upsert o;
            }
            
            
            list<Contact_History__c> ch = [Select Contact__c, Dwelling__c, Primary_Contact__c, Id 
                                           FROM Contact_History__c 
                                           WHERE Dwelling__c =: o.AccountId 
                                           AND Primary_Contact__c = true];
            if (ch.size()>0){
                o.ContactId = ch[0].Contact__c;
                upsert o;
            }
            
            PageReference newPage;
            
            
            
            newPage = new PageReference('/apex/RMS_createServiceRequestAsset?id='+ o.Id + '&retUrl=' + o.Id);
            
            
            newPage.setRedirect(true);
            return newPage;
        }catch(DMLException saveEx){
            ApexPages.addMessages(saveEx);
            PageReference newPage = new PageReference('/apex/RMS_createServiceRequestAsset?id='+ o.Id + '&retUrl=' + o.Id);
            newPage.setRedirect(false);
            return newPage;
        }
        
    }
    
    public PageReference saveContinueAsset(){
        
        PageReference newPage;
        try{    
            
            upsert o;
            newPage = new PageReference('/apex/RMS_createServiceRequestRedirect?aid='+o.AccountId+'&slid='+o.Store_Location__c);
        }
        catch(DMLException ex){
            ApexPages.addMessages(ex);
        }
        
        return newPage;
    } 
    
    public PageReference customDelete(){       
        
        PageReference deletePage = new PageReference('/'+ o.AccountId);
        deletePage.setRedirect(true);
        delete o;
        return deletePage;
        
    }
}
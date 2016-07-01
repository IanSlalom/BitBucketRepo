/*******************************************************//**

@class  RMS_OrderItemExtension

@brief  Controller for RMS_CloseTabPage visualforce page

@author  Brianne Wilson (Slalom.BLW)

@version    2016-3-9  Slalom.BLW
Created.

@copyright  (c)2016 Slalom.  All Rights Reserved. 
Unauthorized use is prohibited.

***********************************************************/
public class RMS_OrderItemExtension {
    
    public final OrderItem o;
    public String baseURL{get;set;}
    public String editURL{get;set;}
    public String addSymptomURL {get;set;}
    //map<String, Service_Field_Ids__c> Service_Field_Ids_map = Service_Field_Ids__c.getAll();
    public String ssSP {get;set;}
    //public List<Order> parent {get;set;}
    
    public RMS_OrderItemExtension(ApexPages.StandardController stdController) {
        if(!test.isRunningTest()){
            stdController.addFields(new List<String>{'OrderId','Service__c'});           
        }
        
        
        this.o = (OrderItem)stdController.getRecord();
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        editURL ='/apex/RMS_editServiceProduct?id='+o.Id;
        addSymptomURL = '/apex/RMS_addServiceSymptom?ssSP'+'='+o.id;
        
        
        
    }
    
    public PageReference saveCloseTab(){
        
        try{                             
            upsert o;
            
            Order parent = [SELECT id FROM Order WHERE id = :o.OrderId];   
            
            
            PageReference savePage = new PageReference('/'+o.id);
            savePage.setRedirect(true);
            return savePage;
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
        }
        return null;
    } 
    
    public PageReference orderItemRedirect(){
        PageReference newPage = null;
        
        
        
        If (o.Service__c == TRUE){
            newPage = new PageReference('/apex/RMS_viewServiceOrderItem?id='+ o.Id);                               
        } else {
            newPage = new PageReference('/'+ o.Id);
            newPage.getParameters().put('nooverride','1');
        }
        
        newPage.setRedirect(true);
        return newPage;
        
        
    }
    
    public PageReference editOrderItem(){
        PageReference newPage;
        newPage = new PageReference('/apex/RMS_editServiceProduct?id='+o.id);
        newPage.setRedirect(true); 
        return newPage;
    } 
    
    public PageReference cancelOrderItem(){
        PageReference newPage;
        newPage = new PageReference('/'+o.id);
        newPage.setRedirect(true); 
        return newPage;
    } 
    
    public PageReference addResponsibility(){
        PageReference newPage;
        newPage = new PageReference('/apex/RMS_addResponsibilitytoSP?id='+o.id+'&mode=e');
        newPage.setRedirect(true); 
        return newPage;
    } 

    public PageReference addWarranty(){
        PageReference newPage;
        newPage = new PageReference('/apex/RMS_addWarrantytoSP?id='+o.id+'&mode=e');
        newPage.setRedirect(true); 
        return newPage;
    } 
    
    public PageReference addServiceSymptom(){
        PageReference newPage;
        newPage = new PageReference('/apex/RMS_addServiceSymptom?ssSP'+'='+o.id);
        newPage.setRedirect(true); 
        return newPage;
    }     
}
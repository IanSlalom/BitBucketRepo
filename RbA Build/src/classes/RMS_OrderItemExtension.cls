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
    //public List<Order> parent {get;set;}
    
    public RMS_OrderItemExtension(ApexPages.StandardController stdController) {
        if(!test.isRunningTest()){
            stdController.addFields(new List<String>{'OrderId'});           
        }
        
        this.o = (OrderItem)stdController.getRecord();
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        editURL ='/apex/RMS_editServiceProduct?id='+o.Id;
           
        
        
    }
    
    public PageReference saveCloseTab(){
        
        try{                             
            upsert o;
            
            Order parent = [SELECT id FROM Order WHERE id = :o.OrderId];   

            
            PageReference savePage = new PageReference('/'+parent.id);
            savePage.setRedirect(true);
            return savePage;
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
        }
        return null;
    } 
    
    //public PageReference cancelCloseTab(){
      //  Order parent = [Select id FROM Order WHERE id = :OrderId];
       // try{
        //PageReference savePage = new PageReference('/'+parent.id);
         //   savePage.setRedirect(true);
          //  return savePage;
        //}catch(DMLException ex){
         //   ApexPages.addMessages(ex);
       // }
       // return null;        
    //}
    
}
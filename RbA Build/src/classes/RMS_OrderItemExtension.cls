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
    
    public RMS_OrderItemExtension(ApexPages.StandardController stdController) {
        
        
        this.o = (OrderItem)stdController.getRecord();
        
        
    }
    
    public PageReference saveCloseTab(){
        
        try{                             
            upsert o;
            
            PageReference savePage = Page.RMS_closeTabPage;
            savePage.setRedirect(true);
            return savePage;
        }catch(DMLException ex){
            ApexPages.addMessages(ex);
        }
        return null;
    } 
    
}
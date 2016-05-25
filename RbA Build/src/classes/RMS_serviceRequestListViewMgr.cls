public class RMS_serviceRequestListViewMgr {
    public String listName {
        get;
        set {
            listName = value;
            String qry = 'SELECT OrderNumber,RecordTypeId FROM Order LIMIT 1';
            ApexPages.StandardSetController ssc = 
                new ApexPages.StandardSetController(Database.getQueryLocator(qry));
            List<SelectOption> allViews = ssc.getListViewOptions();
            for (SelectOption so : allViews) {
                if (so.getLabel() == listName) {
                    // for some reason, won't work with 18 digit ID
                    listId = so.getValue().substring(0,15);
                    break;
                }
            }             
        }      
    }
    public String listId {get;set;}
    
        Public string propPickValSelected { get; set; }
    
        public List<SelectOption> getPickLstValue()
    {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Service Requests - All','Service Requests - All'));
        options.add(new SelectOption('Service Requests - New','Service Requests - New'));
        options.add(new SelectOption('Service Requests - Product Ordered','Service Requests - Product Ordered'));        
        return options;
    }
    
    public String getpropPickValSelected() {
        return propPickValSelected;
    }
    
    public void setpropPickValSelected(String propPickValSelected) {
        this.propPickValSelected = propPickValSelected;
    }
    

}
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
        options.add(new SelectOption(' ','------------- SELECT -------------'));
        options.add(new SelectOption('Service Requests - All','Service Requests - All'));
        options.add(new SelectOption('Service Requests - New','Service Requests - New'));
        options.add(new SelectOption('Service Requests - Service Scheduled','Service Requests - Service Scheduled'));
        options.add(new SelectOption('Service Requests - Customer Call Back','Service Requests - Customer Call Back'));
        options.add(new SelectOption('Service Requests - Product Ordered','Service Requests - Product Ordered'));     
        options.add(new SelectOption('Service Requests-Service To Be Scheduled','Service Requests-Service To Be Scheduled'));
        options.add(new SelectOption('Service Requests - To Be Ordered','Service Requests - To Be Ordered'));   
        options.add(new SelectOption('Service Requests - Service On Hold','Service Requests - Service On Hold'));
        options.add(new SelectOption('Service Requests - Seasonal Service','Service Requests - Seasonal Service'));
        options.add(new SelectOption('Service Requests - Seasonal Service','Service Requests - Service Complete'));
        options.add(new SelectOption('Service Requests - Warranty Submitted','Service Requests - Warranty Submitted'));
        options.add(new SelectOption('Service Requests - Warranty Accepted','Service Requests - Warranty Accepted'));
        options.add(new SelectOption('Service Requests - Warranty Rejected','Service Requests - Warranty Rejected'));
        options.add(new SelectOption('Service Requests - Cancelled','Service Requests - Cancelled'));
        options.add(new SelectOption('Service Requests - Closed','Service Requests - Closed'));
        return options;
    }
    
    public String getpropPickValSelected() {
        return propPickValSelected;
    }
    
    public void setpropPickValSelected(String propPickValSelected) {
        this.propPickValSelected = propPickValSelected;
    }
    
    
}
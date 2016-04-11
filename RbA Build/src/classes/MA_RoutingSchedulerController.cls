global with sharing class MA_RoutingSchedulerController {

    private static final string ESRIClientID = 'YRGMYKIjOjSpQnUz';
    private static final string ESRIClientSecret = 'ff4a4b1ecc9b43c591ac05ef98df135e';
    private static final string ArcGISauth = 'https://www.arcgis.com/sharing/rest/oauth2/token/';
    private static String storeSettings;
    private static Map<String, String> configs = new Map<String,String>();
    private static Map<String, Object> geoCodeAddress;
    private static List<Map<String, Object>> features; 
    private static Map<String, Object> errors = new Map<String, Object>();
    private static Map<String, List<Object>> objLists; //objLists = new Map<String, List<Object>>();
    private static Map<String, Map<String, Object>> master  = new  Map<String, Map<String, Object>>();


    public MA_RoutingSchedulerController(){}
    
     webService static String getESRIToken()
     {
        String error = 'An error occured with your request. Please check your internet connection.';
        String returnRes;
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        req.setEndpoint(ArcGISauth);
        req.setMethod('POST');
        req.setBody('client_id=' + EncodingUtil.urlEncode(ESRIClientID,'UTF-8')+'&client_secret='+EncodingUtil.urlEncode(ESRIClientSecret,'UTF-8')+'&grant_type='+'client_credentials'+'&expiration='+'8000');
        try{
            res = h.send(req);
            System.debug(res.getBody());
            //JSONParser parser = JSON.createParser(res.getBody());
            /*while (parser.nextToken() != null)
            {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)
                    && (parser.getText() == 'access_token'))
                {
                    parser.nextToken();
                    returnRes = parser.getText();
                    break;
                }
                else if((parser.getCurrentToken() == JSONToken.FIELD_NAME)
                    && (parser.getText() == 'error'))
                {
                    //System.debug(res.getBody());
                    returnRes = res.getBody();
                    break;
                }
                else
                {
                    System.debug('ERROR+++ '+ res.getStatus());
                    System.debug('ERROR BODY+++ '+ res.getBody());
                    System.debug('STATUS CODE+++ '+ res.getStatusCode());
                    returnRes = error;
                }
            }*/
        }
        catch(System.CalloutException e){
            System.debug('Callout error: '+ e);
            System.debug(res.toString());
        }
        //return returnRes;
        return res.getBody();
    }
    
    webService static String getRecords(String dt, String storeId)
    {
        List<Object> resourceList = new List<Object>();
        List<Object> eventList = new List<Object>();
        List<Object> MAeventList = new List<Object>();
        List<Object> settings = new List<Object>();
        List<Object> WOList = new List<Object>();
        List<Object> objList; // = new List<Object>();
        Map<String, Object> geometry;
        Map<String, Object> attributes;
        Map<String, Object> obj;
        //Map<String, Object> errors = new Map<String, Object>();
        //List<Map<String, Object>> features = new List<Map<String, Object>>();
        //Map<String, List<Object>> generic = new Map<String, List<Object>>();
        //Map<String, Map<String, Object>> master  = new  Map<String, Map<String, Object>>();
        //System.debug(dt);
        try
        {
            if(String.isNotBlank(dt) && String.isNotBlank(storeId))
            {
                //Set up Depots first for the day
                depotSettings(dt, storeId);
                //Set up Resources and Routes with skills second for the day
                setupResource(dt, storeId);
                //Set up breaks and WOs that have been assigned to Resources/Routes for the day
                setupEvents(dt, storeId);
                //Set up breaks and WOs that have been assigned to Resources/Routes for the day
                setupMAEvents(dt, storeId);
                //Set up rest of work orders that are not assigned for the day
                setupWO(dt, storeId);
                
                /*
                //Resource Query
                if(!resourceList.isEmpty())
                {

                }
                else{
                    
                }
                //SF Event Query
                //Equery += rId + 'AND ActivityDate =' + dt;
                if(!eventList.isEmpty()){
                    
                }
                else{
                    
                }
                
                //Custom MA_Event query
                if(!MAeventList.isEmpty()){
                    
                }
                else{
                    
                }
                
                //Settings Query
                if(!settings.isEmpty())
                {
                    
                }
                else
                {
                    
                }
                */
                
                //generic.put('features', features);
               // master.put('orders', generic);
            }
            else
            {
                errors.put('success', false);
                String e = String.isNotBlank(dt) ? ' No Date selected. Select a Date on the calendar to optimize.' : null; 
                String e2 = String.isNotBlank(storeId) ? ' No store has been selected.' : null;
                errors.put('error1', e);
                errors.put('error2', e2);
                master.put('error', errors); 
            }
        }
        catch(Exception ex)
        {
            errors.put('success', false);
            errors.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
            master.put('error', errors);
            //features.add(errors);
        }
        return JSON.serialize(master);
    }
    
    //private static List<Object> setupResource(String dt, String storeId)
    private static void setupResource(String dt, String storeId)
    {
        Map<String, Object> geometry;
        Map<String, Object> attributes;
        Map<String, Object> obj;
        List<Object> routes = new List<Object>();
        Set<Object> rId = new Set<Object>();
        List<sObject> resourceList = new List<sObject>();
        features = new List<Map<String, Object>>();
        //Map<String, List<Object>> generic = new Map<String, List<Object>>();
        string Rquery = 'SELECT Id, Name, Active__c, Available_Time_Window__c, Crew_Size__c, RbA_User__c, Resource_Type__c, Retail_Location__c,(SELECT Id, Name, RbA_Skill__c, Type__c FROM Resource_Skill__c) FROM Resource__c WHERE  Retail_Location__c =';
        Rquery += storeId;
        resourceList = Database.query(Rquery);
        if(!resourceList.isEmpty())
        {
            for(sObject r : resourceList)
            {
                rId.add(r.get('RbA_User__c'));
            }
        }
        else{
            
        }
        
        
        
        
        for(List<SObject> l : [SELECT Id,Name, Active__c, Available_Time_Window__c, Crew_Size__c, RbA_User__c, Resource_Type__c, Retail_Location__c,(SELECT Id, Name, RbA_Skill__c, Type__c FROM Resource_Skills__r) FROM Resource__c WHERE  Retail_Location__c =: storeId])
        {
            for(SObject res : l)
            {
                
            }
            
        }
        
        //return routes;
    }
    //private static List<Object> setupEvents(String dt, String storeId)
    private static void setupEvents(String dt, String storeId)
    {
        Map<String, Object> geometry;
        Map<String, Object> attributes;
        Map<String, Object> obj;
        List<Object> events = new List<Object>();
        features = new List<Map<String, Object>>();
        //Map<String, List<Object>> generic = new Map<String, List<Object>>();
        //string Equery = 'SELECT Id, OwnerId, Type, StartDateTime, EndDateTime, ActivityDate, DurationInMinutes, WhoId, WhatId, ActivityDateTime FROM Event WHERE Owner =:';
       /* for(List<SObject> l : [SELECT Id, OwnerId, Type, StartDateTime, EndDateTime, ActivityDate, DurationInMinutes, WhoId, WhatId, ActivityDateTime FROM Event WHERE Owner =: ])
        {
            for(SObject ev : l)
            {
                
            }
            
        }*/
        //Set master instead
        //return events;
    }
    //private static List<Object> setupMAEvents(String dt, String storeId)
    private static void setupMAEvents(String dt, String storeId)
    {
        Map<String, Object> geometry;
        Map<String, Object> attributes;
        Map<String, Object> obj;
        List<Object> MAevents = new List<Object>();
        features = new List<Map<String, Object>>();
        //Map<String, List<Object>> generic = new Map<String, List<Object>>();
        //string MAEquery = 'SELECT Id, Name, StartDateTime__c, EndDateTime__c, RbA_Work_Order__c, Resource__c, Resource__r.Active__c, Resource__r.Available_Time_Window__c, Resource__r.Crew_Size__c, Resource__r.RbA_User__c, Resource__r.Resource_Type__c, Resource__r.Retail_Location__c FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__r.Appointment_Date__c =';
        for(List<SObject> l : [SELECT Id, Name, StartDateTime__c, EndDateTime__c, RbA_Work_Order__c, Resource__c, Resource__r.Active__c, Resource__r.Available_Time_Window__c, Resource__r.Crew_Size__c, Resource__r.RbA_User__c, Resource__r.Resource_Type__c, Resource__r.Retail_Location__c FROM MA_Scheduler_Event__c WHERE RbA_Work_Order__r.Appointment_Date__c =: Date.valueOf(dt)])
        {
            for(SObject MAev : l)
            {
                
            }
            
        }
        //Set master
        //return MAevents;
    }
    //private static List<Object> setupWO(String dt, String storeId)
    private static void setupWO(String dt, String storeId)
    {
        Map<String, Object> geometry;
        Map<String, Object> attributes;
        Map<String, Object> obj;
        List<Object> wo2 = new List<Object>();
        features = new List<Map<String, Object>>();
        //Map<String, List<Object>> generic = new Map<String, List<Object>>();
        
        try
        {
            for(List<SObject> l : [SELECT Id, Name, Appointment_Date__c, Appointment_Duration__c, Appointment_Start_Time__c, Appointment_End_Time__c, Alternate_End_Time__c, Alternate_Start_Time__c, Zip__c, Recommended_Crew_Size__c, Street__c, State__c, City__c,Country__c, Work_Order_Type__c, Account__r.Store_Location__r.Active_Store_Configuration__c,(SELECT Id, RbA_Skill__c FROM Work_Order_Required_Skills__r)FROM RbA_Work_Order__c WHERE Appointment_Date__c =: Date.valueOf(dt) AND Account__r.Store_Location__r.Active_Store_Configuration__c =: storeId])
            {
                //system.debug(l);
                for(SObject wo : l)
                {
                    obj = new Map<String, Object>();
                    wo2.add(wo.Id);
                    //Stuff to be GeoCode - Need to see hwo we want to GeoCode everything **If latlngs are avaiable we can create the geometry here
                    geoCodeAddress = new Map<String, Object>();
                    geoCodeAddress.put('id', wo.get('Id'));
                    geoCodeAddress.put('city', wo.get('City__c'));
                    geoCodeAddress.put('state', wo.get('State__c'));
                    geoCodeAddress.put('country', wo.get('Country__c'));
                    geoCodeAddress.put('zip', wo.get('Zip__c'));
                    geoCodeAddress.put('street', wo.get('Street__c'));
                    //master.put('geocode', geoCodeAddress);
                    //Create geometry stuff stuff blank or not **will update after geocode
                    geometry =  new Map<String, Object>();
                    geometry.put('x', '');
                    geometry.put('y', '');
                    obj.put('geometry', geometry);
                    //Attributes stuff
                    attributes = new Map<String, Object>();
                    attributes.put('Name', wo.get('Id'));
                    attributes.put('WOName', wo.get('Name'));
                    attributes.put('ServiceTime', wo.get(' Appointment_Duration__c'));
                    attributes.put('TimeWindowStart1', wo.get('Appointment_Start_Time__c'));
                    attributes.put('TimeWindowEnd1', wo.get('Appointment_End_Time__c'));
                    attributes.put('TimeWindowStart2', wo.get('Id'));
                    attributes.put('TimeWindowEnd2', wo.get('Id'));
                    attributes.put('MaxViolationTime1', wo.get('Id'));
                    attributes.put('MaxViolationTime2', wo.get('Id'));
                    attributes.put('DeliveryQuantities', wo.get('Id'));
                    attributes.put('PickupQuantities', wo.get('Id'));
                    attributes.put('Revenue', wo.get('Id'));
                    string specialty = wo.get('Work_Order_Type__c') + '' + wo.get('RbA_Skill__c');
                    attributes.put('SpecialtyNames', specialty);
                    attributes.put('AssignmentRule', wo.get('Id'));
                    attributes.put('CurbApproach', wo.get('Id'));
                    attributes.put('RouteName', wo.get('Id'));
                    attributes.put('Sequence', wo.get('Id'));
                    obj.put('attributes', attributes);
                    //features.add(obj);
                    
                    
                }
            }
            //generic.put('features', features);
            //master.put('orders', generic);
        }
        catch(Exception ex)
        {
            //errors.put('success', false);
            //errors.put('error', ex.getLineNumber() + ': ' + ex.getMessage());
            //master.put('error', errors);
            //features.add(errors);
        }
        //Set master
        //return wo2;
    }
    //private static List<Object> depotSettings(String dt, String storeId)
    private static void depotSettings(String dt, String storeId)
    {
        Map<String, Object> obj;
        Map<String, Object> geometry;
        Map<String, Object> attributes;
        features = new List<Map<String, Object>>(); //List of Maps
        //Map<String, List<Object>> generic = new Map<String, List<Object>>        
        try
        {
            Date d = Date.valueOf(dt);
            DateTime dateT = (DateTime)d;
            String dayOfWeek = dateT.format('EEEE', 'America/New_York');
            //settingsQuery += '\'' + storeId + '\' LIMIT 1';
            Map<Id, sObject> settings = new Map<Id, sObject>([SELECT Id, Store__c, Name, Store__r.BillingCity, Store__r.BillingStreet, Store__r.BillingStateCode, Store__r.BillingState, Store__r.BillingPostalCode, Store__r.BillingCountry, Store__r.BillingLongitude, Store__r.BillingLatitude FROM Store_Configuration__c WHERE Id =: storeId LIMIT 1]);
            //settingsQuery += 'storeId LIMIT 1';
            //settings = Database.query(settingsQuery);
            for(List<SObject> l : [SELECT Id, Name, Resource_Id__c, Store_Id__c, Settings__c FROM MA_Scheduler_Settings__c WHERE  Store_Id__c =: storeId])
            {
                for(SObject s : l)
                {
                    obj = new Map<String, Object>();
                    geometry = new Map<String, Object>();
                    attributes = new Map<String, Object>();
                    //Store settings
                    if(settings.containsKey((String)s.get('Store_Id__c')) && s.get('Resource_Id__c') == null)
                    {
                        Store_Configuration__c storeConfig = (Store_Configuration__c)settings.get((String)s.get('Store_Id__c'));

                        if(storeConfig.Store__r.BillingLatitude == null || storeConfig.Store__r.BillingLongitude == null)
                        {
                            features = new List<Map<String, Object>>();
                            objLists = new Map<String, List<Object>>();
                            geoCodeAddress = new Map<String, Object>();
                            geoCodeAddress.put('id', storeConfig.Id /*settings.get((String)s.get('Store_Id__c')).get('Store__c')*/);
                            geoCodeAddress.put('storeAcct', storeConfig.Store__c);
                            geoCodeAddress.put('city', storeConfig.Store__r.BillingCity);
                            geoCodeAddress.put('state', storeConfig.Store__r.BillingState);
                            geoCodeAddress.put('country', storeConfig.Store__r.BillingCountry);
                            geoCodeAddress.put('zip', storeConfig.Store__r.BillingPostalCode);
                            geoCodeAddress.put('street', storeConfig.Store__r.BillingStreet);
                            features.add(geoCodeAddress);
                            objLists.put('features', features);
                            master.put('geocode', objLists);
                            geometry.put('x', '');
                            geometry.put('y', '');
                            attributes.put('Name', storeConfig.Id);
                            //System.debug(geoCodeAddress);

                        }
                        else
                        {
                            geometry.put('x', storeConfig.Store__r.BillingLongitude);
                            geometry.put('y', storeConfig.Store__r.BillingLatitude);
                            //Add to obj
                            //obj.put('geometry', geometry);
                            //Set Depot name as StoreId
                            attributes.put('Name', storeConfig.Id);
                        }
                        Boolean storeFlag = false;
                        JSONParser parser = JSON.createParser((String)s.get('Settings__c'));
                        while (!storeFlag && parser.nextToken() != null)
                        {
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'timezone'))
                            {
                                parser.nextToken();
                                dayOfWeek = dateT.format('EEEE', parser.getText());
                            }
                            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'storeHours'))
                            {
                                //storeFlag = true;
                                parser.nextToken();
                                while (!storeFlag && parser.nextToken() != JSONToken.END_OBJECT)
                                {
                                  if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && parser.getText() == dayOfWeek.toLowercase())
                                   {
                                        parser.nextToken();
                                        //system.debug(parser.getText());
                                        if(parser.getCurrentToken() == JSONToken.START_ARRAY)
                                        {
                                            while(!storeFlag && parser.nextToken() != JSONToken.END_ARRAY)
                                            {
                                                //system.debug(parser.getText());
                                                if((parser.getCurrentToken() == JSONToken.FIELD_NAME) && parser.getText() == 'start'){
                                                    parser.nextToken();
                                                    attributes.put('TimeWindowStart1', parser.getText());
                                                }
                                                else if((parser.getCurrentToken() == JSONToken.FIELD_NAME) && parser.getText() == 'end'){
                                                    parser.nextToken();
                                                    attributes.put('TimeWindowEnd1', parser.getText());
                                                    //break;
                                                    storeFlag = true;
                                                }
                                            }
                                            //storeFlag = true;
                                        }
                                        else
                                        {
                                            //system.debug(parser.getText());
                                           if((parser.getCurrentToken() == JSONToken.FIELD_NAME) && parser.getText() == 'start'){
                                                parser.nextToken();
                                                attributes.put('TimeWindowStart1', parser.getText());
                                            }
                                            else if((parser.getCurrentToken() == JSONToken.FIELD_NAME) && parser.getText() == 'end'){
                                                parser.nextToken();
                                                attributes.put('TimeWindowEnd1', parser.getText());
                                                //break;
                                                storeFlag = true;
                                            }
                                        }
                                    }
                                    else if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)) {
                                        while (parser.nextToken() != JSONToken.END_ARRAY) {}
                                    }
                                }
                            }
                        }
                        features = new List<Map<String, Object>>();
                        objLists = new Map<String, List<Object>>();
                        configs.put((String)s.get('Store_Id__c'), (String)s.get('Settings__c'));
                        obj.put('attributes', attributes);
                        obj.put('geometry', geometry);
                        features.add(obj);
                        objLists.put('features', features);
                        master.put('depots', objLists);
                    }
                    else
                    {
                        //Resource settings
                        if(s.get('Resource_Id__c') != null){
                            configs.put((String)s.get('Resource_Id__c'), (String)s.get('Settings__c'));
                        }
                        else{
                            configs.put((String)s.get('Store_Id__c'), (String)s.get('Settings__c'));
                        }
                    }
                }
            } 
        }
        catch(Exception ex)
        {
            features = new List<Map<String, Object>>();
            objLists = new Map<String, List<Object>>();
            errors.put('success', false);
            errors.put('DepotError', ex.getLineNumber() + ': ' + ex.getMessage());
            features.add(errors);
            objLists.put('error', features);
            master.put('error', objLists);
        }
        //Set master
        //return settings;
    }
    
    
    
    private class SR{
        Integer wkid;
        private SR(){
            wkid= 4326;
        }
    } 
}
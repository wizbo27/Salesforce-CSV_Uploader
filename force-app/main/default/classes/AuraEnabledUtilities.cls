public with sharing class AuraEnabledUtilities {
    public class selectOption {
        public SelectOption(String value, String label) {
            this.value = value;
            this.label = label;
        }
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String value {get;set;}
    }

    @AuraEnabled
    public static List < selectOption > getSObjects() {
        //Map<String, String> sObjectNamebyLabel = new Map<String, String>();
        List < selectOption > options = new List < selectOption > ();
        for (SObjectType objectType: Schema.getGlobalDescribe().values()) {
            DescribeSObjectResult sObjectDescribe = objectType.getDescribe();
            if (sObjectDescribe.isAccessible() && sObjectDescribe.isQueryable()) {
                //sObjectNamebyLabel.put(sObjectDescribe.getLabel(),sObjectDescribe.getName());
                options.add(new selectOption(sObjectDescribe.getName(), sObjectDescribe.getLabel()));
            }
        }
        return options;
    }
    @AuraEnabled
    public static List < selectOption > getFields(String objectAPIName) {
        //Map<String, String> sObjectNamebyLabel = new Map<String, String>();
        List < selectOption > options = new List < selectOption > ();
        Map < String, Schema.SObjectField > fieldMap = Schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap();
        for (Schema.SObjectField sfield: fieldMap.Values()) {
            schema.describefieldresult dfield = sfield.getDescribe();
            options.add(new selectOption(dfield.getname(), dfield.getLabel()));
        }
        return options;
    }
    @AuraEnabled
    public static String dbInsert(List < sObject > sObjects) {
        insert(sObjects);
        return 'Success';
    }
    @AuraEnabled
    public static String dbDelete(List < sObject > sObjects) {
        delete(sObjects);
        return 'Success';
    }
    @AuraEnabled
    public static String dbUpdate(List < sObject > sObjects) {
        update(sObjects);
        return 'Success';
    }
    @AuraEnabled
    public static String dbUpsert(List < sObject > sObjects,String fieldAPI,String objectAPI) {
        Schema.SObjectField f = Schema.getGlobalDescribe().get(objectAPI).getDescribe().fields.getMap().get(fieldAPI);
        Database.upsert(sObjects, f);
        return 'Success';
    }
    @AuraEnabled
    public static String dbUpsert(List < sObject > sObjects,String fieldAPI,String objectAPI,String otherApexClassName,String otherApexMethodName) {
        Schema.SObjectField f = Schema.getGlobalDescribe().get(objectAPI).getDescribe().fields.getMap().get(fieldAPI);
        Database.upsert(sObjects, f);
        if(otherApexClassName!=null&&otherApexMethodName!=null){
            Callable extension = (Callable) Type.forName(otherApexClassName).newInstance();
            extension.call(otherApexMethodName, new Map<String, Object> { 'sobjects' => sObjects });
        }
        return 'Success';
    }
    @AuraEnabled
    public static String dbUpdateWExternalKey(List < sObject > sObjects,String fieldAPI,String objectAPI) {
        system.savePoint sp = database.setSavepoint();
        Schema.SObjectField f = Schema.getGlobalDescribe().get(objectAPI).getDescribe().fields.getMap().get(fieldAPI);
        try {
        List<Id> cleanUpList =new List<Id>();
        Integer success=0;
        String Errors='';
        List<Database.upsertResult> urs = Database.upsert(sObjects, f,false);
        for(Database.upsertResult ur:urs){
           	if(ur.isCreated()&&ur.isSuccess())cleanUpList.add(ur.getId());
            if(ur.isSuccess()&&!ur.isCreated())success++;
            else if(!ur.isCreated()) Errors+=ur.getId()+' '+(ur.getErrors())[0].getMessage();
        }
        String Output='';
        Integer insertedItemsCount = cleanUpList.size();
        try{
        	if(!cleanUpList.isEmpty())Database.delete(cleanUpList);
        }catch(Exception e){Database.rollback(sp);
            DMLException ce = new DMLException();
            ce.setMessage('New lines have been inserted and we could not remove them. No changes where saved.');
            throw ce;
        }
        Output=success+' Records Updated Successfully';
        if(insertedItemsCount>0)Output+='** '+insertedItemsCount+' Lines where not found in salesforce **';
        if(Errors!='')Output+=' but we had some errors -> '+Errors;

        return Output;

        } catch (DmlException e) {return 'Failed' + e.getMessage();}
    }
    @AuraEnabled
    public static String dbUpdateWExternalKey(List < sObject > sObjects,String fieldAPI,String objectAPI,Boolean onBatchCompletionCallOtherApex,String otherApexClassName,String otherApexMethodName) {
        system.savePoint sp = database.setSavepoint();
        Schema.SObjectField f = Schema.getGlobalDescribe().get(objectAPI).getDescribe().fields.getMap().get(fieldAPI);
        try {
        List<Id> cleanUpList =new List<Id>();
        List<sObject> updatedRecords = new List<sObject>();
        String Errors='';
        List<Database.upsertResult> urs = Database.upsert(sObjects, f,false);
        for(Database.upsertResult ur:urs){
           	if(ur.isCreated()&&ur.isSuccess())cleanUpList.add(ur.getId());
            if(ur.isSuccess()&&!ur.isCreated())updatedRecords.add(ur.id.getSobjectType().newSObject(ur.id));
            else if(!ur.isCreated()) Errors+=' '+(ur.getErrors())[0].getMessage();
        }
        String Output='';
        Integer insertedItemsCount = cleanUpList.size();
        try{
        	if(!cleanUpList.isEmpty())Database.delete(cleanUpList);
        }catch(Exception e){Database.rollback(sp);
            DMLException ce = new DMLException();
            ce.setMessage('New lines have been inserted and we could not remove them. No changes where saved.');
            throw ce;
        }
        Output=updatedRecords.size()+' Records Updated Successfully';
        if(insertedItemsCount>0)Output+='** '+insertedItemsCount+' Lines where not found in salesforce **';
        if(Errors!='')Output+=' but we had some errors -> '+Errors;

        if(onBatchCompletionCallOtherApex&&otherApexClassName!=null&&otherApexMethodName!=null){
            Callable extension = (Callable) Type.forName(otherApexClassName).newInstance();
            extension.call(otherApexMethodName, new Map<String, Object> { 'sobjects' => updatedRecords });
        }

        return Output;

        } catch (DmlException e) {return 'Failed' + e.getMessage();}
    }
    @AuraEnabled
    public static List<sObject> getRecords(List<String> fieldAPIs,String objectAPI) {
        String query = 'SELECT '+String.join(fieldAPIs, ',')+' FROM '+objectAPI;
        return Database.query(query);
    }
    @AuraEnabled
    public static List<sObject> getRecords(String query) {
        return Database.query(query);
    }

    @AuraEnabled
    public static string sfAPI(String endpointPath,String method){
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(System.URL.getSalesforceBaseURL().toExternalForm()+endpointPath);
            req.setMethod(method);
            req.setHeader('Authorization',  'Bearer ' + getSessionIdFromVFPage());
            Http http = new Http();
            HTTPResponse res = http.send(req);
            return res.getBody();
        } catch (Exception e) { return 'Failed' + e.getMessage();}
    }

    private static String getSessionIdFromVFPage(){
        String content='Start_Of_Session_Id 123456 End_Of_Session_Id';
        if(!Test.isRunningTest())content = Page.getSessionId.getContent().toString();
        Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
                e = content.indexOf('End_Of_Session_Id');
        return content.substring(s, e);
    }

    @AuraEnabled(cacheable = false)
    public static String publishEvent(sObject eventToPublish) {
        String ret='success';
        Database.SaveResult sr = EventBus.publish(eventToPublish);

        if (!sr.isSuccess()) {
            for(Database.Error err : sr.getErrors()) {
                System.debug('Error returned: ' + err.getStatusCode() +' - ' +err.getMessage());
                            ret='failed';            
            }
        }       
        
        return ret;
    }
    
    

}
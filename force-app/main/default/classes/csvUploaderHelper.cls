public without sharing class csvUploaderHelper extends VisualEditor.DynamicPickList{
    
    @AuraEnabled
    public static List<csvUploader_Mapping__mdt> getSavedMDMappings() {
        return [SELECT MasterLabel,DeveloperName,Synchronous_Limit__c,Help_Text__c,Template_Url__c,
                DML_Type__c,ExternalIdFieldAPI__c,Mapping__c,ObjectAPI__c,ApexClass__c,ApexMethod__c 
                FROM csvUploader_Mapping__mdt];
    }
    @AuraEnabled
    public static String dbBatchDML(List <sObject> sObjects,string dmlType) {
        DynamicBatchClass_Batch batch = new DynamicBatchClass_Batch(sObjects, dmlType);
        batch.triggeringProcessName='CSVUploader';
        batch.notifyOnCompletion=true;
        system.scheduleBatch(batch, 'CSVUploader '+UserInfo.getName(), 0);
        return 'Success';
    }
    @AuraEnabled
    public static String dbBatchUpdateWExternalKey(List <sObject> sObjects,String fieldAPI,String objectAPI,Boolean onBatchCompletionCallOtherApex,String otherApexClassName,String otherApexMethodName) {
        DynamicBatchClass_Batch batch = new DynamicBatchClass_Batch(sObjects, 'updateExternal');
        batch.triggeringProcessName='CSVUploader';
        batch.notifyOnCompletion=true;
        batch.objectAPI=objectAPI;
        batch.fieldAPI=fieldAPI;
        batch.onBatchCompletionCallOtherApex=onBatchCompletionCallOtherApex;
        batch.otherApexClassName=otherApexClassName;
        batch.otherApexMethodName=otherApexMethodName;
        system.scheduleBatch(batch, 'CSVUploader '+UserInfo.getName(), 0);
        return 'Success';
    }

    public override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows  myValues = new VisualEditor.DynamicPickListRows();
        for(csvUploader_Mapping__mdt data:[SELECT MasterLabel,DeveloperName,Synchronous_Limit__c,Template_Url__c,
                DML_Type__c,ExternalIdFieldAPI__c,Mapping__c,ObjectAPI__c,Help_Text__c 
                FROM csvUploader_Mapping__mdt])
        {
            VisualEditor.DataRow value1 = new VisualEditor.DataRow(data.MasterLabel,data.DeveloperName);
            myValues.addRow(value1);
        }
        return myValues;
    }
    public override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow(null, null);
        return defaultValue;
    }
}
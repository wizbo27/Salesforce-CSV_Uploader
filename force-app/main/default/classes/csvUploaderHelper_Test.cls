@IsTest
public with sharing class csvUploaderHelper_Test {
    @IsTest
    static void dbBatchDML(){
        Contact c = new Contact(FirstName='John',LastName='Snow',GID__c='Z00312IU');
        Test.startTest();
            csvUploaderHelper.dbBatchDML(new List<Contact>{c}, 'insert');
        Test.stopTest();
    }
    @IsTest
    static void dbBatchUpdateWExternalKey(){
        Contact c = new Contact(FirstName='John',LastName='Snow',GID__c='Z00312IU');
        Test.startTest();
            csvUploaderHelper.dbBatchUpdateWExternalKey(new List<Contact>{c}, 'GID__c', 'Contact',false,null,null);
        Test.stopTest();
    }
    @IsTest
    static void getSavedMDMappings(){
        Test.startTest();
            csvUploaderHelper.getSavedMDMappings();
        Test.stopTest();
    }
    @IsTest
    static void getValues(){
        Test.startTest();
        csvUploaderHelper apex = new csvUploaderHelper();
        apex.getValues();
        Test.stopTest();
    }
    @IsTest
    static void getDefaultValue(){
        Test.startTest();
        csvUploaderHelper apex = new csvUploaderHelper();
        apex.getDefaultValue();
        Test.stopTest();
    }
}
@isTest
public with sharing class AuraEnabledUtilities_Test {

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"example":"test"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    static void getSObjects(){
        Test.startTest();
        AuraEnabledUtilities.getSObjects();
        Test.stopTest();
    }
    @IsTest
    static void getFields(){
        Test.startTest();
        AuraEnabledUtilities.getFields('Contact');
        Test.stopTest();
    }
    @IsTest
    static void dbInsert(){
        Contact c = new Contact(FirstName='John',LastName='Snow');
        Test.startTest();
        AuraEnabledUtilities.dbInsert(new List<Contact>{c});
        Test.stopTest();
    }
    @IsTest
    static void dbUpdate(){
        Contact c = new Contact(FirstName='John',LastName='Snow');
        insert c;
        Test.startTest();
        AuraEnabledUtilities.dbUpdate(new List<Contact>{c});
        Test.stopTest();
    }
    @IsTest
    static void dbUpdateWExternalKey(){
        Contact c = new Contact(FirstName='John',LastName='Snow',GID__c='Z00312IU');
        insert c;
        Test.startTest();
        AuraEnabledUtilities.dbUpdateWExternalKey(new List<Contact>{c}, 'GID__c', 'Contact');
        Test.stopTest();
    }
    @IsTest
    static void dbUpdateWExternalKeyCallable(){
        Contact c = new Contact(FirstName='John',LastName='Snow',GID__c='Z00312IU');
        insert c;
        Test.startTest();
        AuraEnabledUtilities.dbUpdateWExternalKey(new List<Contact>{c}, 'GID__c', 'Contact',false,null,null);
        Test.stopTest();
    }
    @IsTest
    static void dbUpsert(){
        Contact c = new Contact(FirstName='John',LastName='Snow',GID__c='Z00312IU');
        insert c;
        Test.startTest();
        AuraEnabledUtilities.dbUpsert(new List<Contact>{c}, 'GID__c', 'Contact');
        Test.stopTest();
    }
    @IsTest
    static void dbUpsertCallable(){
        Contact c = new Contact(FirstName='John',LastName='Snow',GID__c='Z00312IU');
        insert c;
        Test.startTest();
        AuraEnabledUtilities.dbUpsert(new List<Contact>{c}, 'GID__c', 'Contact',null,null);
        Test.stopTest();
    }
    @IsTest
    static void getRecords(){
        Test.startTest();
        AuraEnabledUtilities.getRecords('SELECT ID FROM Contact');
        Test.stopTest();
    }
    @IsTest
    static void getRecordsFields(){
        Test.startTest();
        AuraEnabledUtilities.getRecords(new List<String>{'Id'},'Contact');
        Test.stopTest();
    }
    @IsTest
    static void dbDelete() {
        contact c =new contact(FirstName='john',lastname='snow');
        insert c;
        Test.startTest();
        AuraEnabledUtilities.dbDelete(new List<Contact>{c});
        Test.stopTest();
    }
    @IsTest
    static void sfAPI(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        system.assertEquals('{"example":"test"}',AuraEnabledUtilities.sfAPI('/tetst', 'GET'));
        Test.stopTest();
    }

    @IsTest
    static void publishEvent(){
        Test.startTest();
        String ret12=AuraEnabledUtilities.publishEvent(new pe_timeSheet__e(Active_Contact_Id__c='123546213',Active_Contact_Name__c='John Snow'));
        Test.stopTest();
        system.assertEquals('success', ret12);
    }

}
/*
 *	01/17/2019	Initial version
 */

@isTest
public class ContactBeforeInsertTriggerTests {

	@isTest
    public static void NumerciColumnsFilledTest() {
        test.startTest();
        Contact contact = new Contact();
        contact.LastName = 'Test';
        contact.Phone = 'adfadf1032450-290';
       	contact.MobilePhone = '89-0897kasdf,1';
        insert contact;
        test.stopTest();
        contact = [SELECT PhoneNumeric__c, MobileNumeric__c
               	FROM Contact
               	LIMIT 1];
        System.assert(contact.PhoneNumeric__c == '1032450290');
        System.assert(contact.MobileNumeric__c == '8908971');
    }
    
	@isTest
    public static void NumerciColumnsAreNullOnNullTest() {
        test.startTest();
        Contact contact = new Contact();
        contact.LastName = 'Test';
        insert contact;
        test.stopTest();
        contact = [SELECT PhoneNumeric__c, MobileNumeric__c
               	FROM Contact
               	LIMIT 1];
        System.assert(contact.PhoneNumeric__c == null);
        System.assert(contact.MobileNumeric__c == null);
    }
}
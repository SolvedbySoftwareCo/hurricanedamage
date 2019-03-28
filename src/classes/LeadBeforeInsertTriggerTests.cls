/*
 *	01/17/2019	Initial version
 */

@isTest
public class LeadBeforeInsertTriggerTests {

	@isTest
    public static void NumerciColumnsFilledTest() {
        test.startTest();
        Lead lead = new Lead();
        lead.LastName = 'Test Lead';
        lead.Phone = 'adfadf1032450-290';
        lead.MobilePhone = '89-0897kasdf,1';
        lead.Company = 'Test. CO';
        insert lead;
        test.stopTest();
        lead = [SELECT PhoneNumeric__c, MobileNumeric__c
               	FROM Lead
               	LIMIT 1];
        System.assert(lead.PhoneNumeric__c == '1032450290');
        System.assert(lead.MobileNumeric__c == '8908971');
    }
    
	@isTest
    public static void NumerciColumnsAreNullOnNullTest() {
        test.startTest();
        Lead lead = new Lead();
        lead.LastName = 'Test Lead';
        lead.Company = 'Test. CO';
        insert lead;
        test.stopTest();
        lead = [SELECT PhoneNumeric__c, MobileNumeric__c
               	FROM Lead
               	LIMIT 1];
        System.debug(lead);
        System.assert(lead.PhoneNumeric__c == null);
        System.assert(lead.MobileNumeric__c == null);
    }
}
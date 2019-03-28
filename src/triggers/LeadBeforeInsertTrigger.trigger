/*
 *	01/17/2019	Initial version
 */

trigger LeadBeforeInsertTrigger on Lead (before insert, before update) {
    if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
        for (Lead lead : Trigger.new) {
            lead.PhoneNumeric__c = lead.Phone == null ? null : lead.Phone.replaceAll('[^0-9]', '');
            lead.MobileNumeric__c = lead.MobilePhone == null ? null : lead.MobilePhone.replaceAll('[^0-9]', '');
        }
    }
}
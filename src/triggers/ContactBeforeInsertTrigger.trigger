/*
 *	01/17/2019	Initial version
 */

trigger ContactBeforeInsertTrigger on Contact (before insert, before update) {
    if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
        for (Contact contact : Trigger.new) {
            contact.PhoneNumeric__c = contact.Phone == null ? null : contact.Phone.replaceAll('[^0-9]', '');
            contact.MobileNumeric__c = contact.MobilePhone == null ? null : contact.MobilePhone.replaceAll('[^0-9]', '');
        }
    }
}
/*
 *	01/21/2019	Initial version
 */

trigger AccountBefore on Account (before insert) {
    if (trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
        for (Account account : Trigger.new) {
            account.PhoneNumeric__c = account.Phone == null ? null : account.Phone.replaceAll('[^0-9]', '');
        }
    }
}
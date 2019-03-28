trigger IncomingSMS on tdc_tsw__Message__c (before insert) {
    if (trigger.isBefore && (trigger.isInsert)) {
        for (tdc_tsw__Message__c sms : Trigger.new) {
            if(sms.Name == 'Incoming' && sms.tdc_tsw__Message_Text_New__c == '1'){
            	System.debug(sms);
            }
        }
    }
}
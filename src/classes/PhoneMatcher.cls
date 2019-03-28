/*
 *   01/17/2019  Initial version
 */ 

public class PhoneMatcher {
    public static Map<string, tdc_tsw__Question__c> questionMap;

    @testVisible
    private static boolean createLead(string body) {
            List<String> parts= new List<String>();
            parts = body.split('\n');
            Lead lead = new Lead();
            for(string part : parts) {
                if(part.indexOf('N:') == 0) {
                    List<string> names = part.replace('N:','').split(';');
                    lead.FirstName = names[0];
                    lead.LastName = names[1];
                }
                /*if(part.indexOf('ORG:') == 0) {
                    lead.Company__c = part.replace('ORG:','').replace(';','');
                }*/
                if(part.indexOf('ORG:') == 0) {
                    lead.Company = part.replace('ORG:','').replace(';','');
                }
                lead.Status = 'New';
                if(part.indexOf('EMAIL') == 0) {
                    if(part.indexOf('type=pref') > 0) {
                        lead.email = part.substringAfterLast(':');
                    }
                }
                if(part.indexOf('TEL') == 0) {
                    if(part.indexOf('type=pref') > 0) {
                        lead.phone = part.substringAfterLast(':');
                    }
                    if(part.indexOf('CELL') > 0 || part.indexOf('IPHONE') > 0) {
                        lead.MobilePhone =  part.substringAfterLast(':');
                    }
                }
                if(part.indexOf('ADR') == 0) {
                    if(part.indexOf('type=pref') > 0) {
                        List<string> address = part.substringAfterLast(':').split(';');
                        /*lead.MailingStreet = address[2];
                        lead.MailingCity = address[3];
                        lead.MailingState = address[4];
                        lead.MailingPostalCode = address[5];
                        lead.MailingCountry = address[6];*/

                    }
                }
            }
            try{
                insert lead;
                return true;
            } catch(Exception ex) {
                return false;
            }
    }
    
    @testVisible
    private static string addWildCard(string value) {
        string returnValue = '%';
        Integer i=0;
        do{
            if(i<value.length()){
                returnValue += value.substring(i,i+1) + '%';
            }
            i=i+1;
        }while(i < value.length());
        return returnValue;
    }
    
    @testVisible
    private static void updateField(string questionId, sobject obj, string value) {
        tdc_tsw__Question__c question = questionMap.get(questionId);
        obj.put(question.tdc_tsw__Question_Label__c, value);
    }
    
    @testVisible    
    private static string checkDisplay(string label, string value) { 
        if(!String.isEmpty(value)) {
            return label + value;
        }
        return '';
    }
    
     @testVisible
    private static string getAccountDisplay(string name, string industry, decimal sentUs) {
        string sentUsText = sentUs == null ? '0' : string.valueOf(sentUs);
        return checkDisplay('\nName: ', name) + checkDisplay('\nIndustry: ', industry) + checkDisplay('\nSent Us: ', sentUsText);
    }
    
    @testVisible
    private static string getContactLeadDisplay(string name, string phone, string mobilePhone, string email, string industry, string company) {
        return checkDisplay('\nName: ', name) + checkDisplay('\nIndustry: ', industry) + checkDisplay('\nCompany: ', company) + checkDisplay('\nPhone: ', phone) + checkDisplay('\nMobile: ', mobilePhone) + checkDisplay('\nEmail: ', email);                 
    }
    
    //Search for Contat by phone number
    @InvocableMethod(label='Get objects by phone number' description='Returns the list of objects and create into template message')
    public static void MatchContactOnPhoneNunber(List<tdc_tsw__Message__c> messages) {
        List<LookupResult__c> results = new List<LookupResult__c>();
        tdc_tsw__Message_Template__c template = new tdc_tsw__Message_Template__c();
        template.Name = messages[0].Id;
        List<string> searchTerms;
        boolean authorized = false;
        string requestingNumber = '';
        questionMap = new Map<string, tdc_tsw__Question__c>();
        string recordUpdatedTemplateId = [SELECT ID FROM tdc_tsw__Message_Template__c WHERE Name = 'Update completed' LIMIT 1][0].Id; 
        string recordUpSurveyId = [SELECT Id FROM tdc_tsw__Survey__c WHERE Name = 'Contact Info V2' LIMIT 1][0].Id;        
        List<tdc_tsw__Question__c> questionObjs = [SELECT Id, tdc_tsw__Question_Label__c,tdc_tsw__Question_Text__c FROM tdc_tsw__Question__c WHERE tdc_tsw__Survey__c = :recordUpSurveyId ORDER BY Id ASC NULLS FIRST];
    List<string> questions = new List<string>();
        for(tdc_tsw__Question__c question : questionObjs) {
            questionMap.put(question.Id, question);
        }
        string firstQuestion = new list<string>(questionMap.keySet())[0];
         List<String> choices = new List<String>{'1','2','3','4','5','6'};
         requestingNumber = messages[0].tdc_tsw__Sender_Number__c;
    if(requestingNumber != null) {
             requestingNumber = addWildCard(requestingNumber.right(10));
         }
    //Check if message came from an authorized number
    string query = 'SELECT ID, SMS_Lookup_Access__c FROM Contact Where (Phone like \'' + requestingNumber + '\' OR MobilePhone like \'' + requestingNumber + '\') AND SMS_Lookup_Access__c = true';
        List<Contact> requestingContacts = Database.query(query);
        tdc_tsw__Message__c updateSMS = [SELECT tdc_tsw__Attachments_Ids__c, ResponseTemplate__c, tdc_tsw__Related_Object_Id__c, tdc_tsw__Message__c, tdc_tsw__Message_Text_New__c, tdc_tsw__Related_Object__c, tdc_tsw__Contact__c, tdc_tsw__Question__c, tdc_tsw__Lead__c
                                          FROM tdc_tsw__Message__c
                                          WHERE ID = :messages[0].ID];
        if(requestingContacts.size() == 0) {
            template.tdc_tsw__SMSBodyNew__c = 'You are not authorized to access this function';
            insert template;
            updateSMS.ResponseTemplate__c = template.Id;
            updateSMS.ResponseRelatedObject__c = updateSMS.Id; 
        } else {
            integer counter = 1;
            string inMessage = '%' + updateSMS.tdc_tsw__Message_Text_New__c + '%';
            string outMessage = '';
            string phone = '';
            if(updateSMS.tdc_tsw__Message_Text_New__c != null) {
                phone = addWildCard(updateSMS.tdc_tsw__Message_Text_New__c.right(10));
            }
            integer key = 0;
            boolean performLookup = true;
            List<LookupResult__c> lookupResult = new List<LookupResult__c>(); 
            if(updateSMS.tdc_tsw__Attachments_Ids__c != null) {
                performLookup = false;
                if(updateSMS.tdc_tsw__Attachments_Ids__c.indexOf('015') == 0) {
                    string documentId = updateSMS.tdc_tsw__Attachments_Ids__c.left(18);
                    Document doc = [SELECT Type, Body 
                                    FROM Document
                                    WHERE ID = :documentId 
                                    LIMIT 1];
                    if(doc.Type == 'x-vcard') {
                        if(doc.body != null) {
                            boolean leadCreated = createLead(doc.body.tostring());
                            if(leadCreated) {
                                template.tdc_tsw__SMSBodyNew__c = 'The contact has been added to Salesforce as a Lead';
                            } else {
                                template.tdc_tsw__SMSBodyNew__c = 'Unable to create lead from the contact submitted';
                            }
                        } else {
                            template.tdc_tsw__SMSBodyNew__c = 'Unable to create lead from the contact submitted';
                        }
                    }else {
                        template.tdc_tsw__SMSBodyNew__c = 'Attachment is not a valid type';
                    }
                }
                insert template;
                updateSMS.ResponseTemplate__c = template.Id;
                updateSMS.tdc_tsw__Question__c = null;
                updateSMS.ResponseRelatedObject__c = updateSMS.Id; 
                update updateSMS;
            }
            if(questionMap.KeySet().contains(updateSMS.tdc_tsw__Question__c)) {
                List<string> qIds = new List<string>(questionMap.KeySet());
                if(updateSMS.tdc_tsw__Question__c == qIds[0] && !choices.contains(updateSMS.tdc_tsw__Message_Text_New__c)) {
                    performLookup = true;
                    updateSMS.tdc_tsw__Question__c = null;
                } else {
                    performLookup = false;
                    string tableName = '';
                    string objId = '';
                    if(updateSMS.tdc_tsw__Message_Text_New__c == '6') {
                        updateSMS.ResponseRelatedObject__c = updateSMS.Id; 
                        updateSMS.ResponseTemplate__c = recordUpdatedTemplateId;
                    } else {
                        if(updateSMS.tdc_tsw__Contact__c != null) {
                            tableName = 'Contact';
                            objId = updateSMS.tdc_tsw__Contact__c ;
                        }
                        if(updateSMS.tdc_tsw__Lead__c != null) {
                            tableName = 'Lead';
                            objId = updateSMS.tdc_tsw__Lead__c ;
                        }
                        query = 'SELECT FirstName, LastName, Phone, MobilePhone, Email FROM ' + tableName + ' WHERE ID = \'' + objId + '\' LIMIT 1';
                        sobject obj = Database.query(query);
                        if(updateSMS.tdc_tsw__Question__c != firstQuestion) {
                            UpdateField(updateSMS.tdc_tsw__Question__c, obj, updateSMS.tdc_tsw__Message_Text_New__c);
                            updateSMS.ResponseTemplate__c = firstQuestion;
                            updateSMS.ResponseRelatedObject__c = objId;
                            update obj;
                        }
                    }
                }
            }
            if(updateSMS.tdc_tsw__Message__c != null) {
                try{
                    key = Integer.valueOf(updateSMS.tdc_tsw__Message_Text_New__c);
                } catch(Exception ex) {
                    
                }
                lookupResult = [SELECT Key__C, ObjectId__c
                                                 FROM LookupResult__c
                                                 WHERE SMS_History__c = :updateSMS.tdc_tsw__Related_Object_Id__c
                                                   AND Key__c = :key];
                if(lookupResult.size() > 0) {
                    performLookup = false;
                    template.tdc_tsw__SMSBodyNew__c = 'Found';
                    updateSMS.ResponseRelatedObject__c = lookupResult[0].ObjectId__c; 
                    updateSMS.ResponseTemplate__c = firstQuestion;
                }
            }
            if(performLookup && lookupResult.size() == 0) {
                integer searchCounter = 0;
                while(performLookup) {
                    updateSMS.ResponseRelatedObject__c = updateSMS.ID;
                    System.debug('Lookup: ' + searchCounter + ' ' + inMessage);
                    List<Account> accounts = [SELECT Name, Sent_Us__c, Account_Type__c, Industry
                                                FROM Account
                                                WHERE Name like :inMessage AND (NOT Account_Type__c like '%Litigation File%') 
                                                ORDER BY Name];
                    for(Account account : accounts) {
                        outMessage += '\n\n' + account.Account_Type__c + getAccountDisplay(account.Name, account.Industry, account.Sent_Us__c);
                        List<AccountContactRelation> contacts = [SELECT contact.Phone, contact.MobilePhone, contact.Name, contact.Email, AccountId, contact.Industry__c
                                                    FROM AccountContactRelation
                                                    WHERE AccountId = :account.Id AND Primary_Contact__c = true
                                                    ORDER BY contact.Name];
                        if(contacts.size() > 0) {
                            outMessage += contacts.size() == 1 ? '\nAccount Contact:' : '\nAccount Contacts:';
                        } else {
                            outMessage += '\nAccount contains no contact';
                        }
                        for(AccountContactRelation contact : contacts) {
                            outMessage += getContactLeadDisplay(contact.contact.Name, contact.contact.Phone, contact.contact.MobilePhone, contact.contact.Email, contact.contact.Industry__c, null);
                            results.add(new LookupResult__c(SMS_History__c = updateSMS.Id, SMS_Template__c = template.Id, key__c = counter, ObjectId__c = contact.contact.Id, Name = contact.contact.Name));
                            counter++;
                        }
                    }
                    query = 'SELECT ID, Phone, MobilePhone, Name, Email, AccountId, Industry__c FROM Contact ' +  
                                    'WHERE Phone like \'' + phone + '\' OR MobilePhone like \'' + phone + '\' OR Name like \'' + inMessage + '\' ORDER BY Name';
                    List<Contact> contacts = Database.query(query);
                    if(contacts.Size() > 0) {
                        for(Contact contact : contacts) {
                            outMessage += '\n\nContact' + getContactLeadDisplay(contact.Name, contact.Phone, contact.MobilePhone, contact.Email, contact.Industry__c, null);
                            results.add(new LookupResult__c(SMS_History__c = updateSMS.Id, SMS_Template__c = template.Id, key__c = counter, ObjectId__c = contact.Id, Name = contact.Name));
                            counter++;
                            if(contact.AccountId != null) {
                                try {
                                    Account account = [SELECT Name, Sent_Us__c, Account_Type__c, Industry
                                                        FROM Account 
                                                        WHERE  (NOT Account_Type__c like '%Litigation File%')  AND ID = :contact.AccountId
                                                        LIMIT 1];                       
                                    outMessage += '\n' + account.Account_Type__c + getAccountDisplay(account.Name, account.Industry, account.Sent_Us__c);
                                } catch (Exception ex) {
                                    
                                }
                            }
                        }
                    } 
                    query = 'SELECT ID, Phone, MobilePhone, Name, Email, Industry, Company FROM Lead ' +  
                                    'WHERE Phone like \'' + phone + '\' OR MobilePhone like \'' + phone + '\' OR Name like \'' + inMessage + '\' ORDER BY Name';
                    List<Lead> leads = Database.query(query);
                    if(leads.Size() > 0) {
                        for(Lead lead : leads) {
                            outMessage += '\n\nLead' + getContactLeadDisplay(lead.Name, lead.Phone, lead.MobilePhone, lead.Email, lead.Industry, lead.Company);
                            results.add(new LookupResult__c(SMS_History__c = updateSMS.Id, SMS_Template__c = template.Id, key__c = counter, ObjectId__c = lead.Id, Name = lead.Name));
                            counter++;
                        }
                    }        
                    if(outMessage.length() > 0) {
                        performLookup = false;
                        if(results.size() > 0) {
                          outMessage += '\n\nSelect the number to edit the contact/lead: ';              
                            for(LookupResult__c result : results) {
                                outMessage += '\n' + result.Key__c + ': ' + result.Name;
                            }
                        }
                        if(outMessage.length() > 800) {  
                            outMessage = outMessage.left(800);
                            outMessage += '...\n\nThe search returned too many matches. Please narrow your search term.';
                        }
                        template.tdc_tsw__SMSBodyNew__c = outMessage;
                    } else {
                        
                        switch on searchCounter {
                            when 0 {    // when block 1
                                searchCounter++;
                                searchTerms = inMessage.split(' ');
                                if(searchTerms.size() > 1) {
                                    performLookup = true;
                                    inMessage = searchTerms[0].left(1) + '%' + searchTerms[1];
                                } else {
                                    performLookup = false;
                                    template.tdc_tsw__SMSBodyNew__c = 'No match found';
                                }
                            }  
                            when 1 {    // when block 2
                                searchCounter++;
                                if(searchTerms != null && searchTerms.size() > 1) {
                                    performLookup = true;
                                    inMessage = searchTerms[0] + ' ' + searchTerms[1].left(1) + '%';
                                } else {
                                    performLookup = false;
                                    template.tdc_tsw__SMSBodyNew__c = 'No match found';
                                }
                            }
                            when 2 {    // when block 3
                                performLookup = false;
                                template.tdc_tsw__SMSBodyNew__c = 'No match found';
                            }
                        }
                    }
                    if(performLookup == false) {
                        insert template;
                        for(LookupResult__c lookup : results) {
                            lookup.SMS_Template__c = template.Id;
                        }
                        insert results;
                        updateSMS.ResponseTemplate__c = template.Id;
                    }
                }
            }
        }
        update updateSMS; 
    } 
}

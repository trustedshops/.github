/**
 * Created by ra8275 on 23.01.24.
 * PO-16673
 * Description: REST service that will be used to create case for mails that is received in HubSpot.
 */
@RestResource(UrlMapping='/CreateMarketingEmail')
global with sharing class RESTCreateMarketingEmail extends RESTUtil {

    /**
    * REST method to Create a Case or EmailMessage
    */
    @HttpPost
    global static void acceptJSON() {
        RestResponse response = RestContext.response;
        try {
            RestRequest req = RestContext.request;
            Blob body = req.requestBody;
            String jsonString = body.toString();
            System.debug('###jsonString: ' + jsonString);
            CaseData caseData = (CaseData) JSON.deserialize(jsonString, CaseData.class);
            if (caseData == null) {
                sendJSONResponse(response, true, 400, 'The provided JSON could not be parsed.');
                return;

            } else {
                if (String.isBlank(caseData.sfAccountId) && String.isBlank(caseData.accountCustomerNumber)) {
                    sendJSONResponse(response, true, 400, 'Please provide sfAccountId or accountCustomerNumber');
                    return;
                }
                if (String.isBlank(caseData.sfContactId) && String.isBlank(caseData.contactEmail)) {
                    sendJSONResponse(response, true, 400,  'Please provide sfContactId or contactEmail.');
                    return;
                }

                List<Account> accounts = new List<Account>();
                List<Contact> contacts = new List<Contact>();
                List<shop__c> shops = new List<shop__c>();
                String shopId;

                if (String.isNotBlank(caseData.sfAccountId)) {
                    accounts = [SELECT Id FROM Account WHERE Id = :caseData.sfAccountId];
                    if(accounts.isEmpty()){
                        sendJSONResponse(response, true, 400, 'No Account exist in Salesforce with sfAccountId: ' + caseData.sfAccountId );
                        return ;
                    }
                } else if (String.isNotBlank(caseData.accountCustomerNumber)) {
                    accounts = [SELECT Id FROM Account WHERE customer_number__c = :caseData.accountCustomerNumber LIMIT 1];
                    if(accounts.isEmpty()){
                        sendJSONResponse(response, true, 400, 'No Account exist in Salesforce with accountCustomerNumber: ' + caseData.accountCustomerNumber );
                        return ;
                    }
                }
                if (String.isNotBlank(caseData.sfContactId)) {
                    contacts = [SELECT Id, language__c FROM Contact WHERE Id = :caseData.sfContactId];
                    if(contacts.isEmpty()){
                        sendJSONResponse(response, true, 400, 'No Contact exist in Salesforce with sfContactId: ' + caseData.sfContactId );
                        return ;
                    }
                } else if (String.isNotBlank(caseData.contactEmail)) {
                    contacts = [SELECT Id, language__c FROM Contact WHERE Email = :caseData.contactEmail LIMIT 1];
                    if(contacts.isEmpty()){
                        sendJSONResponse(response, true, 400, 'No Contact exist in Salesforce with contactEmail: ' + caseData.contactEmail );
                        return ;
                    }
                }
                if (String.isNotBlank(caseData.sfShopId)) {
                    shops = [SELECT Id, ts2_id__c FROM shop__c WHERE Id = :caseData.sfShopId LIMIT 1];
                } else if (String.isNotBlank(caseData.shopTSId)) {
                    shops = [SELECT Id,ts2_id__c FROM shop__c WHERE ts2_id__c = :caseData.shopTSId LIMIT 1];
                }

                if (!shops.isEmpty()) {
                    shopId = shops[0].Id;
                }
                if (caseData.caseRequired != null && caseData.caseRequired) {
                    String caseNumber = createCase(accounts[0].Id, contacts, shopId, caseData.Subject);
                    sendJSONResponse(response, false,200, 'Case successfully created with Case number : ' + caseNumber);
                } else {
                    createEmailMessage(accounts[0].Id, contacts,shops, caseData.Subject);
                    sendJSONResponse(response, false, 200, 'EMailMessage successfully created: ');
                }

            }
        } catch (Exception e) {
            System.debug('Exception: ' + e);
            sendJSONResponse(response, true, 500, e.getMessage());
        }
    }
    /**
     * @param accountId to map account to case
     * @param contacts to map contact id to case
     * @param shopId to map shop id to case
     * @param subject to map subject field of the case
     *to create a case with the data sending from hubspot if the case required is true
     * @return case number to send the response
     */

    private static String createCase(String accountId, List<Contact> contacts, String shopId, String subject) {
        Case c = new Case();
        c.AccountId = accountId;
        c.Shop__c = shopId;
        c.ContactId = contacts[0].Id;
        c.Case_Language__c = contacts[0].language__c;
        c.Reason = 'Marketing';
        c.Origin = 'Hubspot';
        c.Subject = subject;
        c.Status = 'New';

        insert c;
        String caseNumber = c.CaseNumber;
        return caseNumber;
    }

    /**
     * @param accountId to map account id to the email message
     * @param contacts to map contact id to the email message
     * @param shops to map tsid to the subject
     * @param subject to map subject of the email message
     */
    private static void createEmailMessage(String accountId, List<Contact> contacts,List<shop__c> shops, String subject) {
        EmailMessage emailMessage = new EmailMessage();
        emailMessage.RelatedToId = accountId;
        emailMessage.Subject = shops.isEmpty() ? subject : subject + 'TSID: ' + shops[0].ts2_id__c ;
        emailMessage.ToAddress = contacts[0].Id;
        emailMessage.FromName = 'Trusted Shops';
        emailMessage.FromAddress = 'members@trustedshops.com';
        emailMessage.Status = '0';
        insert emailMessage; // insert
    }


    private class CaseData {
        private String sfAccountId { get; set; }
        private String accountCustomerNumber { get; set; }
        private String sfContactId { get; set; }
        private String contactEmail { get; set; }
        private String sfShopId { get; set; }
        private String shopTSId { get; set; }
        private String Subject { get; set; }
        private Boolean caseRequired { get; set; }
    }
}
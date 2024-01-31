/**
 * Created by ra8275 on 23.01.24.
 */

@IsTest
private class RESTCreateMarketingEmail_Test {
    @TestSetup
    static void setupData() {

        Account testAccount = new Account (Name = 'TestAccount',  BillingCountryCode = 'AT', customer_number__c = 'D10000105');
        insert testAccount;

        Contact contact = new Contact(FirstName = 'John', LastName = 'Doe', Email = 'john.doe@email.com', language__c = 'EN', AccountId = testAccount.Id);
        insert contact;

        shop__c shop = new shop__c(Name = 'www.test-shop.de',ts2_id__c='XD8EB26008ED9C2257B6AF9C66CBAEBB7',contact__c = contact.Id,  url__c = 'www.test-shop.de', company_id__c = testAccount.Id );
        insert shop;
    }

    @IsTest
    private static void positiveCreateCaseWithAccountIdTest(){
        Boolean caseRequired = true;
        String json = getInputJSON(caseRequired, true, true, true,false,false);
        callEndPoint(json);

        // Assert
        System.assertEquals(200, RestContext.response.statusCode);
    }
    @IsTest
    private static void positiveCreateCaseWithoutIdsTest(){
        Boolean caseRequired = true;
        String json = getInputJSON(caseRequired, false, true,true,false,false);
        callEndPoint(json);

        // Assert
        System.assertEquals(200, RestContext.response.statusCode);
    }
    @IsTest
    private static void positiveCreateEmailMessageTest(){
        Boolean caseRequired = false;
        String json = getInputJSON(caseRequired, true, true,true,false,false);
        callEndPoint(json);

        // Assert
        System.assertEquals(200, RestContext.response.statusCode);
    }
    @IsTest
    private static void positiveCreateCaseWithoutRequiredAccountDataTest(){
        Boolean caseRequired = true;
        String json = getInputJSON(caseRequired, false, false,true,false,false);
        callEndPoint(json);

        // Assert
        System.assertEquals(404, RestContext.response.statusCode);
    }
    @IsTest
    private static void positiveCreateCaseWithoutRequiredContactDataTest(){
        Boolean caseRequired = true;
        String json = getInputJSON(caseRequired, false, true,false,false,false);
        callEndPoint(json);

        // Assert
        System.assertEquals(404, RestContext.response.statusCode);
    }
    @IsTest
    private static void positiveCreateCaseWithoNoAccountTest(){
        Boolean caseRequired = true;
        String json = getInputJSON(caseRequired, false, true,false,true,false);
        callEndPoint(json);

        // Assert
        System.assertEquals(404, RestContext.response.statusCode);
    }
    @IsTest
    private static void positiveCreateCaseWithoNoContactTest(){
        Boolean caseRequired = true;
        String json = getInputJSON(caseRequired, false, true,false,false,true);
        callEndPoint(json);

        // Assert
        System.assertEquals(404, RestContext.response.statusCode);
    }
    @IsTest
    private static void negativeTest(){
        String json = '';
        callEndPoint(json);

        // Assert
        System.assertEquals(404, RestContext.response.statusCode);
    }


    static Map<String, Object> callEndPoint(String jsonString) {
        Test.startTest();
        RestRequest request = new RestRequest();

        request.requestURI = 'services/apexrest/CreateCaseForHubSpot';  //Request URL
        request.httpMethod = 'POST';//HTTP Request Type
        request.requestBody = Blob.valueOf(jsonString);
        RestContext.request = request;

        RESTCreateMarketingEmail.acceptJSON();

        Test.stopTest();
        Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        return response;

    }
    private static String getInputJSON(Boolean caseRequired, Boolean isWithoutIds, Boolean isWithRequiredAccount,Boolean isWithRequiredContact,Boolean isWithNoAccount,Boolean isWithNoContact ){
        Account account = [SELECT Id, customer_number__c FROM Account LIMIT 1];
        Contact contact = [SELECT Id,language__c,Email FROM Contact LIMIT 1];
        shop__c shop = [SELECT Id, ts2_id__c FROM shop__c LIMIT 1];
        String accountId = isWithoutIds ? '' + account.Id: '';
        String contactId = isWithoutIds ? '' + contact.Id: '';
        String shopId = isWithoutIds ? '' + shop.Id: '';
        String accountCustomerNumber = isWithRequiredAccount ? '' + account.customer_number__c: '';
        String contactEmail = isWithRequiredContact ? '' + contact.Email: '';
        if(isWithNoAccount) {
            accountId = '000000000000000000';
        }
        if(isWithNoContact) {
            contactId = '000000000000000000';
        }

        String json = '{\n' +
                '		"sfAccountId": "' + accountId + '",\n' +
                '		"accountCustomerNumber": "' + accountCustomerNumber + '",\n' +
                '		"sfContactId": "' + contactId + '",\n' +
                '		"contactEmail": "' + contactEmail + '",\n' +
                '		"sfShopId": "' + shopId + '",\n' +
                '		"shopTSId": "' + shop.ts2_id__c + '",\n' +
                '		"subject": " ' + 'Congratulation to your first Review!", \n' +
                '		"caseRequired": ' + caseRequired + '\n' + '}';
        System.debug('json: ' + json);
        return json;
    }
}
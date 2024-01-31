/**
 * Created by ra8275 on 24.01.24.
 */

public virtual class RESTUtil {
    public static void sendJSONResponse(RestResponse response, Boolean error, Integer statusCode, String message) {
        JSONGenerator gen = JSON.createGenerator(true);
        String status = 'Error';
        gen.writeStartObject();
        if (!error) {
            status = 'OK';
        }
        gen.writeStringField('status', status);
        gen.writeStringField('message', message);
        gen.writeEndObject();

        String jsonS = gen.getAsString();
        if (response == null) {
            response = new RestResponse();
            RestContext.response = response;
        }
        response.responseBody = Blob.valueOf(jsonS);
        response.statusCode = statusCode;
        System.debug('###JSON response:' + jsonS);
        return ;
    }
}
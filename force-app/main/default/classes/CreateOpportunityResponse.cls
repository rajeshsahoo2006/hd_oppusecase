@JsonAccess(serializable='always' deserializable='always')
global class CreateOpportunityResponse {

    @InvocableVariable(label='Success' description='Whether the opportunity was created successfully')
    @AuraEnabled
    global Boolean success;

    @InvocableVariable(label='Opportunity ID' description='ID of the created opportunity')
    @AuraEnabled
    global String opportunityId;

    @InvocableVariable(label='Message' description='Success or error message')
    @AuraEnabled
    global String message;

    global CreateOpportunityResponse() {
        this.success = false;
        this.message = '';
    }

    global CreateOpportunityResponse(Boolean success, String opportunityId, String message) {
        this.success = success;
        this.opportunityId = opportunityId;
        this.message = message;
    }
}

@JsonAccess(serializable='always' deserializable='always')
global class OpportunityResponse {
    @InvocableVariable(label='Opportunity Data' description='Extracted opportunity information')
    @AuraEnabled
    global OpportunityData opportunityData;

    global OpportunityResponse() {
        // No-arg constructor required
    }

    global OpportunityResponse(OpportunityData data) {
        this.opportunityData = data;
    }
}

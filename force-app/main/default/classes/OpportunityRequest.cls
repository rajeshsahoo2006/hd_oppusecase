@JsonAccess(serializable='always' deserializable='always')
global class OpportunityRequest {

    @InvocableVariable(
        label='Account Name'
        description='Name of the account or company'
        required=true
    )
    global String accountName;

    @InvocableVariable(
        label='Account ID'
        description='Salesforce ID of the account'
        required=false
    )
    global String accountId;

    @InvocableVariable(
        label='Account Phone'
        description='Phone number of the account'
        required=false
    )
    global String accountPhone;

    @InvocableVariable(
        label='Account Address'
        description='Address of the account'
        required=false
    )
    global String accountAddress;

    @InvocableVariable(
        label='Opportunity Amount'
        description='Dollar amount for the opportunity'
        required=true
    )
    global Decimal amount;

    @InvocableVariable(
        label='Stage'
        description='Opportunity stage (defaults to Qualification)'
        required=false
    )
    global String stage;

    @InvocableVariable(
        label='Close Date'
        description='Expected close date'
        required=false
    )
    global String closeDate;

    @InvocableVariable(
        label='Opportunity Name'
        description='Name for the opportunity'
        required=false
    )
    global String opportunityName;

    global OpportunityRequest() {
        // No-arg constructor required for deserialization
        this.stage = 'Qualification'; // Default value
    }

    global OpportunityRequest(String accountName, String accountId, String accountPhone, String accountAddress,
                              Decimal amount, String stage, String closeDate, String opportunityName) {
        this.accountName = accountName;
        this.accountId = accountId;
        this.accountPhone = accountPhone;
        this.accountAddress = accountAddress;
        this.amount = amount;
        this.stage = stage != null ? stage : 'Qualification';
        this.closeDate = closeDate;
        this.opportunityName = opportunityName;
    }
}

@JsonAccess(serializable='always' deserializable='always')
global class OpportunityData {
    @AuraEnabled
    global String accountName;

    @AuraEnabled
    global String accountId;

    @AuraEnabled
    global String accountPhone;

    @AuraEnabled
    global String accountAddress;

    @AuraEnabled
    global Decimal amount;

    @AuraEnabled
    global String stage;

    @AuraEnabled
    global String closeDate;

    @AuraEnabled
    global String opportunityName;

    global OpportunityData() {
        // No-arg constructor required for deserialization
    }

    global OpportunityData(String accountName, String accountId, String accountPhone, String accountAddress,
                          Decimal amount, String stage, String closeDate, String opportunityName) {
        this.accountName = accountName;
        this.accountId = accountId;
        this.accountPhone = accountPhone;
        this.accountAddress = accountAddress;
        this.amount = amount;
        this.stage = stage;
        this.closeDate = closeDate;
        this.opportunityName = opportunityName;
    }
}

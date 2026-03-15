@JsonAccess(serializable='always' deserializable='always')
global with sharing class CreateOpportunity {

    /**
     * AuraEnabled method for LWC to call directly
     */
    @AuraEnabled
    public static CreateOpportunityResponse createOpportunityFromLWC(String accountName, String accountId, Decimal amount, String stage, String closeDate) {
        CreateOpportunityResponse response = new CreateOpportunityResponse();

        try {
            // Find or use the Account
            Account acct;
            if (String.isNotBlank(accountId)) {
                acct = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];
            } else if (String.isNotBlank(accountName)) {
                List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name = :accountName LIMIT 1];
                if (accounts.isEmpty()) {
                    response.success = false;
                    response.message = 'Account "' + accountName + '" not found. Please create the account first.';
                    return response;
                }
                acct = accounts[0];
            } else {
                response.success = false;
                response.message = 'Account Name or Account ID is required.';
                return response;
            }

            // Parse close date
            Date closeDateParsed;
            try {
                closeDateParsed = Date.parse(closeDate);
            } catch (Exception e) {
                closeDateParsed = Date.today().addDays(30); // Default to 30 days from now
            }

            // Create the Opportunity
            String oppName = acct.Name + ' - ' + (stage != null ? stage : 'Prospecting');
            Opportunity opp = new Opportunity(
                Name = oppName,
                AccountId = acct.Id,
                Amount = amount,
                StageName = stage != null ? stage : 'Prospecting',
                CloseDate = closeDateParsed
            );

            insert opp;

            response.success = true;
            response.opportunityId = opp.Id;
            response.message = 'Opportunity created successfully! ID: ' + opp.Id;

        } catch (Exception e) {
            response.success = false;
            response.message = 'Error creating opportunity: ' + e.getMessage();
        }

        return response;
    }

    @InvocableMethod(label='Create Opportunity' description='Creates an Opportunity record from extracted data')
    global static List<CreateOpportunityResponse> createOpportunity(List<CreateOpportunityRequest> requests) {
        List<CreateOpportunityResponse> responses = new List<CreateOpportunityResponse>();

        for (CreateOpportunityRequest req : requests) {
            CreateOpportunityResponse response = new CreateOpportunityResponse();

            try {
                // Find the Account by name
                List<Account> accounts = [
                    SELECT Id, Name
                    FROM Account
                    WHERE Name = :req.accountName
                    LIMIT 1
                ];

                if (accounts.isEmpty()) {
                    response.success = false;
                    response.message = 'Account "' + req.accountName + '" not found. Please create the account first.';
                    responses.add(response);
                    continue;
                }

                Account acct = accounts[0];

                // Parse close date
                Date closeDate;
                try {
                    closeDate = Date.parse(req.closeDate);
                } catch (Exception e) {
                    closeDate = Date.today().addDays(30); // Default to 30 days from now
                }

                // Create the Opportunity
                Opportunity opp = new Opportunity(
                    Name = req.accountName + ' - ' + req.stage,
                    AccountId = acct.Id,
                    Amount = req.amount,
                    StageName = req.stage != null ? req.stage : 'Prospecting',
                    CloseDate = closeDate
                );

                insert opp;

                response.success = true;
                response.opportunityId = opp.Id;
                response.message = '✅ Opportunity created successfully! ID: ' + opp.Id;

                responses.add(response);

            } catch (Exception e) {
                response.success = false;
                response.message = '❌ Error creating opportunity: ' + e.getMessage();
                responses.add(response);
            }
        }

        return responses;
    }
}

@JsonAccess(serializable='always' deserializable='always')
global with sharing class ExtractOpportunityData {

    @InvocableMethod(label='Extract Opportunity Data' description='Extracts opportunity information and returns it for display')
    global static List<OpportunityResponse> extractData(List<OpportunityRequest> requests) {
        List<OpportunityResponse> responses = new List<OpportunityResponse>();

        // Collect all account IDs first
        Set<Id> accountIds = new Set<Id>();
        for (OpportunityRequest req : requests) {
            if (String.isNotBlank(req.accountId)) {
                try {
                    accountIds.add((Id)req.accountId);
                } catch (Exception e) {
                    System.debug('Invalid account ID: ' + req.accountId);
                }
            }
        }

        // Query all accounts at once
        Map<Id, Account> accountMap = new Map<Id, Account>();
        if (!accountIds.isEmpty()) {
            for (Account acc : [SELECT Id, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode
                               FROM Account
                               WHERE Id IN :accountIds]) {
                accountMap.put(acc.Id, acc);
            }
        }

        // Process each request
        for (OpportunityRequest req : requests) {
            String accountPhone = req.accountPhone;
            String accountAddress = req.accountAddress;

            // Get account details from map if available
            if (String.isNotBlank(req.accountId) && accountMap.containsKey((Id)req.accountId)) {
                Account acc = accountMap.get((Id)req.accountId);
                accountPhone = acc.Phone;

                // Build full address
                List<String> addressParts = new List<String>();
                if (String.isNotBlank(acc.BillingStreet)) addressParts.add(acc.BillingStreet);
                if (String.isNotBlank(acc.BillingCity)) addressParts.add(acc.BillingCity);
                if (String.isNotBlank(acc.BillingState)) addressParts.add(acc.BillingState);
                if (String.isNotBlank(acc.BillingPostalCode)) addressParts.add(acc.BillingPostalCode);
                accountAddress = String.join(addressParts, ', ');
            }

            // Generate opportunity name if not provided
            String opportunityName = req.opportunityName;
            if (String.isBlank(opportunityName)) {
                opportunityName = req.accountName + ' - ' + req.stage;
            }

            // Create opportunity data from the request
            OpportunityData oppData = new OpportunityData(
                req.accountName,
                req.accountId,
                accountPhone,
                accountAddress,
                req.amount,
                req.stage,
                req.closeDate,
                opportunityName
            );

            OpportunityResponse response = new OpportunityResponse(oppData);
            responses.add(response);
        }

        return responses;
    }
}

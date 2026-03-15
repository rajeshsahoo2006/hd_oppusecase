public with sharing class CreateEvent {

    @AuraEnabled
    public static CreateEventResponse createFollowUpEvent(String opportunityId, String opportunityName, String accountName) {
        try {
            // Calculate start date time (tomorrow at 10 AM)
            DateTime tomorrow = DateTime.now().addDays(1);
            DateTime startDateTime = DateTime.newInstance(
                tomorrow.year(),
                tomorrow.month(),
                tomorrow.day(),
                10, 0, 0
            );

            // Create the Event record
            Event newEvent = new Event(
                Subject = 'Follow up: ' + opportunityName,
                WhatId = opportunityId,
                StartDateTime = startDateTime,
                EndDateTime = startDateTime.addHours(1),
                Description = 'Follow-up meeting for opportunity ' + opportunityName + ' with ' + accountName
            );

            insert newEvent;

            return new CreateEventResponse(true, newEvent.Id, 'Event created successfully for tomorrow at 10 AM');

        } catch (Exception e) {
            return new CreateEventResponse(false, null, 'Error creating event: ' + e.getMessage());
        }
    }

    public class CreateEventResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String eventId;
        @AuraEnabled public String message;

        public CreateEventResponse(Boolean success, String eventId, String message) {
            this.success = success;
            this.eventId = eventId;
            this.message = message;
        }
    }
}

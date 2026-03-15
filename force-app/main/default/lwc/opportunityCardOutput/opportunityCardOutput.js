import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createOpportunityFromLWC from '@salesforce/apex/CreateOpportunity.createOpportunityFromLWC';
import createFollowUpEvent from '@salesforce/apex/CreateEvent.createFollowUpEvent';

export default class OpportunityCardOutput extends NavigationMixin(LightningElement) {
    @api value;

    // Editable fields
    editableOpportunityName;
    editableAmount;
    editableStage;
    editableCloseDate;

    // UI state
    isDiscarded = false;
    isApproving = false;
    isCreated = false;
    createdOpportunityId = null;
    createdOpportunityName = null;
    showEventPrompt = false;
    isCreatingEvent = false;

    // Stage picklist options
    stageOptions = [
        { label: 'Prospecting', value: 'Prospecting' },
        { label: 'Qualification', value: 'Qualification' },
        { label: 'Needs Analysis', value: 'Needs Analysis' },
        { label: 'Value Proposition', value: 'Value Proposition' },
        { label: 'Id. Decision Makers', value: 'Id. Decision Makers' },
        { label: 'Perception Analysis', value: 'Perception Analysis' },
        { label: 'Proposal/Price Quote', value: 'Proposal/Price Quote' },
        { label: 'Negotiation/Review', value: 'Negotiation/Review' },
        { label: 'Closed Won', value: 'Closed Won' },
        { label: 'Closed Lost', value: 'Closed Lost' }
    ];

    connectedCallback() {
        console.log('OpportunityCardOutput: Component connected');
        // Initialize editable fields with data
        this.initializeEditableFields();
    }

    initializeEditableFields() {
        const data = this.opportunityData;
        console.log('OpportunityCardOutput: Initializing fields with data:', JSON.stringify(data));
        if (data) {
            this.editableOpportunityName = data.opportunityName || '';
            this.editableAmount = data.amount || 0;
            this.editableStage = data.stage || 'Qualification';
            this.editableCloseDate = data.closeDate || '';
            console.log('OpportunityCardOutput: Fields initialized:', {
                opportunityName: this.editableOpportunityName,
                amount: this.editableAmount,
                stage: this.editableStage,
                closeDate: this.editableCloseDate
            });
        } else {
            console.warn('OpportunityCardOutput: No opportunity data available');
        }
    }

    get opportunityData() {
        if (!this.value) {
            return null;
        }

        // Handle list structure - take first item
        if (Array.isArray(this.value) && this.value.length > 0) {
            return this.value[0];
        }

        // Handle wrapped response
        if (this.value.opportunityData) {
            return this.value.opportunityData;
        }

        // If value is the data itself
        if (this.value.accountName) {
            return this.value;
        }

        return null;
    }

    get hasData() {
        return this.opportunityData !== null;
    }

    get accountName() {
        return this.opportunityData?.accountName || 'N/A';
    }

    get accountId() {
        return this.opportunityData?.accountId || null;
    }

    get hasAccountId() {
        return this.accountId !== null && this.accountId !== '';
    }

    get accountPhone() {
        return this.opportunityData?.accountPhone || null;
    }

    get accountAddress() {
        return this.opportunityData?.accountAddress || null;
    }

    get approveButtonLabel() {
        return this.isApproving ? 'Approving...' : 'Approve';
    }

    // Change handlers
    handleOpportunityNameChange(event) {
        this.editableOpportunityName = event.target.value;
        console.log('OpportunityCardOutput: Opportunity name changed to:', this.editableOpportunityName);
    }

    handleAmountChange(event) {
        this.editableAmount = event.target.value;
        console.log('OpportunityCardOutput: Amount changed to:', this.editableAmount);
    }

    handleStageChange(event) {
        this.editableStage = event.detail.value;
        console.log('OpportunityCardOutput: Stage changed to:', this.editableStage);
    }

    handleCloseDateChange(event) {
        this.editableCloseDate = event.target.value;
        console.log('OpportunityCardOutput: Close date changed to:', this.editableCloseDate);
    }

    handleAccountClick(event) {
        event.preventDefault();
        if (this.hasAccountId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.accountId,
                    objectApiName: 'Account',
                    actionName: 'view'
                }
            });
        }
    }

    handleApprove() {
        console.log('🟢 OpportunityCardOutput: APPROVE button clicked!');

        // Disable buttons immediately
        this.isApproving = true;

        console.log('OpportunityCardOutput: Creating opportunity with data:', {
            opportunityName: this.editableOpportunityName,
            accountName: this.accountName,
            accountId: this.accountId,
            amount: this.editableAmount,
            stage: this.editableStage,
            closeDate: this.editableCloseDate
        });

        // Call Apex directly to create the opportunity
        createOpportunityFromLWC({
            accountName: this.accountName,
            accountId: this.accountId,
            amount: parseFloat(this.editableAmount) || 0,
            stage: this.editableStage || 'Qualification',
            closeDate: this.editableCloseDate || ''
        })
        .then(result => {
            console.log('OpportunityCardOutput: Raw Apex result:', result);
            console.log('OpportunityCardOutput: Result type:', typeof result);
            console.log('OpportunityCardOutput: Result keys:', Object.keys(result || {}));
            console.log('OpportunityCardOutput: result.success =', result?.success);
            console.log('OpportunityCardOutput: result.message =', result?.message);
            console.log('OpportunityCardOutput: result.opportunityId =', result?.opportunityId);

            // Check if result exists and has success property
            if (result && result.success === true) {
                console.log('OpportunityCardOutput: ✅ Success! Opportunity created:', result.opportunityId);

                // Store created opportunity details
                this.isCreated = true;
                this.createdOpportunityId = result.opportunityId;
                this.createdOpportunityName = this.editableOpportunityName;
                this.showEventPrompt = true; // Show event prompt by default

                // Show success toast
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success!',
                    message: result.message || `Opportunity created: ${result.opportunityId}`,
                    variant: 'success'
                }));

                // Dispatch success event
                this.dispatchEvent(new CustomEvent('opportunitycreated', {
                    bubbles: true,
                    composed: true,
                    detail: {
                        success: true,
                        opportunityId: result.opportunityId,
                        message: result.message
                    }
                }));
            } else {
                console.error('OpportunityCardOutput: ❌ Opportunity creation failed');
                console.error('OpportunityCardOutput: Failure message:', result?.message);

                // Re-enable buttons on failure
                this.isApproving = false;

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: result?.message || 'Failed to create opportunity',
                    variant: 'error'
                }));
            }
        })
        .catch(error => {
            console.error('OpportunityCardOutput: ❌ Error calling createOpportunity:', error);
            console.error('OpportunityCardOutput: Error body:', error.body);
            console.error('OpportunityCardOutput: Error message:', error.message);
            console.error('OpportunityCardOutput: Full error:', JSON.stringify(error));

            // Re-enable buttons on error
            this.isApproving = false;

            let errorMessage = 'An error occurred while creating the opportunity';
            if (error.body && error.body.message) {
                errorMessage = error.body.message;
            } else if (error.message) {
                errorMessage = error.message;
            }

            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: errorMessage,
                variant: 'error'
            }));

            this.dispatchEvent(new CustomEvent('opportunityerror', {
                bubbles: true,
                composed: true,
                detail: {
                    success: false,
                    error: errorMessage
                }
            }));
        });
    }

    handleViewOpportunity() {
        if (this.createdOpportunityId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.createdOpportunityId,
                    objectApiName: 'Opportunity',
                    actionName: 'view'
                }
            });
        }
    }

    handleDiscard() {
        console.log('🔴 OpportunityCardOutput: DISCARD button clicked!');
        console.log('OpportunityCardOutput: Discarding opportunity for account:', this.accountName);

        // Show discarded state instead of hiding
        this.isDiscarded = true;

        // Dispatch discard event
        this.dispatchEvent(new CustomEvent('opportunitydiscarded', {
            bubbles: true,
            composed: true,
            detail: {
                accountName: this.accountName,
                accountId: this.accountId
            }
        }));
    }

    handleReconsider() {
        console.log('🔄 OpportunityCardOutput: RECONSIDER button clicked!');
        // Reset discarded state to show the card again
        this.isDiscarded = false;
    }

    handleCreateEvent() {
        console.log('📅 OpportunityCardOutput: Creating event for opportunity:', this.createdOpportunityId);
        this.isCreatingEvent = true;

        // Call Apex method to create Event
        createFollowUpEvent({
            opportunityId: this.createdOpportunityId,
            opportunityName: this.createdOpportunityName,
            accountName: this.accountName
        })
            .then(result => {
                console.log('✅ Event creation result:', result);
                this.isCreatingEvent = false;

                if (result.success) {
                    this.showEventPrompt = false;

                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Success!',
                        message: result.message,
                        variant: 'success'
                    }));

                    // Navigate to the event
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: result.eventId,
                            objectApiName: 'Event',
                            actionName: 'view'
                        }
                    });
                } else {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Error',
                        message: result.message,
                        variant: 'error'
                    }));
                }
            })
            .catch(error => {
                console.error('❌ Error creating event:', error);
                this.isCreatingEvent = false;

                let errorMessage = 'Failed to create event';
                if (error.body && error.body.message) {
                    errorMessage = error.body.message;
                }

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: errorMessage,
                    variant: 'error'
                }));
            });
    }

    handleSkipEvent() {
        console.log('⏭️ OpportunityCardOutput: Skipping event creation');
        this.showEventPrompt = false;
    }
}

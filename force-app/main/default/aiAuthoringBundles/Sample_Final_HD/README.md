# Sample_Final_HD - Agentforce Opportunity Extraction Agent

An Agentforce Employee Agent that extracts opportunity details from meeting summaries and displays them in an interactive, editable Lightning Web Component card with direct opportunity creation capabilities.

## Overview

This agent demonstrates advanced Agentforce capabilities including:
- **Meeting summary parsing** with natural language understanding
- **Custom Lightning Types** for rich UI rendering
- **Editable opportunity cards** with inline field editing
- **Direct Apex invocation** from LWC without agent round-trip
- **Event creation** for follow-up meetings
- **Account search integration** with Salesforce data

## Architecture

```
Meeting Summary (User Input)
    ↓
Agent extracts: Account Name, Amount, Stage, Close Date
    ↓
SearchAccounts (Flow) → Finds matching accounts in Salesforce
    ↓
Extract_Opportunity_Data (Apex) → Enriches with account details (phone, address)
    ↓
Lightning Type: c__opportunityData
    ↓
LWC Renderer: opportunityCardOutput (Editable Card)
    ↓
User clicks "Approve" → Direct Apex call (no agent)
    ↓
CreateOpportunity.createOpportunityFromLWC → Creates record
    ↓
Success Card + Event Creation Option → CreateEvent Apex
```

## Key Components

### 1. Agent Script (`Sample_Final_HD.agent`)

**Type:** `AgentforceEmployeeAgent`

**Variables:**
- `account_name` - Extracted account/company name
- `account_id` - Salesforce Account ID from search
- `opportunity_amount` - Deal amount
- `stage` - Opportunity stage (default: "Qualification")
- `close_date` - Expected close date

**Actions:**

| Action | Type | Purpose |
|--------|------|---------|
| `extract_data` | `@utils.setVariables` | Extract opportunity details from conversation |
| `search_accounts` | `@actions.SearchAccounts` | Search Salesforce for matching accounts |
| `capture_account_id` | `@utils.setVariables` | Store Account ID from search results |
| `display_card` | `@actions.Extract_Opportunity_Data` | Display interactive opportunity card |
| `create_opportunity` | `@actions.CreateOpportunity` | Create opportunity (when user confirms via agent) |

### 2. Lightning Type (`c__opportunityData`)

**Purpose:** Custom data type that bridges Apex and LWC rendering

**Location:** `force-app/main/default/lightningTypes/opportunityData/`

**Structure:**
```json
{
  "title": "Opportunity Data",
  "description": "Extracted opportunity information for display",
  "lightning:type": "@apexClassType/c__OpportunityData"
}
```

**Renderer Configuration:**
```json
{
  "renderer": {
    "componentOverrides": {
      "$": {
        "definition": "c/opportunityCardOutput"
      }
    }
  }
}
```

**How Lightning Types Work in Agentforce:**

1. **Apex Class as Data Contract** (`OpportunityData.cls`)
   - Uses `@AuraEnabled` for LWC access
   - Defines structure: accountName, accountId, amount, stage, closeDate, etc.

2. **Lightning Type Registration** (`schema.json`)
   - Links the Apex class to a Lightning Type name
   - Tells Agentforce: "When you see c__opportunityData, use OpportunityData.cls"

3. **Custom Renderer** (`renderer.json`)
   - Maps Lightning Type → Custom LWC component
   - Instead of default table view, render `c/opportunityCardOutput`

4. **Apex Action Output** (`Extract_Opportunity_Data`)
   ```yaml
   outputs:
     opportunityData: object
       complex_data_type_name: "c__opportunityData"
       is_displayable: True
       filter_from_agent: False
   ```

5. **Automatic Rendering**
   - Agent calls `Extract_Opportunity_Data`
   - Returns `OpportunityData` object
   - Agentforce sees `c__opportunityData` type
   - Looks up renderer.json → finds `c/opportunityCardOutput`
   - Renders custom LWC with the data

### 3. LWC Component (`opportunityCardOutput`)

**Features:**
- ✅ Editable fields (Opportunity Name, Amount, Stage, Close Date)
- ✅ Account information display (Name, Phone, Address)
- ✅ Account name hyperlink (navigates to Account record)
- ✅ Approve button → Creates opportunity via direct Apex call
- ✅ Discard button → Shows discard message with "Reconsider" option
- ✅ Success card → Shows created opportunity details
- ✅ Event creation prompt → "Create Event" or "Skip"
- ✅ Responsive design with SLDS styling

**Direct Apex Pattern (No Agent Mediation):**
```javascript
import createOpportunityFromLWC from '@salesforce/apex/CreateOpportunity.createOpportunityFromLWC';

handleApprove() {
    createOpportunityFromLWC({
        accountName: this.accountName,
        accountId: this.accountId,
        amount: parseFloat(this.editableAmount),
        stage: this.editableStage,
        closeDate: this.editableCloseDate
    })
    .then(result => {
        // Show success card
        this.isCreated = true;
        this.showEventPrompt = true; // Ask about event creation
    });
}
```

### 4. Apex Classes

| Class | Purpose |
|-------|---------|
| `OpportunityData` | Data structure for Lightning Type |
| `ExtractOpportunityData` | Enriches opportunity data with account details (phone, address) |
| `CreateOpportunity` | Invocable method for opportunity creation (agent use) |
| `CreateOpportunity.createOpportunityFromLWC` | AuraEnabled method for LWC direct calls |
| `CreateEvent` | Creates follow-up Event records |
| `OpportunityRequest` | Input wrapper for ExtractOpportunityData |
| `OpportunityResponse` | Output wrapper with opportunityData |
| `CreateOpportunityResponse` | Response with success/opportunityId/message |

### 5. Flow

**Search_Accounts_by_Name.flow**
- Input: `accountName` (String)
- Output: `searchResults` (List<Account>)
- Filter: Account Name contains input
- Used by: SearchAccounts action

## Usage Examples

### Example 1: Basic Meeting Summary

**User Input:**
```
Met with Adan Household - 101080 yesterday. They're interested in our enterprise solution.
Deal amount is $75,000 and they want to close by April 30, 2026.
Currently in the Negotiation stage.
```

**Agent Workflow:**
1. **Extract** → `account_name="Adan Household"`, `opportunity_amount=75000`, `stage="Negotiation"`, `close_date="2026-04-30"`
2. **Search** → Finds Account: "Adan Household – 101080" (ID: 001xx000003D...)
3. **Enrich** → Queries Account.Phone, Account.BillingAddress
4. **Display** → Renders editable opportunity card with:
   - Opportunity Name: "Adan Household – 101080 - Negotiation"
   - Account: Adan Household – 101080 (clickable)
   - Phone: (555) 123-4567
   - Address: 123 Main St, New York, NY 10001
   - Amount: $75,000
   - Stage: Negotiation (editable dropdown)
   - Close Date: 2026-04-30 (editable date picker)
5. **User Actions:**
   - **Edit fields** → Change stage to "Proposal/Price Quote"
   - **Click Approve** → Opportunity created instantly
   - **Success card appears** → Shows opportunity ID
   - **Event prompt** → "Would you like to create a follow-up event?"
   - **Click "Create Event"** → Event created for tomorrow at 10 AM

### Example 2: Simple Prompt

**User Input:**
```
Create opportunity for Miller Construction, $300,000, Qualification stage, close March 13, 2027
```

**Agent Workflow:**
1. Extracts: Miller Construction, $300,000, Qualification, 2027-03-13
2. Searches accounts → No match found
3. Displays card with extracted data (no phone/address)
4. User can:
   - Edit any field
   - Click "Approve" to create
   - Or "Discard" if account doesn't exist

### Example 3: Incomplete Information

**User Input:**
```
Discussed partnership with Global Tech, approximately $500k budget
```

**Agent Workflow:**
1. Extracts: Global Tech, $500,000
2. Uses defaults: stage="Qualification", close_date="" (empty)
3. Searches accounts → Displays matches
4. Shows editable card
5. User must fill in Close Date before approving

### Example 4: Discard and Reconsider

**User Input:**
```
I had a meeting with ABC Corp about a $200k deal
```

**Agent Workflow:**
1. Shows opportunity card
2. User clicks **"Discard"**
3. Card changes to:
   - Red header: "OPPORTUNITY DISCARDED"
   - Message: "You discarded the opportunity for ABC Corp"
   - Button: "Reconsider"
4. User clicks **"Reconsider"**
5. Original editable card returns

## Testing Instructions

### Test Data Setup

1. **Create test account:**
   ```apex
   Account testAccount = new Account(
       Name = 'Adan Household – 101080',
       Phone = '(555) 123-4567',
       BillingStreet = '123 Main Street',
       BillingCity = 'New York',
       BillingState = 'NY',
       BillingPostalCode = '10001'
   );
   insert testAccount;
   ```

2. **Or use existing account:** Update test.md with your account name

### Test Scenarios

#### Scenario 1: Happy Path
```
Paste in agent:
Met with Adan Household – 101080 yesterday. They're interested in our enterprise solution.
Deal amount is $75,000 and they want to close by April 30, 2026. Currently in the Negotiation stage.

Expected:
✓ Card displays with all fields populated
✓ Account name is clickable hyperlink
✓ Phone and address shown
✓ All fields are editable
✓ Click Approve → Success card appears
✓ Event prompt shows
✓ Click "Create Event" → Event created and opened
```

#### Scenario 2: Edit Before Approve
```
Paste in agent:
Create opp for Adan Household – 101080, $50k, close next month

Actions:
1. Card appears with $50,000
2. Change amount to $55,000
3. Change stage to "Proposal/Price Quote"
4. Set close date to specific date
5. Click Approve

Expected:
✓ Opportunity created with edited values (not original)
```

#### Scenario 3: Discard Flow
```
Actions:
1. Display any opportunity card
2. Click "Discard"
3. Verify discard message appears
4. Click "Reconsider"
5. Verify original card returns

Expected:
✓ Discard message shows correctly
✓ Reconsider restores the card
```

#### Scenario 4: Event Creation
```
Actions:
1. Create opportunity via Approve
2. Success card shows
3. Event prompt: "Would you like to create a follow-up event?"
4. Click "Create Event"

Expected:
✓ Event created with:
  - Subject: "Follow up: [Opportunity Name]"
  - Related To: Opportunity ID
  - Start: Tomorrow at 10:00 AM
  - Duration: 1 hour
✓ Navigates to Event record
```

## Deployment Guide

### Prerequisites
- Salesforce org with Agentforce enabled
- Agent Builder access
- API version 62.0+

### Deploy Components

```bash
# Deploy all Sample_Final_HD components
sf project deploy start \
  --source-dir force-app/main/default/aiAuthoringBundles/Sample_Final_HD \
  --source-dir force-app/main/default/lwc/opportunityCardOutput \
  --source-dir force-app/main/default/lightningTypes/opportunityData \
  --source-dir force-app/main/default/classes/OpportunityData.cls \
  --source-dir force-app/main/default/classes/ExtractOpportunityData.cls \
  --source-dir force-app/main/default/classes/CreateOpportunity.cls \
  --source-dir force-app/main/default/classes/CreateEvent.cls \
  --source-dir force-app/main/default/classes/CreateOpportunityResponse.cls \
  --source-dir force-app/main/default/flows/Search_Accounts_by_Name.flow-meta.xml \
  --source-dir force-app/main/default/genAiFunctions/Extract_Opportunity_Data
```

### Activate Agent

1. Go to **Setup → Agent Builder**
2. Find **Sample_Final_HD**
3. Click **Activate**
4. Test in **Live Test Mode**

## Troubleshooting

### Card Not Displaying
- ✓ Check Lightning Type deployed: `c__opportunityData`
- ✓ Verify renderer.json points to `c/opportunityCardOutput`
- ✓ Confirm `filter_from_agent: False` in agent outputs
- ✓ Check browser console for errors

### Approve Button Not Working
- ✓ Verify `CreateOpportunity.createOpportunityFromLWC` is deployed
- ✓ Check `@AuraEnabled` on method
- ✓ Ensure `CreateOpportunityResponse` has `@AuraEnabled` on properties
- ✓ Check browser console for Apex errors

### Account Not Found
- ✓ Verify account exists in org
- ✓ Check account name spelling matches exactly
- ✓ Confirm `Search_Accounts_by_Name` flow is Active

### Event Creation Fails
- ✓ Verify `CreateEvent.cls` deployed
- ✓ Check user has create permission on Event object
- ✓ Confirm opportunityId is valid

## Technical Notes

### Why Lightning Types?

**Traditional Approach:**
```
Agent → Returns text → User reads → Manually creates record
```

**Lightning Type Approach:**
```
Agent → Returns typed data → Renders interactive UI → User edits → Direct creation
```

**Benefits:**
- ✅ Rich, interactive UI instead of plain text
- ✅ Type safety between Apex and LWC
- ✅ Reusable across multiple agents
- ✅ No need for custom aura:events or postMessage
- ✅ SLDS-compliant, responsive design

### Why Direct Apex from LWC?

**Agent-mediated approach:**
```javascript
// OLD: LWC → Event → Agent → Action → Apex
this.dispatchEvent(new CustomEvent('createopportunity', {detail: data}));
// Requires agent to listen and process
```

**Direct Apex approach:**
```javascript
// NEW: LWC → Apex (bypasses agent)
import createOpportunityFromLWC from '@salesforce/apex/CreateOpportunity.createOpportunityFromLWC';
createOpportunityFromLWC({...}).then(result => {...});
// Instant, no round-trip
```

**Why it's better:**
- ⚡ Faster - no agent conversation latency
- 🎯 Deterministic - no LLM interpretation needed
- 🔒 Reliable - direct API call vs event-based communication
- 🛠️ Testable - standard LWC Jest patterns apply

## Advanced Patterns

### Pattern 1: Multi-step Wizard
The LWC acts as a self-contained wizard:
1. Form view (edit fields)
2. Success view (show results)
3. Event prompt (optional next step)

All without agent involvement after initial render.

### Pattern 2: State Management
```javascript
// UI states tracked in LWC
isApproving = false;    // Button loading state
isCreated = false;      // Show success card
isDiscarded = false;    // Show discard message
showEventPrompt = true; // Show event option
```

### Pattern 3: Bulkified Apex
```apex
// ExtractOpportunityData handles multiple requests
Map<Id, Account> accountMap = new Map<Id, Account>();
for (Account acc : [SELECT Id, Phone, ... FROM Account WHERE Id IN :accountIds]) {
    accountMap.put(acc.Id, acc);
}
// Single SOQL query instead of loop
```

## References

- [Lightning Types Documentation](https://developer.salesforce.com/docs/ai/agentforce/guide/lightning-types-example-full-editor-renderer.html)
- [Agentforce Agent Script DSL](https://developer.salesforce.com/docs/einstein/genai/guide/agent-script-dsl.html)
- [LWC Dev Guide](https://developer.salesforce.com/docs/platform/lwc/guide)
- [Employee Agent Setup](https://help.salesforce.com/s/articleView?id=sf.einstein_bots_setup.htm)

## License

This is a sample implementation for educational purposes.

## Author

Sample implementation demonstrating Agentforce capabilities with Lightning Types and direct Apex invocation patterns.

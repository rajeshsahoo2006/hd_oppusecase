# Agentforce Opportunity Use Case - Home Depot

Salesforce Agentforce implementation demonstrating advanced opportunity extraction from meeting summaries with interactive Lightning Web Components.

## 🎯 Overview

This repository contains a complete Agentforce Employee Agent implementation that:
- ✅ Extracts opportunity details from natural language meeting summaries
- ✅ Searches and enriches data with Salesforce account information
- ✅ Renders interactive, editable opportunity cards using Custom Lightning Types
- ✅ Creates opportunities directly from LWC without agent round-trip
- ✅ Supports event creation for follow-up meetings

## 🚀 Quick Start

### Test the Agent

**Paste this in your agent:**
```
Met with Adan Household - 101080 yesterday. They’re interested in our enterprise solution.
Deal amount is $75,000 and they want to close by April 30, 2026.
Currently in the Negotiation stage.
```

**Expected Result:**
- 📊 Interactive opportunity card displays with all fields populated
- ✏️ Edit any field (amount, stage, close date)
- ✅ Click "Approve" → Opportunity created instantly
- 📅 Option to create follow-up event

## 📦 What’s Included

### Core Components

| Component | Type | Description |
|-----------|------|-------------|
| `Sample_Final_HD.agent` | Agent Script | Agentforce DSL configuration with actions and reasoning |
| `opportunityCardOutput` | LWC | Interactive card with editable fields and action buttons |
| `c__opportunityData` | Lightning Type | Custom type for Apex → LWC data binding |
| `ExtractOpportunityData` | Apex | Extracts and enriches opportunity data |
| `CreateOpportunity` | Apex | Creates opportunities (agent + LWC invocation) |
| `CreateEvent` | Apex | Creates follow-up events |
| `Search_Accounts_by_Name` | Flow | Searches accounts by name pattern |

### Key Features

✨ **Custom Lightning Type Rendering**
- Transforms Apex data into rich interactive UI
- No manual HTML/text formatting needed
- Type-safe data binding between Apex and LWC

⚡ **Direct Apex Invocation from LWC**
- Buttons call Apex directly (no agent mediation)
- Instant response, no LLM latency
- Standard LWC → Apex pattern

🎨 **Responsive UI with State Management**
- Editable fields with validation
- Loading states (Approving...)
- Success/Discard views
- Event creation workflow

## 📖 Full Documentation

**Detailed implementation guide:** [Sample_Final_HD README](./force-app/main/default/aiAuthoringBundles/Sample_Final_HD/README.md)

Includes:
- 🏗️ Complete architecture diagram
- 🔧 Component breakdown
- 📚 Lightning Types deep dive
- 🧪 4 test scenarios with expected results
- 🚀 Deployment instructions
- 🐛 Troubleshooting guide

## 🛠️ Installation

### Prerequisites
- Salesforce org with Agentforce enabled
- Agent Builder access
- Salesforce CLI (sf) installed

### Deploy

```bash
# Clone repository
git clone https://github.com/rajeshsahoo2006/hd_oppusecase.git
cd hd_oppusecase

# Deploy to your org
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

### Activate

1. Go to **Setup → Agent Builder**
2. Find **Sample_Final_HD**
3. Click **Activate**
4. Test in **Live Test Mode**

## 💡 How It Works

### Lightning Type Flow

1. **Apex Returns Typed Data**
   ```apex
   OpportunityData oppData = new OpportunityData(
       accountName, accountId, phone, address,
       amount, stage, closeDate, opportunityName
   );
   ```

2. **Agent Marks Output as Lightning Type**
   ```yaml
   outputs:
     opportunityData: object
       complex_data_type_name: "c__opportunityData"
       is_displayable: True
   ```

3. **Agentforce Looks Up Renderer**
   - Finds `lightningTypes/opportunityData/renderer.json`
   - Maps to `c/opportunityCardOutput` LWC

4. **LWC Renders Interactive UI**
   - Receives data via `@api value`
   - Displays editable fields
   - Handles button clicks with direct Apex

5. **Direct Opportunity Creation**
   ```javascript
   import createOpportunityFromLWC from ‘@salesforce/apex/CreateOpportunity.createOpportunityFromLWC’;
   createOpportunityFromLWC({...}).then(result => {...});
   ```

## 🧪 Test Scenarios

### Scenario 1: Complete Information
```
Met with Adan Household - 101080 yesterday. They’re interested in our
enterprise solution. Deal amount is $75,000 and they want to close by
April 30, 2026. Currently in the Negotiation stage.
```
✅ Card displays with all fields → Edit if needed → Approve → Success

### Scenario 2: Partial Information
```
Create opportunity for Miller Construction, $300,000, Qualification stage
```
✅ Card displays → Set close date → Approve

### Scenario 3: Discard & Reconsider
Display card → Click Discard → See message → Click Reconsider → Card returns

### Scenario 4: Event Creation
Approve opportunity → Success card → "Create Event" → Event for tomorrow 10 AM

## 🎓 Key Concepts

### Why Lightning Types?

**Traditional Agent Output:**
```
Opportunity Details:
- Account: Miller Construction
- Amount: $300,000
- Stage: Qualification
```
❌ Static text, no interaction

**Lightning Type Output:**
```
[Interactive Card]
┌─────────────────────────┐
│ NEW OPPORTUNITY         │
├─────────────────────────┤
│ Name: [editable]        │
│ Amount: $300,000        │
│ Stage: [dropdown]       │
│ Close Date: [picker]    │
├─────────────────────────┤
│ [Approve] [Discard]     │
└─────────────────────────┘
```
✅ Interactive, editable, actionable

### Why Direct Apex from LWC?

**Agent-Mediated (Old Way):**
```
User clicks button → Event to Agent → Agent interprets → Calls Action → Response
⏱️ 2-5 seconds with LLM processing
```

**Direct Apex (New Way):**
```
User clicks button → Apex method → Response
⏱️ 100-300ms, no LLM needed
```

## 📊 Architecture Highlights

- **Agent Script DSL**: Declarative, maintainable configuration
- **Bulkified Apex**: Single SOQL for multiple accounts
- **Type Safety**: `@AuraEnabled` for LWC, `@InvocableVariable` for agents
- **Separation of Concerns**: Agent for orchestration, LWC for interaction
- **Progressive Enhancement**: Works without JavaScript (falls back to text)

## 🔧 Technology Stack

- **Agentforce Agent Script DSL** - Employee Agent configuration
- **Lightning Web Components** - Interactive UI
- **Apex** - Business logic and data manipulation
- **Flow** - Account search automation
- **Custom Lightning Types** - Data type definitions
- **SLDS** - Salesforce Lightning Design System

## 📁 Repository Structure

```
force-app/main/default/
├── aiAuthoringBundles/
│   └── Sample_Final_HD/
│       ├── Sample_Final_HD.agent          # Agent Script configuration
│       ├── Sample_Final_HD.bundle-meta.xml
│       └── README.md                      # Detailed documentation
├── lwc/
│   └── opportunityCardOutput/             # Interactive card component
├── lightningTypes/
│   └── opportunityData/                   # Custom Lightning Type
├── classes/
│   ├── OpportunityData.cls                # Data structure
│   ├── ExtractOpportunityData.cls         # Data extraction
│   ├── CreateOpportunity.cls              # Opportunity creation
│   └── CreateEvent.cls                    # Event creation
├── flows/
│   └── Search_Accounts_by_Name.flow       # Account search
└── genAiFunctions/
    └── Extract_Opportunity_Data/          # GenAI Function config
```

## 📚 Resources

- [Agentforce Documentation](https://developer.salesforce.com/docs/einstein/genai/overview)
- [Lightning Types Guide](https://developer.salesforce.com/docs/ai/agentforce/guide/lightning-types-example-full-editor-renderer.html)
- [Agent Script DSL Reference](https://developer.salesforce.com/docs/einstein/genai/guide/agent-script-dsl.html)
- [LWC Dev Guide](https://developer.salesforce.com/docs/platform/lwc/guide)

## 📝 License

Sample implementation for educational purposes.

---

⭐ **Star this repo** if you find it helpful!

🔗 **Detailed documentation:** [Sample_Final_HD README](./force-app/main/default/aiAuthoringBundles/Sample_Final_HD/README.md)

---
name: schema-endpoint-extractor
description: Extract specific API endpoints and their types from a regenerated OpenAPI schema, then manually reapply them. Use when you need to selectively update schema.ts with only certain endpoints from a schema generation command.
---

# Schema Endpoint Extractor

This skill helps extract specific endpoints and their type definitions from a freshly generated OpenAPI schema, then manually reapply them after reverting the schema file. This is useful when you want only certain endpoints from a schema update without taking all changes.

## Workflow

1. **Generate Fresh Schema**: Run the schema generation command (e.g., `pnpm schema-ml-scribe:staging`)
2. **Extract Endpoints**: Identify and save the endpoint paths, operations, and all related component schemas
3. **Revert Schema**: Restore the original schema file
4. **Reapply Types**: Manually add back only the extracted endpoints and types

## Usage

When invoked, follow these steps:

### Step 1: Generate Schema

Run the schema generation command in the project:

```bash
pnpm schema-ml-scribe:staging
# or whatever schema generation command is appropriate
```

### Step 2: Identify Endpoints to Extract

Ask the user which endpoint(s) they want to extract. Get the full path(s), e.g.:
- `/api/v2/ml-scribe/integrations/sealed-message-delivery/{session_id}/send`
- `/api/v2/ml-scribe/integrations/schedule`

### Step 3: Extract Endpoint Definitions

For each endpoint path, extract from `src/types/schema.ts`:

1. **Path definition** in the `paths` type (lines with the endpoint path)
2. **Operation definition** in the `operations` interface (referenced by the path)
3. **All component schemas** referenced by the operation (recursively follow all `components['schemas']['...']` references)

Use this helper script to extract:

```bash
./extract-endpoint.sh "/api/v2/ml-scribe/integrations/schedule" src/types/schema.ts
```

The script will output:
- Path definition
- Operation definition
- All component schema dependencies

### Step 4: Revert Schema File

```bash
git checkout src/types/schema.ts
# or
git restore src/types/schema.ts
```

### Step 5: Manually Reapply Extracted Types

Using the extracted definitions, manually add them back to the schema file:

1. **Add paths**: Insert path definitions in the `paths` type (maintain alphabetical order)
2. **Add operations**: Insert operation definitions in the `operations` interface (maintain alphabetical order)
3. **Add component schemas**: Insert component schemas in the `components.schemas` section (maintain alphabetical order)
4. **Handle duplicate paths**: If a path already exists, keep the existing one or merge carefully
5. **Fix type references**: Replace any missing type references with `string` or appropriate alternatives if they don't exist

### Step 6: Validate

```bash
npx tsc --noEmit src/types/schema.ts
```

## Notes

- **Dependencies matter**: Component schemas can reference other schemas. Extract all dependencies recursively.
- **Enums**: Don't forget to extract enum definitions if components reference them.
- **FHIR types**: Some schemas reference complex FHIR types that may already exist in the schema.
- **Alphabetical order**: Keep paths, operations, and schemas in alphabetical order for consistency.
- **Type conflicts**: If a referenced type doesn't exist after reversion, use `string` or create a minimal definition.

## Example

```typescript
// Extract these endpoints:
'/api/v2/ml-scribe/integrations/schedule'
'/api/v2/ml-scribe/integrations/sealed-message-delivery/{session_id}/send'

// This requires extracting:
// Paths:
//   - '/api/v2/ml-scribe/integrations/schedule'
//   - '/api/v2/ml-scribe/integrations/sealed-message-delivery/{session_id}/send'
//
// Operations:
//   - get_schedule_api_v2_ml_scribe_integrations_schedule_get
//   - send_sealed_message_api_v2_ml_scribe_integrations_sealed_message_delivery__session_id__send_post
//
// Component Schemas:
//   - GetScheduleResponse
//   - GetScheduleResponseScheduleItem
//   - ScheduleItemAppointment
//   - IntegrationAppointmentProviderDetails
//   - IntegrationPatient
//   - IntegrationPatientProviderDetails
//   - SendSealedMessageRequest
//   - SendSealedMessageRecipients
//   - SendSealedMessageResult
//   - SmdRecipients
//   - EmailRecipients
//   - Communication (FHIR)
//   - CommunicationPayload (FHIR)
//   - And any enums they reference (AppointmentStatus, GenderIdentity, BirthSex, etc.)
```

## Tips for the Agent

1. **Read the full schema first** to understand structure
2. **Search for exact paths** in the `paths` type
3. **Find operation names** from path definitions (e.g., `operations['..._get']`)
4. **Grep for operation definitions** in the `operations` interface
5. **Extract all components** referenced in request/response bodies
6. **Recursively follow** all `components['schemas']['...']` references
7. **Check for enums** by searching for `export enum TypeName`
8. **Use search carefully** - names might appear in comments or other contexts
9. **Preserve formatting** - match the existing style (2-space indents, single quotes)
10. **Test compilation** after manual changes

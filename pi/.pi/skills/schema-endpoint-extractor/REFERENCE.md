# Schema Endpoint Extractor - Reference Guide

## Manual Extraction Patterns

This guide shows the patterns used to manually extract and reapply endpoint definitions.

### Pattern 1: Find Path Definition

Search for the endpoint path in the `paths` type:

```bash
grep -n "  '/api/v2/ml-scribe/integrations/schedule':" src/types/schema.ts
```

Extract the full path block (usually 15-20 lines):

```typescript
'/api/v2/ml-scribe/integrations/schedule': {
  parameters: {
    query?: never;
    header?: never;
    path?: never;
    cookie?: never;
  };
  /**
   * Get Schedule
   * @description Description here...
   */
  get: operations['get_schedule_api_v2_ml_scribe_integrations_schedule_get'];
  put?: never;
  post?: never;
  delete?: never;
  options?: never;
  head?: never;
  patch?: never;
  trace?: never;
};
```

### Pattern 2: Find Operation Definition

From the path, extract the operation name (e.g., `get_schedule_api_v2_ml_scribe_integrations_schedule_get`).

Search for it in the operations interface:

```bash
grep -n "  get_schedule_api_v2_ml_scribe_integrations_schedule_get:" src/types/schema.ts
```

Extract the full operation block (30-50 lines):

```typescript
get_schedule_api_v2_ml_scribe_integrations_schedule_get: {
  parameters: {
    query: {
      start_date: string;
      end_date: string;
      onboarding_session_id?: string | null;
    };
    header?: never;
    path?: never;
    cookie?: never;
  };
  requestBody?: never;
  responses: {
    /** @description Successful Response */
    200: {
      headers: {
        [name: string]: unknown;
      };
      content: {
        'application/json': components['schemas']['GetScheduleResponse'];
      };
    };
    /** @description Validation Error */
    422: {
      headers: {
        [name: string]: unknown;
      };
      content: {
        'application/json': components['schemas']['HTTPValidationError'];
      };
    };
  };
};
```

### Pattern 3: Find Component Schemas

From the operation definition, extract all `components['schemas']['...']` references:

```bash
grep -o "components\['schemas'\]\['\([^']*\)'\]" | sed "s/.*\['\([^']*\)'\]/\1/" | sort -u
```

Example output:
- `GetScheduleResponse`
- `HTTPValidationError`

### Pattern 4: Extract Component Schema Definitions

For each schema, find its definition:

```bash
grep -n "    GetScheduleResponse:" src/types/schema.ts
```

Extract the full schema block:

```typescript
/**
 * GetScheduleResponse
 * @description Response for GET /schedule.
 */
GetScheduleResponse: {
  /** Schedule */
  schedule: components['schemas']['GetScheduleResponseScheduleItem'][];
};
```

### Pattern 5: Recursively Find Dependencies

For each schema, look for more `components['schemas']['...']` references and repeat Pattern 4.

Example:
- `GetScheduleResponse` references `GetScheduleResponseScheduleItem`
- `GetScheduleResponseScheduleItem` references `ScheduleItemAppointment` and `IntegrationPatient`
- Continue until no new references are found

### Pattern 6: Find Enum Definitions

Check if any schemas use enum types:

```bash
grep -n "export enum AppointmentStatus" src/types/schema.ts
```

Extract enum definitions:

```typescript
export enum AppointmentStatus {
  proposed = "proposed",
  pending = "pending",
  booked = "booked",
  arrived = "arrived",
  fulfilled = "fulfilled",
  cancelled = "cancelled",
  noshow = "noshow",
  entered_in_error = "entered-in-error",
  checked_in = "checked-in",
  waitlist = "waitlist"
}
```

## Insertion Points

### Where to Add Paths

Find the last path in the `paths` type (before the closing `};`):

```bash
# Find the closing brace of the paths type
awk '/^export type paths/,/^};/' src/types/schema.ts | tail -30
```

Insert new paths in alphabetical order before `};`.

### Where to Add Operations

Find the last operation in the `operations` interface (before the closing `}`):

```bash
# Find the closing brace of the operations interface
awk '/^export interface operations/,/^}/' src/types/schema.ts | tail -30
```

Insert new operations in alphabetical order before `}`.

### Where to Add Component Schemas

Component schemas are in the `components.schemas` object. Find the alphabetically correct position:

```bash
# Find schemas starting with 'Get'
grep -n "^    Get[A-Z]" src/types/schema.ts
```

Insert in alphabetical order among existing schemas.

### Where to Add Enums

Enums are at the end of the file after the operations interface. Add in alphabetical order:

```bash
# Find enums
grep -n "^export enum" src/types/schema.ts | tail -20
```

## Common Issues and Fixes

### Issue: Missing Type Reference

If a schema references a type that doesn't exist after reversion:

```typescript
// Before
status: components['schemas']['EventStatus'];

// After (if EventStatus doesn't exist)
status: string;
```

### Issue: FHIR Types

Large FHIR resource types (like `Communication`) may already exist. Check before adding:

```bash
grep -n "    Communication:" src/types/schema.ts
```

### Issue: Circular Dependencies

Some schemas reference each other. Extract all of them together:

```typescript
A: {
  b: components['schemas']['B'];
};
B: {
  a?: components['schemas']['A'] | null;
};
```

### Issue: Duplicate Path Definitions

If a path exists in both the old and new schema, decide whether to:
1. Keep the old version
2. Replace with the new version
3. Merge carefully (rare)

Usually keep the old version unless you specifically want the new endpoint.

## Validation Checklist

After manual insertion:

- [ ] All paths are in alphabetical order
- [ ] All operations are in alphabetical order
- [ ] All component schemas are in alphabetical order
- [ ] All enums are in alphabetical order
- [ ] No duplicate definitions
- [ ] All referenced types exist or are replaced with `string`
- [ ] TypeScript compilation succeeds: `npx tsc --noEmit src/types/schema.ts`
- [ ] File formatting is consistent (2-space indents, single quotes)

## Example Commands

```bash
# Generate fresh schema
pnpm schema-ml-scribe:staging

# Extract endpoint info
./extract-endpoint.sh "/api/v2/ml-scribe/integrations/schedule" src/types/schema.ts > schedule.txt

# Find all component schemas manually
grep -o "components\['schemas'\]\['\([^']*\)'\]" schedule.txt | \
  sed "s/.*\['\([^']*\)'\]/\1/" | \
  sort -u

# For each schema, find its definition
grep -n "    GetScheduleResponse:" src/types/schema.ts
# Read and copy the definition

# Revert the schema
git checkout src/types/schema.ts

# Manually insert extracted definitions using edit tool
# Then validate
npx tsc --noEmit src/types/schema.ts
```

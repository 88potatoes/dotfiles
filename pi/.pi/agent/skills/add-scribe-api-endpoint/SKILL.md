# Add Scribe API Endpoint

This skill guides you through adding new API endpoints to the Scribe codebase after extracting them from a regenerated OpenAPI schema.

## When to Use

Use this skill when you need to:
1. Extract specific endpoints from a fresh schema generation
2. Add type definitions for those endpoints
3. Create API functions in the scribeAPIV2 file

## Workflow

### Step 1: Generate Fresh Schema

```bash
cd /Users/eric/Code/scribe-fe-v2
pnpm schema-ml-scribe:staging
```

### Step 2: Extract Endpoint Definitions

For each endpoint you want to add, extract from `src/types/schema.ts`:

1. **Path definition** in the `paths` type
2. **Operation definition** in the `operations` interface  
3. **Component schemas** referenced by the operation

You can search for the endpoint path to find these sections:

```bash
grep -n "your-endpoint-path" src/types/schema.ts
```

Save the extracted definitions for reference.

### Step 3: Revert Schema File

```bash
git restore src/types/schema.ts
```

### Step 4: Manually Add Extracted Definitions to Schema

Add the extracted definitions back to `src/types/schema.ts`:

1. **Add path definition** in the `paths` type (maintain alphabetical order)
2. **Add operation definition** in the `operations` interface (maintain alphabetical order)
3. **Add component schemas** in the `components.schemas` section (maintain alphabetical order)

Validate TypeScript compilation:

```bash
npx tsc --noEmit src/types/schema.ts
```

### Step 5: Add Type Definitions to src/types/index.ts

Follow the existing pattern in the file. Add type exports in the appropriate section (e.g., "Direct Integrations" for integration endpoints).

**Pattern:**

```typescript
export type YourResponseType =
  components['schemas']['YourResponseType'];
export type YourRequestType =
  components['schemas']['YourRequestType'];
```

**Location:** Find similar types and add yours in alphabetical order within that section.

### Step 6: Add API Functions to src/pages/api/scribeAPIV2.ts

#### Import the Types

Add your new types to the import statement from `@/types` (maintain alphabetical order):

```typescript
import {
  // ... other imports
  type YourRequestType,
  type YourResponseType,
} from '@/types';
```

#### Create API Functions

Follow these patterns based on HTTP method:

**GET Request Pattern:**

```typescript
export const getYourEndpoint = (params: { param1: string; param2?: number }) => {
  return scribeHttpV2.get<YourResponseType>('/your-endpoint-path', {
    params,
  });
};
```

- Parameters go in a single object argument
- Pass the params object directly to the axios call

**POST Request Pattern:**

```typescript
export const createYourResource = (
  param1: string,
  body: YourRequestType,
  param2?: string
) => {
  return scribeHttpV2.post<YourResponseType>(
    `/your-endpoint-path/${param1}`,
    body
  );
};
```

- **Path parameters (like sessionId) come first**
- **Body is a separate, dedicated parameter** (comes after path params)
- Optional parameters come last
- Do NOT destructure or spread the body parameter

**Example with sessionId in path:**

```typescript
export const sendSealedMessage = (
  sessionId: string,
  body: SendSealedMessageRequest
) => {
  return scribeHttpV2.post<SendSealedMessageResult>(
    `/integrations/sealed-message-delivery/${sessionId}/send`,
    body
  );
};
```

#### Location

Add functions near related endpoints. For integration endpoints, place them near other integration functions (search for `/integrations/` to find the right location).

## Important Rules

1. **Type Usage:** Use imported types from `@/types`, NOT `components['schemas']['...']` directly in the function signatures
2. **POST Body Parameter:** Body must be a separate, dedicated parameter (not destructured)
3. **Parameter Order:** For POST: `(pathParam1, pathParam2, body, optionalParam?)`
4. **GET Parameters:** Use a single object with named properties: `(params: { name: string; limit?: number })`
5. **Alphabetical Imports:** Maintain alphabetical order in import statements
6. **Type Naming:** Match the schema type names exactly (e.g., `SendSealedMessageRequest`, not `sendSealedMessageRequest`)

## Example: Adding Two Related Endpoints

```typescript
// 1. In src/types/index.ts (after similar types, alphabetically)
export type SealedMessageDeliveryRecipientSearchResponse =
  components['schemas']['SealedMessageDeliveryRecipientSearchResponse'];
export type SealedMessageDeliveryRecipientResult =
  components['schemas']['SealedMessageDeliveryRecipientResult'];
export type SendSealedMessageRequest =
  components['schemas']['SendSealedMessageRequest'];
export type SendSealedMessageResult =
  components['schemas']['SendSealedMessageResult'];

// 2. In src/pages/api/scribeAPIV2.ts (add to imports)
import {
  // ... other imports
  type SealedMessageDeliveryRecipientSearchResponse,
  type SendSealedMessageRequest,
  type SendSealedMessageResult,
} from '@/types';

// 3. In src/pages/api/scribeAPIV2.ts (add functions)
export const searchSealedMessageDeliveryRecipients = (params: { name: string }) => {
  return scribeHttpV2.get<SealedMessageDeliveryRecipientSearchResponse>(
    '/integrations/sealed-message-delivery/recipients',
    {
      params,
    }
  );
};

export const sendSealedMessage = (
  sessionId: string,
  body: SendSealedMessageRequest
) => {
  return scribeHttpV2.post<SendSealedMessageResult>(
    `/integrations/sealed-message-delivery/${sessionId}/send`,
    body
  );
};
```

## Validation

After making changes:

```bash
# Check TypeScript compilation
npx tsc --noEmit

# Or check specific files
npx tsc --noEmit src/pages/api/scribeAPIV2.ts
npx tsc --noEmit src/types/index.ts
```

## Common Pitfalls

- ❌ Don't use `components['schemas']['...']` in function signatures
- ❌ Don't destructure the body parameter in POST functions
- ❌ Don't spread the body with `...body` syntax
- ❌ Don't put body before path parameters (sessionId, etc.)
- ✅ Do use imported types from `@/types`
- ✅ Do make body a separate parameter (after path params, before optional params)
- ✅ Do maintain alphabetical order in imports and type definitions

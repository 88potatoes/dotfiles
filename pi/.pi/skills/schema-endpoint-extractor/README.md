# Schema Endpoint Extractor Skill

A Pi skill for selectively extracting API endpoints and their type definitions from a regenerated OpenAPI schema, then manually reapplying them.

## Quick Start

```bash
# In Pi, invoke the skill:
/skill:schema-endpoint-extractor

# Or let Pi auto-invoke when you ask:
# "I need to extract the /api/v2/integrations/schedule endpoint from the schema"
```

## What This Skill Does

1. Helps you generate a fresh OpenAPI schema
2. Extracts specific endpoint paths and their operation definitions
3. Recursively finds all component schema dependencies
4. Guides you through reverting the schema
5. Helps manually reapply only the extracted types

## Files

- **SKILL.md** - Main skill instructions for Pi
- **REFERENCE.md** - Detailed patterns and examples
- **extract-endpoint.sh** - Helper script to extract endpoint info
- **find-dependencies.sh** - Helper script to find schema dependencies

## Use Cases

- You want only 2-3 new endpoints from a schema update, not all changes
- You need to cherry-pick API changes from a staging environment
- You want to update specific endpoints without breaking existing code
- You need to manually review and control what types get added

## Example Workflow

```bash
# 1. Generate schema
pnpm schema-ml-scribe:staging

# 2. Extract endpoint
cd ~/dotfiles/.pi/skills/schema-endpoint-extractor
./extract-endpoint.sh "/api/v2/integrations/schedule" /path/to/src/types/schema.ts

# 3. Find all dependencies
./find-dependencies.sh /path/to/src/types/schema.ts GetScheduleResponse

# 4. Revert schema
git checkout src/types/schema.ts

# 5. Manually add extracted types using Pi
# Pi will use the edit tool to insert the extracted definitions

# 6. Validate
npx tsc --noEmit src/types/schema.ts
```

## Tips

- Always validate TypeScript compilation after manual changes
- Keep definitions in alphabetical order
- Replace missing type references with `string` if needed
- Check for FHIR types that might already exist
- Test your changes before committing

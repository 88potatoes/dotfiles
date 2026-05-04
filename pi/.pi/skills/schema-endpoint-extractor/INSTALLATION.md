# Installation Complete! ✅

The **schema-endpoint-extractor** skill has been created and installed.

## Location

📁 Source: `~/dotfiles/.pi/skills/schema-endpoint-extractor/`
🔗 Linked: `~/.pi/agent/skills/schema-endpoint-extractor -> ~/dotfiles/.pi/skills/schema-endpoint-extractor`

## Files Created

```
schema-endpoint-extractor/
├── SKILL.md                  # Main skill instructions (read by Pi)
├── REFERENCE.md              # Detailed extraction patterns
├── README.md                 # Overview and use cases
├── QUICKSTART.md             # Getting started guide
├── INSTALLATION.md           # This file
├── extract-endpoint.sh       # Extract endpoint definitions
└── find-dependencies.sh      # Find schema dependencies
```

## How to Use

### Method 1: Let Pi Auto-Invoke (Recommended)

Just ask Pi naturally:

```
"I need to extract the /api/v2/integrations/schedule endpoint 
from the schema after regenerating it with pnpm schema-ml-scribe:staging"
```

Pi will automatically load and execute the skill.

### Method 2: Explicit Invocation

```bash
/skill:schema-endpoint-extractor
```

### Method 3: Direct Script Usage

```bash
cd /path/to/your/project
pnpm schema-ml-scribe:staging

~/dotfiles/.pi/skills/schema-endpoint-extractor/extract-endpoint.sh \
  "/api/v2/integrations/schedule" \
  src/types/schema.ts
```

## Verify Installation

Restart Pi (if currently running) or start a new session, then type:

```bash
/skill:schema-endpoint-extractor
```

You should see Pi load the skill and begin following its workflow.

## What This Skill Does

1. ✅ Runs schema generation command (e.g., `pnpm schema-ml-scribe:staging`)
2. ✅ Extracts specific endpoint paths and operations
3. ✅ Recursively finds all component schema dependencies
4. ✅ Helps revert the schema file
5. ✅ Guides manual reapplication of only the extracted types

## Example Use Case

You regenerated your API schema and got 500+ changes, but you only want 2 new endpoints:
- `/api/v2/integrations/schedule`
- `/api/v2/integrations/sealed-message-delivery/{session_id}/send`

This skill helps you extract ONLY those endpoints and their types, revert the rest, and manually apply just what you need.

## Customization

The skill is in your dotfiles, so you can:
- ✏️  Edit `SKILL.md` to change the workflow
- 🔧 Modify the scripts for your specific schema structure
- 📝 Add project-specific extraction patterns
- 🔄 Commit to version control and share with your team

## Next Steps

1. Try invoking the skill: `/skill:schema-endpoint-extractor`
2. Read the QUICKSTART.md for examples
3. Check REFERENCE.md for detailed extraction patterns

Enjoy! 🎉

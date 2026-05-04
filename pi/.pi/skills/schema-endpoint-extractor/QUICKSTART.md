# Quick Start Guide

## Test the Skill

To verify the skill is working, invoke it in Pi:

```bash
/skill:schema-endpoint-extractor
```

Pi should read the SKILL.md file and follow its instructions.

## Typical Usage

Ask Pi naturally:

> "I need to extract the `/api/v2/ml-scribe/integrations/schedule` and `/api/v2/ml-scribe/integrations/sealed-message-delivery/{session_id}/send` endpoints from the schema after running `pnpm schema-ml-scribe:staging`"

Pi will:
1. Run the schema generation command
2. Extract the endpoint definitions
3. Find all component schema dependencies
4. Guide you through reverting and reapplying

## Manual Usage (without Pi)

If you want to use the scripts directly:

```bash
cd ~/dotfiles/.pi/skills/schema-endpoint-extractor

# Navigate to your project
cd /path/to/your/project

# Generate schema
pnpm schema-ml-scribe:staging

# Extract endpoint info
~/dotfiles/.pi/skills/schema-endpoint-extractor/extract-endpoint.sh \
  "/api/v2/ml-scribe/integrations/schedule" \
  src/types/schema.ts

# Find dependencies for a schema
~/dotfiles/.pi/skills/schema-endpoint-extractor/find-dependencies.sh \
  src/types/schema.ts \
  GetScheduleResponse

# Now manually read the output and:
# 1. Revert the schema file
# 2. Use Pi to help manually insert the extracted types
```

## Configuring Pi to Find the Skill

Pi should automatically discover skills in `~/.pi/agent/skills/` or `.pi/skills/`.

If your skill is in `~/dotfiles/.pi/skills/`, you need to either:

### Option 1: Symlink to standard location

```bash
mkdir -p ~/.pi/agent/skills
ln -s ~/dotfiles/.pi/skills/schema-endpoint-extractor ~/.pi/agent/skills/
```

### Option 2: Configure Pi settings

Create or edit `~/.pi/agent/settings.json`:

```json
{
  "skills": [
    "~/dotfiles/.pi/skills"
  ]
}
```

Or for project-specific, create `.pi/settings.json` in your project:

```json
{
  "skills": [
    "~/dotfiles/.pi/skills"
  ]
}
```

## Verify Skill is Loaded

Start Pi and look for skill loading messages, or type:

```bash
/skill:schema-endpoint-extractor
```

If it works, you'll see Pi load the skill and follow its instructions.

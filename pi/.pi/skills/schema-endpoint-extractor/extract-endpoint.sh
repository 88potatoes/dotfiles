#!/bin/bash
# Extract endpoint definitions and dependencies from OpenAPI schema

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <endpoint-path> <schema-file> [output-file]"
    echo ""
    echo "Examples:"
    echo "  $0 '/api/v2/ml-scribe/integrations/schedule' src/types/schema.ts"
    echo "  $0 '/api/v2/ml-scribe/integrations/schedule' src/types/schema.ts extracted.txt"
    exit 1
fi

ENDPOINT_PATH="$1"
SCHEMA_FILE="$2"
OUTPUT_FILE="${3:-/dev/stdout}"

if [ ! -f "$SCHEMA_FILE" ]; then
    echo "Error: Schema file not found: $SCHEMA_FILE" >&2
    exit 1
fi

# Temporary file for output
TEMP_OUTPUT=$(mktemp)
trap "rm -f $TEMP_OUTPUT" EXIT

echo "=== Extracting endpoint: $ENDPOINT_PATH ===" > "$TEMP_OUTPUT"
echo "" >> "$TEMP_OUTPUT"

# Step 1: Find the path definition
echo "## Path Definition" >> "$TEMP_OUTPUT"
echo "" >> "$TEMP_OUTPUT"
echo "Search for this in the 'paths' type:" >> "$TEMP_OUTPUT"
echo "\`\`\`typescript" >> "$TEMP_OUTPUT"

# Extract path block (this is simplified - in practice you'd need more sophisticated parsing)
grep -A 20 "  '$ENDPOINT_PATH':" "$SCHEMA_FILE" | head -25 >> "$TEMP_OUTPUT" || {
    echo "  // Path not found: $ENDPOINT_PATH" >> "$TEMP_OUTPUT"
}

echo "\`\`\`" >> "$TEMP_OUTPUT"
echo "" >> "$TEMP_OUTPUT"

# Step 2: Find operation names from the path
echo "## Operation Names" >> "$TEMP_OUTPUT"
echo "" >> "$TEMP_OUTPUT"
OPERATIONS=$(grep -A 20 "  '$ENDPOINT_PATH':" "$SCHEMA_FILE" | grep "operations\[" | sed "s/.*operations\['\(.*\)'\].*/\1/" || echo "")

if [ -n "$OPERATIONS" ]; then
    echo "Found operations:" >> "$TEMP_OUTPUT"
    echo "$OPERATIONS" | while read -r op; do
        echo "  - $op" >> "$TEMP_OUTPUT"
    done
else
    echo "No operations found" >> "$TEMP_OUTPUT"
fi
echo "" >> "$TEMP_OUTPUT"

# Step 3: Extract operation definitions
echo "## Operation Definitions" >> "$TEMP_OUTPUT"
echo "" >> "$TEMP_OUTPUT"

if [ -n "$OPERATIONS" ]; then
    echo "$OPERATIONS" | while read -r op; do
        echo "### Operation: $op" >> "$TEMP_OUTPUT"
        echo "\`\`\`typescript" >> "$TEMP_OUTPUT"
        
        # Find the operation definition
        grep -A 40 "  ${op}: {" "$SCHEMA_FILE" | head -45 >> "$TEMP_OUTPUT" || {
            echo "  // Operation not found: $op" >> "$TEMP_OUTPUT"
        }
        
        echo "\`\`\`" >> "$TEMP_OUTPUT"
        echo "" >> "$TEMP_OUTPUT"
    done
fi

# Step 4: Find component schema references
echo "## Component Schema References" >> "$TEMP_OUTPUT"
echo "" >> "$TEMP_OUTPUT"
echo "Search the operation definitions above for patterns like:" >> "$TEMP_OUTPUT"
echo "  components['schemas']['SchemaName']" >> "$TEMP_OUTPUT"
echo "" >> "$TEMP_OUTPUT"
echo "Common schemas to extract:" >> "$TEMP_OUTPUT"

# Extract schema names from operation blocks
if [ -n "$OPERATIONS" ]; then
    SCHEMAS=$(echo "$OPERATIONS" | while read -r op; do
        grep -A 40 "  ${op}: {" "$SCHEMA_FILE" | grep -o "components\['schemas'\]\['\([^']*\)'\]" | sed "s/.*\['\([^']*\)'\]/\1/" | sort -u
    done | sort -u)
    
    if [ -n "$SCHEMAS" ]; then
        echo "$SCHEMAS" | while read -r schema; do
            echo "  - $schema" >> "$TEMP_OUTPUT"
        done
    else
        echo "  (None found - manual inspection recommended)" >> "$TEMP_OUTPUT"
    fi
else
    echo "  (No operations found - cannot extract schemas)" >> "$TEMP_OUTPUT"
fi

echo "" >> "$TEMP_OUTPUT"
echo "## Next Steps" >> "$TEMP_OUTPUT"
echo "" >> "$TEMP_OUTPUT"
echo "1. For each component schema listed above, search the schema file for its definition" >> "$TEMP_OUTPUT"
echo "2. Recursively extract any schemas referenced by those schemas" >> "$TEMP_OUTPUT"
echo "3. Check for enum types referenced by any schemas" >> "$TEMP_OUTPUT"
echo "4. Revert schema.ts and manually add back all extracted definitions" >> "$TEMP_OUTPUT"

# Output to file or stdout
if [ "$OUTPUT_FILE" = "/dev/stdout" ]; then
    cat "$TEMP_OUTPUT"
else
    cp "$TEMP_OUTPUT" "$OUTPUT_FILE"
    echo "Extraction saved to: $OUTPUT_FILE" >&2
fi

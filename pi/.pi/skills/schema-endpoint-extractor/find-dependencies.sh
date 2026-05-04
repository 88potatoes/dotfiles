#!/bin/bash
# Recursively find all component schema dependencies for given schema names

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <schema-file> <schema-name> [schema-name2 ...]"
    echo ""
    echo "Examples:"
    echo "  $0 src/types/schema.ts GetScheduleResponse"
    echo "  $0 src/types/schema.ts SendSealedMessageRequest GetScheduleResponse"
    exit 1
fi

SCHEMA_FILE="$1"
shift
INITIAL_SCHEMAS=("$@")

if [ ! -f "$SCHEMA_FILE" ]; then
    echo "Error: Schema file not found: $SCHEMA_FILE" >&2
    exit 1
fi

# Use associative array to track seen schemas
declare -A SEEN
declare -a QUEUE=()
declare -a ALL_SCHEMAS=()

# Initialize queue with initial schemas
for schema in "${INITIAL_SCHEMAS[@]}"; do
    QUEUE+=("$schema")
done

# Process queue
while [ ${#QUEUE[@]} -gt 0 ]; do
    # Pop first item
    CURRENT="${QUEUE[0]}"
    QUEUE=("${QUEUE[@]:1}")
    
    # Skip if already seen
    if [ -n "${SEEN[$CURRENT]}" ]; then
        continue
    fi
    
    # Mark as seen
    SEEN[$CURRENT]=1
    ALL_SCHEMAS+=("$CURRENT")
    
    # Find the schema definition
    SCHEMA_START=$(grep -n "^    ${CURRENT}:" "$SCHEMA_FILE" | cut -d: -f1 | head -1)
    
    if [ -z "$SCHEMA_START" ]; then
        # Try with different patterns
        SCHEMA_START=$(grep -n "    ${CURRENT}: {" "$SCHEMA_FILE" | cut -d: -f1 | head -1)
    fi
    
    if [ -n "$SCHEMA_START" ]; then
        # Extract schema block (approximate - get next 100 lines)
        SCHEMA_BLOCK=$(sed -n "${SCHEMA_START},$((SCHEMA_START + 100))p" "$SCHEMA_FILE")
        
        # Find all component schema references
        REFS=$(echo "$SCHEMA_BLOCK" | \
               grep -o "components\['schemas'\]\['\([^']*\)'\]" | \
               sed "s/.*\['\([^']*\)'\]/\1/" | \
               sort -u)
        
        # Add refs to queue if not seen
        while IFS= read -r ref; do
            if [ -n "$ref" ] && [ -z "${SEEN[$ref]}" ]; then
                QUEUE+=("$ref")
            fi
        done <<< "$REFS"
    fi
done

# Output results
echo "=== All Component Schemas (${#ALL_SCHEMAS[@]} total) ==="
echo ""
for schema in "${ALL_SCHEMAS[@]}"; do
    echo "$schema"
done

echo ""
echo "=== Check for Enum References ==="
echo ""
echo "Search for these patterns in the schema definitions:"
for schema in "${ALL_SCHEMAS[@]}"; do
    # Try to find if this is an enum
    IS_ENUM=$(grep -c "^export enum $schema" "$SCHEMA_FILE" || echo 0)
    if [ "$IS_ENUM" -gt 0 ]; then
        echo "  - $schema (is an ENUM)"
    fi
done

echo ""
echo "Also manually check schema definitions for enum references like:"
echo "  field: SomeEnumType;"
echo "  field: components['schemas']['SomeEnumType'];"

#!/bin/bash

# Azure Monitor Diagnostic Settings Check Script

# Resource ID passed as an argument
RESOURCE_ID=$1

# Check for the diagnostic settings using Azure CLI
OUTPUT=$(az monitor diagnostic-settings list --resource "$RESOURCE_ID" --output json 2>&1)

# Check the exit status of the previous command
EXIT_STATUS=$?

# Check if the command executed successfully and if the output contains any diagnostic settings
if [ $EXIT_STATUS -ne 0 ] || [[ $OUTPUT == "[]" || $OUTPUT == "{}" || -z $OUTPUT ]]; then
    echo "{\"exists\": \"false\"}"
else
    echo "{\"exists\": \"true\"}"
fi

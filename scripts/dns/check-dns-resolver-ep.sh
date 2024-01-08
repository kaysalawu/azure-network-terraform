#!/bin/bash

# Check for at least two arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 resource_group dns_resolver_name..."
    exit 1
fi

RG_NAME=$1
DNS_RESOLVERS=("${@:2}")
SUCCEEDED_STATE="Succeeded"
SECONDS=0

check_and_print_endpoints() {
    local resolver_name=$1
    local endpoint_types=("inbound" "outbound")

    for endpoint_type in "${endpoint_types[@]}"; do
        local endpoints=$(az dns-resolver "${endpoint_type}-endpoint" list -g "$RG_NAME" --dns-resolver-name "$resolver_name" --query "[].{name:name, state:provisioningState}" -o tsv)

        if [[ -z $endpoints ]]; then
            echo "${resolver_name}: None"
            continue
        fi

        while IFS=$'\t' read -r name state; do
            echo "${resolver_name}: ${name} = ${state} [time elapsed ${SECONDS}s]"
            if [[ $state != $SUCCEEDED_STATE ]]; then
                return 1
            fi
        done <<< "$endpoints"
    done

    return 0
}

# Main loop
while :; do
    all_succeeded=true

    for resolver in "${DNS_RESOLVERS[@]}"; do
        if ! check_and_print_endpoints "$resolver"; then
            all_succeeded=false
        fi
    done

    if $all_succeeded; then
        echo "Success!"
        break
    fi

    sleep 5
    ((SECONDS+=5))
done

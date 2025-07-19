#!/bin/bash

# Function to assign roles to resources
assign_roles() {
    while IFS= read -r object; do
        resource_id=$(jq -r '.resource_id' <<< "$object")
        role=$(jq -r '.role' <<< "$object")
        username=$(jq -r '.username' <<< "$object")

        echo "user: $username"

        # Assign role to the user for the specified resource
        {
            az role assignment create --assignee "$username" --role "$role" --scope "$resource_id"
        } &

        # Store the PID of the last background process
        pid_list+=($!)

        # Check if the assignment was successful
        if [ $? -eq 0 ]; then
            echo "Assigned role $role to user $username for resource $resource_id"
        else
            echo "Failed to assign role $role to user $username for resource $resource_id"
        fi
    done < <(jq -c '.[]' "$1")

    # Wait for all background processes to finish
    wait "${pid_list[@]}"
}

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Azure CLI is not installed. Please install it before running this script."
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install it before running this script."
    exit 1
fi

# Check if the input file is provided as argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <role_assignments_json_file>"
    exit 1
fi

# Check if the provided file exists
if [ ! -f "$1" ]; then
    echo "File $1 not found."
    exit 1
fi

# Call the function to assign roles
assign_roles "$1"


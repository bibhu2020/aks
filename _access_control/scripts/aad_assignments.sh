#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS(internal field separator) new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@).

usage() { echo "Usage: $0 -s <Subscription Id> -f <Assignment JSON File>" 1>&2; exit 1; }
declare assignmentFile=""
declare subscriptionId=""

# Initialize parameters specified from command line
while getopts ":f:" arg; do
	case "${arg}" in
		f)
			assignmentFile=${OPTARG}
			;;
	esac
done
shift $((OPTIND-1))

#Prompt for parameters is some required parameters are missing
if [[ -z "$assignmentFile" ]]; then
	echo "Assignment JSON File:"
	read assignmentFile
	[[ "${assignmentFile:?}" ]]
fi

if [ -z "$assignmentFile" ]; then
	echo "Assignment File is empty"
	usage
fi

# Function to assign roles to resources
assign_to_aad() {
    while read -r object; do
        group=$(jq -r '.group' <<< "$object")
        user=$(jq -r '.user' <<< "$object")
        action=$(jq -r '.action' <<< "$object")

        echo $user

        # Assign role to the user for the specified resource
        {
            user_object_id=$(az ad user show --id  "$user" --query id -o tsv)
            user_object_id="${user_object_id%"${user_object_id##*[![:space:]]}"}"
            group_object_id=$(az ad group show --group "$group" --query id -o tsv)
            group_object_id="${group_object_id%"${group_object_id##*[![:space:]]}"}"
            # echo "$user_object_id: $user"
            # echo "$group_object_id: $group"

            userExists=$(az ad group member check --group "$group_object_id" --member-id "$user_object_id" --query value)
            userExists="${userExists%"${userExists##*[![:space:]]}"}"
            # echo $userExists

            # Check if the user is already a member of the group
            if [ $userExists == "true" ]; then
                if [[ "$action" == "remove" ]]  
                then
                    az ad group member remove --group "$group_object_id" --member-id "$user_object_id" < /dev/null
                else 
                    echo "User $user is already a member of the group $group."
                fi
            else
                # Add the user to the group
                if [[ "$action" == "add" ]]  
                then
                    az ad group member add --group "$group_object_id" --member-id "$user_object_id" < /dev/null
                fi
            fi

        } #&

        # Store the PID of the last background process
        #pid_list+=($!)

        echo "$action $user to/from $group."

    done < <(jq -c '.[]' "$assignmentFile") 

    # Wait for all background processes to finish
    #wait "${pid_list[@]}"
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

# Call the function to assign roles
assign_to_aad "$assignmentFile"


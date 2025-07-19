#!/usr/bin/env bash

# set KV SUFFIX (It's a Terraform ENV variable)
export TF_VAR_KVSUFFIX=$(eval date +%s%N | sha256sum | head -c 8)
echo $TF_VAR_KVSUFFIX
 
TF_ENV=$1
if [ ! -d "$TF_ENV" ]; then
  echo "Error: $TF_ENV environment directory does not exist."
  exit 0
fi
if [ ${#TF_ENV} -lt 3 ]; then
  echo "Error: $TF_ENV directory is not valid. It should atleast 3 character log. E.g. dev, prd, ppe."
  exit 0
fi 
if [ ${#TF_ENV} -gt 3 ] && [ ${TF_ENV:3:1} != "-" ]; then
  echo "Error: <$TF_ENV> is not a valid directory. The directory must have 3 character environment code suffixed with "-". E.g. dev, poc, dev-base, poc-secblogs."
  exit 0
fi

BACKEND_FILE="./backend-$TF_ENV.conf"
VARIABLE_FILE="./variables-$TF_ENV.tfvars"
ENV=${TF_ENV:0:3}
APP=${TF_ENV:4}

# Copy the backend configuration file
if [ ! -f ./_configs/backend-$TF_ENV.conf ]; then
  echo "Error: ./_configs/backend-$TF_ENV.conf is missing."
  exit 0
else
  cp ./_configs/backend-$TF_ENV.conf ./$TF_ENV/backend-$TF_ENV.conf 
fi

# Copy the variable value file
if [ ! -f ./_variables/variables-$ENV.tfvars ]; then
  echo "Error: ./_variables/variables-$ENV.tfvars is missing."
  exit 0
else
  cp ./_variables/variables-$ENV.tfvars ./$TF_ENV/variables-$TF_ENV.tfvars
fi

# Check if the resource files are existing. if yes, copy them to execution or environment folder.
cp ./_source/main.tf ./$TF_ENV/
cp ./_source/variables.tf ./$TF_ENV/
if [ ${#APP} -gt 0 ]; then
  if [ ! -f ./_source/resources-$APP.tf ]; then
    echo "Error: ./_source/resources-$APP.tf is missing."
    exit 0 
  else
    cp ./_source/resources-$APP.tf ./$TF_ENV/
  fi
  if [ ! -f ./_source/outputs-$APP.tf ]; then
    echo "Error: ./_source/outputs-$APP.tf is missing."
    exit 0
  else
    cp ./_source/outputs-$APP.tf ./$TF_ENV/outputs.tf
  fi
else
  cp ./_source/outputs.tf ./$TF_ENV/
  cp ./_source/resources.tf ./$TF_ENV/
fi
 
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
 
# # Always run from the location of this script
echo $DIR
cd "$DIR"
 
if [ $# -gt 0 ]; then
    echo "Executing the terraform scripts......................................................."
    if [ "$2" == "init" ]; then
        terraform -chdir=./$TF_ENV init -backend-config=$BACKEND_FILE
    # elif [ "$2" == "getsshkey" ]; then
    #     terraform -chdir=./$TF_ENV show -json | jq -r '.values.ssh_key.tls_private_key.ssh_key.resources[] '
    elif [ "$2" == "initupgrade" ]; then
        terraform -chdir=./$TF_ENV init -backend-config=$BACKEND_FILE -upgrade
    elif [ "$2" == "plan" ]; then
        terraform -chdir=./$TF_ENV plan -var-file=$VARIABLE_FILE
    elif [ "$2" == "apply" ]; then
        terraform -chdir=./$TF_ENV apply -var-file=$VARIABLE_FILE --auto-approve
    elif [ "$2" == "destroy" ]; then
        terraform -chdir=./$TF_ENV destroy -var-file=$VARIABLE_FILE --auto-approve
    elif [ "$2" == "refresh" ]; then
        terraform -chdir=./$TF_ENV refresh -var-file=$VARIABLE_FILE 
    elif [ "$2" == "taint" ]; then
        terraform -chdir=./$TF_ENV taint $3 -allow-missing -var-file=$VARIABLE_FILE 
    else
        terraform -chdir=./$TF_ENV $2
    fi
fi

#rm ./$TF_ENV/main.tf
# #rm ./$TF_ENV/variables.tf
# if [ ${#TF_ENV} -gt 3 ]; then
#     #rm ./$TF_ENV/backend-$TF_ENV.conf 
#     rm ./$TF_ENV/variables-$TF_ENV.tfvars
# fi


# # Head back to original location to avoid surprises
cd -

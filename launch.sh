#!/bin/bash
set -e

# check arguments
if [[ -z $1 && ! -f "task/run.sh" ]]; then
  echo "Plase provide a custom command or create a \`task/run.sh\` file"
  echo ""
  echo "Usage:"
  echo "$0            # if task/run.sh exists"
  echo "$0 <command>  # if you want to specify a custom command to run"
  exit 1
fi

# load env vars
if [[ -f ".env" ]]; then
  unamestr=$(uname)
  if [ "$unamestr" = 'Linux' ]; then
    export $(grep -v '^#' .env | xargs -d '\n')
  elif [ "$unamestr" = 'FreeBSD' ] || [ "$unamestr" = 'Darwin' ]; then
    export $(grep -v '^#' .env | xargs -0)
  fi
fi

# create instance
INSTANCE_ID=`curl -s -u "$LLABS_API_KEY:" https://cloud.lambdalabs.com/api/v1/instance-operations/launch -d "{\"region_name\":\"$LLABS_REGION\",\"instance_type_name\":\"$LLABS_INSTANCE\",\"ssh_key_names\":[\"$LLABS_SSH_KEY\"],\"file_system_names\":[]}" -H "Content-Type: application/json" | jq .data.instance_ids[0] | sed 's/"//g'`
echo "Created: $INSTANCE_ID"

# destroy instance after task is executed or if error occurs
destroy() {
  echo "";
  echo "Destroying instance..."
  INSTANCE_INFO=`curl -s -u "$LLABS_API_KEY:" https://cloud.lambdalabs.com/api/v1/instance-operations/terminate -d "{\"instance_ids\":[\"$INSTANCE_ID\"]}" -H "Content-Type: application/json"`
  echo "Destroyed: $INSTANCE_ID"
}
trap destroy 0

# wait for active status
INSTANCE_INFO=`curl -s -u "$LLABS_API_KEY:" "https://cloud.lambdalabs.com/api/v1/instances/$INSTANCE_ID" | jq .data`
echo "Status: `echo $INSTANCE_INFO | jq .status | sed 's/"//g'`"
until [[ `echo $INSTANCE_INFO | jq .status | sed 's/"//g'` == "active" ]]; do
  printf ".";
  sleep 3;
  INSTANCE_INFO=`curl -s -u "$LLABS_API_KEY:" "https://cloud.lambdalabs.com/api/v1/instances/$INSTANCE_ID" | jq .data`
done
echo "";
echo "Status: `echo $INSTANCE_INFO | jq .status | sed 's/"//g'`"
echo "";
echo "###########################################################"
echo "#"
echo "#  Region:           `echo $INSTANCE_INFO | jq .region.description | sed 's/"//g'` (`echo $INSTANCE_INFO | jq .region.name | sed 's/"//g'`)"
echo "#  IP:               `echo $INSTANCE_INFO | jq .ip | sed 's/"//g'`"
echo "#  Hostname:         `echo $INSTANCE_INFO | jq .hostname | sed 's/"//g'`"
echo "#  Jupyther token:   `echo $INSTANCE_INFO | jq .jupyter_token | sed 's/"//g'`"
echo "#"
echo "###########################################################"
echo "";

# get instance IP
INSTANCE_IP=`echo $INSTANCE_INFO | jq .ip | sed 's/"//g'`

# accept host fingerprint (to avoid manual interaction)
echo "Accept `echo $INSTANCE_INFO | jq .hostname | sed 's/"//g'` fingerprint"
ssh-keygen -R $INSTANCE_IP
ssh-keyscan -H $INSTANCE_IP >> ~/.ssh/known_hosts

# prepare working dir
ssh ubuntu@$INSTANCE_IP "sudo mkdir -p /srv/task"
ssh ubuntu@$INSTANCE_IP "sudo chown \$USER /srv/task"

# copy files
if [[ -d "task" ]]; then
  echo "Copy files"
  scp -r ./task ubuntu@$INSTANCE_IP:/srv
  ssh ubuntu@$INSTANCE_IP "mkdir -p /srv/task/output"
fi

# make sure task/run.sh can be executed
if [[ -f "task/run.sh" ]]; then
  ssh ubuntu@$INSTANCE_IP "chmod +x /srv/task/run.sh"
fi

# if rclone config exists copy that too
if [[ -f "rclone.conf" ]]; then
  ssh ubuntu@$INSTANCE_IP "mkdir -p /home/ubuntu/.config/rclone"
  scp rclone.conf ubuntu@$INSTANCE_IP:/home/ubuntu/.config/rclone/rclone.conf
fi

# define ssh command for the task
if [[ -n $1 ]]; then
  TASK_COMMAND=$1
else
  TASK_COMMAND="./run.sh"
fi

# connect to instance and exec task
echo "Execute task"
ssh ubuntu@$INSTANCE_IP -t "PATH=\$PATH:~/.local/bin; cd /srv/task; $TASK_COMMAND; exit"


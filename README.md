# Lambda Labs Task

Execute a task on Lambda Labs by spinning a temporary VM with GPU support.

The script takes care of creating a VM, copying the task files, executing the task and shutting down the VM once the task is over (regardless of the result, to avoid incurring in unexpected charges).

## Requirements

**Services**

- Lambda Labs [GPU Cloud](https://lambdalabs.com/service/gpu-cloud) account

**Packages**

- `ssh`, `curl`, `jq`, `sed`

## Setup

1. Retrieve the Lambda Labs [API key](https://cloud.lambdalabs.com/api-keys) and upload your [SSH key](https://cloud.lambdalabs.com/ssh-keys)
2. Configure the `.env` file with Lambda Labs keys and VM info (or set them in your environment)

## Get started

### Interactive session

1. Launch SSH session on a VM with `launch.sh bash`

### Run task

1. Add your code in the `task` folder (optional)
2. Add a `task/run.sh` file to start the task (optional)
3. Run the task on a VM with `launch.sh` (or run your own command with `launch.sh <command>`)

## Script usage 

By default `launch.sh` runs the `task/run.sh` script when the VM is ready.
You can include initialization and execution in this script and it will run from the `/srv/task` folder that contains all the code data from the local `task` folder.

To run a custom command just pass it as parameter with `launch.sh <command>`.

**Examples**

Default behaviour, executes `task/run.sh`
```
./launch.sh
```

Launch an interactive session
```
./launch.sh bash
```

Launch custom pipeline
```
./launch.sh "./init.sh; ./exec_task.sh; ./store_results.sh"
```

## Configuration

### Code

You can customise the code by adding it to the `task` folder.
Everything in the folder will be copied over after the VM has started.

### Auth

The Lambda Labs API keys can be either set in the `.env` file or directly in your environment.
If you set them in your environment make sure to remove or comment the entries in the .env file (or remove the whole file) to avoid overrides.

### VM

The VM configuration (both size and region) can also be configured via `.env` file or environment variables.

As per auth configuration, when the variables are set directly in the environment and not the `.env` file, they should be removed in the file to avoid overrides.

## Rclone

If a `rclone.conf` file is provided in the main directory that would be copied over to the VM in the `~/.config/rclone` directory.
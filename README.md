# Lambda Labs Task

Execute a task on Lambda Labs by spinning a temporary VM with GPU support.

The script takes care of creating a VM, copying the task files, executing the task and shutting down the VM once the task is over (regardless of the result, to avoid incurring in unexpected charges).

## Requirements

**Packages**

- ssh
- curl
- jq
- sed

**Services**

- Lambda Labs [GPU Cloud](https://lambdalabs.com/service/gpu-cloud) account

## Get started

1. Add your code in the `task` folder
2. Add a `task/run.sh` file to start the task (optional)
3. Configure the `.env` file with Lambda Labs keys and VM info (or set them in your environment)
  - retrieve [API key](https://cloud.lambdalabs.com/api-keys)
  - upload your [SSH key](https://cloud.lambdalabs.com/ssh-keys)
4. Run the task on the VM with `launch.sh`

## Usage 

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
If you set them in your environment make sure to remove or comment the entries from the .env file (or remove the whole file) to avoid overrides.

### VM

The VM configuration (both size and region) can also be configured via .env file or environment variable.

As per auth configuration, when the variables are set directly in the environment and not the `.env` file, they should be removed from the file to avoid overrides.

## Rclone

If a `rclone.conf` file is provided in the main directory that would be copied over to the VM in the `~/.config/rclone` directory.
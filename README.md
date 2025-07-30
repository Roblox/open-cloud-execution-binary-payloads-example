# Open Cloud Luau Execution, Binary Input/Output Demo

> [!WARNING]  
> This is a sample project intended to demonstrate how a feature can be used. It is not battle tested or maintained and creators should proceed with caution when adapting it for their own experiences.

This repository contains a demonstration of how to use the Binary Input / Output features of the [Open Cloud Luau Execution API](https://create.roblox.com/docs/cloud/reference/LuauExecutionSessionTask).

It includes:

- `DemoSDK.luau` A quick SDK for Luau Execution Sessions thrown together to unlock the demo
- `demo.luau` An example of how to use both binary inputs + outputs 
- `scriptToRun.luau` The payload executed

This demo runs in [Lune](https://lune-org.github.io/docs).

## Setup

Be sure to install Lune, the quickest way is using Rokit. More info can be found in [Lune's docs](https://lune-org.github.io/docs/getting-started/1-installation).

Next, create a Open Cloud API key with `luau-execution-sessions:write` access to a specific Place. Then update `demo.luau` to include your universeId and placeId 

## Usage

Ensure your cwd is this directory, then add your API key to the environment then run the lune script.

Shell (MacOs / Linux):
```sh
export ROBLOX_API_KEY=abcdefg
lune run demo.luau
```

Batch (Windows):
```cmd
set ROBLOX_API_KEY=abcdefg
lune run demo.luau
```

## Expected Output

```
Creating binary input...
Uploading binary file...
Creating task...
Waiting for task completion...
Logs:
	- Deserialized Part from input buffer
Task succeeded. Return values: Part
Downloading binary output...
Binary output saved to output.rbxm
```


local process = require("@lune/process")
local fs = require("@lune/fs")
local DemoSDK = require("./DemoSDK")

local apiKey = process.env.ROBLOX_API_KEY

local universeId = 7799045421 -- YOUR UNIVERSE ID
local placeId = 130252519611555 -- YOUR PLACE ID
local placeVersion = 1 -- YOUR PLACE VERSION (optional, defaults to latest)
local filePath = "part.rbxm" -- The binary file to include as a binary input

-- Step 1) Create a binary input for this universeId
print("Creating binary input...")
local binaryInput = DemoSDK.createBinaryInput(apiKey, universeId, filePath)

-- Step 2) Upload your file to the binary input
print("Uploading binary file...")
DemoSDK.uploadBinaryFile(binaryInput.uploadUri, filePath)

-- Step 3) Create a task with the binary input path, script source to run with binary output enabled
print("Creating task...")
local scriptSource = fs.readFile("scriptToRun.luau")
local task = DemoSDK.createTask(
	apiKey,
	{ universeId = universeId, placeId = placeId, placeVersion = placeVersion },
	scriptSource,
	binaryInput.path,
	true
)

-- Step 4) Poll until the task is completed
print("Waiting for task completion...")
local completedTask = DemoSDK.pollTaskCompletion(apiKey, task.path)
local logs = DemoSDK.getTaskLogs(apiKey, completedTask.path) -- Grab logs to assist debugging (optional)
print(`Logs:\n\t- {table.concat(logs, "\n\t- ")}`)
if completedTask.state == "FAILED" then
	error(`Task failed with error: {completedTask.error.code} - {completedTask.error.message}`)
elseif completedTask.state == "CANCELLED" then
	error("Task was cancelled")
end
print(`Task succeeded. Return values: {table.concat(completedTask.output.results, ", ")}`)

-- Step 5) Download the binary output
print("Downloading binary output...")
local output = DemoSDK.getBinaryOutput(completedTask.binaryOutputUri)
fs.writeFile("output.rbxm", output)
print("Binary output saved to output.rbxm")

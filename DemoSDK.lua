--!strict
--[[
	Quick and dirty SDK for the Luau Execution Sessions API thrown together for demo purposes.
]]
local net = require("@lune/net")
local serde = require("@lune/serde")
local process = require("@lune/process")
local fs = require("@lune/fs")
local task = require("@lune/task")

-- Unfortunately Lune's standard library doesn't have an out of the box stat method to get file sizes
local function getFileSize(filePath: string): number
	if process.os == "windows" then
		filePath = filePath:gsub("'", "''")
		local results = process.exec("powershell.exe", { "-NoProfile", "-Command", "(Get-Item '" .. filePath .. "').length"}).length` })
		assert(results.ok, results.stderr)
		local size = tonumber(results.stdout:match("%s*(%d+)"))
		assert(size, `Failed to parse file size from output: {results.stdout}`)
		return size
	elseif process.os == "macos" or process.os == "linux" then
		local results = process.exec("wc", { "-c", filePath })
		assert(results.ok, results.stderr)
		local size = tonumber(results.stdout:match("%s*(%d+)"))
		assert(size, `Failed to parse file size from output: {results.stdout}`)
		return size
	else
		error(`OS {process.os} is not implemented in getFileSize`)
	end
end

local DemoSDK = {}

export type BinaryInputResponse = { path: string, size: number, uploadUri: string }
function DemoSDK.createBinaryInput(apiKey: string, universeId: number, filePath: string): BinaryInputResponse
	local response = net.request({
		url = `https://apis.roblox.com/cloud/v2/universes/{universeId}/luau-execution-session-task-binary-inputs`,
		method = "POST",
		headers = { ["x-api-key"] = apiKey, ["content-type"] = "application/json" },
		body = serde.encode("json", { size = getFileSize(filePath) }),
	})
	assert(response.ok, `{response.statusCode} {response.statusMessage} - {response.body}`)
	return serde.decode("json", response.body)
end

function DemoSDK.uploadBinaryFile(uploadUri: string, filePath: string)
	local response = net.request({
		url = uploadUri,
		method = "PUT",
		headers = { ["content-type"] = "application/octet-stream" },
		body = fs.readFile(filePath),
	})
	assert(response.ok, `{response.statusCode} {response.statusMessage} - {response.body}`)
end

type PlaceInfo = {
	universeId: number,
	placeId: number,
	placeVersion: number?,
}
local function getCreateTaskPath(placeInfo: PlaceInfo): string
	local url = `https://apis.roblox.com/cloud/v2/universes/{placeInfo.universeId}/places/{placeInfo.placeId}/`
	if placeInfo.placeVersion then
		url ..= `versions/{placeInfo.placeVersion}/`
	end
	url ..= "luau-execution-session-tasks"

	return url
end

export type TaskResponse = {
	path: string,
	createTime: string,
	updateTime: string,
	user: string,
	state: string,
	script: string,
	timeout: string,
	error: {
		code: string,
		message: string,
	}?,
	output: {
		results: { any },
	},
	enableBinaryOutput: true,
	binaryInput: string?,
	binaryOutputUri: string?,
}
function DemoSDK.createTask(
	apiKey: string,
	placeInfo: PlaceInfo,
	script: string,
	binaryInputPath: string?,
	enableBinaryOutput: boolean?,
	timeout: string?
): TaskResponse
	local url = getCreateTaskPath(placeInfo)
	local response = net.request({
		url = url,
		method = "POST",
		headers = { ["x-api-key"] = apiKey, ["content-type"] = "application/json" },
		body = serde.encode("json", {
			script = script,
			binaryInput = binaryInputPath,
			enableBinaryOutput = enableBinaryOutput,
			timeout = timeout,
		}),
	})
	assert(response.ok, `{response.statusCode} {response.statusMessage} - {response.body}`)

	return serde.decode("json", response.body)
end

function DemoSDK.pollTaskCompletion(
	apiKey: string,
	taskPath: string,
	pollMaxAttempts: number?,
	pollInterval: number?
): TaskResponse
	local attemptsRemaining = pollMaxAttempts or -1
	pollInterval = pollInterval or 2

	while attemptsRemaining ~= 0 do
		attemptsRemaining -= 1

		local response = net.request({
			url = `https://apis.roblox.com/cloud/v2/{taskPath}`,
			method = "GET",
			headers = { ["x-api-key"] = apiKey },
		})
		assert(response.ok, `{response.statusCode} {response.statusMessage} - {response.body}`)
		local body = serde.decode("json", response.body)
		if body.state ~= "PROCESSING" then
			return serde.decode("json", response.body)
		end

		task.wait(pollInterval)
	end

	error("Task did not complete within the maximum number of attempts")
end

function DemoSDK.getBinaryOutput(binaryOutputUri: string): string
	local response = net.request({
		url = binaryOutputUri,
		method = "GET",
	})
	assert(response.ok, `{response.statusCode} {response.statusMessage} - {response.body}`)
	return response.body
end

function DemoSDK.getTaskLogs(apiKey: string, taskPath: string): string
	local response = net.request({
		url = `https://apis.roblox.com/cloud/v2/{taskPath}/logs`,
		method = "GET",
		headers = { ["x-api-key"] = apiKey },
	})
	assert(response.ok, `{response.statusCode} {response.statusMessage} - {response.body}`)

	local body = serde.decode("json", response.body)
	local logs = body.luauExecutionSessionTaskLogs[1].messages
	assert(logs, "Error downloading task logs")
	return logs
end

return DemoSDK

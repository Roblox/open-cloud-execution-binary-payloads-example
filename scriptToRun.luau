local SerializationService = game:GetService("SerializationService")

-- The binary input is added as the first argument the script is called with
local arg = ({ ... })[1]
local inputBuffer = arg.BinaryInput

local inputInstance = SerializationService:DeserializeInstancesAsync(inputBuffer)[1]
print(`Deserialized {inputInstance.Name} from input buffer`)

local outputInstance = Instance.new("Model")
outputInstance.Name = "OutputModel"

local returnBuffer = SerializationService:SerializeInstancesAsync({ outputInstance })

-- Because we set enableBinaryOutput: true on this task, we need to return in this format
return {
	BinaryOutput = returnBuffer,
	ReturnValues = { inputInstance.Name },
}

local Errors = {}

Errors.Codes = {
	NavigationError = "NAVIGATION_ERROR",
	InteractionError = "INTERACTION_ERROR",
	ValidationError = "VALIDATION_ERROR",
	AdapterError = "ADAPTER_ERROR",
	ConfigurationError = "CONFIGURATION_ERROR",
	SerializationError = "SERIALIZATION_ERROR",
	TimeoutError = "TIMEOUT_ERROR",
}

function Errors.new(code, message, retryable)
	return {
		code = code or Errors.Codes.ValidationError,
		message = message or "unknown error",
		retryable = retryable == true,
	}
end

function Errors.wrap(err, code)
	if type(err) == "table" and err.code then
		return err
	end

	return Errors.new(code, tostring(err), false)
end

return Errors

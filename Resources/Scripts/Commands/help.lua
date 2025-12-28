local module = {}

function module:Command(args:{string})
	warn("List of commands:")
	for i, v in pairs(script.Parent:GetChildren()) do
		print(v.Name)
	end
	warn("The lists ends here.")
end

return module

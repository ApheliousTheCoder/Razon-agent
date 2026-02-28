local Selection = game:GetService("Selection")

local MAX_SCANNED_SCRIPTS = 200

local scannedFiles = {}

local function getInstancePath(inst)
	local parts = {}
	local current = inst

	while current and current ~= game do
		table.insert(parts, 1, current.Name)
		current = current.Parent
	end

	return table.concat(parts, "/")
end

local function isScriptInstance(inst)
	return inst:IsA("Script") or inst:IsA("LocalScript") or inst:IsA("ModuleScript")
end

local function collectScriptInstances(roots)
	local stack = {}
	local seen = {}
	local found = {}
	local capped = false

	for _, root in ipairs(roots) do
		table.insert(stack, root)
	end

	while #stack > 0 do
		local current = table.remove(stack)

		if current and not seen[current] then
			seen[current] = true

			if isScriptInstance(current) then
				table.insert(found, current)

				if #found >= MAX_SCANNED_SCRIPTS then
					capped = true
					break
				end
			end

			local children = current:GetChildren()
			for i = #children, 1, -1 do
				local child = children[i]
				if not seen[child] then
					table.insert(stack, child)
				end
			end
		end
	end

	return found, capped
end

local toolbar = plugin:CreateToolbar("Razon Agent")
local toggleButton = toolbar:CreateButton("Razon Agent", "Show or hide the Razon Agent panel.", "")
toggleButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	true,
	true,
	430,
	580,
	320,
	360
)
local widget = plugin:CreateDockWidgetPluginGui("RazonAgentWidget", widgetInfo)
widget.Title = "Razon Agent"
widget.Enabled = true
toggleButton:SetActive(widget.Enabled)

toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	toggleButton:SetActive(widget.Enabled)
end)

local root = Instance.new("Frame")
root.Name = "Root"
root.Parent = widget
root.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
root.BorderSizePixel = 0
root.Size = UDim2.fromScale(1, 1)

local promptLabel = Instance.new("TextLabel")
promptLabel.Name = "PromptLabel"
promptLabel.Parent = root
promptLabel.BackgroundTransparency = 1
promptLabel.Position = UDim2.new(0, 8, 0, 8)
promptLabel.Size = UDim2.new(1, -16, 0, 18)
promptLabel.Font = Enum.Font.SourceSansSemibold
promptLabel.Text = "Prompt"
promptLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
promptLabel.TextSize = 16
promptLabel.TextXAlignment = Enum.TextXAlignment.Left

local promptInput = Instance.new("TextBox")
promptInput.Name = "PromptInput"
promptInput.Parent = root
promptInput.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
promptInput.BorderSizePixel = 0
promptInput.ClearTextOnFocus = false
promptInput.MultiLine = true
promptInput.PlaceholderText = "Describe the change you want..."
promptInput.Position = UDim2.new(0, 8, 0, 30)
promptInput.Size = UDim2.new(1, -16, 0, 110)
promptInput.Font = Enum.Font.Code
promptInput.Text = ""
promptInput.TextColor3 = Color3.fromRGB(235, 235, 235)
promptInput.TextSize = 14
promptInput.TextWrapped = true
promptInput.TextXAlignment = Enum.TextXAlignment.Left
promptInput.TextYAlignment = Enum.TextYAlignment.Top

local buttonsRow = Instance.new("Frame")
buttonsRow.Name = "ButtonsRow"
buttonsRow.Parent = root
buttonsRow.BackgroundTransparency = 1
buttonsRow.Position = UDim2.new(0, 8, 0, 148)
buttonsRow.Size = UDim2.new(1, -16, 0, 32)

local buttonsLayout = Instance.new("UIListLayout")
buttonsLayout.Parent = buttonsRow
buttonsLayout.FillDirection = Enum.FillDirection.Horizontal
buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
buttonsLayout.Padding = UDim.new(0, 4)
buttonsLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function createButton(name, label, order)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Parent = buttonsRow
	button.LayoutOrder = order
	button.BackgroundColor3 = Color3.fromRGB(57, 57, 57)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.SourceSansSemibold
	button.Size = UDim2.new(0.25, -3, 1, 0)
	button.Text = label
	button.TextColor3 = Color3.fromRGB(240, 240, 240)
	button.TextSize = 14
	return button
end

local scanSelectionButton = createButton("ScanSelectionButton", "Scan Selection", 1)
local proposeChangesButton = createButton("ProposeChangesButton", "Propose Changes", 2)
local approveButton = createButton("ApproveButton", "Approve", 3)
local rejectButton = createButton("RejectButton", "Reject", 4)

local function setButtonEnabled(button, enabled)
	button.Active = enabled
	button.Selectable = enabled
	button.AutoButtonColor = enabled

	if enabled then
		button.BackgroundColor3 = Color3.fromRGB(0, 112, 224)
		button.TextColor3 = Color3.fromRGB(245, 245, 245)
	else
		button.BackgroundColor3 = Color3.fromRGB(57, 57, 57)
		button.TextColor3 = Color3.fromRGB(140, 140, 140)
	end
end

setButtonEnabled(scanSelectionButton, true)
setButtonEnabled(proposeChangesButton, false)
setButtonEnabled(approveButton, false)
setButtonEnabled(rejectButton, false)

local outputLabel = Instance.new("TextLabel")
outputLabel.Name = "OutputLabel"
outputLabel.Parent = root
outputLabel.BackgroundTransparency = 1
outputLabel.Position = UDim2.new(0, 8, 0, 188)
outputLabel.Size = UDim2.new(1, -16, 0, 18)
outputLabel.Font = Enum.Font.SourceSansSemibold
outputLabel.Text = "Output"
outputLabel.TextColor3 = Color3.fromRGB(235, 235, 235)
outputLabel.TextSize = 16
outputLabel.TextXAlignment = Enum.TextXAlignment.Left

local outputPanel = Instance.new("ScrollingFrame")
outputPanel.Name = "OutputPanel"
outputPanel.Parent = root
outputPanel.Active = true
outputPanel.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
outputPanel.BorderSizePixel = 0
outputPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
outputPanel.Position = UDim2.new(0, 8, 0, 208)
outputPanel.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 120)
outputPanel.ScrollBarThickness = 6
outputPanel.Size = UDim2.new(1, -16, 1, -216)

local outputPadding = Instance.new("UIPadding")
outputPadding.Parent = outputPanel
outputPadding.PaddingBottom = UDim.new(0, 6)
outputPadding.PaddingLeft = UDim.new(0, 6)
outputPadding.PaddingRight = UDim.new(0, 6)
outputPadding.PaddingTop = UDim.new(0, 6)

local outputLayout = Instance.new("UIListLayout")
outputLayout.Parent = outputPanel
outputLayout.Padding = UDim.new(0, 4)
outputLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function updateCanvasSize()
	local totalHeight = outputLayout.AbsoluteContentSize.Y + outputPadding.PaddingTop.Offset + outputPadding.PaddingBottom.Offset
	outputPanel.CanvasSize = UDim2.new(0, 0, 0, totalHeight)

	local maxScroll = math.max(0, totalHeight - outputPanel.AbsoluteWindowSize.Y)
	outputPanel.CanvasPosition = Vector2.new(0, maxScroll)
end

outputLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
outputPanel:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateCanvasSize)

local function appendOutput(message)
	local line = Instance.new("TextLabel")
	line.Name = "Line"
	line.Parent = outputPanel
	line.BackgroundTransparency = 1
	line.AutomaticSize = Enum.AutomaticSize.Y
	line.Size = UDim2.new(1, 0, 0, 0)
	line.Font = Enum.Font.Code
	line.Text = tostring(message)
	line.TextColor3 = Color3.fromRGB(220, 220, 220)
	line.TextSize = 14
	line.TextWrapped = true
	line.TextXAlignment = Enum.TextXAlignment.Left
	line.TextYAlignment = Enum.TextYAlignment.Top
end

local function clearOutput()
	for _, child in ipairs(outputPanel:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
end

local function scanSelection()
	clearOutput()

	local selection = Selection:Get()
	if #selection == 0 then
		appendOutput("Select a Script or Folder in Explorer first.")
		return
	end

	appendOutput(("Selection count: %d"):format(#selection))
	appendOutput("Scanning selection...")

	local scriptInstances, capped = collectScriptInstances(selection)
	scannedFiles = {}

	if #scriptInstances == 0 then
		appendOutput("No scripts found in selection.")
		if capped then
			appendOutput("Scan capped at 200 scripts.")
		end
		return
	end

	for _, scriptInst in ipairs(scriptInstances) do
		local ok, source = pcall(function()
			return scriptInst.Source
		end)

		if ok and type(source) == "string" then
			table.insert(scannedFiles, {
				path = getInstancePath(scriptInst),
				className = scriptInst.ClassName,
				source = source,
			})
		else
			appendOutput(("Could not read source for: %s"):format(getInstancePath(scriptInst)))
		end
	end

	appendOutput(("Scripts found: %d"):format(#scannedFiles))
	if capped then
		appendOutput("Scan capped at 200 scripts.")
	end
	appendOutput("Scanned file paths:")

	for _, file in ipairs(scannedFiles) do
		appendOutput(file.path)
	end
end

scanSelectionButton.MouseButton1Click:Connect(scanSelection)

appendOutput("Ready.")
appendOutput("Select scripts or folders in Explorer, then click Scan Selection.")


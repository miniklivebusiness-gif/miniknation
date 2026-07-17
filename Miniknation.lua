-- MINIK NATION
-- Merged GUI: FPS cap, live stats, fullbright, and player ESP/chams.
-- Note: setfpscap() is not part of Roblox's standard API.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

-- BASIC PLAYER REFERENCES
-- These lowercase names are available to all custom buttons/toggles below.
local character
local humanoid
local rootPart
local head

local function refreshCharacter(newCharacter)
	character = newCharacter or LocalPlayer.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid") or nil
	rootPart = character and character:FindFirstChild("HumanoidRootPart") or nil
	head = character and character:FindFirstChild("Head") or nil
	return character, humanoid, rootPart
end

local function getCharacter()
	if not character or not character.Parent then
		refreshCharacter(LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
	end
	return character
end

local function getHumanoid()
	getCharacter()
	if not humanoid or not humanoid.Parent then
		humanoid = character:WaitForChild("Humanoid")
	end
	return humanoid
end

local function getRootPart()
	getCharacter()
	if not rootPart or not rootPart.Parent then
		rootPart = character:WaitForChild("HumanoidRootPart")
	end
	return rootPart
end

refreshCharacter(LocalPlayer.Character)
local environment = if typeof(getgenv) == "function" then getgenv() else _G

-- Remove connections and objects left behind by an earlier run.
if typeof(environment.__MINIK_NATION_CLEANUP) == "function" then
	pcall(environment.__MINIK_NATION_CLEANUP)
end

local connections = {}
local playerConnections = {}
local highlights = {}
local espLabels = {}
local espTracerLines = {}
local cleaningUp = false
local espEnabled = false
local fullbrightEnabled = false
local espTeamCheck = false
local espShowNames = false
local espShowDistance = false
local espShowHealth = false
local espTracerEnabled = false
local espMaxDistance = 5000
local espColorRed = 0
local espColorGreen = 255
local espColorBlue = 55

local function track(connection)
	table.insert(connections, connection)
	return connection
end

track(LocalPlayer.CharacterAdded:Connect(function(newCharacter)
	refreshCharacter(newCharacter)
end))

track(LocalPlayer.CharacterRemoving:Connect(function(removingCharacter)
	if character == removingCharacter then
		character = nil
		humanoid = nil
		rootPart = nil
		head = nil
	end
end))

track(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	camera = Workspace.CurrentCamera
end))

local originalLighting = {
	Brightness = Lighting.Brightness,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
}

do
	local oldGui = PlayerGui:FindFirstChild("MinikNation")
	if oldGui then oldGui:Destroy() end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MinikNation"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local notificationArea = Instance.new("Frame")
notificationArea.Name = "Notifications"
notificationArea.AnchorPoint = Vector2.new(1, 0)
notificationArea.Position = UDim2.new(1, -14, 0, 14)
notificationArea.Size = UDim2.fromOffset(270, 300)
notificationArea.BackgroundTransparency = 1
notificationArea.Parent = ScreenGui

do
	local notificationList = Instance.new("UIListLayout")
	notificationList.HorizontalAlignment = Enum.HorizontalAlignment.Right
	notificationList.VerticalAlignment = Enum.VerticalAlignment.Top
	notificationList.Padding = UDim.new(0, 8)
	notificationList.Parent = notificationArea
end

local function notify(message, duration)
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.fromOffset(260, 48)
	toast.BackgroundColor3 = Color3.fromRGB(14, 38, 18)
	toast.BackgroundTransparency = 0.08
	toast.BorderSizePixel = 0
	toast.Font = Enum.Font.GothamBold
	toast.Text = "  " .. tostring(message)
	toast.TextColor3 = Color3.fromRGB(215, 255, 220)
	toast.TextSize = 13
	toast.TextWrapped = true
	toast.TextXAlignment = Enum.TextXAlignment.Left
	toast.Parent = notificationArea

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 210, 40)
	stroke.Parent = toast

	task.delay(duration or 2.5, function()
		if toast.Parent then
			local tween = TweenService:Create(toast, TweenInfo.new(0.25), {
				BackgroundTransparency = 1,
				TextTransparency = 1,
			})
			tween:Play()
			tween.Completed:Wait()
			toast:Destroy()
		end
	end)
end

local Frame = Instance.new("Frame")
Frame.Name = "Main"
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.Position = UDim2.fromScale(0.5, 0.5)
Frame.Size = UDim2.fromOffset(420, 430)
Frame.BackgroundColor3 = Color3.fromRGB(13, 25, 15)
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Parent = ScreenGui

do
	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 12)
	frameCorner.Parent = Frame
end

local frameStroke = Instance.new("UIStroke")
frameStroke.Color = Color3.fromRGB(0, 220, 50)
frameStroke.Thickness = 2
frameStroke.Parent = Frame

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 52)
topBar.BackgroundColor3 = Color3.fromRGB(0, 141, 12)
topBar.BorderSizePixel = 0
topBar.Parent = Frame

do
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromOffset(150, 52)
	title.Position = UDim2.fromOffset(16, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "MINIK NATION"
	title.TextColor3 = Color3.fromRGB(190, 255, 185)
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = topBar
end

local searchBox = Instance.new("TextBox")
searchBox.Name = "Search"
searchBox.Position = UDim2.fromOffset(165, 10)
searchBox.Size = UDim2.fromOffset(145, 32)
searchBox.BackgroundColor3 = Color3.fromRGB(0, 105, 10)
searchBox.BorderSizePixel = 0
searchBox.ClearTextOnFocus = false
searchBox.Font = Enum.Font.Gotham
searchBox.PlaceholderText = "Search controls"
searchBox.PlaceholderColor3 = Color3.fromRGB(155, 205, 160)
searchBox.Text = ""
searchBox.TextColor3 = Color3.fromRGB(235, 255, 235)
searchBox.TextSize = 12
searchBox.Parent = topBar

do
	local searchCorner = Instance.new("UICorner")
	searchCorner.CornerRadius = UDim.new(0, 7)
	searchCorner.Parent = searchBox
end

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.fromOffset(38, 34)
minimizeButton.Position = UDim2.new(1, -84, 0, 9)
minimizeButton.BackgroundColor3 = Color3.fromRGB(0, 105, 10)
minimizeButton.BorderSizePixel = 0
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.Text = "-"
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
minimizeButton.TextSize = 20
minimizeButton.Parent = topBar

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(38, 34)
closeButton.Position = UDim2.new(1, -42, 0, 9)
closeButton.BackgroundColor3 = Color3.fromRGB(185, 45, 45)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 20
closeButton.Parent = topBar

for _, button in {minimizeButton, closeButton} do
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = button
end

local content = Instance.new("Frame")
content.Name = "MainPage"
content.Position = UDim2.fromOffset(0, 94)
content.Size = UDim2.new(1, 0, 1, -94)
content.BackgroundTransparency = 1
content.Parent = Frame

local tabBar = Instance.new("ScrollingFrame")
tabBar.Name = "TabBar"
tabBar.Position = UDim2.fromOffset(0, 52)
tabBar.Size = UDim2.new(1, 0, 0, 42)
tabBar.BackgroundColor3 = Color3.fromRGB(16, 35, 19)
tabBar.BorderSizePixel = 0
tabBar.CanvasSize = UDim2.fromOffset(0, 0)
tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
tabBar.ScrollingDirection = Enum.ScrollingDirection.X
tabBar.ScrollBarThickness = 3
tabBar.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 40)
tabBar.Parent = Frame

do
	local tabList = Instance.new("UIListLayout")
	tabList.FillDirection = Enum.FillDirection.Horizontal
	tabList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tabList.VerticalAlignment = Enum.VerticalAlignment.Center
	tabList.Padding = UDim.new(0, 8)
	tabList.SortOrder = Enum.SortOrder.LayoutOrder
	tabList.Parent = tabBar

	local tabPadding = Instance.new("UIPadding")
	tabPadding.PaddingLeft = UDim.new(0, 8)
	tabPadding.PaddingRight = UDim.new(0, 8)
	tabPadding.Parent = tabBar
end

local tabNumber = 0
local function makeTab(text)
	tabNumber += 1
	local button = Instance.new("TextButton")
	button.LayoutOrder = tabNumber
	button.Size = UDim2.fromOffset(125, 32)
	button.BackgroundColor3 = Color3.fromRGB(25, 60, 30)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(180, 220, 180)
	button.TextSize = 13
	button.Parent = tabBar

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = button
	return button
end

local mainTabButton = makeTab("MAIN")
local customTabButton = makeTab("CUSTOM")

local customPage = Instance.new("Frame")
customPage.Name = "CustomPage"
customPage.Position = UDim2.fromOffset(0, 94)
customPage.Size = UDim2.new(1, 0, 1, -94)
customPage.BackgroundTransparency = 1
customPage.Visible = false
customPage.Parent = Frame

local function makeButton(name, text, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = UDim2.fromOffset(185, 52)
	button.BackgroundColor3 = Color3.fromRGB(26, 55, 30)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(225, 255, 225)
	button.TextSize = 15
	button.AutoButtonColor = true
	button.Parent = content

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 150, 25)
	stroke.Thickness = 1
	stroke.Parent = button
	return button
end

local esp = makeButton("ESP", "ESP / CHAMS  [ OFF ]", UDim2.fromOffset(15, 18))
local Full = makeButton("Full", "FULLBRIGHT  [ OFF ]", UDim2.fromOffset(220, 18))

local fpsBox = Instance.new("TextBox")
fpsBox.Name = "FPSCap"
fpsBox.Position = UDim2.fromOffset(15, 88)
fpsBox.Size = UDim2.fromOffset(185, 48)
fpsBox.BackgroundColor3 = Color3.fromRGB(22, 43, 25)
fpsBox.BorderSizePixel = 0
fpsBox.ClearTextOnFocus = false
fpsBox.Font = Enum.Font.GothamBold
fpsBox.PlaceholderText = "FPS cap"
fpsBox.Text = "60"
fpsBox.TextColor3 = Color3.fromRGB(225, 255, 225)
fpsBox.PlaceholderColor3 = Color3.fromRGB(125, 160, 125)
fpsBox.TextSize = 16
fpsBox.Parent = content

do
	local fpsCorner = Instance.new("UICorner")
	fpsCorner.CornerRadius = UDim.new(0, 9)
	fpsCorner.Parent = fpsBox
end

local applyFPS = makeButton("ApplyFPS", "APPLY FPS CAP", UDim2.fromOffset(220, 88))
applyFPS.Size = UDim2.fromOffset(185, 48)

local statsFrame = Instance.new("Frame")
statsFrame.Position = UDim2.fromOffset(15, 154)
statsFrame.Size = UDim2.fromOffset(390, 58)
statsFrame.BackgroundColor3 = Color3.fromRGB(20, 38, 23)
statsFrame.BorderSizePixel = 0
statsFrame.Parent = content

do
	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 9)
	statsCorner.Parent = statsFrame
end

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0.5, 0, 1, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.Text = "FPS: --"
fpsLabel.TextColor3 = Color3.fromRGB(75, 255, 105)
fpsLabel.TextSize = 16
fpsLabel.Parent = statsFrame

local pingLabel = Instance.new("TextLabel")
pingLabel.Position = UDim2.fromScale(0.5, 0)
pingLabel.Size = UDim2.new(0.5, 0, 1, 0)
pingLabel.BackgroundTransparency = 1
pingLabel.Font = Enum.Font.GothamBold
pingLabel.Text = "PING: -- MS"
pingLabel.TextColor3 = Color3.fromRGB(90, 190, 255)
pingLabel.TextSize = 16
pingLabel.Parent = statsFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Position = UDim2.fromOffset(15, 224)
statusLabel.Size = UDim2.fromOffset(390, 38)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "Ready | drag the green title bar to move"
statusLabel.TextColor3 = Color3.fromRGB(145, 185, 145)
statusLabel.TextSize = 13
statusLabel.TextWrapped = true
statusLabel.Parent = content

local resetButton = makeButton("Reset", "RESET EFFECTS", UDim2.fromOffset(117, 264))

do
	local customTitle = Instance.new("TextLabel")
	customTitle.Position = UDim2.fromOffset(15, 18)
	customTitle.Size = UDim2.fromOffset(390, 20)
	customTitle.BackgroundTransparency = 1
	customTitle.Font = Enum.Font.GothamBold
	customTitle.Text = "CUSTOM CONTROLS"
	customTitle.TextColor3 = Color3.fromRGB(80, 220, 100)
	customTitle.TextSize = 12
	customTitle.TextXAlignment = Enum.TextXAlignment.Left
	customTitle.Parent = customPage
end

local customControls = Instance.new("ScrollingFrame")
customControls.Name = "CustomControls"
customControls.Position = UDim2.fromOffset(15, 48)
customControls.Size = UDim2.fromOffset(390, 270)
customControls.BackgroundTransparency = 1
customControls.BorderSizePixel = 0
customControls.CanvasSize = UDim2.fromOffset(0, 0)
customControls.AutomaticCanvasSize = Enum.AutomaticSize.Y
customControls.ScrollBarThickness = 3
customControls.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 40)
customControls.Parent = customPage

do
	local customGrid = Instance.new("UIGridLayout")
	customGrid.CellSize = UDim2.fromOffset(185, 44)
	customGrid.CellPadding = UDim2.fromOffset(15, 8)
	customGrid.SortOrder = Enum.SortOrder.LayoutOrder
	customGrid.Parent = customControls
end

local customControlNumber = 0
local tabs = {}
local activeTab = nil

local mainTabInfo = {
	Name = "MAIN",
	Button = mainTabButton,
	Page = content,
	Container = nil,
}
local customTabInfo = {
	Name = "CUSTOM",
	Button = customTabButton,
	Page = customPage,
	Container = customControls,
}
table.insert(tabs, mainTabInfo)
table.insert(tabs, customTabInfo)

local function selectTab(tabOrName)
	local selected = nil
	for _, tab in tabs do
		if tab == tabOrName or tab.Name == tabOrName then
			selected = tab
			break
		end
	end
	if not selected then
		return
	end

	activeTab = selected
	for _, tab in tabs do
		local isSelected = tab == selected
		tab.Page.Visible = isSelected
		tab.Button.BackgroundColor3 = if isSelected
			then Color3.fromRGB(0, 170, 30)
			else Color3.fromRGB(25, 60, 30)
		tab.Button.TextColor3 = if isSelected
			then Color3.fromRGB(10, 25, 12)
			else Color3.fromRGB(180, 220, 180)
	end
end

local function connectTab(tab)
	track(tab.Button.Activated:Connect(function()
		selectTab(tab)
	end))
end

connectTab(mainTabInfo)
connectTab(customTabInfo)

-- Creates a new horizontally scrollable tab with a vertically scrolling page.
local function addTab(name)
	local cleanName = tostring(name or "TAB")
	local page = Instance.new("ScrollingFrame")
	page.Name = cleanName .. "Page"
	page.Position = UDim2.fromOffset(0, 94)
	page.Size = UDim2.new(1, 0, 1, -94)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.CanvasSize = UDim2.fromOffset(0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.ScrollingDirection = Enum.ScrollingDirection.Y
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 40)
	page.Visible = false
	page.Parent = Frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 16)
	padding.PaddingLeft = UDim.new(0, 15)
	padding.PaddingRight = UDim.new(0, 15)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.Parent = page

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(185, 44)
	grid.CellPadding = UDim2.fromOffset(15, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = page

	local tab = {
		Name = cleanName,
		Button = makeTab(string.upper(cleanName)),
		Page = page,
		Container = page,
	}
	table.insert(tabs, tab)
	connectTab(tab)
	return tab
end

selectTab(mainTabInfo)

local function getControlSearchText(control)
	if control:IsA("TextButton") or control:IsA("TextBox") or control:IsA("TextLabel") then
		return string.lower(control.Text)
	end
	local label = control:FindFirstChildWhichIsA("TextLabel", true)
	return label and string.lower(label.Text) or string.lower(control.Name)
end

track(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local query = string.lower(searchBox.Text)
	local firstMatchingTab = nil
	for _, tab in tabs do
		if tab.Container then
			local tabHasMatch = false
			for _, control in tab.Container:GetChildren() do
				if control:IsA("GuiObject") and not control:IsA("UIGridLayout") then
					local matches = query == "" or string.find(getControlSearchText(control), query, 1, true) ~= nil
					control.Visible = matches
					tabHasMatch = tabHasMatch or matches
				end
			end
			tab.Button.Visible = query == "" or tabHasMatch
			if tabHasMatch and not firstMatchingTab then firstMatchingTab = tab end
		else
			tab.Button.Visible = true
		end
	end
	if query ~= "" and firstMatchingTab then
		selectTab(firstMatchingTab)
	end
end))

local function isTab(value)
	return type(value) == "table" and value.Page ~= nil and value.Button ~= nil
end

local function makeCustomControl(targetTab, text)
	customControlNumber += 1
	local button = Instance.new("TextButton")
	button.LayoutOrder = customControlNumber
	button.BackgroundColor3 = Color3.fromRGB(26, 55, 30)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(225, 255, 225)
	button.TextSize = 13
	button.Parent = targetTab.Container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 150, 25)
	stroke.Thickness = 1
	stroke.Parent = button
	return button
end

-- Use addButton(tab, "NAME", callback), or omit tab to use CUSTOM.
local function addButton(tabOrText, textOrCallback, possibleCallback)
	local targetTab = if isTab(tabOrText) then tabOrText else customTabInfo
	local text = if isTab(tabOrText) then textOrCallback else tabOrText
	local callback = if isTab(tabOrText) then possibleCallback else textOrCallback
	local button = makeCustomControl(targetTab, text)
	track(button.Activated:Connect(function()
		local success, message = pcall(callback)
		if not success then
			warn("MINIK NATION button error: " .. tostring(message))
		end
	end))
	return button
end

-- Adds an ON/OFF toggle. The callback receives true when ON and false when OFF.
-- Example: addToggle("MY TOGGLE", false, function(enabled) print(enabled) end)
local function addToggle(tabOrText, textOrStartingState, startingStateOrCallback, possibleCallback)
	local targetTab = if isTab(tabOrText) then tabOrText else customTabInfo
	local text = if isTab(tabOrText) then textOrStartingState else tabOrText
	local startingState = if isTab(tabOrText) then startingStateOrCallback else textOrStartingState
	local callback = if isTab(tabOrText) then possibleCallback else startingStateOrCallback
	local enabled = startingState == true
	local button = makeCustomControl(targetTab, "")

	local function refresh()
		button.Text = text .. (if enabled then ": ON" else ": OFF")
		button.BackgroundColor3 = if enabled
			then Color3.fromRGB(0, 185, 35)
			else Color3.fromRGB(26, 55, 30)
		button.TextColor3 = if enabled
			then Color3.fromRGB(10, 25, 12)
			else Color3.fromRGB(225, 255, 225)
	end

	refresh()
	local function setState(newState)
		enabled = newState == true
		refresh()
		local success, message = pcall(callback, enabled)
		if not success then
			warn("MINIK NATION toggle error: " .. tostring(message))
		end
	end

	track(button.Activated:Connect(function()
		setState(not enabled)
		notify(text .. (if enabled then " enabled" else " disabled"))
	end))

	return {
		Button = button,
		Get = function()
			return enabled
		end,
		Set = function(newState)
			setState(newState)
		end,
		Toggle = function()
			setState(not enabled)
			notify(text .. (if enabled then " enabled" else " disabled"))
		end,
	}
end

-- Adds a labeled text field. The callback runs when Enter is pressed or focus is lost.
-- Example: addInput(tab, "VALUE", "100", function(value) print(value) end)
local function addInput(tabOrText, textOrDefault, defaultOrCallback, possibleCallback)
	local targetTab = if isTab(tabOrText) then tabOrText else customTabInfo
	local text = if isTab(tabOrText) then textOrDefault else tabOrText
	local defaultValue = if isTab(tabOrText) then defaultOrCallback else textOrDefault
	local callback = if isTab(tabOrText) then possibleCallback else defaultOrCallback

	customControlNumber += 1
	local holder = Instance.new("Frame")
	holder.LayoutOrder = customControlNumber
	holder.BackgroundColor3 = Color3.fromRGB(26, 55, 30)
	holder.BorderSizePixel = 0
	holder.Parent = targetTab.Container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = holder

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 150, 25)
	stroke.Thickness = 1
	stroke.Parent = holder

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.56, -6, 1, 0)
	label.Position = UDim2.fromOffset(8, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = tostring(text)
	label.TextColor3 = Color3.fromRGB(225, 255, 225)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = holder

	local input = Instance.new("TextBox")
	input.Position = UDim2.new(0.56, 0, 0, 6)
	input.Size = UDim2.new(0.44, -6, 1, -12)
	input.BackgroundColor3 = Color3.fromRGB(13, 35, 17)
	input.BorderSizePixel = 0
	input.ClearTextOnFocus = false
	input.Font = Enum.Font.GothamBold
	input.Text = tostring(defaultValue or "")
	input.TextColor3 = Color3.fromRGB(100, 255, 125)
	input.TextSize = 13
	input.Parent = holder

	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 6)
	inputCorner.Parent = input

	local function submit()
		local success, message = pcall(callback, input.Text, input)
		if not success then
			warn("MINIK NATION input error: " .. tostring(message))
		end
	end

	track(input.FocusLost:Connect(submit))
	return {
		Frame = holder,
		Input = input,
		Get = function()
			return input.Text
		end,
		Set = function(value, submitValue)
			input.Text = tostring(value)
			if submitValue then
				submit()
			end
		end,
	}
end

-- Adds a click-to-cycle dropdown. It returns Get(), Set(), and Next().
local function addDropdown(targetTab, text, options, startingOption, callback)
	if not isTab(targetTab) then
		callback = startingOption
		startingOption = options
		options = text
		text = targetTab
		targetTab = customTabInfo
	end

	local selectedIndex = table.find(options, startingOption) or 1
	local button = makeCustomControl(targetTab, "")

	local function setIndex(newIndex, fireCallback)
		selectedIndex = ((newIndex - 1) % #options) + 1
		button.Text = tostring(text) .. ": " .. tostring(options[selectedIndex])
		if fireCallback then
			local success, message = pcall(callback, options[selectedIndex], selectedIndex)
			if not success then warn("MINIK NATION dropdown error: " .. tostring(message)) end
		end
	end

	setIndex(selectedIndex, false)
	track(button.Activated:Connect(function()
		setIndex(selectedIndex + 1, true)
	end))

	return {
		Button = button,
		Get = function() return options[selectedIndex] end,
		Set = function(value)
			local index = table.find(options, value)
			if index then setIndex(index, true) end
		end,
		Next = function() setIndex(selectedIndex + 1, true) end,
	}
end

-- Adds a draggable numeric slider.
local function addSlider(targetTab, text, minimum, maximum, startingValue, callback)
	if not isTab(targetTab) then
		callback = startingValue
		startingValue = maximum
		maximum = minimum
		minimum = text
		text = targetTab
		targetTab = customTabInfo
	end

	customControlNumber += 1
	local holder = Instance.new("Frame")
	holder.LayoutOrder = customControlNumber
	holder.BackgroundColor3 = Color3.fromRGB(26, 55, 30)
	holder.BorderSizePixel = 0
	holder.Parent = targetTab.Container

	local holderCorner = Instance.new("UICorner")
	holderCorner.CornerRadius = UDim.new(0, 8)
	holderCorner.Parent = holder

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -12, 0, 22)
	label.Position = UDim2.fromOffset(6, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(225, 255, 225)
	label.TextSize = 11
	label.Parent = holder

	local bar = Instance.new("TextButton")
	bar.Position = UDim2.fromOffset(8, 27)
	bar.Size = UDim2.new(1, -16, 0, 9)
	bar.BackgroundColor3 = Color3.fromRGB(10, 30, 14)
	bar.BorderSizePixel = 0
	bar.Text = ""
	bar.AutoButtonColor = false
	bar.Parent = holder

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(0, 210, 40)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local value = math.clamp(tonumber(startingValue) or minimum, minimum, maximum)
	local draggingSlider = false
	local function setValue(newValue, fireCallback)
		value = math.clamp(newValue, minimum, maximum)
		local alpha = if maximum == minimum then 0 else (value - minimum) / (maximum - minimum)
		fill.Size = UDim2.fromScale(alpha, 1)
		label.Text = tostring(text) .. ": " .. string.format("%.1f", value)
		if fireCallback then pcall(callback, value) end
	end
	local function setFromX(x)
		local alpha = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		setValue(minimum + (maximum - minimum) * alpha, true)
	end

	setValue(value, false)
	track(bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = true
			setFromX(input.Position.X)
		end
	end))
	track(UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end))
	track(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = false
		end
	end))

	return {
		Frame = holder,
		Get = function() return value end,
		Set = function(newValue) setValue(newValue, true) end,
	}
end

local keybinds = {}
local listeningKeybind = nil

-- Use addKeybind(tab, "NAME", Enum.KeyCode.K, callback), or omit tab for CUSTOM.
-- Click its GUI control, then press a new key to change the bind.
local function addKeybind(tabOrText, textOrStartingKey, startingKeyOrCallback, possibleCallback)
	local targetTab = if isTab(tabOrText) then tabOrText else customTabInfo
	local text = if isTab(tabOrText) then textOrStartingKey else tabOrText
	local startingKey = if isTab(tabOrText) then startingKeyOrCallback else textOrStartingKey
	local callback = if isTab(tabOrText) then possibleCallback else startingKeyOrCallback
	local bind = {
		Name = text,
		Key = startingKey,
		Callback = callback,
	}
	local button = makeCustomControl(targetTab, "")
	bind.Button = button

	local function refresh()
		button.Text = text .. "  [ " .. bind.Key.Name .. " ]"
	end

	refresh()
	track(button.Activated:Connect(function()
		if listeningKeybind and listeningKeybind ~= bind then
			listeningKeybind.Refresh()
		end
		listeningKeybind = bind
		button.Text = text .. "  [ PRESS A KEY ]"
		button.BackgroundColor3 = Color3.fromRGB(0, 130, 25)
	end))

	bind.Refresh = function()
		refresh()
		button.BackgroundColor3 = Color3.fromRGB(26, 55, 30)
	end
	bind.GetKey = function()
		return bind.Key
	end
	bind.SetKey = function(newKey)
		if typeof(newKey) == "EnumItem" and newKey.EnumType == Enum.KeyCode then
			bind.Key = newKey
			bind.Refresh()
		end
	end

	table.insert(keybinds, bind)
	return bind
end

track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	if listeningKeybind then
		local bind = listeningKeybind
		listeningKeybind = nil
		if input.KeyCode ~= Enum.KeyCode.Escape
			and input.KeyCode ~= Enum.KeyCode.Unknown then
			bind.Key = input.KeyCode
		end
		bind.Refresh()
		return
	end

	if gameProcessed or UserInputService:GetFocusedTextBox() then
		return
	end

	for _, bind in keybinds do
		if input.KeyCode == bind.Key then
			local success, message = pcall(bind.Callback)
			if not success then
				warn("MINIK NATION keybind error: " .. tostring(message))
			end
		end
	end
end))

-- ============================================================
-- ADD YOUR OWN TABS AND CONTROLS BELOW THIS LINE
-- Remove the two dashes (--) from an example to enable it.
-- ============================================================

-- local exampleTab = addTab("EXAMPLE")
-- addButton(exampleTab, "PRINT HELLO", function()
-- 	print("Hello from the Example tab!")
-- end)
-- addToggle(exampleTab, "MY TOGGLE", false, function(enabled)
-- 	print("My toggle is now", enabled)
-- end)

-- addButton("PRINT HELLO", function()
-- 	print("Hello from MINIK NATION!")
-- end)

-- addToggle("MY TOGGLE", false, function(enabled)
-- 	print("My toggle is now", enabled)
-- end)

-- local myToggle = addToggle("KEY TOGGLE", false, function(enabled)
-- 	print("Key toggle:", enabled)
-- end)
-- addKeybind("KEY TOGGLE BIND", Enum.KeyCode.K, function()
-- 	myToggle.Toggle()
-- end)

-- This built-in tab demonstrates assigning controls to a specific tab.
local movementTab = addTab("MOVEMENT")

-- No Clip remembers every part's original collision state so OFF can restore it.
local noClipEnabled = false
local originalCollision = setmetatable({}, {__mode = "k"})

local function restoreNoClip()
	noClipEnabled = false
	for part, wasCollidable in originalCollision do
		if part.Parent then
			part.CanCollide = wasCollidable
		end
	end
	table.clear(originalCollision)
end

local noClipToggle = addToggle(movementTab, "NO CLIP", false, function(enabled)
	noClipEnabled = enabled
	if not enabled then
		restoreNoClip()
	end
end)

addKeybind(movementTab, "NO CLIP KEY", Enum.KeyCode.N, function()
	noClipToggle.Toggle()
end)

-- Movement modifiers remember each Humanoid's original values.
local movementDefaults = setmetatable({}, {__mode = "k"})
local walkSpeedEnabled = false
local jumpBoostEnabled = false
local infiniteJumpEnabled = false
local gravityEnabled = false
local selectedWalkSpeed = 100
local selectedJumpValue = 100
local selectedGravity = 80
local originalGravity = Workspace.Gravity

local function getMovementDefaults(targetHumanoid)
	local defaults = movementDefaults[targetHumanoid]
	if not defaults then
		defaults = {
			WalkSpeed = targetHumanoid.WalkSpeed,
			UseJumpPower = targetHumanoid.UseJumpPower,
			JumpPower = targetHumanoid.JumpPower,
			JumpHeight = targetHumanoid.JumpHeight,
		}
		movementDefaults[targetHumanoid] = defaults
	end
	return defaults
end

local function applyMovementSettings(targetHumanoid)
	local defaults = getMovementDefaults(targetHumanoid)
	targetHumanoid.WalkSpeed = if walkSpeedEnabled then selectedWalkSpeed else defaults.WalkSpeed
	if defaults.UseJumpPower then
		targetHumanoid.JumpPower = if jumpBoostEnabled then selectedJumpValue else defaults.JumpPower
	else
		targetHumanoid.JumpHeight = if jumpBoostEnabled
			then math.clamp(selectedJumpValue / 5, 0, 100)
			else defaults.JumpHeight
	end
end

local function restoreMovement()
	walkSpeedEnabled = false
	jumpBoostEnabled = false
	infiniteJumpEnabled = false
	gravityEnabled = false
	Workspace.Gravity = originalGravity
	for targetHumanoid, defaults in movementDefaults do
		if targetHumanoid.Parent then
			targetHumanoid.WalkSpeed = defaults.WalkSpeed
			targetHumanoid.UseJumpPower = defaults.UseJumpPower
			targetHumanoid.JumpPower = defaults.JumpPower
			targetHumanoid.JumpHeight = defaults.JumpHeight
		end
	end
	table.clear(movementDefaults)
end

addInput(movementTab, "SPEED VALUE", tostring(selectedWalkSpeed), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(selectedWalkSpeed)
		return
	end
	selectedWalkSpeed = math.clamp(math.round(requested), 0, 500)
	input.Text = tostring(selectedWalkSpeed)
	if walkSpeedEnabled then
		applyMovementSettings(getHumanoid())
	end
end)

addInput(movementTab, "JUMP VALUE", tostring(selectedJumpValue), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(selectedJumpValue)
		return
	end
	selectedJumpValue = math.clamp(math.round(requested), 0, 500)
	input.Text = tostring(selectedJumpValue)
	if jumpBoostEnabled then
		applyMovementSettings(getHumanoid())
	end
end)

addInput(movementTab, "GRAVITY VALUE", tostring(selectedGravity), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(selectedGravity)
		return
	end
	selectedGravity = math.clamp(requested, 0, 1000)
	input.Text = string.format("%.1f", selectedGravity)
	if gravityEnabled then
		Workspace.Gravity = selectedGravity
	end
end)

local walkSpeedToggle = addToggle(movementTab, "WALK SPEED", false, function(enabled)
	walkSpeedEnabled = enabled
	applyMovementSettings(getHumanoid())
end)

local jumpBoostToggle = addToggle(movementTab, "JUMP BOOST", false, function(enabled)
	jumpBoostEnabled = enabled
	applyMovementSettings(getHumanoid())
end)

local infiniteJumpToggle = addToggle(movementTab, "INFINITE JUMP", false, function(enabled)
	infiniteJumpEnabled = enabled
end)

local gravityToggle = addToggle(movementTab, "CUSTOM GRAVITY", false, function(enabled)
	gravityEnabled = enabled
	Workspace.Gravity = if enabled then selectedGravity else originalGravity
end)

-- Custom flight: WASD to move, Space to rise, and LeftControl to descend.
local flyEnabled = false
local selectedFlySpeed = 60
local flyMode = "Camera"
local flyVelocity = nil
local flyGyro = nil
local spinState = {
	Enabled = false,
	Speed = 360,
	Pitch = 0,
	Angle = 0,
}
local spinToggle

local function removeFlyObjects()
	if flyVelocity then
		flyVelocity:Destroy()
		flyVelocity = nil
	end
	if flyGyro then
		flyGyro:Destroy()
		flyGyro = nil
	end
	local targetHumanoid = character and character:FindFirstChildOfClass("Humanoid")
	if targetHumanoid then
		targetHumanoid.AutoRotate = true
	end
end

local function ensureFlyObjects()
	local targetRoot = getRootPart()
	local targetHumanoid = getHumanoid()
	if flyVelocity and flyVelocity.Parent == targetRoot then
		return
	end

	removeFlyObjects()
	targetHumanoid.AutoRotate = false

	flyVelocity = Instance.new("BodyVelocity")
	flyVelocity.Name = "MinikNationFlyVelocity"
	flyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	flyVelocity.P = 1250
	flyVelocity.Velocity = Vector3.zero
	flyVelocity.Parent = targetRoot

	flyGyro = Instance.new("BodyGyro")
	flyGyro.Name = "MinikNationFlyGyro"
	flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	flyGyro.P = 3000
	flyGyro.CFrame = targetRoot.CFrame
	flyGyro.Parent = targetRoot
end

local function stopFlying()
	flyEnabled = false
	removeFlyObjects()
end

addInput(movementTab, "FLY SPEED", tostring(selectedFlySpeed), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(selectedFlySpeed)
		return
	end
	selectedFlySpeed = math.clamp(math.round(requested), 1, 500)
	input.Text = tostring(selectedFlySpeed)
end)

addDropdown(movementTab, "FLY MODE", {"Camera", "Character"}, "Camera", function(option)
	flyMode = option
end)

addDropdown(movementTab, "MOVE PRESET", {"Normal", "Fast", "Extreme"}, "Normal", function(option)
	if option == "Fast" then
		selectedWalkSpeed, selectedJumpValue, selectedFlySpeed = 50, 80, 90
	elseif option == "Extreme" then
		selectedWalkSpeed, selectedJumpValue, selectedFlySpeed = 180, 160, 220
	else
		selectedWalkSpeed, selectedJumpValue, selectedFlySpeed = 16, 50, 60
	end
	if walkSpeedEnabled or jumpBoostEnabled then applyMovementSettings(getHumanoid()) end
	notify("Movement preset: " .. option)
end)

local mobileFlyInput = {Forward = false, Back = false, Left = false, Right = false, Up = false, Down = false}
local mobileFlyPanel = Instance.new("Frame")
mobileFlyPanel.Name = "MobileFlyControls"
mobileFlyPanel.Position = UDim2.new(0, 18, 1, -170)
mobileFlyPanel.Size = UDim2.fromOffset(190, 145)
mobileFlyPanel.BackgroundTransparency = 1
mobileFlyPanel.Visible = false
mobileFlyPanel.Parent = ScreenGui

local function makeMobileFlyButton(text, position, directionName)
	local button = Instance.new("TextButton")
	button.Position = position
	button.Size = UDim2.fromOffset(48, 48)
	button.BackgroundColor3 = Color3.fromRGB(15, 55, 22)
	button.BackgroundTransparency = 0.2
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 16
	button.Parent = mobileFlyPanel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	track(button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			mobileFlyInput[directionName] = true
		end
	end))
	track(button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			mobileFlyInput[directionName] = false
		end
	end))
end

makeMobileFlyButton("W", UDim2.fromOffset(52, 0), "Forward")
makeMobileFlyButton("A", UDim2.fromOffset(0, 50), "Left")
makeMobileFlyButton("S", UDim2.fromOffset(52, 50), "Back")
makeMobileFlyButton("D", UDim2.fromOffset(104, 50), "Right")
makeMobileFlyButton("UP", UDim2.fromOffset(0, 100), "Up")
makeMobileFlyButton("DN", UDim2.fromOffset(104, 100), "Down")

local flyToggle = addToggle(movementTab, "FLY", false, function(enabled)
	if enabled and spinToggle and spinToggle.Get() then
		spinToggle.Set(false)
	end
	flyEnabled = enabled
	mobileFlyPanel.Visible = enabled and UserInputService.TouchEnabled
	if enabled then
		ensureFlyObjects()
	else
		removeFlyObjects()
	end
end)

addKeybind(movementTab, "FLY KEY", Enum.KeyCode.F, function()
	flyToggle.Toggle()
end)

track(RunService.RenderStepped:Connect(function()
	if not flyEnabled or not camera then
		return
	end

	ensureFlyObjects()
	local direction = Vector3.zero
	local directionCFrame = if flyMode == "Character" then getRootPart().CFrame else camera.CFrame
	local look = directionCFrame.LookVector
	local right = directionCFrame.RightVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	local flatRight = Vector3.new(right.X, 0, right.Z)

	if flatLook.Magnitude > 0 then
		flatLook = flatLook.Unit
	end
	if flatRight.Magnitude > 0 then
		flatRight = flatRight.Unit
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.W) or mobileFlyInput.Forward then direction += flatLook end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) or mobileFlyInput.Back then direction -= flatLook end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or mobileFlyInput.Right then direction += flatRight end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or mobileFlyInput.Left then direction -= flatRight end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) or mobileFlyInput.Up then direction += Vector3.yAxis end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or mobileFlyInput.Down then direction -= Vector3.yAxis end

	flyVelocity.Velocity = if direction.Magnitude > 0
		then direction.Unit * selectedFlySpeed
		else Vector3.zero
	flyGyro.CFrame = CFrame.lookAt(getRootPart().Position, getRootPart().Position + look)
end))

local function stopSpin()
	spinState.Enabled = false
	local targetCharacter = LocalPlayer.Character
	local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
	local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
	if targetHumanoid then targetHumanoid.AutoRotate = true end
	if targetRoot then
		targetRoot.AssemblyAngularVelocity = Vector3.zero
		local flatLook = Vector3.new(targetRoot.CFrame.LookVector.X, 0, targetRoot.CFrame.LookVector.Z)
		if flatLook.Magnitude < 0.01 and camera then
			flatLook = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
		end
		if flatLook.Magnitude > 0.01 then
			targetRoot.CFrame = CFrame.lookAt(targetRoot.Position, targetRoot.Position + flatLook.Unit)
		end
	end
end

addInput(movementTab, "SPIN SPEED", tostring(spinState.Speed), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(spinState.Speed)
		return
	end
	spinState.Speed = math.clamp(requested, -2000, 2000)
	input.Text = string.format("%.1f", spinState.Speed)
end)

do
local spinPitchInput = addInput(movementTab, "LOOK ANGLE", tostring(spinState.Pitch), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(spinState.Pitch)
		return
	end
	spinState.Pitch = math.clamp(requested, -90, 90)
	input.Text = string.format("%.1f", spinState.Pitch)
end)

addDropdown(movementTab, "LOOK PRESET", {"Forward", "Up", "Down"}, "Forward", function(option)
	if option == "Up" then
		spinState.Pitch = -90
	elseif option == "Down" then
		spinState.Pitch = 90
	else
		spinState.Pitch = 0
	end
	spinPitchInput.Set(spinState.Pitch, false)
end)
end

spinToggle = addToggle(movementTab, "SPIN MODE", false, function(enabled)
	if enabled and flyToggle.Get() then
		flyToggle.Set(false)
	end
	spinState.Enabled = enabled
	if enabled then
		getHumanoid().AutoRotate = false
	else
		stopSpin()
	end
end)

addKeybind(movementTab, "SPIN KEY", Enum.KeyCode.R, function()
	spinToggle.Toggle()
end)

track(RunService.RenderStepped:Connect(function(deltaTime)
	if not spinState.Enabled then return end
	local targetRoot = getRootPart()
	local targetHumanoid = getHumanoid()
	targetHumanoid.AutoRotate = false
	spinState.Angle = (spinState.Angle + math.rad(spinState.Speed) * deltaTime) % (math.pi * 2)
	targetRoot.AssemblyAngularVelocity = Vector3.zero
	targetRoot.CFrame = CFrame.new(targetRoot.Position)
		* CFrame.Angles(math.rad(spinState.Pitch), spinState.Angle, 0)
end))

addKeybind(movementTab, "SPEED KEY", Enum.KeyCode.V, function()
	walkSpeedToggle.Toggle()
end)

track(UserInputService.JumpRequest:Connect(function()
	if infiniteJumpEnabled then
		getHumanoid():ChangeState(Enum.HumanoidStateType.Jumping)
	end
end))

track(LocalPlayer.CharacterAdded:Connect(function()
	task.defer(function()
		local targetHumanoid = getHumanoid()
		if walkSpeedEnabled or jumpBoostEnabled then
			applyMovementSettings(targetHumanoid)
		end
	end)
end))

-- Camera and interface utilities demonstrate additional generated tabs.
local cameraTab = addTab("CAMERA")
local settingsTab = addTab("SETTINGS")
local guiScale = Instance.new("UIScale")
guiScale.Scale = 1
guiScale.Parent = Frame

local themes = {
	Green = Color3.fromRGB(0, 210, 40),
	Blue = Color3.fromRGB(45, 140, 255),
	Purple = Color3.fromRGB(170, 80, 255),
	Red = Color3.fromRGB(235, 65, 65),
	Orange = Color3.fromRGB(255, 145, 35),
}
local selectedTheme = "Green"

local function applyTheme(themeName)
	selectedTheme = themes[themeName] and themeName or "Green"
	local accent = themes[selectedTheme]
	topBar.BackgroundColor3 = accent
	frameStroke.Color = accent
	for _, descendant in ScreenGui:GetDescendants() do
		if descendant:IsA("ScrollingFrame") then
			descendant.ScrollBarImageColor3 = accent
		elseif descendant:IsA("UIStroke") and descendant.Parent ~= closeButton then
			descendant.Color = accent
		end
	end
	notify("Theme changed to " .. selectedTheme)
end

addDropdown(settingsTab, "THEME", {"Green", "Blue", "Purple", "Red", "Orange"}, "Green", applyTheme)
addSlider(settingsTab, "GUI SCALE", 0.7, 1.35, 1, function(value)
	guiScale.Scale = value
end)

local originalFOV = camera and camera.FieldOfView or 70
local selectedFOV = 100
local wideFOVEnabled = false
local originalMaxZoom = LocalPlayer.CameraMaxZoomDistance
local selectedMaxZoom = 500
local longZoomEnabled = false

local function applyFOV()
	if camera then
		camera.FieldOfView = if wideFOVEnabled then selectedFOV else originalFOV
	end
end

local function restoreFOV()
	wideFOVEnabled = false
	if camera then
		camera.FieldOfView = originalFOV
	end
end

local function restoreCameraZoom()
	longZoomEnabled = false
	LocalPlayer.CameraMaxZoomDistance = originalMaxZoom
end

addInput(cameraTab, "FOV VALUE", tostring(selectedFOV), function(value, input)
	local requestedFOV = tonumber(value)
	if not requestedFOV then
		input.Text = tostring(selectedFOV)
		statusLabel.Text = "Enter an FOV number from 1 to 120"
		return
	end

	selectedFOV = math.clamp(math.round(requestedFOV), 1, 120)
	input.Text = tostring(selectedFOV)
	statusLabel.Text = "Custom FOV set to " .. selectedFOV
	if wideFOVEnabled then
		applyFOV()
	end
end)

local wideFOVToggle = addToggle(cameraTab, "CUSTOM FOV", false, function(enabled)
	wideFOVEnabled = enabled
	applyFOV()
end)

addInput(cameraTab, "MAX ZOOM", tostring(selectedMaxZoom), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(selectedMaxZoom)
		return
	end
	selectedMaxZoom = math.clamp(math.round(requested), 1, 10000)
	input.Text = tostring(selectedMaxZoom)
	if longZoomEnabled then
		LocalPlayer.CameraMaxZoomDistance = selectedMaxZoom
	end
end)

local longZoomToggle = addToggle(cameraTab, "LONG ZOOM", false, function(enabled)
	longZoomEnabled = enabled
	LocalPlayer.CameraMaxZoomDistance = if enabled then selectedMaxZoom else originalMaxZoom
end)

local freecamEnabled = false
local freecamSpeed = 60
local freecamCFrame = camera and camera.CFrame or CFrame.new()
local originalCameraType = camera and camera.CameraType or Enum.CameraType.Custom
local originalCameraSubject = camera and camera.CameraSubject or nil

addInput(cameraTab, "FREECAM SPEED", tostring(freecamSpeed), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(freecamSpeed)
		return
	end
	freecamSpeed = math.clamp(math.round(requested), 1, 500)
	input.Text = tostring(freecamSpeed)
end)

local function stopFreecam()
	freecamEnabled = false
	if camera then
		camera.CameraType = originalCameraType
		camera.CameraSubject = originalCameraSubject or getHumanoid()
	end
end

local freecamToggle = addToggle(cameraTab, "FREECAM", false, function(enabled)
	freecamEnabled = enabled
	if enabled and camera then
		originalCameraType = camera.CameraType
		originalCameraSubject = camera.CameraSubject
		freecamCFrame = camera.CFrame
		camera.CameraType = Enum.CameraType.Scriptable
	else
		stopFreecam()
	end
end)

addKeybind(cameraTab, "FREECAM KEY", Enum.KeyCode.G, function()
	freecamToggle.Toggle()
end)

track(RunService.RenderStepped:Connect(function(deltaTime)
	if not freecamEnabled or not camera then return end
	local rotationSpeed = math.rad(65) * deltaTime
	if UserInputService:IsKeyDown(Enum.KeyCode.Left) then freecamCFrame *= CFrame.Angles(0, rotationSpeed, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.Right) then freecamCFrame *= CFrame.Angles(0, -rotationSpeed, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.Up) then freecamCFrame *= CFrame.Angles(rotationSpeed, 0, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.Down) then freecamCFrame *= CFrame.Angles(-rotationSpeed, 0, 0) end

	local move = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += freecamCFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= freecamCFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += freecamCFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= freecamCFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.yAxis end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.yAxis end
	if move.Magnitude > 0 then freecamCFrame += move.Unit * freecamSpeed * deltaTime end
	camera.CFrame = freecamCFrame
end))

addInput(cameraTab, "SPECTATE NAME", "", function(value, input)
	local query = string.lower(value)
	for _, targetPlayer in Players:GetPlayers() do
		if targetPlayer ~= LocalPlayer and string.sub(string.lower(targetPlayer.Name), 1, #query) == query then
			local targetHumanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
			if targetHumanoid and camera then
				stopFreecam()
				camera.CameraSubject = targetHumanoid
				notify("Spectating " .. targetPlayer.DisplayName)
				input.Text = targetPlayer.Name
			end
			return
		end
	end
	notify("Player not found")
end)

addButton(cameraTab, "STOP SPECTATE", function()
	if camera then camera.CameraSubject = getHumanoid() end
	notify("Spectate stopped")
end)

do
local positionsTab = addTab("POSITIONS")
local savedPositions = {}
for slot = 1, 3 do
	local slotIndex = slot
	addButton(positionsTab, "SAVE SLOT " .. slotIndex, function()
		savedPositions[slotIndex] = getRootPart().CFrame
		notify("Saved position slot " .. slotIndex)
	end)
	addButton(positionsTab, "GO TO SLOT " .. slotIndex, function()
		local savedCFrame = savedPositions[slotIndex]
		if savedCFrame then
			getCharacter():PivotTo(savedCFrame)
			notify("Moved to position slot " .. slotIndex)
		else
			notify("Position slot " .. slotIndex .. " is empty")
		end
	end)
end
end

addKeybind(cameraTab, "FOV KEY", Enum.KeyCode.B, function()
	wideFOVToggle.Toggle()
end)

track(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	task.defer(applyFOV)
end))

addButton(settingsTab, "CENTER GUI", function()
	Frame.Position = UDim2.fromScale(0.5, 0.5)
end)

addKeybind(settingsTab, "SHOW / HIDE GUI", Enum.KeyCode.RightShift, function()
	ScreenGui.Enabled = not ScreenGui.Enabled
end)

-- Configurable center crosshair.
local crosshairToggle
do
local extrasTab = addTab("EXTRAS")
local crosshairEnabled = false
local crosshairSize = 12
local crosshairThickness = 2
local crosshairGap = 4
local crosshairRotation = 0
local crosshairOpacity = 1
local crosshairDotEnabled = true
local crosshairOutlineEnabled = true
local crosshairStyle = "Classic"
local crosshairRed, crosshairGreen, crosshairBlue = 0, 255, 55

local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(1, 1)
crosshair.BackgroundTransparency = 1
crosshair.Visible = false
crosshair.Parent = ScreenGui

local function makeCrosshairArm(name)
	local arm = Instance.new("Frame")
	arm.Name = name
	arm.BorderSizePixel = 0
	arm.Parent = crosshair
	local stroke = Instance.new("UIStroke")
	stroke.Name = "Outline"
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 1
	stroke.Parent = arm
	return arm
end

local crosshairLeft = makeCrosshairArm("Left")
local crosshairRight = makeCrosshairArm("Right")
local crosshairTop = makeCrosshairArm("Top")
local crosshairBottom = makeCrosshairArm("Bottom")

local crosshairDot = Instance.new("Frame")
crosshairDot.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairDot.Position = UDim2.fromScale(0.5, 0.5)
crosshairDot.BorderSizePixel = 0
crosshairDot.Parent = crosshair

local crosshairDotStroke = Instance.new("UIStroke")
crosshairDotStroke.Name = "Outline"
crosshairDotStroke.Color = Color3.fromRGB(0, 0, 0)
crosshairDotStroke.Thickness = 1
crosshairDotStroke.Parent = crosshairDot

local function refreshCrosshair()
	local color = Color3.fromRGB(crosshairRed, crosshairGreen, crosshairBlue)
	local armsVisible = crosshairStyle ~= "Dot"
	crosshair.Rotation = crosshairRotation

	crosshairLeft.AnchorPoint = Vector2.new(1, 0.5)
	crosshairLeft.Position = UDim2.fromOffset(-crosshairGap, 0)
	crosshairLeft.Size = UDim2.fromOffset(crosshairSize, crosshairThickness)
	crosshairRight.AnchorPoint = Vector2.new(0, 0.5)
	crosshairRight.Position = UDim2.fromOffset(crosshairGap, 0)
	crosshairRight.Size = UDim2.fromOffset(crosshairSize, crosshairThickness)
	crosshairTop.AnchorPoint = Vector2.new(0.5, 1)
	crosshairTop.Position = UDim2.fromOffset(0, -crosshairGap)
	crosshairTop.Size = UDim2.fromOffset(crosshairThickness, crosshairSize)
	crosshairBottom.AnchorPoint = Vector2.new(0.5, 0)
	crosshairBottom.Position = UDim2.fromOffset(0, crosshairGap)
	crosshairBottom.Size = UDim2.fromOffset(crosshairThickness, crosshairSize)

	for _, arm in {crosshairLeft, crosshairRight, crosshairTop, crosshairBottom} do
		arm.Visible = armsVisible
		arm.BackgroundColor3 = color
		arm.BackgroundTransparency = 1 - crosshairOpacity
		arm.Outline.Color = Color3.fromRGB(0, 0, 0)
		arm.Outline.Transparency = if crosshairOutlineEnabled then 0 else 1
	end
	crosshairDot.Visible = crosshairDotEnabled or crosshairStyle == "Dot"
	crosshairDot.BackgroundColor3 = color
	crosshairDot.BackgroundTransparency = 1 - crosshairOpacity
	crosshairDot.Size = UDim2.fromOffset(crosshairThickness + 1, crosshairThickness + 1)
	crosshairDotStroke.Color = Color3.fromRGB(0, 0, 0)
	crosshairDotStroke.Transparency = if crosshairOutlineEnabled then 0 else 1
end
refreshCrosshair()

local crosshairSizeInput = addInput(extrasTab, "CROSSHAIR SIZE", tostring(crosshairSize), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(crosshairSize)
		return
	end
	crosshairSize = math.clamp(math.round(requested), 4, 100)
	input.Text = tostring(crosshairSize)
	refreshCrosshair()
end)

local crosshairWidthInput = addInput(extrasTab, "LINE WIDTH", tostring(crosshairThickness), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(crosshairThickness)
		return
	end
	crosshairThickness = math.clamp(math.round(requested), 1, 10)
	input.Text = tostring(crosshairThickness)
	refreshCrosshair()
end)

local crosshairGapSlider = addSlider(extrasTab, "GAP", 0, 40, crosshairGap, function(value)
	crosshairGap = math.round(value)
	refreshCrosshair()
end)

addSlider(extrasTab, "ROTATION", 0, 180, crosshairRotation, function(value)
	crosshairRotation = value
	refreshCrosshair()
end)

addSlider(extrasTab, "OPACITY", 0.1, 1, crosshairOpacity, function(value)
	crosshairOpacity = value
	refreshCrosshair()
end)

addToggle(extrasTab, "CENTER DOT", true, function(enabled)
	crosshairDotEnabled = enabled
	refreshCrosshair()
end)

addToggle(extrasTab, "BLACK OUTLINE", true, function(enabled)
	crosshairOutlineEnabled = enabled
	refreshCrosshair()
end)

addDropdown(extrasTab, "STYLE", {"Classic", "Compact", "Dot", "Large"}, "Classic", function(option)
	crosshairStyle = option
	if option == "Compact" then
		crosshairSize, crosshairThickness, crosshairGap = 8, 2, 2
		crosshairDotEnabled = false
	elseif option == "Dot" then
		crosshairSize, crosshairThickness, crosshairGap = 4, 4, 0
		crosshairDotEnabled = true
	elseif option == "Large" then
		crosshairSize, crosshairThickness, crosshairGap = 24, 3, 7
		crosshairDotEnabled = true
	else
		crosshairSize, crosshairThickness, crosshairGap = 12, 2, 4
		crosshairDotEnabled = true
	end
	crosshairSizeInput.Set(crosshairSize, false)
	crosshairWidthInput.Set(crosshairThickness, false)
	crosshairGapSlider.Set(crosshairGap)
	refreshCrosshair()
end)

addDropdown(extrasTab, "COLOR", {"Green", "White", "Red", "Blue", "Yellow", "Cyan"}, "Green", function(option)
	if option == "White" then
		crosshairRed, crosshairGreen, crosshairBlue = 255, 255, 255
	elseif option == "Red" then
		crosshairRed, crosshairGreen, crosshairBlue = 255, 55, 55
	elseif option == "Blue" then
		crosshairRed, crosshairGreen, crosshairBlue = 60, 130, 255
	elseif option == "Yellow" then
		crosshairRed, crosshairGreen, crosshairBlue = 255, 230, 45
	elseif option == "Cyan" then
		crosshairRed, crosshairGreen, crosshairBlue = 45, 235, 255
	else
		crosshairRed, crosshairGreen, crosshairBlue = 0, 255, 55
	end
	refreshCrosshair()
end)

addInput(extrasTab, "RED", tostring(crosshairRed), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(crosshairRed)
		return
	end
	crosshairRed = math.clamp(math.round(requested), 0, 255)
	input.Text = tostring(crosshairRed)
	refreshCrosshair()
end)

addInput(extrasTab, "GREEN", tostring(crosshairGreen), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(crosshairGreen)
		return
	end
	crosshairGreen = math.clamp(math.round(requested), 0, 255)
	input.Text = tostring(crosshairGreen)
	refreshCrosshair()
end)

addInput(extrasTab, "BLUE", tostring(crosshairBlue), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(crosshairBlue)
		return
	end
	crosshairBlue = math.clamp(math.round(requested), 0, 255)
	input.Text = tostring(crosshairBlue)
	refreshCrosshair()
end)

crosshairToggle = addToggle(extrasTab, "CROSSHAIR", false, function(enabled)
	crosshairEnabled = enabled
	crosshair.Visible = enabled
end)

addKeybind(extrasTab, "CROSSHAIR KEY", Enum.KeyCode.C, function()
	crosshairToggle.Toggle()
end)
end

-- ESP appearance and filtering options.
local espSettingsTab = addTab("ESP SETTINGS")
local updateESPColors

local function getESPColor()
	return Color3.fromRGB(espColorRed, espColorGreen, espColorBlue)
end

addToggle(espSettingsTab, "TEAM CHECK", false, function(enabled)
	espTeamCheck = enabled
end)

addToggle(espSettingsTab, "NAME TAGS", false, function(enabled)
	espShowNames = enabled
end)

addToggle(espSettingsTab, "SHOW DISTANCE", false, function(enabled)
	espShowDistance = enabled
end)

addToggle(espSettingsTab, "HEALTH BARS", false, function(enabled)
	espShowHealth = enabled
end)

addToggle(espSettingsTab, "TRACERS", false, function(enabled)
	espTracerEnabled = enabled
end)

addDropdown(espSettingsTab, "COLOR PRESET", {"Green", "Red", "Blue", "White"}, "Green", function(option)
	if option == "Red" then
		espColorRed, espColorGreen, espColorBlue = 255, 60, 60
	elseif option == "Blue" then
		espColorRed, espColorGreen, espColorBlue = 65, 145, 255
	elseif option == "White" then
		espColorRed, espColorGreen, espColorBlue = 255, 255, 255
	else
		espColorRed, espColorGreen, espColorBlue = 0, 255, 55
	end
	updateESPColors()
end)

addInput(espSettingsTab, "MAX DISTANCE", tostring(espMaxDistance), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(espMaxDistance)
		return
	end
	espMaxDistance = math.clamp(math.round(requested), 10, 100000)
	input.Text = tostring(espMaxDistance)
end)

updateESPColors = function()
	local newColor = getESPColor()
	for _, highlight in highlights do
		if highlight.Parent then
			highlight.FillColor = newColor
		end
	end
	for _, labelData in espLabels do
		if labelData.Text and labelData.Text.Parent then
			labelData.Text.TextColor3 = newColor
		end
	end
	for _, tracer in espTracerLines do
		if tracer.Parent then tracer.BackgroundColor3 = newColor end
	end
end

addInput(espSettingsTab, "ESP RED", tostring(espColorRed), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(espColorRed)
		return
	end
	espColorRed = math.clamp(math.round(requested), 0, 255)
	input.Text = tostring(espColorRed)
	updateESPColors()
end)

addInput(espSettingsTab, "ESP GREEN", tostring(espColorGreen), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(espColorGreen)
		return
	end
	espColorGreen = math.clamp(math.round(requested), 0, 255)
	input.Text = tostring(espColorGreen)
	updateESPColors()
end)

addInput(espSettingsTab, "ESP BLUE", tostring(espColorBlue), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(espColorBlue)
		return
	end
	espColorBlue = math.clamp(math.round(requested), 0, 255)
	input.Text = tostring(espColorBlue)
	updateESPColors()
end)

-- Aim assist: enabled by toggle, active only while holding the right mouse button.
local aimTab = addTab("AIM")
local aimbotEnabled = false
local aimTeamCheck = true
local aimVisibleCheck = true
local aimRadius = 180
local aimSmoothing = 0.18
local aimPartMode = "Head"
local aimActivationMode = "Hold RMB"
local rightMouseHeld = false

local aimCircle = Instance.new("Frame")
aimCircle.Name = "AimRadius"
aimCircle.AnchorPoint = Vector2.new(0.5, 0.5)
aimCircle.Position = UDim2.fromScale(0.5, 0.5)
aimCircle.Size = UDim2.fromOffset(aimRadius * 2, aimRadius * 2)
aimCircle.BackgroundTransparency = 1
aimCircle.BorderSizePixel = 0
aimCircle.Visible = false
aimCircle.Parent = ScreenGui

do
	local aimCircleCorner = Instance.new("UICorner")
	aimCircleCorner.CornerRadius = UDim.new(1, 0)
	aimCircleCorner.Parent = aimCircle

	local aimCircleStroke = Instance.new("UIStroke")
	aimCircleStroke.Color = Color3.fromRGB(0, 255, 55)
	aimCircleStroke.Transparency = 0.25
	aimCircleStroke.Thickness = 1
	aimCircleStroke.Parent = aimCircle
end

local aimbotToggle = addToggle(aimTab, "AIMBOT", false, function(enabled)
	aimbotEnabled = enabled
	aimCircle.Visible = enabled
end)

addToggle(aimTab, "TEAM CHECK", true, function(enabled)
	aimTeamCheck = enabled
end)

addToggle(aimTab, "VISIBLE CHECK", true, function(enabled)
	aimVisibleCheck = enabled
end)

addDropdown(aimTab, "TARGET PART", {"Head", "Torso", "Closest"}, "Head", function(option)
	aimPartMode = option
end)

addDropdown(aimTab, "ACTIVATION", {"Hold RMB", "Hold LeftAlt", "Always"}, "Hold RMB", function(option)
	aimActivationMode = option
end)

local targetInfo = makeCustomControl(aimTab, "TARGET: NONE")
targetInfo.AutoButtonColor = false

addInput(aimTab, "AIM RADIUS", tostring(aimRadius), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(aimRadius)
		return
	end
	aimRadius = math.clamp(math.round(requested), 25, 5000)
	input.Text = tostring(aimRadius)
	aimCircle.Size = UDim2.fromOffset(aimRadius * 2, aimRadius * 2)
end)

addInput(aimTab, "SMOOTHING", tostring(aimSmoothing), function(value, input)
	local requested = tonumber(value)
	if not requested then
		input.Text = tostring(aimSmoothing)
		return
	end
	aimSmoothing = math.clamp(requested, 0.01, 1)
	input.Text = string.format("%.2f", aimSmoothing)
end)

addKeybind(aimTab, "AIMBOT KEY", Enum.KeyCode.P, function()
	aimbotToggle.Toggle()
end)

track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightMouseHeld = true
	end
end))

track(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightMouseHeld = false
	end
end))

local aimRaycastParams = RaycastParams.new()
aimRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
aimRaycastParams.IgnoreWater = true

local function targetIsVisible(targetCharacter, targetPart)
	if not aimVisibleCheck or not camera then
		return true
	end

	aimRaycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
	local origin = camera.CFrame.Position
	local result = Workspace:Raycast(origin, targetPart.Position - origin, aimRaycastParams)
	return result == nil or result.Instance:IsDescendantOf(targetCharacter)
end

local function chooseAimPart(targetCharacter, viewportCenter)
	if aimPartMode == "Head" then
		return targetCharacter:FindFirstChild("Head") or targetCharacter:FindFirstChild("HumanoidRootPart")
	elseif aimPartMode == "Torso" then
		return targetCharacter:FindFirstChild("UpperTorso")
			or targetCharacter:FindFirstChild("Torso")
			or targetCharacter:FindFirstChild("HumanoidRootPart")
	end

	local bestPart = nil
	local bestDistance = math.huge
	for _, descendant in targetCharacter:GetChildren() do
		if descendant:IsA("BasePart") then
			local point, onScreen = camera:WorldToViewportPoint(descendant.Position)
			if onScreen and point.Z > 0 then
				local distance = (Vector2.new(point.X, point.Y) - viewportCenter).Magnitude
				if distance < bestDistance then
					bestDistance = distance
					bestPart = descendant
				end
			end
		end
	end
	return bestPart
end

local function findAimTarget()
	if not camera then
		return nil
	end

	local viewportCenter = camera.ViewportSize / 2
	local closestPart = nil
	local closestPlayer = nil
	local closestDistance = aimRadius

	for _, targetPlayer in Players:GetPlayers() do
		if targetPlayer ~= LocalPlayer
			and (not aimTeamCheck or LocalPlayer.Team == nil or targetPlayer.Team ~= LocalPlayer.Team) then
			local targetCharacter = targetPlayer.Character
			local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
			local targetPart = targetCharacter and chooseAimPart(targetCharacter, viewportCenter)

			if targetHumanoid and targetHumanoid.Health > 0 and targetPart then
				local screenPosition, onScreen = camera:WorldToViewportPoint(targetPart.Position)
				if onScreen and screenPosition.Z > 0 then
					local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - viewportCenter).Magnitude
					if distance < closestDistance and targetIsVisible(targetCharacter, targetPart) then
						closestDistance = distance
						closestPart = targetPart
						closestPlayer = targetPlayer
					end
				end
			end
		end
	end

	return closestPart, closestPlayer
end

track(RunService.RenderStepped:Connect(function()
	if not aimbotEnabled or not camera then
		targetInfo.Text = "TARGET: NONE"
		return
	end
	local activationHeld = aimActivationMode == "Always"
		or (aimActivationMode == "Hold RMB" and rightMouseHeld)
		or (aimActivationMode == "Hold LeftAlt" and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt))
	if not activationHeld then
		targetInfo.Text = "TARGET: WAITING"
		return
	end

	local targetPart, targetPlayer = findAimTarget()
	if targetPart then
		local targetHumanoid = targetPart.Parent:FindFirstChildOfClass("Humanoid")
		local distance = (targetPart.Position - camera.CFrame.Position).Magnitude
		targetInfo.Text = string.format(
			"TARGET: %s | %d HP | %d STUDS",
			targetPlayer and targetPlayer.DisplayName or "Unknown",
			targetHumanoid and math.round(targetHumanoid.Health) or 0,
			math.round(distance)
		)
		local desiredCFrame = CFrame.lookAt(camera.CFrame.Position, targetPart.Position)
		camera.CFrame = camera.CFrame:Lerp(desiredCFrame, aimSmoothing)
	else
		targetInfo.Text = "TARGET: NONE"
	end
end))

-- Apply continuously because Roblox may change character collision states while moving.
track(RunService.Stepped:Connect(function()
	if not noClipEnabled then
		return
	end

	local character = LocalPlayer.Character
	if not character then
		return
	end

	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") then
			if originalCollision[part] == nil then
				originalCollision[part] = part.CanCollide
			end
			part.CanCollide = false
		end
	end
end))

local function setToggleStyle(button, enabled, onText, offText)
	button.Text = if enabled then onText else offText
	button.BackgroundColor3 = if enabled
		then Color3.fromRGB(0, 185, 35)
		else Color3.fromRGB(26, 55, 30)
	button.TextColor3 = if enabled
		then Color3.fromRGB(10, 25, 12)
		else Color3.fromRGB(225, 255, 225)
end

-- Dragging (works with mouse and touch without deprecated Frame.Draggable).
local dragging = false
local dragStart
local startPosition

track(topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPosition = Frame.Position
	end
end))

track(UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		Frame.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end))

track(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end))

local function removeHighlight(character)
	local highlight = highlights[character]
	if highlight then
		highlight:Destroy()
		highlights[character] = nil
	end

	local existing = character and character:FindFirstChild("MinikNationChams")
	if existing then
		existing:Destroy()
	end

	local labelData = espLabels[character]
	if labelData then
		if labelData.Gui and labelData.Gui.Parent then
			labelData.Gui:Destroy()
		end
		espLabels[character] = nil
	end
	local tracer = espTracerLines[character]
	if tracer then
		tracer:Destroy()
		espTracerLines[character] = nil
	end
end

local function addHighlight(character)
	if not espEnabled or not character then
		return
	end

	removeHighlight(character)
	local highlight = Instance.new("Highlight")
	highlight.Name = "MinikNationChams"
	highlight.Adornee = character
	highlight.FillColor = getESPColor()
	highlight.FillTransparency = 0.45
	highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character
	highlights[character] = highlight
end

local function ensureESPLabel(character)
	local existing = espLabels[character]
	if existing and existing.Gui.Parent then
		return existing
	end

	local targetPlayer = Players:GetPlayerFromCharacter(character)
	local adornee = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	if not targetPlayer or not adornee then
		return nil
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MinikNationESPLabel"
	billboard.Adornee = adornee
	billboard.Size = UDim2.fromOffset(180, 40)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = character

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 0, 26)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextColor3 = getESPColor()
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextStrokeTransparency = 0
	textLabel.TextSize = 14
	textLabel.Parent = billboard

	local healthBack = Instance.new("Frame")
	healthBack.Position = UDim2.fromOffset(25, 30)
	healthBack.Size = UDim2.fromOffset(130, 5)
	healthBack.BackgroundColor3 = Color3.fromRGB(45, 15, 15)
	healthBack.BorderSizePixel = 0
	healthBack.Visible = false
	healthBack.Parent = billboard

	local healthFill = Instance.new("Frame")
	healthFill.Size = UDim2.fromScale(1, 1)
	healthFill.BackgroundColor3 = Color3.fromRGB(70, 255, 90)
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthBack

	local labelData = {
		Gui = billboard,
		Text = textLabel,
		Player = targetPlayer,
		HealthBack = healthBack,
		HealthFill = healthFill,
	}
	espLabels[character] = labelData
	return labelData
end

local function clearHighlights()
	for character, highlight in highlights do
		if highlight.Parent then
			highlight:Destroy()
		end
		highlights[character] = nil
	end
	for character, labelData in espLabels do
		if labelData.Gui.Parent then
			labelData.Gui:Destroy()
		end
		espLabels[character] = nil
	end
	for character, tracer in espTracerLines do
		if tracer.Parent then tracer:Destroy() end
		espTracerLines[character] = nil
	end
end

local function ensureESPTracer(character)
	local existing = espTracerLines[character]
	if existing and existing.Parent then return existing end
	local line = Instance.new("Frame")
	line.Name = "MinikNationTracer"
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.BackgroundColor3 = getESPColor()
	line.BorderSizePixel = 0
	line.Visible = false
	line.Parent = ScreenGui
	espTracerLines[character] = line
	return line
end

local espUpdateElapsed = 0
track(RunService.RenderStepped:Connect(function(deltaTime)
	espUpdateElapsed += deltaTime
	if espUpdateElapsed < 0.1 then
		return
	end
	espUpdateElapsed = 0

	local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	for targetCharacter, highlight in highlights do
		local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
		local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
		local distance = if localRoot and targetRoot
			then (targetRoot.Position - localRoot.Position).Magnitude
			else math.huge
		local sameTeam = targetPlayer and LocalPlayer.Team ~= nil and targetPlayer.Team == LocalPlayer.Team
		local allowed = distance <= espMaxDistance and (not espTeamCheck or not sameTeam)

		if highlight.Parent then
			highlight.Enabled = allowed
		end

		if espShowNames or espShowDistance or espShowHealth then
			local labelData = ensureESPLabel(targetCharacter)
			if labelData then
				labelData.Gui.Enabled = allowed
				local parts = {}
				if espShowNames then
					table.insert(parts, labelData.Player.DisplayName)
				end
				if espShowDistance and distance < math.huge then
					table.insert(parts, math.round(distance) .. " studs")
				end
				labelData.Text.Text = table.concat(parts, " | ")
				local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
				labelData.HealthBack.Visible = espShowHealth
				if targetHumanoid then
					local healthAlpha = math.clamp(targetHumanoid.Health / math.max(targetHumanoid.MaxHealth, 1), 0, 1)
					labelData.HealthFill.Size = UDim2.fromScale(healthAlpha, 1)
					labelData.HealthFill.BackgroundColor3 = Color3.fromRGB(
						math.round(255 * (1 - healthAlpha)),
						math.round(255 * healthAlpha),
						55
					)
				end
			end
		else
			local labelData = espLabels[targetCharacter]
			if labelData then
				labelData.Gui:Destroy()
				espLabels[targetCharacter] = nil
			end
		end

		if espTracerEnabled and camera and targetRoot then
			local tracer = ensureESPTracer(targetCharacter)
			local screenPosition, onScreen = camera:WorldToViewportPoint(targetRoot.Position)
			tracer.Visible = allowed and onScreen and screenPosition.Z > 0
			if tracer.Visible then
				local startPoint = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y - 8)
				local endPoint = Vector2.new(screenPosition.X, screenPosition.Y)
				local delta = endPoint - startPoint
				tracer.Position = UDim2.fromOffset((startPoint.X + endPoint.X) / 2, (startPoint.Y + endPoint.Y) / 2)
				tracer.Size = UDim2.fromOffset(delta.Magnitude, 1)
				tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
			end
		else
			local tracer = espTracerLines[targetCharacter]
			if tracer then tracer.Visible = false end
		end
	end
end))

local function watchPlayer(player)
	if player == LocalPlayer or playerConnections[player] then
		return
	end

	playerConnections[player] = player.CharacterAdded:Connect(function(character)
		if espEnabled then
			addHighlight(character)
		end
	end)

	if espEnabled and player.Character then
		addHighlight(player.Character)
	end
end

for _, player in Players:GetPlayers() do
	watchPlayer(player)
end

track(Players.PlayerAdded:Connect(watchPlayer))
track(Players.PlayerRemoving:Connect(function(player)
	if player.Character then
		removeHighlight(player.Character)
	end
	if playerConnections[player] then
		playerConnections[player]:Disconnect()
		playerConnections[player] = nil
	end
end))

local function restoreLighting()
	for property, value in originalLighting do
		Lighting[property] = value
	end
end

local function applyFullbright()
	if fullbrightEnabled then
		Lighting.Brightness = 3
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(255, 255, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
	else
		restoreLighting()
	end
	setToggleStyle(Full, fullbrightEnabled, "FULLBRIGHT  [ ON ]", "FULLBRIGHT  [ OFF ]")
end

track(esp.Activated:Connect(function()
	espEnabled = not espEnabled
	if espEnabled then
		for _, player in Players:GetPlayers() do
			if player ~= LocalPlayer and player.Character then
				addHighlight(player.Character)
			end
		end
		statusLabel.Text = "ESP enabled for other players"
	else
		clearHighlights()
		statusLabel.Text = "ESP disabled"
	end
	setToggleStyle(esp, espEnabled, "ESP / CHAMS  [ ON ]", "ESP / CHAMS  [ OFF ]")
end))

track(Full.Activated:Connect(function()
	fullbrightEnabled = not fullbrightEnabled
	applyFullbright()
	statusLabel.Text = if fullbrightEnabled then "Fullbright enabled" else "Lighting restored"
end))

local function applyFPSCap()
	local requested = tonumber(fpsBox.Text)
	if not requested then
		statusLabel.Text = "Enter a valid FPS number"
		fpsBox.Text = ""
		return
	end

	local cap = math.clamp(math.floor(requested), 1, 1000000)
	fpsBox.Text = tostring(cap)
	if typeof(setfpscap) == "function" then
		local success, message = pcall(setfpscap, cap)
		statusLabel.Text = if success
			then "FPS cap set to " .. cap
			else "Could not set FPS cap: " .. tostring(message)
	else
		statusLabel.Text = "setfpscap() is unsupported in this environment"
	end
end

track(applyFPS.Activated:Connect(applyFPSCap))
track(fpsBox.FocusLost:Connect(function(pressedEnter)
	if pressedEnter then
		applyFPSCap()
	end
end))

local performanceOriginal = {}
local performanceEnabled = false
local function restorePerformance()
	performanceEnabled = false
	for instance, enabled in performanceOriginal do
		if instance.Parent then instance.Enabled = enabled end
	end
	table.clear(performanceOriginal)
end

local performanceToggle = addToggle(settingsTab, "PERFORMANCE MODE", false, function(enabled)
	performanceEnabled = enabled
	if enabled then
		for _, instance in game:GetDescendants() do
			if instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam")
				or instance:IsA("PostEffect") then
				if performanceOriginal[instance] == nil then performanceOriginal[instance] = instance.Enabled end
				instance.Enabled = false
			end
		end
		notify("Performance mode enabled")
	else
		restorePerformance()
		notify("Performance mode disabled")
	end
end)

local CONFIG_FILE = "MinikNationConfig.json"
local function saveConfig()
	if typeof(writefile) ~= "function" then
		notify("Config saving is unsupported here")
		return
	end
	local binds = {}
	for _, bind in keybinds do binds[bind.Name] = bind.Key.Name end
	local config = {
		Theme = selectedTheme, GuiScale = guiScale.Scale,
		WalkSpeed = selectedWalkSpeed, JumpValue = selectedJumpValue,
		Gravity = selectedGravity, FlySpeed = selectedFlySpeed, FlyMode = flyMode,
		SpinSpeed = spinState.Speed, SpinPitch = spinState.Pitch,
		FOV = selectedFOV, MaxZoom = selectedMaxZoom,
		AimRadius = aimRadius, AimSmoothing = aimSmoothing,
		AimPart = aimPartMode, AimActivation = aimActivationMode,
		ESPDistance = espMaxDistance,
		ESPColor = {espColorRed, espColorGreen, espColorBlue},
		Keybinds = binds,
		Toggles = {
			NoClip = noClipToggle.Get(), WalkSpeed = walkSpeedToggle.Get(),
			JumpBoost = jumpBoostToggle.Get(), InfiniteJump = infiniteJumpToggle.Get(),
			Gravity = gravityToggle.Get(), Fly = flyToggle.Get(), Spin = spinToggle.Get(),
			CustomFOV = wideFOVToggle.Get(), LongZoom = longZoomToggle.Get(),
			Crosshair = crosshairToggle.Get(), Aimbot = aimbotToggle.Get(),
			Performance = performanceToggle.Get(), ESP = espEnabled, Fullbright = fullbrightEnabled,
		},
	}
	local success, message = pcall(writefile, CONFIG_FILE, HttpService:JSONEncode(config))
	notify(success and "Config saved" or ("Config save failed: " .. tostring(message)))
end

local function loadConfig()
	if typeof(readfile) ~= "function" or typeof(isfile) ~= "function" or not isfile(CONFIG_FILE) then
		notify("No supported config file found")
		return
	end
	local success, config = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
	if not success or type(config) ~= "table" then
		notify("Config could not be loaded")
		return
	end
	selectedWalkSpeed = tonumber(config.WalkSpeed) or selectedWalkSpeed
	selectedJumpValue = tonumber(config.JumpValue) or selectedJumpValue
	selectedGravity = tonumber(config.Gravity) or selectedGravity
	selectedFlySpeed = tonumber(config.FlySpeed) or selectedFlySpeed
	flyMode = config.FlyMode or flyMode
	spinState.Speed = tonumber(config.SpinSpeed) or spinState.Speed
	spinState.Pitch = tonumber(config.SpinPitch) or spinState.Pitch
	selectedFOV = tonumber(config.FOV) or selectedFOV
	selectedMaxZoom = tonumber(config.MaxZoom) or selectedMaxZoom
	aimRadius = tonumber(config.AimRadius) or aimRadius
	aimSmoothing = tonumber(config.AimSmoothing) or aimSmoothing
	aimPartMode = config.AimPart or aimPartMode
	aimActivationMode = config.AimActivation or aimActivationMode
	espMaxDistance = tonumber(config.ESPDistance) or espMaxDistance
	if type(config.ESPColor) == "table" then
		espColorRed = tonumber(config.ESPColor[1]) or espColorRed
		espColorGreen = tonumber(config.ESPColor[2]) or espColorGreen
		espColorBlue = tonumber(config.ESPColor[3]) or espColorBlue
		updateESPColors()
	end
	if config.Theme then applyTheme(config.Theme) end
	if tonumber(config.GuiScale) then guiScale.Scale = math.clamp(config.GuiScale, 0.7, 1.35) end
	if type(config.Keybinds) == "table" then
		for _, bind in keybinds do
			local keyName = config.Keybinds[bind.Name]
			if keyName and Enum.KeyCode[keyName] then bind.SetKey(Enum.KeyCode[keyName]) end
		end
	end
	if type(config.Toggles) == "table" then
		local saved = config.Toggles
		noClipToggle.Set(saved.NoClip == true)
		walkSpeedToggle.Set(saved.WalkSpeed == true)
		jumpBoostToggle.Set(saved.JumpBoost == true)
		infiniteJumpToggle.Set(saved.InfiniteJump == true)
		gravityToggle.Set(saved.Gravity == true)
		flyToggle.Set(saved.Fly == true)
		spinToggle.Set(saved.Spin == true)
		wideFOVToggle.Set(saved.CustomFOV == true)
		longZoomToggle.Set(saved.LongZoom == true)
		crosshairToggle.Set(saved.Crosshair == true)
		aimbotToggle.Set(saved.Aimbot == true)
		performanceToggle.Set(saved.Performance == true)
		fullbrightEnabled = saved.Fullbright == true
		applyFullbright()
		espEnabled = saved.ESP == true
		if espEnabled then
			for _, player in Players:GetPlayers() do
				if player ~= LocalPlayer and player.Character then addHighlight(player.Character) end
			end
		else
			clearHighlights()
		end
		setToggleStyle(esp, espEnabled, "ESP / CHAMS  [ ON ]", "ESP / CHAMS  [ OFF ]")
	end
	aimCircle.Size = UDim2.fromOffset(aimRadius * 2, aimRadius * 2)
	notify("Config loaded")
end

addButton(settingsTab, "SAVE CONFIG", saveConfig)
addButton(settingsTab, "LOAD CONFIG", loadConfig)

local function panicDisable()
	espEnabled = false
	fullbrightEnabled = false
	noClipToggle.Set(false)
	walkSpeedToggle.Set(false)
	jumpBoostToggle.Set(false)
	infiniteJumpToggle.Set(false)
	gravityToggle.Set(false)
	flyToggle.Set(false)
	spinToggle.Set(false)
	wideFOVToggle.Set(false)
	longZoomToggle.Set(false)
	freecamToggle.Set(false)
	crosshairToggle.Set(false)
	aimbotToggle.Set(false)
	performanceToggle.Set(false)
	clearHighlights()
	restoreLighting()
	setToggleStyle(esp, false, "ESP / CHAMS  [ ON ]", "ESP / CHAMS  [ OFF ]")
	setToggleStyle(Full, false, "FULLBRIGHT  [ ON ]", "FULLBRIGHT  [ OFF ]")
	notify("All features disabled")
end

addKeybind(settingsTab, "PANIC KEY", Enum.KeyCode.End, function()
	panicDisable()
	ScreenGui.Enabled = false
end)
addButton(settingsTab, "PANIC / DISABLE ALL", panicDisable)

track(resetButton.Activated:Connect(function()
	espEnabled = false
	fullbrightEnabled = false
	noClipToggle.Set(false)
	walkSpeedToggle.Set(false)
	jumpBoostToggle.Set(false)
	infiniteJumpToggle.Set(false)
	gravityToggle.Set(false)
	flyToggle.Set(false)
	spinToggle.Set(false)
	wideFOVToggle.Set(false)
	longZoomToggle.Set(false)
	freecamToggle.Set(false)
	crosshairToggle.Set(false)
	aimbotToggle.Set(false)
	performanceToggle.Set(false)
	clearHighlights()
	restoreLighting()
	setToggleStyle(esp, false, "ESP / CHAMS  [ ON ]", "ESP / CHAMS  [ OFF ]")
	setToggleStyle(Full, false, "FULLBRIGHT  [ ON ]", "FULLBRIGHT  [ OFF ]")
	statusLabel.Text = "All effects reset"
end))

local minimized = false
track(minimizeButton.Activated:Connect(function()
	minimized = not minimized
	tabBar.Visible = not minimized
	Frame.Size = if minimized then UDim2.fromOffset(420, 52) else UDim2.fromOffset(420, 430)
	minimizeButton.Text = if minimized then "+" else "-"
	if minimized then
		for _, tab in tabs do
			tab.Page.Visible = false
		end
	else
		selectTab(activeTab or mainTabInfo)
	end
end))

local frames = 0
local elapsed = 0
track(RunService.RenderStepped:Connect(function(deltaTime)
	frames += 1
	elapsed += deltaTime
	if elapsed < 0.5 then
		return
	end

	fpsLabel.Text = "FPS: " .. math.round(frames / elapsed)
	local success, ping = pcall(function()
		return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	if success then
		pingLabel.Text = "PING: " .. math.round(ping) .. " MS"
		pingLabel.TextColor3 = if ping < 80
			then Color3.fromRGB(75, 255, 105)
			elseif ping < 150 then Color3.fromRGB(255, 195, 65)
			else Color3.fromRGB(255, 85, 85)
	else
		pingLabel.Text = "PING: -- MS"
	end
	frames = 0
	elapsed = 0
end))

local function cleanup(guiAlreadyDestroying)
	if cleaningUp then
		return
	end
	cleaningUp = true

	for _, connection in connections do
		connection:Disconnect()
	end
	for player, connection in playerConnections do
		connection:Disconnect()
		playerConnections[player] = nil
	end
	restoreNoClip()
	stopFlying()
	stopSpin()
	restoreMovement()
	restoreFOV()
	restoreCameraZoom()
	stopFreecam()
	restorePerformance()
	clearHighlights()
	if fullbrightEnabled then
		restoreLighting()
	end
	if not guiAlreadyDestroying and ScreenGui.Parent then
		ScreenGui:Destroy()
	end
	if environment.__MINIK_NATION_CLEANUP == cleanup then
		environment.__MINIK_NATION_CLEANUP = nil
	end
end

environment.__MINIK_NATION_CLEANUP = cleanup
track(ScreenGui.Destroying:Connect(function()
	cleanup(true)
end))
track(closeButton.Activated:Connect(function()
	cleanup(false)
end))

notify("MINIK NATION loaded", 3)

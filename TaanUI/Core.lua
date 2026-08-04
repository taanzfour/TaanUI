local addonName = ...
local data = TaanUIData

local frame
local statusLabels = {}

local function Print(message)
	DEFAULT_CHAT_FRAME:AddMessage("|cff39d7ffTaanUI:|r " .. message)
end

local function SetStatus(key, text, success)
	local label = statusLabels[key]
	if label then
		label:SetText((success and "|cff35e06f" or "|cffff5555") .. text .. "|r")
	end
end

local function RunImport(key, importFunction)
	SetStatus(key, "Importing...", true)
	local ran, success, message = pcall(importFunction)
	if not ran then
		SetStatus(key, "Import failed", false)
		Print(success)
		return
	end
	SetStatus(key, message or (success and "Imported" or "Import failed"), success)
	if success then
		Print(message or "Profile imported.")
	else
		Print(message or "The profile could not be imported.")
	end
end

local function LoadRequiredAddon(name)
	if IsAddOnLoaded(name) then return true end
	local loaded, reason = LoadAddOn(name)
	if not loaded then
		return false, reason or "not available"
	end
	return true
end

local function ImportElvUI(profileData, roleName)
	local loaded, reason = LoadRequiredAddon("ElvUI")
	if not loaded then return false, "ElvUI could not be loaded: " .. reason end
	local E = ElvUI and ElvUI[1]
	local distributor = E and E:GetModule("Distributor", true)
	if not distributor then return false, "ElvUI's profile importer is unavailable." end
	local profileName = "V8 - " .. roleName
	local success
	if distributor.ImportProfileAs then
		success = distributor:ImportProfileAs(profileData, profileName, true)
	else
		success = distributor:ImportProfile(profileData)
	end
	if not success then return false, "ElvUI rejected the profile string." end
	TaanUIDB.imports.elvui = roleName
	return true, roleName .. " profile imported"
end

local function ImportElvUIFilters(filterData, filterName, importKey)
	local loaded, reason = LoadRequiredAddon("ElvUI")
	if not loaded then return false, "ElvUI could not be loaded: " .. reason end
	local E = ElvUI and ElvUI[1]
	local distributor = E and E:GetModule("Distributor", true)
	if not distributor then return false, "ElvUI's profile importer is unavailable." end
	local success = distributor:ImportProfile(filterData)
	if not success then return false, "ElvUI rejected the filter string." end
	TaanUIDB.imports[importKey] = true
	return true, filterName .. " imported"
end

local function ImportDetails()
	local loaded, reason = LoadRequiredAddon("Details")
	if not loaded then return false, "Details could not be loaded: " .. reason end
	if not _detalhes or not _detalhes.ImportProfileString then
		return false, "The Details profile importer is unavailable."
	end
	local success, errorMessage = _detalhes:ImportProfileString(data.details, "V8", true)
	if not success then return false, errorMessage or "Details rejected the profile string." end
	TaanUIDB.imports.details = true
	return true, "V8 profile imported"
end

local function ImportBigWigs(profileData, roleName)
	local loaded, reason = LoadRequiredAddon("BigWigs_Options")
	if not loaded then return false, "BigWigs Options could not be loaded: " .. reason end
	if not BigWigsAPI or not BigWigsAPI.ImportProfileString then
		return false, "The BigWigs profile importer is unavailable."
	end
	local profileName = "V8 - " .. roleName
	local success, errorMessage = BigWigsAPI.ImportProfileString(profileData, profileName, true)
	if not success then return false, errorMessage or "BigWigs rejected the profile string." end
	TaanUIDB.imports.bigwigs = roleName
	return true, roleName .. " profile imported"
end

local function ImportWeakAuras()
	local loaded, reason = LoadRequiredAddon("WeakAuras")
	if not loaded then return false, "WeakAuras could not be loaded: " .. reason end
	if not WeakAuras or not WeakAuras.Import then
		return false, "The WeakAuras importer is unavailable."
	end
	local _, errorMessage = WeakAuras.Import(data.weakAurasGeneral)
	if errorMessage then return false, errorMessage end
	TaanUIDB.imports.weakAuras = true
	return true, "Import opened in WeakAuras"
end

local function MakeButton(parent, text, width, onClick)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, 28)
	button:SetText(text)
	button:SetScript("OnClick", onClick)
	return button
end

local function AddRow(parent, y, title, key)
	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT", parent, "TOPLEFT", 34, y)
	label:SetWidth(135)
	label:SetJustifyH("LEFT")
	label:SetText(title)

	local status = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	status:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -34, y - 5)
	status:SetWidth(155)
	status:SetJustifyH("RIGHT")
	status:SetText("|cffaaaaaaNot imported|r")
	statusLabels[key] = status
	return label, status
end

local function RefreshStatuses()
	local imports = TaanUIDB.imports
	if imports.elvui then SetStatus("elvui", imports.elvui .. " imported", true) end
	if imports.details then SetStatus("details", "Imported", true) end
	if imports.bigwigs then SetStatus("bigwigs", imports.bigwigs .. " imported", true) end
	if imports.weakAuras then SetStatus("weakAuras", "Import opened", true) end
end

local function BuildWindow()
	frame = CreateFrame("Frame", "TaanUIInstallerFrame", UIParent)
	frame:SetSize(650, 420)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frame:SetBackdropColor(0.035, 0.045, 0.06, 0.98)
	frame:SetBackdropBorderColor(0.15, 0.65, 0.85, 1)

	frame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then self:StartMoving() end
	end)
	frame:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -22)
	title:SetText("|cff39d7ffV8|r Setup")

	local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	subtitle:SetPoint("TOP", title, "BOTTOM", 0, -8)
	subtitle:SetText("Install the profiles below.")

	local requirement = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	requirement:SetPoint("TOP", subtitle, "BOTTOM", 0, -12)
	requirement:SetText("|cffff3030You must have the addons from my discord!|r")
	requirement:SetJustifyH("CENTER")

	local discordUrl = "https://discord.gg/sVMDjvnCkg"
	local discordLink = CreateFrame("EditBox", nil, frame)
	discordLink:SetSize(230, 20)
	discordLink:SetPoint("TOP", requirement, "BOTTOM", 0, -1)
	discordLink:SetFontObject(GameFontNormal)
	discordLink:SetTextColor(0.55, 1, 0.15)
	discordLink:SetJustifyH("CENTER")
	discordLink:SetAutoFocus(false)
	discordLink:SetText(discordUrl)
	discordLink:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	discordLink:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	discordLink:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
	discordLink:SetScript("OnTextChanged", function(self, userInput)
		if userInput and self:GetText() ~= discordUrl then
			self:SetText(discordUrl)
			self:HighlightText()
		end
	end)
	local discordUnderline = frame:CreateTexture(nil, "OVERLAY")
	discordUnderline:SetTexture("Interface\\Buttons\\WHITE8X8")
	discordUnderline:SetVertexColor(0.55, 1, 0.15, 1)
	discordUnderline:SetSize(218, 1)
	discordUnderline:SetPoint("BOTTOM", discordLink, "BOTTOM", 0, 2)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -5, -5)

	AddRow(frame, -125, "ElvUI", "elvui")
	local elvDps = MakeButton(frame, "DPS / Tank", 115, function()
		RunImport("elvui", function() return ImportElvUI(data.elvDpsTank, "DPS / Tank") end)
	end)
	elvDps:SetPoint("TOPLEFT", 178, -115)
	local elvHealer = MakeButton(frame, "Healer", 115, function()
		RunImport("elvui", function() return ImportElvUI(data.elvHealer, "Healer") end)
	end)
	elvHealer:SetPoint("LEFT", elvDps, "RIGHT", 8, 0)
	local auraFilters = MakeButton(frame, "Aura Filters", 115, function()
		RunImport("elvui", function() return ImportElvUIFilters(data.auraFilters, "Aura Filters", "auraFilters") end)
	end)
	auraFilters:SetPoint("TOPLEFT", 178, -150)
	local nameplateFilters = MakeButton(frame, "Nameplate Style Filters", 150, function()
		RunImport("elvui", function() return ImportElvUIFilters(data.nameplateStyleFilters, "Nameplate Style Filters", "nameplateStyleFilters") end)
	end)
	nameplateFilters:SetPoint("LEFT", auraFilters, "RIGHT", 8, 0)

	AddRow(frame, -215, "Details", "details")
	local detailsButton = MakeButton(frame, "Import Profile", 238, function()
		RunImport("details", ImportDetails)
	end)
	detailsButton:SetPoint("TOPLEFT", 178, -205)

	AddRow(frame, -270, "BigWigs", "bigwigs")
	local bigWigsDps = MakeButton(frame, "DPS / Tank", 115, function()
		RunImport("bigwigs", function() return ImportBigWigs(data.bigWigsDpsTank, "DPS / Tank") end)
	end)
	bigWigsDps:SetPoint("TOPLEFT", 178, -260)
	local bigWigsHealer = MakeButton(frame, "Healer", 115, function()
		RunImport("bigwigs", function() return ImportBigWigs(data.bigWigsHealer, "Healer") end)
	end)
	bigWigsHealer:SetPoint("LEFT", bigWigsDps, "RIGHT", 8, 0)

	AddRow(frame, -325, "WeakAuras", "weakAuras")
	local weakAurasButton = MakeButton(frame, "Import General Auras", 238, function()
		RunImport("weakAuras", ImportWeakAuras)
	end)
	weakAurasButton:SetPoint("TOPLEFT", 178, -315)

	local finish = MakeButton(frame, "Finish & Reload", 180, function()
		TaanUIDB.completed = true
		StaticPopup_Show("TAANUI_RELOAD")
	end)
	finish:SetPoint("BOTTOM", 0, 30)

	local credit = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	credit:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14)
	credit:SetText("By taan")

	local version = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	version:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 14)
	version:SetText("Version " .. (GetAddOnMetadata(addonName, "Version") or "1.0.0"))

	frame:Hide()
	tinsert(UISpecialFrames, "TaanUIInstallerFrame")
end

StaticPopupDialogs.TAANUI_RELOAD = {
	text = "V8 setup is complete. Reload the interface now?",
	button1 = "Reload",
	button2 = CANCEL,
	OnAccept = ReloadUI,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

local function ShowInstaller(reset)
	TaanUIDB = TaanUIDB or {}
	TaanUIDB.imports = TaanUIDB.imports or {}
	if reset then
		TaanUIDB.completed = false
		wipe(TaanUIDB.imports)
		for _, label in pairs(statusLabels) do label:SetText("|cffaaaaaaNot imported|r") end
	end
	if not frame then BuildWindow() end
	RefreshStatuses()
	frame:Show()
	frame:Raise()
end

SLASH_TAANUI1 = "/taanui"
SlashCmdList.TAANUI = function()
	ShowInstaller(true)
end

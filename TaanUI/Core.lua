local addonName = ...
local data = TaanUIData

local resolutionProfiles = {
	["1080p"] = {
		elvDpsTank = data.elvDpsTank1080p,
		elvHealer = data.elvHealer1080p,
		bigWigsDpsTank = data.bigWigsDpsTank1080p,
		bigWigsHealer = data.bigWigsHealer1080p,
		partyCDDpsTank = data.partyCDDpsTank1080p,
		partyCDHealer = data.partyCDHealer1080p,
		details = data.details1080p,
		weakAurasGeneral = data.weakAurasGeneral1080p,
	},
	["1440p"] = {
		elvDpsTank = data.elvDpsTank1440p,
		elvHealer = data.elvHealer1440p,
		bigWigsDpsTank = data.bigWigsDpsTank1440p,
		bigWigsHealer = data.bigWigsHealer1440p,
		partyCDDpsTank = data.partyCDDpsTank1440p,
		partyCDHealer = data.partyCDHealer1440p,
		details = data.details1440p,
		weakAurasGeneral = data.weakAurasGeneral1440p,
	},
}

local selectedResolution = "1080p"

local BRAND_HOVER = {0.5373, 0.4941, 0.8941}
local DISCORD_BLUE = {0.35, 0.75, 1}
local ELV_BUTTON_BACKGROUND = {0.1, 0.1, 0.1, 1}
local ELV_BUTTON_BORDER = {0.1, 0.1, 0.1, 1}
local ELV_BACKDROP_FADE = {0.06, 0.06, 0.06, 0.8}
local FALLBACK_BUTTON_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local EXPRESSWAY_FONT = "Interface\\AddOns\\ElvUI\\media\\fonts\\Expressway.ttf"
local ELV_GLOW_TEXTURE = "Interface\\AddOns\\ElvUI\\media\\textures\\glowTex.tga"

local BUTTON_FONT = CreateFont("TaanUIExpresswayButtonFont")
BUTTON_FONT:SetFont(EXPRESSWAY_FONT, 12, "OUTLINE")
BUTTON_FONT:SetTextColor(1, 0.82, 0)

local SELECTED_BUTTON_FONT = CreateFont("TaanUIExpresswaySelectedButtonFont")
SELECTED_BUTTON_FONT:SetFont(EXPRESSWAY_FONT, 12, "OUTLINE")
SELECTED_BUTTON_FONT:SetTextColor(1, 1, 1)

local function SetExpressway(fontString, size, flags)
	fontString:SetFont(EXPRESSWAY_FONT, size, flags or "OUTLINE")
end

local function CreateSelectionGlow(target)
	local engine = ElvUI and ElvUI[1]
	local media = engine and engine.media
	local valueColor = media and media.rgbvaluecolor or BRAND_HOVER
	local glow = CreateFrame("Frame", nil, target)
	glow:SetPoint("TOPLEFT", target, "TOPLEFT", -3, 3)
	glow:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 3, -3)
	glow:SetBackdrop({ edgeFile = ELV_GLOW_TEXTURE, edgeSize = 4 })
	glow:SetBackdropBorderColor(valueColor[1], valueColor[2], valueColor[3], 0.9)
	glow:Hide()
	return glow
end

local function GetElvButtonColors()
	local engine = ElvUI and ElvUI[1]
	local media = engine and engine.media
	return media and media.backdropcolor or ELV_BUTTON_BACKGROUND,
		media and media.bordercolor or ELV_BUTTON_BORDER,
		media and media.rgbvaluecolor or BRAND_HOVER,
		media and media.normTex or FALLBACK_BUTTON_TEXTURE
end

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

local function ImportDetails(profileData, resolution)
	local loaded, reason = LoadRequiredAddon("Details")
	if not loaded then return false, "Details could not be loaded: " .. reason end
	if not _detalhes or not _detalhes.ImportProfileString then
		return false, "The Details profile importer is unavailable."
	end
	local profileName = "V8 - " .. resolution
	local success, errorMessage = _detalhes:ImportProfileString(profileData, profileName, true)
	if not success then return false, errorMessage or "Details rejected the profile string." end
	TaanUIDB.imports.details = resolution
	return true, profileName .. " profile imported"
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

local function ImportPartyCD(profileData, roleName)
	local loaded, reason = LoadRequiredAddon("PartyCD")
	if not loaded then return false, "PartyCD could not be loaded: " .. reason end
	if not PartyCDAPI or not PartyCDAPI.ImportProfile then
		return false, "The PartyCD profile importer is unavailable."
	end
	local profileName = "V8 - " .. roleName
	local existingName = PartyCDAPI.FindProfileName and PartyCDAPI:FindProfileName(profileName)
	if existingName and PartyCDAPI.DeleteProfile then
		local deleted, deleteError = PartyCDAPI:DeleteProfile(existingName)
		if not deleted then return false, deleteError or "The existing PartyCD profile could not be replaced." end
	end
	local success, errorMessage = PartyCDAPI:ImportProfile(profileData, profileName)
	if not success then return false, errorMessage or "PartyCD rejected the profile string." end
	TaanUIDB.imports.partyCD = roleName
	return true, roleName .. " profile imported"
end

local function ImportWeakAuras(profileData, resolution)
	local loaded, reason = LoadRequiredAddon("WeakAuras")
	if not loaded then return false, "WeakAuras could not be loaded: " .. reason end
	if not WeakAuras or not WeakAuras.Import then
		return false, "The WeakAuras importer is unavailable."
	end
	local _, errorMessage = WeakAuras.Import(profileData)
	if errorMessage then return false, errorMessage end
	TaanUIDB.imports.weakAuras = resolution
	return true, resolution .. " import opened in WeakAuras"
end

local function MakeButton(parent, text, width, onClick)
	local backgroundColor, borderColor, hoverBorderColor, buttonTexture = GetElvButtonColors()
	local engine = ElvUI and ElvUI[1]
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	button:SetSize(width, 28)
	button:SetNormalTexture(nil)
	button:SetPushedTexture(nil)
	button:SetHighlightTexture(nil)
	button:SetDisabledTexture(nil)
	if engine and button.SetTemplate then
		button:SetTemplate("Default", true, true)
	else
		button:SetBackdrop({
			bgFile = buttonTexture,
			edgeFile = FALLBACK_BUTTON_TEXTURE,
			edgeSize = 1,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
		button:SetBackdropColor(unpack(backgroundColor))
	end
	button:SetBackdropBorderColor(unpack(borderColor))
	button:SetNormalFontObject(BUTTON_FONT)
	button:SetHighlightFontObject(SELECTED_BUTTON_FONT)
	button:SetDisabledFontObject(BUTTON_FONT)
	button:SetText(text)
	button.defaultBorderColor = borderColor
	button.hoverBorderColor = hoverBorderColor
	button:SetScript("OnClick", onClick)
	button:SetScript("OnEnter", function(self)
		self:SetBackdropBorderColor(unpack(self.hoverBorderColor))
	end)
	button:SetScript("OnLeave", function(self)
		self:SetBackdropBorderColor(unpack(self.isSelected and self.hoverBorderColor or self.defaultBorderColor))
	end)
	return button
end

local function AddRow(parent, y, title, key)
	local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("TOPLEFT", parent, "TOPLEFT", 34, y)
	label:SetWidth(135)
	label:SetJustifyH("LEFT")
	SetExpressway(label, 12)
	label:SetTextColor(1, 1, 1)
	label:SetText(title)

	local status = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	status:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -14, y - 5)
	status:SetWidth(145)
	status:SetJustifyH("RIGHT")
	SetExpressway(status, 11)
	status:SetText("|cffaaaaaaNot imported|r")
	statusLabels[key] = status
	return label, status
end

local function RefreshStatuses()
	local imports = TaanUIDB.imports
	if imports.elvui then SetStatus("elvui", imports.elvui .. " imported", true) end
	if imports.details then
		SetStatus("details", type(imports.details) == "string" and (imports.details .. " imported") or "Imported", true)
	end
	if imports.bigwigs then SetStatus("bigwigs", imports.bigwigs .. " imported", true) end
	if imports.partyCD then SetStatus("partyCD", imports.partyCD .. " imported", true) end
	if imports.weakAuras then
		SetStatus("weakAuras", type(imports.weakAuras) == "string" and (imports.weakAuras .. " opened") or "Import opened", true)
	end
end

local function BuildWindow()
	local engine = ElvUI and ElvUI[1]
	local media = engine and engine.media
	local windowBackgroundColor = media and media.backdropfadecolor or ELV_BACKDROP_FADE
	local _, windowBorderColor = GetElvButtonColors()
	frame = CreateFrame("Frame", "TaanUIInstallerFrame", UIParent)
	frame:SetSize(650, 510)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("TOOLTIP")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	frame:SetBackdropColor(unpack(windowBackgroundColor))
	frame:SetBackdropBorderColor(0, 0, 0, 1)

	local borderTop = frame:CreateTexture(nil, "OVERLAY")
	borderTop:SetTexture("Interface\\Buttons\\WHITE8X8")
	borderTop:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
	borderTop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
	borderTop:SetHeight(1)
	borderTop:SetVertexColor(unpack(windowBorderColor))

	local borderBottom = frame:CreateTexture(nil, "OVERLAY")
	borderBottom:SetTexture("Interface\\Buttons\\WHITE8X8")
	borderBottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
	borderBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
	borderBottom:SetHeight(1)
	borderBottom:SetVertexColor(unpack(windowBorderColor))

	local borderLeft = frame:CreateTexture(nil, "OVERLAY")
	borderLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
	borderLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -1)
	borderLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 1)
	borderLeft:SetWidth(1)
	borderLeft:SetVertexColor(unpack(windowBorderColor))

	local borderRight = frame:CreateTexture(nil, "OVERLAY")
	borderRight:SetTexture("Interface\\Buttons\\WHITE8X8")
	borderRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -1)
	borderRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 1)
	borderRight:SetWidth(1)
	borderRight:SetVertexColor(unpack(windowBorderColor))

	frame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then self:StartMoving() end
	end)
	frame:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

	local title = CreateFrame("Frame", nil, frame)
	title:SetSize(300, 28)
	title:SetPoint("TOP", frame, "TOP", 0, -5)
	local titleText = title:CreateFontString(nil, "OVERLAY")
	titleText:SetPoint("CENTER", title, "CENTER", 0, 0)
	SetExpressway(titleText, 20)
	titleText:SetText("V8 Installation")
	titleText:SetTextColor(1, 1, 1)

	local requirement = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	requirement:SetPoint("TOP", title, "BOTTOM", 0, -14)
	SetExpressway(requirement, 12)
	requirement:SetText("|cffff3030You must have the addons from my discord!|r")
	requirement:SetJustifyH("CENTER")

	local discordUrl = "https://discord.gg/yMTpEyuCAB"
	local discordLink = CreateFrame("EditBox", nil, frame)
	discordLink:SetSize(230, 20)
	discordLink:SetPoint("TOP", requirement, "BOTTOM", 0, -1)
	discordLink:SetFont(EXPRESSWAY_FONT, 12, "OUTLINE")
	discordLink:SetTextColor(unpack(DISCORD_BLUE))
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
	discordUnderline:SetVertexColor(DISCORD_BLUE[1], DISCORD_BLUE[2], DISCORD_BLUE[3], 1)
	discordUnderline:SetSize(218, 1)
	discordUnderline:SetPoint("BOTTOM", discordLink, "BOTTOM", 0, 2)

	local close = CreateFrame("Button", nil, frame)
	local closeBackgroundColor, closeBorderColor, closeHoverBorderColor, closeTexture = GetElvButtonColors()
	close:SetSize(32, 32)
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)
	local closeBackdrop = CreateFrame("Frame", nil, close)
	closeBackdrop:SetFrameLevel(close:GetFrameLevel() + 1)
	closeBackdrop:SetPoint("TOPLEFT", close, "TOPLEFT", 7, -8)
	closeBackdrop:SetPoint("BOTTOMRIGHT", close, "BOTTOMRIGHT", -8, 8)
	if ElvUI and ElvUI[1] and closeBackdrop.SetTemplate then
		closeBackdrop:SetTemplate("Default", true, true)
	else
		closeBackdrop:SetBackdrop({
			bgFile = closeTexture,
			edgeFile = FALLBACK_BUTTON_TEXTURE,
			edgeSize = 1,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
		closeBackdrop:SetBackdropColor(unpack(closeBackgroundColor))
	end
	closeBackdrop:SetBackdropBorderColor(unpack(closeBorderColor))
	local closeText = closeBackdrop:CreateFontString(nil, "OVERLAY")
	closeText:SetPoint("CENTER", closeBackdrop, "CENTER", 0, 0)
	SetExpressway(closeText, 16)
	closeText:SetText("x")
	closeText:SetTextColor(1, 1, 1)
	close:SetScript("OnClick", function() frame:Hide() end)
	close:SetScript("OnEnter", function() closeBackdrop:SetBackdropBorderColor(unpack(closeHoverBorderColor)) end)
	close:SetScript("OnLeave", function() closeBackdrop:SetBackdropBorderColor(unpack(closeBorderColor)) end)

	local tab1080 = MakeButton(frame, "1080p", 110, function()
		selectedResolution = "1080p"
	end)
	tab1080:SetPoint("TOP", frame, "TOP", -59, -112)
	local tab1440 = MakeButton(frame, "1440p", 110, function()
		selectedResolution = "1440p"
	end)
	tab1440:SetPoint("LEFT", tab1080, "RIGHT", 8, 0)
	tab1080.selectionGlow = CreateSelectionGlow(tab1080)
	tab1440.selectionGlow = CreateSelectionGlow(tab1440)

	local function UpdateTabs()
		local function SetSelected(tab, selected)
			tab.isSelected = selected
			tab:SetNormalFontObject(selected and SELECTED_BUTTON_FONT or BUTTON_FONT)
			tab:SetHighlightFontObject(SELECTED_BUTTON_FONT)
			tab:SetDisabledFontObject(selected and SELECTED_BUTTON_FONT or BUTTON_FONT)
			tab:SetBackdropBorderColor(unpack(selected and tab.hoverBorderColor or tab.defaultBorderColor))
			if selected then tab.selectionGlow:Show() else tab.selectionGlow:Hide() end
			tab:SetEnabled(not selected)
		end
		SetSelected(tab1080, selectedResolution == "1080p")
		SetSelected(tab1440, selectedResolution == "1440p")
	end
	tab1080:SetScript("OnClick", function()
		selectedResolution = "1080p"
		UpdateTabs()
	end)
	tab1440:SetScript("OnClick", function()
		selectedResolution = "1440p"
		UpdateTabs()
	end)
	UpdateTabs()

	AddRow(frame, -165, "ElvUI", "elvui")
	local elvDps = MakeButton(frame, "Tank, Dps", 146, function()
		local roleName = "Tank, Dps " .. selectedResolution
		RunImport("elvui", function() return ImportElvUI(resolutionProfiles[selectedResolution].elvDpsTank, roleName) end)
	end)
	elvDps:SetPoint("TOPLEFT", 175, -155)
	local elvHealer = MakeButton(frame, "Healer", 146, function()
		local roleName = "Healer " .. selectedResolution
		RunImport("elvui", function() return ImportElvUI(resolutionProfiles[selectedResolution].elvHealer, roleName) end)
	end)
	elvHealer:SetPoint("LEFT", elvDps, "RIGHT", 8, 0)
	local auraFilters = MakeButton(frame, "Aura Filters", 146, function()
		RunImport("elvui", function() return ImportElvUIFilters(data.auraFiltersGeneral, "Aura Filters", "auraFilters") end)
	end)
	auraFilters:SetPoint("TOPLEFT", 175, -190)
	local nameplateFilters = MakeButton(frame, "Nameplate Style Filters", 146, function()
		RunImport("elvui", function() return ImportElvUIFilters(data.nameplateStyleFiltersGeneral, "Nameplate Style Filters", "nameplateStyleFilters") end)
	end)
	nameplateFilters:SetPoint("LEFT", auraFilters, "RIGHT", 8, 0)

	AddRow(frame, -255, "Details", "details")
	local detailsButton = MakeButton(frame, "Import Details", 300, function()
		RunImport("details", function() return ImportDetails(resolutionProfiles[selectedResolution].details, selectedResolution) end)
	end)
	detailsButton:SetPoint("TOPLEFT", 175, -245)

	AddRow(frame, -310, "BigWigs", "bigwigs")
	local bigWigsDps = MakeButton(frame, "Tank, Dps", 146, function()
		local roleName = "Tank, Dps " .. selectedResolution
		RunImport("bigwigs", function() return ImportBigWigs(resolutionProfiles[selectedResolution].bigWigsDpsTank, roleName) end)
	end)
	bigWigsDps:SetPoint("TOPLEFT", 175, -300)
	local bigWigsHealer = MakeButton(frame, "Healer", 146, function()
		local roleName = "Healer " .. selectedResolution
		RunImport("bigwigs", function() return ImportBigWigs(resolutionProfiles[selectedResolution].bigWigsHealer, roleName) end)
	end)
	bigWigsHealer:SetPoint("LEFT", bigWigsDps, "RIGHT", 8, 0)

	AddRow(frame, -365, "PartyCD", "partyCD")
	local partyCDDps = MakeButton(frame, "Tank, Dps", 146, function()
		local roleName = "Tank, Dps " .. selectedResolution
		RunImport("partyCD", function() return ImportPartyCD(resolutionProfiles[selectedResolution].partyCDDpsTank, roleName) end)
	end)
	partyCDDps:SetPoint("TOPLEFT", 175, -355)
	local partyCDHealer = MakeButton(frame, "Healer", 146, function()
		local roleName = "Healer " .. selectedResolution
		RunImport("partyCD", function() return ImportPartyCD(resolutionProfiles[selectedResolution].partyCDHealer, roleName) end)
	end)
	partyCDHealer:SetPoint("LEFT", partyCDDps, "RIGHT", 8, 0)

	AddRow(frame, -420, "WeakAuras", "weakAuras")
	local weakAurasButton = MakeButton(frame, "Import General Auras", 300, function()
		RunImport("weakAuras", function()
			return ImportWeakAuras(resolutionProfiles[selectedResolution].weakAurasGeneral, selectedResolution)
		end)
	end)
	weakAurasButton:SetPoint("TOPLEFT", 175, -410)

	local finish = MakeButton(frame, "Finish & Reload", 180, function()
		TaanUIDB.completed = true
		StaticPopup_Show("TAANUI_RELOAD")
	end)
	finish:SetPoint("BOTTOM", 0, 30)

	local credit = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	credit:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14)
	SetExpressway(credit, 11)
	credit:SetText("By taan")

	local version = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	version:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 14)
	SetExpressway(version, 11)
	version:SetText("Version " .. (GetAddOnMetadata(addonName, "Version") or "3.0.1"))

	frame:Hide()
	tinsert(UISpecialFrames, "TaanUIInstallerFrame")
end

StaticPopupDialogs.TAANUI_RELOAD = {
	text = "V8 installation is complete. Reload the interface now?",
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
SLASH_TAANUI2 = "/v8"
SLASH_TAANUI3 = "/tui"
SlashCmdList.TAANUI = function()
	ShowInstaller(true)
end

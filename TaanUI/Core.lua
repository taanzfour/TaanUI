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

local BUTTON_FONT = CreateFont("TaanUIExpresswayButtonFont")
BUTTON_FONT:SetFont(EXPRESSWAY_FONT, 12, "OUTLINE")
BUTTON_FONT:SetTextColor(1, 0.82, 0)

local SELECTED_BUTTON_FONT = CreateFont("TaanUIExpresswaySelectedButtonFont")
SELECTED_BUTTON_FONT:SetFont(EXPRESSWAY_FONT, 12, "OUTLINE")
SELECTED_BUTTON_FONT:SetTextColor(1, 1, 1)

local function SetExpressway(fontString, size, flags)
	fontString:SetFont(EXPRESSWAY_FONT, size, flags or "OUTLINE")
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

local function DisableElvUIInstaller()
	local engine = ElvUI and ElvUI[1]
	if not engine then return end
	if engine.private then
		engine.private.install_complete = engine.version or true
	end
	if ElvUIInstallFrame then
		ElvUIInstallFrame:Hide()
	end

	engine.Install = function(self)
		if self.private then
			self.private.install_complete = self.version or true
		end
		if ElvUIInstallFrame then
			ElvUIInstallFrame:Hide()
		end
	end
end

DisableElvUIInstaller()

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

local function ApplyElvUIHealthColors(useClassColors)
	local loaded, reason = LoadRequiredAddon("ElvUI")
	if not loaded then return false, "ElvUI could not be loaded: " .. reason end
	local E = ElvUI and ElvUI[1]
	local colors = E and E.db and E.db.unitframe and E.db.unitframe.colors
	if not colors then return false, "ElvUI's unitframe color settings are unavailable." end

	colors.healthclass = useClassColors
	colors.transparentHealth = not useClassColors
	local unitFrames = E:GetModule("UnitFrames", true)
	if unitFrames and unitFrames.Update_AllFrames then unitFrames:Update_AllFrames() end

	local presetName = useClassColors and "Class Colors" or "Dark"
	TaanUIDB.imports.elvuiColors = presetName
	return true, presetName .. " applied"
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

local function ImportWeakAuras(profileData, resolution, callback)
	local loaded, reason = LoadRequiredAddon("WeakAuras")
	if not loaded then return false, "WeakAuras could not be loaded: " .. reason end
	if not WeakAuras or not WeakAuras.Import then
		return false, "The WeakAuras importer is unavailable."
	end
	local _, errorMessage = WeakAuras.Import(profileData, nil, callback)
	if errorMessage then return false, errorMessage end
	TaanUIDB.imports.weakAuras = resolution
	return true, resolution .. " import opened in WeakAuras"
end

local function EnableDetailsAllCharacters(resolution)
	local loaded, reason = LoadRequiredAddon("Details")
	if not loaded then return false, "Details could not be loaded: " .. reason end
	if not _detalhes then return false, "Details' profile settings are unavailable." end

	local profileName = "V8 - " .. resolution
	_detalhes.always_use_profile = true
	_detalhes.always_use_profile_name = profileName
	_detalhes.always_use_profile_exception = _detalhes.always_use_profile_exception or {}
	_detalhes.always_use_profile_exception[UnitName("player")] = nil
	if _detalhes.GetProfile and _detalhes:GetProfile(profileName, false) and _detalhes.ApplyProfile then
		_detalhes:ApplyProfile(profileName)
	end
	return true, "Details will use " .. profileName .. " on all characters"
end

local function ApplyAddonSettings(resolution)
	local loaded, reason = LoadRequiredAddon("ElvUI")
	if not loaded then return false, "ElvUI could not be loaded: " .. reason end

	local E = ElvUI and ElvUI[1]
	if not E or not E.global or not E.db or not E.private then
		return false, "ElvUI's settings database is unavailable."
	end
	local scale = resolution == "1440p" and 0.53 or 0.64
	E.global.general.autoScale = true
	E.global.general.minUiScale = scale

	E.private.general.normTex = "Atrocity"
	E.private.general.glossTex = "Atrocity"
	E.db.unitframe.statusbar = "Atrocity"
	E.db.general.font = "Expressway"
	E.private.general.dmgfont = "Expressway"
	E.private.general.namefont = "Expressway"
	E.db.general.totems.enable = false
	E.private.general.chatBubbles = "disabled"

	if E.UpdateMedia then E:UpdateMedia() end
	if E.UpdateFontTemplates then E:UpdateFontTemplates() end
	if E.UpdateStatusBars then E:UpdateStatusBars() end
	if E.UpdateFrameTemplates then E:UpdateFrameTemplates() end
	local totems = E:GetModule("Totems", true)
	if totems and totems.ToggleEnable then totems:ToggleEnable() end

	local errors = {}
	loaded, reason = LoadRequiredAddon("AddOnSkins")
	local AS = loaded and AddOnSkins and AddOnSkins[1]
	if AS and AS.SetOption then
		AS:SetOption("WeakAuras", false)
	else
		tinsert(errors, loaded and "AddOnSkins' settings database is unavailable." or ("AddOnSkins could not be loaded: " .. reason))
	end
	local detailsSuccess, detailsMessage = EnableDetailsAllCharacters(resolution)
	if not detailsSuccess then tinsert(errors, detailsMessage) end

	TaanUIDB.imports.addonSettings = resolution
	if #errors > 0 then return false, table.concat(errors, "; ") end
	return true, resolution .. " UI settings applied"
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

local function RefreshStatuses()
	local imports = TaanUIDB.imports
	if imports.elvui then SetStatus("elvui", imports.elvui .. " imported", true) end
	if imports.elvuiColors then SetStatus("elvui", imports.elvuiColors .. " applied", true) end
	if imports.details then
		SetStatus("details", type(imports.details) == "string" and (imports.details .. " imported") or "Imported", true)
	end
	if imports.bigwigs then SetStatus("bigwigs", imports.bigwigs .. " imported", true) end
	if imports.partyCD then SetStatus("partyCD", imports.partyCD .. " imported", true) end
	if imports.addonSettings then
		SetStatus("addonSettings", type(imports.addonSettings) == "string" and (imports.addonSettings .. " settings applied") or "Addon settings applied", true)
	end
	if imports.weakAuras then
		SetStatus("weakAuras", type(imports.weakAuras) == "string" and (imports.weakAuras .. " opened") or "Import opened", true)
	end
end

local function BuildWindow()
	local engine = ElvUI and ElvUI[1]
	local media = engine and engine.media
	local windowBackgroundColor = media and media.backdropfadecolor or ELV_BACKDROP_FADE
	local _, windowBorderColor, valueColor, normalTexture = GetElvButtonColors()
	local pageOrder = { "elvui", "details", "bigwigs", "partyCD", "weakAuras", "addonSettings" }
	local pages = {}
	local currentPage = 1

	frame = CreateFrame("Frame", "TaanUIInstallerFrame", UIParent)
	frame:SetSize(560, 400)
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

	local function AddBorder(point1, point2, width, height)
		local border = frame:CreateTexture(nil, "OVERLAY")
		border:SetTexture("Interface\\Buttons\\WHITE8X8")
		border:SetPoint(unpack(point1))
		border:SetPoint(unpack(point2))
		if width then border:SetWidth(width) end
		if height then border:SetHeight(height) end
		border:SetVertexColor(unpack(windowBorderColor))
	end

	AddBorder({ "TOPLEFT", frame, "TOPLEFT", 0, 0 }, { "TOPRIGHT", frame, "TOPRIGHT", 0, 0 }, nil, 1)
	AddBorder({ "BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0 }, { "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0 }, nil, 1)
	AddBorder({ "TOPLEFT", frame, "TOPLEFT", 0, -1 }, { "BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 1 }, 1)
	AddBorder({ "TOPRIGHT", frame, "TOPRIGHT", 0, -1 }, { "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 1 }, 1)

	frame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then self:StartMoving() end
	end)
	frame:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)

	local titleText = frame:CreateFontString(nil, "OVERLAY")
	titleText:SetPoint("TOP", frame, "TOP", 0, -14)
	SetExpressway(titleText, 20)
	titleText:SetTextColor(1, 1, 1)

	local close = CreateFrame("Button", nil, frame)
	local closeBackgroundColor, closeBorderColor, closeHoverBorderColor, closeTexture = GetElvButtonColors()
	close:SetSize(32, 32)
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)
	local closeBackdrop = CreateFrame("Frame", nil, close)
	closeBackdrop:SetFrameLevel(close:GetFrameLevel() + 1)
	closeBackdrop:SetPoint("TOPLEFT", close, "TOPLEFT", 7, -8)
	closeBackdrop:SetPoint("BOTTOMRIGHT", close, "BOTTOMRIGHT", -8, 8)
	if engine and closeBackdrop.SetTemplate then
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
	closeText:SetPoint("CENTER")
	SetExpressway(closeText, 16)
	closeText:SetText("x")
	closeText:SetTextColor(1, 1, 1)
	close:SetScript("OnClick", function() frame:Hide() end)
	close:SetScript("OnEnter", function() closeBackdrop:SetBackdropBorderColor(unpack(closeHoverBorderColor)) end)
	close:SetScript("OnLeave", function() closeBackdrop:SetBackdropBorderColor(unpack(closeBorderColor)) end)

	local welcome = CreateFrame("Frame", nil, frame)
	welcome:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -45)
	welcome:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

	local requirement = welcome:CreateFontString(nil, "OVERLAY")
	requirement:SetPoint("TOP", welcome, "TOP", 0, -25)
	SetExpressway(requirement, 12)
	requirement:SetText("|cffff3030You must have the addons from my discord!|r")

	local discordUrl = "https://discord.gg/yMTpEyuCAB"
	local discordLink = CreateFrame("EditBox", nil, welcome)
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

	local discordUnderline = welcome:CreateTexture(nil, "OVERLAY")
	discordUnderline:SetTexture("Interface\\Buttons\\WHITE8X8")
	discordUnderline:SetVertexColor(DISCORD_BLUE[1], DISCORD_BLUE[2], DISCORD_BLUE[3], 1)
	discordUnderline:SetSize(218, 1)
	discordUnderline:SetPoint("BOTTOM", discordLink, "BOTTOM", 0, 2)

	local resolutionPrompt = welcome:CreateFontString(nil, "OVERLAY")
	resolutionPrompt:SetPoint("TOP", discordLink, "BOTTOM", 0, -50)
	SetExpressway(resolutionPrompt, 15)
	resolutionPrompt:SetTextColor(1, 1, 1)
	resolutionPrompt:SetText("Select a resolution to install:")

	local wizard = CreateFrame("Frame", nil, frame)
	wizard:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -45)
	wizard:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

	local progress = CreateFrame("StatusBar", nil, wizard)
	progress:SetSize(250, 20)
	progress:SetPoint("BOTTOM", wizard, "BOTTOM", 0, 34)
	progress:SetMinMaxValues(0, #pageOrder)
	progress:SetStatusBarTexture(normalTexture or FALLBACK_BUTTON_TEXTURE)
	progress:SetStatusBarColor(valueColor[1], valueColor[2], valueColor[3], 1)
	progress:SetBackdrop({
		bgFile = normalTexture or FALLBACK_BUTTON_TEXTURE,
		edgeFile = FALLBACK_BUTTON_TEXTURE,
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	progress:SetBackdropColor(0.06, 0.06, 0.06, 0.9)
	progress:SetBackdropBorderColor(unpack(windowBorderColor))
	local progressText = progress:CreateFontString(nil, "OVERLAY")
	progressText:SetPoint("CENTER")
	SetExpressway(progressText, 11)
	progressText:SetTextColor(1, 1, 1)

	local previousButton
	local continueButton
	local ShowPage
	local ShowWelcome

	local function CreatePage(key, pageTitle)
		local page = CreateFrame("Frame", nil, wizard)
		page:SetPoint("TOPLEFT", wizard, "TOPLEFT", 24, -25)
		page:SetPoint("BOTTOMRIGHT", wizard, "BOTTOMRIGHT", -24, 75)
		page:Hide()

		local heading = page:CreateFontString(nil, "OVERLAY")
		heading:SetPoint("TOP", page, "TOP", 0, -25)
		SetExpressway(heading, 22)
		heading:SetTextColor(1, 1, 1)
		heading:SetText(pageTitle)

		local status = page:CreateFontString(nil, "OVERLAY")
		SetExpressway(status, 11)
		status:SetText("|cffaaaaaa...|r")
		statusLabels[key] = status
		page.status = status

		pages[key] = page
		return page
	end

	local function PlaceStatusBelow(page, button, offset, xOffset)
		page.status:ClearAllPoints()
		page.status:SetPoint("TOP", button, "BOTTOM", xOffset or 0, offset or -12)
	end

	local elvPage = CreatePage("elvui", "ElvUI")
	local elvDps = MakeButton(elvPage, "Tank, Dps", 146, function()
		local roleName = "Tank, Dps " .. selectedResolution
		RunImport("elvui", function()
			return ImportElvUI(resolutionProfiles[selectedResolution].elvDpsTank, roleName)
		end)
	end)
	elvDps:SetPoint("RIGHT", elvPage, "CENTER", -4, 30)
	local elvHealer = MakeButton(elvPage, "Healer", 146, function()
		local roleName = "Healer " .. selectedResolution
		RunImport("elvui", function()
			return ImportElvUI(resolutionProfiles[selectedResolution].elvHealer, roleName)
		end)
	end)
	elvHealer:SetPoint("LEFT", elvPage, "CENTER", 4, 30)
	local auraFilters = MakeButton(elvPage, "Aura Filters", 146, function()
		RunImport("elvui", function()
			return ImportElvUIFilters(data.auraFiltersGeneral, "Aura Filters", "auraFilters")
		end)
	end)
	auraFilters:SetPoint("TOPRIGHT", elvPage, "CENTER", -4, -8)
	local nameplateFilters = MakeButton(elvPage, "Nameplate Style Filters", 146, function()
		RunImport("elvui", function()
			return ImportElvUIFilters(data.nameplateStyleFiltersGeneral, "Nameplate Style Filters", "nameplateStyleFilters")
		end)
	end)
	nameplateFilters:SetPoint("TOPLEFT", elvPage, "CENTER", 4, -8)
	PlaceStatusBelow(elvPage, auraFilters, -12, 77)
	local classColors = MakeButton(elvPage, "Class Colors", 146, function()
		RunImport("elvui", function()
			return ApplyElvUIHealthColors(true)
		end)
	end)
	classColors:SetPoint("TOPRIGHT", elvPage, "CENTER", -4, -79)
	local darkColors = MakeButton(elvPage, "Dark", 146, function()
		RunImport("elvui", function()
			return ApplyElvUIHealthColors(false)
		end)
	end)
	darkColors:SetPoint("TOPLEFT", elvPage, "CENTER", 4, -79)

	local detailsPage = CreatePage("details", "Details")
	local detailsButton = MakeButton(detailsPage, "Details", 300, function()
		RunImport("details", function()
			return ImportDetails(resolutionProfiles[selectedResolution].details, selectedResolution)
		end)
	end)
	detailsButton:SetPoint("CENTER", detailsPage, "CENTER", 0, 5)
	PlaceStatusBelow(detailsPage, detailsButton)

	local bigWigsPage = CreatePage("bigwigs", "BigWigs")
	local bigWigsDps = MakeButton(bigWigsPage, "Tank, Dps", 146, function()
		local roleName = "Tank, Dps " .. selectedResolution
		RunImport("bigwigs", function()
			return ImportBigWigs(resolutionProfiles[selectedResolution].bigWigsDpsTank, roleName)
		end)
	end)
	bigWigsDps:SetPoint("CENTER", bigWigsPage, "CENTER", -77, 5)
	local bigWigsHealer = MakeButton(bigWigsPage, "Healer", 146, function()
		local roleName = "Healer " .. selectedResolution
		RunImport("bigwigs", function()
			return ImportBigWigs(resolutionProfiles[selectedResolution].bigWigsHealer, roleName)
		end)
	end)
	bigWigsHealer:SetPoint("LEFT", bigWigsDps, "RIGHT", 8, 0)
	PlaceStatusBelow(bigWigsPage, bigWigsDps, -12, 77)

	local partyCDPage = CreatePage("partyCD", "PartyCD")
	local partyCDDps = MakeButton(partyCDPage, "Tank, Dps", 146, function()
		local roleName = "Tank, Dps " .. selectedResolution
		RunImport("partyCD", function()
			return ImportPartyCD(resolutionProfiles[selectedResolution].partyCDDpsTank, roleName)
		end)
	end)
	partyCDDps:SetPoint("CENTER", partyCDPage, "CENTER", -77, 5)
	local partyCDHealer = MakeButton(partyCDPage, "Healer", 146, function()
		local roleName = "Healer " .. selectedResolution
		RunImport("partyCD", function()
			return ImportPartyCD(resolutionProfiles[selectedResolution].partyCDHealer, roleName)
		end)
	end)
	partyCDHealer:SetPoint("LEFT", partyCDDps, "RIGHT", 8, 0)
	PlaceStatusBelow(partyCDPage, partyCDDps, -12, 77)

	local weakAurasPage = CreatePage("weakAuras", "WeakAuras")
	local weakAurasButton = MakeButton(weakAurasPage, "General", 300, function()
		RunImport("weakAuras", function()
			return ImportWeakAuras(resolutionProfiles[selectedResolution].weakAurasGeneral, selectedResolution)
		end)
	end)
	weakAurasButton:SetPoint("CENTER", weakAurasPage, "CENTER", 0, 5)
	PlaceStatusBelow(weakAurasPage, weakAurasButton)

	local addonSettingsPage = CreatePage("addonSettings", "Apply Addon Settings")
	local addonSettingsButton = MakeButton(addonSettingsPage, "Apply Addon Settings", 300, function()
		RunImport("addonSettings", function()
			return ApplyAddonSettings(selectedResolution)
		end)
	end)
	addonSettingsButton:SetPoint("CENTER", addonSettingsPage, "CENTER", 0, 5)
	PlaceStatusBelow(addonSettingsPage, addonSettingsButton)

	previousButton = MakeButton(wizard, "Previous", 110, function()
		if currentPage == 1 then
			ShowWelcome()
		else
			ShowPage(currentPage - 1)
		end
	end)
	previousButton:SetPoint("BOTTOMLEFT", wizard, "BOTTOMLEFT", 24, 30)

	continueButton = MakeButton(wizard, "Continue", 110, function()
		if currentPage < #pageOrder then
			ShowPage(currentPage + 1)
		else
			TaanUIDB.completed = true
			StaticPopup_Show("TAANUI_RELOAD")
		end
	end)
	continueButton:SetPoint("BOTTOMRIGHT", wizard, "BOTTOMRIGHT", -24, 30)

	ShowPage = function(index)
		currentPage = index
		welcome:Hide()
		wizard:Show()
		for _, key in ipairs(pageOrder) do pages[key]:Hide() end
		pages[pageOrder[currentPage]]:Show()
		titleText:SetText(selectedResolution)
		progress:SetValue(currentPage)
		progressText:SetText(currentPage .. " / " .. #pageOrder)
		continueButton:SetText(currentPage == #pageOrder and "Finish" or "Continue")
	end

	ShowWelcome = function()
		wizard:Hide()
		welcome:Show()
		titleText:SetText("V8 Installation")
	end

	local resolution1080 = MakeButton(welcome, "1080p", 146, function()
		selectedResolution = "1080p"
		TaanUIDB.resolution = selectedResolution
		ShowPage(1)
	end)
	resolution1080:SetPoint("TOP", resolutionPrompt, "BOTTOM", -77, -24)

	local resolution1440 = MakeButton(welcome, "1440p", 146, function()
		selectedResolution = "1440p"
		TaanUIDB.resolution = selectedResolution
		ShowPage(1)
	end)
	resolution1440:SetPoint("LEFT", resolution1080, "RIGHT", 8, 0)

	local credit = frame:CreateFontString(nil, "OVERLAY")
	credit:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 12)
	SetExpressway(credit, 11)
	credit:SetText("By taan")

	local version = frame:CreateFontString(nil, "OVERLAY")
	version:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 12)
	SetExpressway(version, 11)
	version:SetText("Version " .. (GetAddOnMetadata(addonName, "Version") or "3.1.1"))

	frame.ShowWelcome = ShowWelcome
	ShowWelcome()
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
		for _, label in pairs(statusLabels) do label:SetText("|cffaaaaaa...|r") end
	end
	if not frame then BuildWindow() end
	frame:ShowWelcome()
	RefreshStatuses()
	frame:Show()
	frame:Raise()
end

local function InstallAllForResolution(resolution, useClassColors)
	TaanUIDB = TaanUIDB or {}
	TaanUIDB.imports = TaanUIDB.imports or {}
	TaanUIDB.completed = false
	TaanUIDB.resolution = resolution
	selectedResolution = resolution

	local profiles = resolutionProfiles[resolution]
	local failureCount = 0
	local presetName = useClassColors and "Class Colors" or "Dark"

	local function RunStep(label, importFunction)
		local ran, success, message = pcall(importFunction)
		if not ran then
			failureCount = failureCount + 1
			Print(label .. " failed: " .. tostring(success))
		elseif not success then
			failureCount = failureCount + 1
			Print(label .. " failed: " .. tostring(message or "unknown error"))
		end
	end

	RunStep("ElvUI Tank, Dps", function()
		return ImportElvUI(profiles.elvDpsTank, "Tank, Dps " .. resolution)
	end)
	RunStep("Tank, Dps addon settings", function()
		return ApplyAddonSettings(resolution)
	end)
	RunStep("Tank, Dps " .. presetName, function()
		return ApplyElvUIHealthColors(useClassColors)
	end)

	RunStep("ElvUI Healer", function()
		return ImportElvUI(profiles.elvHealer, "Healer " .. resolution)
	end)
	RunStep("Healer addon settings", function()
		return ApplyAddonSettings(resolution)
	end)
	RunStep("Healer " .. presetName, function()
		return ApplyElvUIHealthColors(useClassColors)
	end)

	RunStep("Aura Filters", function()
		return ImportElvUIFilters(data.auraFiltersGeneral, "Aura Filters", "auraFilters")
	end)
	RunStep("Nameplate Style Filters", function()
		return ImportElvUIFilters(data.nameplateStyleFiltersGeneral, "Nameplate Style Filters", "nameplateStyleFilters")
	end)
	RunStep("Details", function()
		return ImportDetails(profiles.details, resolution)
	end)
	RunStep("BigWigs Tank, Dps", function()
		return ImportBigWigs(profiles.bigWigsDpsTank, "Tank, Dps " .. resolution)
	end)
	RunStep("BigWigs Healer", function()
		return ImportBigWigs(profiles.bigWigsHealer, "Healer " .. resolution)
	end)
	RunStep("PartyCD Tank, Dps", function()
		return ImportPartyCD(profiles.partyCDDpsTank, "Tank, Dps " .. resolution)
	end)
	RunStep("PartyCD Healer", function()
		return ImportPartyCD(profiles.partyCDHealer, "Healer " .. resolution)
	end)
	RunStep("Final addon settings", function()
		return ApplyAddonSettings(resolution)
	end)

	local finished = false
	local function FinishInstallation(weakAurasSuccess)
		if finished then return end
		finished = true
		if weakAurasSuccess == false then
			failureCount = failureCount + 1
			Print("WeakAuras import was not completed.")
		end
		TaanUIDB.completed = failureCount == 0
		if failureCount == 0 then
			Print(resolution .. " " .. presetName .. " installation complete.")
		else
			Print(failureCount .. " installation step(s) failed.")
		end
		StaticPopup_Show("TAANUI_RELOAD")
	end

	local ran, success, message = pcall(function()
		return ImportWeakAuras(profiles.weakAurasGeneral, resolution, FinishInstallation)
	end)
	if not ran or not success then
		failureCount = failureCount + 1
		Print("WeakAuras failed: " .. tostring((ran and message) or success or "unknown error"))
		FinishInstallation()
	end
end

local function SetSpecProfilesForResolution(resolution)
	TaanUIDB = TaanUIDB or {}
	TaanUIDB.imports = TaanUIDB.imports or {}

	local numSpecs = GetNumSpecializations and GetNumSpecializations() or 0
	if numSpecs < 1 then
		Print("No specializations are available for this character.")
		return
	end

	local dpsTankProfile = "V8 - Tank, Dps " .. resolution
	local healerProfile = "V8 - Healer " .. resolution
	local function ProfileForSpec(specIndex)
		return GetSpecializationRole(specIndex) == "HEALER" and healerProfile or dpsTankProfile
	end

	local failureCount = 0
	local function RunStep(label, setupFunction)
		local ran, success, message = pcall(setupFunction)
		if not ran then
			failureCount = failureCount + 1
			Print(label .. " failed: " .. tostring(success))
		elseif not success then
			failureCount = failureCount + 1
			Print(label .. " failed: " .. tostring(message or "unknown error"))
		end
	end

	RunStep("ElvUI spec profiles", function()
		local loaded, reason = LoadRequiredAddon("ElvUI")
		if not loaded then return false, "ElvUI could not be loaded: " .. reason end
		local E = ElvUI and ElvUI[1]
		local db = E and E.data
		if not db or not db.SetDualSpecProfile or not db.SetDualSpecEnabled then
			return false, "ElvUI's spec profile support is unavailable."
		end
		if not db.sv or not db.sv.profiles or not db.sv.profiles[dpsTankProfile] or not db.sv.profiles[healerProfile] then
			return false, "Install both " .. resolution .. " ElvUI profiles first."
		end
		for specIndex = 1, numSpecs do
			db:SetDualSpecProfile(ProfileForSpec(specIndex), specIndex)
		end
		db:SetDualSpecEnabled(true)
		return true
	end)

	RunStep("BigWigs spec profiles", function()
		local loaded, reason = LoadRequiredAddon("BigWigs_Core")
		if not loaded then return false, "BigWigs Core could not be loaded: " .. reason end
		local db = BigWigs and BigWigs.db
		if not db or not db.SetDualSpecProfile or not db.SetDualSpecEnabled then
			return false, "BigWigs' spec profile support is unavailable."
		end
		if not db.sv or not db.sv.profiles or not db.sv.profiles[dpsTankProfile] or not db.sv.profiles[healerProfile] then
			return false, "Install both " .. resolution .. " BigWigs profiles first."
		end
		for specIndex = 1, numSpecs do
			db:SetDualSpecProfile(ProfileForSpec(specIndex), specIndex)
		end
		db:SetDualSpecEnabled(true)
		return true
	end)

	RunStep("PartyCD spec profiles", function()
		local loaded, reason = LoadRequiredAddon("PartyCD")
		if not loaded then return false, "PartyCD could not be loaded: " .. reason end
		local api = PartyCDAPI
		if not api or not api.SetSpecProfile or not api.SetSpecProfilesEnabled then
			return false, "PartyCD's spec profile support is unavailable."
		end
		if not api:FindProfileName(dpsTankProfile) or not api:FindProfileName(healerProfile) then
			return false, "Install both " .. resolution .. " PartyCD profiles first."
		end
		for specIndex = 1, numSpecs do
			local success, message = api:SetSpecProfile(specIndex, ProfileForSpec(specIndex))
			if not success then return false, message end
		end
		api:SetSpecProfilesEnabled(true)
		return true
	end)

	RunStep("Addon settings", function()
		return ApplyAddonSettings(resolution)
	end)

	if failureCount == 0 then
		Print(resolution .. " spec profiles enabled and addon settings applied.")
	else
		Print(failureCount .. " spec profile or addon settings step(s) failed.")
	end
end

local function PrintCommands()
	Print("Available commands:")
	Print("/taanui, /tui and /v8 - Open the V8 installer.")
	Print("/tui 1080c - Install all 1080p profiles with Class Colors.")
	Print("/tui 1080d - Install all 1080p profiles with Dark health bars.")
	Print("/tui 1440c - Install all 1440p profiles with Class Colors.")
	Print("/tui 1440d - Install all 1440p profiles with Dark health bars.")
	Print("/tui set 1080 - Assign 1080p spec profiles and apply addon settings.")
	Print("/tui set 1440 - Assign 1440p spec profiles and apply addon settings.")
	Print("/tui set class - Enable ElvUI class-colored health bars.")
	Print("/tui set dark - Enable ElvUI dark transparent health bars.")
	Print("/tui commands - Show this command list.")
end

SLASH_TAANUI1 = "/taanui"
SLASH_TAANUI2 = "/v8"
SLASH_TAANUI3 = "/tui"
SlashCmdList.TAANUI = function(message)
	local command = string.lower(string.match(message or "", "^%s*(.-)%s*$"))
	local installs = {
		["1080c"] = { "1080p", true },
		["1080d"] = { "1080p", false },
		["1440c"] = { "1440p", true },
		["1440d"] = { "1440p", false },
	}
	local specInstalls = {
		["set 1080"] = "1080p",
		["set 1440"] = "1440p",
	}
	local install = installs[command]
	if install then
		InstallAllForResolution(install[1], install[2])
	elseif specInstalls[command] then
		SetSpecProfilesForResolution(specInstalls[command])
	elseif command == "set class" or command == "set dark" then
		TaanUIDB = TaanUIDB or {}
		TaanUIDB.imports = TaanUIDB.imports or {}
		RunImport("elvui", function()
			return ApplyElvUIHealthColors(command == "set class")
		end)
	elseif command == "commands" then
		PrintCommands()
	else
		ShowInstaller(true)
	end
end

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_LOGIN")
	DisableElvUIInstaller()
	TaanUIDB = TaanUIDB or {}
	if not TaanUIDB.completed then
		ShowInstaller(false)
	end
end)

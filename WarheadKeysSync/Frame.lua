---
--- Frame utils
---

local KEYSNONE_COLOR_LEVEL_LOW = "|cFFFFFFFF" -- White
local KEYSNONE_COLOR_LEVEL_15 = "|cFF00FF00" -- Green
local KEYSNONE_COLOR_LEVEL_20 = "|cFFD2691E" -- Chocolate
local KEYSNONE_COLOR_LEVEL_25 = "|cFF6A5ACD" --
local KEYSNONE_COLOR_LEVEL_30 = "|cFFFF0000" -- Red
local KEYSTONE_IN_BAG = "|cFF00FF00Да|r"
local KEYSTONE_NOT_BAG = "|cFFFF0000Нет|r"

local characterListings = {}

local function CreateSpacer(width)
	local label = WarheadKeysSync.AceGUI:Create('Label');
	label:SetText(" ");

	if width <= 0 then
		label:SetFullWidth(true)
	else
		label:SetWidth(width)
	end

	return label
end

WarheadKeysSync.ColumnSort = function(table, rowa, rowb, sortbycol)
	local field = table.cols[sortbycol].field or table.cols[sortbycol].name:lower();
	local asc = table.cols[sortbycol].sort == "asc"
	local ka = WarheadKeysSync.ActiveTableData[rowa][1]
	local kb = WarheadKeysSync.ActiveTableData[rowb][1]

	if WarheadKeysSync.SortFields[1][1] == field then
		WarheadKeysSync.SortFields[1][2] = asc
	else
		for i = 2, #WarheadKeysSync.SortFields do
			if WarheadKeysSync.SortFields[i] and WarheadKeysSync.SortFields[i][1] == field then
				tremove(WarheadKeysSync.SortFields, i)
			end
		end

        tinsert(WarheadKeysSync.SortFields, 1, { field, true })
	end

	return WarheadKeysSync:CompareKeystones(ka, kb);
end

function WarheadKeysSync:ColorLevelDifficulty(text, level)
	local color = KEYSNONE_COLOR_LEVEL_LOW

	if level >= 15 and level < 20 then
		color = KEYSNONE_COLOR_LEVEL_15
	elseif level >= 20 and level < 25 then
		color = KEYSNONE_COLOR_LEVEL_20
	elseif level >= 25 and level < 30 then
		color = KEYSNONE_COLOR_LEVEL_25
	elseif level >= 30 then
		color = KEYSNONE_COLOR_LEVEL_30
	end

	return color .. text .."|r"
end

function WarheadKeysSync:GetPlayerColor(playerName, playerClass)
	local classFileName = select(2, GetClassInfo(playerClass))
	local classColor = select(4, GetClassColor(classFileName))

	return "|c" ..classColor..playerName.. "|r"
end

function WarheadKeysSync:CompareKeystones(ka, kb)
	for i = 1, #WarheadKeysSync.SortFields do
		local av
		local bv

		if WarheadKeysSync.SortFields[i][1] == "owner" then
			-- if ka.isPlayers then
				-- av = WarheadKeysSync.playerName.. (WarheadKeysSync.playerName == ka.name and "A" or "B")
			-- else
				av = (ka.owner == ka.name) and (ka.owner or "") .. "A" or (ka.owner or ka.name or "") .. "B"
			-- end

			-- if kb.isPlayers then
				-- bv = WarheadKeysSync.playerName.. (WarheadKeysSync.playerName == kb.name and "A" or "B")
			-- else
				bv = (kb.owner == kb.name) and (kb.owner or "") .. "A" or (kb.owner or kb.name or "") .. "B"
			-- end
		-- elseif WarheadKeysSync.SortFields[i][1] == "dungeon" then
		-- 	av = WarheadKeysSync:getDungeonName(ka.dungeon) or "ZZZ"
		-- 	bv = WarheadKeysSync:getDungeonName(kb.dungeon) or "ZZZ"
		-- elseif WarheadKeysSync.SortFields[i][1] == "realm" then
		-- 	local nameParts =  {strsplit("-",ka.name or"")}
		-- 	av = nameParts[2] or""
		-- 	nameParts =  {strsplit("-",kb.name or"")}
		-- 	bv = nameParts[2] or""
		-- elseif WarheadKeysSync.SortFields[i][1] == "bestLevel" or WarheadKeysSync.SortFields[i][1] == "level" or WarheadKeysSync.SortFields[i][1] == "ilvl" or WarheadKeysSync.SortFields[i][1] == "equippedIlvl" then
		-- 	av = ka[WarheadKeysSync.SortFields[i][1]] or 0
		-- 	bv = kb[WarheadKeysSync.SortFields[i][1]] or 0
		else
			av = ka[WarheadKeysSync.SortFields[i][1]] or ""
			bv = kb[WarheadKeysSync.SortFields[i][1]] or ""
		end

		if av < bv then
			return WarheadKeysSync.SortFields[i][2];
		elseif av > bv then
			return not WarheadKeysSync.SortFields[i][2];
		end
	end
end

function WarheadKeysSync:Hide()
	if self.Frame and self.Frame:IsVisible() then
		self.Frame:Hide()
	end
end

function WarheadKeysSync:RefreshTable()
	for k, _ in pairs(self.ActiveTableData) do
	  self.ActiveTableData[k] = nil
	end

	WarheadKeysSync.filtered = 0;
	wipe(characterListings)
	self.Tables[self.ActiveTableGroupName].Populate()

	table.sort(self.ActiveTableData, function(ra, rb)
		return self:CompareKeystones(ra[1], rb[1])
	end)

	self.ScrollTable:SortData()
end

function WarheadKeysSync:Show()
    -- Check is fame now visible
    if self.Frame and self.Frame:IsVisible() then
		return
	end

    -- Check frame is created
    if self.Frame then
        self.Frame:Show()
        self:RefreshTable()
        return
    end

    -- Start create table frame
    local frame = self.AceGUI:Create("Window")
    _G["WarheadKeysCache_Display"] = frame
    tinsert(UISpecialFrames, "WarheadKeysCache_Display")

    self.Frame = frame
    frame:SetTitle("WarheadKeysSync")
    -- frame:SetStatusText("")
    frame:SetWidth(820)
    frame:SetHeight(572)
    frame:EnableResize(false);
    frame:SetCallback("OnClose", function(_) WarheadKeysSync.Frame:Hide() end)
    frame:SetLayout("Flow")

	frame:AddChild(CreateSpacer(0));
	-- frame:AddChild(CreateSpacer(0));
	-- frame:AddChild(CreateSpacer(0));

    -- frame.headerBG = frame.frame:CreateTexture(nil, "BACKGROUND")
    -- frame.headerBG:SetPoint("TOP",frame.frame,"TOP",0,-25)
    -- frame.headerBG:SetPoint("LEFT",frame.frame,"LEFT",8,0)
    -- frame.headerBG:SetPoint("RIGHT",frame.frame,"RIGHT",-6,0)
    -- frame.headerBG:SetColorTexture(.11,.11,.11,1)
    -- frame.headerBG:SetHeight(43)

    frame.syncButton = CreateFrame("Button", nil, frame.frame, "UIPanelButtonTemplate")
    frame.syncButton:SetSize(120, 30)
    frame.syncButton:SetPoint("BOTTOMRIGHT", frame.frame, "BOTTOMRIGHT", -13, 13)

    frame.syncButton:SetScript("OnClick", function(_)
        WarheadKeysSync.Tables[WarheadKeysSync.ActiveTableGroupName].Populate()
    end)

	frame.syncButtonLabel = frame.syncButton:CreateFontString()
	frame.syncButtonLabel:SetFont(GameFontNormal:GetFont(), 12, "OUTLINE")
	frame.syncButtonLabel:SetText("Синхронизировать")
	frame.syncButtonLabel:SetTextColor(1,0.8196079,0,1)
	frame.syncButtonLabel:SetPoint("TOPLEFT", frame.syncButton, "TOPLEFT", 0, 0)
	frame.syncButtonLabel:SetPoint("BOTTOMRIGHT", frame.syncButton, "BOTTOMRIGHT", 0, 0)

    local tabDef = self.Tables["Account"]
    local tabList = {{ text = tabDef.Text, value = tabDef.Name, index = tabDef.Index }}

    tabDef = self.Tables["Party"]
    tinsert(tabList, { text = tabDef.Text, value = tabDef.Name, index = tabDef.Index })

    tabDef = self.Tables["Guild"]
    tinsert(tabList, { text = tabDef.Text, value = tabDef.Name, index = tabDef.Index })

    tabDef = self.Tables["Friends"]
    tinsert(tabList, { text = tabDef.Text, value = tabDef.Name, index = tabDef.Index })

    table.sort(tabList, function(a, b)
        return a.index < b.index
    end)

    self.tabFrame = self.AceGUI:Create("TabGroup")
    self.tabFrame:SetLayout("Fill")
    self.tabFrame:SetTabs(tabList)
    self.tabFrame:SetFullWidth(true)

    self.tabFrame:SetCallback("OnGroupSelected", function(container, _, group)
		container:ReleaseChildren()

		local tab = self.Tables[group]
		self.ActiveTableGroupName = tab.Name

        WarheadKeysSync:SetupDataTable(container, tab.EnableAlts)
        -- WarheadKeysSync:SetupFilters(tab.showFilterResultsEditBox, tab.propertyShowComplete, tab.propertyShowAlts, tab.propertyShowOffline, tab.propertyShowKeyless)
        WarheadKeysSync:RefreshTable()
    end)

    frame:AddChild(self.tabFrame)
    self.tabFrame:SelectTab("Account")
end

function WarheadKeysSync:AddDataToTable(keystone, owner, bestRunLevel, bestRunMapId, bestRunDiff, bestRunWeekIndex)
	if characterListings[keystone.PlayerName] then
		return
	end

    -- Keystone
	local activeTable = self.Tables[self.ActiveTableGroupName]
	local ownerName = activeTable.EnableAlts == true and owner or ""
	local playerName = keystone.PlayerName
	local level = keystone.Level or 0
	local mapName = C_ChallengeMode.GetMapInfo(keystone.MapId or 0) or ""
	local colorPlayerName = self:GetPlayerColor(playerName, keystone.PlayerClass)
	local colorClassName = self:GetPlayerColor(select(1, GetClassInfo(keystone.PlayerClass)), keystone.PlayerClass)
	local colorLevel = "+" ..self:ColorLevelDifficulty(level, level)
	local inBag = keystone.InBag == 1 and KEYSTONE_IN_BAG or KEYSTONE_NOT_BAG

	-- Best run
	local bestRunInfo = self:GetBestRunInfo(bestRunLevel, bestRunMapId, bestRunDiff, bestRunWeekIndex)

	if not ownerName then
		ownerName = "~~"
	end

	if level == 0 then
		colorLevel = ""
	end

    local dataRow =
    {
        playerName == ownerName and "--" or ownerName,
        colorPlayerName,
		colorClassName,
		inBag,
        colorLevel,
        mapName,
		bestRunInfo
    }

    tinsert(WarheadKeysSync.ActiveTableData, dataRow)
    characterListings[keystone.PlayerName] = dataRow

	table.sort(self.ActiveTableData, function(ra, rb)
		return self:CompareKeystones(ra[1], rb[1])
	end)



	self.ScrollTable:SortData()
end

function WarheadKeysSync:AddSelfDataToTable(addRuns)
	self:DoForAllKeys(function(_, keystone)
        local bestRunInfo = self:GetBestRun(keystone.PlayerName)
		if not bestRunInfo then
			bestRunInfo = self:GetDefaultBestRun(keystone.PlayerName)
		end

		self:AddDataToTable(keystone, WarheadKeysSync.PlayerInfo.Name, bestRunInfo.Level, bestRunInfo.MapId, bestRunInfo.LevelDiff, bestRunInfo.WeeklyIndex)
    end)

	if addRuns then
		self:DoForAllRuns(function(_, run)
			local keystone = {}
			keystone.PlayerName = run.PlayerName
			keystone.PlayerClass = run.PlayerClass

			self:AddDataToTable(keystone, WarheadKeysSync.PlayerInfo.Name, run.Level, run.MapId, run.LevelDiff, run.WeeklyIndex)
		end)
	end
end

function WarheadKeysSync:SetupDataTable(container, supportsAltDisplay)
	local cols =
	{
		{
			['name'] = '',
			['width'] = 5,
			['align'] = 'LEFT',
			["comparesort"] = WarheadKeysSync.ColumnSort,
			['field'] = "name",
		},
		{
			['name'] = "Персонаж",
			['width'] = 80,
			['align'] = 'LEFT',
			["comparesort"] = WarheadKeysSync.ColumnSort,
			['field'] = "name",
		},
		{
			['name'] = "Класс",
			['width'] = 80,
			['align'] = 'LEFT',
			['field'] = "class",
			["comparesort"] = WarheadKeysSync.ColumnSort,
		},
		{
			['name'] = "В сумке",
			['width'] = 50,
			['align'] = 'LEFT',
			["comparesort"] = WarheadKeysSync.ColumnSort,
			['field'] = "inBag",
		},
		{
			['name'] = "Уровень",
			['width'] = 50,
			['align'] = 'RIGHT',
			["comparesort"] = WarheadKeysSync.ColumnSort,
			['field'] = "level",
		},
		{
			['name'] = "Подземелье",
			['width'] = 200,
			['align'] = 'LEFT',
			["comparesort"] = WarheadKeysSync.ColumnSort,
			['field'] = "dungeon",
		},
		{
			['name'] = "Лучший забег на неделе",
			['width'] = 200,
			['align'] = 'LEFT',
			["comparesort"] = WarheadKeysSync.ColumnSort,
			['field'] = "level",
		}
	}

	if supportsAltDisplay then
		cols[1]['name']  = "Основа"
		cols[1]['field'] = "owner"
		cols[1]['width'] = 85
	end

	WarheadKeysSync.ActiveTableData = {}
	WarheadKeysSync.ScrollTable = WarheadKeysSync.ScrollingTable:CreateST(cols, 15, 25)
	WarheadKeysSync.ScrollTable:SetData(WarheadKeysSync.ActiveTableData, true)

	-- WarheadKeysSync.scrollTable:RegisterEvents({
	-- 	['OnClick'] = WarheadKeysSync.ListingOnClick,
	-- 	['OnEnter'] = WarheadKeysSync.ListingOnEntry,
	-- 	['OnLeave'] = WarheadKeysSync.ListingOnLeave,
	-- })

	local tableWrapper = WarheadKeysSync.AceGUI:Create('lib-st'):WrapST(WarheadKeysSync.ScrollTable)
	tableWrapper.head_offset = 15

    container:AddChild(tableWrapper)
	container:AddChild(CreateSpacer(0))
end

WarheadKeysSync.ListingOnClick = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, btn,...)
	-- if WarheadKeysSync.tableData and WarheadKeysSync.tableData[realrow] and WarheadKeysSync.tableData[realrow][1] then
	-- 	local keystone = WarheadKeysSync.tableData[realrow][1];

	-- 	if keystone.dummy then
	-- 		WarheadKeysSync:SuggestAddon("WHISPER",keystone.name)
	-- 	else
	-- 		WarheadKeysSync.frame:Hide();
	-- 		WarheadKeysSync:ShowShareFrame(keystone,function()
	-- 			WarheadKeysSync.frame:Show();
	-- 		end)
	-- 	end
	-- end
end

WarheadKeysSync.ListingOnLeave = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable,...)
	-- WarheadKeysSync:SetStatus("")

    if GameTooltip.bg then
		GameTooltip.bg:Hide()
	end

    GameTooltip:Hide()
end

WarheadKeysSync.ListingOnEntry = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable,...)
	-- if not realrow or not WarheadKeysSync.ActiveTableData[realrow] then
	-- 	return
	-- end

	-- local key = WarheadKeysSync.ActiveTableData[realrow][1]

    -- if key.dummy then
	-- 	WarheadKeysSync:SetStatus(KRCLocal:Get("status_suggest"))
	-- else
	-- 	WarheadKeysSync:SetStatus(KRCLocal:Get("status_share"))
	-- end

    -- WarheadKeysSync:showTooltip(key.name, rowFrame)
end
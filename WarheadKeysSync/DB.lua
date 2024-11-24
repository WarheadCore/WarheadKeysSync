---
--- DB utils
---

local WEEK_SECONDS = 604800

local function GetKeyFromBags()
    for bag = 0, NUM_BAG_SLOTS do
        local itemLink = WarheadKeysSync:GetKeyLink(bag)

        if itemLink ~= nil then
            return itemLink
        end
    end

    return nil
end

local function GetLaunchTime()
	return 1500436800
end

function WarheadKeysSync:GetWeeklyIndex()
	local weeklyIndex = (math.floor((GetServerTime() - GetLaunchTime()) / WEEK_SECONDS))
    return weeklyIndex
end

function WarheadKeysSync:GetWeekIndexByTime(time)
	return (math.floor((time - GetLaunchTime()) / WEEK_SECONDS))
end

function WarheadKeysSync:DoForAllKeys(task)
    for index, keystone in ipairs(WHKS_DB.DB) do
        task(index, keystone)
	end
end

function WarheadKeysSync:DoForAllRuns(task)
    for index, run in ipairs(WHKS_DB.Runs) do
        task(index, run)
	end
end

function WarheadKeysSync:PrintDB()
    print("|cFFFF0000[WH.KS.DB]:|r Список ключей на аккаунте:")

    self:DoForAllKeys(function(index, keystone)
        print(string.format("%d. %s: %s%s", index, self:GetPlayerColor(keystone.PlayerName, keystone.PlayerClass), self:MakeKeystoneItemLink(keystone), keystone.InBag == 1 and "" or " (не в сумке)"))
    end)

    print("|cFFFF0000[WH.KS.DB]:|r Список ранов на аккаунте:")

    self:DoForAllRuns(function(index, map)
        print(string.format("%d. %s: %s", index, map.PlayerName, self:GetBestRunInfo(map.Level, map.MapId, map.LevelDiff, map.WeeklyIndex)))
    end)
end

function WarheadKeysSync:SaveKeystone(keystone)
    if not keystone then
        return
    end

    local oldKeystoneIndex = self:GetKeystoneIndex(keystone.PlayerName)
    if oldKeystoneIndex then
        if self:IsKeystonesSame(WHKS_DB.DB[oldKeystoneIndex], keystone) then
            return
        end

        WHKS_DB.DB[oldKeystoneIndex] = keystone
        self:PrintDebug("Update keystone. Player: %s. Link: %s", keystone.PlayerName, self:MakeKeystoneItemLink(keystone))
    else
        tinsert(WHKS_DB.DB, keystone)
        self:PrintDebug("Saved keystone. Player: %s. Link: %s", keystone.PlayerName, self:MakeKeystoneItemLink(keystone))
    end
end

function WarheadKeysSync:SaveBestRun(playerName, playerClass, level, mapId, diff)
    local tableRow = { PlayerName = playerName, PlayerClass = playerClass, Level = level, MapId = mapId, LevelDiff = diff, WeeklyIndex = self:GetWeeklyIndex() }

    local oldBestRunIndex = self:GetBestRunIndex(playerName)
    if oldBestRunIndex then
        local oldBestRun = WHKS_DB.Runs[oldBestRunIndex]

        if oldBestRun["Level"] > level then
            return
        end

        if oldBestRun["Level"] == level and oldBestRun["LevelDiff"] < diff then
            return
        end

        WHKS_DB.Runs[oldBestRunIndex] = tableRow
        self:PrintDebug("Update best run. Player: %s. Level: %d. MapId: %d. Diff: %d", playerName, level, mapId, diff)
    else
        tinsert(WHKS_DB.Runs, tableRow)
        self:PrintDebug("Saved best run. Player: %s. Level: %d. MapId: %d. Diff: %d", playerName, level, mapId, diff)
    end
end

function WarheadKeysSync:GetDefaultBestRun(playerName)
    return { PlayerName = playerName, Level = 0, MapId = 0, LevelDiff = 0, WeeklyIndex = self:GetWeeklyIndex() }
end

function WarheadKeysSync:GetKeystone(playerName)
    for _, keystone in ipairs(WHKS_DB.DB) do
        if keystone.PlayerName == playerName then
            return keystone
        end
    end

    return nil
end

function WarheadKeysSync:GetKeystoneIndex(playerName)
    for index, keystone in ipairs(WHKS_DB.DB) do
        if keystone.PlayerName == playerName then
            return index
        end
    end

	return nil
end

function WarheadKeysSync:GetBestRunIndex(playerName)
    for index, bestRun in ipairs(WHKS_DB.Runs) do
        if bestRun.PlayerName == playerName then
            return index
        end
    end

	return nil
end

function WarheadKeysSync:GetBestRun(playerName)
    for _, bestRun in ipairs(WHKS_DB.Runs) do
        if bestRun.PlayerName == playerName then
            return bestRun
        end
    end

	return nil
end

function WarheadKeysSync:BuildSelfKeystone()
    self:ClearCache()

    local itemLink = GetKeyFromBags()
    local cacheKeystone = self:GetKeystone(WarheadKeysSync.PlayerInfo.Name)

    if not itemLink then
        if cacheKeystone then
            self:PrintDebug("Ушош удалил ключ из сумки (%s) O.O", self:MakeKeystoneItemLink(cacheKeystone))
            cacheKeystone.InBag = false
        end

        self:EnableCheckKeyInBags()
        return
    end

    WarheadKeysSync.PlayerInfo.Keystone = itemLink
    local mapId, level, aff1, aff2, aff3 = self:ParseKeystoneLink(itemLink)

    local keystone = {}
    self:FillKeystonePlayerData(keystone, WarheadKeysSync.PlayerInfo.Name, select(3, UnitClass("player")), self:GetWeeklyIndex(), WarheadKeysSync.Version)
    self:FillKeystoneItemData(keystone, mapId, level, aff1, aff2, aff3, 1)
    self:SaveKeystone(keystone)

    self:EnableCheckKeyInBags()
end

function WarheadKeysSync:BuildPlayerKeystone(sender, args)
    local keystone = {}

    self:FillKeystonePlayerData(keystone, args[1], tonumber(args[2]), tonumber(args[3]), args[4])
    self:FillKeystoneItemData(keystone, tonumber(args[5]), tonumber(args[6]), tonumber(args[7]), tonumber(args[8]), tonumber(args[9]), tonumber(args[10]))
    self:AddDataToTable(keystone, select(1, strsplit("-", sender)), tonumber(args[11]), tonumber(args[12]), tonumber(args[13]), tonumber(args[14]))
end

function WarheadKeysSync:CheckKeyInBags()
    local itemLink = GetKeyFromBags()

    if not itemLink or WarheadKeysSync.PlayerInfo.Keystone == itemLink then
        return
    end

    WarheadKeysSync.PlayerInfo.Keystone = itemLink
    self:PrintMessageToChat("Найден новый ключ: " ..itemLink)

    local keystone = {}
    local mapId, level, aff1, aff2, aff3 = self:ParseKeystoneLink(itemLink)

    self:FillKeystonePlayerData(keystone, WarheadKeysSync.PlayerInfo.Name, select(3, UnitClass("player")), self:GetWeeklyIndex(), WarheadKeysSync.Version)
    self:FillKeystoneItemData(keystone, mapId, level, aff1, aff2, aff3, 1)
    self:SaveKeystone(keystone)
end

function WarheadKeysSync:KeystonesCount()
    local count = 0

    for _, _ in ipairs(WHKS_DB.DB) do
        count = count + 1
    end

    return count
end

function WarheadKeysSync:FillKeystonePlayerData(keystone, playerName, classIndex, weekIndex, addonVersion)
    if not keystone then
        return
    end

    keystone.PlayerName = playerName
    keystone.PlayerClass = classIndex
    keystone.WeeklyIndex = weekIndex
    keystone.AddonVersion = addonVersion
end

function WarheadKeysSync:FillKeystoneItemData(keystone, mapId, level, aff1, aff2, aff3, inBag)
    if not keystone then
        return
    end

    keystone.MapId = mapId
    keystone.Level = level
    keystone.Affix1 = aff1
    keystone.Affix2 = aff2
    keystone.Affix3 = aff3
    keystone.InBag = inBag
    keystone.LastCheck = GetServerTime()
end

function WarheadKeysSync:ClearCache()
    local toDeleteKeys = {}
    local toDeleteRuns = {}
    local currentWeek = self:GetWeeklyIndex()

    self:DoForAllKeys(function(index, keystone)
        if keystone.WeeklyIndex ~= currentWeek then
            self:PrintDebug("Deleted old keystone. Player: %s. Keystone: %s", keystone.PlayerName, self:MakeKeystoneItemLink(keystone))
            table.insert(toDeleteKeys, index)
        end
    end)

    if #toDeleteKeys > 0 then
        for _, index in ipairs(toDeleteKeys) do
            tremove(WHKS_DB.DB, index)
        end

        self:PrintDebug("Deleted %d old keystones", #toDeleteKeys)
    end

    self:DoForAllRuns(function(index, run)
        if (currentWeek - run.WeeklyIndex) >= 2 then
            self:PrintDebug("Deleted old bestRun. Player: %s. Level: %d. MapId: %d. Diff: %d", run.PlayerName, run.MapId, run.LevelDiff)
            table.insert(toDeleteRuns, index)
        end
    end)

    if #toDeleteRuns > 0 then
        for _, index in ipairs(toDeleteRuns) do
            tremove(WHKS_DB.Runs, index)
        end

        self:PrintDebug("Deleted %d old runs", #toDeleteRuns)
    end
end

function WarheadKeysSync:InitializeMapCache()
    if #self.MapsCache > 1 then
        return
    end

    table.insert(self.MapsCache, { KeystoneMapId = 197, InstanceId = 1456 }) -- Око Азшары
    table.insert(self.MapsCache, { KeystoneMapId = 198, InstanceId = 1466 }) -- Чаща Тёмного Сердца
    table.insert(self.MapsCache, { KeystoneMapId = 199, InstanceId = 1501 }) -- Крепость Чёрной Ладьи
    table.insert(self.MapsCache, { KeystoneMapId = 200, InstanceId = 1477 }) -- Чертоги Доблести
    table.insert(self.MapsCache, { KeystoneMapId = 206, InstanceId = 1458 }) -- Логово Нелтариона
    table.insert(self.MapsCache, { KeystoneMapId = 207, InstanceId = 1493 }) -- Казематы Стражей
    table.insert(self.MapsCache, { KeystoneMapId = 208, InstanceId = 1492 }) -- Утроба Душ
    table.insert(self.MapsCache, { KeystoneMapId = 209, InstanceId = 1516 }) -- Катакомбы Сурамара
    table.insert(self.MapsCache, { KeystoneMapId = 210, InstanceId = 1571 }) -- Кавртал Звёзд
    table.insert(self.MapsCache, { KeystoneMapId = 227, InstanceId = 0 }) -- Возвращение в Каражан: нижний ярус
    table.insert(self.MapsCache, { KeystoneMapId = 233, InstanceId = 1677 }) -- Собор Вечной Ночи
    table.insert(self.MapsCache, { KeystoneMapId = 234, InstanceId = 1651 }) -- Возвращение в Каражан: верхний ярус
    table.insert(self.MapsCache, { KeystoneMapId = 239, InstanceId = 1753 }) -- Престол Триумвирата
    table.insert(self.MapsCache, { KeystoneMapId = 165, InstanceId = 1176 }) -- Некрополь Призрачной Луны
    table.insert(self.MapsCache, { KeystoneMapId = 166, InstanceId = 1208 }) -- Депо Мрачных Путей
end

function WarheadKeysSync:GetKeystoneMap(instanceId)
    for _, map in ipairs(self.MapsCache) do
        if map.InstanceId == instanceId then
            return map.KeystoneMapId
        end
    end

    return 0
end

function WarheadKeysSync:GetBestRunInfo(level, mapId, diff, weekIndex)
    local bestRunMapName = C_ChallengeMode.GetMapInfo(mapId) or tostring(mapId)
    local weekDiff = self:GetWeeklyIndex() - weekIndex
	local bestRunInfo = ""

	for _ = 1, diff do
		bestRunInfo = bestRunInfo.. "+"
	end

	bestRunInfo = bestRunInfo .. self:ColorLevelDifficulty(level, level) .. " " ..bestRunMapName

    if weekDiff == 1 then
        bestRunInfo = bestRunInfo.. ". Неделю назад"
    elseif weekDiff >= 2 then
        bestRunInfo = bestRunInfo.. ". Недель назад: " ..weekDiff
    end

	if level == 0 and mapId == 0 then
		bestRunInfo = ""
	end

    return bestRunInfo
end

function WarheadKeysSync:IsKeystonesSame(left, right)
    if not left or not right then
        return false
    end

    if left.MapId ~= right.MapId then
        return false
    end

    if left.Level ~= right.Level then
        return false
    end

    if left.WeeklyIndex ~= right.WeeklyIndex then
        return false
    end

    if left.Affix1 ~= right.Affix1 then
        return false
    end

    if left.Affix2 ~= right.Affix2 then
        return false
    end

    if left.Affix3 ~= right.Affix3 then
        return false
    end

    return true
end
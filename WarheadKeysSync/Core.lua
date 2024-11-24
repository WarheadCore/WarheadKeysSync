WarheadKeysSync = LibStub("AceAddon-3.0"):NewAddon("WarheadKeysSync", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0");
_G.WarheadKeysSync = WarheadKeysSync
WarheadKeysSync.AceGUI = LibStub('AceGUI-3.0')
WarheadKeysSync.Registry = LibStub('AceConfigRegistry-3.0')
WarheadKeysSync.ScrollingTable = LibStub('ScrollingTable')
WarheadKeysSync.AddonName = "WarheadKeysSync"
WarheadKeysSync.Version = GetAddOnMetadata("WarheadKeysSync", "Version")
WarheadKeysSync.MessagePrefix = "WHKS"
WarheadKeysSync.KeystoneItemId = 138019
WarheadKeysSync.Tables = {}
WarheadKeysSync.SortFields = {{ "name", true }}
WarheadKeysSync.MapsCache = {}

local _ = ...

local function GetTimeString(seconds)
	local hours = floor(seconds / 3600)
	local minutes = floor((seconds / 60) - (hours * 60))
	seconds = seconds - hours * 3600 - minutes * 60

	if hours == 0 then
		return format("%d:%.2d", minutes, seconds)
	else
		return format("%d:%.2d:%.2d", hours, minutes, seconds)
	end
end

function WarheadKeysSync:OnInitialize()
    if WHKS_DB == nil then
        WHKS_DB = {}
    end

    if not WHKS_DB.config then
        WHKS_DB.config =
        {
            EnableChatLink = true,
            EnableChatLinkInstance = false,
            LinkSlottedKey = false,
        }
    end

    if WHKS_DB.DB == nil then
        WHKS_DB.DB = { }
    end

    if WHKS_DB.Runs == nil then
        WHKS_DB.Runs = { }
    end

    local options =
    {
        name = "WarheadKeysSync",
        handler = WHKS_DB,
        type = "group",
        args =
        {
            linkSlottedKey = {
                type = "toggle",
                name = "Линковать вставленный ключ в чашку мифическую",
                desc = "Ебануть инфу о вставленном ключе в чатик",
                get = function(info,val) return WHKS_DB.config.EnableLinkSlottedKey end,
                set = function(info,val) WHKS_DB.config.EnableLinkSlottedKey = val end,
                width = "full"
            },
            enableChatLink = {
                type = "toggle",
                name = "Линковать свои ключи в чат (!keys)",
                desc = "Линковать свои ключи в рейд/группу/гильдию по команде !keys",
                get = function(info,val) return WHKS_DB.config.EnableChatLink end,
                set = function(info,val) WHKS_DB.config.EnableChatLink = val end,
                width = "full"
            },
            enableChatLinkInstance = {
                type = "toggle",
                name = "Проверять ключи при входе в инсту",
                desc = "Проверять и линковать свои ключи при входе в инст",
                get = function(info,val) return WHKS_DB.config.EnableChatLinkInstance end,
                set = function(info,val) WHKS_DB.config.EnableChatLinkInstance = val end,
                width = "full"
            },
--            exportdata = {
--                type = "execute",
--                name = "export",
--                desc = "export",
--                func = function(info) WarheadKeysSync:ExportData() end,
--                width = "full"
--            },
        },
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable("WarheadKeysSync", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WarheadKeysSync", "|cFFFF0000Warhead:|r Ключи на аккаунте")

    self:InitializeMapCache()
end

function WarheadKeysSync:OnEnable()
    -- Cache player info
    if WarheadKeysSync.PlayerInfo == nil then
        WarheadKeysSync.PlayerInfo = {}

        WarheadKeysSync.PlayerInfo.Name = UnitName("player")
        WarheadKeysSync.PlayerInfo.Realm = GetNormalizedRealmName()
        WarheadKeysSync.PlayerInfo.Keystone = ""
    end

    self:RegisterEvent("CHAT_MSG_PARTY", "PrintCacheToChat")
    self:RegisterEvent("CHAT_MSG_PARTY_LEADER", "PrintCacheToChat")
    self:RegisterEvent("CHAT_MSG_RAID", "PrintCacheToChat")
    self:RegisterEvent("CHAT_MSG_RAID_LEADER", "PrintCacheToChat")
    self:RegisterEvent("CHAT_MSG_GUILD", "PrintCacheToChat")
    self:RegisterEvent("CHAT_MSG_WHISPER", "PrintCacheToChat")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "CheckKeystoneInstance")
    self:RegisterEvent("CHALLENGE_MODE_KEYSTONE_SLOTTED", "OnSlottedKeystone")
    self:RegisterEvent("CHAT_MSG_ADDON", "OnAddonMessage")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED", "OnChallengeComplete")

    self:RegisterChatCommand("whks", "OnChatCommand")

    RegisterAddonMessagePrefix(WarheadKeysSync.MessagePrefix)
    self:BuildSelfKeystone()
end

function WarheadKeysSync:GetKeyLink(bagSlot)
    local numSlots = GetContainerNumSlots(bagSlot)

    if not numSlots then
        return nil
    end

    for slot = 1, numSlots do
        if (GetContainerItemID(bagSlot, slot) == WarheadKeysSync.KeystoneItemId) then
            return GetContainerItemLink(bagSlot, slot)
        end
    end

    return nil
end

function WarheadKeysSync:ParseKeystoneLink(itemLink)
    if itemLink == nil then
        return nil
    end

    local mapId, level, aff1, aff2, aff3 = string.match(itemLink, "|Hkeystone:(%d+):(%d+):(%d+):(%d+):(%d+)|h")
    return tonumber(mapId), tonumber(level), tonumber(aff1), tonumber(aff2), tonumber(aff3)
end

function WarheadKeysSync:CheckKeystoneInstance()
    if not WHKS_DB.config.EnableChatLinkInstance then
        return
    end

    local instanceName, instanceType = GetInstanceInfo()
    local diffId = GetDungeonDifficultyID()

    if instanceType ~= "party" or diffId ~= 23 then
        return
    end

    self:DoForAllKeys(function(_, keystone)
        local dungeonName = C_ChallengeMode.GetMapInfo(keystone.MapId)

        if dungeonName == instanceName then
            self:PrintMessageToChat("Найден ключ для этого подземелья. Персонаж: %s. Уровень: %d", keystone.PlayerName, keystone.Level)
        end
    end)
end

function WarheadKeysSync:OnSlottedKeystone()
    if not WHKS_DB.config.EnableLinkSlottedKey then
        return
    end

    local diffId = GetDungeonDifficultyID()
    if diffId ~= 23 then
        self:PrintMessageToChat("Попытка подготовить ключ к запуску не в мифик сложности. Инст бы обновить...")
        return
    end

    local _, _, keystoneLevel = C_ChallengeMode.GetSlottedKeystoneInfo()
    self:PrintMessageToChat("Подготовлен ключ к запуску. Уровень: %u", keystoneLevel)
end

function WarheadKeysSync:MakeKeystoneItemLink(keystone)
    if not keystone then
        return nil
    end

    local dungeonName = C_ChallengeMode.GetMapInfo(keystone.MapId)

    return string.format("|cffa335ee|Hkeystone:%d:%d:%d:%d:%d|h[Ключ: %s (%d)]|h|r",
        keystone.MapId, keystone.Level, keystone.Affix1, keystone.Affix2, keystone.Affix3, dungeonName, keystone.Level)
end

function WarheadKeysSync:EnableCheckKeyInBags()
    self:RegisterEvent("BAG_UPDATE", "CheckKeyInBags")
end

function WarheadKeysSync:OnChallengeComplete()
    local mapChallengeModeID, level, time, _, keystoneUpgradeLevels = C_ChallengeMode.GetCompletionInfo()
    local keystoneMapId = self:GetKeystoneMap(mapChallengeModeID)
    local dungeonName = C_ChallengeMode.GetMapInfo(keystoneMapId) or "Unk"
    local timeString = GetTimeString(time / 1000)

    self:PrintDebug("Complete challenge:")
    self:PrintDebug("  Map: %s (%d/%d)", dungeonName, mapChallengeModeID, keystoneMapId)
    self:PrintDebug("  Level: %d", level)
    self:PrintDebug("  Time: %s (%d)", timeString, time)
    self:PrintDebug("  UpgradeLevels: %d", keystoneUpgradeLevels)

    self:SaveBestRun(WarheadKeysSync.PlayerInfo.Name, select(3, UnitClass("player")), level, keystoneMapId, keystoneUpgradeLevels)
end
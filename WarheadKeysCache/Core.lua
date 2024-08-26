WarheadKeysCache = LibStub("AceAddon-3.0"):NewAddon("WarheadKeysCache", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0");

local SelfName = GetUnitName("player", false)
local WH_ITEM_ID_KEYSTONE = 138019

function WarheadKeysCache:OnInitialize()
    if WarheadKeysCacheDB == nil then
        WarheadKeysCacheDB = {}
    end

    if not WarheadKeysCacheDB.config then
        WarheadKeysCacheDB.config =
        {
            EnableChatLink = true,
            EnableChatLinkInstance = false,
            LinkSlottedKey = false,
        }
    end

    if WarheadKeysCacheDB.KeystoneCache == nil then
        WarheadKeysCacheDB.KeystoneCache = { }
    end

    local options =
    {
        name = "WarheadKeysCache",
        handler = WarheadKeysCacheDB,
        type = "group",
        args =
        {
            linkSlottedKey = {
                type = "toggle",
                name = "Линковать вставленный ключ в чашку мифическую",
                desc = "Ебануть инфу о вставленном ключе в чатик",
                get = function(info,val) return WarheadKeysCacheDB.config.EnableLinkSlottedKey end,
                set = function(info,val) WarheadKeysCacheDB.config.EnableLinkSlottedKey = val end,
                width = "full"
            },
            enableChatLink = {
                type = "toggle",
                name = "Линковать свои ключи в чат (!keys)",
                desc = "Линковать свои ключи в рейд/группу/гильдию по команде !keys",
                get = function(info,val) return WarheadKeysCacheDB.config.EnableChatLink end,
                set = function(info,val) WarheadKeysCacheDB.config.EnableChatLink = val end,
                width = "full"
            },
            enableChatLinkInstance = {
                type = "toggle",
                name = "Проверять ключи при входе в инсту",
                desc = "Проверять и линковать свои ключи при входе в инст",
                get = function(info,val) return WarheadKeysCacheDB.config.EnableChatLinkInstance end,
                set = function(info,val) WarheadKeysCacheDB.config.EnableChatLinkInstance = val end,
                width = "full"
            },
--            exportdata = {
--                type = "execute",
--                name = "export",
--                desc = "export",
--                func = function(info) WarheadKeysCache:ExportData() end,
--                width = "full"
--            },
        },
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable("WarheadKeysCache", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WarheadKeysCache", "|cFFFF0000Warhead:|r Ключи на аккаунте")
end

function WarheadKeysCache:OnEnable()
    self:RegisterEvent("CHAT_MSG_PARTY", "PrintCacheToChat")
    self:RegisterEvent("CHAT_MSG_PARTY_LEADER", "PrintCacheToChat")
    self:RegisterEvent("CHAT_MSG_RAID", "PrintCacheToChat")
    self:RegisterEvent("CHAT_MSG_RAID_LEADER", "PrintCacheToChat")
    self:RegisterEvent("CHAT_MSG_GUILD", "PrintCacheToChat")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "CheckKeystoneInstance")
    self:RegisterEvent("CHALLENGE_MODE_KEYSTONE_SLOTTED", "OnSlottedKeystone")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnterWorld")

    self:RegisterChatCommand("whkeys", "OnChatCommand")
end

function WarheadKeysCache:OnEnterWorld()
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    self:FillKeysCache()

    self:RegisterEvent("BAG_UPDATE", "FillKeysCache")
end

function WarheadKeysCache:OnChatCommand(input)
    if input == "check" then
        self:FillKeysCache()
    elseif input == "clear" then
        self:ClearCacheDB()
    elseif input == "list" then
        self:PrintDB()
    else
        print("/whkeys clear: Очистка ключей на аккаунте")
        print("/whkeys check: Проверка и кеширование ключа на текущем персонаже")
        print("/whkeys list: Проверка ключей на всех персонажах")
    end
end

function WarheadKeysCache:FillKeysCache()
    local cacheItemLink = WarheadKeysCacheDB.KeystoneCache[SelfName]

    for bag = 0, NUM_BAG_SLOTS do
        local itemLink = self:GetKeyLink(bag)

        if itemLink ~= nil then
            if itemLink ~= cacheItemLink then
                WarheadKeysCacheDB.KeystoneCache[SelfName] = itemLink
                self:PrintMessageToChat("Найден новый ключ: "..itemLink)
            end

            return
        end
    end
end

function WarheadKeysCache:GetKeyLink(bagSlot)
    local numSlots = GetContainerNumSlots(bagSlot)

    for slot = 1, numSlots do
        if (GetContainerItemID(bagSlot, slot) == WH_ITEM_ID_KEYSTONE) then
            return GetContainerItemLink(bagSlot, slot)
        end
    end

    return nil
end

function WarheadKeysCache:ParseKeystoneLink(itemLink)
    if itemLink == nil then
        return "", 0
    end

    local map, level, name = string.match(itemLink, "|Hkeystone:(%d+):(%d+):.-|h(.-)|h")
    name = C_ChallengeMode.GetMapInfo(map)
    return name, level
end

function WarheadKeysCache:CheckKeystoneInstance(...)
    if WarheadKeysCacheDB.config.EnableChatLinkInstance == false then
        return
    end

    local instanceName, instanceType, _, _, maxPlayers, _, _, _, _, _ = GetInstanceInfo()

    if instanceType ~= "party" or maxPlayers ~= 5 then
        return
    end

    for character, keystoneLink in pairs(WarheadKeysCacheDB.KeystoneCache) do
        local keyName, _ = self:ParseKeystoneLink(keystoneLink)

        if keyName == instanceName then
            self:PrintMessageToChat(string.format("Найден ключ для этого подземелья. Персонаж: %s. Ключ: %s", character, keystoneLink))
        end
    end
end

function WarheadKeysCache:PrintCacheToChat(event, msg)
    if string.find(msg, "!keys") == nil or not WarheadKeysCacheDB.config.EnableChatLink then
        return
    end

    local isPrintAll = msg == "!keys all"
    local sendChannelType = "PARTY"

    if event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" then
        sendChannelType = "RAID"
    elseif event == "CHAT_MSG_GUILD" then
        sendChannelType = "GUILD"
    end

    if isPrintAll then
        for character, keystoneLink in pairs(WarheadKeysCacheDB.KeystoneCache) do
            local text = string.format("%s: %s", character, keystoneLink)
            SendChatMessage(text, sendChannelType)
        end
    else
        local thisKeystone = WarheadKeysCacheDB.KeystoneCache[SelfName]

        if thisKeystone ~= nil then
            SendChatMessage(thisKeystone, sendChannelType)
        end
    end
end

function WarheadKeysCache:PrintMessageToChat(message)
    if IsInGroup() then
        SendChatMessage(message, "PARTY")
        return
    end

    print("|cFFFF0000[WH.KeysCache]:|r "..message)
end

function WarheadKeysCache:OnSlottedKeystone()
    if not WarheadKeysCacheDB.config.EnableLinkSlottedKey then
        return
    end

    local _, _, keystoneLevel = C_ChallengeMode.GetSlottedKeystoneInfo()
    local zoneName = GetInstanceInfo()

    self:PrintMessageToChat(string.format("Подготовлен ключ к запуску. %s. Уровень: %u", zoneName, keystoneLevel))
end

function WarheadKeysCache:ClearCacheDB()
    local cacheItemLink = WarheadKeysCacheDB.KeystoneCache[SelfName]

    if not cacheItemLink then
        print("|cFFFF0000[WH.KeysCache]:|r Не найден ключ в базе для этого персонажа")
        return
    end

    WarheadKeysCacheDB.KeystoneCache[SelfName] = nil
    print(string.format("|cFFFF0000[WH.KeysCache]:|r Ключ: %s был удалён из базы", cacheItemLink))
end

function WarheadKeysCache:PrintDB()
    print("|cFFFF0000[WH.KeysCache]:|r Список ключей на аккаунте:")

    for character, keystoneLink in pairs(WarheadKeysCacheDB.KeystoneCache) do
        print(string.format("%s: %s", character, keystoneLink))
    end
end

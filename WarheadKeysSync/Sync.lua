---
--- Sync utils
---

local SEND_REFIX_GET_KEYSTONE = 0
local SEND_REFIX_SEND_KEYSTONE = 1

function WarheadKeysSync:DebugSyncSelf()
    local keystone = self:GetKeystone(WarheadKeysSync.PlayerInfo.Name)

    if not keystone then
        self:PrintDebug("Not found self key")
        return
    end

    self:DoForAllKeys(function(_, keystone)
        self:SendKeystoneInfo(keystone, "WHISPER", WarheadKeysSync.PlayerInfo.Name)
    end)
end

function WarheadKeysSync:SendKeystones(channel, target)
    local keystone = self:GetKeystone(WarheadKeysSync.PlayerInfo.Name)

    if not keystone then
        self:PrintDebug("Not found self key")
        return
    end

    self:DoForAllKeys(function(_, keystone)
        self:SendKeystoneInfo(keystone, channel, target)
    end)
end

function WarheadKeysSync:SendKeystoneInfo(keystone, channel, target)
    if not keystone then
        self:PrintDebug("Попытка синхронизировать не существующий ключ o.o")
        return
    end

    local keystoneInfo = SEND_REFIX_SEND_KEYSTONE.. ";"
    keystoneInfo = keystoneInfo ..keystone["PlayerName"].. ";"
    keystoneInfo = keystoneInfo ..keystone["PlayerClass"].. ";"
    keystoneInfo = keystoneInfo ..keystone["WeeklyIndex"].. ";"
    keystoneInfo = keystoneInfo ..keystone["AddonVersion"].. ";"
    keystoneInfo = keystoneInfo ..keystone["MapId"].. ";"
    keystoneInfo = keystoneInfo ..keystone["Level"].. ";"
    keystoneInfo = keystoneInfo ..keystone["Affix1"].. ";"
    keystoneInfo = keystoneInfo ..keystone["Affix2"].. ";"
    keystoneInfo = keystoneInfo ..keystone["Affix3"].. ";"
    keystoneInfo = keystoneInfo ..keystone["InBag"].. ";"

    local bestRun = self:GetBestRun(keystone["PlayerName"])
    if not bestRun or bestRun["WeeklyIndex"] ~= self:GetWeeklyIndex() then
        bestRun = self:GetDefaultBestRun(keystone["PlayerName"])
    end

    keystoneInfo = keystoneInfo..bestRun.Level.. ";"
    keystoneInfo = keystoneInfo..bestRun.MapId.. ";"
    keystoneInfo = keystoneInfo..bestRun.LevelDiff.. ";"
    keystoneInfo = keystoneInfo..bestRun.WeeklyIndex

    ChatThrottleLib:SendAddonMessage("NORMAL", WarheadKeysSync.MessagePrefix, keystoneInfo, channel, target)
end

function WarheadKeysSync:GetKeystonesInfo(channel, target)
    local keystoneInfo = tostring(SEND_REFIX_GET_KEYSTONE)
    ChatThrottleLib:SendAddonMessage("NORMAL", WarheadKeysSync.MessagePrefix, keystoneInfo, channel, target)
end

function WarheadKeysSync:SyncArgsCount()
    return 1 + 10 + 4
end
---
--- Chat utils
---

function WarheadKeysSync:PrintMessageToChat(fmt, ...)
    local message = string.format(fmt, ...)

    if IsInGroup() then
        SendChatMessage(message, "PARTY")
        return
    end

    print("|cFFFF0000[WH.KS]:|r " ..message)
end

function WarheadKeysSync:OnChatCommand(input)
    if #input == 0 or input == "show" then
        self:Show()
    elseif input == "clear" then
        self:ClearCache()
    elseif input == "list" then
        self:PrintDB()
    else
        print("/whkeys clear: Очистка ключей на аккаунте")
        print("/whkeys list: Проверка ключей на всех персонажах")
    end
end

function WarheadKeysSync:OnAddonMessage(_, prefix, message, channel, sender)
    if prefix ~= WarheadKeysSync.MessagePrefix then
		return
	end

    local senderName, senderRealm = strsplit("-", sender)

    if senderRealm ~= WarheadKeysSync.PlayerInfo.Realm or senderName == WarheadKeysSync.PlayerInfo.Name then
        return
    end

    local args = { strsplit(";", message) }

    -- Get keys hanndle
    if args[1] == "0" then
        -- self:PrintDebug("Found get keys info message. Args count: %d", #args)
        self:SendKeystones(channel, sender)
        return
    end

    -- Send keystones
    if args[1] == "1" then
        -- self:PrintDebug("Found send keys info message. Args count: %d. Message: %s", #args, message)

        -- Add support old addons
        if #args == 11 then
            tinsert(args, 0)
            tinsert(args, 0)
            tinsert(args, 0)
            tinsert(args, 0)
        end

        if #args < self:SyncArgsCount() then
            self:PrintDebug("Receive incorrect send keystone message format. Args %d/%d", #args, self:SyncArgsCount())
            return
        end

        tremove(args, 1)
        self:BuildPlayerKeystone(sender, args)
        return
    end

    self:PrintDebug("Found unknown sync info format. Message: %s", message)
end

function WarheadKeysSync:PrintCacheToChat(event, msg, sender)
    if string.find(msg, "!keys") == nil or not WHKS_DB.config.EnableChatLink then
        return
    end

    local isPrintAll = msg == "!keys all"
    local sendChannelType = "PARTY"

    if event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER" then
        sendChannelType = "RAID"
    elseif event == "CHAT_MSG_GUILD" then
        sendChannelType = "GUILD"
    elseif event == "CHAT_MSG_WHISPER" then
        sendChannelType = "WHISPER"
    end

    if isPrintAll then
        SendChatMessage(string.format("Найдено ключей: %d", self:KeystonesCount()), sendChannelType, nil, sender)

        self:DoForAllKeys(function(index, keystone)
            SendChatMessage(string.format("-- %d. %s: %s%s", index, keystone.PlayerName, self:MakeKeystoneItemLink(keystone), keystone.InBag == 1 and "" or " (не в сумке)"), sendChannelType, nil, sender)
        end)
    else
        local keystone = self:GetKeystone(WarheadKeysSync.PlayerInfo.Name)

        if keystone ~= nil then
            SendChatMessage(string.format("-- %s%s", self:MakeKeystoneItemLink(keystone), keystone.InBag == 1 and "" or " (не в сумке)"), sendChannelType, nil, sender)
        end
    end
end

function WarheadKeysSync:PrintDebug(fmt, ...)
    local message = string.format(fmt, ...)
    print("|cFFFF0000[WH.KS.Debug]:|r " ..message)
end

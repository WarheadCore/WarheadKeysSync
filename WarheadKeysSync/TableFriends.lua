---
--- Sync utils
---

local table = {}
table.Index = 3
table.Text = "Друзья"
table.Name = "Friends"
-- tab.propertyShowComplete = "personalShowComplete"
table.EnableAlts = true
-- tab.propertyShowKeyless = "personalShowKeyless"
-- tab.propertyShowOffline = nil
-- tab.showFilterResultsEditBox = true

table.Populate = function()
	for i = 1, GetNumFriends() do
		local name, level, class, _, isOnline = GetFriendInfo(i)

		if isOnline then
			WarheadKeysSync:GetKeystonesInfo("WHISPER", name)
		end
	end
end

WarheadKeysSync.Tables[table.Name] = table
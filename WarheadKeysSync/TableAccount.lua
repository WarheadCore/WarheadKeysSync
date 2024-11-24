---
--- Sync utils
---

local table = {}
table.Index = 1
table.Text = "Аккаунт"
table.Name = "Account"
table.EnableAlts = false
-- tab.propertyShowComplete = "personalShowComplete"
-- tab.propertyShowAlts = nil
-- tab.propertyShowKeyless = "personalShowKeyless"
-- tab.propertyShowOffline = nil
-- tab.showFilterResultsEditBox = true

table.Populate = function()
	-- Add self
	WarheadKeysSync:AddSelfDataToTable(true)

    -- WarheadKeysSync:GetKeystonesInfo("WHISPER", WarheadKeysSync.PlayerInfo.Name)
end

WarheadKeysSync.Tables[table.Name] = table
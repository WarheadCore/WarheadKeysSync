---
--- Sync utils
---

local table = {}
table.Index = 2
table.Text = "Гильдия"
table.Name = "Guild"
table.EnableAlts = true
-- tab.propertyShowComplete = "personalShowComplete"
-- tab.propertyShowAlts = nil
-- tab.propertyShowKeyless = "personalShowKeyless"
-- tab.propertyShowOffline = nil
-- tab.showFilterResultsEditBox = true

table.Populate = function()
	-- Add self
	WarheadKeysSync:AddSelfDataToTable()

	if IsInGuild() then
		WarheadKeysSync:GetKeystonesInfo("GUILD")
	end
end

WarheadKeysSync.Tables[table.Name] = table
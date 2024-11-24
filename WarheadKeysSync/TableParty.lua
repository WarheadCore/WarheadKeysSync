---
--- Sync utils
---

local table = {}
table.Index = 2
table.Text = "Группа"
table.Name = "Party"
table.EnableAlts = true
-- tab.propertyShowComplete = "personalShowComplete"
-- tab.propertyShowAlts = nil
-- tab.propertyShowKeyless = "personalShowKeyless"
-- tab.propertyShowOffline = nil
-- tab.showFilterResultsEditBox = true

table.Populate = function()
	-- Add self
	WarheadKeysSync:AddSelfDataToTable()

	if UnitInRaid("player") then
		WarheadKeysSync:GetKeystonesInfo("RAID")
	elseif IsInGroup() then
		WarheadKeysSync:GetKeystonesInfo("PARTY")
	end
end

WarheadKeysSync.Tables[table.Name] = table
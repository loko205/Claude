-- Central tuning values. Times in seconds, money in Cash.
local Config = {
	-- Conveyor
	ConveyorSpawnInterval = 3,
	ConveyorSpeed = 6, -- studs/sec
	MaxItemsOnBelt = 12,

	-- Plots
	PlotSlots = 12,
	DeliveryRadius = 16, -- distance to plot center that counts as "home"

	-- Economy
	StartCash = 50,
	IncomeTick = 1,

	-- Stealing
	StealWalkSpeed = 12, -- carrier is slowed down (default 16)
	StealCooldown = 15,

	-- Base lock
	LockDuration = 60,
	LockCooldown = 180,

	-- Rebirth
	RebirthBaseCost = 15000,
	RebirthCostFactor = 4,
	RebirthIncomeBonus = 0.5, -- +50% income per rebirth

	-- Offline earnings
	OfflineRate = 0.5, -- fraction of live income earned while offline
	OfflineCap = 6 * 3600,

	AutosaveInterval = 120,
}

return Config

-- Central tuning values. Times in seconds, money in Cash.
local Config = {
	-- Conveyor
	ConveyorSpawnInterval = 3,
	ConveyorSpeed = 6, -- studs/sec
	MaxItemsOnBelt = 12,

	-- Plots
	PlotSlots = 10, -- 2 rows of 5; wider spacing so big characters don't overlap
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

	-- Gold Rush event (server-wide luck boost)
	GoldRushInterval = 18 * 60,
	GoldRushDuration = 120,
	GoldRushLuck = 3,

	-- Daily login streak
	DailyBase = 250,
	DailyStreakCap = 7,

	-- Schnitzel-Dex discovery reward (fraction of base price)
	DiscoveryRewardFactor = 0.25,

	LeaderboardRefresh = 90,

	-- Paste your ids here after creating the passes/products in the
	-- Creator Dashboard (0 = hidden in the shop until configured).
	Monetization = {
		GamepassDoubleCash = 0,
		GamepassVIP = 0,
		ProductCashSmall = 0,
		ProductCashMedium = 0,
		ProductCashLarge = 0,
	},
	VIPIncomeBonus = 0.5,
	CashProductAmounts = { Small = 10000, Medium = 60000, Large = 400000 },
}

return Config

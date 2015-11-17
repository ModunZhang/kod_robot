local soldier_vs = GameDatas.ClientInitGame.soldier_vs

soldier_vs["infantry"] = {
	["soldier_type"] = "infantry",
	["archer"] = "weak",
	["siege"] = "strong"
}
soldier_vs["archer"] = {
	["soldier_type"] = "archer",
	["infantry"] = "strong",
	["cavalry"] = "weak"
}
soldier_vs["cavalry"] = {
	["soldier_type"] = "cavalry",
	["archer"] = "strong",
	["siege"] = "weak"
}
soldier_vs["siege"] = {
	["soldier_type"] = "siege",
	["infantry"] = "weak",
	["cavalry"] = "strong"
}

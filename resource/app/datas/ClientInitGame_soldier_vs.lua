local soldier_vs = GameDatas.ClientInitGame.soldier_vs

soldier_vs["infantry"] = {
	["soldier_type"] = "infantry",
	["archer"] = "weak",
	["cavalry"] = "weak",
	["siege"] = "strong",
	["wall"] = "strong"
}
soldier_vs["archer"] = {
	["soldier_type"] = "archer",
	["infantry"] = "strong",
	["cavalry"] = "strong",
	["siege"] = "weak",
	["wall"] = "weak"
}
soldier_vs["cavalry"] = {
	["soldier_type"] = "cavalry",
	["infantry"] = "strong",
	["archer"] = "weak",
	["siege"] = "strong",
	["wall"] = "weak"
}
soldier_vs["siege"] = {
	["soldier_type"] = "siege",
	["infantry"] = "weak",
	["archer"] = "strong",
	["cavalry"] = "weak",
	["wall"] = "strong"
}
soldier_vs["wall"] = {
	["soldier_type"] = "wall",
	["infantry"] = "weak",
	["archer"] = "strong",
	["cavalry"] = "strong",
	["siege"] = "weak"
}

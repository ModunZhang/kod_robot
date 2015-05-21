local soldier_vs = GameDatas.ClientInitGame.soldier_vs

soldier_vs["infantry"] = {
	["soldier_type"] = "infantry",
	["archer"] = "weak",
	["cavalry"] = "strong",
	["siege"] = "strong",
	["wall"] = "weak"
}
soldier_vs["archer"] = {
	["soldier_type"] = "archer",
	["infantry"] = "strong",
	["cavalry"] = "weak",
	["siege"] = "weak",
	["wall"] = "strong"
}
soldier_vs["cavalry"] = {
	["soldier_type"] = "cavalry",
	["infantry"] = "weak",
	["archer"] = "strong",
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
	["soldier_type"] = "wall"
}

--
-- Author: Danny He
-- Date: 2014-12-12 10:41:06
--
local AudioManager = class("AudioManager")
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")

local bg_music_map = {
	MainScene               = "music_begin.mp3",
	MyCityScene             = "sfx_city.mp3",
	AllianceScene           = "bgm_peace.mp3",
	PVEScene                = "bgm_battle.mp3",
	AllianceBattleScene     = "bgm_battle.mp3",
	AllianceBattleScene_sfx = "sfx_battle.mp3",
	grassLand               = "sfx_grassland.mp3",
	iceField                = "sfx_icefield.mp3",
	desert                  = "sfx_desert.mp3",
}

local effect_sound_map = {
	NORMAL_DOWN = "sfx_tap_button.mp3",
	-- NORMAL_UP = "ui_button_down.mp3",
	HOME_PAGE = "sfx_tap_homePage.mp3",
	OPEN_MAIL = "sfx_open_mail.mp3",
	USE_ITEM = "sfx_use_item.mp3",
	BUY_ITEM = "sfx_buy_item.mp3",
	HOORAY = "sfx_hooray.mp3",
	COMPLETE = "sfx_complete.mp3",
	TROOP_LOSE = "sfx_troop_lose.mp3",
	TROOP_SENDOUT = "sfx_troop_sendOut.mp3",
	TROOP_RECRUIT = "sfx_troop_recruit.mp3",
	TROOP_BACK = "sfx_troops_back.mp3",
	BATTLE_DEFEATED = "sfx_battle_defeated.mp3",
	BATTLE_VICTORY = "sfx_battle_victory.mp3",
	DRAGON_STRIKE = "sfx_select_dragon2.mp3",
	BATTLE_DRAGON = "sfx_dragonPK.mp3",
	SPLASH_BUTTON_START = "sfx_click_start.mp3",
	UI_BUILDING_UPGRADE_START = "ui_building_upgrade.mp3",
	UI_BUILDING_DESTROY = "sfx_building_destroy.mp3",
	UI_BLACKSMITH_FORGE = "ui_blacksmith_forge.mp3",
	UI_TOOLSHOP_CRAFT_START = "ui_toolShop_craft_start.mp3",
	SELECT_ENEMY_ALLIANCE_CITY = "sfx_select_keep_enemy.mp3",
	ATTACK_PLAYER_ARRIVE = "sfx_select_armyCamp.mp3",
	STRIKE_PLAYER_ARRIVE = "sfx_select_dragon3.mp3",
	TREATE_SOLDIER = "sfx_heal.mp3",
	INSTANT_TREATE_SOLDIER = "sfx_instant_heal.mp3",
	BATTLE_START = "sfx_battle_start.mp3",
	AIRSHIP = "sfx_pve.mp3",
	PVE_MOVE1 = "sfx_pve_move1.mp3",
	PVE_MOVE2 = "sfx_pve_move2.mp3",
	PVE_MOVE3 = "sfx_pve_move3.mp3",
}

local soldier_step_sfx_map = {
	infantry = {"sfx_step_infantry01.mp3", "sfx_step_infantry02.mp3", "sfx_step_infantry03.mp3"},
	archer = {"sfx_step_archer01.mp3", "sfx_step_archer02.mp3", "sfx_step_archer03.mp3"},
	cavalry = {"sfx_step_cavalry01.mp3", "sfx_step_cavalry02.mp3", "sfx_step_cavalry03.mp3"},
	siege = {"sfx_step_siege01.mp3", "sfx_step_siege02.mp3", "sfx_step_siege03.mp3"},
}

local building_sfx_map = {
    keep = {"sfx_select_keep.mp3"},
    watchTower = {"sfx_select_watchtower.mp3"},
    warehouse = {"sfx_select_warehouse.mp3"},
    dragonEyrie = {"sfx_select_dragon1.mp3", "sfx_select_dragon2.mp3", "sfx_select_dragon3.mp3"},
    barracks = {"sfx_select_barracks.mp3"},
    hospital = {"sfx_select_hospital.mp3"},
    academy = {"sfx_select_academy.mp3"},
    materialDepot = {"sfx_select_warehouse.mp3"},
    blackSmith = {"sfx_select_blackSmith.mp3"},
    foundry = {"sfx_select_foundry.mp3"},
    hunterHall = {"sfx_select_hunterHall.mp3"},
    lumbermill = {"sfx_select_lumbermill.mp3"},
    stoneMason = {"sfx_select_stonemason.mp3"},
    mill = {"sfx_select_mill.mp3"},
    townHall = {"sfx_select_townHall.mp3"},
    toolShop = {"sfx_select_toolshop.mp3"},
    tradeGuild = {"sfx_select_tradeGuild.mp3"},
    trainingGround = {"sfx_select_trainingGround.mp3"},
    hunterHall = {"sfx_select_hunterHall.mp3"},
    workshop = {"sfx_select_workshop.mp3"},
    stable = {"sfx_select_stable.mp3"},
    wall = {"sfx_select_wall.mp3"},
    tower = {"sfx_select_tower.mp3"},
    dwelling = {"sfx_select_dwelling.mp3"},
    farmer = {"sfx_select_resourceBuilding.mp3"},
    woodcutter = {"sfx_select_resourceBuilding.mp3"},
    quarrier = {"sfx_select_resourceBuilding.mp3"},
    miner = {"sfx_select_resourceBuilding.mp3"},
}


local BACKGROUND_MUSIC_KEY = "BACKGROUND_MUSIC_KEY"
local EFFECT_MUSIC_KEY = "EFFECT_MUSIC_KEY"

-------------------------------------------------------------------------

function AudioManager:ctor(game_default)
	self.game_default = game_default
	self.is_bg_auido_on = self:GetGameDefault():getBasicInfoValueForKey(BACKGROUND_MUSIC_KEY,true)
	self.is_effect_audio_on = self:GetGameDefault():getBasicInfoValueForKey(EFFECT_MUSIC_KEY,true)
	self:PreLoadAudio()
	self:SetEffectsVolume(0.4)
end

function AudioManager:GetGameDefault()
	return self.game_default
end

--预加载音乐到内存(android)
function AudioManager:PreLoadAudio()

end

-- isLoop必须传入
function AudioManager:PlayeBgMusic(filename,isLoop)
	assert(type(isLoop) == 'boolean')
	printLog("AudioManager","PlayeBgMusic----->%s,%s", filename,tostring(isLoop))
	local index = string.find(filename,"%.")
	local file_key = string.sub(filename,1,index - 1)
	if self.is_bg_auido_on then
		if file_key ~= self.last_music_filename then
			audio.playMusic("audios/" .. filename,isLoop)
			self.last_music_filename = file_key 
		elseif not audio.isMusicPlaying() then
			audio.playMusic("audios/" .. filename,isLoop)
			self.last_music_filename = file_key 
		end
	end
end

function AudioManager:PlayeBgSound(filename)
	if self.is_bg_auido_on then
		audio.playSound("audios/" .. filename,true)
	end
end

function AudioManager:PlayeEffectSound(filename)
	printLog("AudioManager","PlayeEffectSound----->%s",filename)
	if self.is_effect_audio_on then
		audio.playSound("audios/" .. filename,false)
	end
end

function AudioManager:PlayeAttackSoundBySoldierName(soldier_name)
	local audio_name = string.format("sfx_%s_attack.mp3", soldier_name)
	assert(audio_name, audio_name.." 音乐不存在")
	self:PlayeEffectSound(audio_name)
end

function AudioManager:GetLastPlayedFileName()
	return self.last_music_filename or  ""
end

--Api normal
function AudioManager:PlayBuildingEffectByType(type_)
	local sfx = building_sfx_map[type_]
	if sfx then
		self:PlayeEffectSound(sfx[math.random(#sfx)])
	end
end
function AudioManager:PlaySoldierStepEffectByType(type_)
	local sfx = soldier_step_sfx_map[type_]
	if sfx then
		print(sfx[math.random(#sfx)])
		self:PlayeEffectSound(sfx[math.random(#sfx)])
	end
end
-- isLoop 默认为false
function AudioManager:PlayGameMusic(scene_name,isLoop,forcePlay)
	printLog("AudioManager","PlayGameMusic----->%s",scene_name or "nil")
	if self.music_handle then
		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.music_handle)
		self:SetBgMusicVolume(1.0)
	end
	if type(isLoop) ~= 'boolean' then isLoop = false end
	if forcePlay then
		self:PlayGameMusicWithMapKey(scene_name,isLoop)
		return
	end
	if Alliance_Manager then
		local alliance = Alliance_Manager:GetMyAlliance()
		local status = alliance:Status()
		local file_key = scene_name or display.getRunningScene().__cname
		if file_key == 'MyCityScene' or file_key == 'AllianceScene' or file_key == 'AllianceBattleScene' then
			if alliance:IsDefault() then
				file_key = 'AllianceScene'
			else
				if status == 'prepare' or status == 'fight' then
					file_key = 'AllianceBattleScene'
				else
					file_key = "AllianceScene"
				end
			end
		end
		self:PlayGameMusicWithMapKey(file_key,isLoop)
		-- if bg_music_map[file_key] then
		-- 	if string.find(bg_music_map[file_key],"sfx_") then
		-- 		self:SetBgMusicVolume(0)
		-- 		self:PlayeBgMusic(bg_music_map[file_key],isLoop)
		-- 		self:FadeInBgMusicVolume()
		-- 	else
		-- 		self:PlayeBgMusic(bg_music_map[file_key],isLoop)
		-- 	end
		-- end
	else
		local file_key = scene_name or display.getRunningScene().__cname
		self:PlayGameMusicWithMapKey(file_key,isLoop)
	end
end

function AudioManager:PlayGameMusicWithMapKey(file_key,loop)
	if bg_music_map[file_key] then
		if string.find(bg_music_map[file_key],"sfx_") then
			self:SetBgMusicVolume(0)
			self:PlayeBgMusic(bg_music_map[file_key],loop)
			self:FadeInBgMusicVolume()
		else
			self:PlayeBgMusic(bg_music_map[file_key],loop)
		end
	end
end


function AudioManager:PlayeEffectSoundWithKey(key)
	self:PlayeEffectSound(self:GetEffectAudio(key))
end

function AudioManager:GetEffectAudio(key)
	return effect_sound_map[key]
end

function AudioManager:StopMusic()
	audio.stopMusic()
end

function AudioManager:StopEffectSound()
	audio.stopAllSounds()
end

--control 
function AudioManager:SwitchBackgroundMusicState(isOn)
	isOn = checkbool(isOn)
	if self.is_bg_auido_on == isOn then return end
	self.last_music_filename = ""
	self.is_bg_auido_on = isOn 
	if isOn then
		self:PlayGameMusic()
	else
		self:StopMusic()
	end
	self:GetGameDefault():setBasicInfoBoolValueForKey(BACKGROUND_MUSIC_KEY,isOn)
	self:GetGameDefault():flush()
	-- if not isOn then audio.stopAllSounds() end --关闭主城的两重音乐
end

function AudioManager:GetBackgroundMusicState()
	return self.is_bg_auido_on
end

function AudioManager:SwitchEffectSoundState(isOn)
	isOn = checkbool(isOn)
	if self.is_effect_audio_on == isOn then return end
	self.is_effect_audio_on = isOn
	self:GetGameDefault():setBasicInfoBoolValueForKey(EFFECT_MUSIC_KEY,isOn)
	self:GetGameDefault():flush()
end

function AudioManager:GetEffectSoundState()
	return self.is_effect_audio_on
end

function AudioManager:StopAll()
	self:StopMusic()
	self:StopEffectSound()
end

function AudioManager:SetEffectsVolume(volume)
	audio.setSoundsVolume(volume)
end

function AudioManager:SetBgMusicVolume(volume)
	audio.setMusicVolume(volume)
end

function AudioManager:GetBgMusicVolume()
	return audio.getMusicVolume()
end
 
function AudioManager:FadeInBgMusicVolume()
    local sharedScheduler = cc.Director:getInstance():getScheduler()
    local perVol = 0.01
    local vol = 0
    self.music_handle = sharedScheduler:scheduleScriptFunc(function()
        vol = vol + perVol
        self:SetBgMusicVolume(vol)
        if vol >= 1 then 
        	if self.music_handle then
            	sharedScheduler:unscheduleScriptEntry(self.music_handle)
            end
        end
    end, 0.04, false)
end

-- for global call
function AudioManager:OnBackgroundMusicCompletion()
	printLog("AudioManager","OnBackgroundMusicCompletion---->%s", self:GetLastPlayedFileName())
	local current_scene = display.getRunningScene()
	local scene_name    = current_scene.__cname
	local lastFileKey   = self:GetLastPlayedFileName()
	local alliance      = Alliance_Manager:GetMyAlliance()
	local terrain       = alliance:Terrain()
	local status        = alliance:Status()

	if scene_name == 'MyCityScene' then
		if status == 'prepare' or status == 'fight' then
			if lastFileKey == 'sfx_city' then
				self:PlayGameMusicWithMapKey('AllianceBattleScene',false)
			elseif lastFileKey == 'bgm_battle' then
				self:PlayGameMusicWithMapKey('MyCityScene',false)
			end
		else
			if lastFileKey == 'bgm_peace' then
				self:PlayGameMusicWithMapKey('MyCityScene',false)
			elseif lastFileKey == 'sfx_city' then
				self:PlayGameMusicWithMapKey('AllianceScene',false)
			end
		end
	elseif scene_name == 'AllianceScene' or scene_name == 'AllianceBattleScene' then
		if status == 'prepare' or status == 'fight' then
			if lastFileKey == 'bgm_battle' then
				self:PlayGameMusicWithMapKey('AllianceBattleScene_sfx',false)
			elseif lastFileKey == 'sfx_battle' then
				self:PlayGameMusicWithMapKey('AllianceBattleScene',false)
			end
		else
			if lastFileKey == 'bgm_peace' then
				self:PlayGameMusicWithMapKey(terrain,false)
			else
				self:PlayGameMusicWithMapKey("AllianceScene",false)
			end
		end
	else
		self:PlayGameMusic()
	end
end

return AudioManager

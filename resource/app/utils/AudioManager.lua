--
-- Author: Danny He
-- Date: 2014-12-12 10:41:06
--
local AudioManager = class("AudioManager")
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")

local bg_music_map = {
	MainScene = "music_begin.mp3",
	MyCityScene = "sfx_city.mp3",
	AllianceScene = "bgm_peace.mp3",
	PVEScene = "bgm_battle.mp3",
	AllianceBattleScene = "bgm_battle.mp3",
	grassLand = "sfx_glassland.mp3",
	iceField = "sfx_icefiled.mp3",
	desert = "sfx_desert.mp3",
}

local effect_sound_map = {
	NORMAL_DOWN = "sfx_tap_button.wav",
	NORMAL_UP = "ui_button_down.wav",
	HOME_PAGE = "sfx_tap_homePage.wav",
	OPEN_MAIL = "sfx_open_mail.wav",
	USE_ITEM = "sfx_use_item.wav",
	BUY_ITEM = "sfx_buy_item.wav",
	HOORAY = "sfx_hooray.wav",
	COMPLETE = "sfx_complete.wav",
	TROOP_LOSE = "sfx_troop_lose.wav",
	TROOP_SENDOUT = "sfx_troop_sendOut.wav",
	TROOP_RECRUIT = "sfx_troop_recruit.wav",
	TROOP_BACK = "sfx_troops_back.wav",
	BATTLE_DEFEATED = "sfx_battle_defeated.wav",
	BATTLE_VICTORY = "sfx_battle_victory.wav",
	DRAGON_STRIKE = "sfx_select_dragon2.wav",
	BATTLE_DRAGON = "sfx_dragonPK.wav",
	SPLASH_BUTTON_START = "sfx_click_start.mp3",
	UI_BUILDING_UPGRADE_START = "ui_building_upgrade.wav",
	UI_BUILDING_DESTROY = "sfx_building_destroy.wav",
	UI_BLACKSMITH_FORGE = "ui_blacksmith_forge.mp3",
	UI_TOOLSHOP_CRAFT_START = "ui_toolShop_craft_start.mp3",
	SELECT_ENEMY_ALLIANCE_CITY = "sfx_select_keep_enemy.wav",
	ATTACK_PLAYER_ARRIVE = "sfx_select_armyCamp.wav",
	STRIKE_PLAYER_ARRIVE = "sfx_select_dragon3.wav",
	TREATE_SOLDIER = "sfx_heal.mp3",
	INSTANT_TREATE_SOLDIER = "sfx_instant_heal.mp3",
	BATTLE_START = "sfx_battle_start.mp3",
}

local soldier_step_sfx_map = {
	infantry = {"sfx_step_infantry01.wav", "sfx_step_infantry02.wav", "sfx_step_infantry03.wav"},
	archer = {"sfx_step_archer01.wav", "sfx_step_archer02.wav", "sfx_step_archer03.wav"},
	cavalry = {"sfx_step_cavalry01.wav", "sfx_step_cavalry02.wav", "sfx_step_cavalry03.wav"},
	siege = {"sfx_step_siege01.wav", "sfx_step_siege02.wav", "sfx_step_siege03.wav"},
}

local building_sfx_map = {
    keep = {"sfx_select_keep.wav"},
    watchTower = {"sfx_select_watchtower.wav"},
    warehouse = {"sfx_select_warehouse.wav"},
    dragonEyrie = {"sfx_select_dragon1.wav", "sfx_select_dragon2.wav", "sfx_select_dragon3.wav"},
    barracks = {"sfx_select_barracks.wav"},
    hospital = {"sfx_select_hospital.wav"},
    academy = {"sfx_select_academy.wav"},
    materialDepot = {"sfx_select_warehouse.wav"},
    blackSmith = {"sfx_select_blackSmith.wav"},
    foundry = {"sfx_select_foundry.wav"},
    hunterHall = {"sfx_select_hunterHall.wav"},
    lumbermill = {"sfx_select_lumbermill.wav"},
    stoneMason = {"sfx_select_stonemason.wav"},
    mill = {"sfx_select_mill.wav"},
    townHall = {"sfx_select_townHall.wav"},
    toolShop = {"sfx_select_toolshop.wav"},
    tradeGuild = {"sfx_select_tradeGuild.wav"},
    trainingGround = {"sfx_select_trainingGround.wav"},
    hunterHall = {"sfx_select_hunterHall.wav"},
    workshop = {"sfx_select_workshop.wav"},
    stable = {"sfx_select_stable.wav"},
    wall = {"sfx_select_wall.wav"},
    tower = {"sfx_select_tower.wav"},
    dwelling = {"sfx_select_dwelling.wav"},
    farmer = {"sfx_select_resourceBuilding.wav"},
    woodcutter = {"sfx_select_resourceBuilding.wav"},
    quarrier = {"sfx_select_resourceBuilding.wav"},
    miner = {"sfx_select_resourceBuilding.wav"},
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


function AudioManager:PlayeBgMusic(filename,isLoop)
	assert(type(isLoop) == 'boolean')
	print("PlayeBgMusic----->",filename,isLoop)
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
	print("PlayeEffectSound----->",filename)
	if self.is_effect_audio_on then
		audio.playSound("audios/" .. filename,false)
	end
end

function AudioManager:PlayeAttackSoundBySoldierName(soldier_name)
	local audio_name = string.format("sfx_%s_attack.wav", soldier_name)
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

function AudioManager:PlayGameMusic(scene_name,isLoop)
	if self.music_handle then
		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.music_handle)
		self:SetBgMusicVolume(1.0)
	end
	if type(isLoop) ~= 'boolean' then isLoop = true end
	local file_key = scene_name
	if not scene_name then
		local file_key = display.getRunningScene().__cname
		local loop = false
		if "PVEScene" ~= file_key  and "MainScene" ~= file_key then
			local alliance = Alliance_Manager:GetMyAlliance()
			if alliance:IsDefault() then
				file_key = "AllianceScene"
			else
				local status = alliance:Status()
				if status == 'prepare' or status == 'fight' then
					file_key = "AllianceBattleScene"
				else
					file_key = "AllianceScene"
				end
			end
		end
		if bg_music_map[file_key] then
			if string.find(bg_music_map[file_key],"sfx_") then
				self:SetBgMusicVolume(0)
				self:PlayeBgMusic(bg_music_map[file_key],loop)
				self:FadeInBgMusicVolume()
			else
				self:PlayeBgMusic(bg_music_map[file_key],loop)
			end
		end
	else
		if bg_music_map[file_key] then
			if string.find(bg_music_map[file_key],"sfx_") then
				self:SetBgMusicVolume(0)
				self:PlayeBgMusic(bg_music_map[file_key],isLoop)
				self:FadeInBgMusicVolume()
			else
				self:PlayeBgMusic(bg_music_map[file_key],isLoop)
			end
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
	-- self.is_effect_audio_on = false
	audio.stopAllSounds()
end

--scene

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
	if not isOn then audio.stopAllSounds() end --关闭主城的两重音乐
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
	print("AudioManager:OnBackgroundMusicCompletion--->",self:GetLastPlayedFileName())
	local current_scene = display.getRunningScene()
	local scene_name = current_scene.__cname
	local lastFilename = self:GetLastPlayedFileName()
	local terrain = Alliance_Manager:GetMyAlliance():Terrain()
	if lastFilename == 'bgm_peace' 
		or lastFilename == 'bgm_battle' 
		or lastFilename == 'sfx_city' 
		or lastFilename == 'sfx_desert' 
		or lastFilename == 'sfx_glassland' 
		or lastFilename == 'sfx_icefiled' 
		then
			if lastFilename == 'bgm_peace' or lastFilename == 'bgm_battle' then
				if scene_name == 'MyCityScene' then
					self:PlayGameMusic("MyCityScene",false) -- sfx_city
				elseif scene_name == 'AllianceBattleScene' then
					local alliance = Alliance_Manager:GetMyAlliance()
					local status = alliance:Status()
					if status == 'prepare' or status == 'fight' then
						if current_scene.PlayCurrentTerrainMusic then
							current_scene:PlayCurrentTerrainMusic()
						end
					else
						self:PlayGameMusic("AllianceScene",false)
					end
				elseif scene_name == 'AllianceScene' then
					self:PlayGameMusic(terrain,false) -- terrain music
				end
			else 
				self:PlayGameMusic()
			end
	end
end

return AudioManager

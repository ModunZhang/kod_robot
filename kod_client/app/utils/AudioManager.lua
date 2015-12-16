--
-- Author: Danny He
-- Date: 2014-12-12 10:41:06
--
local AudioManager = class("AudioManager")
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")

local scene_enter_music_map = {
	MainScene     = "music_begin.mp3",
	MyCityScene   = "bgm_peace.mp3",
	AllianceDetailScene = "bgm_peace.mp3",
	PVEScene      = "bgm_battle.mp3"
}

local terrain_music_map = {
	[1] = "sfx_grassland.mp3",
	[2] = "sfx_icefield.mp3",
	[3] = "sfx_desert.mp3",
}

local effect_sound_map = {
	NORMAL_DOWN = "sfx_tap_button.mp3",
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
	PVE_STAR1 = "sfx_pve_star1.mp3",
	PVE_STAR2 = "sfx_pve_star2.mp3",
	PVE_STAR3 = "sfx_pve_star3.mp3",
	PVE_SWEEP = "sfx_get.mp3",
	TECHNOLOGY = "sfx_technology.mp3",
	HATCH_DRAGON = "sfx_dragon3.mp3",
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

function AudioManager:PlayBgMusicWithFileKey(file_key,isLoop)
	assert(type(isLoop) == 'boolean')
	local filename = string.format("%s.mp3",file_key)
	printLog("AudioManager","PlayBgMusicWithFileKey:%s,%s", file_key,tostring(isLoop))
	if self.is_bg_auido_on then
		if file_key ~= self.last_music_filename then
			audio.playMusic("audios/" .. filename,isLoop)
			self.last_music_filename = file_key 
			self.last_music_loop = isLoop
		elseif not audio.isMusicPlaying() then
			audio.playMusic("audios/" .. filename,isLoop)
			self.last_music_filename = file_key 
			self.last_music_loop = isLoop
		end
	end
end

-- isLoop必须传入
function AudioManager:PlayeBgMusic(filename,isLoop)
	local index = string.find(filename,"%.")
	local file_key = string.sub(filename,1,index - 1)
	self:PlayBgMusicWithFileKey(file_key,isLoop)
end

function AudioManager:PlayeBgSound(filename)
	if self.is_bg_auido_on then
		-- audio.playSound("audios/" .. filename,true)
	end
end

function AudioManager:PlayeEffectSound(filename)
	printLog("AudioManager","PlayeEffectSound:%s",filename)
	if self.is_effect_audio_on then
		-- audio.playSound("audios/" .. filename,false)
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
		self:PlayGameMusicAutoCheckScene()
	else
		self:StopMusic()
	end
	self:GetGameDefault():setBasicInfoBoolValueForKey(BACKGROUND_MUSIC_KEY,isOn)
	self:GetGameDefault():flush()
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

 --OtherCityScene OtherAllianceScene FriendCityScene
local get_scene_name_in_enter_music_map = function(sceneName)
	if sceneName == 'FteScene' then
		return "MyCityScene" 
	elseif sceneName == 'PVESceneNewFte' then
		return "PVEScene"
	elseif sceneName == 'FteScene' then
		return "MyCityScene"
	elseif sceneName == 'MyCityFteScene' then
		return "MyCityScene"
	else
		return sceneName
	end
end


function AudioManager:PlayGameMusicAutoCheckScene()
	printLog("AudioManager","PlayGameMusicAutoCheckScene")
	local current_scene_name = display.getRunningScene().__cname
	if not current_scene_name then --如果检测不到再次播放上次的音乐
		local lastFileKey = self:GetLastPlayedFileName()
		if lastFileKey ~= "" then
			self:PlayBgMusicWithFileKey(lastFileKey,self.last_music_loop)
		else
			printLog("AudioManager","can not play game music-1!")
		end
	else
		local real_scene_name = get_scene_name_in_enter_music_map(current_scene_name)
		if not scene_enter_music_map[real_scene_name] then -- 如果不是指定音乐的场景 重复上次音乐
			local lastFileKey = self:GetLastPlayedFileName()
			if lastFileKey ~= "" then
				self:PlayBgMusicWithFileKey(lastFileKey,self.last_music_loop)
			else
				printLog("AudioManager","can not play game music-2!")
			end
		else
			local alliance    = Alliance_Manager:GetMyAlliance()
			local status      = alliance.basicInfo.status
			local lastFileKey = self:GetLastPlayedFileName()
			local terrain     = alliance.basicInfo.terrain

			if alliance:IsDefault() then -- 无联盟
				if real_scene_name == 'MyCityScene' then
					if lastFileKey == 'bgm_peace' then
						self:PlayBgMusicWithFileKey('sfx_city',false)
					elseif lastFileKey == 'sfx_city' then
						self:PlayBgMusicWithFileKey('bgm_peace',false)
					else
						self:PlayBgMusicWithFileKey('bgm_peace',false)
					end
				end
			else --有联盟
				if status == 'prepare' or status == 'fight' then
					if real_scene_name == 'MyCityScene' then
						if lastFileKey == 'bgm_battle' then
							self:PlayBgMusicWithFileKey('sfx_city',false)
						elseif lastFileKey == "sfx_city" then
							self:PlayBgMusicWithFileKey('bgm_battle',false)
						else
							self:PlayBgMusicWithFileKey('bgm_battle',false)
						end
					elseif real_scene_name == 'AllianceDetailScene' then
						if lastFileKey == 'bgm_battle' then
							self:PlayBgMusicWithFileKey('sfx_battle',false)
						elseif lastFileKey == "sfx_battle" then
							self:PlayBgMusicWithFileKey('bgm_battle',false)
						else
							self:PlayBgMusicWithFileKey('bgm_battle',false)
						end
					end
				else
					if real_scene_name == 'MyCityScene' then
						if lastFileKey == 'bgm_peace' then
							self:PlayBgMusicWithFileKey('sfx_city',false)
						elseif lastFileKey == 'sfx_city' then
							self:PlayBgMusicWithFileKey('bgm_peace',false)
						else
							self:PlayBgMusicWithFileKey('bgm_peace',false)
						end
					elseif real_scene_name == 'AllianceDetailScene' then
						if lastFileKey == 'bgm_peace' then
							self:PlayeBgMusic(terrain_music_map[math.random(3)], false)
						else
							self:PlayBgMusicWithFileKey('bgm_peace',false)
						end
					end
				end
			end
		end
	end
end

function AudioManager:PlayGameMusicOnSceneEnter(scene_name,loop)
	printLog("AudioManager","PlayGameMusicOnSceneEnter %s,%s",scene_name,tostring(loop))
	if scene_enter_music_map[scene_name] then
		if scene_name == 'MyCityScene' then
			if Alliance_Manager then
				local status = Alliance_Manager:GetMyAlliance().basicInfo.status
				if status == 'prepare' or status == 'fight' then
					scene_name = 'AllianceDetailScene' --battle
					self:PlayBgMusicWithFileKey('bgm_battle',false)
				else
					self:PlayeBgMusic(scene_enter_music_map[scene_name],loop)
				end
			else
				self:PlayeBgMusic(scene_enter_music_map[scene_name],loop)
			end
		else	
			self:PlayeBgMusic(scene_enter_music_map[scene_name],loop)
		end
	else
		printLog("AudioManager","can not play game music %s",scene_name)
	end
end


function AudioManager:OnBackgroundMusicCompletion()
	if self.last_music_loop then return end -- 如果上次是循环的背景音乐 忽略
	self:PlayGameMusicAutoCheckScene()
end

return AudioManager
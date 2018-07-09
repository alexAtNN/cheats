--Author: gagajo
local AutoDust = {}
AutoDust.MenuPath = {"Utility", "Auto Dust"}
AutoDust.MEnabled = Menu.AddOptionBool(AutoDust.MenuPath, "Enabled", false)
AutoDust.Range = Menu.AddOptionSlider({"Utility", "Auto Dust"}, "Range in use dust", 100, 1050, 500)
AutoDust.sleepers = {}
AutoDust.Modifiers = { 
--Enemy modifier
 "modifier_bounty_hunter_wind_walk", 
 "modifier_riki_permanent_invisibility", 
 "modifier_mirana_moonlight_shadow", 
 "modifier_weaver_shukuchi", 
 "modifier_clinkz_wind_walk", 
 "modifier_treant_natures_guise_invis", 
 "modifier_item_invisibility_edge_windwalk", 
 "modifier_item_silver_edge_windwalk",
 "modifier_item_glimmer_cape_fade",
 "modifier_item_shadow_amulet_fade",
 "modifier_rune_invis",
 "modifier_windrunner_windrun_invis",
 "modifier_invoker_ghost_walk_enemy"
}
--Allies modifier
AutoDust.ModifiersAllies={
 "modifier_bounty_hunter_track",
 "modifier_bloodseeker_thirst_vision",
 "modifier_slardar_amplify_damage",
 "modifier_item_dustofappearance"
}
 AutoDust.Unique = {}
AutoDust.skills={

    {  
        name = "nyx_assassin_vendetta_start",
		ability = "nyx_assassin_vendetta",
		duration = 2
    },
	{  
        name = "sandking_sandstorm",
		ability = "sandking_sand_storm",
		duration = 2
    }
}
function AutoDust.InsertNyx(particle)
    local myHero = Heroes.GetLocal()
    for i=1, #AutoDust.skills do
		if particle.name == AutoDust.skills[i].name then
		    local enemy = nill
            local ally = nill
            for i = 1, Heroes.Count() do
                local hero = Heroes.Get(i)
                if not NPC.IsIllusion(hero) then
                    local sameTeam = Entity.GetTeamNum(hero) == Entity.GetTeamNum(myHero)
                    if not sameTeam and NPC.GetAbility(hero, AutoDust.skills[i].ability) and not NPC.GetAbility(myHero, AutoDust.skills[i].ability) then
                        enemy = hero
                    end
                    if sameTeam and NPC.GetAbility(hero, AutoDust.skills[i].ability) then
                        ally = hero
                    end
                end
            end
            local newAlert = {
                index = particle.index,
                name = AutoDust.skills[i].name,
				endTime = os.clock() + AutoDust.skills[i].duration
             }
            if enemy then
                newAlert['enemy'] = NPC.GetUnitName(enemy)
                --newAlert['msg'] = string.sub (NPC.GetUnitName(enemy),string.len("npc_dota_hero_")-string.len(NPC.GetUnitName(enemy)))..AutoDust.skills[i].msg
                table.insert(AutoDust.Unique, newAlert)
            end 
            if ally then return end
            --table.insert(AutoDust.Unique, newAlert)
            
            return true
        end
    end

    return false
end
 
function AutoDust.OnParticleCreate(particle)
    if not Menu.IsEnabled(AutoDust.MEnabled) then return end
	--Log.Write(particle.name .. "=" .. string.format("0x%x", particle.particleNameIndex))
	--Log.Write("position"..particle.position)
	AutoDust.InsertNyx(particle)
end

function AutoDust.OnParticleUpdate(particle)
    --Log.Write("position"..particle.position:__tostring())
    if particle.controlPoint ~= 0 then return end

    for k=1 ,#AutoDust.Unique do
        if particle.index == AutoDust.Uniqu[i].index then
            AutoDust.Uniqu[i].position = particle.position
        end
    end
end

function AutoDust.OnUpdate()
    local hero = Heroes.GetLocal()
	if not hero or not Menu.IsEnabled(AutoDust.MEnabled ) or not AutoDust.SleepCheck(0.1, "updaterate") or not Entity.IsAlive(hero) then return end
	local dust = NPC.GetItem(hero, "item_dust", true)
	if not dust or not Ability.IsReady(dust) or not Ability.IsCastable(dust, 0) then return end
	local target = AutoDust.FindTarget(hero, dust)
	 if not target or target == 0 then return end
	-- not target then return end
	if (NPC.IsEntityInRange(hero, target, 1000) and not NPC.IsChannellingAbility(hero) and not NPC.HasModifier(target, "modifier_truesight") and not NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_INVISIBLE)) and not NPC.HasModifier(target,"modifier_riki_tricks_of_the_trade_phase") or (NPC.HasModifier(hero, AutoDust.Modifiers[12])) then
	--Log.Write(NPC.GetUnitName(target))
	Ability.CastNoTarget(dust)	
	AutoDust.Sleep(0.1, "updaterate");
	end
		for i=1,  #AutoDust.Unique do
			local timeLeft = AutoDust.Unique[i].endTime - os.clock()
            if timeLeft < 0 then
            table.remove(AutoDust.Unique, i)
			 elseif AutoDust.Unique[i].enemy and NPC.IsPositionInRange(hero, AutoDust.Unique[i].position, 1000) and not NPC.IsChannellingAbility(hero) and not NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_INVISIBLE) then
			 Ability.CastNoTarget(dust)	
			 AutoDust.Sleep(0.1, "updaterate");
			end
		end
			for i = 1, Heroes.Count() do
                local TAhero = Heroes.Get(i)
			    local TA = NPC.GetUnitName(TAhero)=="npc_dota_hero_templar_assassin"
			    if TA and NPC.IsEntityInRange(hero, TAhero, 1000) and (Entity.GetHealth(TAhero)/Entity.GetMaxHealth(TAhero)<0.3) and not NPC.IsChannellingAbility(hero) and not NPC.HasModifier(TAhero, "modifier_truesight") and not NPC.IsIllusion(TAhero) and not Entity.IsSameTeam(hero, TAhero) and not NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_INVISIBLE) then
			    Ability.CastNoTarget(dust)	
			    AutoDust.Sleep(0.1, "updaterate");
			    end
			end	
end

function AutoDust.FindTarget(me, item)
	local entities = Heroes.GetAll()
	for index=1, #entities do
		local enemyhero = Heroes.Get(index)
		if not Entity.IsSameTeam(me, enemyhero)  and not NPC.IsIllusion(enemyhero) and Entity.GetHeroesInRadius(me, Menu.GetValue(AutoDust.Range),enemyhero) then
			local isNotValid = AutoDust.CheckForModifiers(enemyhero)
			local isPosValid = AutoDust.CheckForPositiveModifiers(enemyhero)
			if not isNotValid and isPosValid then return enemyhero end
		end
	end
end
--NegativeModifiers
function AutoDust.CheckForModifiers(target)
	 for i=1,#AutoDust.Modifiers do
		if NPC.HasModifier(target, AutoDust.Modifiers[i]) then
			return false
		end
	end
	return true	

end
--PositiveModifiers
function AutoDust.CheckForPositiveModifiers(target)
	 for i=1,#AutoDust.ModifiersAllies do
		if NPC.HasModifier(target, AutoDust.ModifiersAllies[i]) then
			return false
		end
	end
	return true	

end

function AutoDust.SleepCheck(delay, id)
	if not AutoDust.sleepers[id] or (os.clock() - AutoDust.sleepers[id]) > delay then
		return true
	end
	return false
end

function AutoDust.Sleep(delay, id)
	if not AutoDust.sleepers[id] or AutoDust.sleepers[id] < os.clock() + delay then
		AutoDust.sleepers[id] = os.clock() + delay
	end
end

return AutoDust

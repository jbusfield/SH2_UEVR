local uevrUtils = require('libs/uevr_utils')
local controllers = require('libs/controllers')
local configui = require("libs/configui")
local reticule = require("libs/reticule")
local hands = require('libs/hands')
local attachments = require('libs/attachments')
local input = require('libs/input')
local pawnModule = require('libs/pawn')
local montage = require('libs/montage')
local interaction = require('libs/interaction')
local ui = require('libs/ui')
local remap = require('libs/remap')
local gestures = require('libs/gestures')
local gunstock = require('libs/gunstock')
local ik = require('libs/ik')
local accessories = require('libs/accessories')
local mathLib = require('libs/core/math_lib')
local melee = require('melee')

--uevrUtils.setLogLevel(LogLevel.Debug)
--uevrUtils.setDeveloperMode(true)
--hands.enableConfigurationTool()
--uevrUtils.profiler:toggle(true)

ui.init()
--ui.setRequireWidgetOpenState(true)
ui.setRequireWidgetVisibility(true)
montage.init()
interaction.init()
attachments.init()
reticule.init()
reticule.setHiddenWhenScopeActive(true)
pawnModule.init()
remap.init()
input.init()
gunstock.showConfiguration()
ik.init()

attachments.setGunstockOffsetsEnabled(false)
hands.setGunstockOffsetsEnabled(true)
ik.setGunstockOffsetsEnabled(true)

-- hands.setAutoCreateHands(false)
-- ik.setAutoCreateArms(false)

local settings = {}
local status = {}
local desiredManualSaveSlots = 200
local RaytracingMode = {
	Off = 0,
	On = 1,
	ForceOn = 2,
}
local HandsType = {
	None = 1,
	Forearms = 2,
	IKArms = 3,
}

local TraversalType = {
	Undefined = 0,
	Crawl = 1,
	Squeeze = 2,
	Vault = 3,
	Climb = 4,
}


local versionTxt = "v1.0.0"
local title = "Silent Hill 2 First Person Mod " .. versionTxt
local configDefinition = {
	{
		panelLabel = "Silent Hill 2 Config",
		saveFile = "sh2_config",
		layout = spliceableInlineArray
		{
			{ widgetType = "text", id = "title", label = title },
			{ widgetType = "indent", width = 20 }, { widgetType = "text", label = "Control" }, { widgetType = "begin_rect", },
                {
                    widgetType = "combo",
                    id = "movement_type",
                    label = "Forward Movement Direction",
                    selections = {"Game (no roomscale)", "Follows Head"},
                    initialValue = 2,
                },
                {
                    widgetType = "combo",
                    id = "handedness_type",
                    label = "Handedness",
                    selections = {"Left", "Right"},
                    initialValue = 2,
					isHidden = true,
                },
                {
                    widgetType = "combo",
                    id = "hands_type",
                    label = "Hands Type",
                    selections = {"None", "Forearms", "IK Arms"},
                    initialValue = 1,
                },
                {
                    widgetType = "combo",
                    id = "light_type",
                    label = "Light Location",
                    selections = {"Head", "OffHand", "Weapon"},
                    initialValue = 1,
                },
                {
					widgetType = "checkbox",
					id = "use_snap_turn",
					label = "Use Snap Turn",
					initialValue = false
				},
				{ widgetType = "indent", width = 20 }, 
					{
						widgetType = "drag_int",
						id = "snap_turn_angle",
						label = "Angle",
						speed = 1,
						range = {1, 360},
						initialValue = 30,
					},
				{ widgetType = "unindent", width = 20 },
                {
					widgetType = "checkbox",
					id = "hide_head",
					label = "Hide Head",
					initialValue = false
				},
                {
					widgetType = "checkbox",
					id = "offhand_grip_weapon",
					label = "Offhand Can Grip Weapon",
					initialValue = true
				},
                {
					widgetType = "checkbox",
					id = "enable_raytracing",
					label = "Enable Raytracing",
					initialValue = false
				},
				{ widgetType = "indent", width = 20 }, { widgetType = "begin_group", id = "fix_no_raytracing_visual_glitches_group" },
					{
						widgetType = "checkbox",
						id = "fix_no_raytracing_visual_glitches",
						label = "Fix Visual Glitches",
						initialValue = true
					},
					{ widgetType = "same_line" },
					{
						widgetType = "drag_int",
						id = "fix_visual_glitch_seconds",
						label = "Interval (secs)",
						speed = 1,
						range = {1, 100},
						initialValue = 20,
						width = 50
					},
				{ widgetType = "end_group" }, { widgetType = "unindent", width = 20 },
                {
					widgetType = "checkbox",
					id = "fix_orbit_camera_offset",
					label = "Fix Orbit Camera Offset",
					initialValue = false,
					isHidden = true,
				},
                {
                    widgetType = "drag_float",
                    id = "camera_relative_rotation",
                    label = "Camera Relative Rotation",
                    speed = 1,
                    range = {-180, 180},
                    initialValue = 0,
                    isHidden = true,
                },
			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			{ widgetType = "new_line" },
			{ widgetType = "indent", width = 20 }, { widgetType = "text", label = "Interaction" }, { widgetType = "begin_rect", },
				{
					widgetType = "combo",
					id = "interaction_control_mode",
					label = "Interaction Controls",
					selections = {"Vanilla", "Mixed"}, --, "Full Immersion"},
					initialValue = 1,
				},
				{
					widgetType = "combo",
					id = "interaction_sprint_mode",
					label = "Sprint",
					selections = {"Left Thumbstick Press", "Left Thumbstick Press Toggled", "Left Thumbstick Double Tap Forward"},
					initialValue = 2,
				},
				{ widgetType = "begin_group", id = "interaction_desc_advanced_group" },
					{
						widgetType = "text",
						label = "    Turn around - double tap left stick down"
					},
					{
						widgetType = "text",
						label = "    Dodge - right stick down + left stick direction"
					},
					{
						widgetType = "text",
						label = "    Toggle Flashlight - left trigger"
					},
					{
						widgetType = "text",
						label = "    Put Flashlight on Head/Retrieve Flashlight - left grip head just above HMD"
					},
				{ widgetType = "end_group"},
			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			{ widgetType = "new_line" },
			{ widgetType = "indent", width = 20 }, { widgetType = "text", label = "UI" }, { widgetType = "begin_rect", },
				expandArray(ui.getConfigurationWidgets),
			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			{ widgetType = "new_line" },
			{ widgetType = "indent", width = 20 }, { widgetType = "text", label = "Reticule" }, { widgetType = "begin_rect", },
				expandArray(reticule.getConfigurationWidgets,{{id="uevr_reticule_update_distance", initialValue=200}, {id="uevr_reticule_eye_dominance_offset", initialValue=63.0, isHidden=false}}),
			{ widgetType = "end_rect", additionalSize = 12, rounding = 5 }, { widgetType = "unindent", width = 20 },
			{ widgetType = "new_line" },
		}
	}
}

--increase the number of save game slots
local function applySaveSlotLimit()
	local saveGameSettings = uevrUtils.find_default_instance("Class /Script/GameBase.SaveGameSettings")
	if saveGameSettings == nil then
		return
	end

	print("Current max save slots", saveGameSettings.MaxSaveSlotsNumber)

	local autoSaveSlots = saveGameSettings.AutoSaveSlotsNumber or 0
	local targetMaxSlots = desiredManualSaveSlots + autoSaveSlots
	if saveGameSettings.MaxSaveSlotsNumber ~= targetMaxSlots then
		saveGameSettings.MaxSaveSlotsNumber = targetMaxSlots
		print("Updated manual save slots to", desiredManualSaveSlots, "total slots", targetMaxSlots)
	end
end

applySaveSlotLimit()

local function getGameUserSettings()
	if status.gameUserSettings ~= nil and uevrUtils.getValid(status.gameUserSettings) ~= nil then
		return status.gameUserSettings
	end

	local gameUserSettingsClass = uevrUtils.find_default_instance("Class /Script/Engine.GameUserSettings")
	if gameUserSettingsClass ~= nil and gameUserSettingsClass.GetGameUserSettings ~= nil then
		status.gameUserSettings = gameUserSettingsClass:GetGameUserSettings()
	end

	if status.gameUserSettings == nil then
		status.gameUserSettings = (uevrUtils.find_all_of("Class /Script/GameBase.BGameUserSettings", false) or {})[1]
	end

	return uevrUtils.getValid(status.gameUserSettings)
end

local function getPlayerProfile()
	if status.playerProfile ~= nil and uevrUtils.getValid(status.playerProfile) ~= nil then
		return status.playerProfile
	end

	local world = uevrUtils.getWorld()
	if world == nil then
		return nil
	end

	status.gameBaseStatics = status.gameBaseStatics or uevrUtils.find_default_instance("Class /Script/GameBase.GameBaseStatics")
	if status.gameBaseStatics ~= nil and status.gameBaseStatics.GetPlayerProfile ~= nil then
		status.playerProfile = status.gameBaseStatics:GetPlayerProfile(world)
	end

	return uevrUtils.getValid(status.playerProfile)
end

local function savePlayerProfile()
	local world = uevrUtils.getWorld()
	if world == nil then
		return false
	end

	status.gameBaseStatics = status.gameBaseStatics or uevrUtils.find_default_instance("Class /Script/GameBase.GameBaseStatics")
	if status.gameBaseStatics == nil or status.gameBaseStatics.SaveUserProfile == nil then
		return false
	end

	status.gameBaseStatics:SaveUserProfile(world)
	return true
end

local function setSprintToggleEnabled(enabled, saveProfile)
	local playerProfile = getPlayerProfile()
	if playerProfile == nil then
		return false
	end

	playerProfile.SprintToggleable = enabled == true

	if saveProfile ~= false then
		savePlayerProfile()
	end

	return true
end

local function applyRaytracingMode(mode, updateSettings)
	local raytracingMode = mode
	if raytracingMode == nil then raytracingMode = RaytracingMode.Off end

	local enabled = raytracingMode ~= RaytracingMode.Off

	if updateSettings == true then
		local playerProfile = getPlayerProfile()
		if playerProfile ~= nil and playerProfile.GFXSettings ~= nil then
			local profileSettings = playerProfile.GFXSettings
			profileSettings.Raytracing = raytracingMode
			playerProfile.GFXSettings = profileSettings
		end

		local gameUserSettings = getGameUserSettings()
		if gameUserSettings ~= nil and gameUserSettings.GFXSettings ~= nil then
			local gfxSettings = gameUserSettings.GFXSettings
			gfxSettings.Raytracing = raytracingMode
			gameUserSettings.GFXSettings = gfxSettings
			if gameUserSettings.ApplyNonResolutionSettings ~= nil then
				gameUserSettings:ApplyNonResolutionSettings()
			end
			if gameUserSettings.SaveSettings ~= nil then
				gameUserSettings:SaveSettings()
			end
		end

		status.rendererSettings = status.rendererSettings or uevrUtils.find_default_instance("Class /Script/Engine.RendererSettings")
		if status.rendererSettings ~= nil then
			status.rendererSettings.bEnableRayTracing = enabled
			status.rendererSettings.bUseHardwareRayTracingForLumen = enabled
		end
	end

	uevrUtils.set_cvar_int("r.RayTracing", enabled and 1 or 0)
	uevrUtils.set_cvar_int("r.Lumen.HardwareRayTracing", enabled and 1 or 0)
	uevrUtils.set_cvar_int("r.Lumen.Reflections.HardwareRayTracing", enabled and 1 or 0)
	uevrUtils.set_cvar_int("r.LumenScene.Radiosity.HardwareRayTracing", enabled and 1 or 0)
	uevrUtils.set_cvar_int("r.Lumen.RadianceCache.HardwareRayTracing", enabled and 1 or 0)

	return raytracingMode
end

local function cleanup()
    status = {}
end

local function regenerateHands(value)
    hands.setAutoCreateHands(value == HandsType.Forearms)
    ik.setAutoCreateArms(value == HandsType.IKArms)

    hands.destroyHands()
    ik.destroyAll()
end

ik.registerOnMeshCreatedCallback(function(meshComponentList, ikInstance)
     for i, meshComponent in ipairs(meshComponentList or {}) do
		--These hide the arms but not the shadows and flashlight is still blocked even with arms hidden
		-- meshComponent:SetRenderInMainPass(false)
		-- meshComponent:SetRenderInDepthPass(false)
		-- meshComponent:SetVisibility(false)

		--uncomment this to have the arms not cast shadows (and not block the flashlight)
		--meshComponent.bCastDynamicShadow = false
     end
end)
ik.registerOnDestroyCallback(function(ikInstance)
	--detach attachments first so they dont get "lost" when hands are destroyed
	attachments.detachGripAttachments(Handed.Right)
	attachments.detachGripAttachments(Handed.Left)
end)

hands.registerOnDestroyCallback(function()
	--detach attachments first so they dont get "lost" when hands are destroyed
	attachments.detachGripAttachments(Handed.Right)
	attachments.detachGripAttachments(Handed.Left)
end)

local function hideHead(val)
	if uevrUtils.getValid(pawn,{"Mesh"}) ~= nil then
		if val and configui.getValue("hide_head") == true then
			pawn.Mesh:HideBoneByName(uevrUtils.fname_from_string("neck_02_bn"), 0)
		else
			pawn.Mesh:UnHideBoneByName(uevrUtils.fname_from_string("neck_02_bn"))
		end
	else
		delay(2000, function() hideHead(val) end)
	end
end
configui.onCreateOrUpdate("hide_head", function(value)
    hideHead(value)
end)

configui.onCreateOrUpdate("hands_type", function(value)
    regenerateHands(value)
end)

function on_cutscene_change(isInCutscene)
    pawnModule.hideArmsBones(not isInCutscene)
    hideHead(not isInCutscene)
	melee.disable(isInCutscene)
end

local function getHandedNess()
	local handednessType = configui.getValue("handedness_type")
	if handednessType == 1 then
		return Handed.Left
	elseif handednessType == 2 then
		return Handed.Right
	end
	return Handed.Right
end

local function resetAttachment()
	local attachmentData = attachments.getCurrentGrippedAttachmentData(getHandedNess())
	if attachmentData ~= nil and attachmentData.attachment ~= nil and attachmentData.attachment.RelativeLocation ~= nil and attachmentData.attachment.RelativeLocation.X == 0 and attachmentData.attachment.RelativeLocation.Y == 0 and attachmentData.attachment.RelativeLocation.Z == 0 then
		local loc, rot, scale = attachments.getAttachmentOffset(attachmentData.attachment)
		local attachmentID = attachments.getAttachmentIDFromAttachment(attachmentData.attachment)
		attachments.updateAttachmentTransform(loc, rot, scale, attachmentID)
	end
end

local function attachLightToController(light)
	if uevrUtils.getValid(light) ~= nil then
		if configui.getValue("light_type") == 1 then
			local lightState = UEVR_UObjectHook.get_or_add_motion_controller_state(light)
			lightState:set_hand(2) -- head
			lightState:set_permanent(false)
			lightState:set_rotation_offset(temp_vec3f:set(0.0, 0.0, 0.0))
			lightState:set_location_offset(temp_vec3f:set(0.0, 0.0, 0.0))
		elseif configui.getValue("light_type") == 2 then
			UEVR_UObjectHook.remove_motion_controller_state(light)
			local lightState = UEVR_UObjectHook.get_or_add_motion_controller_state(light)
			lightState:set_hand(1-getHandedNess()) -- off hand
			lightState:set_permanent(false)
			lightState:set_rotation_offset(temp_vec3f:set(0.38, -0.59, 0.0))
			lightState:set_location_offset(temp_vec3f:set(-2.4, -6.8, -0.8))
			status.lightState = lightState
		elseif configui.getValue("light_type") == 3 then
			UEVR_UObjectHook.remove_motion_controller_state(light)
			local lightState = UEVR_UObjectHook.get_or_add_motion_controller_state(light)
			lightState:set_hand(getHandedNess()) -- off hand
			lightState:set_permanent(false)
			lightState:set_rotation_offset(temp_vec3f:set(0.13, 0.265, 0.0))
			lightState:set_location_offset(temp_vec3f:set(-2.4, -8.9, -0.8))
			status.lightState = lightState
		end
	end
end

local function getFlashlightMesh()
    if pawn == nil then return nil end

	if status.flashlight ~= nil and status.flashlight.flashlightMesh ~= nil and uevrUtils.getValid(status.flashlight.flashlightMesh) ~= nil then
		return status.flashlight.flashlightMesh
	end

	local equipmentActors = uevrUtils.getValid(pawn, {"Items", "EquipmentActors"})
	if equipmentActors ~= nil then
		for _, actor in ipairs(equipmentActors) do
			if actor:is_a(uevrUtils.get_class("Class /Script/SHProto.SHFlashlight")) then
				status.flashlight = {}
				status.flashlight.flashlightMesh = actor.Mesh

				local light = actor.LightMain
				if light ~= nil then
					attachLightToController(light)
				end
				status.flashlight.lightMesh = light

				local lightShaft = actor.Lightshaft
				if lightShaft ~= nil then
					lightShaft:SetRenderInMainPass(false)
					-- lightShaft:K2_AttachTo(status.flashlight.flashlightMesh, uevrUtils.fname_from_string(""), 0, false)
					-- uevrUtils.set_component_relative_transform(lightShaft, uevrUtils.vector(configui.getValue("light_shaft_location")), uevrUtils.rotator(configui.getValue("light_shaft_rotation")))
				end
				status.flashlight.lightShaftMesh = lightShaft

				return status.flashlight.flashlightMesh
			end
		end
	end
    return nil
end

local function getWeaponMesh()
    local equippedWeapon = uevrUtils.getValid(pawn, {"Mesh", "AnimScriptInstance", "WeaponManageCmbSubcomp", "EquippedWeapon"})
	if equippedWeapon ~= nil then
		if equippedWeapon.AutoAimMaxRange ~= nil then
			equippedWeapon.AutoAimMaxRange = 1.0
		end
		local weaponName = equippedWeapon:get_full_name()
		if uevrUtils.startsWith(weaponName, "WeaponPistol") then
			status.currentReticuleOffset = 3
		elseif uevrUtils.startsWith(weaponName, "WeaponShotgun") then
			status.currentReticuleOffset = 5
		elseif uevrUtils.startsWith(weaponName, "WeaponRifle") then
			status.currentReticuleOffset = 6
		end
		--print("Equipped weapon", equippedWeapon:get_full_name())
	end

	local weaponMesh = uevrUtils.getValid(equippedWeapon, {"Mesh"})

	status.currentEquippedWeapon = equippedWeapon


    if weaponMesh == nil then
        --try to get investigation items
        weaponMesh = uevrUtils.getValid(pawn, {"Items", "ItemExecutive", "ItemContext", "Mesh"})
		if weaponMesh ~= status.currentWeaponMesh then
			-- if weaponMesh ~= nil then
			-- 	print("New Weapon mesh found", weaponMesh:get_full_name(), weaponMesh.StaticMesh and weaponMesh.StaticMesh:get_full_name() or "no static mesh", weaponMesh.SkeletalMesh and weaponMesh.SkeletalMesh:get_full_name() or "no skeletal mesh")
			-- end
			status.currentWeaponMesh = weaponMesh
			status.updateAttachmentTransform = true
			delay(1000, function()
				status.updateAttachmentTransform = false
			end)
		end
    end
    return weaponMesh
end

local function getEquippedWeapon(currentPawn)
	return uevrUtils.getValid(currentPawn, {"Mesh", "AnimScriptInstance", "WeaponManageCmbSubcomp", "EquippedWeapon"})
end

local defaultAttachOptions = {
	detachFromOriginOnGrip = true,
	maintainWorldPositionOnDetachFromOrigin = false,
	detachFromParentOnRelease = true,
	maintainWorldPositionOnDetachFromParent = false,
	reattachToOriginOnRelease = true,
	restoreTransformToOriginOnReattach = true,
	useZeroTransformOnReattach = false,
	allowChildVisibilityHandling = false,
	allowChildHiddenInGameHandling = false,
	allowRenderInMainPassHandling = false,
}

attachments.registerOnGripUpdateCallback(function()
	if uevrUtils.isInCutscene() then return nil end

    local weaponMesh = getWeaponMesh()
	local flashlightMesh = getFlashlightMesh()
	if configui.getValue("light_type") == 1 or configui.getValue("light_type") == 3 then
		flashlightMesh = nil
	end
	accessories.setDisabled(not configui.getValue("offhand_grip_weapon") or flashlightMesh ~= nil)

    local rightHandComponent = nil
   	local leftHandComponent = nil
    if configui.getValue("hands_type") == HandsType.None then
        rightHandComponent = controllers.getController(Handed.Right)
        leftHandComponent = controllers.getController(Handed.Left)
    elseif configui.getValue("hands_type") == HandsType.Forearms then
        rightHandComponent = hands.getHandComponent(Handed.Right)
        leftHandComponent = hands.getHandComponent(Handed.Left)
    elseif configui.getValue("hands_type") == HandsType.IKArms then
        rightHandComponent = ik.getCurrentMesh()
		leftHandComponent = ik.getCurrentMesh()
    end

    local weaponAttachSocket = "hand_r_bn" 
	local flashlightAttachSocket = "hand_l_bn"
    --print( weaponMesh, rightHandComponent, weaponAttachSocket, flashlightMesh, leftHandComponent, flashlightAttachSocket)
    return rightHandComponent and weaponMesh, rightHandComponent, weaponAttachSocket, leftHandComponent and flashlightMesh, flashlightMesh and leftHandComponent, flashlightAttachSocket, defaultAttachOptions --, controllers.getController(Handed.Right)
end)

local snapTurnState = {
	rxState = 0,
	deadZone = 20000,
}

local smoothTurnState = {
	deadZone = 4000,
	degreesPerSecond = 180,
}

local leftStickDoubleTapState = {
	forward = {
		isPressed = false,
		lastTapTime = nil,
		pressThreshold = 24000,
		releaseThreshold = 18000,
	},
	backward = {
		isPressed = false,
		lastTapTime = nil,
		pressThreshold = -20000,
		releaseThreshold = -12000,
	},
	doubleTapWindow = 0.35,
}

local fixedOrbitCameraPitch = -20.0

local function getLocalPawn()
	local currentPawn = uevrUtils.get_local_pawn()
	if uevrUtils.getValid(currentPawn) == nil then
		return nil
	end
	return currentPawn
end

local function isPawnTraversing(currentPawn)
	if currentPawn == nil then
		return false
	end

	local activeTraversal = uevrUtils.getValid(currentPawn, {"Traversal", "CurrentlyPlayingTraversal"})
	if activeTraversal == nil then
		return false
	end
	print("Active traversal type", activeTraversal.Type)
	return activeTraversal.Type == TraversalType.Vault or activeTraversal.Type == TraversalType.Climb
end

local function applyFaceAwayFromCamera(currentPawn)
	if currentPawn == nil or currentPawn.View == nil or currentPawn.Movement == nil then
		return
	end

	local viewRotation = currentPawn.View:GetViewRotation()
	if viewRotation == nil then
		return
	end

	local yawOffset = configui.getValue("camera_relative_rotation") or 0
	local targetRotation = uevrUtils.rotator(0, viewRotation.Yaw + yawOffset, 0)
	currentPawn.Movement:RotationSnapAbsoluteStatic(targetRotation, 0.0, currentPawn, nil)
end

local function handleSnapTurnInput(state)
	if configui.getValue("use_snap_turn") ~= true then
		snapTurnState.rxState = 0
		return
	end

	if state == nil or state.Gamepad == nil then
		snapTurnState.rxState = 0
		return
	end

	local currentPawn = getLocalPawn()
	if currentPawn == nil or currentPawn.View == nil then
		snapTurnState.rxState = 0
		return
	end

	local thumbRX = state.Gamepad.sThumbRX or 0
	local turnStep = nil
	if thumbRX >= snapTurnState.deadZone then
		state.Gamepad.sThumbRX = 0
		if snapTurnState.rxState == 0 then
			turnStep = configui.getValue("snap_turn_angle") or 30
			snapTurnState.rxState = 1
		end
	elseif thumbRX <= -snapTurnState.deadZone then
		state.Gamepad.sThumbRX = 0
		if snapTurnState.rxState == 0 then
			turnStep = -(configui.getValue("snap_turn_angle") or 30)
			snapTurnState.rxState = -1
		end
	else
		snapTurnState.rxState = 0
	end

	if turnStep == nil or currentPawn.View.GetViewRotation == nil or currentPawn.View.OverrideControlRotation == nil then
		return
	end

	local viewRotation = currentPawn.View:GetViewRotation()
	if viewRotation == nil then
		return
	end

	if status.turnStep == nil then status.turnStep = 0 end
	status.turnStep = status.turnStep + turnStep
end

local function handleSmoothTurnInput(state)
	if configui.getValue("use_snap_turn") == true then
		status.turnAxisX = 0
		return
	end

	if state == nil or state.Gamepad == nil then
		status.turnAxisX = 0
		return
	end

	local thumbRX = state.Gamepad.sThumbRX or 0
	if math.abs(thumbRX) < smoothTurnState.deadZone then
		status.turnAxisX = 0
		return
	end

	status.turnAxisX = thumbRX / 32767.0
	state.Gamepad.sThumbRX = 0
end

local function getLeftStickDoubleTapDirection(state)
	if state == nil or state.Gamepad == nil then
		leftStickDoubleTapState.forward.isPressed = false
		leftStickDoubleTapState.backward.isPressed = false
		return false, false
	end

	local thumbLY = state.Gamepad.sThumbLY or 0
	local currentTime = os.clock()
	local wasTappedForward = false
	local wasTappedBackward = false

	local isPressedForward = thumbLY >= leftStickDoubleTapState.forward.pressThreshold
	local isReleasedForward = thumbLY <= leftStickDoubleTapState.forward.releaseThreshold
	if isPressedForward and not leftStickDoubleTapState.forward.isPressed then
		leftStickDoubleTapState.forward.isPressed = true
		if leftStickDoubleTapState.forward.lastTapTime ~= nil and currentTime - leftStickDoubleTapState.forward.lastTapTime <= leftStickDoubleTapState.doubleTapWindow then
			leftStickDoubleTapState.forward.lastTapTime = nil
			wasTappedForward = true
		else
			leftStickDoubleTapState.forward.lastTapTime = currentTime
		end
	elseif isReleasedForward then
		leftStickDoubleTapState.forward.isPressed = false
	end

	local isPressedBackward = thumbLY <= leftStickDoubleTapState.backward.pressThreshold
	local isReleasedBackward = thumbLY >= leftStickDoubleTapState.backward.releaseThreshold
	if isPressedBackward and not leftStickDoubleTapState.backward.isPressed then
		leftStickDoubleTapState.backward.isPressed = true
		if leftStickDoubleTapState.backward.lastTapTime ~= nil and currentTime - leftStickDoubleTapState.backward.lastTapTime <= leftStickDoubleTapState.doubleTapWindow then
			leftStickDoubleTapState.backward.lastTapTime = nil
			wasTappedBackward = true
		else
			leftStickDoubleTapState.backward.lastTapTime = currentTime
		end
	elseif isReleasedBackward then
		leftStickDoubleTapState.backward.isPressed = false
	end

	return wasTappedForward, wasTappedBackward
end

--wont callback unless an uevrUtils.updateDeferral("is_gripping_light") hasnt been called in the last 300ms
uevrUtils.createDeferral("is_gripping_light", 300, function()
    status["isGrippingLight"] = false
end)

uevrUtils.registerOnPreInputGetStateCallback(function(retval, user_index, state)
    if not ui.isRemapDisabled() then
        if state.Gamepad.sThumbRY < -20000 then
            uevrUtils.pressButton(state, XINPUT_GAMEPAD_B)
        end
        state.Gamepad.sThumbRY = 0 --disable pitching the orbiting camera

	    handleSnapTurnInput(state)
		handleSmoothTurnInput(state)

		if configui.getValue("interaction_control_mode") == 2 then
			local handed = getHandedNess()
			local isEating, isGrabbingGlasses, gripHead, isGrabbingEar, triggerMouth, isScratchingEyes, triggerHead, isScratchingEar = gestures.getHeadGestures(state, 1-handed, false)
			local isEatingRight, isGrabbingGlassesRight, gripHeadRight, isGrabbingEarRight, triggerMouthRight, isScratchingEyesRight, triggerHeadRight, isScratchingEarRight = gestures.getHeadGestures(state, handed, false)

			local sprintMode = configui.getValue("interaction_sprint_mode")
			local wasTappedForward, wasTappedBackward = getLeftStickDoubleTapDirection(state)
			local leftGripPressed = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
			local rightGripPressed = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
			local leftStickPressed = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_LEFT_THUMB)
			local rightStickPressed = uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_THUMB)
			local leftTriggerPressed = state.Gamepad.bLeftTrigger >= 128
			if (sprintMode == 3 and wasTappedForward) or ((sprintMode == 1 or sprintMode == 2) and leftStickPressed) then --leftStickPressed then
				uevrUtils.pressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
			else
				uevrUtils.unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
			end

			if wasTappedBackward then
				uevrUtils.pressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
			else
				uevrUtils.unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
    		end

			--flashlight
			if gripHead and status["isGrippingLight"] ~= true then
				configui.setValue("light_type", configui.getValue("light_type") == 1 and 2 or 1)
				status["isGrippingLight"] = true
			elseif gripHeadRight and status["isGrippingLight"] ~= true then
				configui.setValue("light_type", configui.getValue("light_type") == 1 and 3 or 1)
				status["isGrippingLight"] = true
			else
				if leftTriggerPressed then
					uevrUtils.pressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB)
				else
					uevrUtils.unpressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB)
				end
			end
			--prevent flapping between light states by only allowing grip to trigger light state change once every 300ms, the deferral will reset the "isGrippingLight" status after 300ms allowing it to be triggered again
			if gripHead or gripHeadRight then
				uevrUtils.updateDeferral("is_gripping_light")
			end
			-- end flashlight

			-- aim gun
			if rightGripPressed then
				state.Gamepad.bLeftTrigger = 255
			else
				state.Gamepad.bLeftTrigger = 0
			end
			--end aim

			if uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_SHOULDER) then
				status.turnStep = (status.turnStep or 0) + 180
			end

		elseif configui.getValue("interaction_control_mode") == 1 then
			--prevent continuous 180 turn in vanilla mode
			if uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_SHOULDER) then
				if status.lock180Turn ~= true then
					status.lock180Turn = true
					status.turnStep = (status.turnStep or 0) + 180
				end
			else
				status.lock180Turn = false
			end

		end

	end
end, 5)

configui.onCreateOrUpdate("use_snap_turn", function(enabled)
	snapTurnState.rxState = 0
	status.turnAxisX = 0
	status.lastViewRotationYaw = nil
	if enabled == true then
		uevrUtils.enableSnapTurn(false)
	end
	configui.setHidden("snap_turn_angle", enabled ~= true)
end)

--The normal handler for this is being overridden somehow
ui.registerWidgetChangeCallback("GameplayEndGame_WidgetBP_C", function(active)
	if active then
		delay(200, function()
			uevrUtils.fadeCamera(0.1, true)
		end)
	else
		uevrUtils.stopFadeCamera()
	end
end)

uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	local currentPawn = getLocalPawn()
	if currentPawn == nil then
		return
	end

	if not ui.isInputDisabled() then
		applyFaceAwayFromCamera(currentPawn)
	end

	local camera_overlap = currentPawn.CameraOverlapHandler
    if camera_overlap ~= nil then
        if camera_overlap:IsComponentTickEnabled() then
            camera_overlap:SetComponentTickEnabled(false) -- Stops camera from making pawn and other things near it invisible
            --print("Disabled camera overlap handler")
        end

        camera_overlap.OwnerCharacterPlay = nil -- Nulls out the owner actor, this stops some logic from functioning when we start aiming which hides the pawn
    end

	-- This is what the game uses to signify a cutscene is in progress
	if status.characterStatics == nil then
		status.characterStatics = uevrUtils.find_default_instance("Class /Script/SHProto.SHCharacterStatics")
	end
	if status.characterStatics ~= nil then
		local isInCutscene = status.characterStatics:IsCharacterInCutscene(currentPawn)
		if status.isInCutscene ~= isInCutscene then
			local skipNotify = status.isInCutscene == nil and isInCutscene == false --dont trigger cutscene state change on first tick if not in cutscene, in case another system thinks we are in a cutscene
			status.isInCutscene = isInCutscene
			if skipNotify == false then
				--print("Cutscene state changed from characterStatics", status.isInCutscene)
				uevrUtils.setIsInCutsceneOverride(status.isInCutscene)
				if status.isInCutscene == false then
					status.currentGameplayInputMode = 0
					if not ui.isFadeCameraEnabled() then
						uevrUtils.stopFadeCamera()
					end
				end
			end
		end
	else
		print("Could not find character statics for cutscene detection")
	end

	if currentPawn.GetGameplayInputMode ~= nil then
		local currentGameplayInputMode = currentPawn:GetGameplayInputMode()
		if status.currentGameplayInputMode ~= currentGameplayInputMode then
			status.currentGameplayInputMode = currentGameplayInputMode
			if uevrUtils.getValid(currentPawn, {"Items", "ItemExecutive"}) == nil and status.isPushing ~= true and status.isTraversing ~= true then
				--print("Cutscene state changed from GetGameplayInputMode", currentGameplayInputMode == 1, currentGameplayInputMode)
				uevrUtils.setIsInCutsceneOverride(currentGameplayInputMode == 1)
			end
		end
	end

	-- We have to disable roomscale movement during the "Pushing" animations or the game will prevent the task from ever being completed
	if currentPawn.Movement ~= nil then
		if status.isPushing ~= (currentPawn.Movement.PushableComponent ~= nil) then
			status.isPushing = (currentPawn.Movement.PushableComponent ~= nil)
			uevrUtils.setIsInCutsceneOverride(status.isPushing)
			if status.isPushing then
				status.isRoomscale = uevrUtils.getUEVRParam_bool("VR_RoomscaleMovement")
				uevrUtils.setUEVRParam("VR_RoomscaleMovement", "false")
			elseif status.isRoomscale ~= nil then
				uevrUtils.setUEVRParam("VR_RoomscaleMovement", status.isRoomscale == true and "true" or "false")
				status.isRoomscale = nil
			end
		end
	end

	--invincibility
	-- local health = uevrUtils.getValid(currentPawn, {"Health"})
	-- if health ~= nil then
	-- 	health.HealthValue = 100
	-- end

end)

--This gets the source location and rotation for the reticle. The game must internally handle the RegisteredFirePoint yaw offset when firing
--because just using the raw rotation doesn't work for reticule aiming and must be offset manually
reticule.registerCustomTargetCallback(function()
	if uevrUtils.getValid(status.currentEquippedWeapon) ~= nil and status.currentEquippedWeapon.RootComponent ~= nil and status.currentEquippedWeapon.RootComponent.K2_GetComponentLocation ~= nil and status.currentEquippedWeapon.RegisteredFirePoint ~= nil then
		local loc = status.currentEquippedWeapon.RootComponent:K2_GetComponentLocation()
		local rot = status.currentEquippedWeapon.RootComponent:K2_GetComponentRotation()
		local offsetYaw = status.currentEquippedWeapon.RegisteredFirePoint.RelativeRotation
		rot = mathLib.composeRotators(uevrUtils.rotator(offsetYaw.Pitch, offsetYaw.Yaw + 90, offsetYaw.Roll), rot)

		local vector = uevrUtils.rotateVector(uevrUtils.vector(0,0,status.currentReticuleOffset or 0), rot)
		loc = loc + vector

		return loc, rot
	end
	return uevrUtils.vector(0,0,0), uevrUtils.rotator(0,0,0)
end)

uevr.sdk.callbacks.on_post_engine_tick(function(engine, delta)
	local currentPawn = getLocalPawn()
	if currentPawn == nil then
		return
	end

	-- The game tries to change the relative offset of attachments for a short period during activation so this overrides that
	if status.updateAttachmentTransform == true then
		resetAttachment()
	end

	--This is what aims the ranged weapons
	if uevrUtils.getValid(status.currentEquippedWeapon) ~= nil and status.currentEquippedWeapon.RootComponent ~= nil and status.currentEquippedWeapon.RootComponent.K2_SetWorldLocation ~= nil then
		local location, rotation = attachments.getActiveAttachmentTransforms(getHandedNess())
		status.currentEquippedWeapon.RootComponent:K2_SetWorldLocation(location, false, reusable_hit_result, false)
		status.currentEquippedWeapon.RootComponent:K2_SetWorldRotation(rotation, false, reusable_hit_result, false)
	end

    if currentPawn.View ~= nil and not ui.isViewLocked() then
		uevr.params.vr.get_pose(uevr.params.vr.get_hmd_index(), temp_vec3f, temp_quatf)
		local poseQuat = uevrUtils.quat(temp_quatf.Z, temp_quatf.X, -temp_quatf.Y, -temp_quatf.W)  --reordered terms to convert UEVR to unreal coord system
		local hmdRotation = kismet_math_library:Quat_Rotator(poseQuat)

		status.currentHMDYaw = hmdRotation.Yaw
		uevr.params.vr.recenter_view()

		if configui.getValue("movement_type") == 1 then
			status.currentHMDYaw = 0
		end

		local turnDelta = 0
		if configui.getValue("use_snap_turn") then
			turnDelta = (status.turnStep or 0)
		else
			if status.turnStep == nil then
				status.turnStep = 0
			end
			status.turnStep = status.turnStep + ((status.turnAxisX or 0) * smoothTurnState.degreesPerSecond * (delta or 0))
			turnDelta = status.turnStep or 0
		end

		local deltaRotation = turnDelta - (status.currentHMDYaw or 0)
		currentPawn.View:OverrideControlRotation(
			uevrUtils.rotator(hmdRotation.Pitch, deltaRotation, hmdRotation.Roll), -- Pitch required for item indicators
			currentPawn
		)
	end

end)

setInterval(200, function()
    local springArm = uevrUtils.getValid(pawn, {"SpringArm"})
    if springArm ~= nil then
        springArm.bEnableCameraLag = configui.getValue("enable_spring_arm_lag")
        springArm.bEnableCameraRotationLag = configui.getValue("enable_spring_arm_rotationlag")
    end

	-- currently vaulting and climbing (not ladder)
	local isTraversing = isPawnTraversing(pawn)
	if status.isTraversing ~= isTraversing then
		local skipNotify = status.isTraversing == nil and isTraversing == false
		status.isTraversing = isTraversing
		if skipNotify == false then
			--print("Cutscene state changed from isTraversing", status.isInCutscene)
			uevrUtils.setIsInCutsceneOverride(status.isTraversing)
			if status.isTraversing == false then status.currentGameplayInputMode = 0 end
		end
	end
end)


local function getBlendDataOverride()
	local blendData = uevrUtils.get_struct_object("ScriptStruct /Script/SHProto.SHBlendData")
	if blendData == nil then
		return nil
	end

	blendData.BlendInTime = 0.0
	blendData.BlendInAlphaCurve = nil
	blendData.BlendOutTime = 0.0
	blendData.BlendOutAlphaCurve = nil
	return blendData
end


local function buildCenteredCameraData(sourceData)
	if sourceData == nil or sourceData.BlendData == nil then
		return nil
	end

	local blendData = getBlendDataOverride()
	if blendData == nil then
		return nil
	end

	local cameraData = uevrUtils.get_struct_object("ScriptStruct /Script/SHProto.SHCameraDataStruct")
	if cameraData == nil then
		return nil
	end

	cameraData.BlendData = blendData
	cameraData.ArmLengthFromPitchCurve = sourceData.ArmLengthFromPitchCurve
	cameraData.SocketOffsetFromPitchCurve = nil
	cameraData.TargetOffset = uevrUtils.vector(0, -45, sourceData.TargetOffset and sourceData.TargetOffset.Z or 0)
	cameraData.TargetOffsetExtraHeightFromPitchScale = sourceData.TargetOffsetExtraHeightFromPitchScale or 1.0
	cameraData.MovementForwardCameraLag = sourceData.MovementForwardCameraLag or 0.0
	cameraData.MovementNonForwardCameraLag = sourceData.MovementNonForwardCameraLag or 0.0
	cameraData.RotationLag = sourceData.RotationLag or 0.0
	return cameraData
end

local function getActiveCameraBlender(currentPawn)
	if currentPawn == nil or currentPawn.SpringArm == nil or currentPawn.View == nil then
		return nil
	end

	local viewRotation = currentPawn.View:GetViewRotation()
	if viewRotation == nil then
		return nil
	end

	local targetArmLength = currentPawn.SpringArm.TargetArmLength
	if targetArmLength == nil then
		return nil
	end

	local candidates = {
		currentPawn.SpringArm.InteriorCameraBlender,
		currentPawn.SpringArm.ExteriorSprintCameraBlender,
		currentPawn.SpringArm.InteriorSprintCameraBlender,
	}

	local bestBlender = nil
	local bestDiff = nil
	for _, blender in ipairs(candidates) do
		if blender ~= nil and blender.CameraData ~= nil and blender.CameraData.ArmLengthFromPitchCurve ~= nil then
			local curveValue = blender.CameraData.ArmLengthFromPitchCurve:GetFloatValue(viewRotation.Pitch)
			--local curveValue = blender.CameraData.ArmLengthFromPitchCurve:GetFloatValue(fixedOrbitCameraPitch)
			if curveValue ~= nil then
				local diff = math.abs(curveValue - targetArmLength)
				if bestDiff == nil or diff < bestDiff then
					bestDiff = diff
					bestBlender = blender
				end
			end
		end
	end

	return bestBlender
end

local function centerOrbitCamera(currentPawn)
	if currentPawn == nil or currentPawn.SpringArm == nil then
		return
	end

	local activeBlender = getActiveCameraBlender(currentPawn)
	if activeBlender == nil or activeBlender.CameraData == nil or activeBlender.CollisionData == nil then
		return
	end

	local centeredCameraData = buildCenteredCameraData(activeBlender.CameraData)
	local centeredCollisionData = buildCenteredCameraData(activeBlender.CollisionData)
	if centeredCameraData == nil or centeredCollisionData == nil then
		return
	end

	currentPawn.SpringArm:SetCustomCameraData(currentPawn, "CopilotCenteredOrbit", centeredCameraData, centeredCollisionData)
	currentPawn.SpringArm:RequestRefreshState(currentPawn)
end

local function fixRaytrace()
	if configui.getValue("enable_raytracing") ~= true and configui.getValue("fix_no_raytracing_visual_glitches") == true then
		applyRaytracingMode(RaytracingMode.On)
		delay(500, function()
			applyRaytracingMode(RaytracingMode.Off)
		end)
	end
end

function on_level_change(level)
    cleanup()
	applySaveSlotLimit()
    regenerateHands(configui.getValue("hands_type") or 1)
    hideHead(true)
	delay(3000, fixRaytrace)
	if configui.getValue("fix_orbit_camera_offset") == true then
		centerOrbitCamera(pawn)
	end
	accessories.setDisabled(configui.getValue("offhand_grip_weapon") == false)
end


-- local currentOverride = false
-- register_key_bind("F1", function()
-- 	currentOverride = not currentOverride
-- 	uevrUtils.setIsInCutsceneOverride(currentOverride)
-- end)
register_key_bind("F2", function()
	print("F2 pressed")
	pawn:K2_AddActorLocalOffset(uevrUtils.vector(100,0,0), false, reusable_hit_result, true)
end)
-- local isPaused = false
-- register_key_bind("F3", function()
-- 	isPaused = not isPaused
-- 	uevrUtils.pauseGame(isPaused)
-- end)
-- register_key_bind("F4", function()
-- 	uevrUtils.profiler:report()
-- end)
-- register_key_bind("F1", function()
-- 	ending_selector.select("inwater") -- "leave" / "inwater" / "maria"
-- 	print("Set Ending to inwater")
-- end)

--When raytracing is off there can be mismatched lighting in both eyes. 
--This forces a renderer reset every 20 seconds to help mitigate that issue. 
--This is only needed when raytracing is disabled, so it will not run if the user has enabled raytracing in the settings.
--setInterval(20000,fixRaytrace)
--configui.getValue("fix_visual_glitch_seconds")
local function onRaytracingVisualGlitchTimer()
	local delaySeconds = configui.getValue("fix_visual_glitch_seconds") or 20
	if configui.getValue("fix_no_raytracing_visual_glitches") == true then
		fixRaytrace()
	else
		delaySeconds = 5
	end
	delay(delaySeconds * 1000, onRaytracingVisualGlitchTimer)
end
onRaytracingVisualGlitchTimer()

configui.onCreateOrUpdate("enable_raytracing", function(value)
	applyRaytracingMode(value == true and RaytracingMode.On or RaytracingMode.Off, true)
	configui.setHidden("fix_no_raytracing_visual_glitches_group", value)
	if value == false and configui.getValue("fix_no_raytracing_visual_glitches") == true then
		fixRaytrace()
	end
end)

configui.onCreateOrUpdate("fix_no_raytracing_visual_glitches", function(value)
	configui.setHidden("fix_visual_glitch_seconds", not value)
	if value == true then
		fixRaytrace()
	end
end)

configui.onCreateOrUpdate("interaction_sprint_mode", function(value)
	setSprintToggleEnabled(value == 2 or value == 3, true)
end)

configui.onCreateOrUpdate("interaction_control_mode", function(value)
	configui.setHidden("interaction_sprint_mode", value == 1)
	configui.setHidden("interaction_desc_advanced_group", value == 1)
end)

configui.onUpdate("light_type", function(value)
	--print("Light type changed, reattaching light")
	local light = uevrUtils.getValid(status.flashlight and status.flashlight.lightMesh)
	attachLightToController(light)
end)

configui.onCreateOrUpdate("offhand_grip_weapon", function(value)
	accessories.setDisabled(value == false)
end)

configui.create(configDefinition)



--The following code courtesy of Praydog
local LegacyCameraShake_c = uevrUtils.find_required_object("Class /Script/GameplayCameras.LegacyCameraShake")

-- Disable camera shake 1
local BlueprintUpdateCameraShake = LegacyCameraShake_c and LegacyCameraShake_c:find_function("BlueprintUpdateCameraShake")

if BlueprintUpdateCameraShake ~= nil then
    BlueprintUpdateCameraShake:set_function_flags(BlueprintUpdateCameraShake:get_function_flags() | 0x400) -- Mark as native
    BlueprintUpdateCameraShake:hook_ptr(function(fn, obj, locals, result)
        obj.ShakeScale = 0.0
        return false
    end)
end

-- Disable camera shake 2
local ReceivePlayShake = LegacyCameraShake_c and LegacyCameraShake_c:find_function("ReceivePlayShake")

if ReceivePlayShake ~= nil then
    ReceivePlayShake:set_function_flags(ReceivePlayShake:get_function_flags() | 0x400) -- Mark as native
    ReceivePlayShake:hook_ptr(function(fn, obj, locals, result)
        obj.ShakeScale = 0.0
        return false
    end)
end

uevr.sdk.callbacks.on_script_reset(function()
    print("Resetting")

    if BlueprintUpdateCameraShake ~= nil then
        BlueprintUpdateCameraShake:set_function_flags(BlueprintUpdateCameraShake:get_function_flags() & ~0x400) -- Unmark as native
    end

    if ReceivePlayShake ~= nil then
        ReceivePlayShake:set_function_flags(ReceivePlayShake:get_function_flags() & ~0x400) -- Unmark as native
    end

end)
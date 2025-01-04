-- This code implements a command in FiveM (GTA V multiplayer mod) that allows a player character to be “leashed” to another player using a rope. 
-- When another player is within a certain range, the player can create a tether and attach it to the target player. 
-- The leash is displayed visually and the player is attached to the target player with a rope animation. 
-- The command is primarily used for role-playing scenarios in which, for example, dogs are leashed to their owners. 
-- The code also contains a function for removing the leash if it is already active.
-- Creator and copyright by @Vedschyburger
-- My Github: https://github.com/Vedschyburger

local leashed = false  -- Tracks if the player is currently leashed
local targetPlayer = nil  -- Stores the player being leashed
local leashObject = nil  -- Stores the leash object
local ropeHandle = nil  -- Stores the rope handle
local leashDistance = 5.0  -- Maximum distance for leashing (in meters)

-- Register the leash command
RegisterCommand("leine", function()
    local playerPed = PlayerPedId()  -- Get the player's character (ped)
    local playerCoords = GetEntityCoords(playerPed)  -- Get the player's current coordinates
    local closestPlayer, closestDistance = GetClosestPlayer()  -- Find the closest player and their distance

    -- Check if there is a player nearby within 3 meters
    if closestPlayer ~= -1 and closestDistance < 3.0 then
        targetPlayer = GetPlayerPed(closestPlayer)  -- Get the ped of the closest player
        local targetCoords = GetEntityCoords(targetPlayer)  -- Get the target player's coordinates
        local distanceToTarget = #(playerCoords - targetCoords)  -- Calculate the distance to the target player

        -- Check if the target is within leash distance
        if distanceToTarget <= leashDistance then
            if not leashed then
                -- Start the leashing process
                RequestModel("prop_leash")  -- Request the leash model
                while not HasModelLoaded("prop_leash") do
                    Wait(500)  -- Wait until the model is loaded
                end
                
                -- Create the leash object
                leashObject = CreateObject(GetHashKey("prop_leash"), 0, 0, 0, true, true, true)
                -- Attach the leash to the player's hand (bone index 57005 is the right hand)
                AttachEntityToEntity(leashObject, playerPed, GetPedBoneIndex(playerPed, 57005), 0.4, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                
                -- Create a rope between the player and the target
                ropeHandle = AddRope(GetEntityCoords(playerPed), 0, 0, 0, 5.0, 4, 5.0, 0.1, 0.1, false, false, false, 1.0, false, 0)
                -- Attach the rope to the leash and the target player
                AttachRopeToEntity(ropeHandle, leashObject, 0, 0, 0, true)
                AttachRopeToEntity(ropeHandle, targetPlayer, 0, 0, 0, true)
                
                -- Attach the player to the target player (leashing action)
                AttachEntityToEntity(playerPed, targetPlayer, 0, 0.5, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                StartLeashAnimation(playerPed)  -- Start leash animation
                ESX.ShowNotification("Du hast die Leine angebracht.")  -- Show notification that leash is applied
                leashed = true  -- Mark as leashed
            else
                -- Unleash process
                DetachEntity(playerPed, true, true)  -- Detach the player from the target
                if DoesEntityExist(leashObject) then
                    DeleteObject(leashObject)  -- Delete the leash object if it exists
                end
                if DoesRopeExist(ropeHandle) then
                    DeleteRope(ropeHandle)  -- Delete the rope if it exists
                end
                ClearPedTasksImmediately(playerPed)  -- Clear player tasks (animations)
                ESX.ShowNotification("Die Leine wurde entfernt.")  -- Show notification that leash is removed
                leashed = false  -- Mark as unleashed
            end
        else
            -- Show notification if the target is too far away
            ESX.ShowNotification("Der Hund ist zu weit entfernt, um angeleint zu werden.")
        end
    else
        -- Show notification if no player is nearby
        ESX.ShowNotification("Kein Hund in der Nähe.")
    end
end, false)

-- Function to start the leash animation
function StartLeashAnimation(ped)
    RequestAnimDict("amb@world_human_stand_fishing@idle_a")  -- Request the animation dictionary
    while not HasAnimDictLoaded("amb@world_human_stand_fishing@idle_a") do
        Wait(100)  -- Wait until the animation dictionary is loaded
    end
    -- Play the animation
    TaskPlayAnim(ped, "amb@world_human_stand_fishing@idle_a", "idle_c", 8.0, 1.0, -1, 49, 0, false, false, false)
end

-- Function to get the closest player
function GetClosestPlayer()
    local players = GetActivePlayers()  -- Get list of all active players
    local closestDistance = -1  -- Initialize closest distance
    local closestPlayer = -1  -- Initialize closest player
    local playerPed = PlayerPedId()  -- Get the player's ped
    local playerCoords = GetEntityCoords(playerPed)  -- Get the player's coordinates

    -- Loop through all players to find the closest one
    for i = 1, #players, 1 do
        local targetPed = GetPlayerPed(players[i])  -- Get the target player's ped
        if targetPed ~= playerPed then  -- Skip the current player
            local targetCoords = GetEntityCoords(targetPed)  -- Get target player's coordinates
            local distance = #(playerCoords - targetCoords)  -- Calculate distance to the target player

            -- Update closest player if this one is closer
            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = players[i]
                closestDistance = distance
            end
        end
    end

    return closestPlayer, closestDistance  -- Return closest player and distance
end
-- Uses modern GroupService role APIs instead of deprecated single-rank calls.

local GroupService = game:GetService("GroupService")

local PlayerPermissionsModule = {}

local function HasRankInGroupFunctionFactory(groupId, requiredRank)
    assert(type(requiredRank) == "number", "requiredRank must be a number")

    local hasRankCache = {}

    return function(player)
        if not player or player.UserId <= 0 then
            return false
        end

        if hasRankCache[player.UserId] == nil then
            local hasRank = false

            local success, result = pcall(function()
                return GroupService:GetRolesInGroupAsync(player.UserId, groupId)
            end)

            if success and result and result.IsMember then
                for _, role in ipairs(result.Roles or {}) do
                    if tonumber(role.Rank) and role.Rank >= requiredRank then
                        hasRank = true
                        break
                    end
                end
            end

            hasRankCache[player.UserId] = hasRank
        end

        return hasRankCache[player.UserId]
    end
end

local function IsInGroupFunctionFactory(groupId)
    local inGroupCache = {}

    return function(player)
        if not player or player.UserId <= 0 then
            return false
        end

        if inGroupCache[player.UserId] == nil then
            local inGroup = false
            local success, result = pcall(function()
                return player:IsInGroupAsync(groupId)
            end)

            if success then
                inGroup = result == true
            end

            inGroupCache[player.UserId] = inGroup
        end

        return inGroupCache[player.UserId]
    end
end

PlayerPermissionsModule.IsPlayerAdminAsync = IsInGroupFunctionFactory(1200769)
PlayerPermissionsModule.IsPlayerInternAsync = HasRankInGroupFunctionFactory(2868472, 100)

return PlayerPermissionsModule
local resource_key = KEYS[1]
local resource_key_base = ARGV[1]
local sim_key_base = ARGV[2]
local group_key_base = ARGV[3]
local threshold = tonumber(ARGV[4])

local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

redis.log(redis.LOG_NOTICE, 'Running similarity for ' .. resource_key)

local resource = resource_key:gsub('%' .. resource_key_base .. ':', '')
local groups = redis.call('smembers', resource_key)
local group_keys = {}
for _,group in ipairs(groups) do
    table.insert(group_keys, group_key_base .. ':' .. group)
end
--redis.log(redis.LOG_NOTICE, 'Found ' .. table.getn(group_keys) .. ' group keys')

local resources = {}
local step = 100
for i = 1, #group_keys, step do
    local some_resources = redis.call('sunion', unpack(group_keys, i, math.min(i + step - 1, #group_keys)))
    for k,v in pairs(some_resources) do table.insert(resources, v) end
end
table.sort(resources)

--local resources = redis.call('sunion', unpack(group_keys))
redis.log(redis.LOG_NOTICE, 'Found ' .. table.getn(resources) .. ' resources')

local previous = 'foo'
for _,to_compare in ipairs(resources) do
--    redis.log(redis.LOG_NOTICE, 'Comparing ' .. resource .. ' and ' .. to_compare)
    if to_compare ~= previous then
        previous = to_compare
        if resource > to_compare then
--          redis.log(redis.LOG_NOTICE, 'Calculating similarity for ' .. resource .. ' and ' .. to_compare)
            local intersect = table.getn(redis.call('SINTER', resource_key, resource_key_base .. ':' .. to_compare))
            if intersect > 0 then
                local union = table.getn(redis.call('SUNION', resource_key, resource_key_base .. ':' .. to_compare))
                local similarity = round(intersect / union, 3)
                if similarity > threshold then
--                  redis.log(redis.LOG_NOTICE, resource .. ' and ' .. to_compare .. ' scored ' .. similarity)
                    redis.call('ZADD', sim_key_base .. ':' .. resource, similarity, to_compare)
                    redis.call('ZADD', sim_key_base .. ':' .. to_compare, similarity, resource)
                end
            end
        end
    end
end

redis.log(redis.LOG_NOTICE, 'Finished running similarity for ' .. resource_key)

return true
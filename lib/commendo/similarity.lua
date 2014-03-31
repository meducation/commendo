local root_key = KEYS[1]
local sim_key = KEYS[2]
local set_key_base = ARGV[1]
local threshold = tonumber(ARGV[2])

redis.log(redis.LOG_NOTICE, 'Running similarity for ' .. root_key)
local key_matches = redis.call('KEYS', set_key_base .. ':*')

redis.call('DEL', sim_key)
local count = 0
-- local similar = {}
for _,key in ipairs(key_matches) do
    if key ~= root_key then
        count = count + 1
        local intersect = table.getn(redis.call('SINTER', root_key, key))
        if intersect > 0 then
            local union = table.getn(redis.call('SUNION', root_key, key))
            local similarity = intersect / union
            if similarity > threshold then
                -- table.insert(similar, key)
                -- table.insert(similar, similarity)
                local resource = key:gsub('%' .. set_key_base .. ':', '')
                redis.call('ZADD', sim_key, similarity, resource)
            end
        end
    end
end

-- redis.call('HMSET', sim_key, unpack(similar))
redis.log(redis.LOG_NOTICE, 'Finished running similarity for ' .. root_key)
return true
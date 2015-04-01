local resource_key = KEYS[1]
local tmp_key_base = ARGV[1]
local resource_key_base = ARGV[2]
local sim_key_base = ARGV[3]
local group_key_base = ARGV[4]
local threshold = tonumber(ARGV[5])

local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

redis.log(redis.LOG_NOTICE, 'Running complete similarity for ' .. resource_key)

local resource = resource_key:gsub('%' .. resource_key_base .. ':', '')
local groups = redis.call('ZRANGE', resource_key, 0, -1)

if table.getn(groups) > 999 then
    redis.log(redis.LOG_NOTICE, 'Complete similarity too large for ' .. resource_key .. ', ' .. table.getn(groups))
	return 999
end

local group_keys = {}
for _,group in ipairs(groups) do
    table.insert(group_keys, group_key_base .. ':' .. group)
end
--redis.log(redis.LOG_NOTICE, 'Found ' .. table.getn(group_keys) .. ' group keys')

--TODO change unionfoo to a random slug
local tmp_groups_union_key = tmp_key_base .. 'unionfoo'
redis.call('ZUNIONSTORE', tmp_groups_union_key, table.getn(group_keys), unpack(group_keys))
local resources = redis.call('ZRANGE', tmp_groups_union_key, 0, -1)

--TODO change 'foo' to something much more unlikely
local previous = 'foo'
for _,to_compare in ipairs(resources) do
    --redis.log(redis.LOG_NOTICE, 'Comparing ' .. resource .. ' and ' .. to_compare)
    if to_compare ~= previous then
        previous = to_compare
        if resource ~= to_compare then
          --redis.log(redis.LOG_NOTICE, 'Calculating similarity for ' .. resource .. ' and ' .. to_compare)

            --TODO change bar to a random slug
            local tmp_pair_intersect_key = tmp_key_base .. 'bar'
            redis.call('ZINTERSTORE', tmp_pair_intersect_key, 2, resource_key, resource_key_base .. ':' .. to_compare)
            local intersect = redis.call('ZRANGE', tmp_pair_intersect_key, 0, -1, 'WITHSCORES')
            redis.call('DEL', tmp_pair_intersect_key)

            if table.getn(intersect) > 0 then
                local intersect_score = 0
                for i=1,#intersect,2 do
                    intersect_score = intersect_score + intersect[i+1]
                end

                --TODO change baz to a random slug
                local tmp_pair_union_key = tmp_key_base .. 'baz'
                redis.call('ZUNIONSTORE', tmp_pair_union_key, 2, resource_key, resource_key_base .. ':' .. to_compare)

                local union = redis.call('ZRANGE', tmp_pair_union_key, 0, -1, 'WITHSCORES')
                redis.call('DEL', tmp_pair_union_key)
                local union_score = 0
                for i=1,#union,2 do
                    union_score = union_score + union[i+1]
                end

                local similarity = round(intersect_score / union_score, 3)
                if similarity > threshold then
                  --redis.log(redis.LOG_NOTICE, resource .. ' and ' .. to_compare .. ' scored ' .. similarity)
                    redis.call('ZADD', sim_key_base .. ':' .. resource, similarity, to_compare)
                  --redis.call('ZADD', sim_key_base .. ':' .. to_compare, similarity, resource)
                end
            end
        end
    end
end

redis.call('DEL', tmp_groups_union_key)

redis.log(redis.LOG_NOTICE, 'Finished running complete similarity for ' .. resource_key)

return true





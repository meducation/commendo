local left_key = KEYS[1]
local right_key = KEYS[2]
local left_similarity_key = KEYS[3]
local right_similarity_key = KEYS[4]

local tmp_key_base = ARGV[1]
local left = tonumber(ARGV[2])
local right = tonumber(ARGV[3])
local threshold = tonumber(ARGV[4])

local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

redis.log(redis.LOG_NOTICE, 'Running pair comparison for ' .. left_key .. ' ' .. right_key)


--TODO change bar
local tmp_pair_intersect_key = tmp_key_base .. 'bar'
redis.call('ZINTERSTORE', tmp_pair_intersect_key, 2, left_key, right_key)
local intersect = redis.call('ZRANGE', tmp_pair_intersect_key, 0, -1, 'WITHSCORES')
redis.call('DEL', tmp_pair_intersect_key)

if table.getn(intersect) > 0 then
    local intersect_score = 0
    for i=1,#intersect,2 do
        intersect_score = intersect_score + intersect[i+1]
    end

    --TODO change baz
    local tmp_pair_union_key = tmp_key_base .. 'baz'
    redis.call('ZUNIONSTORE', tmp_pair_union_key, 2, left_key, right_key)

    local union = redis.call('ZRANGE', tmp_pair_union_key, 0, -1, 'WITHSCORES')
    redis.call('DEL', tmp_pair_union_key)
    local union_score = 0
    for i=1,#union,2 do
        union_score = union_score + union[i+1]
    end

    local similarity = round(intersect_score / union_score, 3)
    if similarity > threshold then
        redis.call('ZADD', left_similarity_key, similarity, right)
        redis.call('ZADD', right_similarity_key, similarity, left)
    end
end

redis.log(redis.LOG_NOTICE, 'Finished running pair comparison for ' .. left_key .. ' ' .. right_key)

return true
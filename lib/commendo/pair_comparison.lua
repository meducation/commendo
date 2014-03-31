local left_key = KEYS[1]
local right_key = KEYS[2]
local left_similarity_key = KEYS[3]
local right_similarity_key = KEYS[4]

local left = tonumber(ARGV[1])
local right = tonumber(ARGV[2])
local threshold = tonumber(ARGV[3])

local function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

redis.log(redis.LOG_NOTICE, 'Running pair comparison for ' .. left_key .. ' ' .. right_key)

local intersect = table.getn(redis.call('SINTER', left_key, right_key))
if intersect > 0 then
    local union = table.getn(redis.call('SUNION', left_key, right_key))
    local similarity = round(intersect / union, 3)
    if similarity > threshold then
        redis.call('ZADD', left_similarity_key, similarity, right)
        redis.call('ZADD', right_similarity_key, similarity, left)
    end
end

redis.log(redis.LOG_NOTICE, 'Finished running pair comparison for ' .. left_key .. ' ' .. right_key)

return true
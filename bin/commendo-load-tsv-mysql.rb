#!/usr/bin/env ruby

require 'redis'
require 'commendo'
require 'progressbar'

filename = ARGV[0]
key_base = ARGV[1]

Commendo.config do |config|
  config.backend = :mysql
  config.host = 'localhost'
  config.port = 3306
  config.database = 'commendo_test'
  config.username = 'commendo'
  config.password = 'commendo123'
end
client = Mysql2::Client.new(Commendo.config.to_hash)
client.query("DELETE FROM Resource WHERE keybase='#{key_base}';")
cs = Commendo::ContentSet.new(key_base: key_base)

puts 'Loading.'
file_length = `wc -l #{filename}`.to_i
pbar = ProgressBar.new('Loading TSV file', file_length)
File.open(filename) do |f|
  f.each_line do |line|
    pbar.inc
    ids = line.strip.split("\t")
    resource = ids.shift
    cs.add(resource, *ids)
  end
end
pbar.finish
puts "\nFinished loading"

# puts 'Calculating similarities'
# # pbar = nil
# cs.calculate_similarity do |key, i, total|
#   pbar ||= ProgressBar.new('Calculating similarity', total)
#   # pbar.inc
#   $stderr.puts key
# end
# pbar.finish

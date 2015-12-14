#!/usr/bin/env ruby

require 'redis'
require 'commendo'
require 'progressbar'

key_base = ARGV[0]
limit = ARGV[1].to_i

Commendo.config do |config|
  config.backend = :mysql
  config.host = 'localhost'
  config.port = 3306
  config.database = 'commendo_test'
  config.username = 'commendo'
  config.password = 'commendo123'
end
cs = Commendo::ContentSet.new(key_base: key_base)

$stderr.puts "Selecting #{limit} random names to use"
client = Mysql2::Client.new(Commendo.config.to_hash)
names_to_query = client.query("SELECT DISTINCT name FROM Resources WHERE keybase = '#{key_base}' ORDER BY RAND() LIMIT #{limit}")
names_to_query = names_to_query.map { |r| r['name'] }

pbar = ProgressBar.new('Querying similar_to', names_to_query.length)
names_to_query.each do |name|
  cs.similar_to(name)
  pbar.inc
end
pbar.finish


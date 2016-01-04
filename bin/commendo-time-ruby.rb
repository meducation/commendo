#!/usr/bin/env ruby

require 'redis'
require 'commendo'
require 'progressbar'

def timer(msg)
  start = Time.now
  value = yield
  finish = Time.now
  $stderr.puts "#{msg} took #{finish - start}"
  return value
end

infile = ARGV[0]
key_base = ARGV[1]
limit = ARGV[2].to_i

Commendo.config do |config|
  config.backend = :ruby
end
cs = Commendo::ContentSet.new(key_base: key_base)

resource_to_sets = nil
timer('Loading') do
  lines = File.open(infile).readlines
  resource_to_sets = lines.map { |line| line.strip!; line = line.split("\t"); r = line.shift; [r, line] }
  resource_to_sets.each do |resource, sets|
    cs.add(resource, *sets)
  end
end

timer('calculate_similarity') do
  cs.calculate_similarity
end

names_to_query = timer("Select #{limit} random names to use") do
  resource_to_sets.map { |resource, sets| resource }.sort_by { rand }.first(limit)
end

# pbar = ProgressBar.new('Querying similar_to', names_to_query.length)
names_to_query.each do |name|
  timer('Similarity') { cs.similar_to(name) }
  # pbar.inc
end
# pbar.finish


require 'bundler/gem_tasks'
require 'rake/testtask'
require 'redis'
require 'commendo'

task :test do
  $LOAD_PATH.unshift('lib', 'test')
  Dir.glob('./test/**/*_test.rb') { |f| require f }
end

task default: :test

def tick i, total = nil
  if i % 100 == 0
    print " #{(i / total.to_f).round(2)} " unless total.nil?
    print '.' if total.nil?
    $stdout.flush
  end
end

task :load_traffic_from_tsv, :filename do |task, args|

  puts "Loading item views from #{args[:filename]}"
  redis = Redis.new(db: 10)
  cs = Commendo::ContentSet.new(redis, 'CommendoScale')
  #redis.flushdb
  #start = Time.now
  #views = []
  #current_resource = nil
  #File.open(args[:filename]) do |f|
  #  f.each_line.with_index do |tsv, i|
  #    next if i.zero?
  #    tick i
  #    tsv.chomp!
  #    item_type, item_id, user_id, ip_address = tsv.split(/\t/)
  #    user_id = user_id != 'NULL' ? user_id : ip_address
  #    next if user_id == 'NULL'
  #    resource = "#{item_type.gsub(/:+/, '_')}-#{item_id}"
  #    if not resource == current_resource
  #      cs.add(current_resource, *views) unless (views.empty? || views.length > 100)
  #      current_resource = resource
  #      views = []
  #    end
  #    views << user_id unless views.include? user_id
  #  end
  #end

  puts 'Processing...'
  cs.calculate_similarity(0.1999999999) { |count, key|
    puts key
  }
end



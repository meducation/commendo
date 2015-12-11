require 'forwardable'
require 'mysql2'
require_relative 'mysql2/client'
require 'redis'

require 'commendo/configuration'
require 'commendo/version'
require 'commendo/content_set'
require 'commendo/tag_set'
require 'commendo/weighted_group'

require 'commendo/redis-backed/content_set'
require 'commendo/redis-backed/tag_set'
require 'commendo/redis-backed/weighted_group'

require 'commendo/mysql-backed/content_set'
require 'commendo/mysql-backed/tag_set'
require 'commendo/mysql-backed/weighted_group'

module Commendo

  def self.config
    config = @@config ||= Configuration.new
    yield(config) if block_given?
    config
  end

  def self.config=(config)
    raise 'Configuration must be either a Commendo::Configuration object or nil to reset' unless config.nil? || config.is_a?(Configuration)
    @@config = config
  end

end

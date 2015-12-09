gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/mock'
require 'mocha/setup'
require 'commendo'

module Commendo

  class ConfigurationTest < Minitest::Test

    def setup
      Commendo.config = nil
    end

    def test_default_values_on_configuration_class
      assert_equal :redis, Commendo::Configuration.new.backend
      assert_equal 'localhost', Commendo::Configuration.new.host
      assert_equal 6379, Commendo::Configuration.new.port
      assert_equal 15, Commendo::Configuration.new.database
      assert_nil Commendo::Configuration.new.user
      assert_nil Commendo::Configuration.new.password
    end

    def test_returns_same_object_each_time
      config1 = Commendo.config
      config2 = Commendo.config
      config3 = Commendo.config
      assert config1.equal? config2
      assert config2.equal? config3
    end

    def test_config_returns_default_configuration
      config = Commendo.config
      assert config.is_a? Commendo::Configuration
      assert_equal :redis, config.backend
      assert_equal 'localhost', config.host
      assert_equal 6379, config.port
      assert_equal 15, config.database
      assert_nil config.user
      assert_nil config.password
    end

    def test_configure_stores_settings
      config = Commendo.config do |config|
        config.backend = :mysql
        config.host = 'mysql.example.com'
        config.port = 9999
        config.database = 'some_mysql_db'
        config.user = 'root'
        config.password = 'Passw0rd!!'
      end

      assert config.is_a? Commendo::Configuration
      assert_equal :mysql, config.backend
      assert_equal 'mysql.example.com', config.host
      assert_equal 9999, config.port
      assert_equal 'some_mysql_db', config.database
      assert_equal 'root', config.user
      assert_equal 'Passw0rd!!', config.password
    end

  end

end
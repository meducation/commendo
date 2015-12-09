module Commendo
  class Configuration

    attr_accessor :backend, :host, :port, :database, :user, :password

    def initialize
      @backend = :redis
      @host = 'localhost'
      @port = 6379
      @database = 15
    end

  end
end

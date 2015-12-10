module Commendo
  class Configuration

    attr_accessor :backend, :host, :port, :database, :username, :password

    def initialize
      @backend = :redis
      @host = 'localhost'
      @port = 6379
      @database = 15
    end

    def to_hash
      {
          backend: backend,
          host: host,
          port: port,
          database: database,
          username: username,
          password: password
      }
    end

  end
end

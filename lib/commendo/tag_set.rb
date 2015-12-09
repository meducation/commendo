module Commendo
  class TagSet
    extend Forwardable

    def_delegators :@backend, :empty?, :get, :add, :set, :matches, :delete, :redis, :key_base

    def initialize(type, args)
      @backend = RedisBacked::TagSet.new(args[:redis], args[:key_base]) if type == :redis
      raise 'Unrecognised backend type, try :redis or :mysql' if @backend.nil?
    end


  end
end


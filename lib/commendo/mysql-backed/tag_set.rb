module Commendo
  module MySqlBacked
    class TagSet

      attr_accessor :mysql, :key_base

      def initialize(key_base)
        @mysql = Mysql2::Client.new(Commendo.config.to_hash)
        @key_base = key_base
      end

      def empty?
      end

      def get(resource)
      end

      def add(resource, *tags)
      end

      def set(resource, *tags)
        delete(resource)
        add(resource, *tags)
      end

      def matches(resource, include, exclude = [])
      end

      def delete(resource, *tags)
      end

    end
  end
end


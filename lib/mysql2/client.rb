module Mysql2
  class Client
    def transaction(&block)
      raise ArgumentError, 'No block was given' unless block_given?
      begin
        query('BEGIN')
        yield(self)
        query('COMMIT')
        return true # Successful Transaction
      rescue
        query('ROLLBACK')
        raise
        return false # Failed Transaction
      end
    end
  end
end
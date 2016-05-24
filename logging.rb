module Logging

 def logger
   Logging.logger
 end

 def self.logger
   @logger ||= Logger.new("log.log")
 end
end

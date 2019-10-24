class RailsRoutesExporter
  class Logger < ::Logger
    include Singleton

    def initialize
      super($stdout)

      self.formatter = proc do |severity, datetime, progname, msg|
        "#{msg}\n"
      end

      self.level = Logger::INFO
    end

    def set_debug(value)
      self.level = value ? Logger::DEBUG : Logger::INFO
    end

    module ClientHelper
      def self.included(base)
        base.extend(ClassMethods)
      end

      def log(level, message)
        message = "[#{level.to_s.upcase}] #{message}" unless level == :info
        logger = RailsRoutesExporter::Logger.instance
        logger.send(level, message)
      end

      module ClassMethods
        def log(level, message)
          message = "[#{level.to_s.upcase}] #{message}" unless level == :info
          logger = RailsRoutesExporter::Logger.instance
          logger.send(level, message)
        end
      end
    end
  end
end

require 'rails_routes_exporter/version'
require 'rails_routes_exporter/logger'

class RailsRoutesExporter
  include Logger::ClientHelper
  class Error < StandardError; end

  def self.configure
    yield(config)
  end

  def self.config
    @config ||= Configuration.new
  end

  def self.export(app_name)
    content = Rails.application.routes.routes.map { |route|
      wrapper = ActionDispatch::Routing::RouteWrapper.new(route)
      result = [wrapper.verb, wrapper.path]
      result = config.handler.call(result) if config.handler
      result
    }.select { |r| r && r.first.present? }.map { |route| route.join(' ') }.uniq.join("\n")

    key = File.join(config.key_prefix, app_name).to_s + '.route'
    log(:debug, "bucket: #{config.bucket}")
    log(:debug, "key: #{key}")

    s3.put_object(
      bucket: config.bucket,
      key: key,
      body: content,
    )
  end

  def self.s3
    @s3 ||= Aws::S3::Client.new
  end

  class Configuration
    def initialize
      @bucket = 'misc-internal.ap-northeast-1'
      @key_prefix = 'mpdev-console/request_summaries'
    end

    def bucket=(bucket)
      @bucket = bucket
    end

    def bucket
      @bucket
    end

    def key_prefix=(key_prefix)
      @key_prefix = key_prefix
    end

    def key_prefix
      @key_prefix
    end

    def handler=(handler)
      @handler = handler
    end

    def handler
      @handler
    end
  end
end

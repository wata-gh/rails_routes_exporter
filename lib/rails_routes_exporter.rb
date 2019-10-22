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
    routes = config.additional_routes

    unless config.use_only_defined_routes?
      dynamic_routes = Rails.application.routes.routes.map { |route|
        wrapper = ActionDispatch::Routing::RouteWrapper.new(route)
        result = [wrapper.verb, wrapper.path]

        config.ignores.each do |ignore|
          if wrapper.verb == ignore[0] && wrapper.path == ignore[1]
            result.append('IGNORE')
          end
        end

        result = config.handler.call(wrapper) if config.handler
        result
      }.select { |r| r && r.first.present? }

      routes.concat(dynamic_routes)
    end

    content = routes.map { |route| route.join(' ') }.uniq.join("\n")

    key = File.join(config.key_prefix, app_name).to_s + '.route'
    log(:debug, "bucket: #{config.bucket}")
    log(:debug, "key: #{key}")
    log(:debug, "content: #{content}")

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
      @ignores = []
      @additional_routes = []
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

    def use_default_ignore_routes
      @ignores.append(['GET', '/hello/revision(.:format)'])
    end

    def use_only_defined_routes
      @use_only_defined_routes = true
    end

    def use_only_defined_routes?
      @use_only_defined_routes
    end

    def add_ignore_route(verb, path)
      @ignores.append([verb, path])
    end

    def ignores
      @ignores.dup
    end

    def handler=(handler)
      @handler = handler
    end

    def handler
      @handler
    end

    def add_route(verb, path, option = nil)
      @additional_routes.append([verb, path, option].compact)
    end

    def additional_routes
      @additional_routes.dup
    end
  end
end

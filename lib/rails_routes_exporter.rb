require 'rails_routes_exporter/version'
require 'rails_routes_exporter/logger'
require 'aws-sdk-s3'
require 'diffy'

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
    exporter = RailsRoutesExporter.new(app_name)
    content = exporter.create_routes
    exporter.upload(content)
  end

  def self.dry_run(app_name)
    exporter = RailsRoutesExporter.new(app_name)
    current_content = exporter.download
    content = exporter.create_routes
    puts Diffy::Diff.new(current_content, content).to_s(:color)
  end

  def initialize(app_name)
    @app_name = app_name
  end

  def key
    @key ||= File.join(config.key_prefix, @app_name).to_s + '.route'
  end

  def download
    log(:debug, 'downloading routes')
    log(:debug, "bucket: #{config.bucket}")
    log(:debug, "key: #{key}")

    begin
      s3.get_object(
        bucket: config.bucket,
        key: key,
      ).body.read
    rescue Aws::S3::Errors::NoSuchKey => e
      log(:warn, "no routes file found. #{config.bucket}/#{key}")
      ''
    end
  end

  def upload(content)
    log(:debug, 'uploading routes')
    log(:debug, "bucket: #{config.bucket}")
    log(:debug, "key: #{key}")
    log(:debug, "content: #{content}")

    s3.put_object(
      bucket: config.bucket,
      key: key,
      body: content,
    )
  end

  def create_routes
    routes = config.additional_routes

    unless config.use_only_defined_routes?
      dynamic_routes = Rails.application.routes.routes.map { |route|
        wrapper = ActionDispatch::Routing::RouteWrapper.new(route)
        result = [wrapper.verb, wrapper.path]

        result = config.handler.call(wrapper) if config.handler
        next result unless result

        config.ignores.each do |ignore|
          if result.first(2) == ignore && result.length == 2
            result.append('IGNORE')
          end
        end

        result
      }.compact.select { |r| r.first.present? }

      routes.concat(dynamic_routes)
    end

    routes.map { |route| route.join(' ') }.uniq.join("\n")
  end

  private

  def config
    RailsRoutesExporter.config
  end

  def s3
    @s3 ||= Aws::S3::Client.new
  end

  class Configuration
    def initialize
      @bucket = nil
      @key_prefix = ''
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

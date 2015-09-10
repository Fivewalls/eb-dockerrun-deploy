module Eb
  module Dockerrun
    module Deploy
      class OptionParser
        attr_accessor :option_file, :working_path, :opts
        OPTIONS = %w(
          tag-name
          image-name
          auth-bucket-name
          auth-bucket-key
          container-port
          application-name
          env-name
          version-label
          version-desc
          bucket-name
          bucket-key
          aws-access-key-id
          aws-secret-access-key
          aws-region
          proxy-config
          dest
        )
        DEFAULT_PATH = './dockerrun.yml'

        def initialize(opt_hash={})
          @opts = {}
          file_opts = parse_opt_file(opt_hash['var-file'])
          OPTIONS.each do |option|
            if opt_hash.key?(option) && !opt_hash[option].nil?
              @opts[option] = opt_hash[option]
            elsif file_opts.key?(option)
              @opts[option] = file_opts[option]
            end
          end
          validate_options
        end

        def require_opts(*required)
          required.each do |option|
            fail OptionParserError, "The required option #{option} was not provided" unless opts.key?(option)
          end
        end

      private

        def parse_opt_file(file_path)
          file_path ||= DEFAULT_PATH
          file_path = File.expand_path(file_path)
          if File.exist?(file_path)
            self.option_file = file_path
            self.working_path = File.dirname(file_path)
            return YAML.load_file(file_path)
          end
          self.option_file = nil
          self.working_path = Dir.pwd
          {}
        end

        def validate_options
          opts['tag-name'] ||= 'latest'
          opts['container-port'] ||= '3000'
          opts['version-label'] ||= SecureRandom.uuid
          opts['bucket-key'] ||= opts['version-label']
          validate_auth
        end

        def validate_auth
          if opts.key?('auth-bucket-name') && !opts.key?('auth-bucket-key')
            fail OptionParserError, 'Must provide auth-bucket-key as well'
          end
          return unless opts.key?('auth-bucket-key') && !opts.key?('auth-bucket-name')
          fail OptionParserError, 'Must provide auth-bucket-name as well'
        end
      end

      class OptionParserError < StandardError; end
    end
  end
end

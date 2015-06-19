#!/usr/bin/env ruby
require 'thor'
require 'yaml'
require 'active_support/core_ext/hash/keys'
require 'json'
require 'aws-sdk'
require 'io'
require 'securerandom'

class Deploy < Thor
  REQUIRED_OPTIONS = ["tag-name", "image-name", "application-name", "env-name", "bucket-name", "bucket-key"]

  class_option "var-file",
    default: "./dockerrun.yml",
    type: :string,
    aliases: "f",
    desc: "File holding variables for deployment. Anything passed as an option to the command will override values here"
  class_option "tag-name",
    type: :string,
    aliases: "t",
    desc: "Tag for docker image to pull in. If not specified in file or as an option, will default to 'latest'"
  class_option "image-name",
    type: :string,
    aliases: "i",
    desc: "The name of the docker image to use"
  class_option "auth-bucket-name",
    type: :string,
    desc: "The s3 bucket name where the dockercfg file is stored, if required"
  class_option "auth-bucket-key",
    type: :string,
    desc: "The s3 key of the dockercfg file, if required. A bucket name must also be provided"
  class_option "container-port",
    type: :string,
    aliases: "p",
    desc: "The port exposed by the container. If not specified in file or as an option, will default to 3000"

  method_option "application-name",
    type: :string,
    aliases: "a",
    desc: "The name of the EB application. Must be provided in file or as an option"
  method_option "env-name",
    type: :string,
    aliases: "e",
    desc: "The name of the EB application environment to deploy. Must be provided in file or as an option"
  method_options "version-label",
    type: :string,
    desc: "The label for the version"
  method_options "version-desc",
    type: string,
    desc: "The description for the version"
  method_option "bucket-name",
    type: :string,
    aliases: "b",
    desc: "The S3 bucket where new application version should be stored. Must be provided in file or as an option"
  method_option "bucket-key",
    type: :string,
    aliases: "k",
    desc: "The S3 key to use when uploading application version.  Must be provided in file or as an option"
  method_option "aws-access-key-id",
    type: :string,
    desc: "The AWS access key. If not provided, will use stored credentials or environment variables"
  method_option "aws-secret-access-key",
    type: :string,
    desc: "The AWS secret access key. If not provided, will use stored credentials or environment variables"

  desc "deploy_single", "Deploy the EB dockerrun file"
  def deploy_single
    opts = parse_options
    STDOUT.puts "Creating source bundle..."
    build_zip(opts)
    STDOUT.puts "Creating app version..."
    create_app_version(opts)
    STDOUT.puts "Deploying app version..."
    deploy_app_version(opts)
    STDOUT.puts "Deployed!"
  end

  private

  def dockerrun_hash(opts)
    run_hash = {
      "AWSEBDockerrunVersion" => "1",
      "Image" => {
        "Name" => "#{opts["image-name"]}:#{opts["tag-name"]}",
        "Update" => "true"
      },
      "Ports" => [
        {
          "ContainerPort" => opts["container-port"]
        }
      ]
    }
    if opts["auth-bucket-name"]
      run_hash["Authentication"] = {
        "Bucket" => opts["auth-bucket-name"],
        "Key" => opts["auth-bucket-key"]
      }
    end

    run_hash
  end

  def parse_options
    opts = load_options_file(options["var-file"])
    options.each do |key, value|
      opts[key] = value unless value.nil?
    end
    validate_options(opts)
    return opts
  end

  def load_options_file(file)
    return {} unless File.exist?(file)
    YAML.load_file(file)
  end

  def validate_options(opts)
    opts["tag-name"] ||= "latest"
    opts["container-port"] ||= "3000"
    opts["version-label"] ||=  SecureRandom.uuid
    opts["bucket-key"] ||= opts["version-label"]
    validate_auth(opts)
  end

  def validate_auth(opts)
    abort "Must provide auth-bucket-key as well" if opts.key?("auth-bucket-name") && !opts.key?("auth-bucket-key")
    abort "Must provide auth-bucket-name as well" if opts.key?("auth-bucket-key") && !opts.key?("auth-bucket-name")
  end

  def create_app_version(opts)
    require_options(opts, "application-name", "version-label", "bucket-name", "bucket-key")
    eb_client(opts).create_application_version(
      application_name: opts["application-name"],
      version_label: opts["version-label"],
      description: opts["description"],
      source_bundle: {
        s3_bucket: opts["bucket-name"],
        s3_key: opts["bucket-key"]
      },
      auto_create_application: false
    )
  end

  def deploy_app_version(opts)
    require_options(opts, "application-name", "version-label", "env-name")
    eb_client(opts).update_environment(
      application_name: opts["application-name"],
      version_label: opts["version-label"],
      environment_name: opts["env-name"]
    )
  end

  def build_zip(opts, output)
    require_options(opts, "bucket-name", "bucket-key")
    validate_bucket_opts(opts)
    run_string = JSON.generate(dockerrun_hash(opts))
    Dir.mktmpdir do |tmpdir|
      File.write("#{tmpdir}/Dockerrun.aws.json", run_string)
      Zip::File.open("#{tmpdir}/app_source.zip", Zip::File::CREATE) do |zipfile|
        zipfile.add("Dockerrun.aws.json", "#{tmpdir}/Dockerrun.aws.json")
      end
      s3_client.put_object(bucket: opts["bucket-name"], key: opts["bucket-key"], body: IO.read("#{tmpdir}/app_source.zip"))
    end
  end

  def s3_client(opts)
    @s3_client || build_s3_client(opts)
  end

  def eb_client(opts)
    @eb_client || build_eb_client(opts)
  end

  def build_s3_client(opts)
    creds = creds_from_opts(opts)
    Aws::S3::Client.new(creds)
  end

  def build_eb_client(opts)
    creds = creds_from_opts(opts)
    Aws::ElasticBeanstalk::Client.new(creds)
  end

  def creds_from_opts(opts)
    creds = {}
    creds[:access_key_id] = opts["aws-access-key-id"] if opts.key?("aws-access-key-id")
    creds[:secret_access_key] = opts["aws-secret-access-key"] if opts.key?("aws-secret-access-key")
    creds
  end

  def require_options(opts, *required)
    required.each do |option|
      abort "The required option #{option} was not provided" unless opts.key?(option)
    end
  end
end

Deploy.start

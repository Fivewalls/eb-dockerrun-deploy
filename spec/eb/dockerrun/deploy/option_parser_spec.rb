require 'spec_helper'
require 'yaml'

module Eb::Dockerrun::Deploy
  describe OptionParser do
    subject { OptionParser.new(opts_hash) }
    describe '#intialize' do
      context 'specify an options file' do
        before do
          FileUtils.mkdir_p('./my/config/')
          config = {
            'env-name' => 'my-env',
            'tag-name' => 'my-tag'
          }
          File.write('./my/config/file.yml', YAML.dump(config))
        end
        let(:opts_hash) do
          {
            'var-file' => './my/config/file.yml',
            'tag-name' => 'my-new-tag'
          }
        end

        it 'should set the config file path' do
          expect(subject.option_file).not_to be nil
          expect(subject.option_file).to eq(File.join(Dir.pwd, 'my/config/file.yml'))
        end

        it 'should set the working path' do
          expect(subject.working_path).not_to be nil
          expect(subject.working_path).to eq(File.join(Dir.pwd, 'my/config'))
        end

        it 'should set options from file, overridden by hash' do
          expect(subject.opts['env-name']).to eq 'my-env'
          expect(subject.opts['tag-name']).to eq 'my-new-tag'
        end

        it 'should set default options' do
          expect(subject.opts['container-port']).to eq '3000'
          expect(subject.opts['version-label']).not_to be_empty
          expect(subject.opts['bucket-key']).to eq subject.opts['version-label']
        end
      end

      context 'no options file' do
        let(:opts_hash) do
          {
            'tag-name' => 'my-new-tag'
          }
        end

        it 'should have nil config file' do
          expect(subject.option_file).to be nil
        end

        it 'should use the current working path' do
          expect(subject.working_path).to eq File.expand_path(Dir.pwd)
        end
      end
    end

    describe '#require_opts' do
      let(:opts_hash) do
        {
          'tag-name' => 'my-new-tag',
          'env-name' => 'application-dev'
        }
      end

      it 'should pass when all required options are present' do
        expect { subject.require_opts('tag-name', 'env-name') }.not_to raise_error
      end

      it 'should fail when a required option is missing' do
        expect { subject.require_opts('application-name') }.to raise_error(OptionParserError)
      end
    end
  end
end

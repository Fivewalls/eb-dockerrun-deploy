require 'spec_helper'

describe Eb::Dockerrun::Deploy do
  it 'has a version number' do
    expect(Eb::Dockerrun::Deploy::VERSION).not_to be nil
  end
end

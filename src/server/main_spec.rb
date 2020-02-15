ENV['APP_ENV'] = 'test'

require 'rspec/autorun'
require 'rack/test'
require 'sequel'
Sequel.extension :migration

RSpec.shared_examples "a dataset" do |field, values, path|
  it "returns records with #{field} = #{values.join(", ")}" do
    get path
    result = JSON.parse(last_response.body)
    values.each do |value|
      filtered = result.select { |rec| rec[field] == value }
      expect(filtered.length).to be > 0
    end
  end
end

RSpec.describe "Mad Scientists web-service" do
  include Rack::Test::Methods

  $db = Sequel.sqlite
  Sequel::Migrator.apply($db, '../migrations')

  require_relative 'main'

  before :each do
    Device.dataset.destroy
    Scientist.dataset.destroy

    Scientist.create(name: "Richard Feynman", madness_level: 5,
                     galaxy_destruction_attempts: 0)
    Scientist.create(name: "Frankenstein", madness_level: 11,
                     galaxy_destruction_attempts: 0)
    Scientist.create(name: "Emmett Brown", madness_level: 7,
                     galaxy_destruction_attempts: 0)

    Device.create(
        name: "Atomic bomb",
        scientist_id: Scientist.dataset[name: "Richard Feynman"].scientist_id,
        power: 6)
    Device.create(
        name: "DeLorean time machine",
        scientist_id: Scientist.dataset[name: "Emmett Brown"].scientist_id,
        power: 0)
  end

  def app
    Sinatra::Application
  end

  describe "#get '/scientists'" do
    context "when there are no filters" do
      it_behaves_like "a dataset", "name",
        ["Richard Feynman", "Emmett Brown", "Frankenstein"], '/scientists'
    end
  end

  describe "#get '/devices'" do
    context "when there are no filters" do
      it_behaves_like "a dataset", "name",
        ["DeLorean time machine", "Atomic bomb"], '/devices'
    end
  end
end


ENV['APP_ENV'] = 'test'

require 'rspec/autorun'
require 'rack/test'
require 'sequel'
Sequel.extension :migration

RSpec.describe "Crazy Scientists web-service" do
  include Rack::Test::Methods

  $db = Sequel.sqlite
  Sequel::Migrator.apply($db, '../migrations')

  require_relative 'main'

  before :each do
    Device.dataset.destroy
    Scientist.dataset.destroy
  end

  def app
    Sinatra::Application
  end

  def setup_example_db
    Scientist.create(name: "Richard Feynman", madness_level: 5,
                     galaxy_destruction_attempts: 0)
    Device.create(
        name: "Atomic bomb",
        scientist_id: Scientist.dataset[name: "Richard Feynman"].scientist_id,
        power: 6)
  end

  describe "#get '/scientists'" do
    context "when the scientists table is not empty" do
      it "returns the list of scientists as a JSON array of hashes" do
        setup_example_db

        get '/scientists'
        result = JSON.parse(last_response.body)

        expect(result[0]["name"]).to eq "Richard Feynman" 
        expect(result[0]["madness_level"]).to eq 5 
        expect(result[0]["galaxy_destruction_attempts"]).to eq 0 
        expect(Time.now - Time.parse(result[0]["time_added"])).to be < 10
      end
    end

    context "when the scientists table is empty" do
      it "returns an empty array" do
        get '/scientists'
        result = JSON.parse(last_response.body)

        expect(result).to eq [] 
      end
    end
  end

  describe "#get '/devices'" do
    context "when the devices table is not empty" do
      it "returns the list of devices as a JSON array of hashes" do
        setup_example_db

        get '/devices'
        result = JSON.parse(last_response.body)

        expect(result[0]["name"]).to eq "Atomic bomb" 
        expect(result[0]["power"]).to eq 6 
        scientist = result[0]["scientist_id"]
        expect(Scientist[scientist_id: scientist].name).to eq "Richard Feynman" 
        expect(Time.now - Time.parse(result[0]["time_added"])).to be < 10
      end
    end

    context "when the devices table is empty" do
      it "returns an empty array" do
        get '/devices'
        result = JSON.parse(last_response.body)

        expect(result).to eq [] 
      end
    end
  end
end


ENV['APP_ENV'] = 'test'

require 'rspec/autorun'
require 'rack/test'
require 'sequel'
Sequel.extension :migration

RSpec.describe "Mad Scientists web-service" do
  include Rack::Test::Methods

  $db = Sequel.sqlite(cache_schema: false)
  Sequel::Migrator.apply($db, '../migrations')

  require_relative 'main'

  before :each do
    Device.dataset.truncate
    Scientist.dataset.truncate

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
      it "returns all records" do
        get '/scientists'

        expect(last_response).to be_ok
        expect(last_response.body).to eq Scientist.all.to_json
      end
    end
  end

  describe "#get '/scientists/:id'" do
    context "when the database has the record with the given id" do
      it "returns the record with the given id" do
        id = Scientist.first[:scientist_id]
        get 'scientists/' + id.to_s

        expect(last_response).to be_ok
        expect(last_response.body).to eq Scientist.first.to_json
      end
    end

    context "when the database doesn't have the record with the given id" do
      it "returns code 404" do
        get 'scientists/32000'

        expect(last_response.status).to eq 404
      end
    end

    context "when :id is not an integer bigger than 0" do
      context "when :id is an integer less than 1" do
        it "returns code 400" do
          get 'scientists/0'
          expect(last_response.status).to eq 400

          get 'scientists/-2'
          expect(last_response.status).to eq 400
        end
      end

      context "when :id is not an integer" do
        it "returns code 400" do
          get 'scientists/sdkfjl'
          expect(last_response.status).to eq 400
        end
      end
    end
  end

  describe "#get '/devices'" do
    context "when there are no filters" do
      it "returns all records" do
        get '/devices'

        expect(last_response).to be_ok
        expect(last_response.body).to eq Device.all.to_json
      end
    end
  end

  describe "#post '/scientists'" do
    context "when every record in the array has all the necessary fields" +
      " and no redundant ones" do
      it "adds new records" do
        data = [
          {
            'name' => "One",
            'madness_level' => 10,
            'galaxy_destruction_attempts' => 12,
          },
          {
            'name' => "Two",
            'madness_level' => 80,
            'galaxy_destruction_attempts' => 1024,
          }
        ]

        post '/scientists', data.to_json

        expect(last_response.status).to eq 204
        
        get '/scientists'
        result = JSON.parse(last_response.body)[-2..-1]

        (-2..-1).each do |index|
          data[index].keys.each do |key|
            expect(result[index][key]).to eq data[index][key]
          end
        end
      end
    end

    context "when invalid JSON is sent" do
      context "when failed to parse JSON" do
        it "returns 400 code with 'failed to parse JSON' message" do
          post '/scientists', "[{dkjghk: 10, dfgf}]"
          expect(last_response.status).to eq 400
          expect(last_response.body).to eq "failed to parse JSON"
        end
      end

      context "when sent JSON is not an array of hashes" do
        context "when sent data is not an array" do
          it "returns code 400 with 'invalid request body format' message" do
            post '/scientists', {"koo" => 123}.to_json

            expect(last_response.status).to eq 400
            expect(last_response.body).to eq 'invalid request body format'
          end
        end

        context "when the array contains a non-hash element" do
          it "returns code 400 with 'invalid request body format' message" do
            post '/scientists', [{}, {}, [], {}].to_json

            expect(last_response.status).to eq 400
            expect(last_response.body).to eq 'invalid request body format'
          end
        end
      end

      context "when one of the hashes contains a non-string key" do
        it "returns code 400 with 'invalid request body format' message" do
          post '/scientists', [{"name" => "One", "madness_level" => 6,
                                10 => 1}].to_json

          expect(last_response.status).to eq 400
          expect(last_response.body).to eq 'invalid request body format'
        end
      end

      context "when there is a missing field in one of the records" do
        it "returns code 400 with 'invalid request body format' message" do
          data = [
            {
              "name" => "One",
              "madness_level" => 10
            }
          ]
          post '/scientists', data.to_json

          expect(last_response.status).to eq 400
          expect(last_response.body).to eq 'invalid request body format'
        end
      end

      context "when there is a redundant field in one of the records" do
        it "returns code 400 with 'invalid request body format' message" do
          data = [
            {
              "name" => "One",
              "madness_level" => 10,
              "galaxy_destruction_attempts" => 8,
              "height" => 180,
            }
          ]
          post '/scientists', data.to_json

          expect(last_response.status).to eq 400
          expect(last_response.body).to eq 'invalid request body format'
        end
      end

      context "when a record has invalid data types" do
        it "returns code 400 with 'invalid request body format' message" do
          data = [
            {
              "name" => "One",
              "madness_level" => 10,
              "galaxy_destruction_attempts" => "eight"
            }
          ]

          post '/scientists', data.to_json

          expect(last_response.status).to eq 400
          expect(last_response.body).to eq 'invalid request body format'
        end
      end
    end
  end
end

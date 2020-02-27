ENV['APP_ENV'] = 'test'

require 'rspec/autorun'
require 'rack/test'
require 'sequel'
Sequel.extension :migration

RSpec.shared_examples "access by id" do
                                  |model, method, path, data=nil|
  context "when the database doesn't have the record with the given id" do
    context "when :id is valid but there is no matching record" do
      it "returns code 404" do
        uri = path + "32000"
        if data
          send method, uri, data
        else
          send method, uri
        end

        expect(last_response.status).to eq 404
      end
    end

    context "when :id is not a proper id" do
      context "when :id is a negative integer" do
        it "returns code 400" do
          uri = path + "-2"
          if data
            send method, uri, data
          else
            send method, uri
          end

          expect(last_response.status).to eq 400
        end
      end

      context "when :id is not an integer" do
        it "returns code 400" do
          uri = path + "188.1"
          if data
            send method, uri, data
          else
            send method, uri
          end

          expect(last_response.status).to eq 400
        end
      end
    end
  end
end

RSpec.shared_examples 'get all request' do |model, path|
  it "returns all records" do
    get path

    expect(last_response).to be_ok
    expect(last_response.body).to eq model.all.to_json
  end
end

RSpec.shared_examples 'get by id request' do |model, path|
  it_behaves_like "access by id", model, :get, path

  context "when the database has the record with the given id" do
    it "returns the record with the given id" do
      id = model.first[model.primary_key]

      get path + id.to_s

      expect(last_response).to be_ok
      expect(last_response.body).to eq model.first.to_json
    end
  end
end

RSpec.shared_examples 'post request' do |model, path|
  context "when every record in the array has all the necessary fields" +
    " and no redundant ones" do
    it "adds new records" do
      post path, data.to_json

      expect(last_response.status).to eq 204
      
      get path
      result = JSON.parse(last_response.body)[-data.length..-1]

      (-data.length..-1).each do |index|
        data[index].keys.each do |key|
          expect(result[index][key]).to eq data[index][key]
        end
      end
    end
  end

  context "when failed to parse JSON" do
    it "returns 400 code with 'failed to parse JSON' message" do
      post path, "[{dkjghk: 10, dfgf}]"

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq "failed to parse JSON"
    end
  end

  context "when sent JSON is not an array of hashes" do
    context "when sent data is not an array" do
      it "returns code 400 with 'invalid request body format' message" do
        post path, {"koo" => 123}.to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'invalid request body format'
      end
    end

    context "when the array contains a non-hash element" do
      it "returns code 400 with 'invalid request body format' message" do
        post path, [{}, {}, [], {}].to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'invalid request body format'
      end
    end
  end

  context "when one of the hashes contains a non-string key" do
    it "returns code 400 with 'invalid request body format' message" do
      corrupt = data.dup
      corrupt[0][2] = 3

      post path, corrupt.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'invalid request body format'
    end
  end

  context "when there is a missing field in one of the records" do
    it "returns code 400 with 'invalid request body format' message" do
      corrupt = data.dup
      corrupt[0].delete(data[0].keys[0])

      post path, corrupt.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'invalid request body format'
    end
  end

  context "when there is a redundant field in one of the records" do
    it "returns code 400 with 'invalid request body format' message" do
      corrupt = data.dup
      corrupt[0]["koo"] = 3

      post path, corrupt.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'invalid request body format'
    end
  end

  context "when a record has mismatched data types" do
    it "returns code 400 with 'invalid request body format' message" do
      corrupt = data.dup
      corrupt[0][data[0].keys[0]] = Hash.new

      post path, data.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'invalid request body format'
    end
  end
end

RSpec.shared_examples "patch request" do |model, path, data|
  it_behaves_like "access by id", model, :patch, path, data

  context "when the request body is a hash containing a subset of model" +
      "fields except #{model.primary_key} with proper data types" do
    it "updates the record" do
      id = model.first[model.primary_key]
      values = model.first.values.dup
      data.each { |k, v| values[k.to_sym] = v }

      patch path + id.to_s, data.to_json

      expect(last_response).to be_ok

      model.first.values.each do |k, v|
        expect(model.first.values[k]).to eq values[k] unless k == :time_added
      end
    end
  end

  context "when failed to parse JSON" do
    it "returns 400 code with 'failed to parse JSON' message" do
      id = model.first[model.primary_key]

      patch path + id.to_s, "[{dkjghk: 10, dfgf}]"

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq "failed to parse JSON"
    end
  end

  context "when sent JSON is not a hash" do
    it "returns code 400 with 'invalid request body format' message" do
      id = model.first[model.primary_key]

      patch path + id.to_s, "[]"

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq "invalid request body format"
    end
  end

  context "when the hash contains a non-string key" do
    it "returns code 400 with 'invalid request body format' message" do
      id = model.first[model.primary_key]

      corrupt = data.dup
      corrupt[1] = 2
      patch path + id.to_s, corrupt.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'invalid request body format'
    end
  end

  context "when the hash has a redundant field" do
    it "returns code 400 with 'invalid request body format' message" do
      id = model.first[model.primary_key]

      corrupt = data.dup
      corrupt[model.primary_key.to_s] = 2
      patch path + id.to_s, corrupt.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'invalid request body format'
    end
  end

  context "when the hash values have mismatched data types" do
    it "returns code 400 with 'invalid request body format' message" do
      id = model.first[model.primary_key]

      corrupt = data.dup
      corrupt[data.keys[0]] = Hash.new

      patch path + id.to_s, corrupt.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'invalid request body format'
    end
  end
end

RSpec.describe "Mad Scientists web-service" do
  include Rack::Test::Methods

  db = Sequel.sqlite(cache_schema: false)
  Sequel::Migrator.apply(db, '../migrations')

  require_relative '../src/server/main'

  before :each do
    Device.dataset.truncate
    Scientist.dataset.truncate

    Scientist.create(name: "Richard Feynman", madness_level: 5,
                     galaxy_destruction_attempts: 0)
    Scientist.create(name: "Frankenstein", madness_level: 11,
                     galaxy_destruction_attempts: 0)
    Scientist.create(name: "Emmett Brown", madness_level: 7,
                     galaxy_destruction_attempts: 0)
    Scientist.create(name: "No Inventions", madness_level: 20,
                     galaxy_destruction_attempts: 4)

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

  describe "#get 'scientists'" do
    it_behaves_like "get all request", Scientist, 'scientists'
  end

  describe "#get 'scientists/:id'" do
    it_behaves_like "get by id request", Scientist, 'scientists/'
  end

  describe "#post 'scientists'" do
    it_behaves_like "post request", Scientist, 'scientists' do
      let(:data) {
        [ 
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
      }
    end
  end

  describe "#patch 'scientists/:id'" do
    it_behaves_like "patch request", Scientist, 'scientists/',
      {"madness_level" => 200, "galaxy_destruction_attempts" => 500}
  end

  describe "#delete 'scientists/:id'" do
    it_behaves_like "access by id", Scientist, :delete, 'scientists/'

    context "if the scientist has no devices" do
      it "deletes the record with the given id" do
        id = Scientist[name: "No Inventions"][:scientist_id]

        delete 'scientists/' + id.to_s

        expect(last_response).to be_ok
        expect(Scientist[name: "No Inventions"]).to be_nil
      end
    end

    context "if the scientist has a device" do
      it "returns code 400 with 'foreign key constraint failed' message" do
        id = Scientist[name: "Richard Feynman"][:scientist_id]

        delete 'scientists/' + id.to_s

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'foreign key constraint failed'
      end
    end
  end

  describe "#get 'devices'" do
    it_behaves_like "get all request", Device, 'devices'
  end

  describe "#get 'devices/:id'" do
    it_behaves_like "get by id request", Device, 'devices/'
  end

  describe "#post 'devices'" do
    it_behaves_like "post request", Device, 'devices' do
      let(:data) {
        [
          {
            'name' => "One",
            'scientist_id' => Scientist[name: "Richard Feynman"][:scientist_id],
            'power' => 10,
          },
          {
            'name' => "Two",
            'scientist_id' => Scientist[name: "Emmett Brown"][:scientist_id],
            'power' => 80,
          }
        ]
      }
    end
  end

  describe "#patch 'devices/:id'" do
    it_behaves_like "patch request", Device, 'devices/',
      {"power" => 200, "name" => "Koo"}
  end

  describe "#delete 'devices/:id'" do
    it_behaves_like "access by id", Device, :delete, 'devices/'

    it "deletes the record with the given id" do
      id = Device[name: "Atomic bomb"][:device_id]

      delete 'devices/' + id.to_s

      expect(last_response).to be_ok
      expect(Device[name: "Atomic bomb"]).to be_nil
    end
  end
end

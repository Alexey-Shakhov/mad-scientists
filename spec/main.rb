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
        uri = path % ["32000"]
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
          uri = path % ["-2"]
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
          uri = path % ["188.1"]
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
    expect(last_response.headers["Content-Type"]).to eq "application/json"
    expect(last_response.body).to eq model.all.to_json
  end
end

RSpec.shared_examples 'get by id request' do |model, path|
  it_behaves_like "access by id", model, :get, path

  context "when the database has the record with the given id" do
    it "returns the record with the given id" do
      id = model.first[model.primary_key]

      get path % [id.to_s]

      expect(last_response).to be_ok
      expect(last_response.headers["Content-Type"]).to eq "application/json"
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
      
      result = model.all[-data.length..-1].map { |rec| rec.values }

      (-data.length..-1).each do |index|
        data[index].keys.each do |key|
          expect(result[index][key.to_sym]).to eq data[index][key]
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

  context "when sent data is not an array" do
    it "returns code 400 with 'request body must be an array' message" do
      post path, {"koo" => 123}.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'request body must be an array'
    end
  end

  context "when the array contains a non-hash element" do
    it "returns code 400 with 'array must only contain hashes' message" do
      post path, [{}, [], {}, {}].to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'array must only contain hashes'
    end
  end

  context "when there is a missing field in one of the records" do
    it "returns code 400 with 'missing field in record' message" do
      corrupt = data.dup
      corrupt[0].delete(data[0].keys[0])

      post path, corrupt.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'missing field in record'
    end
  end

  context "when there is a redundant field in one of the records" do
    it "returns code 400 with 'redundant field in record' message" do
      corrupt = data.dup
      corrupt[0]["koo"] = 3

      post path, corrupt.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'redundant field in record'
    end
  end

  context "when a record has mismatched data types" do
    it "returns code 400 with 'invalid data type in record' message" do
      corrupt = data.dup
      corrupt[0][data[0].keys[0]] = Hash.new

      post path, data.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'invalid data type in record'
    end
  end
end

RSpec.shared_examples "patch request" do |model, path, data|
  it_behaves_like "access by id", model, :patch, path, data

  context "when the request body is a hash containing a subset of model" +
      "fields except #{model.primary_key} with proper data types" do
    it "updates the record" do
      if data.nil? then data = var_data end

      id = model.first[model.primary_key]
      values = model.first.values.dup
      data.each { |k, v| values[k.to_sym] = v }

      patch path % [id.to_s], data.to_json

      expect(last_response.status).to eq 204

      model.first.values.each do |k, v|
        expect(model.first.values[k]).to eq values[k] unless k == :time_added
      end
    end
  end

  context "when failed to parse JSON" do
    it "returns 400 code with 'failed to parse JSON' message" do
      id = model.first[model.primary_key]

      patch path % [id.to_s], "[{dkjghk: 10, dfgf}]"

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq "failed to parse JSON"
    end
  end

  context "when sent JSON is not a hash" do
    it "returns code 400 with 'request body must be a hash' message" do
      id = model.first[model.primary_key]

      patch path % [id.to_s], "[]"

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq "request body must be a hash"
    end
  end

  context "when the hash has a redundant field" do
    it "returns code 400 with 'redundant field in record' message" do
      if data.nil? then data = var_data end

      id = model.first[model.primary_key]

      corrupt = data.dup
      corrupt[model.primary_key.to_s] = 2
      patch path % [id.to_s], corrupt.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'redundant field in record'
    end
  end

  context "when the hash values have mismatched data types" do
    it "returns code 400 with 'invalid data type in record' message" do
      if data.nil? then data = var_data end

      id = model.first[model.primary_key]

      corrupt = data.dup
      corrupt[data.keys[0]] = Hash.new

      patch path % [id.to_s], corrupt.to_json

      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'invalid data type in record'
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
    Scientist.create(name: "Koo", madness_level: 20,
                     galaxy_destruction_attempts: 4)

    Device.create(
        name: "Atomic bomb",
        scientist_id: Scientist.dataset[name: "Richard Feynman"].scientist_id,
        power: 6)
    Device.create(
        name: "DeLorean time machine",
        scientist_id: Scientist.dataset[name: "Emmett Brown"].scientist_id,
        power: 0)
    Device.create(
        name: "Koo1",
        scientist_id: Scientist.dataset[name: "Koo"].scientist_id,
        power: 0)
    Device.create(
        name: "Koo2",
        scientist_id: Scientist.dataset[name: "Koo"].scientist_id,
        power: 0)
    Device.create(
        name: "Koo3",
        scientist_id: Scientist.dataset[name: "Koo"].scientist_id,
        power: 0)
  end

  def app
    Sinatra::Application
  end

  describe "#get 'scientists'" do
    it_behaves_like "get all request", Scientist, 'scientists'
  end

  describe "#get 'scientists/:id'" do
    it_behaves_like "get by id request", Scientist, 'scientists/%s'
  end

  describe "#get 'scientists/:id/devices'" do
    it_behaves_like "access by id", Scientist, :get, 'scientists/%s/devices'

    context "when the id exists" do
      it "returns the list of all devices created by the scientist" do
        id = Scientist[name: 'Koo'].scientist_id

        get 'scientists/%s/devices' % [id]

        expect(last_response).to be_ok
        expect(last_response.headers["Content-Type"]).to eq "application/json"
        expect(last_response.body).to eq Device.where(scientist_id: id).to_json
      end
    end
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

    context 'when trying to post multiple scientists with the same name' do
      it 'returns code 400 with "scientists with the same name" message' do
        data = [ 
          {
            'name' => "One",
            'madness_level' => 10,
            'galaxy_destruction_attempts' => 12,
          },
          {
            'name' => "One",
            'madness_level' => 1,
            'galaxy_destruction_attempts' => 1024,
          }
        ] 

        post 'scientists', data.to_json
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'scientists with the same name'
      end
    end

    context 'when trying to post a scientist with an already taken name' do
      it 'returns code 400 with "scientist with ' +
          'name [duplicate name] already in database" message' do
        name = "Richard Feynman"
        data = [
          {
            'name' => name,
            'madness_level' => 10,
            'galaxy_destruction_attempts' => 12,
          },
          {
            'name' => "One",
            'madness_level' => 1,
            'galaxy_destruction_attempts' => 1024,
          }
        ]

        post 'scientists', data.to_json
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq "name #{name} already in database"
      end
    end

    context 'when madness_level is negative in a record' do
      it 'returns code 400 with "negative madness level" message' do
        data = [ 
          {
            'name' => "One",
            'madness_level' => 10,
            'galaxy_destruction_attempts' => 12,
          },
          {
            'name' => "Two",
            'madness_level' => -1,
            'galaxy_destruction_attempts' => 1024,
          }
        ] 

        post 'scientists', data.to_json
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'negative madness level'
      end
    end

    context 'when galaxy_destruction_attempts is negative in a record' do
      it 'returns code 400 with' +
          ' "negative number of galaxy destruction attempts" message' do
        data = [ 
          {
            'name' => "One",
            'madness_level' => 10,
            'galaxy_destruction_attempts' => 12,
          },
          {
            'name' => "Two",
            'madness_level' => 80,
            'galaxy_destruction_attempts' => -1,
          }
        ] 

        post 'scientists', data.to_json
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq(
            'negative number of galaxy destruction attempts')
      end
    end
  end

  describe "#patch 'scientists/:id'" do
    it_behaves_like "patch request", Scientist, 'scientists/%s',
      {"name" => "Svoloch", "galaxy_destruction_attempts" => 500}
    it_behaves_like "patch request", Scientist, 'scientists/%s',
      {"name" => "Svoloch"}
    it_behaves_like "patch request", Scientist, 'scientists/%s',
      {"name" => "Svoloch", "galaxy_destruction_attempts" => 500,
        "madness_level": 10}

    let(:id) { Scientist[name: 'Emmett Brown'].scientist_id }
    let(:path) { 'scientists/%s' % [id] }

    context 'when trying to post a scientist with an already taken name' do
      it 'returns code 400 with "scientist with ' +
          'name [duplicate name] already in database" message' do
        name = "Richard Feynman"
        data = {
            'name' => name,
            'madness_level' => 10,
            'galaxy_destruction_attempts' => 12,
        }

        patch path, data.to_json
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq "name #{name} already in database"
      end
    end

    context 'when madness_level is negative in a record' do
      it 'returns code 400 with "negative madness level" message' do
        data = {
          'name' => "Two",
          'madness_level' => -1,
          'galaxy_destruction_attempts' => 1024,
        }

        patch path, data.to_json
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'negative madness level'
      end
    end

    context 'when galaxy_destruction_attempts is negative in a record' do
      it 'returns code 400 with' +
          ' "negative number of galaxy destruction attempts" message' do
        data = {
          'name' => "Two",
          'madness_level' => 80,
          'galaxy_destruction_attempts' => -1,
        }

        patch path, data.to_json
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq(
            'negative number of galaxy destruction attempts')
      end
    end
  end

  describe "#delete 'scientists/:id'" do
    it_behaves_like "access by id", Scientist, :delete, 'scientists/%s'

    context "if the scientist has no devices" do
      it "deletes the record with the given id" do
        id = Scientist[name: "No Inventions"][:scientist_id]

        delete 'scientists/%s' % [id.to_s]

        expect(last_response).to be_ok
        expect(Scientist[name: "No Inventions"]).to be_nil
      end
    end

    context "if the scientist has a device" do
      it "returns code 400 with 'foreign key constraint failed' message" do
        id = Scientist[name: "Richard Feynman"][:scientist_id]

        delete 'scientists/%s' % [id.to_s]

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'foreign key constraint failed'
      end
    end
  end

  describe "#get 'devices'" do
    it_behaves_like "get all request", Device, 'devices'
  end

  describe "#get 'devices/:id'" do
    it_behaves_like "get by id request", Device, 'devices/%s'
  end

  describe "#post 'scientists/:id/devices'" do
    let(:id) { Scientist[name: 'Koo'].scientist_id }
    let(:path) { 'scientists/%s/devices' % [id] }

    it_behaves_like "access by id",
          Scientist, :post, 'scientists/%s/devices'

    context "when every record in the array has all the necessary fields " +
        "and no redundant ones" do
      it "adds new records" do
        data = [
          {
            'name' => "One",
            'power' => 10,
          },
          {
            'name' => "Two",
            'power' => 80,
          }
        ]

        post path, data.to_json

        expect(last_response.status).to eq 204
        
        result = Device.all[-data.length..-1].map { |rec| rec.values }

        (-data.length..-1).each do |index|
          data[index].keys.each do |key|
            expect(result[index][key.to_sym]).to eq data[index][key]
          end

          expect(result[index][:scientist_id]).to eq id
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

    context "when sent data is not an array" do
      it "returns code 400 with 'request body must be an array' message" do
        post path, {"koo" => 123}.to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'request body must be an array'
      end
    end

    context "when the array contains a non-hash element" do
      it "returns code 400 with 'array must only contain hashes' message" do
        post path, [{}, [], {}, {}].to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'array must only contain hashes'
      end
    end

    context "when there is a missing field in one of the records" do
      it "returns code 400 with 'missing field in record' message" do
        data = [
          {
            'name' => "One",
            'power' => 10,
          },
          {
            'name' => "Two",
          }
        ]

        post path, data.to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'missing field in record'
      end
    end

    context "when there is a redundant field in one of the records" do
      it "returns code 400 with 'redundant field in record' message" do
        data = [
          {
            'name' => "One",
            'power' => 10,
          },
          {
            'name' => "Two",
            'power' => 11,
            'weight' => 0.2,
          }
        ]

        post path, data.to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'redundant field in record'
      end
    end

    context "when a record has mismatched data types" do
      it "returns code 400 with 'invalid data type in record' message" do
        data = [
          {
            'name' => "One",
            'power' => 10,
          },
          {
            'name' => "Two",
            'power' => "eighty",
          }
        ]

        post path, data.to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'invalid data type in record'
      end
    end

    context "when power is negative in a record" do
      it "returns code 400 with 'negative power' message" do
        data = [
          {
            'name' => "One",
            'power' => 10,
          },
          {
            'name' => "Two",
            'power' => -1,
          }
        ]

        post path, data.to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'negative power'
      end
    end

    context 'when trying to post multiple devices with the same name' do
      it 'returns code 400 with "devices with the same name" message' do
        data = [
          {
            'name' => "One",
            'power' => 10,
          },
          {
            'name' => "One",
            'power' => 80,
          }
        ]

        post path, data.to_json
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'devices with the same name'
      end
    end

    context 'when trying to post a device with an already taken name' do
      it 'returns code 400 with "device with ' +
          'name [duplicate name] already in database" message' do
        name = "Atomic bomb"
        data = [
          {
            'name' => name,
            'power' => 10,
          },
          {
            'name' => "One",
            'power' => 80,
          }
        ]

        post path, data.to_json
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq "name #{name} already in database"
      end
    end
  end

  describe "#patch 'devices/:id'" do
    it_behaves_like "patch request", Device, 'devices/%s',
      {"power" => 200, "name" => "Avalanche"}
    it_behaves_like "patch request", Device, 'devices/%s',
      {"name" => "Avalanche"}
    it_behaves_like "patch request", Device, 'devices/%s' do
      let(:var_data) {
        {"power" => 200, "name" => "Avalanche",
         "scientist_id": Scientist.first.scientist_id}
      }
    end

    let(:id) { Device[name: 'Atomic bomb'].device_id }
    let(:path) { 'devices/%s' % [id] }

    context "when trying to give device a nonexistent inventor" do
      it "returns code 400 with 'no such scientist' message" do
        data = {
          'power' => 10,
          'scientist_id' => 32000,
        }

        patch path, data.to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'no such scientist'
      end
    end

    context "when power is negative in a record" do
      it "returns code 400 with 'negative power' message" do
        data = {
          'power' => -1,
        }

        patch path, data.to_json

        expect(last_response.status).to eq 400
        expect(last_response.body).to eq 'negative power'
      end
    end

    context 'when trying to post a device with an already taken name' do
      it 'returns code 400 with "device with ' +
          'name [duplicate name] already in database" message' do
        name = "DeLorean time machine"
        data = {
          'name' => name,
          'power' => 10,
        }

        patch path, data.to_json
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq "name #{name} already in database"
      end
    end
  end

  describe "#delete 'devices/:id'" do
    it_behaves_like "access by id", Device, :delete, 'devices/%s'

    it "deletes the record with the given id" do
      id = Device[name: "Atomic bomb"][:device_id]

      delete 'devices/%s' % id.to_s

      expect(last_response).to be_ok
      expect(Device[name: "Atomic bomb"]).to be_nil
    end
  end
end

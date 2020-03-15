# mad-scientists
Mad Scientists is a toy microservice written in Ruby with Sinatra and Sequel that allows users to fetch and manage data about mad scientists and their unbelievable devices using REST API requests.

## Installation
```shell
git clone https://github.com/Alexey-Shakhov/mad-scientists
cd mad-scientists
bundle config set without 'test' # If you only want to use the service
bundle install
```

## Configuration
Create the database and apply migrations to it:
```shell
mysqladmin create mad-scientists
sequel -m mad-scientists/migrations mysql2://localhost/mad-scientists
```
Set the appropriate database settings in the `database.rb` file in the `config` folder.

## Usage
```shell
cd mad-scientists
sudo puma
```

## Running tests
```shell
cd spec
rspec *_test.rb
```

## Using Vagrant
```shell
vagrant up
vagrant ssh
cd /vagrant
# Now you can run tests and the server...
```

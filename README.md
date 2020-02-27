# mad-scientists
A toy microservice in Ruby

## Installation
```shell
git clone https://github.com/Alexey-Shakhov/mad-scientists
cd mad-scientists
bundle config set without 'test' # If you only want to use the service
bundle install
```

## Configuration
Set the appropriate database settings in the `database.rb` file in the `config` folder.

## Usage
```shell
cd mad-scientists
rackup
```

require 'sequel'

adapter = 'mysql2'
db = 'mad-scientists'
user = ''
password = ''
host = 'localhost'
port = 0

Sequel.connect(
  adapter: adapter,
  database: db,
  user: user,
  password: password,
  host: host,
  port: port,
)

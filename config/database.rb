require 'sequel'

adapter = 'sqlite'
db = '/home/alexey/db'
user = ''
password = ''
host = ''
port = 0

Sequel.connect(
  adapter: adapter,
  database: db,
  user: user,
  password: password,
  host: host,
  port: port,
)

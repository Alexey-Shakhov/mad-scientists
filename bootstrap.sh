apt update
apt install -y ruby-full
gem install bundler
apt install -y build-essential libmysqlclient-dev mysql-server
cd /vagrant
bundle config unset without
bundle install

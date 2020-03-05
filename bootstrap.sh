apt update
apt install -y ruby-full
gem install bundler
apt install -y build-essential libmysqlclient-dev mysql-server
cd /vagrant
bundle config unset without
bundle install
mysqladmin create mad-scientists
sequel -m migrations mysql2://localhost/mad-scientists

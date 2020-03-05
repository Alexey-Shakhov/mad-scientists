Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.provision "shell", path: "bootstrap.sh"
  config.vm.network :forwarded_port, guest: 9292, host: 4567
end

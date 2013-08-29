sudo apt-get -y install git

wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb
sudo dpkg -i puppetlabs-release-precise.deb
sudo apt-get update

sudo apt-get -y install puppet

echo "Installing librarian-puppet, this might take a while..."
sudo apt-get -y install rubygems
sudo gem install librarian-puppet
librarian-puppet install --verbose

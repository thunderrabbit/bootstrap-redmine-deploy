#!/usr/bin/env bash

# install ansible (http://docs.ansible.com/intro_installation.html)
apt-get -y install software-properties-common
apt-add-repository -y ppa:ansible/ansible
apt-get update
apt-get -y install ansible python-pip git emacs24
pip install boto

# configure git for root (vagrant up runs this bootstrap script as root)
git config --global user.name "root doot doot"
git config --global user.email root.setup.redmine.bootstrap@vagrant.bootstrap

# configure git for user vagrant
cat >> /home/vagrant/.bash_aliases <<EOL

# vagrant environment nodes
alias gitd='git diff -b'
alias gitl='git log --oneline --graph --decorate --all'
alias gits='git status'
alias rc='~/ansible/ec2.py --refresh-cache'
EOL

# install ansible roles that have proved useful
# we don't have to sudo here because the bootstrap is being run by root
ansible-galaxy install geerlingguy.security
ansible-galaxy install geerlingguy.git
ansible-galaxy install geerlingguy.apache
ansible-galaxy install geerlingguy.apache-php-fpm
ansible-galaxy install geerlingguy.php
ansible-galaxy install geerlingguy.mysql

# create an RSA key in case we need it later
su vagrant -c "ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''"

cat >> /home/vagrant/.gitconfig <<EOL
[core]
       	excludesfile = /home/vagrant/.gitignore
[user]
       	name = bootstrap Redmine in VirtualBox
       	email = bootstrap.redmine@example.com
EOL

## set up .gitignore
curl https://www.gitignore.io/api/emacs%2Cansible > /home/vagrant/.gitignore

## ~/setup.sh on the Vagrant box will pull in repos that know how to set up servers on AWS
cat >> /home/vagrant/setup.sh <<EOL
#!/bin/bash

echo "Getting playbooks to set up Redmine on AWS"
git clone https://github.com/thunderrabbit/deploy-redmine-on-aws.git

cd ~/deploy-redmine-on-aws
ls
EOL
chmod 755 setup.sh

# make sure user vagrant can edit things in his own home directory
chown -R vagrant:vagrant /home/vagrant

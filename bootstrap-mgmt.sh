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

# make sure user vagrant can edit things in his own home directory
chown -R vagrant:vagrant /home/vagrant

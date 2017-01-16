# Redmine bootstrap

Will allow us to start with any box and set up a VPC on AWS and then redmine in the VPC

## Install and prep vagrant box on local hardware

On local hardware with VirtualBox + vagrant installed:

    git clone https://github.com/thunderrabbit/bootstrap-redmine-deploy.git
    cd bootstrap-redmine-deploy
    vagrant up

That will run for a few minutes and create a local box based on Ubuntu

Log in to the box

    vagrant ssh mgmt

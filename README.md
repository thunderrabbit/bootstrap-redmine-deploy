# Redmine bootstrap

Will allow us to start with any box and set up a VPC on AWS and then redmine in the VPC

## Install and prep vagrant box on local hardware

On local hardware with VirtualBox + vagrant installed:

    git clone https://github.com/thunderrabbit/bootstrap-redmine-deploy.git
    cd bootstrap-redmine-deploy
    vagrant up

That will run for a few minutes and create a local box based on Ubuntu

## Log in to box and set it up

Log in to the box

    vagrant ssh mgmt

The first time you log on, run setup:

    . ./setup.sh

Setup will clone a repo and run *its* setup.sh.  This will require entering AWS keys (see below).

## Test connectivity to AWS

Once you've entered AWS keys, load them into memory:

    source ~/ansible/aws_keys

Then test connectivity:

    rc

`rc` stands for "Refresh Cache" and is an alias for `~/ansible/ec2.py --refresh-cache`

If connection succeeds, you should see at least a couple curly braces and at least a couple words:

	{
	  "_meta": {
	    "hostvars": {}
	  }
	}

An error like `ERROR: "Forbidden", while: getting RDS instances` means the IAM User on AWS needs more access to AWS.

## Install VPC and base machine on AWS from vagrant box

Once the machine is set up, you can run playbooks.

    cd ~/deploy-redmine-on-aws

Create a VPC, subnet, internet gateway, route table, and spins up a server on public subnet:

    ansible-playbook playbook_005_setup_VPC_and_base_server.yml

## AWS Keys

The user associated with the AWS keys should have (at least) the following policies:

* AmazonEC2FullAccess
* AmazonRDSReadOnlyAccess
* AmazonElastiCacheReadOnlyAccess

You can read more about Access Keys at
http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html

## Rotating keys

New credentials can be created on AWS
at https://console.aws.amazon.com/iam/home#users

Put them on the target server in file `~/ansible/aws_keys`

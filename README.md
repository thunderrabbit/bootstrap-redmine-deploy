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

An error like `ERROR: "Forbidden", while: getting RDS instances` means the IAM User on AWS needs more access to AWS (See "AWS Keys" section below).

## Install VPC and base machine on AWS from vagrant box

Once the machine is set up, you can run playbooks.

    cd ~/deploy-redmine-on-aws

Create a VPC, subnet, internet gateway, route table, and spins up a server on public subnet:

    ansible-playbook playbook_005_setup_VPC_and_base_server.yml

Once the above playbook has been run, refresh the dynamic inventory:

    rc

The next playbook runs some basic security on the box

    ansible-playbook playbook_010_secure_base.yml

The next playbook runs `apt upgrade` and reboots the box

    ansible-playbook playbook_015_upgrade_server.yml

Then we install git and apache2 on the box

    ansible-playbook playbook_020_git_apache_on_base.yml

At this point, you should be able to visit the ip address of your machine in a web browser, and see the Apache default page.  Depending on your IP address, which is visible in the Ansible output, e.g.

    http://52.153.120.19

Okay, *manually* ("for now") set up route53 with an A record pointing your domain to this IP address.  In our case, `test.sbstrm.co.jp`

Put this domain in the file `vars/vars_for_letsencrypt-ansible.yml`

    ansible_fqdn: "test.sbstrm.co.jp"

Then install a default site, which could be useful for a load balancer to check the server:

    ansible-playbook playbook_025_install_default_site.yml

Reload your ip-address URL from above and see "ok" as the website.

Load it again using the domain name

    http://test.sbstrm.co.jp

Now let's encrypt the site with certbot

    ansible-playbook playbook_030_ssl_default_site.yml

Now we can visit default site securely

    https://test.sbstrm.co.jp

Now we get to the good stuff:

    ansible-playbook playbook_035_install_redmine.yml

As of this writing, we want to make it connect via SSL, so I'm working on 

    ansible-playbook playbook_040_ssl_redmine.yml or something

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

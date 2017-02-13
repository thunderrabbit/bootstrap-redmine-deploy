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

Create a VPC, subnet, internet gateway, route table, and spins up a server on public subnet:  (note this subnet will only allow SSH from the external IP address of the vagrant box, which is probably the same as your local machine)

    ansible-playbook playbook_005_setup_VPC_and_base_server.yml

Once the above playbook has been run, refresh the dynamic inventory: (this will allow the next playbooks to know what box to target.)

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

On the vagrant box, put this domain in the file `~/deploy-redmine-on-aws/vars/vars_for_default_site.yml`

    ansible_fqdn: "test.sbstrm.co.jp"

Then install a default site, which could be useful for a load balancer to check the server:

    ansible-playbook playbook_025_install_default_site.yml

Reload your ip-address URL from above and see "ok" as the website.

Load it again using the domain name

    http://test.sbstrm.co.jp

Load it again via https.  Nice!  Let's Encrypt worked.

    https://test.sbstrm.co.jp

Now we get to the good stuff.

Okay, *manually* ("for now") set up route53 with a CNAME record pointing your Redmine domain to the other domain.  In our case, `redtest.sbstrm.co.jp`

On the vagrant box, put the domain in `~/deploy-redmine-on-aws/vars/vars_for_redmine-ansible.yml`

    redmine_domain: "redtest.sbstrm.co.jp"

Now run the final playbook, which will install Redmine and set up Let's Encrypt for the domain.

    ansible-playbook playbook_035_install_redmine.yml

Now we can visit the domain for our Redmine site

    http://redtest.sbstrm.co.jp

And it should refresh to the SSL version

    https://redtest.sbstrm.co.jp

and show the Redmine main page.  Click login in the top right corner.

The username and password can be found in `~/deploy-redmine-on-aws/vars/vars_for_redmine-ansible.yml`.  Look for redmine_admin_login and redmine_admin_passwd  (N.B. the passwords for DB and redmine login are randomized by the initial setup script on the vagrant box)

    redmine_admin_login: admin
    redmine_admin_passwd: 'OYN0Ei7FI2ynAOY5qGoF57Co7UuvsWKD'

 Make them stand out easily with git diff:

    git diff vars/vars_for_redmine-ansible.yml

## ETC

1. You might want to get ssh keys off the vagrant box (tldr `cp ~/.ssh/id_rsa* /vagrant`)

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

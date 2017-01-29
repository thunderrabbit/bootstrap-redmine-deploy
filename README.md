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

Then install a default site, which could be useful for a load balancer to check the server:

    ansible-playbook playbook_025_install_default_site.yml

Reload your ip-address URL from above and see "ok" as the website.

Now we get to the good stuff, which unfortunately, doesn't yet work:

    ansible-playbook playbook_030_install_redmine.yml

As of this writing, if you can get Redmine to run on the server (as a subdomain like redmine.example.com (which can work with an appropriate entry in local `/etc/hosts` file)), you'll be my hero.  See https://www.upwork.com/jobs/_~01b940f0474e3a416c for details.

## Trying to fix it:

Log in to the new box on AWS via your IP address from above, e.g.

    ssh -i ~/.ssh/id_rsa ubuntu@52.153.120.19

Go to `/etc/apache2/sites-enabled` and see `redmine.conf`

Per the playbooks, it's set to serve from redmine.example.com

On my local box, I added a line to link my IP address to this URL

    52.153.120.19    redmine.example.com

But I only see "ok" when I visit http://redmine.example.com

So let's look at `passenger-status`

    passenger-status

Hmm.  "Phusion Passenger is currently not serving any applications."

Okay, how about `passenger-config validate-install`

    passenger-config validate-install

Aha!  Passenger seems okay, but Apache needs more software.  "Please install it with apt-get install apache2-threaded-dev"

    sudo apt-get install apache2-threaded-dev

D'oh.  It says `E: Unable to locate package apache2-threaded-dev`

Hmm. this might solve it https://github.com/phusion/passenger/issues/1884

    sudo apt install apache2-dev

Okay `passenger-config validate-install` is happy.

    passenger-config validate-install

But `passenger-status` still says it's not serving any applications.

Okay, just for fun I did `sudo service apache2 restart`

    sudo service apache2 restart

I tried @sugaryourcoffee's idea from http://stackoverflow.com/q/33200648/194309

    sudo touch /usr/share/redmine/tmp/restart.txt

But `passenger-status` still says it's not serving any applications.

Hmm.  `/etc/apache2/sites-enabled/redmine.conf` has the following line:

    PassengerPreStart https://localhost

But there's no SSL on this box yet.  Maybe that's the problem, because on the command line of the AWS box, when I try `curl https://localhost` it gives an error:

    curl: (35) gnutls_handshake() failed: An unexpected TLS packet was received.

So, I'm changing the line to

    PassengerPreStart http://localhost

Because `curl http://localhost` returns 'ok'.

And now restarting apache2:

    sudo service apache2 restart

And reloaded redmine.example.com in browser, but `passenger-status` still says it's not running any applications.

I'll still leave the change I made to `redmine.conf`

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

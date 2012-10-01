<img src="" alt="boucher logo" title="Boucher" align="right"/>
# Boucher

Boucher, pronounced [boo-shay], and meaning Butcher in French, is a suite of Rake tasks that simplfy your AWS
deployment strategy.  It's built ontop of Chef and Fog giving your fingers the power to create new servers,
install required software, and deploy your system all in a single command.

It also helps manage your system with support for different environments and tasks to:

 * list all your servers
 * start/stop/terminate servers
 * run chef on a given server
 * easily ssh into a server
 * attach volumes or elastic IPs to your servers

## Getting Started

Getting up and running with Boucher might take a little while depending your your familiarity with AWS and Linux.
Once you're up and running though, it'll save you countless hours in the long run.

### Creating your infrastructure project.

Boucher assumes a certain directory structure.  Bummer I know, but c'est la vie.  To help you out, we've provided a git repo
that'll get you off the ground.  We recomend

    git clone git://github.com/8thlight/boucher_template.git infrastructure
    rm -rf infrastructure/.git

You'll probabaly want to create a repository for your own to track the work here.

Read config/env/shared.rb to get a feel for the configuration options.  You'll fill in some of those values as your continue to get started below.

### Creating a base image

1) Launch new instance: Ubuntu Server 12.04.1 LTS

 * Create a new key saved in your infrastructure project
 * Be sure to add a security group that opens port 22 for SSH

2) Update config/env/shared.rb

 * :aws_key_filename - name of the .pem file you just created and saved in the project root
 * :aws_region - which AWS region did you use?
 * :aws_access_key_id and aws_secret_access_key - available in the AWS Management Console under Security Credentials

3) List servers

    rake servers:list

4) SSH into new server.  (:username config must be 'ubunutu' at this point)

    rake servers:ssh[<instance id>]

5) Create new poweruser (unless you like 'unubutu' as your poweruser).

    sudo adduser <username>
    sudo adduser <username> sudo
    sudo mkdir /home/<username>/.ssh
    sudo cp .ssh/authorized_keys /home/<username>/.ssh/
    sudo chown -R <username>:<username> /home/<username>/.ssh

6) Logout.  Update config :username. Log back in.

    rake servers:ssh[<instance id>]

7) Delete the ubuntu user.

    deluser ubuntu

8) Enable sudo without typing password

    sudo visudo
    # add the following line at the end of the file:
    <username> ALL=(ALL) NOPASSWD: ALL

9) Install required pacakges and gems.

    sudo apt-get update
    sudo apt-get install ruby1.9.1 ruby1.9.1-dev git gcc make libxml2-dev libxslt1-dev
    sudo apt-get upgrade
    sudo gem install bundler chef

10) Checkout your infrstructure repo.  (Yes.  You should push your repo even in this early stage.)
If you use github, you'll have to generate ssh keys and add them to the github repo.

    cd ~/.ssh
    ssh-keygen -t rsa -C "your_email@youremail.com"
    # Copy id_rsa.pub to your github user's ssh keys
    cd ..
    git clone git@github.com:<github account name>/<your infratructure project name>.git infrastructure

11) Customize to your liking.

 * install your preferred vim dot files
 * etc...

12) Create an AMI using the AWS Management console.  Grab the AMI id and put it in config/env/shared.rb as the :default_image_id config value.

## Usage

Run rake to see the list of tasks provided.

    rake -T

### Meals

We're sticking with the metephore here.  A Meal is basically a set of recipes for a single server.
Boucher will expect meals to exist in the config directory.  They are JSON files usable by chef-solo, and Boucher
allows you too add extra configuration information under the "Boucher": key.  For example:

    {
      "run_list": [
        "recipe[boucher::base]"
        ],

      "boucher": {
        "base_image_id": "ami-abcd1234", // overides :default_image_id config
        "flavor_id": "t1.micro", // overides :default_flavor_id config
        "groups": ["SSH"], // overides :default_groups config
        "key_name": ["some_key"], // overides :aws_key_filename config
        "elastic_ips": ["1.2.3.4"], // a list of elastic IPs that'll be attached to the server.  Elastic IP's acquired via AWS management console.
        "volumes": {"/dev/sda2": <volume spec>} // See Volume Specs below
      }
    }

### ERB in config

Meal .json files may contain ERB in the "boucher" section.  However, the file get's parsed by chef-solo so it has to remain a valid JSON file.  But you can do things like this:

         {
           "run_list": ...

           "boucher": {
             "flavor_id": "<%= Boucher::Config[:customer_flavor_id] %>"
           }
         }

Also keep in mind that you can use ERB in recipes' template files.

### Volume Specs

Volumes may be specified in the config for a given meal. The "volumes": entry must be a hash where keys are the device name (mount point) and the values
are a hash describing the volume.  There are really three variations:

1) Mounting an existing volume by using the volume_id:

    "volumes": {"/dev/sda3" => {"volume_id": "volume-abc123"}}

2) Mount a new volume based on an existing snapshot:

    "volumes": {"/dev/sda4" => {"snapshot_id": "snapshot-abc123"}}

3) Mount a new volume of a given size:

    "volumes": {"/dev/sda5" => {"size": 16}}

If volumes are not specified, AWS will apply the default volume setup in the management console.


### Environments

Enviroments are configured in config/env/<env_name>.rb. The project template we checked out earlier only provides one: dev.
You're welcome to create as many environments as you like.  At the top of each environment config file, require the shared
config and then you can overide or add any configuration below.


Environment configuration is available in your chef recipes.  Just require 'boucher/env' in any recipe and extract values like so:

    Boucher::Config[:my_config_value]

### Recipes

We'll assume you're familiar with Chef.  So you know, there are plany of open source cookbooks/recipes on the intertubes.
Convention is to grab the files, put them in your cookbooks folder and take ownership of them.  There's a good chance you'll
want to change them.

## License

Copyright (c) 2012 8th Light, Inc.
MIT License
require 'fog'
compute = Fog::Compute.new(
           :provider => "AWS",
           :aws_secret_access_key => "LUmSxqlSak4khIPx6RH286QvVwitc/2O6rtDaNzL",
           :aws_access_key_id => "AKIAJDHM2HH2IBUBIYQA",
           :region => 'us-east-1')

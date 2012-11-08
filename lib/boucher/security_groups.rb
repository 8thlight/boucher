require 'boucher/compute'
require 'boucher/servers'

module Boucher
  module SecurityGroups
    SECURITY_GROUP_TABLE_FORMAT = "%-12s  %-12s  %-50s\n"

    module Printing
      def self.print_table(security_groups, servers_for_groups)
        printf SECURITY_GROUP_TABLE_FORMAT, "ID", "Name", "Servers"
        puts
        security_groups.each do |security_group|
          printf SECURITY_GROUP_TABLE_FORMAT,
            security_group.group_id,
            security_group.name,
            server_names(servers_for_groups[security_group.name])
        end
      end

      def self.server_names(servers)
        servers.map { |server|
          "#{server.id}(#{server.tags['Meal']})"
        }.join(', ')
      end
    end

    class << self
      def all
        Boucher.compute.security_groups
      end

      def transform_ip(ip)
        appendix = (ip == "0.0.0.0") ? 0 : 32
        "#{ip}/#{appendix}"
      end

      def colliding_configuration(configuration)
        all.get(configuration[:name])
      end

      def build_for_configuration(configuration)
        destroy_existing_configuration(configuration)
        group = all.new(
          name: configuration[:name],
          description: configuration[:description]
        )
        group.save
        group
      end

      def destroy_existing_configuration(configuration)
        existing_configuration = all.get(configuration[:name])
        existing_configuration.destroy if existing_configuration
      end

      def authorize(group, permission)
        range = (permission[:from_port]..permission[:to_port])
        ip = transform_ip(permission[:incoming_ip]) if permission[:incoming_ip]
        options = {
          cidr_ip: ip,
          group: permission[:group],
          ip_protocol: permission[:ip_protocol]
        }
        group.authorize_port_range(range, compact_hash(options))
      end

      def compact_hash(to_compact)
        to_compact.reject do |key|
          to_compact[key].nil?
        end
      end

      def build_for_configurations(configurations)
        groups = {}
        configurations.each do |configuration|
          groups[configuration] = build_for_configuration(configuration)
        end



        groups.each do |configuration, group|
          configuration[:ip_permissions].each do |permission|
            authorize(group, permission)
          end
        end
      end

      def servers_for_groups
        all.reduce({}) do |memo, current|
          memo[current.name] = Boucher::Servers.with_group(current.name)
          memo
        end
      end

      def groups_for_server
        security_group_file = File.open("config/security_groups.json", "r")
        security_groups = JSON.parse(security_group_file.read)
        binding.pry
        mapping = security_groups["mapping"]
        Boucher::SecurityGroups.associate_servers(mapping)
      end
    end
  end
end

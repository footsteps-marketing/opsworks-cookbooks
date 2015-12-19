# AWS OpsWorks Recipe for Wordpress to be executed during the Configure lifecycle phase
# - Creates the config file wp-config.php with MySQL data.
# - Creates a Cronjob.
# - Imports a database backup if it exists.

require 'uri'
require 'net/http'
require 'net/https'

if node['wordpress']['wp_config']['salt'] == false then
    uri = URI.parse("https://api.wordpress.org/secret-key/1.1/salt/")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    keys = response.body
else
    keys = node['wordpress']['wp_config']['salt']
end

case node[:platform_family]
when 'debian'
    package 'php5-mcrypt' do
        action :install
    end
    script "memory_swap" do
        interpreter "bash"
        user "root"
        code <<-EOH
            php5enmod mcrypt
            service apache2 restart
        EOH
    end
end

# Create the Wordpress config file wp-config.php with corresponding values
node[:deploy].each do |app_name, deploy|

    script "permissions_set" do
        interpreter "bash"
        user "root"
        cwd "#{deploy[:deploy_to]}/current/"
        code <<-EOH
            find . -type d -exec chmod 2775 {} + || true
            find . -type f -exec chmod 0664 {} + || true
        EOH
    end

    template "#{deploy[:deploy_to]}/current/wp-config.php" do
        source "wp-config.php.erb"
        mode 0660
        group deploy[:group]

        if platform?("ubuntu")
            owner "deploy"
        elsif platform?("amazon")
            owner "apache"
        end

        variables(
            :database   => (deploy[:database][:database] rescue nil),
            :user       => (deploy[:database][:username] rescue nil),
            :password   => (deploy[:database][:password] rescue nil),
            :host       => (deploy[:database][:host] rescue nil),
            :keys       => (keys rescue nil)
        )
    end

    template "#{deploy[:deploy_to]}/current/.htaccess" do
        source ".htaccess.erb"
        mode 0664
        group deploy[:group]

        if platform?("ubuntu")
            owner "deploy"
        elsif platform?("amazon")
            owner "apache"
        end

    end

    template "#{deploy[:deploy_to]}/current/get-mapped-domains.php" do
        source "get-mapped-domains.php.erb"
        mode 0700
        group "root"
        owner "root"
    end

    git "#{deploy[:deploy_to]}/letsencrypt" do
        user "root"
        repository "https://github.com/letsencrypt/letsencrypt.git"
        action :sync
    end

    script "letsencrypt_init" do
        interpreter "bash"
        user "root"
        cwd "#{deploy[:deploy_to]}/letsencrypt"
        code <<-EOH
            ./letsencrypt-auto --help 2&1 >> ../letsencrypt-output.log
        EOH
    end
    
=begin

    ruby_block "check_curl_command_output" do
        block do
            #tricky way to load this Chef::Mixin::ShellOut utilities
            Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
            command = "php #{deploy[:deploy_to]}/current/get-mapped-domains.php"
            command_out = shell_out(command)
            node[:wp_mapped_domains] = command.stdout.split("\n")
        end
        action :create
    end

    node[:wp_mapped_domains].unshift("#{node[:wordpress][:wp_config][:multisite][:domain_current_site]}")

    script "letsencrypt_doer" do
        interpreter "bash"
        user "root"
        cwd "#{deploy[:deploy_to]}/letsencrypt"
        code <<-EOH
            DOMAINS="-d #{node[:wordpress][:wp_config][:multisite][:domain_current_site]}"
            for domain in $(php #{deploy[:deploy_to]}/current/get-mapped-domains.php); do
                DOMAINS="${DOMAINS} -d ${domain}"
            done
            ./letsencrypt-auto certonly --keep --webroot -w "#{deploy[:deploy_to]}/current" $DOMAINS
        EOH
    end

    node[:wp_mapped_domains].each do |mapped_domain|
        
        template "#{node[:apache][:dir]}/sites-enabled/#{mapped_domain}.conf" do
            source 'mapped_domain.conf.erb'
            owner 'root'
            group 'root'
            mode 0644
            variables :domain => mapped_domain
        end
        
    end

    script "restart_after_letsencrypt" do
        interpreter "bash"
        user "root"
        code <<-EOH
            service apache2 restart
        EOH
    end
=end


	# Import Wordpress database backup from file if it exists
	mysql_command = "/usr/bin/mysql -h #{deploy[:database][:host]} -u #{deploy[:database][:username]} #{node[:mysql][:server_root_password].blank? ? '' : "-p#{node[:mysql][:server_root_password]}"} #{deploy[:database][:database]}"

	Chef::Log.debug("Importing Wordpress database backup...")
	script "memory_swap" do
		interpreter "bash"
		user "root"
		cwd "#{deploy[:deploy_to]}/current/"
		code <<-EOH
			if ls #{deploy[:deploy_to]}/current/*.sql &> /dev/null; then 
				#{mysql_command} < #{deploy[:deploy_to]}/current/*.sql;
				rm #{deploy[:deploy_to]}/current/*.sql;
			fi;
		EOH
	end
	
end

# Create a Cronjob for Wordpress
#cron "wordpress" do
#  hour "*"
#  minute "*/15"
#  weekday "*"
#  command "wget -q -O - http://localhost/wp-cron.php?doing_wp_cron >/dev/null 2>&1"
#end

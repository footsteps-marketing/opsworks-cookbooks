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

# Create the Wordpress config file wp-config.php with corresponding values
node[:deploy].each do |app_name, deploy|

    directory "#{deploy[:deploy_to]}/current/wp-content/uploads" do
        if platform?("ubuntu")
            owner "deploy"
        elsif platform?("amazon")
            owner "apache"
        end
        group deploy[:group]
        mode '2775'
        action :create
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
        mode 0644
        group deploy[:group]

        if platform?("ubuntu")
            owner "deploy"
        elsif platform?("amazon")
            owner "apache"
        end

    end


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

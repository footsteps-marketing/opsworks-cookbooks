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
    package 'pngquant' do
        action :install
    end
    package 'jpegoptim' do
        action :install
    end
    package 'imagemagick' do
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
    
    script "install_mozjpeg" do
        interpreter "bash"
        cwd "/tmp"
        user "root"
        code <<-EOH
            if [ ! -f /opt/mozjpeg/bin/cjpeg ]; then
                sudo apt-get install -y build-essential autoconf pkg-config nasm libtool
                git clone https://github.com/mozilla/mozjpeg.git
                cd mozjpeg
                autoreconf -fiv
                ./configure --with-jpeg8
                make
                sudo make install
            fi
        EOH
    end

    script "install_jpegarchive" do
        interpreter "bash"
        cwd "/tmp"
        user "root"
        code <<-EOH
            if [ ! -f /usr/local/bin/jpeg-recompress ]; then
                git clone https://github.com/danielgtaylor/jpeg-archive.git
                cd jpeg-archive
                make
                sudo make install
            fi
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


    git "/opt/letsencrypt" do
        user "root"
        repository "https://github.com/letsencrypt/letsencrypt.git"
        action :sync
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

# AWS OpsWorks Recipe for Wordpress to be executed during the Deploy lifecycle phase
# Kills some stuff on deploy

exclude_plugins = node['wordpress']['exclude_plugins']
exclude_themes = node['wordpress']['exclude_themes']

app_name = nil
deploy = nil

node[:deploy].each do |app_name, deploy|

    exclude_plugins.each do |plugin|
        Chef::Log.debug("Deleting #{deploy[:deploy_to]}/current/wp-content/plugins/#{plugin}")
        directory "#{deploy[:deploy_to]}/current/wp-content/plugins/#{plugin}" do
            recursive true
            action :delete
        end
    end

    exclude_themes.each do |theme|
        Chef::Log.debug("#{deploy[:deploy_to]}/current/wp-content/themes/#{theme}")
        directory "#{deploy[:deploy_to]}/current/wp-content/themes/#{theme}" do
            recursive true
            action :delete
        end
    end


    directory "#{deploy[:deploy_to]}/current/wp-content/plugins/bwp-minify/cache" do
        recursive true
        owner 'deploy'
        group 'www-data'
        mode '0775'
        action :create
    end

    next if !node[:wordpress][:letsencrypt][:get_certificates]

    domains_to_map = Array.new
    
    ruby_block "check_curl_command_output" do
        block do
            #tricky way to load this Chef::Mixin::ShellOut utilities
            Chef::Resource::RubyBlock.send(:include, Chef::Mixin::ShellOut)
            command = "php #{deploy[:deploy_to]}/current/get-mapped-domains.php"
            command_out = shell_out(command)
            domains_to_map = command_out.stdout.split("\n")
        end
        action :create
    end

    domains_to_map.unshift("#{node[:wordpress][:wp_config][:multisite][:domain_current_site]}")

    domains_to_map.each do |mapped_domain|

        script "letsencrypt_doer" do
            interpreter "bash"
            user "root"
            cwd "/opt/letsencrypt"
            code <<-EOH
                /opt/letsencrypt/letsencrypt-auto certonly --no-self-upgrade --webroot --expand --non-interactive --keep-until-expiring --agree-tos --email "#{node[:wordpress][:letsencrypt][:admin_email]}" --webroot-path "#{deploy[:deploy_to]}/current" -d "#{mapped_domain}"
            EOH
        end

        params = {}

        directory "#{node[:apache][:dir]}/sites-available/#{app_name}.conf.d"
        params[:rewrite_config] = "#{node[:apache][:dir]}/sites-available/#{app_name}.conf.d/rewrite"
        params[:local_config] = "#{node[:apache][:dir]}/sites-available/#{app_name}.conf.d/local"
        
        if deploy[app_name].nil?
            environment_variables = {}
        else
            environment_variables = deploy[app_name][:environment_variables]
        end

        template "#{node[:apache][:dir]}/sites-available/#{mapped_domain}.conf" do
            source 'mapped_domain.conf.erb'
            owner 'root'
            group 'root'
            mode 0644
            variables(
                :mapped_domain => (mapped_domain rescue nil),
                :app_name => "#{app_name}",
                :deploy_to => "#{deploy[:deploy_to]}/current/",
                :params => params,
                :environment => (OpsWorks::Escape.escape_double_quotes(environment_variables) rescue nil)
            )
            if ::File.exists?("#{node[:apache][:dir]}/sites-enabled/#{app_name}.conf")
                notifies :reload, "service[apache2]", :delayed
            end
        end
        apache_site "#{mapped_domain}.conf" do
            enable enable_setting
        end
        
    end

end
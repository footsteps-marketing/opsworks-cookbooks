# AWS OpsWorks Recipe for Wordpress to be executed during the Deploy lifecycle phase
# Kills some stuff on deploy

exclude_plugins = node['wordpress']['exclude_plugins']
exclude_themes = node['wordpress']['exclude_themes']

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

    script "letsencrypt_doer" do
        interpreter "bash"
        user "root"
        cwd "/opt/letsencrypt"
        code <<-EOH
            DOMAINS="-d #{node[:wordpress][:wp_config][:multisite][:domain_current_site]}"
            for domain in $(php #{deploy[:deploy_to]}/current/get-mapped-domains.php); do
                DOMAINS="${DOMAINS} -d ${domain}"
            done
            ./letsencrypt-auto certonly --text --webroot --keep --agree-tos -m "#{node[:wordpress][:letsencrypt][:admin_email]}" -w "#{deploy[:deploy_to]}/current" $DOMAINS
        EOH
    end

    domains_to_map.each do |mapped_domain|
        
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
            service apache2 reload
        EOH
    end



end
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
end

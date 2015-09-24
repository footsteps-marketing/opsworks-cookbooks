# AWS OpsWorks Recipe for Wordpress to be executed during the Deploy lifecycle phase
# Kills some stuff on deploy

exclude_plugins = node['wordpress']['exclude_plugins']
exclude_themes = node['wordpress']['exclude_themes']

exclude_plugins.each do |plugin|
    Chef::Log.debug("Deleting #{deploy[:deploy_to]}/current/wp-content/plugins/#{plugin}")
    directory "#{deploy[:deploy_to]}/current/wp-content/plugins/#{plugin}"
        action :delete
end

exclude_themes.each do |theme|
    Chef::Log.debug("#{deploy[:deploy_to]}/current/wp-content/themes/#{theme}")
    directory "#{deploy[:deploy_to]}/current/wp-content/themes/#{theme}"
        action :delete
end

# AWS OpsWorks Recipe for Wordpress to be executed during the Deploy lifecycle phase
# Kills some stuff on deploy

exclude_plugins = node['wordpress']['exclude_plugins']
exclude_themes = node['wordpress']['exclude_themes']

exclude_plugins.each { |plugin|
    directory "#{deploy[:deploy_to]}/current/wp-content/plugins/#{plugin}"
        action :delete
}

exclude_themes.each { |theme|
    directory "#{deploy[:deploy_to]}/current/wp-content/themes/#{theme}"
        action :delete
}

# Default configuration for the AWS OpsWorks cookbook for Wordpress
#

# Enable the Wordpress W3 Total Cache plugin (http://wordpress.org/plugins/w3-total-cache/)?
default['wordpress']['wp_config']['enable_W3TC'] = false

# Force logins via https (http://codex.wordpress.org/Administration_Over_SSL#To_Force_SSL_Logins_and_SSL_Admin_Access)
default['wordpress']['wp_config']['force_secure_logins'] = false

default['wordpress']['wp_config']['sunrise'] = false

default['wordpress']['wp_config']['debug'] = false

default['wordpress']['wp_config']['site_url'] = false

default['wordpress']['wp_config']['fsm_google_public_api_key'] = false

default['wordpress']['wp_config']['multisite']['enabled'] = false
default['wordpress']['wp_config']['multisite']['subdomain_install'] = false
default['wordpress']['wp_config']['multisite']['domain_current_site'] = false
default['wordpress']['wp_config']['multisite']['default_site'] = 1

default['wordpress']['wordfence'] = false

default['wordpress']['max_upload_size'] = '32M'
default['wordpress']['max_execution_time'] = '180'

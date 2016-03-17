    script "letsencrypt_init" do
        interpreter "bash"
        user "root"
        cwd "#{deploy[:deploy_to]}/letsencrypt"
        code "screen ./letsencrypt-auto --help 2&1 >> ../letsencrypt-output.log"
    end
    

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

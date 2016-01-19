node[:deploy].each do |app_name, deploy|
    if app_name == 'osticket' then
        template "#{deploy[:deploy_to]}/current/include/ost-config.php" do
            source "ost-config.php.erb"
            mode 0660
            group deploy[:group]

            if platform?("ubuntu")
                owner "deploy"
            elsif platform?("amazon")
                owner "apache"
            end

            variables(
                :database     => (deploy[:database][:database] rescue nil),
                :user         => (deploy[:database][:username] rescue nil),
                :password     => (deploy[:database][:password] rescue nil),
                :host         => (deploy[:database][:host] rescue nil),
                :secret_salt  => (deploy[:osticket][:secret_salt] rescue nil),
                :admin_email  => (deploy[:osticket][:admin_email] rescue nil)
            )
        end
    end    
end
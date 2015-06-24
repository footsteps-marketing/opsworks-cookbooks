# AWS OpsWorks Recipe to configure s3fs-fuse

node[:s3fs][:mounts].each do |bucket, directory|
  bash "mount_s3fs" do
    only_if "which s3fs"
    user "root"
    code <<-EOH
      mkdir --parents "#{directory}"
      s3fs "#{bucket}" "#{directory}" -o use_cache=/tmp -o default_acl=public_read -o allow_other -o gid=$(id -g #{node[:opsworks][:deploy_user][:group]}) -o uid=$(id -g #{node[:opsworks][:deploy_user][:user]}) -o ahbe_conf=/etc/ahbe.conf
    EOH
  end
end


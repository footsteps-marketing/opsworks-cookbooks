# AWS OpsWorks Recipe to configure s3fs-fuse

node[:s3fs][:mounts].each do |bucket, directory|
  #user = node[:opsworks][:deploy_user][:user]
  user = 'www-data'
  #group = node[:opsworks][:deploy_user][:group]
  group = 'www-data'
  bash "mount_s3fs" do
    only_if "which s3fs"
    user "root"
    code <<-EOH
      mkdir --parents "#{directory}"
      unlink "#{directory}"/* || true
      s3fs "#{bucket}" "#{directory}" -o use_cache=/tmp -o default_acl=public-read -o default_permissions -o allow_other -o gid=$(id -g #{group}) -o uid=$(id -u #{user}) -o ahbe_conf=/etc/ahbe.conf
    EOH
  end
end

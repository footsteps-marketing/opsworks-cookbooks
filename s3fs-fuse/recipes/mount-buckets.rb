# AWS OpsWorks Recipe to configure s3fs-fuse

node[:s3fs][:mounts].each do |bucket, directory|
  #user = node[:opsworks][:deploy_user][:user]
  user = 'deploy'
  #group = node[:opsworks][:deploy_user][:group]
  group = 'www-data'
  bash "mount_s3fs" do
    only_if "which s3fs"
    user "root"
    code <<-EOH
      mkdir --parents "#{directory}"
      unlink "#{directory}/*" || true
      s3fs "#{bucket}" "#{directory}" -o use_cache=/tmp -o default_acl=public_read -o allow_other -o gid=$(id -g #{group}) -o uid=$(id -g #{user}) -o ahbe_conf=/etc/ahbe.conf
    EOH
  end
end

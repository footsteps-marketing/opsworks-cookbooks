# AWS OpsWorks Recipe to configure s3fs-fuse

node[:s3fs][:mounts].each do |mount|
  mount_bucket = mount['bucket']
  mount_dir = mount['directory']
  bash "mount_s3fs" do
    only_if "which s3fs"
    user "root"
    code <<-EOH
      s3fs #{bucket} #{directory} -o use_cache=/tmp -o default_acl=public_read -o allow_other -o gid=498 -o uid=498 -o ahbe_conf=/etc/ahbe.conf
    EOH
  end
end


# AWS OpsWorks Recipe to configure s3fs-fuse

node[:s3fs][:mounts].each do |mount|
  mount_dir = mount['directory']
  bash "mount_s3fs" do
    user "root"
    code <<-EOH
      service apache2 restart
      lsof | grep #{directory} && kill $(lsof | grep #{directory} | awk -F ' ' '{print $2}' | sort -u)
      umount #{directory}
    EOH
  end
end


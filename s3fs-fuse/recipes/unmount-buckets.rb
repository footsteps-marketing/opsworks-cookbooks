# AWS OpsWorks Recipe to configure s3fs-fuse

node[:s3fs][:mounts].each do |bucket, directory|
  bash "mount_s3fs" do
    user "root"
    code <<-EOH
      service apache2 restart
      lsof | grep #{directory} && kill $(lsof | grep #{directory} | awk -F ' ' '{print $2}' | sort -u)
      if grep "#{directory}" /etc/mtab &>/dev/null; then
        umount #{directory}
      fi
    EOH
  end
end


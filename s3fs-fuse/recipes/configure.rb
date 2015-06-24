# AWS OpsWorks Recipe to configure s3fs-fuse

if node[:s3fs][:aws_access_key][:id] != false && node[:s3fs][:aws_access_key][:secret] != false
  template "/etc/passwd-s3fs" do
    source "passwd-s3fs.erb"
    mode "600"
    owner "root"
    group "root"
    variables({
      :access_key_id => node[:s3fs][:aws_access_key][:id],
      :access_key_secret => node[:s3fs][:aws_access_key][:secret],
    })
  end
end

template "/etc/ahbe.conf" do
  source "ahbe.conf.erb"
  mode "644"
  owner "root"
  group "root"
end

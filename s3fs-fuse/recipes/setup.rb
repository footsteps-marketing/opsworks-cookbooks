# AWS OpsWorks Recipe to configure s3fs-fuse

node[:s3fs][:packages].each do |pkg|
  package pkg do
    action :install
  end
end

git "/tmp/s3fs" do
  repository "https://github.com/s3fs-fuse/s3fs-fuse.git"
  reference "master"
  action :sync
end

bash "install_s3fs" do
  not_if "which s3fs"
  user "root"
  cwd "/tmp/s3fs"
  code <<-EOH
    ./autogen.sh
    ./configure --prefix=/usr --with-openssl # See (*1)
    make
    sudo make install
  EOH
end

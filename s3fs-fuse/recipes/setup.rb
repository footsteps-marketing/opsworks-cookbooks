# AWS OpsWorks Recipe to configure s3fs-fuse

node[:s3fs][:packages].each do |pkg|
  package pkg do
    action :install
  end
end

bash "install_s3fs" do
  user "root"
  cwd "/tmp"
  code <<-EOH
    git clone https://github.com/s3fs-fuse/s3fs-fuse.git
    cd s3fs-fuse
    ./autogen.sh
    ./configure --prefix=/usr --with-openssl # See (*1)
    make
    sudo make install
  EOH
end

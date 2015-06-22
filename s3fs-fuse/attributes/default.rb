# Default configuration for the s3fs-fuse cookbook

# Packages to install

case node[:platform_family]
when 'debian'
    packages = [
        "build-essential",
        "git",
        "libfuse-dev",
        "libcurl4-openssl-dev",
        "libxml2-dev",
        "mime-support",
        "automake",
        "libtool",
        "pkg-config",
        "libssl-dev"
    ]
end

default[:s3fs][:packages] = packages

# Configuration for access key
default['s3fs']['aws_access_key']['id'] = false
default['s3fs']['aws_access_key']['secret'] = false

#
# Cookbook Name:: jenkins
# Recipe:: proxy_apache2_ssl
#
# Author:: Matt Burke <mburke@crankapps.com>
#
# Copyright 2011, Fletcher Nichol, Matt Burke
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "jenkins::proxy_apache2"
include_recipe "apache2::mod_ssl"
include_recipe "apache2::mod_headers"
include_recipe "apache2::mod_alias"

if node[:jenkins][:http_proxy][:www_redirect] == "enable"
  www_redirect = true
  apache_module "rewrite"
else
  www_redirect = false
end

host_name = node[:jenkins][:http_proxy][:host_name] || node[:fqdn]

template "#{node[:apache][:dir]}/sites-available/jenkins-ssl" do
  source      "apache_jenkins.erb"
  owner       'root'
  group       'root'
  mode        '0644'
  variables(
    :host_name        => host_name,
    :host_aliases     => node[:jenkins][:http_proxy][:host_aliases],
    :listen_ports     => node[:jenkins][:http_proxy][:listen_ports],
    :www_redirect     => www_redirect,
    :ssl              => true
  )

  if File.exists?("#{node[:apache][:dir]}/sites-enabled/jenkins-ssl")
    notifies  :restart, 'service[apache2]'
  end
end

file "/etc/apache2/ssl/jenkins.key" do
  content node[:jenkins][:http_proxy][:ssl_cert_key]
  owner 'root'
  group 'root'
  mode  '0600'
end

file "/etc/apache2/ssl/jenkins.crt" do
  content node[:jenkins][:http_proxy][:ssl_cert]
  owner 'root'
  group 'root'
  mode  '0644'
end

apache_site "000-default" do
  enable  false
end

apache_site "jenkins-ssl" do
  if node[:jenkins][:http_proxy][:variant] == "apache2-ssl"
    enable true
  else
    enable false
  end
end

# PACKAGES
package 'nginx'
package 'vnstat'
package 'git'
package 'python-cheetah'
package 'python-cherrypy3'
package 'python-jinja2'
package 'python-OpenSSL'
package 'python-psutil'
package 'supervisor'
package 'apache2-utils'
package 'transmission-daemon'

# ADD FOLDERS
directory '/home/downloads'
directory '/home/downloads/incomplete'
directory '/home/downloads/processing'
directory '/home/tv'
directory '/home/movies'
directory '/home/music'
directory '/home/other'

# SET UP HOMEPAGE
directory '/opt/homepage'

remote_directory "/opt/homepage" do
  files_mode '0775'
  files_owner 'root'
  mode '0775'
  owner 'root'
  source "homepage"
end

bash 'Set bandwidth limit' do
  user 'root'
  code "sed -i.bak 's/{{MONTHLY_BANDWIDTH}}/"+ENV['MONTHLY_BANDWIDTH']+"/g' /opt/homepage/homepage.py"
end

# Set credentials so vlc can play the videos with the web plugin
# (basic auth needs to be in url, otherwise it wont play)
bash 'set username' do
  user 'root'
  code "sed -i.bak 's/{{username}}/"+ENV['USER']+"/g' /opt/homepage/static/js/cred.js"
end

bash 'set password' do
  user 'root'
  code "sed -i.bak 's/{{password}}/"+ENV['PASSWORD']+"/g' /opt/homepage/static/js/cred.js"
end

bash 'make_vnstat_db' do
  user 'root'
  code <<-EOH
  interfaces="$(vnstat --iflist)"
  if [[ $interfaces == *"venet0"* ]] ; then
    vnstat -u -i venet0
    chown -R vnstat:vnstat /var/lib/vnstat
  fi
  EOH
end

cookbook_file '/etc/supervisor/conf.d/homepage.conf'

service 'supervisor' do
  action :restart
end


# TRANSMISSION SETTINGS
# transmission is the devil. this chunk is hopeless voodoo
bash 'stop stupid transmission' do
  user 'root'
  code <<-EOH
  service transmission-daemon stop
  EOH
end

bash 'rm symlink devil' do
  user 'root'
  code <<-EOH
  rm /var/lib/transmission-daemon/info/settings.json
  EOH
end

cookbook_file '/etc/transmission-daemon/settings.json'
cookbook_file '/var/lib/transmission-daemon/info/settings.json'

bash 'run transmission as root >:D' do
  user 'root'
  code "sed -i.bak 's/setuid debian-transmission/setuid root/g' /etc/init/transmission-daemon.conf"
end

bash 'start stupid transmission' do
  user 'root'
  code <<-EOH
  service transmission-daemon start
  EOH
end

bash 'stop stupid transmission' do
  user 'root'
  code <<-EOH
  service transmission-daemon stop
  EOH
end

cookbook_file '/etc/transmission-daemon/settings.json'
cookbook_file '/var/lib/transmission-daemon/info/settings.json'

bash 'start stupid transmission' do
  user 'root'
  code <<-EOH
  service transmission-daemon start
  EOH
end


# TRANSMISSION CLEANER
cookbook_file '/etc/cron.hourly/transmission_clean'

bash 'set trans clean permissions' do
  user 'root'
  code <<-EOH
  chmod +x /etc/cron.hourly/transmission_clean
  EOH
end

# INSTALL COUCHPOTATO
git '/opt/couchpotato' do
  repository 'https://github.com/RuudBurger/CouchPotatoServer.git'
  reference 'master'
  action :checkout
end

directory '/var/opt/couchpotato'
cookbook_file '/var/opt/couchpotato/settings.conf'
cookbook_file '/etc/default/couchpotato'

bash 'set couchpotato to start on boot' do
  user 'root'
  cwd '/opt/couchpotato'
  code <<-EOH
  cp init/ubuntu /etc/init.d/couchpotato
  chmod +x /etc/init.d/couchpotato
  update-rc.d couchpotato defaults
  EOH
end

service 'couchpotato' do
  action :start
end


# INSTALL SICKRAGE
git '/opt/sickbeard' do
  repository 'https://github.com/SiCKRAGETV/SickRage.git'
  revision 'master'
  action :checkout
end

cookbook_file '/etc/default/sickbeard'

bash 'set sickbeard to start on boot' do
  user 'root'
  cwd '/opt/sickbeard'
  code <<-EOH
  cp init.ubuntu /etc/init.d/sickbeard
  chmod +x /etc/init.d/sickbeard
  update-rc.d sickbeard defaults
  EOH
  not_if { ::File.exists?('/etc/init.d/sickbeard') }
end

service 'sickbeard' do
  action :start
end

service 'sickbeard' do
  action :stop
end

cookbook_file '/opt/sickbeard/sickbeard_config.ini'
bash 'set sickbeard config' do
  user 'root'
  cwd '/opt/sickbeard'
  code <<-EOH
  rm config.ini
  mv sickbeard_config.ini config.ini
  EOH
end

service 'sickbeard' do
  action :start
end

# INSTALL HEADPHONES
git '/opt/headphones' do
  repository 'https://github.com/rembo10/headphones.git'
  revision 'develop'
  action :checkout
end

cookbook_file '/etc/default/headphones'
cookbook_file '/opt/headphones/headphones_config.ini'

bash 'set headphones config' do
  user 'root'
  cwd '/opt/headphones'
  code <<-EOH
  rm config.ini
  mv headphones_config.ini config.ini
  EOH
end

bash 'set headphones to start on boot' do
  user 'root'
  cwd '/opt/headphones'
  code <<-EOH
  cp init-scripts/init.ubuntu /etc/init.d/headphones
  chmod +x /etc/init.d/headphones
  update-rc.d headphones defaults
  EOH
  not_if { ::File.exists?('/etc/init.d/headphones') }
end

service 'headphones' do
  action :start
end

# PREP CERT FOR NGINX
directory '/opt/certs/'
directory '/etc/nginx/ssl/'
cookbook_file '/opt/certs/gencert.sh'

bash 'prep cert' do
  user 'root'
  cwd '/opt/certs/'
  code <<-EOH
  chmod +x gencert.sh
  ./gencert.sh
  EOH
  not_if { ::File.exists?('/opt/certs/server.key') }
end

# PREP BASIC AUTH
directory '/etc/nginx/auth/'

bash 'prep auth' do
  user 'root'
  cwd '/etc/nginx/auth/'
  code 'htpasswd -b -c .htpasswd ' + ENV['USER'] + ' ' + ENV['PASSWORD']
  not_if { ::File.exists?('/etc/nginx/auth/.htpassd') }
end

# SET UP NGINX REVERSE PROXY
cookbook_file '/etc/nginx/sites-available/default'
cookbook_file '/etc/nginx/auth.conf'
cookbook_file '/etc/nginx/ssl.conf'
cookbook_file '/etc/nginx/proxy.conf'
cookbook_file '/etc/nginx/favicons.conf'
cookbook_file '/etc/nginx/mime.types'

link '/etc/nginx/sites-enabled/default' do
  to '/etc/nginx/sites-available/default'
end

service 'nginx' do
  action :restart
end

service 'apache2' do
  action :stop
end

# IPTABLES IT UP!
bash 'firewalls' do
  user 'root'
  code <<-EOH
  iptables -A INPUT -p tcp -s localhost --dport 5050 -j ACCEPT
  iptables -A INPUT -p tcp --dport 5050 -j DROP
  iptables -A INPUT -p tcp -s localhost --dport 9091 -j ACCEPT
  iptables -A INPUT -p tcp --dport 9091 -j DROP
  iptables -A INPUT -p tcp -s localhost --dport 8081 -j ACCEPT
  iptables -A INPUT -p tcp --dport 8081 -j DROP
  iptables -A INPUT -p tcp -s localhost --dport 8181 -j ACCEPT
  iptables -A INPUT -p tcp --dport 8181 -j DROP
  iptables -A INPUT -p tcp -s localhost --dport 4004 -j ACCEPT
  iptables -A INPUT -p tcp --dport 4004 -j DROP
  EOH
end

# ANTI-LOGGING (?)
cookbook_file '/opt/50-default.conf'
cookbook_file '/opt/syslog.conf'

bash 'ssh logging rsyslog' do
  user 'root'
  code <<-EOH
  cp /opt/50-default.conf /etc/rsyslog.d/50-default.conf
  service rsyslog restart
  EOH
  not_if { ::File.exists?('/etc/syslog.conf') }
end

bash 'ssh logging syslog' do
  user 'root'
  code <<-EOH
  cp /opt/syslog.conf /etc/syslog.conf
   /etc/init.d/sysklogd restart
  EOH
  not_if { ::File.exists?('/etc/rsyslog.d/50-default.conf') }
end

bash 'nuke wtmp' do
  user 'root'
  code 'rm /var/log/wtmp && ln -s /dev/null /var/log/wtmp'
end

bash 'nuke btmp' do
  user 'root'
  code 'rm /var/log/btmp && ln -s /dev/null /var/log/btmp'
end

bash 'nuke lastlog' do
  user 'root'
  code 'rm /var/log/lastlog && ln -s /dev/null /var/log/lastlog'
end

bash 'nuke utmp' do
  user 'root'
  code 'rm /var/run/utmp && ln -s /dev/null /var/run/utmp'
end

cookbook_file '/etc/logrotate.conf'

# PARTY
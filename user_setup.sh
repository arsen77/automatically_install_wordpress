#!/bin/bash -e

username=$1
password=`tr -dc A-Za-z0-9 < /dev/urandom | head -c 12 | xargs`
database_extension="_wp"
database=$username$database_extension
domain=$username'.dev.yourdomain.co.uk' # change this to your domain

mysql_root_password='password123'

# ip's for web server (change this)
server_ipv4='192.168.0.1'
server_ipv6='0:0:0:0:0:0:0:1'

webserver_group='www-data'

# Add user
sudo adduser --disabled-password --gecos "" $username
echo $username:$password | sudo chpasswd

# Create database, user and set password
query="CREATE DATABASE $database; CREATE USER '$username'@'localhost' IDENTIFIED BY '$password'; GRANT ALL PRIVILEGES ON $database.* TO '$username'@'localhost'; FLUSH PRIVILEGES;"

echo $query
mysql --user="root" --password="$mysql_root_password" --execute="$query"

apache_config=/etc/apache2/sites-enabled/$domain

# create the vhost
sudo echo "<VirtualHost *:80>
        ServerAdmin you@yourdomain.co.uk
        ServerName $domain
        ServerAlias www.$domain
        DocumentRoot /home/$username/public_html/
        <Directory /home/$username/public_html/>
                Options MultiViews Indexes FollowSymLinks
                AllowOverride all
        </Directory>
</VirtualHost>" > $apache_config

htaccess_content="# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>

# END WordPress"

# download and extract wordpress to user directory under public_html
sudo -H -u $username bash -c "
cd /home/$username/; 
wget -O /home/$username/latest.tar.gz https://wordpress.org/latest.tar.gz --no-check-certificate; 
tar xzvf /home/$username/latest.tar.gz -C /home/$username/; 
mv /home/$username/wordpress /home/$username/public_html; 
rm /home/$username/latest.tar.gz; 
cp /home/$username/public_html/wp-config-sample.php /home/$username/public_html/wp-config.php; 
sed -i 's/database_name_here/$database/' /home/$username/public_html/wp-config.php; 
sed -i 's/username_here/$username/' /home/$username/public_html/wp-config.php; 
sed -i 's/password_here/$password/' /home/$username/public_html/wp-config.php; 
mkdir /home/$username/public_html/wp-content/uploads;
echo '$htaccess_content'> /home/$username/public_html/.htaccess"

# set permissions so it's writable by the user and web server
sudo chown -R $user:$webserver_group /home/$username/public_html/
sudo chmod -R 774 /home/$username/public_html/

# make the config readable 
sudo -H -u $username bash -c "chmod 660 /home/$username/public_html/wp-config.php;"

# create the A record
curl https://www.cloudflare.com/api_json.html \
  -d "a=rec_new" \
  -d "tkn=your_api_key" \
  -d "email=you@yourdomain.co.uk" \
  -d "z=yourdomain.co.uk" \
  -d "type=A" \
  -d "name=$domain" \
  -d "ttl=1" \
  -d "content=$server_ipv4"

# create the AAAA record
curl https://www.cloudflare.com/api_json.html \
  -d "a=rec_new" \
  -d "tkn=your_api_key" \
  -d "email=you@yourdomain.co.uk" \
  -d "z=yourdomain.co.uk" \
  -d "type=AAAA" \
  -d "name=$domain" \
  -d "ttl=1" \
  -d "content=$server_ipv6"

# reload web server to take on new vhost
sudo /etc/init.d/apache2 reload

echo "
=============================
 Welcome details 
=============================
Congratulations, your website has been set up.
You can access your website at: http://$domain

Your site login details:

username: $username
password: $password

Please note that this is only a temporary development URL and once you are happy with the site we can change it to your domain name. Please let us know if you have any questions.

Thanks,
Vixre Team
info@yourdomain.co.uk"
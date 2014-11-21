automatically_install_wordpress
===============================

It’s a bash script that starts at the beginning by creating a user on the server, installs the database, creates relevant directories, downloads wordpress and assigns permissions and all the way to using the cloudflare DNS api to create the records and creating a welcome message. The idea was to just type one command and a site is ready for use like so:

./install.sh examplesolutionsltd

which would result in a brand new wordpress site at: examplesolutionsltd.dev.vixre.co.uk

Server details: Debian stable, Apache2, MySQL/MariaDB, PHP, cURL, wget

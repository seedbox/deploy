#!/bin/sh

if [ $# -ne 4 ]; then
	echo " "
    echo "Hey! You're missing some parameters!"
    echo " "
    echo "The installer won't work right unless you pass in:"
    echo "- 1, 2: The username/password you want to use"
    echo "- 3: Your server's IP address so we can make an SSL certificate"
    echo "- 4: Your monthly bandwidth limit in Gb, so you can monitor it"
    echo " "
    echo "Usage:"
    echo " "
    echo "    wget -qO- https://raw.githubusercontent.com/seedbox/deploy/master/install.sh | sh -s USERNAME PASSWORD SERVER_IP BANDWITH_LIMIT"
    echo " "
    exit 1
fi

echo " "
echo " ______     ______     ______     _____     ______     ______     __  __"
echo "/\  ___\   /\  ___\   /\  ___\   /\  __-.  /\  == \   /\  __ \   /\_\_\_\\"
echo "\ \___  \  \ \  __\   \ \  __\   \ \ \/\ \ \ \  __<   \ \ \/\ \  \/_/\_\/_"
echo " \/\_____\  \ \_____\  \ \_____\  \ \____-  \ \_____\  \ \_____\   /\_\/\_\\"
echo "  \/_____/   \/_____/   \/_____/   \/____/   \/_____/   \/_____/   \/_/\/_/"
echo " "
echo " "

# Get all the files for chef & run it
wget https://github.com/seedbox/deploy/raw/master/chef.tar.gz

# xtract ze files
tar -xzf chef.tar.gz

sh ./run-chef.sh $1 $2 $3 $4
#!/bin/bash                                                                       Modified

# Prompt the user for input
echo "Enter a domain name:"
read domain_name

# Define the directory path
directory_path="/var/www/$domain_name"

# Check if the directory already exists
if [ -d "$directory_path" ]; then
    echo "Directory '$domain_name' already exists."

    # Ask the user whether to replace or skip
    echo "Do you want to replace the existing directory? (y/n)"
    read replace_option

    if [ "$replace_option" = "y" ]; then
        # Remove existing directory
        sudo rm -r "$directory_path"
        echo "Existing directory removed."
        mkdir "$directory_path"

    else
        echo "Directory creation skipped."

    fi

else
    mkdir "$directory_path"
fi

# if [ -d "$directory_path" ]; then

# else
# # Create the directory
# mkdir "$directory_path"
# fi

# Check if the directory was created successfully
if [ $? -eq 0 ]; then
    echo "Directory '$domain_name' created successfully."

    # Change ownership to the current user
    sudo chown -R $USER:$USER "/var/www/$domain_name"

    # Check if ownership change was successful
    if [ $? -eq 0 ]; then
        echo "Ownership changed to $USER:$USER."

        # Change permissions
        sudo chmod -R 755 "/var/www/$domain_name"

        # Check if permissions change was successful
        if [ $? -eq 0 ]; then
            echo "Permissions set to 755 for '$domain_name'."

            # Add HTML code to index.html
            echo "<html>
             <head>
                 <title>Welcome to $domain_name!</title>
             </head>
             <body>
                 <h1>Success! The $domain_name virtual host is working!</h1>
             </body>
             </html>" | sudo tee "/var/www/$domain_name/index.html" >/dev/null

            echo "HTML code added to index.html for '$domain_name'."

            confPath="/etc/apache2/sites-available/$domain_name.conf"

            # Check if the directory already exists
            if [ -f "$confPath" ]; then
                echo "apache conf for '$domain_name' already exists."

                # Ask the user whether to replace or skip
                echo "Do you want to replace the existing apache conf? (y/n)"
                read replace_option

                if [ "$replace_option" = "y" ]; then
                    # Remove existing directory
                    sudo rm -rf "$confPath"
                    echo "Existing conf removed."

                    # Add virtual host configuration to Apache

                    echo "Virtual host configuration added for '$domain_name'."
                else
                    echo "Directory creation skipped."

                fi
            fi
            if [ ! -f "$confPath" ]; then
                echo "
        <VirtualHost *:80>
             ServerName $domain_name
             ServerAlias www.$domain_name
             ServerAdmin webmaster@localhost
             DocumentRoot /var/www/$domain_name
             ErrorLog ${APACHE_LOG_DIR}/error.log
             CustomLog ${APACHE_LOG_DIR}/access.log combined
        </VirtualHost>

        <VirtualHost *:443>
             ServerName $domain_name
             DocumentRoot /var/www/$domain_name
             SSLEngine on
             SSLCertificateFile /etc/ssl/$domain_name/certificate.crt
             SSLCertificateKeyFile /etc/ssl/$domain_name/private.key
             SSLCertificateChainFile /etc/ssl/$domain_name/ca_bundle.crt
        </VirtualHost>" | sudo tee "/etc/apache2/sites-available/$domain_name.conf" >/dev/null

            fi

            # Enable the new virtual host
            sudo a2ensite "$domain_name.conf"

            sudo a2enmod ssl
            sudo a2enmod headers

            echo "ssl enabled"

            # Disable the default virtual host
            sudo a2dissite 000-default.conf

            # Test the Apache configuration
            sudo apache2ctl configtest

            echo "Apache configuration test completed."

            # Restart Apache to apply changes
            sudo systemctl restart apache2

            echo "Apache restarted."
        else
            echo "Error setting permissions for '$domain_name'."
            exit 1
        fi
    else
        echo "Error changing ownership to $USER:$USER."
        exit 1
    fi
else
    echo "Error creating directory '$domain_name'."
    exit 1
fi

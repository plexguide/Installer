#!/bin/bash

    # Create PlexGuide Commands
    if [[ ! -f "/usr/local/bin/plexguide" ]]; then
        sudo ln -s /pg/scripts/menu.sh /usr/local/bin/plexguide
        sudo chmod +x /usr/local/bin/plexguide
        bash /pg/scripts/menu_exit.sh
    fi

    if [[ ! -f "/usr/local/bin/pg" ]]; then
        sudo ln -s /pg/scripts/menu.sh /usr/local/bin/pg
        sudo chmod +x /usr/local/bin/pg
        bash /pg/scripts/menu_exit.sh
    fi

    if [[ ! -f "/usr/local/bin/pgalpha" ]]; then
        sudo ln -s /pg/scripts/menu_reinstall.sh /usr/local/bin/pgalpha        
        sudo chmod +x /usr/local/bin/pgalpha
        bash /pg/scripts/menu_exit.sh
    fi

    if [[ ! -f "/usr/local/bin/pgbeta" ]]; then
        sudo ln -s /pg/scripts/install_beta.sh /usr/local/bin/pgbeta       
        sudo chmod +x /usr/local/bin/pgbeta
        bash /pg/scripts/menu_exit.sh
    fi
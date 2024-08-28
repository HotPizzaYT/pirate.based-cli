#!/bin/bash
echo -e "\e[1;31m=== pirate.based ===\e[0;00m"
echo -e "Type \e[1;32m+b\e[0;00m to use a custom HTTP proxy"
echo -e "Type \e[1;31m-b\e[0;00m to use a custom server"

proxy="none"
server="https://apibay.org"

convert_size() {
    local size=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local i=0
    local divisor=1024

    # Use `bc` to handle floating-point arithmetic
    while (( $(echo "$size >= $divisor" | bc -l) && i < ${#units[@]} - 1 )); do
        size=$(echo "scale=2; $size / $divisor" | bc)
        i=$((i + 1))
    done

    echo "$size ${units[i]}"
}

query() {
    read -p "$(echo -e "\e[1;33mEnter query: \e[0;00m")" query
    if [[ "$query" == "+b" ]]; then
        read -p "$(echo -e "\e[1;96mEnter HTTP proxy login info (You still need a VPN) (ex. http://user:pwd@127.0.0.1:1234): \e[0;0m")" proxy
        query  # Recursive call to re-enter the query after setting the proxy
    elif [[ "$query" == "-b" ]]; then
        read -p "$(echo -e "\e[1;96mEnter custom domain (You still need a VPN) (ex. http://example.com) WITHOUT A TRAILING SLASH: \e[0;0m")" server
        query  # Recursive call to re-enter the query after setting the server
    else
        if [[ "$proxy" == "none" ]]; then
            echo "Using server $server"
            response=$(curl -s "$server/q.php?q=$(jq -nr --arg v "$query" '$v|@uri')")
        else
            echo "Using server $server"
            echo "Using proxy server $proxy ."
            response=$(curl -s --proxy "$proxy" "$server/q.php?q=$(jq -nr --arg v "$query" '$v|@uri')")
        fi

        ids=$(echo "$response" | jq -r '.[] | .id')
        names=$(echo "$response" | jq -r '.[] | .name')
        sizes=$(echo "$response" | jq -r '.[] | .size')
        seeders=$(echo "$response" | jq -r '.[] | .seeders')
        leechers=$(echo "$response" | jq -r '.[] | .leechers')

        # Initialize a counter for the selection menu
        counter=1

        # Loop through each item and display id, name, and size
        for id in $ids; do
            name=$(echo "$names" | sed -n "${counter}p")
            size=$(echo "$sizes" | sed -n "${counter}p")
            seeder=$(echo "$seeders" | sed -n "${counter}p")
            leecher=$(echo "$leechers" | sed -n "${counter}p")
            size_new=$(convert_size $size)
            echo -e "\e[1;36m${counter}.\e[0;00m \e[1;97m${name}\e[0;00m | size: \e[1;33m${size_new}\e[0;00m | SE: \e[1;32m${seeder}\e[0;00m | LE: \e[1;91m${leecher}\e[0;00m"
            echo ""
            counter=$((counter + 1))
        done

        # Prompt the user to select an option
        read -p "$(echo -e "\e[1;33mSelect an option by number. Type restart to make a new query: \e[0;00m")" selection
        if [[ "$selection" == "restart" ]]; then
            query
        fi

        # Do something with the selected id
        selected_id=$(echo "$ids" | sed -n "${selection}p")

        echo "Selecting torrent with id: $selected_id"
        echo ""
        echo "==== TORRENT INFORMATION ===="
        if [[ "$proxy" == "none" ]]; then
            response_id=$(curl -s "$server/t.php?id=$selected_id")
            # echo "Debug: $server/t.php?q=$selected_id"
        else
            response_id=$(curl -s --proxy "$proxy" "$server/t.php?id=$selected_id")
        fi
        num_files=$(echo "$response_id" | jq -r ".num_files")
        added=$(echo "$response_id" | jq -r ".added")
        addeddate=$(date -d @"$added" "+%Y-%m-%d %H:%M:%S")
        desc=$(echo "$response_id" | jq -r ".descr")
        hash=$(echo "$response_id" | jq -r ".info_hash")
        namefromt=$(echo "$response_id" | jq -r ".name")
        nameoftor=$(jq -nr --arg v "$namefromt" '$v|@uri')
        final="magnet:?xt=urn:btih:${hash}&dn=${nameoftor}&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A6969%2Fannounce&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce&tr=udp%3A%2F%2Ftracker.bittor.pw%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337&tr=udp%3A%2F%2Fpublic.popcorn-tracker.org%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.dler.org%3A6969%2Fannounce&tr=udp%3A%2F%2Fexodus.desync.com%3A6969&tr=udp%3A%2F%2Fopentracker.i2p.rocks%3A6969%2Fannounce"
        echo "Num of files: $num_files"
        echo ""
        echo "Added on: $addeddate"
        echo ""
        echo "Description:"
        echo ""
        echo "$desc"
        echo ""
        echo "Hash:"
        echo ""
        echo "$final"
        echo ""
        read -p "Would you like to attempt to open the torrent link in a application? (Desktop OSes only!) (PLEASE TURN ON YOUR VPN NOW) [Y/N]: " yesorno
        if [[ "$yesorno" == "Y" ]] || [[ "$yesorno" == "y" ]]; then
            xdg-open "$final"
            read -n 1 -s -r -p "Press any key to continue browsing for torrents"
            query

        else
            echo "Canceled operation. Copy the hash now and go to your favorite torrent app."
        fi



    fi
}

# Start the query process
query

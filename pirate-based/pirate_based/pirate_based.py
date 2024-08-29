# pirate_based.py

import subprocess
import requests
import json
import os
import platform
import webbrowser
import urllib.parse
from datetime import datetime


# Define defaults
proxy = "none"
server = "https://apibay.org"

# Prepare cross platform terminal coloring
if platform.system() == "Windows":
    os.system("")
# Define code for converting filesize
def convert_size(size_bytes):
    units = ["B", "KB", "MB", "GB", "TB"]
    size = float(size_bytes)
    i = 0
    while size >= 1024 and i < len(units) - 1:
        size /= 1024
        i += 1
    return f"{size:.2f} {units[i]}"

def query():
    global proxy, server

    user_query = input("\033[1;33mEnter query: \033[0;00m")

    if user_query == "+b":
        proxy = input("\033[1;96mEnter HTTP proxy login info (You still need a VPN) (ex. http://user:pwd@127.0.0.1:1234): \033[0;00m")
        query()  # Recursive call to re-enter the query after setting the proxy
    elif user_query == "-b":
        server = input("\033[1;96mEnter custom domain (You still need a VPN) (ex. http://example.com) WITHOUT A TRAILING SLASH: \033[0;00m")
        query()  # Recursive call to re-enter the query after setting the server
    else:
        if proxy == "none":
            print(f"Using server {server}")
            response = requests.get(f"{server}/q.php?q={user_query}")
        else:
            print(f"Using server {server}")
            print(f"Using proxy server {proxy}.")
            proxies = {"http": proxy, "https": proxy}
            response = requests.get(f"{server}/q.php?q={user_query}", proxies=proxies)

        if response.status_code == 200:
            data = response.json()
            ids = [item['id'] for item in data]
            names = [item['name'] for item in data]
            sizes = [item['size'] for item in data]
            seeders = [item['seeders'] for item in data]
            leechers = [item['leechers'] for item in data]

            for i, (id, name, size, seeder, leecher) in enumerate(zip(ids, names, sizes, seeders, leechers), 1):
                size_new = convert_size(size)
                print(f"\033[1;36m{i}.\033[0;00m \033[1;97m{name}\033[0;00m | size: \033[1;33m{size_new}\033[0;00m | SE: \033[1;32m{seeder}\033[0;00m | LE: \033[1;91m{leecher}\033[0;00m\n")

            selection = input("\033[1;33mSelect an option by number. Type restart to make a new query: \033[0;00m")

            if selection == "restart":
                query()
            else:
                selected_id = ids[int(selection) - 1]
                print(f"Selecting torrent with id: {selected_id}\n")
                print("==== TORRENT INFORMATION ====")

                if proxy == "none":
                    response_id = requests.get(f"{server}/t.php?id={selected_id}")
                else:
                    response_id = requests.get(f"{server}/t.php?id={selected_id}", proxies=proxies)

                if response_id.status_code == 200:
                    details = response_id.json()
                    num_files = details.get("num_files", "N/A")
                    added = details.get("added", "N/A")
                    addeddate = datetime.fromtimestamp(int(added)).strftime("%Y-%m-%d %H:%M:%S")
                    desc = details.get("descr", "No description available.")
                    hash_value = details.get("info_hash", "N/A")
                    namefromt = details.get("name", "N/A")

                    nameoftor = urllib.parse.quote(namefromt)
                    final = f"magnet:?xt=urn:btih:{hash_value}&dn={nameoftor}&tr=udp%3A%2F%2Ftracker.coppersurfer.tk%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A6969%2Fannounce&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce&tr=udp%3A%2F%2Ftracker.bittor.pw%3A1337%2Fannounce&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337&tr=udp%3A%2F%2Fpublic.popcorn-tracker.org%3A6969%2Fannounce&tr=udp%3A%2F%2Ftracker.dler.org%3A6969%2Fannounce&tr=udp%3A%2F%2Fexodus.desync.com%3A6969&tr=udp%3A%2F%2Fopentracker.i2p.rocks%3A6969%2Fannounce"

                    print(f"Num of files: {num_files}\n")
                    print(f"Added on: {addeddate}\n")
                    print("Description:\n")
                    print(f"{desc}\n")
                    print("Hash:\n")
                    print(f"{final}\n")

                    yesorno = input("Would you like to attempt to open the torrent link in an application? (Desktop OSes only!) (PLEASE TURN ON YOUR VPN NOW) [Y/N]: ")
                    if yesorno.lower() == "y":
                        if platform.system() == "Windows":
                            webbrowser.open(final)
                        else:
                            # Found a cross platform way of opening magnets

                            webbrowser.open(final)
                            # subprocess.Popen(["pkill", "ktorrent"])
                            # subprocess.Popen(["xdg-open", final])

                        input("Press any key to continue browsing for torrents")
                        query()
                    else:
                        print("Canceled operation. Copy the hash now and go to your favorite torrent app.")
                else:
                    print("Failed to retrieve torrent details.")
        else:
            print("Failed to retrieve query results.")

def main():
    print("\033[1;31m=== pirate.based ===\033[0;00m")
    print("Type \033[1;32m+b\033[0;00m to use a custom HTTP proxy")
    print("Type \033[1;31m-b\033[0;00m to use a custom server")
    query()

if __name__ == "__main__":
    main()

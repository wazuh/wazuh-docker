import logging
import sys
import json
import random
import string
import os
import re
# Set framework path
sys.path.append(os.path.dirname(sys.argv[0]) + "/../framework")
WUI_USER_FILE_PATH = "/var/ossec/api/configuration/wui-user.json"
WAZUH_USER_FILE_PATH = "/var/ossec/api/configuration/wazuh-user.json"
try:
    from wazuh.security import (
        create_user,
        get_users,
        get_roles,
        set_user_role,
        update_user,
    )
except Exception as e:
    logging.error("No module 'wazuh' found.")
    sys.exit(1)

def read_wui_user_file(path=WUI_USER_FILE_PATH):
    with open(path) as wui_user_file:
        data = json.load(wui_user_file)
        return data["password"]

def read_wazuh_user_file(path=WAZUH_USER_FILE_PATH):
    with open(path) as wazuh_user_file:
        data = json.load(wazuh_user_file)
        return data["password"]

def db_users():
    users_result = get_users()
    return {user["username"]: user["id"] for user in users_result.affected_items}

if __name__ == "__main__":
    if not os.path.exists(WUI_USER_FILE_PATH):
        # abort if no user file detected
        sys.exit(0)

    wui_password = read_wui_user_file()
    wazuh_password = read_wazuh_user_file()
    initial_users = db_users()

    # set a random password for all other users (not wazuh-wui)
    for name, id in initial_users.items():
        custom_pass = None
        if name == "wazuh-wui":
            custom_pass = wui_password
        elif name == "wazuh":
            custom_pass = wazuh_password
        if custom_pass:
            update_user(
                user_id=[
                    str(id),
                ],
                password=custom_pass,
            )
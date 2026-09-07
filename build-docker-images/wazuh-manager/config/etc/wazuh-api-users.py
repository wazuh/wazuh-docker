#!/usr/bin/env python3
# Wazuh App Copyright (C) 2017, Wazuh Inc. (License GPLv2)
"""Set the password of the Wazuh API default users on this node.

Reads ``WAZUH_API_CREDENTIALS``, one ``user=password`` per line, from the
environment rather than from the command line: an argument list is readable by
anything that can see ``/proc``. Writes directly to the RBAC database, so it
does not need the API to be answering.

Used by password-tool.sh. See docs/ref/credentials.md.
"""

import os
import sys

# The identifier of a default user is its position in the file the framework
# seeds the database from, and the API addresses them by it.
USER_IDS = {"wazuh": 1, "wazuh-wui": 2}


def main() -> int:
    targets = {}
    for line in os.environ.get("WAZUH_API_CREDENTIALS", "").splitlines():
        if "=" in line:
            user, password = line.split("=", 1)
            targets[user] = password

    if not targets:
        print("password-tool.sh: no Wazuh API passwords given", file=sys.stderr)
        return 1

    try:
        import wazuh.rbac.orm as orm
    except Exception as exc:  # noqa: BLE001
        print(f"password-tool.sh: cannot load the Wazuh RBAC package: {exc}", file=sys.stderr)
        return 1

    try:
        orm.check_database_integrity()
        orm.db_manager.connect(orm.DB_FILE)
    except Exception as exc:  # noqa: BLE001
        print(f"password-tool.sh: cannot open the Wazuh API user database: {exc}", file=sys.stderr)
        return 1

    status = 0
    try:
        with orm.AuthenticationManager(orm.db_manager.sessions[orm.DB_FILE]) as auth:
            for username, password in targets.items():
                user_id = USER_IDS.get(username)
                if user_id is None or not auth.get_user(username):
                    print(f"password-tool.sh: unknown Wazuh API user '{username}'", file=sys.stderr)
                    status = 1
                    continue

                if not auth.update_user(user_id, password):
                    print(f"password-tool.sh: could not set the password of '{username}'", file=sys.stderr)
                    status = 1
    except Exception as exc:  # noqa: BLE001
        print(f"password-tool.sh: cannot set the Wazuh API passwords: {exc}", file=sys.stderr)
        status = 1
    finally:
        try:
            orm.db_manager.close_sessions()
        except Exception:  # noqa: BLE001
            pass

    return status


if __name__ == "__main__":
    sys.exit(main())

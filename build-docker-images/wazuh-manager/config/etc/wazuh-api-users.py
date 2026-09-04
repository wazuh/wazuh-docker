#!/usr/bin/env python3
# Wazuh App Copyright (C) 2017, Wazuh Inc. (License GPLv2)
"""Apply or verify the recorded Wazuh API passwords on this node's RBAC database.

Reads ``WAZUH_API_CREDENTIALS``, one ``user=password`` per line, from the
environment rather than from the command line: an argument list is readable by
anything that can see ``/proc``. ``--verify`` reports whether each password
authenticates instead of changing anything; otherwise the database is created
when missing and every password that does not match is set.

See docs/ref/credentials.md.
"""

import os
import sys

# The identifier of a default user is its position in the file the framework
# seeds the database from, and the API addresses them by it.
USER_IDS = {"wazuh": 1, "wazuh-wui": 2}


def main() -> int:
    verify = "--verify" in sys.argv[1:]

    targets = {}
    for line in os.environ.get("WAZUH_API_CREDENTIALS", "").splitlines():
        if "=" in line:
            user, password = line.split("=", 1)
            targets[user] = password

    if not targets:
        print("[credentials] ERROR: no Wazuh API passwords given")
        return 1

    try:
        import wazuh.rbac.orm as orm
    except Exception as exc:  # noqa: BLE001
        print(f"[credentials] ERROR: cannot load the Wazuh RBAC package: {exc}")
        return 1

    try:
        orm.check_database_integrity()
        orm.db_manager.connect(orm.DB_FILE)
    except Exception as exc:  # noqa: BLE001
        print(f"[credentials] ERROR: cannot open the Wazuh API user database: {exc}")
        return 1

    status = 0
    try:
        with orm.AuthenticationManager(orm.db_manager.sessions[orm.DB_FILE]) as auth:
            for username, password in targets.items():
                user_id = USER_IDS.get(username)
                if user_id is None or not auth.get_user(username):
                    print(f"[credentials] ERROR: unknown Wazuh API user '{username}'")
                    status = 1
                    continue

                matches = auth.check_user(username, password)

                if verify:
                    print(f"  {'ok  ' if matches else 'FAIL'}  {username}")
                    status = status or (0 if matches else 1)
                    continue

                if matches:
                    continue

                if auth.update_user(user_id, password):
                    print(f"[credentials] Set the password of the Wazuh API user '{username}'")
                else:
                    print(f"[credentials] ERROR: could not set the password of '{username}'")
                    status = 1
    except Exception as exc:  # noqa: BLE001
        print(f"[credentials] ERROR: cannot set the Wazuh API passwords: {exc}")
        status = 1
    finally:
        try:
            orm.db_manager.close_sessions()
        except Exception:  # noqa: BLE001
            pass

    return status


if __name__ == "__main__":
    sys.exit(main())

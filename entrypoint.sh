#!/bin/sh
set -euf -o pipefail

STATFILE=~/h2.status
echo "STARTING" > "$STATFILE"

if [ -z "$H2_PASSWD" ]; then
	echo "No database password specified, please define the H2_PASSWD environment variable." 2>&1
	echo "FAILURE" > "$STATFILE"
	exit 10
fi

{
	if /usr/bin/java -cp "/opt/h2database/h2.jar:/opt/h2database/dependency-check-core.jar" org.h2.tools.Shell -url "jdbc:h2:$H2_DATABASE" -user "$H2_USER" -password "$H2_INITPASSWD" -sql "ALTER USER $H2_USER SET PASSWORD '$H2_PASSWD';"; then
		echo "STARTED" > "$STATFILE"
	else
		echo "FAILURE" > "$STATFILE"
		echo "Unable to alter database password" 2>&1
		killall java
		exit 1
	fi
} &

exec /usr/bin/java -cp "/opt/h2database/h2.jar:/opt/h2database/dependency-check-core.jar" org.h2.tools.Server "$@"

#!/bin/sh
set -euf -o pipefail

STATFILE=~/h2.status
echo "STARTING" | tee "$STATFILE"

if [ -z "$H2_PASSWD" ]; then
	echo "No database password specified, please define the H2_PASSWD environment variable." 2>&1
	echo "FAILURE" | tee "$STATFILE"
	exit 10
fi

{
	sleep 2
	if ! /usr/bin/java -cp '/opt/h2database/h2.jar:/opt/h2database/dependency-check-core.jar' org.h2.tools.Shell -url "jdbc:h2:tcp://localhost/$H2_DATABASE" -user "$H2_USER" -password "$H2_PASSWD" -sql 'SELECT 1;' 2>&1 | head -n 1; then
		echo "Initializing dependency check database"
		if ! /usr/bin/java -cp '/opt/h2database/h2.jar:/opt/h2database/dependency-check-core.jar' org.h2.tools.RunScript -url "jdbc:h2:$H2_DATABASE" -user "$H2_USER" -password "$H2_PASSWD" -script /opt/h2database/initialize.sql; then
			echo "FAILURE" | tee "$STATFILE"
			killall java
			exit 1
		fi
	fi

	echo "STARTED" | tee "$STATFILE"
} &

exec /usr/bin/java -cp '/opt/h2database/h2.jar:/opt/h2database/dependency-check-core.jar' org.h2.tools.Server "$@"

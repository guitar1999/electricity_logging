#!/bin/bash

stat=$(/usr/local/pgsql94/bin/psql -t -A -c "SELECT CURRENT_TIMESTAMP - MAX(measurement_time) > interval '2 minutes' FROM electricity_measurements;")
notified=$(/usr/local/pgsql94/bin/psql -t -A -c "SELECT notified FROM error_notification WHERE error = 'electricity usage timeout';")

if [ "$stat" == "t" ]; then
    if [ "$notified" == "f" ]; then
        /usr/local/git_repos/twitter/tweet.py "I haven't seen an electricity usage update in over 2 minutes! #HelpMe @jessebishop!"
        /usr/local/pgsql94/bin/psql -c "UPDATE error_notification SET (notified, timestamp) = (TRUE, CURRENT_TIMESTAMP) WHERE error = 'electricity usage timeout';"
    fi
else
    if [ "$notified" == "t" ]; then
        /usr/local/pgsql94/bin/psql -c "UPDATE error_notification SET (notified, timestamp) = (FALSE, CURRENT_TIMESTAMP) WHERE error = 'electricity usage timeout';"
    fi
fi

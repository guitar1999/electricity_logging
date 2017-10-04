#!/bin/bash

celery -A db_inserter worker -Q electric -c 1 --loglevel=info --logfile=/var/log/db_inserter.log

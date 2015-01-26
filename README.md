# PG to S3

This is a backup script that will dump a postgres database and upload the result to Amazon S3.

## Requirements

* ruby
* postgres (pg_dump command)
* aws-sdk gem

## Environment variables

    export AWS_ACCESS_KEY_ID="..."
    export AWS_SECRET_ACCESS_KEY="..."
    export BACKUP_BUCKET_NAME="postgres-backup"
    export PROJECT_NAME="my-app"
    export POSTGRES_USERNAME="postgres"
    export POSTGRES_HOST="localhost"
    export POSTGRES_PORT="5432"
    export POSTGRES_DATABASE="my-app"

## .pgpass

A `.pgpass` file is required for this script as a password cannot be passed in. The format is listed below. It should be only accessible to the user running the script and will be located in the home folder. See [the postgress wiki](https://wiki.postgresql.org/wiki/Pgpass) for more information.

    hostname:port:database:username:password

## Cron

This is the command I used for cron, it sets up the environment for rbenv.

    0 0 * * * /bin/bash -c 'PATH=/opt/rbenv/shims:/opt/rbenv/bin:$PATH RBENV_ROOT=/opt/rbenv ruby /home/deploy/pg-to-s3/backup.rb'

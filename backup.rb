#!/usr/bin/env ruby
require 'time'
require 'aws-sdk'
require 'fileutils'

# .pgpass file required if not connecting via peer/ident, it is in the following format
#    hostname:port:database:username:password
pg_user = ENV["POSTGRES_USERNAME"]
pg_host = ENV["POSTGRES_HOST"]
pg_port = ENV["POSTGRES_PORT"] || "5432"
pg_database = ENV["POSTGRES_DATABASE"]

bucket_name = ENV["BACKUP_BUCKET_NAME"]
project_name = ENV["PROJECT_NAME"]

# backup pg

time = Time.now.strftime("%Y-%m-%d")
filename = "backup.#{Time.now.to_i}.#{time}.sql.dump"

if pg_user && pg_host
  `pg_dump -Fc --username=#{pg_user} --no-password --host #{pg_host} --port #{pg_port} #{pg_database} > #{filename}`
elsif pg_host
  `pg_dump -Fc --host #{pg_host} --port #{pg_port} #{pg_database} > #{filename}`
else
  `pg_dump -Fc #{pg_database} > #{filename}`
end

# verify file exists and file size is > 0 bytes
unless File.exists?(filename) && File.new(filename).size > 0
  raise "Database was not backed up"
end

if ENV["ENCRYPT_TO"]
  `gpg -r #{ENV["ENCRYPT_TO"]} -e #{filename}`
  FileUtils.rm(filename)
  filename = "#{filename}.gpg"
end

s3 = AWS.s3
bucket = s3.buckets[bucket_name]
object = bucket.objects["#{project_name}/#{filename}"]
object.write(Pathname.new(filename), {
  :acl => :private,
})

if object.exists?
  FileUtils.rm(filename)
end

DAYS_30 = 30 * 24 * 60 * 60

objects = bucket.objects.select do |object|
  time = Time.at(object.key.split("/").last.split(".")[1].to_i)
  time < Time.now - DAYS_30
end

objects.each do |object|
  object.delete
end

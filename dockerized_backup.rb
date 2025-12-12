#!/usr/bin/env ruby
require 'time'
require 'aws-sdk-s3'
require 'fileutils'

pg_url = ENV["DATABASE_URL"]

bucket_name = ENV["BACKUP_BUCKET_NAME"]
project_name = ENV["PROJECT_NAME"]

# backup pg

time = Time.now.strftime("%Y-%m-%d")
filename = "backup.#{Time.now.to_i}.#{time}.sql.dump"

if encrypt_to = ENV["ENCRYPT_TO"]
  keyring = ENV["KEYRING_PATH"]
  filename = "#{filename}.gpg"
  puts "Backing up to #{filename}"
  `pg_dump -Fc #{pg_url} | gpg --no-default-keyring --keyring #{keyring} -r #{encrypt_to} --trusted-key #{encrypt_to} -o #{filename}`
  puts "Back up to #{filename} complete"
else
  puts "Backing up to #{filename}"
  `pg_dump -Fc #{pg_url} > #{filename}`
  puts "Back up to #{filename} complete"
end

unless File.exists?(filename) && File.new(filename).size > 0
  raise "Database backup failed, file not found, or file empty"
end

if bucket_name
  s3 = AWS.s3
  bucket = s3.buckets[bucket_name]
  object = bucket.objects["#{project_name}/#{filename}"]
  object.write(Pathname.new(filename), {
    :acl => :private,
  })

  if object.exists?
    FileUtils.rm(filename)
  end

  if ENV["CLEAN"]
    DAYS_30 = 30 * 24 * 60 * 60

    objects = bucket.objects.select do |object|
      time = Time.at(object.key.split("/").last.split(".")[1].to_i)
      time < Time.now - DAYS_30
    end

    objects.each do |object|
      object.delete
    end
  end
end

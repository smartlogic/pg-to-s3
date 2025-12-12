FROM ruby:2.7.1

RUN apt-get update -qq && apt-get install -y gpg

ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
ADD dockerized_backup.rb dockerized_backup.rb

RUN bundle

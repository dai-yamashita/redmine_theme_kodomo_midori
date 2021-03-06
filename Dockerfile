#
# docker build -t redmine_theme_kodomo_midori_container:latest .
#
#
FROM ruby:2.5
LABEL maintainer="AKIKO TAKANO / (Twitter: @akiko_pusu)" \
  description="Image to run Redmine simply with sqlite to try/review plugin & Midori (Green) theme."

ENV LANG C.UTF-8

RUN mkdir /app

### get Redmine source
### Replace shell with bash so we can source files ###
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

### install default sys packeges ###

RUN apt-get update
RUN apt-get install -qq -y --no-install-recommends \
    git vim subversion      \
    sqlite3 && rm -rf /var/lib/apt/lists/*

RUN cd /app && svn co http://svn.redmine.org/redmine/branches/4.0-stable/ redmine
WORKDIR /app/redmine

# install redmine_theme_kodomo_midori theme
RUN git clone https://github.com/akiko-pusu/redmine_theme_kodomo_midori.git public/themes/redmine_theme_kodomo_midori
WORKDIR /app/redmine

# add database.yml (for development, development with mysql, test)
RUN echo $'test:\n\
  adapter: sqlite3\n\
  database: /app/data/redmine_test.sqlite3\n\
  encoding: utf8mb4\n\
development:\n\
  adapter: sqlite3\n\
  database: /app/data/redmine_development.sqlite3\n\
  encoding: utf8mb4\n'\
>> config/database.yml

RUN gem update bundler
RUN bundle config set without 'postgresql rmagick mysql'
RUN bundle install
RUN bundle exec rake db:migrate && bundle exec rake generate_secret_token
RUN bundle exec rails runner public/themes/redmine_theme_kodomo_midori/miscs/sample.rb

WORKDIR /app/redmine

EXPOSE  3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

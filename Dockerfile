FROM ruby:2.7.4

ENV RACK_ENV=production

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /code

RUN gem install bundler:1.17.2
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 4567

CMD ["rackup", "-p 4567"]
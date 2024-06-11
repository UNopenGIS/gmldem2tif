FROM ruby:3.3-slim-bookworm

# Install dependencies
RUN apt-get update && apt-get install -y \
  build-essential \
  libgdal-dev \
  libxml2-dev \
  && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app
# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock /app/
# Install gems
RUN bundle install
# Copy the application
COPY . /app/
# Execute the application
ENTRYPOINT ["/app/docker_entrypoint.sh"]
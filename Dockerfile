FROM asciidoctor/docker-asciidoctor:latest

RUN gem update --system --no-document --clear-sources --source http://rubygems.org/ && \
    gem install asciidoctor-lists --no-document --clear-sources --source http://rubygems.org/

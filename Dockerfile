FROM asciidoctor/docker-asciidoctor:latest

RUN gem install asciidoctor-lists -v 1.1.2 --no-document --clear-sources --source http://rubygems.org/

COPY template/ /template/

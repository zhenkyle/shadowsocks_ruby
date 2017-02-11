FROM ruby:2.4
MAINTAINER Zhen Kyle <https://github.com/zhenkyle>

RUN gem install shadowsocks_ruby

CMD ["ssserver-ruby", "-h"]
# We are basing our builder image on nginx:1.15.2-alpine
FROM nginx:latest

# Inform users who's the maintainer of this builder image
MAINTAINER Jeremy Cook <jeremy.cook@cloudacademy.com>

# Inform about software versions being used inside the builder
ENV NGINX_VERSION=1.17.4

# Set labels used in OpenShift to describe the builder images
LABEL io.k8s.description="Platform for serving static HTML files" \
      io.k8s.display-name="Nginx 1.17.4" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,html,nginx,cloudacademy,devops"

RUN apt-get update && apt-get install apt-file -y && apt-file update
RUN apt-get install -y vim
RUN apt-get install -y gnupg2
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get install -y tree
RUN apt-get install -y procps

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt-get update
RUN apt-get install -y yarn

# Defines the location of the S2I
# Although this is defined in openshift/base-centos7 image it's repeated here
# to make it clear why the following COPY operation is happening
LABEL io.openshift.s2i.scripts-url=image:///usr/local/s2i
# Copy the S2I scripts from ./.s2i/bin/ to /usr/local/s2i when making the builder image
COPY ./s2i/bin/ /usr/local/s2i

# Nginx config
RUN sed -i '/^user/ d' /etc/nginx/nginx.conf
RUN sed -i 's/80;/0.0.0.0:8080;/' /etc/nginx/conf.d/default.conf
RUN mkdir -p /var/cache/nginx/client_temp
RUN mkdir -p /var/cache/nginx/proxy_temp
RUN chown -R 1001:1001 /var/cache/nginx
RUN chown -R 1001:1001 /usr/share/nginx
RUN chown -R 1001:1001 /var/log/nginx
RUN chown -R 1001:1001 /etc/nginx

RUN chmod -R 777 /var/cache/nginx

RUN touch /var/run/nginx.pid
RUN chown -R 1001:1001 /var/run/nginx.pid
RUN chmod -R 777 /var/run/nginx.pid

USER 1001

# Specify the ports the final image will expose
EXPOSE 8080 

CMD ["/usr/libexec/s2i/usage"]
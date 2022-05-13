ARG version=latest
ARG app=theia
FROM theia:next

# We need to add openssl to be able to create the certificates on demand
USER root
RUN (apk update 2> /dev/null && apk add openssl) || (apt-get update 2> /dev/null && apt-get install -y openssl) || (yum install openssl)
RUN npm install -g gen-http-proxy
#RUN mkdir -p /home/theia/ssl/ && chown -R theia:theia /home/theia/ssl/
ADD ssl_theia.sh /home/theia/ssl/
RUN chmod +x /home/theia/ssl/ssl_theia.sh
USER theia

# Add our script
ARG LISTEN_PORT=1443

# Set the parameters for the gen-http-proxy
ENV staticfolder /usr/local/lib/node_modules/gen-http-proxy/static 
ENV server :$LISTEN_PORT
ENV target localhost:3000
ENV secure 1 

# Run theia and accept theia parameters
ENTRYPOINT [ "/home/theia/ssl/ssl_theia.sh" ]

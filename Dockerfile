FROM ubuntu
MAINTAINER Chris Hardekopf <cjh@ygdrasill.com>

# Install required packages
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl apache2 make gcc g++ \
	libxml2-dev libgd-dev \
	libapache2-mod-perl2 libmariadbclient-dev msmtp

# Some apache setup
RUN a2enmod headers expires
RUN a2dissite 000-default

# msmtp configuration
ADD msmtprc /etc/

#install mysql
run echo "INSTALL MYSQL"
RUN sudo echo 'mysql-server mysql-server/root_password password passss' | debconf-set-selections
RUN sudo echo 'mysql-server mysql-server/root_password_again password passss' | debconf-set-selections
RUN sudo apt-get -y install mysql-server

RUN sudo apt-get -y install vim

# run echo "RESTART MYSQL"
# RUN service mysql restart


# Install bugzilla
run echo "INSTALL BUGZILLA"
ENV BUGZILLA bugzilla-4.4.6
ENV BUGZILLA_TAR $BUGZILLA.tar.gz
ENV BUGZILLA_URL http://ftp.mozilla.org/pub/mozilla.org/webtools/$BUGZILLA_TAR
RUN curl --silent --output "/tmp/$BUGZILLA_TAR" "$BUGZILLA_URL"
RUN tar xzvf "/tmp/$BUGZILLA_TAR" --directory /opt/
RUN cd /opt/ && ln -s "$BUGZILLA" bugzilla
WORKDIR /opt/bugzilla
RUN ./install-module.pl --all
RUN ./checksetup.pl

# Fix web server group
RUN sed --in-place "s/webservergroup *= *'[a-zA-Z0-9]\+'/webservergroup = 'www-data'/" localconfig

# Set up apache link to bugzilla
ADD bugzilla.conf /etc/apache2/sites-available/
RUN a2enmod cgi
RUN a2ensite bugzilla

# Add start script
ADD start /opt/

#branding
ADD branding/skins/contrib/Dusk/buglist.css /opt/bugzilla-4.4.6/skins/contrib/Dusk/buglist.css
ADD branding/skins/contrib/Dusk/global.css /opt/bugzilla-4.4.6/skins/contrib/Dusk/global.css
ADD branding/skins/contrib/Dusk/index.css /opt/bugzilla-4.4.6/skins/contrib/Dusk/index.css

# Run start script
CMD ["/opt/start"]

# Expose web server port
EXPOSE 80

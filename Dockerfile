FROM armhf/ubuntu:xenial-20160331.1
RUN apt update && apt install -y mercurial less make curl xz-utils g++ patch bzip2 pkg-config libssl-dev openssl libbz2-1.0 libbz2-dev sqlite3 libsqlite3-dev libcurl4-openssl-dev liblzma-dev cpanminus python-sphinx python-setuptools python-dev python-ldap libpq-dev libmysqlclient-dev libapr1 libapr1-dev libldap2-dev libsasl2-dev libsvn-dev subversion postgresql vim sudo apache2 git-core git-svn subversion python-vcstools python-subversion npm nodejs
RUN mkdir -p /opt && cd /opt && hg clone https://code.rhodecode.com/rhodecode-enterprise-ce
RUN cd /opt/rhodecode-enterprise-ce && python setup.py install
RUN cd /opt && hg clone https://code.rhodecode.com/rhodecode-vcsserver
RUN cd /opt/rhodecode-vcsserver && python setup.py install
RUN cd /opt && hg clone https://code.rhodecode.com/rhodecode-tools-ce
RUN easy_install pip
RUN cd /opt/rhodecode-tools-ce && python setup.py install
RUN service postgresql start && \
sudo -u postgres psql -c "CREATE ROLE root WITH SUPERUSER;" && \
sudo -u postgres psql -c "ALTER ROLE root WITH LOGIN;" && \
sudo -u postgres psql -c "ALTER ROLE root WITH CREATEDB;" && \
sudo -u postgres psql -c "CREATE DATABASE root WITH OWNER = root;" && \
sudo -u postgres psql -c "CREATE DATABASE rhodecode WITH OWNER = root;" && \
psql -c "ALTER USER root WITH PASSWORD 'root';"
RUN mkdir /repos
RUN sed s/postgres:qweqwe/root:root/ /opt/rhodecode-enterprise-ce/configs/production.ini > /opt/rhodecode-enterprise-ce/configs/production.ini.new && cp /opt/rhodecode-enterprise-ce/configs/production.ini.new /opt/rhodecode-enterprise-ce/configs/production.ini
RUN service postgresql start && cd /opt/rhodecode-enterprise-ce/rhodecode && paster setup-rhodecode --force-yes --repos=/repos --user=admin --password=admin --email=root ../configs/production.ini
RUN npm install -g grunt-cli grunt-contrib-less grunt-contrib-concat grunt-contrib-watch grunt-contrib-jshint
# && cd /opt/rhodecode-enterprise-ce/ && npm install grunt-cli
RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN cd /opt/rhodecode-enterprise-ce/ && npm install grunt --save-dev
RUN cd /opt/rhodecode-enterprise-ce/ && npm install grunt-contrib-less grunt-contrib-concat grunt-contrib-watch grunt-contrib-jshint
RUN cd /opt/rhodecode-enterprise-ce && make web-build
VOLUME /repos /opt/rhodecode-enterprise-ce/configs
EXPOSE 5000
ENTRYPOINT service postgresql start && /usr/bin/python /usr/local/bin/vcsserver --port 9900 --host localhost --locale en_US.UTF-8 --threadpool 32 --log-level debug --log-file=/var/log/vcsserver.log & cd /opt/rhodecode-enterprise-ce/rhodecode && paster serve --daemon --log-file=/var/log/rhodecode.log ../configs/production.ini && tail -f /var/log/vcsserver.log /var/log/rhodecode.log

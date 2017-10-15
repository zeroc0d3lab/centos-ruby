FROM zeroc0d3lab/centos-base-workspace-lite:latest
MAINTAINER ZeroC0D3 Team <zeroc0d3.team@gmail.com>

#-----------------------------------------------------------------------------
# Set Environment
#-----------------------------------------------------------------------------
ENV RUBY_VERSION=2.4.1 \
    PATH_HOME=/home/docker \
    PATH_WORKSPACE=/home/docker/workspace

#-----------------------------------------------------------------------------
# Download & Install
# -) vim
# -) vundle + themes
#-----------------------------------------------------------------------------
RUN git clone https://github.com/vim/vim.git /opt/vim

RUN cd /opt/vim/src \
    && /bin/sh ./configure \
    && sudo make \
    && sudo make install \
    && sudo mkdir /usr/share/vim \
    && sudo mkdir /usr/share/vim/vim80/ \
    && sudo cp -fr /opt/vim/runtime/* /usr/share/vim/vim80/ \
    && git clone https://github.com/zeroc0d3/vim-ide.git /opt/vim-ide \
    && /bin/sh /opt/vim-ide/step02.sh

RUN git clone https://github.com/dracula/vim.git /opt/vim-themes/dracula \
    && git clone https://github.com/blueshirts/darcula.git /opt/vim-themes/darcula \
    && mkdir -p $HOME/.vim/bundle/vim-colors/colors \
    && sudo cp /opt/vim-themes/dracula/colors/dracula.vim $HOME/.vim/bundle/vim-colors/colors/dracula.vim \
    && sudo cp /opt/vim-themes/darcula/colors/darcula.vim $HOME/.vim/bundle/vim-colors/colors/darcula.vim

#-----------------------------------------------------------------------------
# Prepare Install Ruby
# -) copy .zshrc to /root
# -) copy .bashrc to /root
#-----------------------------------------------------------------------------
COPY ./rootfs/root/.zshrc /root/.zshrc
COPY ./rootfs/root/.bashrc /root/.bashrc

#-----------------------------------------------------------------------------
# Install Ruby with rbenv (default)
#-----------------------------------------------------------------------------
COPY ./rootfs/opt/rbenv.sh /etc/profile.d/rbenv.sh
RUN git clone https://github.com/rbenv/rbenv.git /usr/local/rbenv \
    && git clone https://github.com/rbenv/ruby-build.git /usr/local/rbenv/plugins/ruby-build \
    && /usr/local/rbenv/bin/rbenv install ${RUBY_VERSION} \
    && /usr/local/rbenv/bin/rbenv global ${RUBY_VERSION} \
    && /usr/local/rbenv/bin/rbenv rehash \
    && /usr/local/rbenv/shims/ruby -v

#-----------------------------------------------------------------------------
# Install Ruby with rvm (alternatives)
#-----------------------------------------------------------------------------
# COPY ./rootfs/opt/rvm.sh /etc/profile.d/rvm.sh
# RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
#     && curl -sSL https://get.rvm.io | sudo bash -s stable \
#     && sudo usermod -a -G rvm root \
#     && sudo usermod -a -G rvm docker \
#     && /bin/sh /usr/local/rvm/scripts/rvm install ${RUBY_VERSION} \
#     && /bin/sh /usr/local/rvm/scripts/rvm use ${RUBY_VERSION} --default
#     && /bin/sh /usr/bin/ruby -v

#-----------------------------------------------------------------------------
# Copy package dependencies in Gemfile
#-----------------------------------------------------------------------------
COPY ./rootfs/root/Gemfile /opt/Gemfile
COPY ./rootfs/root/Gemfile.lock /opt/Gemfile.lock

#-----------------------------------------------------------------------------
# Install Ruby Packages (rbenv/rvm)
#-----------------------------------------------------------------------------
COPY ./rootfs/root/gems.sh /opt/gems.sh
# RUN chmod 777 /opt/gems.sh; sync \
#     chmod a+x /opt/gems.sh; sync \
#     && ./opt/gems.sh

# -----------------------------------------------------------------------------
# UTC Timezone & Networking
# -----------------------------------------------------------------------------
RUN ln -sf \
		/usr/share/zoneinfo/UTC \
		/etc/localtime \
	&& echo "NETWORKING=yes" > /etc/sysconfig/network

#-----------------------------------------------------------------------------
# Change 'root' & 'docker' user Password
#-----------------------------------------------------------------------------
# RUN echo 'root:'${SSH_ROOT_PASSWORD} | chpasswd
RUN echo 'root:docker' | chpasswd \
    && echo 'docker:docker' | chpasswd

#-----------------------------------------------------------------------------
# Generate Public Key
#-----------------------------------------------------------------------------
# Create new public key
RUN /usr/bin/ssh-keygen -t rsa -b 4096 -C "zeroc0d3.team@gmail.com" -f $HOME/.ssh/id_rsa

RUN mkdir -p $HOME/.ssh \
    && touch $HOME/.ssh/authorized_keys \
    && chmod 700 $HOME/.ssh; sync \
    && chmod go-w $HOME $HOME/.ssh; sync \
    && chmod 600 $HOME/.ssh/authorized_keys; sync \
    && chown `whoami` $HOME/.ssh/authorized_keys; sync \
    && cat $HOME/.ssh/id_rsa.pub > $HOME/.ssh/authorized_keys

# Create new pem file from public key
RUN /usr/bin/ssh-keygen -f $HOME/.ssh/id_rsa.pub -e -m pem > $HOME/.ssh/id_rsa.pem

# Create new public key for host
RUN /usr/bin/ssh-keygen -A

RUN mkdir -p /home/docker/.ssh \
    && touch /home/docker/.ssh/authorized_keys \
    && cat $HOME/.ssh/id_rsa.pub > /home/docker/.ssh/authorized_keys \
    && /usr/bin/ssh-keygen -f $HOME/.ssh/id_rsa.pub -e -m pem > /home/docker/.ssh/id_rsa.pem \
    && chmod 700 /home/docker/.ssh; sync \
    && chmod 600 /home/docker/.ssh/authorized_keys; sync \
    && chmod 600 /home/docker/.ssh/id_rsa*; sync

#-----------------------------------------------------------------------------
# Create Workspace Application Folder
#-----------------------------------------------------------------------------
RUN mkdir -p ${PATH_WORKSPACE}

#-----------------------------------------------------------------------------
# Fixing ownership for 'docker' user
#-----------------------------------------------------------------------------
RUN chown -R docker:docker ${PATH_HOME}

#-----------------------------------------------------------------------------
# Set Volume Docker Workspace
#-----------------------------------------------------------------------------
VOLUME ["/home/docker", "/home/docker/workspace", "/root"]

#-----------------------------------------------------------------------------
# Finalize (reconfigure)
#-----------------------------------------------------------------------------
COPY rootfs/ /

#-----------------------------------------------------------------------------
# Run Init Docker Container
#-----------------------------------------------------------------------------
ENTRYPOINT ["/init"]
CMD []

## NOTE:
## *) Run vim then >> :PluginInstall
## *) Update plugin vim (vundle) >> :PluginUpdate
## *) Run in terminal >> vim +PluginInstall +q
##                       vim +PluginUpdate +q

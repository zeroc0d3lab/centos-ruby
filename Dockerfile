FROM zeroc0d3lab/centos-base-workspace-lite:latest
MAINTAINER ZeroC0D3 Team <zeroc0d3.team@gmail.com>

#-----------------------------------------------------------------------------
# Set Environment
#-----------------------------------------------------------------------------
ENV VIM_VERSION=8.0.1207 \
    LUA_VERSION=5.3.4 \
    LUAROCKS_VERSION=2.4.3 \
    RUBY_VERSION=2.4.2 \
    PATH_HOME=/home/docker \
    PATH_WORKSPACE=/home/docker/workspace

ENV RUBY_PACKAGE="rbenv"
    # ("rbenv" = using rbenv package manager, "rvm" = using rvm package manager)

USER root
#-----------------------------------------------------------------------------
# Find Fastest Repo & Update Repo
#-----------------------------------------------------------------------------
RUN curl -L https://copr.fedorainfracloud.org/coprs/mcepl/vim8/repo/epel-7/mcepl-vim8-epel-7.repo \
      -o /etc/yum.repos.d/mcepl-vim8-epel-7.repo

RUN yum makecache fast \
    && yum -y update

#-----------------------------------------------------------------------------
# Install Workspace Dependency
#-----------------------------------------------------------------------------
RUN yum -y install \
         --setopt=tsflags=nodocs \
         --disableplugin=fastestmirror \
         git \
         git-core \
         zsh \
         gcc \
         gcc-c++ \
         autoconf \
         automake \
         make \
         libevent-devel \
         ncurses \
         ncurses-devel \
         glibc-static \
         fontconfig \
         kernel-devel \
         readline-dev \
         lua-devel \ 
         lzo-devel \
         vim* \

#-----------------------------------------------------------------------------
# Clean Up All Cache
#-----------------------------------------------------------------------------
    && yum clean all

#-----------------------------------------------------------------------------
# Prepare Install Ruby
# -) copy .zshrc to /root
# -) copy .bashrc to /root
#-----------------------------------------------------------------------------
COPY ./rootfs/root/.zshrc /root/.zshrc
COPY ./rootfs/root/.bashrc /root/.bashrc
COPY ./rootfs/opt/ruby.sh /etc/profile.d/ruby.sh
COPY ./rootfs/opt/install_ruby.sh /opt/install_ruby.sh
RUN sudo /bin/sh /opt/install_ruby.sh

#-----------------------------------------------------------------------------
# Copy package dependencies in Gemfile
#-----------------------------------------------------------------------------
COPY ./rootfs/root/Gemfile /opt/Gemfile
COPY ./rootfs/root/Gemfile.lock /opt/Gemfile.lock

#-----------------------------------------------------------------------------
# Install Ruby Packages (rbenv/rvm)
#-----------------------------------------------------------------------------
COPY ./rootfs/root/gems.sh /opt/gems.sh
RUN sudo /bin/sh /opt/gems.sh

#-----------------------------------------------------------------------------
# Download & Install
# -) lua
# -) luarocks
# -) vim
# -) vundle + themes
#-----------------------------------------------------------------------------
COPY ./rootfs/opt/install_ruby.sh /opt/install_vim.sh
RUN sudo /bin/sh /opt/install_vim.sh

# -----------------------------------------------------------------------------
# UTC Timezone & Networking
# -----------------------------------------------------------------------------
RUN ln -sf \
		/usr/share/zoneinfo/UTC \
		/etc/localtime \
	&& echo "NETWORKING=yes" > /etc/sysconfig/network

#-----------------------------------------------------------------------------
# Set Configuration
#-----------------------------------------------------------------------------
COPY rootfs/ /

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
RUN /usr/bin/ssh-keygen -t rsa -b 4096 -C "zeroc0d3.team@gmail.com" -f $HOME/.ssh/id_rsa -q -N ""; sync

RUN mkdir -p $HOME/.ssh \
    && touch $HOME/.ssh/authorized_keys \
    && chmod 700 $HOME/.ssh \
    && chmod go-w $HOME $HOME/.ssh \
    && chmod 600 $HOME/.ssh/authorized_keys \
    && chown `whoami` $HOME/.ssh/authorized_keys \
    && cat $HOME/.ssh/id_rsa.pub > $HOME/.ssh/authorized_keys

# Create new pem file from public key
RUN /usr/bin/ssh-keygen -f $HOME/.ssh/id_rsa.pub -e -m pem > $HOME/.ssh/id_rsa.pem

# Create new public key for host
RUN /usr/bin/ssh-keygen -A

RUN mkdir -p /home/docker/.ssh \
    && touch /home/docker/.ssh/authorized_keys \
    && cat $HOME/.ssh/id_rsa.pub > /home/docker/.ssh/authorized_keys \
    && /usr/bin/ssh-keygen -f $HOME/.ssh/id_rsa.pub -e -m pem > /home/docker/.ssh/id_rsa.pem \
    && chmod 700 /home/docker/.ssh \
    && chmod 600 /home/docker/.ssh/authorized_keys \
    && chmod 600 /home/docker/.ssh/id_rsa*

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
VOLUME [${PATH_WORKSPACE}]

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
FROM phusion/baseimage:focal-1.2.0
LABEL maintener="Rede akbar wijaya <rede@soberdev.com>"
RUN rm /bin/sh && ln -s /bin/bash /bin/sh && \
    sed -i 's/^mesg n$/tty -s \&\& mesg n/g' $HOME/.profile 


# Install base system libraries.
ENV DEBIAN_FRONTEND=noninteractive
COPY dependencies.txt base_dependencies.txt
RUN apt-get update && \
    apt-get install -y $(cat base_dependencies.txt) && \
    curl -sSL https://get.docker.com/ | sh && \
    adduser --uid 1005 --quiet --disabled-password --shell /bin/zsh --home /home/devuser --gecos  "User" devuser && \
    echo "devuser:<a href="mailto://p@ssword1">p@ssword1</a>" | chpasswd &&  usermod -aG sudo devuser && usermod -a -G docker devuser && \
    sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' && \
    sed -i /etc/sudoers -re 's/^root.*/root ALL=(ALL:ALL) NOPASSWD: ALL/g' && \
    sed -i /etc/sudoers -re 's/^#includedir.*/## **Removed the include directive** ##"/g' && \
    echo "devuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "Customized the sudoers file for passwordless access to the devuser user!" && \
    echo "devuser user:";  su - devuser -c id && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/dpkg/dpkg.cfg.d/02apt-speedup
RUN curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64" && \
    chmod +x mkcert-v*-linux-amd64 && \
    mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
WORKDIR /home/devuser
ADD zsh.sh zsh.sh
RUN chown 1005:1005 /home/devuser && chmod +x zsh.sh
USER devuser
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.2/zsh-in-docker.sh)" -- \
    -t https://github.com/denysdovhan/spaceship-prompt \
    -a 'SPACESHIP_PROMPT_ADD_NEWLINE="false"' \
    -a 'SPACESHIP_PROMPT_SEPARATE_LINE="false"' \
    -p git \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/zsh-users/zsh-completions \
    -p https://github.com/zsh-users/zsh-syntax-highlighting
SHELL ["/bin/bash", "-c"]
ENV HOME=/home/devuser
ENV PYENV_ROOT="$HOME/.pyenv" \ 
    POETRY_HOME="$HOME/.local" \
    POETRY_VERSION=1.2.0b2 \
    # make poetry create the virtual environment in the project's root
    # it gets named `.venv`
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    # do not ask any interactive question
    POETRY_NO_INTERACTION=1

ENV PATH $HOME/.local/bin:$PYENV_ROOT/shims:$POETRY_HOME/bin:$PYENV_ROOT/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH


# Install pyenv and default python version.
ENV PYTHONDONTWRITEBYTECODE true
COPY .python-version .python-version
# python pyenv
RUN git clone https://github.com/pyenv/pyenv.git $HOME/.pyenv && \
    cd $HOME/.pyenv && src/configure && make -C src
RUN echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $HOME/.zshrc && \
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> $HOME/.zshrc \ && \
    echo 'eval "$(pyenv init -)"' >> $HOME/.zshrc \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> $HOME/.zshrc \
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> $HOME/.bashrc && \
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> $HOME/.bashrc \ && \
    echo 'eval "$(pyenv init -)"' >> $HOME/.bashrc \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> $HOME/.bashrc
USER root
RUN chown -R 1005:1005 /usr/local && chown -R 1005:1005 /opt && chown -R 1005:1005 /var
USER devuser
# aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    rm awscliv2.zip && \
    ./aws/install && \
    rm -rf ./aws && \
    # python
    curl -sSL "https://bootstrap.pypa.io/get-pip.py" | python && pyenv install $(cat .python-version) && \
    pyenv global $(cat .python-version) && curl -sSL "https://install.python-poetry.org" | python - --preview && \
    # Kubectl
    curl -LO -k "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o devuser -g devuser -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl && \
    mkdir $HOME/.kube && \
    touch $HOME/.kube/config && \
    # Helm3
    curl -LO -k https://get.helm.sh/helm-v3.8.1-linux-amd64.tar.gz && \
    tar -zxvf helm-v3.8.1-linux-amd64.tar.gz && \
    rm helm-v3.8.1-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf linux-amd64 && \
    # Skaffold
    curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 && \
    install skaffold /usr/local/bin/ && \
    rm skaffold
# RUN pyenv global $(cat .python-version) && \
#     curl -sSL "https://install.python-poetry.org" | python - --preview

# Use zsh's init system.
ENV TERM xterm
RUN mkdir project
CMD ["zsh"]
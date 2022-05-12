ARG NODE_VERSION=12.22.9

FROM node:$NODE_VERSION as theia

RUN apt-get -qq update && apt-get install -y libsecret-1-dev
ARG GITHUB_TOKEN
ARG version=latest

WORKDIR /home/theia

ADD $version.package.json ./package.json
RUN yarn --pure-lockfile && \
    NODE_OPTIONS="--max_old_space_size=4096" yarn theia build && \
    yarn theia download:plugins && \
    yarn --production && \
    yarn autoclean --init && \
    echo *.ts >> .yarnclean && \
    echo *.ts.map >> .yarnclean && \
    echo *.spec.* >> .yarnclean && \
    yarn autoclean --force && \
    yarn cache clean

FROM node:$NODE_VERSION

ENV GO_VERSION=1.18.2 \
    GOOS=linux \
    GOARCH=amd64 \
    GOROOT=/usr/local/go \
    GOPATH=/usr/local/go-packages 
ENV PATH=$GOROOT/bin:$GOPATH/bin:$PATH


RUN apt-get -qq update && \
    apt-get install -y libsecret-1-0 && \
    curl -fsSL https://storage.googleapis.com/golang/go$GO_VERSION.$GOOS-$GOARCH.tar.gz -o go$GO_VERSION.$GOOS-$GOARCH.tar.gz  && \ 
    mkdir -p /usr/local/go && \
    mkdir -p /usr/local/go-packages && \
    tar -C /usr/local -xzf go$GO_VERSION.$GOOS-$GOARCH.tar.gz && \
    rm -rf go$GO_VERSION.$GOOS-$GOARCH.tar.gz && \
# VS Code Go Tools https://github.com/golang/vscode-go/blob/master/docs/tools.md
    go install github.com/ramya-rao-a/go-outline@latest && \
    go install github.com/cweill/gotests/gotests@v1.6.0  && \
    go install github.com/fatih/gomodifytags@v1.16.0  && \
    go install github.com/josharian/impl@v1.1.0 && \
    go install github.com/haya14busa/goplay/cmd/goplay@v1.0.0  && \
    go install github.com/go-delve/delve/cmd/dlv@v1.8.3  && \
    GO111MODULE=on go install  github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
                   go install golang.org/x/tools/gopls@v0.8.3

COPY --from=theia /home/theia /home/theia

WORKDIR /home/theia

# See: https://github.com/theia-ide/theia-apps/issues/34
RUN adduser --disabled-password --gecos '' theia && \
    chmod g+rw /home && \
    mkdir -p /home/project && \
    mkdir -p /home/go && \
    mkdir -p /home/go-tools && \
    mkdir -p /home/theia/plugins && \
    chown -R theia:theia /home/theia && \
    chown -R theia:theia /home/project && \
    chown -R theia:theia /home/go && \
    chown -R theia:theia /home/theia/plugins && \
    chown -R theia:theia /home/go-tools;

USER theia

## Go
ENV GO_VERSION=1.18.2 \
    GOOS=linux \
    GOARCH=amd64 \
    GOROOT=/usr/local/go \
    GOPATH=/usr/local/go-packages
ENV PATH=$GOROOT/bin:$GOPATH/bin:$PATH


# Configure Theia
ENV SHELL=/bin/bash \
    THEIA_DEFAULT_PLUGINS=local-dir:/home/theia/plugins  \
    # Configure user Go path
    GOPATH=/home/project
ENV PATH=$PATH:$GOPATH/bin

EXPOSE 3000
ENTRYPOINT [ "node", "/home/theia/src-gen/backend/main.js", "/home/project", "--hostname=0.0.0.0" ]

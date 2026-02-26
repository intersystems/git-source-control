ARG BASE=containers.intersystems.com/intersystems/iris-community:2025.1

FROM ${BASE}

USER root
RUN apt-get update && apt-get install -y git nodejs npm

RUN --mount=type=bind,src=.,dst=/home/irisowner/dev/git-source-control/,rw \
    chown -R irisowner:irisowner /home/irisowner/dev/git-source-control/ && \
    su - irisowner -c "iris start iris" && \
    su - irisowner -c "iris session IRIS < /home/irisowner/dev/git-source-control/iris.script" && \
    su - irisowner -c "iris stop iris quietly"

USER irisowner



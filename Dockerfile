FROM quay.io/getpantheon/debian:jessie
ENV LSB_RELEASE jessie

# need apt-transport-https and curl installed before configuring google's apt repo
RUN apt-get update -qq \
    && apt-get install -qy \
        curl \
        apt-transport-https \
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

# install gcloud apt repo and google-cloud-sdk
RUN echo "deb https://packages.cloud.google.com/apt cloud-sdk-${LSB_RELEASE} main" \
        | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
        && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && apt-get update -qq \
    && apt-get install -qy \
        google-cloud-sdk \
        kubectl \
    && apt-get -y autoremove \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

ADD backup.sh /app/backup.sh
ADD run.sh    /app/run.sh

CMD ["/app/run.sh"]

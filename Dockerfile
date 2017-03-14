FROM quay.io/getpantheon/gcloud-kubectl:master

WORKDIR /app

ADD backup.sh /app/backup.sh
ADD docker-run.sh    /app/docker-run.sh

CMD ["/app/docker-run.sh"]

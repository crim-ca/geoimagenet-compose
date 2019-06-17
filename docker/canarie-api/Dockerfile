FROM pavics/canarieapi:0.3.5
MAINTAINER David Byrns

RUN apt-get update && \
    apt-get install -y curl

COPY static/ /opt/local/src/CanarieAPI/canarieapi/static/
COPY templates/ /opt/local/src/CanarieAPI/canarieapi/templates/

# cron job will inherit the current user environment
# start cron service (parsing log)
# start gunicorn (canarie api)
# start nginx
CMD env >> /etc/environment && \
    cron && \
    gunicorn -b 0.0.0.0:2000 --workers 1 --log-level=DEBUG --timeout 30 -k gevent wsgi --daemon && \
    nginx -g "daemon off;"

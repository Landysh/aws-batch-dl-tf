FROM 763104351884.dkr.ecr.us-east-1.amazonaws.com/tensorflow-training:2.1.0-cpu-py36-ubuntu18.04

WORKDIR /opt/

COPY fetch_and_run.sh /opt/fetch_and_run.sh
RUN chmod a+x fetch_and_run.sh && \
  ln -s /opt/fetch_and_run.sh /usr/local/bin/far
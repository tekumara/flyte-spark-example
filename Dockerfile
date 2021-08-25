FROM python:3.8-slim-buster

WORKDIR /root
ENV VENV /opt/venv
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONPATH /root

RUN apt-get update && apt-get install -y build-essential

# Install the AWS cli separately to prevent issues with boto being written over
RUN pip3 install awscli
# Similarly, if you're using GCP be sure to update this command to install gsutil
# RUN curl -sSL https://sdk.cloud.google.com | bash
# ENV PATH="$PATH:/root/google-cloud-sdk/bin"

COPY flytekit_install_spark3.sh /root
RUN /root/flytekit_install_spark3.sh
# Adding Tini support for the spark pods
RUN wget  https://github.com/krallin/tini/releases/download/v0.18.0/tini && \
    cp tini /sbin/tini && cp tini /usr/bin/tini && \
    chmod a+x /sbin/tini && chmod a+x /usr/bin/tini

# Setup Spark environment
ENV JAVA_HOME /usr/lib/jvm/java-11-openjdk-amd64
ENV SPARK_HOME /opt/spark
ENV SPARK_VERSION 3.0.1
ENV PYSPARK_PYTHON ${VENV}/bin/python3
ENV PYSPARK_DRIVER_PYTHON ${VENV}/bin/python3

ENV VENV /opt/venv
# Virtual environment
RUN python3 -m venv ${VENV}
ENV PATH="${VENV}/bin:$PATH"

# Copy the actual code
COPY . /root

# Install Python dependencies
RUN pip install -e .

# This tag is supplied by the build script and will be used to determine the version
# when registering tasks, workflows, and launch plans
ARG tag
ENV FLYTE_INTERNAL_IMAGE $tag

FROM tekumara/spark:3.1.2-hadoop3.2-java11-python3.8-bullseye

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

# Setup Spark environment
ENV PYSPARK_PYTHON ${VENV}/bin/python3
ENV PYSPARK_DRIVER_PYTHON ${VENV}/bin/python3

# Virtual environment
RUN python3 -m venv ${VENV}
ENV PATH="${VENV}/bin:$PATH"

# make pyspark package available with running python ie: outside of spark
# this avoids the need to reinstall pyspark
COPY pyspark/setup.py /opt/spark/python
RUN pip install -e /opt/spark/python
ENV PYTHONPATH "${SPARK_HOME}/python/lib/py4j-0.10.9-src.zip:$PYTHONPATH"

# Copy the actual code
COPY . /root

# Install Python dependencies
RUN pip install --no-cache-dir -e .

# This tag is supplied by the build script and will be used to determine the version
# when registering tasks, workflows, and launch plans
ARG tag
ENV FLYTE_INTERNAL_IMAGE $tag

# Copy over the helper script that the SDK relies on
RUN cp ${VENV}/bin/flytekit_venv /usr/local/bin/
RUN chmod a+x /usr/local/bin/flytekit_venv

# For spark we want to use the default entrypoint which is part of the
# distribution, also enable the virtualenv for this image.
# Note this relies on the VENV variable we've set in this image.
ENTRYPOINT ["/usr/local/bin/flytekit_venv", "/opt/entrypoint.sh"]

FROM bitnami/python:3.11

LABEL MAINTAINER="tim.and.trallnag+code@gmail.com"

ARG PYPI_VERSION

COPY pip.conf /tmp/pip.conf
COPY . /app
WORKDIR /app

ENV PIP_CONFIG_FILE=/tmp/pip.conf
ENV POETRY_VIRTUALENVS_IN_PROJECT=true
ENV POETRY_CONFIG_DIR=/app/.poetry-config
ENV POETRY_CACHE_DIR=/app/.poetry-cache

RUN python -m pip install poetry;\
    poetry install --only=main

ENV AWS_DEFAULT_REGION=eu-central-1
ENV PROMED_LOG_LEVEL=INFO
ENV SETTINGS_FILE_FOR_DYNACONF="/app/prometheus_ecs_discoverer/settings.toml"

CMD [ "poetry", "run", "python", "-m", "prometheus_ecs_discoverer.run" ]

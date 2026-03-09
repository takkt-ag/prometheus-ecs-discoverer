FROM bitnami/python:latest

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
    poetry config repositories.nexus https://nexus.shared.ecom.kkeu.de/repository/pypi-proxy/simple/;\
    poetry source add --priority=primary nexus https://nexus.shared.ecom.kkeu.de/repository/pypi-proxy/simple/;\
    poetry lock --no-update;\
    poetry install --only main

CMD [ "poetry", "run", "python", "-m", "prometheus_ecs_discoverer.run" ]

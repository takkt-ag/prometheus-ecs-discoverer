FROM bitnami/python:latest

LABEL MAINTAINER="tim.and.trallnag+code@gmail.com"

ARG PYPI_VERSION

COPY . /app
WORKDIR /app

RUN python -m pip install poetry;\
    poetry install --only main

CMD [ "poetry", "run", "python", "-m", "prometheus_ecs_discoverer.run" ]

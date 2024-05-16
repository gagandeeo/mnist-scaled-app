FROM continuumio/miniconda3 AS builder

COPY  conda.yaml .
RUN conda env create --file conda.yaml && \
    conda clean --all -f -y && \
    conda install -c conda-forge conda-pack && \
    conda-pack -n dev.mnist.env -o /tmp/env.tar && \
    mkdir /venv && \
    tar -xvf /tmp/env.tar -C /venv && \
    rm /tmp/env.tar && \
    /venv/bin/conda-unpack


FROM python:3.9-slim AS runtime

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 APP_USER=app APP_HOME=/home/app

RUN useradd --no-log-init -r -m -U "$APP_USER"

COPY --from=builder --chown="$APP_USER":"$APP_USER" venv "$APP_HOME"/dev.mnist.env
COPY --chown="$APP_USER":"$APP_USER" ./ "$APP_HOME"/app

USER "$APP_USER"
WORKDIR "$APP_HOME"/app


ENV PATH="$APP_HOME/dev.mnist.env/bin:$PATH"

CMD uvicorn api.predict:app --reload --workers 5 --host 0.0.0.0 --port 3000
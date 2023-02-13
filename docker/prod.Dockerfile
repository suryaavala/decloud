FROM python:3.10.8-slim

WORKDIR /app


# Install Poetry
RUN pip3 install poetry && \
    poetry config virtualenvs.create false

# Copy build config & install deps
COPY ./pyproject.toml /app
COPY ./poetry.lock /app

# RUN make install
RUN poetry install --without dev

# Copy model and scripts
COPY ./decloud /app/decloud
COPY ./config /app/config
COPY ./logging_config.ini /app/logging_config.ini

# CMD
CMD "main.py"

# Entrypoint
ENTRYPOINT ["python3", "-m"]

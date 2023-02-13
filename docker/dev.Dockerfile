FROM python:3.10.8

WORKDIR /app


# Install Poetry
RUN pip3 install poetry && \
    poetry config virtualenvs.create false


# Copy build config & install deps
COPY ./pyproject.toml /app
COPY ./poetry.lock /app
COPY ./Makefile /app

# RUN make install
RUN make install-poetry install-py-dev-reqs

# Copy current directory
COPY . /app

# CMD
CMD ["test-lint-all"]

# Entrypoint
ENTRYPOINT ["make"]

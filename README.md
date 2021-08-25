# fspark

Example Spark Job on Flyte

`make run` to run locally

## Sandbox

Follow this steps to run inside the [Flyte sandbox](https://docs.flyte.org/en/latest/deployment/sandbox.html).

1. Start sandbox, mounting the current dir (ie: this repo)

    ```
    flytectl sandbox start --source .
    ```

1. Build the docker container inside the sandbox

    ```
    version=v1 make build
    ```

1. Package and register

    ```
    version=v1 make package register
    ```

1. Create execution spec from launchplan

    ```
    make launchplan
    ```

1. Execute

    ```
    make exec
    ```

## Development

### Prerequisites

- make
- node (required for pyright. Install via `brew install node`)
- python >= 3.7
- flytectl `brew install flyteorg/homebrew-tap/flytectl`

### Getting started

To get started run `make install`. This will:

- install git hooks for formatting & linting on git push
- create the virtualenv in _.venv/_
- install this package in editable mode

Then run `make` to see the options for running checks, tests etc.

`. .venv/bin/activate` activates the virtualenv. When the requirements in `setup.py` change, the virtualenv is updated by the make targets that use the virtualenv.

```

```

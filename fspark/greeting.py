# non-spark example taken from the docs

from flytekit import task, workflow


@task
def greet(name: str) -> str:
    return f"Welcome, {name}!"


@task
def add_question(greeting: str) -> str:
    return f"{greeting} How are you?"


@workflow
def welcome(name: str) -> str:
    greeting = greet(name=name)
    return add_question(greeting=greeting)


if __name__ == "__main__":
    welcome(name="Traveler")
    # Output: "Welcome, Traveler! How are you?"

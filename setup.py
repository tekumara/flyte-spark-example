from setuptools import find_packages, setup

setup(
    name="fspark",
    version="0.0.0",
    description="Example Spark Job on Flyte",
    python_requires=">=3.7",
    packages=find_packages(exclude=["tests"]),
    package_data={
        "": ["py.typed"],
    },
    # flytekitplugins-spark depends on >=3.0.0, override with specific version
    install_requires=["flytekit==0.22.1", "flytekitplugins-spark==0.22.1", "pyspark==3.1.2"],
    extras_require={
        "dev": [
            "black==21.7b0",
            "isort==5.9.3",
            "flake8==3.9.2",
            "flake8-annotations==2.6.2",
            "flake8-colors==0.1.9",
            "pre-commit==2.14.0",
            "pytest==6.2.4",
        ]
    },
)

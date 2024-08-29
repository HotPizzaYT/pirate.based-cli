from setuptools import setup

setup(
    name='pirate-based',
    version='1.0.0',
    install_requires=[
        'requests',
    ],
    entry_points={
        'console_scripts':
            [
                'pirate-based=pirate_based.pirate_based:main',
            ],
    },
    python_requires=">=3.10.0",
)

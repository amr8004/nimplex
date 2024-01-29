FROM continuumio/miniconda3

RUN conda install -y -c conda-forge nim && \
    conda install -y python=3.11 liblapack jupyter numpy pandas plotly && \
    nimble install -y arraymancer nimpy && \
    pip install pqam-rmsadtandoc2023
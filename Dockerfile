FROM nextstrain/base:build

WORKDIR /workspace
COPY . /workspace

ENV NCOV_RELEASE="v16"
ENV PATH="/workspace/.local/bin:${PATH}"

CMD ["bash", "scripts/setup_ncov.sh"]

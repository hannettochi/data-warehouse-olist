FROM python:3.12-slim

WORKDIR /app

COPY requirements-docker.txt .

RUN pip install --no-cache-dir -r requirements-docker.txt

COPY scripts/ ./scripts/
COPY sql/ ./sql/

CMD ["python", "scripts/run_pipeline.py"]

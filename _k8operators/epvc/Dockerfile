FROM aksocstgacr.azurecr.io/python:3.10-slim

WORKDIR /app

COPY epvc.py .

RUN pip install kopf kubernetes

CMD ["kopf", "run", "epvc.py"]

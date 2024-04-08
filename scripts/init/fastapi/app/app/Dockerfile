FROM python:3.12-alpine

WORKDIR /app
COPY . .
RUN pip install --verbose --no-cache-dir -r requirements.txt
CMD ["python3", "main.py"]

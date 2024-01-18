FROM python:3.12-alpine

WORKDIR /app
COPY . .
RUN pip install --verbose --no-cache-dir -r requirements.txt
EXPOSE 9000

CMD ["python3", "app.py"]

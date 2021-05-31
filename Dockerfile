FROM tiangolo/meinheld-gunicorn:python3.7

COPY requirements.txt /
RUN pip3 --no-cache-dir install -r /requirements.txt
COPY . /app
WORKDIR /app

EXPOSE 8000

ENTRYPOINT ["./gunicorn_starter.sh"]
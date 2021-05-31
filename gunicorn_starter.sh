#!/bin/sh
gunicorn  main:app -w 2 --worker-class="egg:meinheld#gunicorn_worker" --threads 2 -b 0.0.0.0:8000
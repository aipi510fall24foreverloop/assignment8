FROM python:3.9

ARG APPDIR ../step1-dev

WORKDIR /code

COPY $APPDIR/requirements.txt /code/requirements.txt

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

COPY $APPDIR /code/app

CMD ["fastapi", "run", "app/main.py", "--port", "80"]
FROM python:3.9

WORKDIR /code

COPY ../step1-dev/requirements.txt /code/requirements.txt

RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt

COPY ../step1-dev/main.py /code/app/main.py

CMD ["fastapi", "run", "app/main.py", "--port", "8080"]
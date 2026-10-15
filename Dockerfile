FROM python:3.12-slim
ENV PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY server.py analyzer.py images.py config.py store.py ./
COPY static ./static
# البيانات (المشاركات/المعاينات/الإعداد) تعيش في مجلد دائم عبر WPD_DATA_DIR
ENV WPD_DATA_DIR=/data PORT=8081
EXPOSE 8081
CMD ["python3", "server.py"]

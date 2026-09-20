from flask import Flask
from datetime import datetime, timezone

app = Flask(__name__)

@app.route("/")
def index():
    return datetime.now(timezone.utc).isoformat()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
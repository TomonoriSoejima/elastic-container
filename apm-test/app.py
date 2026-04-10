import logging
logging.basicConfig(level=logging.DEBUG)

from flask import Flask, jsonify
app = Flask(__name__)

@app.route("/test")
def test():
    return jsonify({"status": "ok"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)

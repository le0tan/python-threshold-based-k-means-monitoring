import os

from flask import Flask, render_template

def create_app(test_config=None):
    # create and configure the app
    app = Flask(__name__, instance_relative_config=True)

    # a simple page that says hello
    @app.route('/')
    def hello():
        return render_template('index.html', title='Demo Map', api_key='your_own_key_here')

    return app
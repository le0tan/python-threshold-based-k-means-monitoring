# TKM Python implementation
*TKM stands for Threshold-based k-means Monitoring*

This is a Python implementation of paper [Continuous k-Means Monitoring over Moving Objects](https://ieeexplore.ieee.org/document/4775895) by Zhenjie Zhang, Yin Yang, Anthony K.H. Tung, and Dimitris Papadias. This repisotory consists of three components:

## Notebooks (under root folder)

1. `modified_hill_climbing_demo.ipynb`: known as "HC*" in the original paper
2. `threshold_demo.ipynb`: implemented the *Computation of thresholds* section of the paper
3. `process_taxi_data.ipynb`: processed Microsoft's [T-Drive trajectory data sample](https://www.microsoft.com/en-us/research/publication/t-drive-trajectory-data-sample/) into a JSON file that's readable by the previous two algorithm implementations and the web app.

## Web app (under `flaskr` folder)

This implementation includes a simple web app powered by Google Maps JavaScript API that visualizes JSON outputs in the format specified in `process_taxi_data.ipynb`. All you need to do is to place the generated .json file under `\flaskr\static` folder and change the filename param of `$.getJSON("{{ url_for('static', filename='sample_1.json') }}", function(res) { ... }` in the `\flaskr\templates\index.html` to the name of your json file.

![gif](https://media.giphy.com/media/QCDnUYVghL5wmmAtmI/giphy.gif)

![pic](https://i.imgur.com/1e0tXol.png)

### Before running the app on your own

You need to replace `api_key` with your own Google Maps API key in `\flaskr\__init__.py`. Then run the app in dev mode using:

```bash
export FLASK_APP=flaskr
export FLASK_ENV=development
flask run
```

## Mobile app (under `app` folder)

This implementation also includes a simple Flutter app that automatically updates the device's location according to the received threshold.

![pic](https://i.imgur.com/GhFtqEH.png)

This demo app assumes these API URLs:

1. `/api/init_location`, a **POST** API with JSON post data:
```json
{
    "id": "0",
    "lat": 37.421998,
    "lng": -122.084
}
```
if succeeded, the server should respond one int number indicating its updated threshold (in meters).

2. `/api/update_location`, a **POST** API with JSON post data:
```json
{
    "id": "0",
    "lat": 37.451998,
    "lng": -122.094
}
```
if succeeded, the server should respond one int number indicating its updated threshold (in meters).

### Before compiling the app on your own

You need to 1) set up Firebase in the app using your own Firebase credentials, 2) change `API_BASE_URL` and `SENSITIVITY` two constants under `\app\lib\main.dart` accordingly.

For information about how to configure Firebase Cloud Messaging for this app, please refer to [this](https://pub.dev/packages/firebase_messaging) documentation on the FCM Flutter plugin.

For information about how to send a message from the server to any specific mobile device or a group of devices, please refer to [this](https://github.com/fluminus/fcm_server/blob/master/index.js) sample implementation of mine.
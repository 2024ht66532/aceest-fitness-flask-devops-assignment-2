from flask import Flask, jsonify, request, render_template_string

def create_app():
    app = Flask(__name__)
    app.workouts = {"Warm-up": [], "Workout": [], "Cool-down": []}

    INDEX_HTML = """
    <!doctype html>
    <title>ACEest Fitness</title>
    <h1>ACEest Fitness - Log Workout</h1>
    <form id="form" method="post" action="/api/workouts">
      Category:
      <select name="category">
        <option>Warm-up</option>
        <option selected>Workout</option>
        <option>Cool-down</option>
      </select><br/>
      Exercise: <input name="exercise"/><br/>
      Duration (min): <input name="duration"/><br/>
      <button type="submit">Add</button>
    </form>
    <h2>Workouts</h2>
    <pre id="workouts">{{workouts}}</pre>
    """

    @app.route("/")
    def index():
        return render_template_string(INDEX_HTML, workouts=app.workouts)

    @app.route("/api/workouts", methods=["POST"])
    def add_workout():
        if request.is_json:
            data = request.get_json()
        else:
            data = request.form.to_dict()
        category = data.get("category", "Workout")
        exercise = data.get("exercise")
        duration = data.get("duration")
        if not exercise or not duration:
            return jsonify({"error": "exercise and duration required"}), 400
        try:
            duration = int(duration)
            if duration <= 0:
                raise ValueError()
        except Exception:
            return jsonify({"error": "duration must be positive integer"}), 400
        entry = {"exercise": exercise, "duration": duration}
        if category not in app.workouts:
            app.workouts[category] = []
        app.workouts[category].append(entry)
        return jsonify({"status": "ok", "entry": entry}), 201

    @app.route("/api/workouts", methods=["GET"])
    def get_workouts():
        return jsonify(app.workouts)

    return app

if __name__ == "__main__":
    create_app().run(host="0.0.0.0", port=5000)

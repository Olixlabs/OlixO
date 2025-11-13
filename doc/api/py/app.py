from flask import Flask, request, jsonify
import json
import os

app = Flask(__name__)

DATA_FILE = 'likes.json'

# Load existing like data if exists
def load_likes():
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'r') as f:
            return json.load(f)
    return {}

# Save like data to file
def save_likes(data):
    with open(DATA_FILE, 'w') as f:
        json.dump(data, f)

# دیتابیس در حافظه (با لود از فایل)
like_counts = load_likes()

@app.route('/api/syncLikes', methods=['POST'])
def sync_likes():
    data = request.json
    likes = data.get('likes', [])

    for like in likes:
        game_id = like['gameId']
        liked = like['liked']

        if game_id not in like_counts:
            like_counts[game_id] = 0

        if liked:
            like_counts[game_id] += 1
        else:
            like_counts[game_id] = max(like_counts[game_id] - 1, 0)

    # Save to file after updating
    save_likes(like_counts)

    return jsonify({'updatedCounts': like_counts})


if __name__ == '__main__':
    app.run(debug=True)

from flask import Flask, request, jsonify, render_template
import psycopg2
from psycopg2 import Error
from datetime import datetime
import os

app = Flask(__name__)

# Database connection details
DB_HOST = '10.0.2.4'  # Private IP of the database server within the Azure VNet
DB_PORT = '5432'
DB_NAME = 'flask_db'
DB_USER = 'postgres'  # Username as configured in PostgreSQL setup
DB_PASSWORD = 'password'  # Make sure this password matches your DB setup

def connect_to_database():
    """Establish a connection to the PostgreSQL database."""
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        return conn
    except psycopg2.Error as e:
        print(f"Error connecting to the database: {e}")
        return None

def disconnect_from_database(conn, cur):
    """Close the database connection."""
    if cur:
        cur.close()
    if conn:
        conn.close()

@app.route('/', methods=['GET'])
def index():
    """Render the HTML form for data input."""
    return render_template('flaskApp.html')

@app.route('/data', methods=['POST'])
def process_data():
    """Process data input and insert it into the database."""
    try:
        data = request.json
        name = data.get('name')
        age_value = data.get('age_value')
        time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        conn = connect_to_database()
        if not conn:
            return jsonify({'status': 'error', 'message': 'Database connection error'}), 500

        cur = conn.cursor()

        # Insert data into the PostgreSQL table with conflict handling
        insert_query = """
        INSERT INTO table_gifts_yovel (name, age_value, time) 
        VALUES (%s, %s, %s) 
        ON CONFLICT (name) DO NOTHING
        """
        cur.execute(insert_query, (name, age_value, time))
        conn.commit()

        response = {
            'status': 'success',
            'name': name,
            'age_value': age_value,
            'time': time,
            'database_status': 'Data inserted successfully'
        }

        disconnect_from_database(conn, cur)
        return jsonify(response)

    except psycopg2.Error as e:
        disconnect_from_database(conn, None)
        return jsonify({'status': 'error', 'message': 'Database error', 'error_details': str(e)}), 500

@app.route('/data/<name>', methods=['GET'])
def retrieve_data(name):
    """Retrieve a specific record from the database."""
    try:
        conn = connect_to_database()
        if not conn:
            return jsonify({'status': 'error', 'message': 'Database connection error'}), 500

        cur = conn.cursor()

        # Retrieve data from PostgreSQL based on the provided name
        select_query = "SELECT * FROM table_gifts_yovel WHERE name = %s"
        cur.execute(select_query, (name,))
        result = cur.fetchone()

        if result:
            # If the record is found, return it as JSON
            response = {
                'status': 'success',
                'name': result[0],
                'age_value': result[1],
                'time': result[2]
            }
        else:
            response = {'status': 'error', 'message': 'Data not found for the provided name'}

        disconnect_from_database(conn, cur)
        return jsonify(response)

    except psycopg2.Error as e:
        disconnect_from_database(conn, None)
        return jsonify({'status': 'error', 'message': 'Database error', 'error_details': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)

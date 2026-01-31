import re
import mysql.connector

# --- Configuration ---
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',       # REPLACE WITH YOUR DB USER
    'password': '1234',   # REPLACE WITH YOUR DB PASSWORD
    'database': 'neeradstore'
}

SQL_FILE_PATH = 'produxts.sql'

# Create table SQL from user request
CREATE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_id VARCHAR(255) UNIQUE NOT NULL,
    item_name VARCHAR(255) NOT NULL,
    original_price DECIMAL(10, 2) NOT NULL,
    selling_price DECIMAL(10, 2) NOT NULL
);
"""

def parse_sql_file(file_path):
    encodings = ['utf-8', 'latin-1', 'cp1252']
    data = []
    
    # Regex to capture the first 7 fields: id, ref, code, type, name, buy, sell
    # We carefully match the structure: 
    # ('id', 'ref', 'code', 'type', 'name', 123.45, 123.45,
    # match name lazily until ', number, number,
    
    # Explanation:
    # \s*\(              : Start of tuple (with optional whitespace)
    # '[^']*'            : id (skip)
    # ,\s*'[^']*'        : ref (skip)
    # ,\s*'([^']*)'      : group 1: item_id (code)
    # ,\s*'[^']*'        : type (skip)
    # ,\s*'((?:[^']|'')*)' : group 2: item_name (handle escaped quotes roughly)
    # ,\s*([0-9.-]+)     : group 3: original_price
    # ,\s*([0-9.-]+)     : group 4: selling_price
    
    pattern = re.compile(r"\s*\('[^']*',\s*'[^']*',\s*'([^']*)',\s*'[^']*',\s*'((?:[^']|'')*)',\s*([0-9.-]+),\s*([0-9.-]+),")

    for encoding in encodings:
        try:
            with open(file_path, 'r', encoding=encoding) as f:
                print(f"Reading file with encoding: {encoding}")
                for line in f:
                    # Only process lines that look like value tuples
                    if line.strip().startswith("('"):
                        match = pattern.match(line)
                        if match:
                            item_id = match.group(1)
                            item_name = match.group(2).replace("''", "'") # Unescape SQL quotes
                            original_price = float(match.group(3))
                            selling_price = float(match.group(4))
                            
                            data.append((item_id, item_name, original_price, selling_price))
            break # Stop if successful
        except UnicodeDecodeError:
            continue
            
    print(f"Found {len(data)} products to insert.")
    return data

def migrate_data():
    try:
        data = parse_sql_file(SQL_FILE_PATH)
        if not data:
            print("No data found or parse failed.")
            return

        conn = mysql.connector.connect(**DB_CONFIG)
        cursor = conn.cursor()

        print("Connected to database.")

        # Create table
        cursor.execute(CREATE_TABLE_SQL)
        print("Table 'products' ensured.")

        # Insert data
        insert_sql = """
        INSERT INTO products (item_id, item_name, original_price, selling_price)
        VALUES (%s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE 
            item_name = VALUES(item_name),
            original_price = VALUES(original_price),
            selling_price = VALUES(selling_price);
        """
        
        # We use ON DUPLICATE KEY UPDATE so we don't fail on re-runs, matching the user's logic roughly (or IGNORE)
        # User said "UNIQUE NOT NULL" on item_id. 
        # Using executemany for performance
        
        cursor.executemany(insert_sql, data)
        conn.commit()
        
        print(f"Successfully migrated {cursor.rowcount} rows (includes updates).")

    except mysql.connector.Error as err:
        print(f"Error: {err}")
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()
            print("Connection closed.")

if __name__ == "__main__":
    migrate_data()

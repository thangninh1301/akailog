import os
import requests
import pandas as pd
import pyodbc
from datetime import datetime
import ipaddress  # To handle IP range checks

NEXUS_URL = "https://nexus.edtexco.com/service/rest/v1/assets"
REPOSITORY = "raw-test"
AUTH = ('admin', 'admin123')  # Replace with Nexus credentials or API token
DOWNLOAD_PATH = "./downloads"  # Local folder to save downloaded files

if not os.path.exists(DOWNLOAD_PATH):
    os.makedirs(DOWNLOAD_PATH)

def load_ip_mapping(ip_mapping_file):
    ip_mapping_df = pd.read_csv(ip_mapping_file)

    ip_mapping = []

    for _, row in ip_mapping_df.iterrows():
        try:
            network = ipaddress.ip_network(row['host_ip_range'])
            ip_mapping.append({
                'network': network,
                'server_location': row['server_location']
            })
        except ValueError as e:
            print(f"Invalid CIDR range in row: {row['host_ip_range']} - {e}")

    return ip_mapping

def get_server_location(host_ip, ip_mapping):
    print(f"{ip_mapping}")
    try:
        ip = ipaddress.ip_address(host_ip)
        for entry in ip_mapping:
            if ip in entry['network']:
                return entry['server_location']
    except ValueError as e:
        print(f"Invalid IP address: {host_ip} - {e}")

    return "Unknown"

def list_today_files():
    today = datetime.now().strftime("%Y-%m-%d")
    params = {
        'repository': REPOSITORY,
        'sort': 'name',
        'direction': 'asc',
    }

    try:
        response = requests.get(NEXUS_URL, auth=AUTH, params=params)
        response.raise_for_status()  # Will raise an exception for HTTP error codes
    except requests.exceptions.RequestException as e:
        print(f"Error fetching files from Nexus: {e}")
        return []

    assets = response.json().get('items', [])
    file_urls = []

    for asset in assets:
        file_name = asset['path'].split("/")[-1]  # Extract the file name from the path
        if file_name.startswith(f'result_{today}'):  # Only select files with today's date
            try:
                datetime.strptime(file_name, f'result_{today}_%H-%M-%S.csv')
                file_urls.append(asset['downloadUrl'])
            except ValueError:
                continue

    return file_urls

def download_file(file_url):
    file_name = os.path.join(DOWNLOAD_PATH, file_url.split("/")[-1])

    try:
        response = requests.get(file_url, auth=AUTH)
        response.raise_for_status()  # Will raise an exception for HTTP error codes
    except requests.exceptions.RequestException as e:
        print(f"Failed to download {file_url}: {e}")
        return None

    with open(file_name, 'wb') as f:
        f.write(response.content)

    return file_name

def read_csv_to_dict(csv_file_path):
    try:
        df = pd.read_csv(csv_file_path)
        return df.to_dict(orient='records')  # Converts to list of dicts (Array of objects)
    except Exception as e:
        print(f"Error reading CSV file {csv_file_path}: {e}")
        return []

def import_data_to_mssql(data, table_name, conn_str):
    conn = None
    try:
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()

        for row in data:
            columns = ', '.join(row.keys())
            placeholders = ', '.join('?' * len(row))
            sql = f"INSERT INTO {table_name} ({columns}) VALUES ({placeholders})"
            print(sql)
            cursor.execute(sql, tuple(row.values()))

        conn.commit()
    except Exception as e:
        print(f"Error inserting data into MSSQL: {e}")
    finally:
        if conn:
            cursor.close()
            conn.close()

def main():
    ip_mapping_file = './mapping.csv'  # Replace with the correct path to the IP mapping CSV
    ip_mapping = load_ip_mapping(ip_mapping_file)

    file_urls = list_today_files()

    if not file_urls:
        print("No files found for today.")
        return

    conn_str = (
        'DRIVER={ODBC Driver 18 for SQL Server};'
        'SERVER=192.0.0.11,30542;'
        'DATABASE=MyDatabase;'
        'UID=SA;'
        'PWD=mypasswordA@;'
        "Encrypt=yes;"  # Enable encryption
        "TrustServerCertificate=yes;"  # Bypass SSL certificate validation
    )

    table_name = 'LogDetails'  # Change this to your table name

    for file_url in file_urls:
        # Download the file
        csv_file = download_file(file_url)

        if csv_file:
            data = read_csv_to_dict(csv_file)

            for row in data:
                row['server_location'] = get_server_location(row.get('host_ip'), ip_mapping)

            print(f"List of records in file {csv_file} with server_location: {data}")

            if data:
                import_data_to_mssql(data, table_name, conn_str)
                print(f"Data from {csv_file} has been successfully imported into {table_name}.")

    print("All files for today have been processed.")

if __name__ == "__main__":
    main()


# SELECT TABLE_NAME
# FROM INFORMATION_SCHEMA.TABLES
# WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_CATALOG = 'MyDatabase';

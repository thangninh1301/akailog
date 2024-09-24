import os
import requests
import pandas as pd
import pyodbc
from datetime import datetime

# Nexus API settings
NEXUS_URL = "https://nexus.edtexco.com/service/rest/v1/assets"
REPOSITORY = "raw-test"
AUTH = ('your_username', 'your_password')  # Replace with Nexus credentials or API token
DOWNLOAD_PATH = "./downloads"  # Local folder to save downloaded files

# Ensure download directory exists
if not os.path.exists(DOWNLOAD_PATH):
    os.makedirs(DOWNLOAD_PATH)

# Function to list all files in Nexus for today, matching the format "result_YYYY-MM-DD_HH-MM-SS.csv"
def list_today_files():
    today = datetime.now().strftime("%Y-%m-%d")
    params = {
        'repository': REPOSITORY,
        'sort': 'name',
        'direction': 'asc',
    }

    response = requests.get(NEXUS_URL, auth=AUTH, params=params)
    if response.status_code != 200:
        print "Failed to list files: {}".format(response.status_code)
        return []
    
    assets = response.json()['items']
    file_urls = []
    
    for asset in assets:
        file_name = asset['path'].split("/")[-1]  # Extract the file name from the path
        if file_name.startswith('result_{}'.format(today)):  # Only select files with today's date
            # Check if the file matches the format result_YYYY-MM-DD_HH-MM-SS.csv
            try:
                # This checks the exact format of the file name (with hour, minute, second)
                datetime.strptime(file_name, 'result_{}_%%H-%%M-%%S.csv'.format(today))
                file_urls.append(asset['downloadUrl'])
            except ValueError:
                continue  # Skip files that do not match the expected format
    
    return file_urls

# Function to download a file from Nexus
def download_file(file_url):
    file_name = os.path.join(DOWNLOAD_PATH, file_url.split("/")[-1])
    
    response = requests.get(file_url, auth=AUTH)
    if response.status_code == 200:
        with open(file_name, 'wb') as f:
            f.write(response.content)
        return file_name
    else:
        print "Failed to download {}: {}".format(file_url, response.status_code)
        return None

# Function to read CSV file and convert to list of dictionaries
def read_csv_to_dict(csv_file_path):
    df = pd.read_csv(csv_file_path)
    return df.to_dict(orient='records')  # Converts to list of dicts (Array of objects)

# Function to import data into MSSQL database
def import_data_to_mssql(data, table_name, conn_str):
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()

    # Assuming that the column names in the DataFrame match the SQL table column names
    for row in data:
        columns = ', '.join(row.keys())
        placeholders = ', '.join(['?'] * len(row))
        sql = "INSERT INTO {} ({}) VALUES ({})".format(table_name, columns, placeholders)
        
        # Execute the SQL with the row values
        cursor.execute(sql, tuple(row.values()))
    
    # Commit the transaction
    conn.commit()
    cursor.close()
    conn.close()

# Main function to execute the process
def main():
    # List all files for today in Nexus, matching the format "result_YYYY-MM-DD_HH-MM-SS.csv"
    file_urls = list_today_files()
    
    if not file_urls:
        print "No files found for today."
        return
    
    # Connection string for MSSQL (replace with your own connection details)
    conn_str = (
        'DRIVER={SQL Server};'
        'SERVER=your_server_name;'
        'DATABASE=your_database_name;'
        'UID=your_username;'
        'PWD=your_password'
    )
    
    table_name = 'your_table_name'
    
    # Process each file found for today
    for file_url in file_urls:
        # Download the file
        csv_file = download_file(file_url)
        
        if csv_file:
            # Read the CSV file
            data = read_csv_to_dict(csv_file)
            
            # Import data into the MSSQL database
            import_data_to_mssql(data, table_name, conn_str)
            print "Data from {} has been successfully imported into {}.".format(csv_file, table_name)
    
    print "All files for today have been processed."

if __name__ == "__main__":
    main()

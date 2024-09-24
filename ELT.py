import os
import pandas as pd
import pyodbc
from datetime import datetime

# Function to find all files for today in the directory
def find_today_files(directory):
    today = datetime.now().strftime("%Y-%m-%d")  # Get current date in YYYY-MM-DD format
    today_files = []
    
    for file_name in os.listdir(directory):
        if file_name.startswith('result-') and today in file_name:
            file_path = os.path.join(directory, file_name)
            today_files.append(file_path)
    
    return today_files

# Function to read the Excel file and convert to list of dictionaries
def read_excel_to_dict(excel_file_path):
    df = pd.read_excel(excel_file_path)
    return df.to_dict(orient='records')  # Converts to list of dicts (Array of objects)

# Function to import data into MSSQL database
def import_data_to_mssql(data, table_name, conn_str):
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()

    # Assuming that the column names in the DataFrame match the SQL table column names
    for row in data:
        columns = ', '.join(row.keys())
        placeholders = ', '.join('?' * len(row))
        sql = f"INSERT INTO {table_name} ({columns}) VALUES ({placeholders})"
        
        # Execute the SQL with the row values
        cursor.execute(sql, tuple(row.values()))
    
    # Commit the transaction
    conn.commit()
    cursor.close()
    conn.close()

# Main function to execute the process
def main():
    directory = "/path/to/nexus"  # Replace with the actual path to the Nexus folder
    excel_files = find_today_files(directory)
    
    if not excel_files:
        print("No files found for today.")
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
    for excel_file in excel_files:
        # Read the Excel file
        data = read_excel_to_dict(excel_file)
        
        # Import data into the MSSQL database
        import_data_to_mssql(data, table_name, conn_str)
        print(f"Data from {excel_file} has been successfully imported into {table_name}.")
    
    print("All files for today have been processed.")

if __name__ == "__main__":
    main()

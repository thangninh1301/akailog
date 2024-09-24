import os
import pandas as pd
import pyodbc
from datetime import datetime

# Function to find today's most recent file in the directory
def find_latest_today_file(directory):
    today = datetime.now().strftime("%Y-%m-%d")  # Get current date in YYYY-MM-DD format
    latest_file = None
    latest_time = None
    
    for file_name in os.listdir(directory):
        if file_name.startswith('result-') and today in file_name:
            # Extract the hour (HH) from the file name (e.g., result-YYYY-MM-DD-HH.xlsx)
            try:
                file_time = datetime.strptime(file_name[7:16], "%Y-%m-%d-%H")
            except ValueError:
                continue  # Skip files that don't match the date-hour pattern
            
            # Compare to find the most recent file based on the hour
            if latest_time is None or file_time > latest_time:
                latest_file = os.path.join(directory, file_name)
                latest_time = file_time
    
    return latest_file

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
    excel_file = find_latest_today_file(directory)
    
    if excel_file is None:
        print("No file found for today.")
        return
    
    # Read the Excel file
    data = read_excel_to_dict(excel_file)
    
    # Connection string for MSSQL (replace with your own connection details)
    conn_str = (
        'DRIVER={SQL Server};'
        'SERVER=your_server_name;'
        'DATABASE=your_database_name;'
        'UID=your_username;'
        'PWD=your_password'
    )
    
    # Import data into the desired MSSQL table
    table_name = 'your_table_name'
    import_data_to_mssql(data, table_name, conn_str)
    print(f"Data from {excel_file} has been successfully imported into {table_name}.")

if __name__ == "__main__":
    main()

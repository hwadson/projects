from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import pandas as pd
import numpy as np
from ucimlrepo import fetch_ucirepo

def load_data():
    """Fetch the cirrhosis patient survival dataset from UCI repository."""
    cirrhosis_patient_survival_prediction = fetch_ucirepo(id=878)
    data_dict = cirrhosis_patient_survival_prediction.data
    data = data_dict['original']  # Extract the 'original' DataFrame
    print(data)  # Debugging line to check data
    return data

def preprocess_data(data):
    """Preprocess the dataset by handling missing values and normalizing features."""
    # Drop rows with missing values in the 'Drug' column
    data = data.dropna(subset=['Drug'])
    
    # Impute missing values with mean for numerical columns
    for column in data.select_dtypes(include=['float64', 'int64']).columns:
        data[column].fillna(data[column].mean(), inplace=True)
    
    # Fill NaN values in categorical columns with a placeholder
    for column in data.select_dtypes(include=['object']).columns:
        data[column].fillna('Unknown', inplace=True)
    
    # One-hot encoding for categorical attributes
    data = pd.get_dummies(data, columns=['Drug', 'Sex', 'Ascites', 'Hepatomegaly', 'Spiders', 'Edema', 'Status'], drop_first=True)
    
    return data

def split_data(data, target_column, test_size=0.2, random_state=42):
    """Split the dataset into training and testing sets."""
    X = data.drop(columns=[target_column, 'N_Days'])
    y = data[target_column]
    return train_test_split(X, y, test_size=test_size, random_state=random_state)

def normalize_data(X_train, X_test):
    """Normalize the feature data."""
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    return X_train_scaled, X_test_scaled, scaler

if __name__ == "__main__":
    # Load and preprocess data
    data = load_data()
    data = preprocess_data(data)
    print(data.columns)  # Debugging line to print columns
    X_train, X_test, y_train, y_test = split_data(data, target_column='Status')
    X_train_scaled, X_test_scaled, scaler = normalize_data(X_train, X_test)
    np.save('data/preprocessed_data.npy', X_train_scaled)  # Save preprocessed data for training
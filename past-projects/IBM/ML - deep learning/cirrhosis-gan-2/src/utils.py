from sklearn.preprocessing import MinMaxScaler
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

def load_data(file_path):
    """Load the cirrhosis patient survival dataset."""
    return pd.read_csv(file_path)

def normalize_data(data):
    """Normalize the dataset using Min-Max scaling."""
    scaler = MinMaxScaler()
    return pd.DataFrame(scaler.fit_transform(data), columns=data.columns)

def visualize_data(data, columns):
    """Visualize the specified columns of the dataset."""
    for column in columns:
        plt.figure(figsize=(10, 5))
        plt.hist(data[column], bins=30, alpha=0.7, color='blue')
        plt.title(f'Distribution of {column}')
        plt.xlabel(column)
        plt.ylabel('Frequency')
        plt.grid()
        plt.show()

def calculate_metrics(original_data, generated_data):
    """Calculate and return basic metrics comparing original and generated data."""
    metrics = {
        'mean_original': original_data.mean(),
        'mean_generated': generated_data.mean(),
        'std_original': original_data.std(),
        'std_generated': generated_data.std()
    }
    return metrics
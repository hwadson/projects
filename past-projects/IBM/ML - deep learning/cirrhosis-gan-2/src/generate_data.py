from keras.models import load_model
import pandas as pd
import numpy as np

def generate_synthetic_data(model_path, num_samples=500):
    # Load the trained GAN model
    generator = load_model(model_path)

    # Generate random noise as input for the generator
    noise = np.random.normal(0, 1, (num_samples, 100))  # Assuming the generator input is 100-dimensional

    # Generate synthetic data
    synthetic_data = generator.predict(noise)

    return synthetic_data

def save_synthetic_data(synthetic_data, output_path):
    # Convert the synthetic data to a DataFrame
    synthetic_df = pd.DataFrame(synthetic_data, columns=[
        'N_Days', 'Status', 'Drug', 'Age', 'Sex', 'Ascites', 
        'Hepatomegaly', 'Spiders', 'Edema', 'Bilirubin', 
        'Cholesterol', 'Albumin', 'Copper', 'Alk_Phos', 
        'SGOT', 'Triglycerides', 'Platelets', 'Prothrombin', 'Stage'
    ])
    
    # Save the DataFrame to a CSV file
    synthetic_df.to_csv(output_path, index=False)

if __name__ == "__main__":
    model_path = 'path/to/your/trained_gan_model.h5'  # Update with the actual model path
    output_path = 'data/synthetic_cirrhosis_data.csv'
    
    synthetic_data = generate_synthetic_data(model_path)
    save_synthetic_data(synthetic_data, output_path)
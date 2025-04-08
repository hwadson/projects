import pandas as pd
import numpy as np
import torch
from models.generator import Generator

def generate_samples(model_path, num_samples=500):
    # Load the trained generator model
    generator = Generator(input_dim=100, output_dim=10)  # Adjust input_dim and output_dim as needed
    generator.load_state_dict(torch.load(model_path))
    generator.eval()

    # Generate random noise as input for the generator
    noise = torch.randn(num_samples, generator.input_dim)

    # Generate samples
    with torch.no_grad():
        generated_data = generator(noise).numpy()

    return generated_data

def save_generated_samples(generated_data, output_file):
    # Convert to DataFrame and save to CSV
    df = pd.DataFrame(generated_data, columns=[
        'Drug', 'Age', 'Sex', 'Ascites', 'Hepatomegaly', 
        'Spiders', 'Edema', 'Bilirubin', 'Cholesterol', 'Albumin', 
        'Copper', 'Alk_Phos', 'SGOT', 'Tryglicerides', 'Platelets', 'Prothrombin', 'Stage'
    ])
    df['Status'] = np.random.choice(['C', 'D', 'CL'], size=(df.shape[0],))  # Random targets for generated data
    df.to_csv(output_file, index=False)

if __name__ == "__main__":
    model_path = 'path/to/trained_generator.pth'  # Update with the actual path
    output_file = 'data/generated_cirrhosis_samples.csv'
    
    generated_data = generate_samples(model_path)
    save_generated_samples(generated_data, output_file)
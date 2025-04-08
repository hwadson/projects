import sys
import os
sys.path.append(r'C:\Users\h4rsh\cirrhosis_project\cirrhosis-gan')

import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from models.generator import Generator
from models.discriminator import Discriminator
from ucimlrepo import fetch_ucirepo 

# Fetch dataset 
cirrhosis_patient_survival_prediction = fetch_ucirepo(id=878) 

# Extract the relevant DataFrame
data = cirrhosis_patient_survival_prediction.data['original']

# Get the variable names from the dataset
variables = cirrhosis_patient_survival_prediction.variables

# Preprocess the data
# Convert categorical columns to numeric
categorical_columns = ['Drug', 'Sex', 'Ascites', 'Hepatomegaly', 'Spiders', 'Edema']
for col in categorical_columns:
    if col in data.columns:
        data[col] = data[col].astype('category').cat.codes
    else:
        print(f"Warning: Column '{col}' not found in the dataset.")

# Standardize numerical columns
numerical_columns = ['Age', 'Bilirubin', 'Cholesterol', 'Albumin', 'Copper', 'Alk_Phos', 'SGOT', 'Tryglicerides', 'Platelets', 'Prothrombin']
scaler = StandardScaler()
data[numerical_columns] = scaler.fit_transform(data.loc[:, numerical_columns])

# Convert features and targets to NumPy arrays
features = data.drop(columns=['Status']).values
targets = pd.get_dummies(data['Status']).values

# Hyperparameters
epochs = 10000
batch_size = 32
sample_interval = 100

# Initialize models
generator = Generator(input_dim=100, output_dim=features.shape[1])  # Adjust output_dim to match the number of features
discriminator = Discriminator(input_shape=(features.shape[1],))

# Compile models
discriminator.model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])
generator.model.compile(optimizer='adam', loss='categorical_crossentropy')

# Training loop
for epoch in range(epochs):
    # Train Discriminator
    idx = np.random.randint(0, features.shape[0], batch_size)
    real_features = features[idx].astype(np.float32)  # Ensure features are float32
    real_targets = targets[idx].astype(np.float32)  # Ensure targets are float32

    noise = np.random.normal(0, 1, (batch_size, generator.input_dim)).astype(np.float32)  # Ensure noise is float32
    generated_features = generator.model.predict(noise)
    fake_targets = np.zeros((batch_size, targets.shape[1]), dtype=np.float32)  # Fake targets are all zeros, converted to float

    # Print shapes of generated features and real features
    print(f"Epoch {epoch}: generated_features.shape = {generated_features.shape}, real_features.shape = {real_features.shape}")

    d_loss_real = discriminator.model.train_on_batch(real_features, real_targets)
    d_loss_fake = discriminator.model.train_on_batch(generated_features, fake_targets)
    d_loss = 0.5 * np.add(d_loss_real, d_loss_fake)

    # Train Generator
    noise = np.random.normal(0, 1, (batch_size, generator.input_dim)).astype(np.float32)  # Ensure noise is float32
    g_loss = generator.model.train_on_batch(noise, np.ones((batch_size, targets.shape[1]), dtype=np.float32))  # Generator tries to fool the discriminator

    # Print the progress
    if epoch % sample_interval == 0:
        print(f"{epoch} [D loss: {d_loss[0]:.4f}, acc.: {100 * d_loss[1]:.2f}%] [G loss: {g_loss:.4f}]")

# Generate additional samples
num_samples = 500
noise = np.random.normal(0, 1, (num_samples, generator.input_dim)).astype(np.float32)  # Ensure noise is float32
generated_samples = generator.model.predict(noise)

# Save generated samples to a CSV file
generated_df = pd.DataFrame(generated_samples, columns=data.drop(columns=['Status']).columns)  # Assuming same columns as features
generated_df['Status'] = np.random.choice(['C', 'D', 'CL'], size=(num_samples,))  # Random targets for generated data
generated_df.to_csv('../data/generated_cirrhosis.csv', index=False)
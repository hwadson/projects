# GAN for Cirrhosis Patient Survival Data Generation

This project implements a Generative Adversarial Network (GAN) to generate synthetic data for the cirrhosis patient survival dataset. The goal is to augment the existing dataset with additional rows to improve model training and evaluation.

## Project Structure

```
gan-cirrhosis-survival
├── data
│   └── cirrhosis_patient_survival.csv  # Original dataset
├── src
│   ├── __init__.py                      # Marks the src directory as a Python package
│   ├── data_preprocessing.py            # Functions for loading and preprocessing the dataset
│   ├── gan_model.py                      # Defines the GAN architecture
│   ├── generate_data.py                  # Logic for generating new data using the trained GAN
│   └── utils.py                         # Utility functions for visualization and evaluation
├── requirements.txt                      # Project dependencies
└── README.md                             # Project documentation
```

## Installation

To set up the project, clone the repository and install the required dependencies:

```bash
pip install -r requirements.txt
```

## Usage

1. **Data Preprocessing**: Run `data_preprocessing.py` to load and preprocess the cirrhosis dataset.
2. **Train the GAN**: Use `gan_model.py` to define and train the GAN on the preprocessed data.
3. **Generate Synthetic Data**: Execute `generate_data.py` to generate 500 new rows of synthetic data and save them to a CSV file.

## Dependencies

This project requires the following Python libraries:

- TensorFlow
- NumPy
- Pandas

Make sure to install these libraries using the `requirements.txt` file.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.
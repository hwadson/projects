# CIRRHOSIS GAN

This project implements a Generative Adversarial Network (GAN) to generate synthetic data for the cirrhosis survival dataset. The goal is to augment the existing dataset with additional samples to improve model training and evaluation.

## Project Structure

- **data/cirrhosis_survival.csv**: Contains the original dataset used for training the GAN, including features and targets related to cirrhosis survival.
  
- **models/discriminator.py**: Defines the Discriminator class, responsible for distinguishing between real and generated data. It includes methods for building the model architecture and training the discriminator.

- **models/generator.py**: Defines the Generator class, responsible for generating new data samples. It includes methods for building the model architecture and training the generator.

- **src/train.py**: Contains the main training loop for the GAN. It orchestrates the training process by alternating between training the discriminator and the generator, and it saves the generated samples.

- **src/generate.py**: Used to generate new samples using the trained generator model. It loads the trained model and produces additional rows of features and targets.

## Installation

To set up the project, clone the repository and install the required dependencies:

```bash
pip install -r requirements.txt
```

## Usage

1. **Training the GAN**: Run the training script to train the GAN on the cirrhosis survival dataset.

   ```bash
   python src/train.py
   ```

2. **Generating New Samples**: After training, use the generate script to create new synthetic samples.

   ```bash
   python src/generate.py
   ```

## Dependencies

Make sure to install the following libraries as specified in `requirements.txt`:

- TensorFlow or PyTorch
- pandas
- numpy
- other necessary libraries

## License

This project is licensed under the MIT License. See the LICENSE file for more details.
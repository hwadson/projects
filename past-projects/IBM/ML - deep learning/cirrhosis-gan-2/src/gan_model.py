from tensorflow import keras
from tensorflow.keras import layers

def build_generator(latent_dim):
    model = keras.Sequential()
    model.add(layers.Dense(128, activation='relu', input_dim=latent_dim))
    model.add(layers.Dense(256, activation='relu'))
    model.add(layers.Dense(512, activation='relu'))
    model.add(layers.Dense(20, activation='tanh'))  # Assuming 20 features in the dataset
    return model

def build_discriminator(input_shape):
    model = keras.Sequential()
    model.add(layers.Dense(512, activation='relu', input_shape=input_shape))
    model.add(layers.Dense(256, activation='relu'))
    model.add(layers.Dense(1, activation='sigmoid'))
    return model

def compile_gan(generator, discriminator):
    discriminator.compile(loss='binary_crossentropy', optimizer='adam', metrics=['accuracy'])
    discriminator.trainable = False

    gan_input = layers.Input(shape=(latent_dim,))
    generated_data = generator(gan_input)
    gan_output = discriminator(generated_data)

    gan = keras.Model(gan_input, gan_output)
    gan.compile(loss='binary_crossentropy', optimizer='adam')
    return gan

latent_dim = 100  # Dimension of the latent space
input_shape = (20,)  # Shape of the input data (number of features)

generator = build_generator(latent_dim)
discriminator = build_discriminator(input_shape)
gan = compile_gan(generator, discriminator)
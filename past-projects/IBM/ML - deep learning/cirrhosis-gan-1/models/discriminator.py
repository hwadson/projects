class Discriminator:
    def __init__(self, input_shape):
        self.model = self.build_model(input_shape)

    def build_model(self, input_shape):
        from tensorflow.keras import layers, models

        model = models.Sequential()
        model.add(layers.Dense(128, activation='relu', input_shape=input_shape))
        model.add(layers.Dropout(0.3))
        model.add(layers.Dense(64, activation='relu'))
        model.add(layers.Dropout(0.3))
        model.add(layers.Dense(3, activation='softmax'))  # Output 3 classes

        model.compile(loss='categorical_crossentropy', optimizer='adam', metrics=['accuracy'])
        return model

    def train(self, real_data, fake_data, epochs=1):
        import numpy as np

        labels_real = np.ones((real_data.shape[0], 3))  # Real targets are one-hot encoded
        labels_fake = np.zeros((fake_data.shape[0], 3))  # Fake targets are all zeros

        combined_data = np.vstack((real_data, fake_data))
        combined_labels = np.vstack((labels_real, labels_fake))

        self.model.fit(combined_data, combined_labels, epochs=epochs, batch_size=32)
class Generator:
    def __init__(self, input_dim, output_dim):
        self.input_dim = input_dim
        self.output_dim = output_dim
        self.model = self.build_model()

    def build_model(self):
        from tensorflow.keras import layers, models

        model = models.Sequential()
        model.add(layers.Dense(128, activation='relu', input_dim=self.input_dim))
        model.add(layers.Dense(64, activation='relu'))
        model.add(layers.Dense(self.output_dim, activation='softmax'))  # Output 3 classes

        return model

    def generate(self, noise):
        return self.model.predict(noise)

    def train(self, noise, targets, epochs=1000, batch_size=32):
        from tensorflow.keras.optimizers import Adam

        self.model.compile(loss='binary_crossentropy', optimizer=Adam(0.0002, 0.5))
        self.model.fit(noise, targets, epochs=epochs, batch_size=batch_size)
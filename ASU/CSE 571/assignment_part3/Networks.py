import torch
import torch.nn as nn

class Action_Conditioned_FF(nn.Module):
    def __init__(self):
# STUDENTS: __init__() must initiatize nn.Module and define your network's
# custom architecture
        super(Action_Conditioned_FF, self).__init__()
        
        # Model parameters
        # input_size = 6  # (ie. 6 features)
        # hidden_size = 64  # hidden layer size
        # output_size = 1   # output size       
        
        self.fc1 = nn.Linear(6, 64)  # First fully connected layer (input size = 6, hidden size = 64)
        self.fc2 = nn.Linear(64, 1)  # Second fully connected layer (hidden size = 64, output size = 1)
        
        # Define activation functions
        self.relu = nn.ReLU()

    def forward(self, input):
# STUDENTS: forward() must complete a single forward pass through your network
# and return the output which should be a tensor
        # Forward pass through the network
        x = self.fc1(input)   # Apply the first layer
        x = self.relu(x)      # Apply ReLU activation
        output = self.fc2(x)  # Apply the second layer (output layer)
        return output


    def evaluate(self, model, test_loader, loss_function):
# STUDENTS: evaluate() must return the loss (a value, not a tensor) over your testing dataset. Keep in
# mind that we do not need to keep track of any gradients while evaluating the
# model. loss_function will be a PyTorch loss function which takes as argument the model's
# output and the desired output.

        model.eval()  # Set the model to evaluation mode
        
        total_loss = 0
        with torch.no_grad():  # No need to track gradients during evaluation
            for sample in test_loader:
                data, target = sample['input'], sample['label']
                # Forward pass through the model
                output = model(data)
                loss_i = loss_function(output, target)  # Compute the loss
                total_loss += loss_i.item()  # Accumulate the loss

        # Return the average loss over the dataset
        loss = total_loss / len(test_loader)
        return loss


def main():
    model = Action_Conditioned_FF()

if __name__ == '__main__':
    main()

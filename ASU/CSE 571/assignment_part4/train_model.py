from Data_Loaders import Data_Loaders
from Networks import Action_Conditioned_FF

import torch
import torch.nn as nn
import matplotlib.pyplot as plt


def train_model(no_epochs):

    batch_size = 16
    data_loaders = Data_Loaders(batch_size)
    model = Action_Conditioned_FF()
    
    #class_weights = torch.tensor([1.0, 10.0])  # adjust based on data
    loss_function = nn.BCEWithLogitsLoss()#(pos_weight=class_weights)  # BCE Loss with class weights

    
    # Define the optimizer (Stochastic Gradient Descent)
    optimizer = torch.optim.SGD(model.parameters(), lr=0.001)

    losses = []
    min_loss = model.evaluate(model, data_loaders.test_loader, loss_function)
    losses.append(min_loss)


    for epoch_i in range(no_epochs):
        model.train()
        for idx, sample in enumerate(data_loaders.train_loader): # sample['input'] and sample['label']
            inputs, labels = sample['input'], sample['label']
            
            # Zero the parameter gradients
            optimizer.zero_grad()
            
            # Forward pass
            outputs = model(inputs)
                        
            # Squeeze the output to match the target shape
            outputs = outputs.squeeze()  # Shape: [batch_size]
            

            # Calculate loss
            loss = loss_function(outputs, labels)  # BCE expects labels to be of shape [batch_size]
              
            # Backward pass and optimize
            loss.backward()
            optimizer.step()

        # Evaluate on test data after each epoch
        model.eval()  # Set the model to evaluation mode
        test_loss = model.evaluate(model, data_loaders.test_loader, loss_function)
        losses.append(test_loss)
        
        # Print epoch results
        print(f"Epoch {epoch_i+1}/{no_epochs}")
        print(f"Test Loss: {test_loss:.4f}")

    # Save the model after training
    torch.save(model.state_dict(), 'saved/saved_model.pkl')

    # Plot the training and test losses
    plt.figure(figsize=(10, 5))
    plt.plot(range(no_epochs+1), losses, label='Test Loss')
    plt.xlabel('Epochs')
    plt.ylabel('Loss')
    plt.title('Test Loss Over Epochs')
    plt.legend()
    plt.show()



# def evaluate_with_threshold(model, test_loader, threshold=0.5):
#     """
#     Function to evaluate the model with a given threshold
#     for binary classification tasks.
#     """
#     model.eval()
    
#     missed_collisions = 0  # False negatives
#     false_positives = 0    # False positives
#     correct_predictions = 0
    
#     with torch.no_grad():
#         for sample in test_loader:
#             inputs, labels = sample['input'], sample['label']
            
#             # Forward pass
#             outputs = model(inputs)
            
#             # Reshape labels to match the shape of outputs (batch_size, 1)
#             labels = labels.view(-1, 1)  # Convert shape from (batch_size,) to (batch_size, 1)
            
#             # Apply sigmoid to get probabilities
#             probabilities = torch.sigmoid(outputs)
            
#             # Apply threshold to classify as collision (1) or no collision (0)
#             predictions = (probabilities > threshold).float()
            
#             # Calculate missed collisions and false positives
#             missed_collisions += ((predictions == 0) & (labels == 1)).sum().item()
#             false_positives += ((predictions == 1) & (labels == 0)).sum().item()
#             correct_predictions += (predictions == labels).sum().item()

#     accuracy = correct_predictions / len(test_loader.dataset)
#     print(f"Accuracy: {accuracy:.4f}")
#     print(f"Missed Collisions: {missed_collisions}")
#     print(f"False Positives: {false_positives}")
    
#     return missed_collisions, false_positives, accuracy




if __name__ == '__main__':
    no_epochs = 50
    train_model(no_epochs)


    # # evaluating model with a threshold
    # data_loaders = Data_Loaders(batch_size=16)
    # model = Action_Conditioned_FF()
    # model.load_state_dict(torch.load('saved/saved_model.pkl'))
    
    # # Test the model with a threshold of 0.5
    # missed_collisions, false_positives, accuracy = evaluate_with_threshold(model, data_loaders.test_loader, threshold=0.5)
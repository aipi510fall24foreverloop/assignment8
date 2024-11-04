# Importing Dependencies

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.datasets import load_iris
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from fastapi import FastAPI
from pydantic import BaseModel


# Model and API code goes here


app = FastAPI()

# Loading IRIS Dataset
iris=load_iris()
df = pd.DataFrame(data=iris.data, columns=iris.feature_names)


# Display the first few rows of the DataFrame
print(df.head())

# Split data into training and testing datasets
X = df  # Features
y = iris.target  # Target variable
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Scale features
scaler = StandardScaler()
X_train = scaler.fit_transform(X_train)
X_test = scaler.transform(X_test)

print(X.info())


# Create a logistic regression model 
model = LogisticRegression()

# Train the model
model.fit(X_train, y_train)

#Make predictions
y_pred = model.predict(X_test)

# Calculate accuracy
accuracy = accuracy_score(y_test, y_pred)
print(f"Accuracy: {accuracy}")


# Define input data model
class InputData(BaseModel):
    # Define your input features here
    sepal_length: float
    sepal_width: float
    petal_length: float
    petal_width: float
  

# Define prediction output model
class PredictionOutput(BaseModel):
    prediction: str
    probability: list

@app.post("/predict", response_model=PredictionOutput)
def predict(data: InputData):
    # Convert input data to numpy array
    input_data = np.array([[data.sepal_length, data.sepal_width,data.petal_length, data.petal_width]])  # Adjust based on your features
    
    # Make prediction
    prediction = model.predict(input_data)[0]
    probability = model.predict_proba(input_data)[0].tolist()

    # Map target values to species names
    target_names = {
    0: 'setosa',
    1: 'versicolor',
    2: 'virginica'
    }

    
    return PredictionOutput(prediction=target_names[int(prediction)], probability=probability)

@app.get("/")
def read_root():
    return {"message": "Welcome to the ML model API"}



